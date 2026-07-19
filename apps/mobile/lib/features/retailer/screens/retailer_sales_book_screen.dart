import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_pos_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';

class RetailerSalesBookScreen extends StatefulWidget {
  const RetailerSalesBookScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  State<RetailerSalesBookScreen> createState() =>
      _RetailerSalesBookScreenState();
}

class _RetailerSalesBookScreenState extends State<RetailerSalesBookScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.session.salesSearchQuery,
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
        title: 'Sales Book',
        subtitle: 'Completed and open shop sales',
        activeDock: 'orders',
        returnRoute: '/app/retailer/books',
        trailing: IconButton.outlined(
          key: const Key('sales-book-export'),
          tooltip: 'Export Sales Book',
          onPressed: widget.session.businessBookAuthorized
              ? () => _showExport(context)
              : null,
          icon: const Icon(Icons.ios_share_rounded),
        ),
        body: widget.session.businessBookAuthorized
            ? _buildBook(context)
            : _buildUnauthorized(context),
      ),
    );
  }

  Widget _buildUnauthorized(BuildContext context) {
    return ListView(
      key: const Key('sales-book-unauthorized'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      children: [
        RetailerEmptyState(
          keyName: 'sales-book-permission-blocked',
          title: 'Sales Book access is restricted',
          detail:
              'Ask the shop owner to give this staff profile permission to view financial records.',
          actionLabel: 'Return to shop',
          onAction: () => context.go('/app/retailer/home'),
        ),
      ],
    );
  }

  Widget _buildBook(BuildContext context) {
    final visible = widget.session.visibleSales;
    return RefreshIndicator(
      onRefresh: widget.session.refreshSalesBook,
      child: ListView(
        key: const Key('sales-book-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: RetailerSectionTitle(
                  title: 'Sales Book',
                  detail: 'Every shop channel in one trusted record',
                ),
              ),
              OutlinedButton.icon(
                key: const Key('sales-book-period'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(92, 48),
                ),
                onPressed: () => _showPeriod(context),
                icon: const Icon(Icons.calendar_today_outlined, size: 17),
                label: const Text('Today'),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          SegmentedButton<RetailerSalesBookView>(
            key: const Key('sales-book-tabs'),
            segments: const [
              ButtonSegment(
                value: RetailerSalesBookView.sales,
                label: KeyedSubtree(
                  key: Key('sales-tab-sales'),
                  child: Text('Sales'),
                ),
              ),
              ButtonSegment(
                value: RetailerSalesBookView.payments,
                label: KeyedSubtree(
                  key: Key('sales-tab-payments'),
                  child: Text('Payments 2'),
                ),
              ),
              ButtonSegment(
                value: RetailerSalesBookView.returns,
                label: KeyedSubtree(
                  key: Key('sales-tab-returns'),
                  child: Text('Returns 1'),
                ),
              ),
            ],
            selected: {widget.session.salesBookView},
            showSelectedIcon: false,
            onSelectionChanged: (values) =>
                widget.session.setSalesBookView(values.first),
          ),
          const SizedBox(height: MoolSpacing.sm),
          RetailerCard(
            color: MoolColors.navy,
            child: Row(
              children: const [
                Expanded(
                  child: _OverviewMetric(value: '₹18,460', label: 'Net sales'),
                ),
                Expanded(
                  child: _OverviewMetric(value: '42', label: 'Sales'),
                ),
                Expanded(
                  child: _OverviewMetric(value: '₹1,480', label: 'Due'),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          RetailerCard(
            keyName: 'sales-book-attention',
            color: const Color(0xFFFFF4E5),
            onTap: widget.session.reviewPaymentAttention,
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: MoolColors.orange,
                  foregroundColor: MoolColors.navy,
                  child: Text(
                    '2',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments need matching',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'One bank transfer and one customer due',
                        style: TextStyle(color: MoolColors.muted, fontSize: 11),
                      ),
                    ],
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
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('sales-book-search'),
                  controller: _search,
                  onChanged: widget.session.searchSales,
                  decoration: InputDecoration(
                    labelText: 'Invoice, customer or order',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('sales-book-clear-search'),
                            tooltip: 'Clear sales search',
                            onPressed: () {
                              _search.clear();
                              widget.session.searchSales('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              IconButton.filled(
                key: const Key('sales-book-new-sale'),
                tooltip: 'Create sale',
                onPressed: () => _showNewSale(context),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  key: const Key('sales-filter-all'),
                  selected:
                      widget.session.salesSourceFilter == null &&
                      !widget.session.salesDueOnly,
                  onSelected: (_) => widget.session.setSalesSourceFilter(null),
                  label: const Text('All'),
                ),
                const SizedBox(width: MoolSpacing.xxs),
                for (final source in RetailerSaleSource.values) ...[
                  ChoiceChip(
                    key: Key('sales-filter-${source.name}'),
                    selected:
                        widget.session.salesSourceFilter == source &&
                        !widget.session.salesDueOnly,
                    onSelected: (_) =>
                        widget.session.setSalesSourceFilter(source),
                    label: Text(source.label),
                  ),
                  const SizedBox(width: MoolSpacing.xxs),
                ],
                ChoiceChip(
                  key: const Key('sales-filter-due'),
                  selected: widget.session.salesDueOnly,
                  onSelected: (_) =>
                      widget.session.setSalesSourceFilter(null, dueOnly: true),
                  label: const Text('Due'),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          RetailerSectionTitle(
            title: switch (widget.session.salesBookView) {
              RetailerSalesBookView.sales => 'Recent sales',
              RetailerSalesBookView.payments => 'Payment follow-up',
              RetailerSalesBookView.returns => 'Returns and refunds',
            },
            detail: '${visible.length} visible · tap for details',
          ),
          const SizedBox(height: MoolSpacing.xs),
          if (visible.isEmpty)
            RetailerEmptyState(
              keyName: 'sales-book-empty',
              title: 'No matching sales',
              detail:
                  'Clear search and source filters to see this Sales Book view.',
              actionLabel: 'Clear filters',
              onAction: () {
                _search.clear();
                widget.session.clearSalesFilters();
              },
            )
          else
            for (final sale in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                child: RetailerCard(
                  keyName: 'sales-row-${sale.invoiceId}',
                  padding: EdgeInsets.zero,
                  onTap: () => _showSale(context, sale),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _sourceColor(sale.source),
                      foregroundColor: Colors.white,
                      child: Text(
                        sale.source.mark,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(
                      sale.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '${sale.invoiceId} · ${sale.orderId}\n${sale.subtitle}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${sale.amount}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          sale.payment,
                          style: TextStyle(
                            color: sale.status == RetailerSaleStatus.due
                                ? const Color(0xFFB54708)
                                : sale.status == RetailerSaleStatus.returned
                                ? const Color(0xFFB42318)
                                : MoolColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: MoolSpacing.xs),
          OutlinedButton.icon(
            key: const Key('sales-book-refresh'),
            onPressed: widget.session.busy
                ? null
                : widget.session.refreshSalesBook,
            icon: widget.session.busy
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Sales Book'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPeriod(BuildContext context) => _sheet(
    context,
    keyName: 'sales-period-sheet',
    title: 'Today · 19 July 2026',
    detail: 'Completed, due and returned shop sales',
    child: GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      mainAxisSpacing: MoolSpacing.xs,
      crossAxisSpacing: MoolSpacing.xs,
      children: [
        _PeriodMetric(value: '₹18,460', label: 'Net sales'),
        _PeriodMetric(value: '42', label: 'Sales'),
        _PeriodMetric(value: '₹16,980', label: 'Collected'),
        _PeriodMetric(value: '₹1,480', label: 'Due'),
        _PeriodMetric(value: '₹2,860', label: 'Estimated margin'),
        _PeriodMetric(value: '1', label: 'Return'),
      ],
    ),
  );

  Future<void> _showNewSale(BuildContext context) => _sheet(
    context,
    keyName: 'sales-new-sale-sheet',
    title: 'Create sale',
    detail: 'Choose how this customer order started.',
    child: Column(
      children: [
        _RouteTile(
          keyName: 'sales-new-counter',
          icon: Icons.storefront_outlined,
          title: 'Counter sale',
          detail: 'Scan products and collect payment',
          onTap: () {
            Navigator.pop(context);
            context.go('/app/retailer/orders/new?source=counter');
          },
        ),
        _RouteTile(
          keyName: 'sales-new-phone',
          icon: Icons.phone_outlined,
          title: 'Phone order',
          detail: 'Select customer and arrange collection or delivery',
          onTap: () {
            Navigator.pop(context);
            context.go('/app/retailer/orders/new?source=phone');
          },
        ),
        _RouteTile(
          keyName: 'sales-new-chat',
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Chat order',
          detail: 'Create from the linked customer conversation',
          onTap: () {
            Navigator.pop(context);
            context.go('/app/retailer/orders/new?source=chat');
          },
        ),
      ],
    ),
  );

  Future<void> _showSale(BuildContext context, RetailerSaleRecord sale) {
    widget.session.selectSale(sale.invoiceId);
    return _sheet(
      context,
      keyName: 'sales-detail-sheet',
      title: sale.invoiceId,
      detail: '${sale.title} · ₹${sale.amount}',
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.15,
            mainAxisSpacing: MoolSpacing.xs,
            crossAxisSpacing: MoolSpacing.xs,
            children: [
              _PeriodMetric(value: sale.customer, label: 'Customer'),
              _PeriodMetric(value: sale.payment, label: 'Payment'),
              _PeriodMetric(value: sale.fulfilment, label: 'Handover'),
              _PeriodMetric(value: sale.stockPosting, label: 'Stock'),
              _PeriodMetric(value: sale.margin, label: 'Estimated margin'),
              _PeriodMetric(value: sale.orderId, label: 'Order'),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('sales-view-invoice'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showInvoice(context, sale);
                  },
                  child: const Text('View invoice'),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: FilledButton(
                  key: const Key('sales-share-receipt'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showShare(context, sale);
                  },
                  child: const Text('Share receipt'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showInvoice(BuildContext context, RetailerSaleRecord sale) =>
      _sheet(
        context,
        keyName: 'sales-invoice-sheet',
        title: 'Tax invoice',
        detail: '${sale.invoiceId} · original transaction record',
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.15,
          mainAxisSpacing: MoolSpacing.xs,
          crossAxisSpacing: MoolSpacing.xs,
          children: [
            _PeriodMetric(value: sale.invoiceId, label: 'Invoice'),
            _PeriodMetric(value: '₹${sale.amount}', label: 'Total'),
            const _PeriodMetric(value: 'GST-ready', label: 'Tax record'),
            _PeriodMetric(value: sale.payment, label: 'Settlement'),
          ],
        ),
      );

  Future<void> _showShare(
    BuildContext context,
    RetailerSaleRecord sale,
  ) => _sheet(
    context,
    keyName: 'sales-share-sheet',
    title: 'Share receipt',
    detail: 'Choose a permitted delivery channel.',
    child: Column(
      children: [
        _RouteTile(
          keyName: 'sales-share-chat',
          icon: Icons.chat_bubble_outline_rounded,
          title: 'MoolSocial Chat',
          detail: 'Linked receipt in the customer thread',
          onTap: () {
            Navigator.pop(context);
            context.go(
              Uri(
                path: '/app/chat/inbox',
                queryParameters: {'return': '/app/retailer/books/sales'},
              ).toString(),
            );
          },
        ),
        _RouteTile(
          keyName: 'sales-share-whatsapp',
          icon: Icons.send_outlined,
          title: 'WhatsApp',
          detail: 'Approved template or secure receipt link',
          onTap: () {
            Navigator.pop(context);
            widget.session.showNotice(
              '${sale.invoiceId} is ready for consent-approved WhatsApp delivery.',
            );
          },
        ),
        _RouteTile(
          keyName: 'sales-share-qr',
          icon: Icons.qr_code_rounded,
          title: 'QR or Print',
          detail: 'Counter receipt without app installation',
          onTap: () {
            Navigator.pop(context);
            widget.session.showNotice('${sale.invoiceId} receipt QR is ready.');
          },
        ),
      ],
    ),
  );

  Future<void> _showExport(BuildContext context) => _sheet(
    context,
    keyName: 'sales-export-sheet',
    title: 'Export Sales Book',
    detail: 'Create a period-locked business record.',
    child: Column(
      children: [
        _ExportTile(
          keyName: 'sales-export-statement',
          title: 'Sales statement',
          detail: 'Invoice, payment and return summary',
          onTap: () => _runExport(context, 'Sales statement'),
        ),
        _ExportTile(
          keyName: 'sales-export-gst',
          title: 'GST-ready export',
          detail: 'Taxable value and invoice register',
          onTap: () => _runExport(context, 'GST-ready export'),
        ),
        _ExportTile(
          keyName: 'sales-export-accountant',
          title: 'Share with accountant',
          detail: 'Role-controlled access with an audit trail',
          onTap: () => _runExport(context, 'Accountant access pack'),
        ),
      ],
    ),
  );

  Future<void> _runExport(BuildContext context, String format) async {
    final exported = await widget.session.exportSalesBook(format);
    if (exported && context.mounted) Navigator.pop(context);
  }

  Future<void> _sheet(
    BuildContext context, {
    required String keyName,
    required String title,
    required String detail,
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        child: Material(
          key: Key(keyName),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(MoolRadii.sheet),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            detail,
                            style: const TextStyle(
                              color: MoolColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('$keyName-close'),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _sourceColor(RetailerSaleSource source) => switch (source) {
    RetailerSaleSource.app => const Color(0xFF3C61D7),
    RetailerSaleSource.counter => MoolColors.navy,
    RetailerSaleSource.phone => const Color(0xFF9E5B00),
    RetailerSaleSource.chat => const Color(0xFF147A42),
  };
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD9DAFF), fontSize: 9),
        ),
      ],
    );
  }
}

class _PeriodMetric extends StatelessWidget {
  const _PeriodMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6FC),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: const Color(0x1F000080)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(color: MoolColors.muted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(keyName),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final String keyName;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(keyName),
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.description_outlined)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
