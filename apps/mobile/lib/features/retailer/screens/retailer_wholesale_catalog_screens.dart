import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_session.dart';
import '../retailer_wholesale_models.dart';
import '../widgets/retailer_widgets.dart';

String wholesaleMoney(int value) => '₹${value.toString()}';

Future<void> showWholesaleSheet(
  BuildContext context, {
  required String title,
  required String detail,
  required List<Widget> children,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.md,
          0,
          MoolSpacing.md,
          MediaQuery.viewInsetsOf(sheetContext).bottom + MoolSpacing.lg,
        ),
        child: Column(
          key: const Key('wholesale-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(color: MoolColors.muted)),
            const SizedBox(height: MoolSpacing.md),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class RetailerWholesaleCatalogScreen extends StatefulWidget {
  const RetailerWholesaleCatalogScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  State<RetailerWholesaleCatalogScreen> createState() =>
      _RetailerWholesaleCatalogScreenState();
}

class _RetailerWholesaleCatalogScreenState
    extends State<RetailerWholesaleCatalogScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.session.wholesaleSearchQuery,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => RetailerPageScaffold(
        session: widget.session,
        title: 'Wholesale Buy',
        subtitle: 'Area-matched cases · Jodhpur',
        activeDock: 'wholesale',
        returnRoute: '/app/retailer/home',
        trailing: IconButton.outlined(
          key: const Key('wholesale-alerts'),
          tooltip: 'Open wholesale alerts',
          onPressed: () => showWholesaleSheet(
            context,
            title: 'Wholesale alerts',
            detail: 'Only procurement events that need action.',
            children: const [
              _SheetFact(
                title: '7 low-stock products',
                detail: 'Build an MOQ-ready reorder',
              ),
              _SheetFact(
                title: '2 supplier deliveries',
                detail: 'One dispatch due today',
              ),
              _SheetFact(
                title: '₹2,568 supplier bill',
                detail: 'Due 25 July',
              ),
            ],
          ),
          icon: const Badge(
            label: Text('3'),
            child: Icon(Icons.notifications_none_rounded),
          ),
        ),
        bottomAction: widget.session.wholesaleCaseCount == 0
            ? null
            : FilledButton(
                key: const Key('wholesale-open-cart'),
                onPressed: () => context.go('/app/retailer/wholesale/cart'),
                child: Text(
                  'Review ${widget.session.wholesaleCaseCount} cases · ${wholesaleMoney(widget.session.wholesaleCartTotal)}',
                ),
              ),
        body: ListView(
          key: const Key('wholesale-catalog-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const RetailerSectionTitle(
              title: 'Buy for your shop',
              detail:
                  'Wholesale cases, MOQ and delivery are separate from consumer Buy',
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('wholesale-search'),
              controller: _search,
              onChanged: widget.session.searchWholesale,
              decoration: InputDecoration(
                labelText: 'Search brand, product or SKU',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? IconButton(
                        key: const Key('wholesale-scan'),
                        tooltip: 'Scan product barcode',
                        onPressed: () => _showScanner(context),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      )
                    : IconButton(
                        key: const Key('wholesale-clear-search'),
                        tooltip: 'Clear wholesale search',
                        onPressed: () {
                          _search.clear();
                          widget.session.searchWholesale('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            RetailerCard(
              color: const Color(0xFFEAF7E8),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: MoolColors.success),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: Text(
                      'Invoice, payment and delivery terms are shown before purchase.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            RetailerCard(
              onTap: widget.session.buildLowStockReorder,
              keyName: 'wholesale-reorder',
              child: const Row(
                children: [
                  Icon(Icons.replay_circle_filled_rounded),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '7 low-stock products',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text('Build an MOQ-ready reorder'),
                      ],
                    ),
                  ),
                  Text(
                    'Reorder',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in RetailerWholesaleCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: MoolSpacing.xxs),
                      child: ChoiceChip(
                        key: Key('wholesale-category-${category.name}'),
                        label: Text(category.label),
                        selected:
                            widget.session.wholesaleCategory == category,
                        onSelected: (_) =>
                            widget.session.setWholesaleCategory(category),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            RetailerSectionTitle(
              title: 'Area-matched supply',
              detail:
                  '${widget.session.visibleWholesaleProducts.length} products · price · MOQ · delivery',
            ),
            const SizedBox(height: MoolSpacing.sm),
            if (widget.session.visibleWholesaleProducts.isEmpty)
              RetailerEmptyState(
                keyName: 'wholesale-empty',
                title: 'No wholesale product found',
                detail: 'Clear search or choose All to see available cases.',
                actionLabel: 'Clear search',
                onAction: () {
                  _search.clear();
                  widget.session.searchWholesale('');
                  widget.session.setWholesaleCategory(
                    RetailerWholesaleCategory.all,
                  );
                },
              )
            else
              for (final product in widget.session.visibleWholesaleProducts) ...[
                _WholesaleProductCard(
                  product: product,
                  session: widget.session,
                ),
                const SizedBox(height: MoolSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _showScanner(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Scan wholesale product',
    detail: 'Camera permission is requested only when scanning begins.',
    children: [
      OutlinedButton.icon(
        key: const Key('wholesale-scan-denied'),
        onPressed: () {
          Navigator.pop(context);
          widget.session.cameraAllowed = false;
          widget.session.showNotice(
            'Camera access was not allowed. Search and product Add remain available.',
          );
        },
        icon: const Icon(Icons.no_photography_outlined),
        label: const Text('Continue without camera'),
      ),
      const SizedBox(height: MoolSpacing.xs),
      FilledButton.icon(
        key: const Key('wholesale-scan-success'),
        onPressed: () {
          Navigator.pop(context);
          widget.session.cameraAllowed = true;
          widget.session.searchWholesale('Tata Premium Tea');
          _search.text = 'Tata Premium Tea';
        },
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan test barcode'),
      ),
    ],
  );
}

class _WholesaleProductCard extends StatelessWidget {
  const _WholesaleProductCard({
    required this.product,
    required this.session,
  });

  final RetailerWholesaleProduct product;
  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    final quantity = session.wholesaleQuantity(product.id);
    return RetailerCard(
      keyName: 'wholesale-product-${product.id}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEEFF),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
                child: Text(
                  product.brand.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: const TextStyle(
                        color: MoolColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      product.pack,
                      style: const TextStyle(color: MoolColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('wholesale-product-details-${product.id}'),
                tooltip: 'View buying terms',
                onPressed: () => showWholesaleSheet(
                  context,
                  title: '${product.brand} ${product.name}',
                  detail: 'Complete buying and fulfilment terms.',
                  children: [
                    _SheetFact(
                      title: '${wholesaleMoney(product.casePrice)} per case',
                      detail: 'MOQ ${product.moq} cases',
                    ),
                    _SheetFact(
                      title: product.payment,
                      detail: 'Supplier payment',
                    ),
                    _SheetFact(
                      title: product.delivery,
                      detail: 'Committed delivery',
                    ),
                    const _SheetFact(
                      title: 'Supermandi Tech Pvt Ltd',
                      detail: 'Procurement invoice issuer',
                    ),
                    const _SheetFact(
                      title: 'Jodhpur area',
                      detail: 'Serviceable supply',
                    ),
                  ],
                ),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Wrap(
            spacing: MoolSpacing.xxs,
            runSpacing: MoolSpacing.xxs,
            children: [
              RetailerPill(label: 'MOQ ${product.moq}'),
              RetailerPill(label: product.delivery),
              RetailerPill(label: product.payment),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wholesaleMoney(product.casePrice),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      product.offer,
                      style: const TextStyle(
                        color: MoolColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (quantity == 0)
                SizedBox(
                  width: 130,
                  child: FilledButton(
                    key: Key('wholesale-add-${product.id}'),
                    onPressed: () =>
                        session.changeWholesaleQuantity(product.id, 1),
                    child: const Text('Add to cart'),
                  ),
                )
              else
                Row(
                  children: [
                    IconButton.outlined(
                      key: Key('wholesale-reduce-${product.id}'),
                      tooltip: 'Reduce ${product.name}',
                      onPressed: () =>
                          session.changeWholesaleQuantity(product.id, -1),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton.filled(
                      key: Key('wholesale-increase-${product.id}'),
                      tooltip: 'Add ${product.name}',
                      onPressed: () =>
                          session.changeWholesaleQuantity(product.id, 1),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class RetailerWholesaleCartScreen extends StatelessWidget {
  const RetailerWholesaleCartScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final products = reviewWholesaleProducts
            .where((product) => session.wholesaleQuantity(product.id) > 0)
            .toList(growable: false);
        return RetailerPageScaffold(
          session: session,
          title: 'Review wholesale order',
          subtitle: 'MOQ, delivery, GST and payment',
          activeDock: 'wholesale',
          returnRoute: '/app/retailer/wholesale',
          trailing: IconButton.outlined(
            key: const Key('wholesale-save-cart'),
            tooltip: 'Save wholesale cart',
            onPressed: () => session.showNotice(
              'Wholesale cart saved. Price, stock and delivery will be checked again before order.',
            ),
            icon: const Icon(Icons.bookmark_border_rounded),
          ),
          bottomAction: products.isEmpty
              ? null
              : FilledButton(
                  key: const Key('wholesale-review-order'),
                  onPressed: session.busy
                      ? null
                      : () => _reviewOrder(context),
                  child: Text(
                    'Review order · ${wholesaleMoney(session.wholesaleCartTotal)}',
                  ),
                ),
          body: products.isEmpty
              ? Center(
                  child: RetailerEmptyState(
                    keyName: 'wholesale-cart-empty',
                    title: 'Your wholesale cart is empty',
                    detail:
                        'Add cases from the area-matched wholesale catalogue.',
                    actionLabel: 'Browse wholesale products',
                    onAction: () =>
                        context.go('/app/retailer/wholesale'),
                  ),
                )
              : ListView(
                  key: const Key('wholesale-cart-screen'),
                  padding: const EdgeInsets.all(MoolSpacing.md),
                  children: [
                    RetailerSectionTitle(
                      title: 'Purchase order',
                      detail:
                          '${products.length} products · ${session.wholesaleCaseCount} cases',
                      trailing: const RetailerPill(
                        label: 'MOQ met',
                        icon: Icons.check_rounded,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    for (final product in products) ...[
                      RetailerCard(
                        keyName: 'wholesale-cart-${product.id}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${product.brand} ${product.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '${product.pack} · ${product.delivery}',
                                      ),
                                      Text(
                                        product.payment,
                                        style: const TextStyle(
                                          color: MoolColors.success,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  wholesaleMoney(
                                    product.casePrice *
                                        session.wholesaleQuantity(product.id),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: MoolSpacing.xs),
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      key: Key(
                                        'wholesale-cart-terms-${product.id}',
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: MoolSpacing.xxs,
                                        ),
                                        minimumSize: const Size(0, 48),
                                      ),
                                      onPressed: () => showWholesaleSheet(
                                        context,
                                        title: 'Price and terms',
                                        detail:
                                            '${product.brand} ${product.name}',
                                        children: [
                                          _SheetFact(
                                            title: wholesaleMoney(
                                              product.casePrice,
                                            ),
                                            detail: 'Locked case rate',
                                          ),
                                          _SheetFact(
                                            title: 'MOQ ${product.moq}',
                                            detail: 'Minimum cases',
                                          ),
                                          _SheetFact(
                                            title: product.delivery,
                                            detail: 'Delivery',
                                          ),
                                          _SheetFact(
                                            title: product.payment,
                                            detail: 'Payment',
                                          ),
                                        ],
                                      ),
                                      icon: const Icon(
                                        Icons.info_outline_rounded,
                                      ),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('Price & terms'),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton.outlined(
                                  key: Key(
                                    'wholesale-cart-reduce-${product.id}',
                                  ),
                                  onPressed: () =>
                                      session.changeWholesaleQuantity(
                                        product.id,
                                        -1,
                                      ),
                                  icon: const Icon(Icons.remove_rounded),
                                ),
                                SizedBox(
                                  width: 38,
                                  child: Text(
                                    '${session.wholesaleQuantity(product.id)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                IconButton.filled(
                                  key: Key(
                                    'wholesale-cart-increase-${product.id}',
                                  ),
                                  onPressed: () =>
                                      session.changeWholesaleQuantity(
                                        product.id,
                                        1,
                                      ),
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                    ],
                    const RetailerSectionTitle(
                      title: 'Delivery & GST details',
                      detail: 'Check before ordering',
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    RetailerCard(
                      keyName: 'wholesale-address',
                      onTap: () => showWholesaleSheet(
                        context,
                        title: 'Delivery address',
                        detail: 'Mahadev Fresh Mart',
                        children: const [
                          _SheetFact(
                            title: 'Paota, Jodhpur',
                            detail: 'Verified shop delivery address',
                          ),
                          _SheetFact(
                            title: 'Rakesh · +91 ••••• 93684',
                            detail: 'Receiving contact',
                          ),
                        ],
                      ),
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.location_on_outlined),
                        title: Text('Mahadev Fresh Mart'),
                        subtitle: Text('Paota, Jodhpur · delivery address'),
                        trailing: Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    RetailerCard(
                      keyName: 'wholesale-gst',
                      onTap: () => showWholesaleSheet(
                        context,
                        title: 'GST tax profile',
                        detail: 'Invoice details used for this purchase.',
                        children: const [
                          _SheetFact(
                            title: '08ABCDE1234F1Z5',
                            detail: 'Verified GSTIN',
                          ),
                          _SheetFact(
                            title: 'Rajasthan',
                            detail: 'Place of supply',
                          ),
                        ],
                      ),
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.receipt_long_outlined),
                        title: Text('GSTIN verified'),
                        subtitle: Text('GST tax invoice enabled'),
                        trailing: Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    RetailerCard(
                      color: const Color(0xFFEDEEFF),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment split',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: MoolSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: _SheetFact(
                                  title: wholesaleMoney(
                                    (session.wholesaleCartTotal * .15).round(),
                                  ),
                                  detail: 'Protected advance',
                                ),
                              ),
                              Expanded(
                                child: _SheetFact(
                                  title: wholesaleMoney(
                                    (session.wholesaleCartTotal * .85).round(),
                                  ),
                                  detail: 'After goods receipt',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _reviewOrder(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Place purchase orders?',
    detail:
        'Current price, stock, delivery and payment terms will be rechecked.',
    children: [
      _SheetFact(
        title: wholesaleMoney(session.wholesaleCartTotal),
        detail: '${session.wholesaleCaseCount} cases · supplier-wise orders',
      ),
      const _SheetFact(
        title: 'No silent substitution',
        detail: 'Any changed term requires your approval',
      ),
      const SizedBox(height: MoolSpacing.sm),
      FilledButton(
        key: const Key('wholesale-place-orders'),
        onPressed: session.busy
            ? null
            : () async {
                Navigator.pop(context);
                if (await session.placeWholesaleOrders() && context.mounted) {
                  context.go('/app/retailer/wholesale/orders/confirmed');
                }
              },
        child: const Text('Place purchase orders'),
      ),
      const SizedBox(height: MoolSpacing.xs),
      OutlinedButton(
        key: const Key('wholesale-cancel-place'),
        onPressed: () => Navigator.pop(context),
        child: const Text('Review again'),
      ),
    ],
  );
}

class RetailerWholesaleOrderConfirmedScreen extends StatelessWidget {
  const RetailerWholesaleOrderConfirmedScreen({
    required this.session,
    super.key,
  });

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Order confirmed',
        subtitle: 'Supplier-wise purchase orders',
        activeDock: 'wholesale',
        returnRoute: '/app/retailer/wholesale/cart',
        trailing: IconButton.outlined(
          key: const Key('wholesale-download-orders'),
          tooltip: 'Download purchase orders',
          onPressed: () => session.showNotice(
            'Purchase-order PDFs are ready for controlled download and sharing.',
          ),
          icon: const Icon(Icons.download_rounded),
        ),
        bottomAction: FilledButton(
          key: const Key('wholesale-track-orders'),
          onPressed: () =>
              context.go('/app/retailer/wholesale/orders/tracking'),
          child: const Text('Track orders'),
        ),
        body: ListView(
          key: const Key('wholesale-order-confirmed-screen'),
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            RetailerCard(
              color: const Color(0xFFEAF7E8),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: MoolColors.success,
                    size: 34,
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Protected advance secured',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'It is not released until accepted goods receipt.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            for (final order in session.purchaseOrders) ...[
              RetailerCard(
                keyName: 'purchase-order-${order.id}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.id,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const RetailerPill(label: 'CONFIRMED'),
                      ],
                    ),
                    Text('${order.supplier} · ${order.deliveryMode}'),
                    const SizedBox(height: MoolSpacing.sm),
                    Wrap(
                      spacing: MoolSpacing.md,
                      runSpacing: MoolSpacing.xs,
                      children: [
                        _SheetFact(
                          title: '${order.cases} cases',
                          detail: order.productName,
                        ),
                        _SheetFact(
                          title: wholesaleMoney(order.value),
                          detail: 'PO value',
                        ),
                        _SheetFact(
                          title: order.deliveryWindow,
                          detail: 'Delivery',
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: Key('purchase-order-view-${order.id}'),
                            onPressed: () => showWholesaleSheet(
                              context,
                              title: order.id,
                              detail: '${order.supplier} · purchase order',
                              children: [
                                _SheetFact(
                                  title: wholesaleMoney(order.value),
                                  detail: 'Purchase-order value',
                                ),
                                _SheetFact(
                                  title: order.paymentTerm,
                                  detail: 'Payment term',
                                ),
                                _SheetFact(
                                  title: order.deliveryWindow,
                                  detail: 'Committed delivery',
                                ),
                                const _SheetFact(
                                  title: 'Not added yet',
                                  detail: 'Retailer stock',
                                ),
                              ],
                            ),
                            child: const Text('View PO'),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: FilledButton(
                            key: Key('purchase-order-track-${order.id}'),
                            onPressed: () {
                              session.selectPurchaseOrder(order.id);
                              context.go(
                                '/app/retailer/wholesale/orders/tracking',
                              );
                            },
                            child: const Text('Track order'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
            ],
            const RetailerSectionTitle(
              title: 'What happens next',
              detail: 'Payment, invoice and stock remain separate',
            ),
            const SizedBox(height: MoolSpacing.sm),
            const RetailerCard(
              child: Column(
                children: [
                  _SheetFact(
                    title: 'Advance releases after accepted delivery',
                    detail: 'Shortage or damage keeps settlement protected',
                  ),
                  _SheetFact(
                    title: 'GST invoice on dispatch',
                    detail: 'A purchase order is not a tax invoice',
                  ),
                  _SheetFact(
                    title: 'Stock updates after receipt',
                    detail: 'Ordered cases are not available stock',
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

class _SheetFact extends StatelessWidget {
  const _SheetFact({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(
            detail,
            style: const TextStyle(color: MoolColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
