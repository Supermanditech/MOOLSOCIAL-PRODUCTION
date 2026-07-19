import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_models.dart';
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

  @override
  void initState() {
    super.initState();
    widget.session.view = widget.initialView;
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
              ? 'Mahadev Fresh Mart'
              : view.label,
          subtitle: switch (view) {
            RetailerHomeView.home => 'Verified shop · Sardarpura',
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
                onPressed: () => context.go('/app/retailer/books/sales'),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shop is live',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
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
            labelText: 'Search orders, products or customers',
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
          onTap: () => widget.session.showNotice(
            'Professional delivery, sales, tax and growth plans are ready for review. No plan starts without your approval.',
          ),
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
      ],
    );
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
        RetailerCard(
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF7E8),
                foregroundColor: MoolColors.success,
                child: Icon(Icons.inventory_2_outlined),
              ),
              const SizedBox(width: MoolSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aashirvaad Whole Wheat Atta',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '1 kg · 24 available · ₹55',
                      style: TextStyle(color: MoolColors.muted),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('retailer-stock-review'),
                onPressed: () => widget.session.showNotice(
                  'Stock review is open. Quantity, price and fulfilment changes require explicit saving.',
                ),
                child: const Text('Review'),
              ),
            ],
          ),
        ),
      ],
    );
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
