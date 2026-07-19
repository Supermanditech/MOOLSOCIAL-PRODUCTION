import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../manufacturer_models.dart';
import '../manufacturer_session.dart';
import '../widgets/manufacturer_widgets.dart';

class ManufacturerHomeScreen extends StatelessWidget {
  const ManufacturerHomeScreen({
    required this.session,
    this.initialView = ManufacturerHomeView.home,
    super.key,
  });

  final ManufacturerSession session;
  final ManufacturerHomeView initialView;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final view = initialView;
        return ManufacturerPageScaffold(
          session: session,
          title: 'Shakti Foods',
          subtitle: view == ManufacturerHomeView.home
              ? 'Manufacturer · Jodhpur'
              : 'Verified buyer orders',
          activeDock: view == ManufacturerHomeView.orders ? 'orders' : 'none',
          returnRoute: '/app/manufacturer',
          showBack: false,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                key: const Key('manufacturer-alerts'),
                tooltip: 'Open priority actions',
                onPressed: () => session.showNotice(
                  '6 orders, 2 dispatches and 4 input requirements need action.',
                ),
                icon: const Badge(
                  label: Text('4'),
                  child: Icon(Icons.notifications_none_rounded),
                ),
              ),
              const SizedBox(width: MoolSpacing.xxs),
              ManufacturerSupplyControl(
                live: session.supplyOn,
                onPressed: session.busy ? null : session.toggleSupply,
              ),
            ],
          ),
          body: view == ManufacturerHomeView.home
              ? _ManufacturerHome(session: session)
              : _ManufacturerOrders(session: session),
        );
      },
    );
  }
}

class _ManufacturerHome extends StatelessWidget {
  const _ManufacturerHome({required this.session});

