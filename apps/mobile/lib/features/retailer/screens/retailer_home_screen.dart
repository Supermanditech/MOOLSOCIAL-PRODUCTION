import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_models.dart';
import '../retailer_pos_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';

class RetailerHomeScreen extends StatefulWidget {
  const RetailerHomeScreen({
    required this.session,
    this.initialView = RetailerHomeView.home,
    super.key,
  });

  final RetailerSession session;
  final RetailerHomeView initialView;

  @override
  State<RetailerHomeScreen> createState() => _RetailerHomeScreenState();
}

class _RetailerHomeScreenState extends State<RetailerHomeScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.session.searchQuery,
  );
  final ScrollController _homeScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.session.view = widget.initialView;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.session.loadInitialStore();
    });
  }

  @override
  void didUpdateWidget(covariant RetailerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialView != widget.initialView) {
      widget.session.view = widget.initialView;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _homeScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final view = widget.session.view;
        return RetailerPageScaffold(
          session: widget.session,
          title: view == RetailerHomeView.home
              ? widget.session.shopName
              : view.label,
          subtitle: switch (view) {
            RetailerHomeView.home =>
              widget.session.shopArea.isEmpty
                  ? 'Verified shop'
                  : 'Verified shop · ${widget.session.shopArea}',
            RetailerHomeView.orders => 'Review and complete customer orders',
            RetailerHomeView.stock => 'Available consumer products',
            RetailerHomeView.wholesale => 'Business procurement stays separate',
          },
          showBack: false,
          activeDock: switch (view) {
            RetailerHomeView.orders => 'orders',
            RetailerHomeView.stock => 'stock',
            RetailerHomeView.wholesale => 'wholesale',
            RetailerHomeView.home => 'none',
          },
          returnRoute: '/app/retailer/home?view=${view.name}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                key: const Key('retailer-business-book'),
                tooltip: 'Open Business Book',
                onPressed: () => context.go('/app/retailer/books'),
                icon: const Icon(Icons.auto_stories_outlined),
              ),
              const SizedBox(width: MoolSpacing.xxs),
              IconButton.outlined(
                key: const Key('retailer-alerts'),
                tooltip: 'Open retailer alerts',
                onPressed: () => _showAlerts(context),
                icon: Badge(
                  label: Text('${widget.session.openOrderCount}'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ],
          ),
          body: switch (view) {
            RetailerHomeView.home => _buildHome(context),
            RetailerHomeView.orders => _buildOrders(context),
            RetailerHomeView.stock => _buildStock(context),
            RetailerHomeView.wholesale => _buildWholesale(context),
          },
        );
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return ListView(
      key: const Key('retailer-home-screen'),
      controller: _homeScroll,
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        RetailerCard(
          color: MoolColors.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.session.ordersOnline
                              ? 'Shop is live'
                              : 'Shop is paused',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Customers see only available products and approved fulfilment.',
                          style: TextStyle(
                            color: Color(0xFFD9DAFF),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const Key('retailer-orders-online'),
                    value: widget.session.ordersOnline,
                    activeThumbColor: MoolColors.orange,
                    onChanged: widget.session.busy
                        ? null
                        : widget.session.setOrdersOnline,
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              Text(
                widget.session.ordersOnline
                    ? 'New customer orders are on'
                    : 'New orders are paused',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        TextField(
          key: const Key('retailer-home-search'),
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: widget.session.search,
          decoration: InputDecoration(
            labelText: 'Order, product or customer',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty
                ? IconButton(
                    key: const Key('retailer-scan-barcode'),
                    tooltip: 'Scan barcode',
                    onPressed: () => widget.session.showNotice(
                      'Barcode scan is ready. Camera permission is requested only when scanning starts.',
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                  )
                : IconButton(
                    key: const Key('retailer-clear-search'),
                    tooltip: 'Clear search',
                    onPressed: () {
                      _search.clear();
                      widget.session.clearSearch();
                      _returnHomeListToTop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const RetailerSectionTitle(
          title: 'Needs action',
          detail: 'Paid orders and delivery promises first',
        ),
        const SizedBox(height: MoolSpacing.sm),
        for (final order
            in widget.session.filteredOrders
                .where((item) => item.stage != RetailerOrderStage.delivered)
                .take(1))
          _OrderCard(order: order, session: widget.session),
        if (widget.session.filteredOrders.isEmpty)
          RetailerEmptyState(
            keyName: 'retailer-home-empty',
            title: 'No matching shop activity',
            detail: 'Clear the search to see current orders and products.',
            actionLabel: 'Clear search',
            onAction: () {
              _search.clear();
              widget.session.clearSearch();
              _returnHomeListToTop();
            },
          ),
        const SizedBox(height: MoolSpacing.md),
        const RetailerSectionTitle(
          title: 'Run the shop',
          detail: 'Choose the exact task you want to finish',
        ),
        const SizedBox(height: MoolSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.65,
          mainAxisSpacing: MoolSpacing.xs,
          crossAxisSpacing: MoolSpacing.xs,
          children: [
            _QuickAction(
              keyName: 'retailer-open-orders',
              label: 'Review orders',
              icon: Icons.receipt_long_outlined,
              onTap: () {
                widget.session.setView(RetailerHomeView.orders);
                context.go('/app/retailer/orders');
              },
            ),
            _QuickAction(
              keyName: 'retailer-new-order',
              label: 'Create order',
              icon: Icons.add_shopping_cart_rounded,
              onTap: () => context.go('/app/retailer/orders/new'),
            ),
            _QuickAction(
              keyName: 'retailer-open-stock',
              label: 'Manage stock',
              icon: Icons.inventory_2_outlined,
              onTap: () {
                widget.session.setView(RetailerHomeView.stock);
                context.go('/app/retailer/home?view=stock');
              },
            ),
            _QuickAction(
              keyName: 'retailer-send-invoice',
              label: 'Send invoice',
              icon: Icons.send_to_mobile_outlined,
              onTap: () => context.go('/app/retailer/books/sales'),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.md),
        RetailerCard(
          onTap: () => context.go('/app/retailer/services'),
          keyName: 'retailer-business-services',
          color: const Color(0xFFFFF4E5),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: MoolColors.orange,
                foregroundColor: MoolColors.navy,
                child: Icon(Icons.auto_awesome_rounded),
              ),
              SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoolSocial Business Services',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Delivery, sales, tax, books and growth plans',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: RetailerCard(
                keyName: 'retailer-customers',
                onTap: () => context.go('/app/retailer/customers'),
                color: const Color(0xFFF4F3FF),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.people_alt_outlined, color: MoolColors.navy),
                    SizedBox(height: MoolSpacing.xs),
                    Text(
                      'Customers',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Baskets, dues and permission',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: MoolSpacing.sm),
            Expanded(
              child: RetailerCard(
                keyName: 'retailer-campaigns',
                onTap: () => context.go('/app/retailer/campaigns'),
                color: const Color(0xFFEAF7E8),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.campaign_outlined, color: MoolColors.success),
                    SizedBox(height: MoolSpacing.xs),
                    Text(
                      'Campaigns',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Stock-backed measured sales',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: RetailerCard(
                keyName: 'retailer-ai',
                onTap: () => context.go('/app/retailer?panel=ai'),
                color: const Color(0xFFF4F3FF),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: MoolColors.navy),
                    SizedBox(height: MoolSpacing.xs),
                    Text(
                      'Ask Mool AI',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Explain and prepare for approval',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: MoolSpacing.sm),
            Expanded(
              child: RetailerCard(
                keyName: 'retailer-settings',
                onTap: () => context.go('/app/retailer/settings'),
                color: const Color(0xFFFFF4E5),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFFB05C00)),
                    SizedBox(height: MoolSpacing.xs),
                    Text(
                      'Store settings',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Readiness, staff and customer rules',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _returnHomeListToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_homeScroll.hasClients) return;
      _homeScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildOrders(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.session.refreshOrders,
      child: ListView(
        key: const Key('retailer-orders-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          TextField(
            key: const Key('retailer-order-search'),
            controller: _search,
            onChanged: widget.session.search,
            decoration: InputDecoration(
              labelText: 'Search order, customer or product',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                key: const Key('retailer-refresh-orders'),
                tooltip: 'Refresh orders',
                onPressed: widget.session.busy
                    ? null
                    : widget.session.refreshOrders,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          RetailerSectionTitle(
            title: '${widget.session.filteredOrders.length} orders',
            detail: 'Payment and fulfilment remain visible before acceptance',
          ),
          const SizedBox(height: MoolSpacing.sm),
          if (widget.session.filteredOrders.isEmpty)
            RetailerEmptyState(
              keyName: 'retailer-orders-empty',
              title: 'No matching orders',
              detail: 'Try an order number, customer or product name.',
              actionLabel: 'Clear search',
              onAction: () {
                _search.clear();
                widget.session.clearSearch();
              },
            )
          else
            for (final order in widget.session.filteredOrders) ...[
              _OrderCard(order: order, session: widget.session),
              const SizedBox(height: MoolSpacing.sm),
            ],
        ],
      ),
    );
  }

  Widget _buildStock(BuildContext context) {
    return ListView(
      key: const Key('retailer-stock-preview-screen'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      children: [
        const RetailerSectionTitle(
          title: 'Available products',
          detail: 'Consumer quantities and household prices only',
        ),
        const SizedBox(height: MoolSpacing.sm),
        if (widget.session.catalogueProducts.isEmpty)
          RetailerEmptyState(
            keyName: 'retailer-stock-empty',
            title: widget.session.busy
                ? 'Loading products'
                : 'No available products',
            detail: widget.session.busy
                ? 'Checking the authoritative shop catalogue.'
                : 'Finish product setup or retry the shop refresh.',
            actionLabel: 'Retry',
            onAction: widget.session.loadInitialStore,
          )
        else
          for (final product in widget.session.catalogueProducts) ...[
            RetailerCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: product.stock > 0
                        ? const Color(0xFFEAF7E8)
                        : const Color(0xFFFFF4E5),
                    foregroundColor: product.stock > 0
                        ? MoolColors.success
                        : const Color(0xFFB05C00),
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${product.pack} · ${product.stock} available · ₹${product.price}',
                          style: const TextStyle(color: MoolColors.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: Key(
                      product.id == 'atta'
                          ? 'retailer-stock-review'
                          : 'retailer-stock-review-${product.id}',
                    ),
                    onPressed: () {
                      widget.session.showNotice(
                        'Stock review is open. Quantity and price change only after saving.',
                      );
                      _showProductEditor(context, product);
                    },
                    child: const Text('Review'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
          ],
        const SizedBox(height: MoolSpacing.sm),
        RetailerCard(
          keyName: 'retailer-slow-stock',
          color: const Color(0xFFFFF4E5),
          onTap: () =>
              context.go('/app/retailer/home?view=stock&panel=recovery'),
          child: const Row(
            children: [
              Icon(Icons.trending_down_rounded, color: Color(0xFFB05C00)),
              SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Move slow stock',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '18 products · protected floor and quantity',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showProductEditor(
    BuildContext context,
    RetailerPosProduct product,
  ) {
    final stock = TextEditingController(text: '${product.stock}');
    final buyPrice = TextEditingController();
    final sellPrice = TextEditingController(text: '${product.price}');
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          0,
          MoolSpacing.lg,
          MediaQuery.viewInsetsOf(sheetContext).bottom + MoolSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${product.pack} · ${product.sku}',
                style: const TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: MoolSpacing.md),
              TextField(
                key: const Key('retailer-edit-stock'),
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Available stock'),
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('retailer-edit-buy-price'),
                controller: buyPrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current purchase price ₹',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('retailer-edit-sell-price'),
                controller: sellPrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Customer price ₹',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              FilledButton(
                key: const Key('retailer-save-product'),
                onPressed: widget.session.busy
                    ? null
                    : () async {
                        final saved = await widget.session.saveCatalogueProduct(
                          productId: product.id,
                          stock: int.tryParse(stock.text) ?? -1,
                          buyPrice: int.tryParse(buyPrice.text) ?? 0,
                          sellPrice: int.tryParse(sellPrice.text) ?? 0,
                        );
                        if (saved && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                child: const Text('Save product'),
              ),
              TextButton(
                key: const Key('retailer-product-editor-cancel'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      stock.dispose();
      buyPrice.dispose();
      sellPrice.dispose();
    });
  }

  Widget _buildWholesale(BuildContext context) {
    return ListView(
      key: const Key('retailer-wholesale-preview-screen'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      children: [
        const RetailerSectionTitle(
          title: 'Wholesale Buy',
          detail: 'Business packs, MOQ and supplier terms stay out of Buy',
        ),
        const SizedBox(height: MoolSpacing.sm),
        RetailerCard(
          color: const Color(0xFFEDEEFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RetailerPill(
                label: 'Business procurement',
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: MoolSpacing.xs),
              const Text(
                'Compare verified wholesale cases',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'MOQ, landed cost, delivery promise and return rules appear before a purchase order.',
                style: TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: MoolSpacing.sm),
              OutlinedButton(
                key: const Key('retailer-wholesale-review'),
                onPressed: () => context.go('/app/retailer/wholesale'),
                child: const Text('Open Wholesale Buy'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAlerts(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.lg,
          ),
          child: Column(
            key: const Key('retailer-alert-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shop alerts',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final alert in retailerAlerts)
                ListTile(
                  leading: Icon(alert.icon, color: MoolColors.navy),
                  title: Text(
                    alert.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(alert.detail),
                ),
              FilledButton(
                key: const Key('retailer-alert-review-order'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  widget.session.openOrder('MS-2841');
                  context.go('/app/retailer/orders/MS-2841');
                },
                child: const Text('Review paid order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.session});

  final RetailerOrder order;
  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    final complete = order.stage == RetailerOrderStage.delivered;
    return RetailerCard(
      keyName: 'retailer-order-${order.id}',
      onTap: () {
        session.openOrder(order.id);
        context.go(
          complete
              ? '/app/retailer/orders/${order.id}/tracking'
              : '/app/retailer/orders/${order.id}',
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RetailerPill(
                label: order.stage.label,
                color: complete ? MoolColors.success : MoolColors.orange,
                icon: complete
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_rounded,
              ),
              const Spacer(),
              Text(
                order.id,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            order.customer,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${order.fulfilment} · ${order.deliveryPromise}',
            style: const TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.payment,
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MoolRadii.card),
        side: const BorderSide(color: MoolColors.line),
      ),
      child: InkWell(
        key: Key(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(MoolRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.sm),
          child: Row(
            children: [
              Icon(icon, color: MoolColors.navy),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
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