  final ManufacturerSession session;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('manufacturer-home-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        ManufacturerSearch(
          session: session,
          hint: 'Search orders, stock or inputs',
          scan: () => _notice(
            context,
            'Scan business record',
            'Scan a product pack, invoice, LR or purchase document.',
          ),
          voice: () => session.setSearch('Sunflower Oil'),
        ),
        const SizedBox(height: MoolSpacing.sm),
        ManufacturerCard(
          keyName: 'manufacturer-classification',
          color: const Color(0xFFF4F3FF),
          onTap: () => context.go('/app/manufacturer/control?tab=settings'),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: MoolColors.navy,
                foregroundColor: Colors.white,
                child: Text(
                  'FMCG',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your verified business',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Edible oil, flour, tea and spices · HSN linked',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ManufacturerPill(label: 'VERIFIED'),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        ManufacturerCard(
          keyName: 'manufacturer-business-book',
          onTap: () => context.go('/app/manufacturer/books'),
          padding: const EdgeInsets.all(MoolSpacing.sm),
          child: const Row(
            children: [
              Icon(Icons.menu_book_outlined, color: MoolColors.navy),
              SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: _CompactMetric(label: 'Sales', value: '₹8.6L'),
              ),
              Expanded(
                child: _CompactMetric(label: 'Purchases', value: '₹3.2L'),
              ),
              Expanded(
                child: _CompactMetric(label: 'Receivable', value: '₹4.26L'),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const ManufacturerSectionTitle(
          title: 'Action required',
          detail: '4 live actions',
        ),
        const SizedBox(height: MoolSpacing.sm),
        ManufacturerCard(
          keyName: 'manufacturer-priority-order',
          color: const Color(0xFFFFF6E8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MoolColors.orange,
                    foregroundColor: MoolColors.navy,
                    child: Icon(Icons.receipt_long_outlined),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SO-4821 · ₹3.41L',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '240 cases · verified retailer pool',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ManufacturerPill(
                    label: '02:14 LEFT',
                    color: Color(0xFFB05C00),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              const Text(
                'Confirm available quantity and dispatch date. The same order creates the GST invoice and receivable.',
                style: TextStyle(color: MoolColors.muted, fontSize: 12),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('manufacturer-view-order'),
                      onPressed: () =>
                          context.go('/app/manufacturer/orders/review'),
                      child: const Text('View order'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: FilledButton(
                      key: const Key('manufacturer-confirm-quantity'),
                      onPressed: () =>
                          context.go('/app/manufacturer/orders/review'),
                      child: const Text('Confirm quantity'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const ManufacturerSectionTitle(
          title: 'Operate your business',
          detail: 'One connected workspace',
        ),
        const SizedBox(height: MoolSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: MoolSpacing.xs,
          crossAxisSpacing: MoolSpacing.xs,
          childAspectRatio: 2.2,
          children: [
            _HomeAction(
              keyName: 'manufacturer-add-products',
              icon: Icons.add_box_outlined,
              label: 'Add products',
              onTap: () =>
                  context.go('/app/manufacturer/catalogue?mode=master'),
            ),
            _HomeAction(
              keyName: 'manufacturer-update-stock',
              icon: Icons.inventory_2_outlined,
              label: 'Update stock',
              onTap: () => context.go('/app/manufacturer/catalogue'),
            ),
            _HomeAction(
              keyName: 'manufacturer-dispatch',
              icon: Icons.local_shipping_outlined,
              label: 'Dispatch',
              onTap: () => context.go('/app/manufacturer/dispatch'),
            ),
            _HomeAction(
              keyName: 'manufacturer-gst-invoice',
              icon: Icons.description_outlined,
              label: 'GST invoice',
              onTap: () => context.go('/app/manufacturer/books'),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        ManufacturerActionRow(
          keyName: 'manufacturer-services',
          icon: Icons.auto_awesome_rounded,
          title: 'MoolSocial Business Services',
          detail: 'Transport, sales, GST, books and campaigns',
          meta: 'See the price and expected result before you start',
          action: 'View',
          color: const Color(0xFFF4F3FF),
          onTap: () => context.go('/app/manufacturer/services'),
        ),
        const SizedBox(height: MoolSpacing.md),
        const ManufacturerSectionTitle(
          title: 'Demand and input matches',
          detail: 'Based on your catalogue',
        ),
        const SizedBox(height: MoolSpacing.sm),
        ManufacturerActionRow(
          keyName: 'manufacturer-demand-pool',
          icon: Icons.groups_2_outlined,
          title: '860 cases · retailer demand pool',
          detail: 'Sunflower Oil 1 L · Jodhpur + Jaipur',
          meta: '78% committed · closes 22 Jul',
          action: 'Review',
          onTap: () => context.go('/app/manufacturer/growth?tab=demand'),
        ),
        const SizedBox(height: MoolSpacing.xs),
        ManufacturerActionRow(
          keyName: 'manufacturer-input-matches',
          icon: Icons.factory_outlined,
          title: '4 confirmed input requirements',
          detail: 'Oil bulk, PET bottle, label and carton',
          meta: 'Matched from confirmed outputs',
          action: 'Buy',
          onTap: () => context.go('/app/manufacturer/purchases'),
        ),
      ],
    );
  }

  Future<void> _notice(BuildContext context, String title, String detail) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                Text(detail),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('manufacturer-sheet-done'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ManufacturerOrders extends StatelessWidget {
  const _ManufacturerOrders({required this.session});

  final ManufacturerSession session;

  @override
  Widget build(BuildContext context) {
    final orders = session.filteredOrders;
    return ListView(
      key: const Key('manufacturer-orders-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        Row(
          children: [
            const Expanded(
              child: ManufacturerSectionTitle(
                title: 'Orders',
                detail: 'Retailers · hotels · distributors',
              ),
            ),
            IconButton.outlined(
              key: const Key('manufacturer-export-orders'),
              tooltip: 'Export authorized orders',
              onPressed: () =>
                  session.showNotice('Order export is ready to share.'),
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        ManufacturerSearch(
          session: session,
          hint: 'Search buyer, order or product',
          voice: () => session.setSearch('Hotel'),
        ),
        const SizedBox(height: MoolSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                      'Need action',
                      'Retailers',
                      'Hotels',
                      'Restaurants',
                      'Distributors',
                    ]
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xs),
                        child: MoolSegment(
                          key: Key(
                            'manufacturer-order-filter-${filter.toLowerCase().replaceAll(' ', '-')}',
                          ),
                          label: filter,
                          selected: session.orderFilter == filter,
                          onPressed: () => session.setOrderFilter(filter),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        const Row(
          children: [
            Expanded(
              child: ManufacturerMetric(
                label: 'NEED ACTION',
                value: '6',
                detail: 'confirmed orders',
              ),
            ),
            SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: ManufacturerMetric(
                label: 'SALES ORDERS',
                value: '₹8.6L',
                detail: 'current period',
              ),
            ),
            SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: ManufacturerMetric(
                label: 'RECEIVABLE',
                value: '₹4.26L',
                detail: 'buyer ledger',
              ),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.md),
        if (orders.isEmpty)
          ManufacturerCard(
            keyName: 'manufacturer-orders-empty',
            color: const Color(0xFFF4F3FF),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, size: 34),
                const SizedBox(height: MoolSpacing.xs),
                const Text(
                  'No matching order',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                TextButton(
                  key: const Key('manufacturer-orders-clear'),
                  onPressed: session.clearSearch,
                  child: const Text('Show all orders'),
                ),
              ],
            ),
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
              child: ManufacturerActionRow(
                keyName: 'manufacturer-order-${order.id}',
                icon: Icons.receipt_long_outlined,
                title: '${order.id} · ${order.buyerType} · ₹${order.total}',
                detail: '${order.cases} cases · ${order.protection}',
                meta: order.due,
                action: order.id == 'SO-4807' ? 'Dispatch' : 'Review',
                onTap: () {
                  session.selectOrder(order.id);
                  context.go(
                    order.id == 'SO-4807'
                        ? '/app/manufacturer/dispatch'
                        : '/app/manufacturer/orders/review',
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class ManufacturerBusinessBookScreen extends StatelessWidget {
  const ManufacturerBusinessBookScreen({required this.session, super.key});

  final ManufacturerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => ManufacturerPageScaffold(
        session: session,
        title: 'Business Book',
        subtitle: 'Sales, purchases and receivables',
        activeDock: 'none',
        returnRoute: '/app/manufacturer',
        trailing: IconButton.outlined(
          key: const Key('manufacturer-book-period'),
          tooltip: 'Choose reporting period',
          onPressed: () => _periodSheet(context),
          icon: const Icon(Icons.calendar_month_outlined),
        ),
        body: ListView(
          key: const Key('manufacturer-book-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            ManufacturerCard(
              keyName: 'manufacturer-book-position',
              color: const Color(0xFFF4F3FF),
              onTap: session.toggleBookPosition,
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: MoolColors.navy,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      const SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.bookPeriod,
                              style: const TextStyle(
                                color: MoolColors.muted,
                                fontSize: 11,
                              ),
                            ),
                            const Text(
                              'Estimated operating position ₹2.42L',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        session.showBookPosition
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ],
                  ),
                  if (session.showBookPosition) ...[
                    const SizedBox(height: MoolSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: MoolSpacing.sm),
                    const Row(
                      children: [
                        Expanded(
                          child: _CompactMetric(
                            label: 'Money in',
                            value: '₹6.18L',
                          ),
                        ),
                        Expanded(
                          child: _CompactMetric(
                            label: 'Money out',
                            value: '₹3.76L',
                          ),
                        ),
                        Expanded(
                          child: _CompactMetric(
                            label: 'Protected',
                            value: '₹1.02L',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            ManufacturerCard(
              keyName: 'manufacturer-book-attention',
              color: const Color(0xFFFFF6E8),
              onTap: () => _detailSheet(
                context,
                'Records needing attention',
                '2 supplier documents and one receivable confirmation need action.',
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.notification_important_outlined,
                    color: Color(0xFFB05C00),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Text(
                      '3 records need attention before close',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    'Review',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const ManufacturerSectionTitle(
              title: 'Books',
              detail: 'No duplicate entry',
            ),
            const SizedBox(height: MoolSpacing.sm),
            ...reviewManufacturerBookRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                child: ManufacturerActionRow(
                  keyName: 'manufacturer-book-${row.id}',
                  icon: switch (row.id) {
                    'sales' => Icons.trending_up_rounded,
                    'purchases' => Icons.shopping_bag_outlined,
                    'receivables' => Icons.call_received_rounded,
                    _ => Icons.call_made_rounded,
                  },
                  title: row.label,
                  detail: row.detail,
                  meta: row.value,
                  action: 'Open',
                  onTap: () {
                    session.selectBook(row.id);
                    _detailSheet(
                      context,
                      row.label,
                      '${row.value} · ${row.detail}. Entries come from completed operating transactions.',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const ManufacturerSectionTitle(
              title: 'Money and records',
              detail: 'Role controlled',
            ),
            const SizedBox(height: MoolSpacing.sm),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: MoolSpacing.xs,
              crossAxisSpacing: MoolSpacing.xs,
              childAspectRatio: 2.4,
              children:
                  {
                        'cash': ('Cash & Bank', Icons.account_balance_outlined),
                        'expenses': ('Expenses', Icons.receipt_long_outlined),
                        'notes': ('Credit notes', Icons.note_alt_outlined),
                        'reconcile': ('Reconcile', Icons.rule_folder_outlined),
                        'documents': ('Documents', Icons.folder_copy_outlined),
                        'reports': ('Reports', Icons.analytics_outlined),
                      }.entries
                      .map(
                        (entry) => _HomeAction(
                          keyName: 'manufacturer-book-tool-${entry.key}',
                          icon: entry.value.$2,
                          label: entry.value.$1,
                          onTap: () => _detailSheet(
                            context,
                            entry.value.$1,
                            'Authorized ${entry.value.$1.toLowerCase()} records for ${session.bookPeriod}.',
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: MoolSpacing.sm),
            ManufacturerActionRow(
              keyName: 'manufacturer-book-tax',
              icon: Icons.verified_user_outlined,
              title: 'GST working estimate',
              detail: 'Not a filed return or audit opinion',
              meta: 'Qualified review required before filing',
              action: 'Review',
              onTap: () =>
                  context.go('/app/manufacturer/services?tab=services'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _periodSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('manufacturer-book-period-sheet'),
          mainAxisSize: MainAxisSize.min,
          children: ['Today', 'This week', 'This month', 'Quarter']
              .map(
                (period) => ListTile(
                  key: Key(
                    'manufacturer-book-period-${period.toLowerCase().replaceAll(' ', '-')}',
                  ),
                  title: Text(period),
                  trailing: session.bookPeriod == period
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    session.setBookPeriod(period);
                    Navigator.pop(sheetContext);
                  },
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

Future<void> _detailSheet(BuildContext context, String title, String detail) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('manufacturer-detail-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              Text(detail),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('manufacturer-detail-done'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ManufacturerCard(
    keyName: keyName,
    onTap: onTap,
    padding: const EdgeInsets.all(MoolSpacing.sm),
    child: Row(
      children: [
        Icon(icon, color: MoolColors.navy),
        const SizedBox(width: MoolSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: MoolColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, size: 18),
      ],
    ),
  );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: MoolColors.navy,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: MoolColors.muted, fontSize: 9),
      ),
    ],
  );
}
