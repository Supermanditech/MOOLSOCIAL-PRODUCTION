import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_session.dart';
import '../retailer_wholesale_models.dart';
import '../widgets/retailer_widgets.dart';
import 'retailer_wholesale_catalog_screens.dart';

class RetailerPurchaseBookScreen extends StatefulWidget {
  const RetailerPurchaseBookScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  State<RetailerPurchaseBookScreen> createState() =>
      _RetailerPurchaseBookScreenState();
}

class _RetailerPurchaseBookScreenState
    extends State<RetailerPurchaseBookScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.session.purchaseSearchQuery,
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
      builder: (context, _) {
        if (!widget.session.purchaseBookAuthorized) {
          return RetailerPageScaffold(
            session: widget.session,
            title: 'Purchase Book',
            subtitle: 'Owner or accountant access required',
            activeDock: 'wholesale',
            returnRoute: '/app/retailer/books',
            body: Center(
              child: RetailerEmptyState(
                keyName: 'purchase-book-role-denied',
                title: 'Financial records are protected',
                detail: 'Ask the shop owner to grant Purchase Book permission.',
                actionLabel: 'Return to shop',
                onAction: () => context.go('/app/retailer/home'),
              ),
            ),
          );
        }
        return RetailerPageScaffold(
          session: widget.session,
          title: 'Purchase Book',
          subtitle: 'Supplier bills, received stock and payments',
          activeDock: 'wholesale',
          returnRoute: '/app/retailer/books',
          trailing: IconButton.outlined(
            key: const Key('purchase-book-tools'),
            tooltip: 'Purchase Book tools',
            onPressed: () => _showTools(context),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          body: RefreshIndicator(
            key: const Key('purchase-book-refresh'),
            onRefresh: widget.session.refreshPurchaseBook,
            child: ListView(
              key: const Key('purchase-book-screen'),
              padding: const EdgeInsets.all(MoolSpacing.md),
              children: [
                RetailerSectionTitle(
                  title: 'Purchases',
                  detail: 'Accepted stock and supplier obligations',
                  trailing: SizedBox(
                    width: 104,
                    child: OutlinedButton(
                      key: const Key('purchase-period'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: MoolSpacing.xs,
                        ),
                      ),
                      onPressed: () => _showPeriod(context),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Jul 2026'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                SegmentedButton<RetailerPurchaseBookView>(
                  key: const Key('purchase-book-views'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: RetailerPurchaseBookView.purchases,
                      label: Text('Purchases'),
                    ),
                    ButtonSegment(
                      value: RetailerPurchaseBookView.payables,
                      label: Text('Payables'),
                    ),
                    ButtonSegment(
                      value: RetailerPurchaseBookView.returns,
                      label: Text('Returns'),
                    ),
                  ],
                  selected: {widget.session.purchaseBookView},
                  onSelectionChanged: (selection) =>
                      widget.session.setPurchaseBookView(selection.first),
                ),
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  keyName: 'purchase-actions',
                  color: const Color(0xFFFFF4E6),
                  onTap: () => _showAttention(context),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: MoolColors.orange,
                      ),
                      SizedBox(width: MoolSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '4 purchase actions need attention',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text('Payments · GST invoice · cost change'),
                          ],
                        ),
                      ),
                      Text(
                        'View',
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
                        key: const Key('purchase-search'),
                        controller: _search,
                        onChanged: widget.session.searchPurchases,
                        decoration: InputDecoration(
                          labelText: 'Supplier, PO or invoice',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  key: const Key('purchase-clear-search'),
                                  onPressed: () {
                                    _search.clear();
                                    widget.session.searchPurchases('');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    IconButton.filled(
                      key: const Key('purchase-add-bill'),
                      tooltip: 'Add supplier bill',
                      onPressed: () => _showAddBill(context),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in const [
                        ('all', 'All'),
                        ('platform', 'MoolSocial POs'),
                        ('direct', 'Direct bills'),
                        ('paid', 'Paid'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(
                            right: MoolSpacing.xxs,
                          ),
                          child: ChoiceChip(
                            key: Key('purchase-filter-${filter.$1}'),
                            label: Text(filter.$2),
                            selected:
                                widget.session.purchaseSourceFilter ==
                                filter.$1,
                            onSelected: (_) => widget.session
                                .setPurchaseSourceFilter(filter.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                if (widget.session.visiblePurchases.isEmpty)
                  RetailerEmptyState(
                    keyName: 'purchase-book-empty',
                    title: 'No purchases found',
                    detail:
                        'Clear search or choose Purchases and All to see records.',
                    actionLabel: 'Clear filters',
                    onAction: () {
                      _search.clear();
                      widget.session.searchPurchases('');
                      widget.session.setPurchaseBookView(
                        RetailerPurchaseBookView.purchases,
                      );
                      widget.session.setPurchaseSourceFilter('all');
                    },
                  )
                else
                  for (final purchase in widget.session.visiblePurchases) ...[
                    RetailerCard(
                      keyName: 'purchase-entry-${purchase.id}',
                      onTap: () => _showPurchase(context, purchase),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEEFF),
                              borderRadius: BorderRadius.circular(
                                MoolRadii.control,
                              ),
                            ),
                            child: Text(
                              purchase.supplier
                                  .split(' ')
                                  .take(2)
                                  .map((part) => part[0])
                                  .join(),
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
                                  purchase.supplier,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(purchase.summary),
                                Text(
                                  '${purchase.source} · ${purchase.invoiceId}',
                                  style: const TextStyle(
                                    color: MoolColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                wholesaleMoney(purchase.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                purchase.status.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      purchase.status.toLowerCase().contains(
                                        'paid',
                                      )
                                      ? MoolColors.success
                                      : MoolColors.orange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPeriod(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Choose accounting period',
    detail: 'Totals and exports use the selected period.',
    children: [
      for (final value in const [
        'Jul 2026',
        'Jun 2026',
        'This quarter',
        'Custom dates',
      ])
        ListTile(
          key: Key(
            'purchase-period-${value.toLowerCase().replaceAll(' ', '-')}',
          ),
          title: Text(value),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            widget.session.showNotice('$value purchase period selected.');
          },
        ),
    ],
  );

  Future<void> _showTools(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Purchase Book tools',
    detail: 'Reports and controlled sharing for the selected period.',
    children: [
      for (final tool in const [
        ('export', 'Export Purchase Book', 'PDF, Excel or CSV'),
        ('accountant', 'Share with accountant', 'Read-only period report'),
        ('gst', 'GST purchase summary', 'Eligible input and issues'),
        ('import', 'Import purchase bills', 'CSV or Excel with validation'),
      ])
        ListTile(
          key: Key('purchase-tool-${tool.$1}'),
          title: Text(tool.$2),
          subtitle: Text(tool.$3),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            switch (tool.$1) {
              case 'export':
                _showExport(context);
              case 'accountant':
                widget.session.showNotice(
                  'A read-only July Purchase Book link is ready for the accountant.',
                );
              case 'gst':
                widget.session.showNotice(
                  'GST purchase summary opened: ₹856 eligible input, one invoice needs correction.',
                );
              case 'import':
                _showAddBill(context);
            }
          },
        ),
    ],
  );

  Future<void> _showExport(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Export Purchase Book',
    detail: 'Choose a period-locked report format.',
    children: [
      for (final format in const ['PDF', 'Excel', 'CSV'])
        FilledButton.tonal(
          key: Key('purchase-export-${format.toLowerCase()}'),
          onPressed: widget.session.busy
              ? null
              : () async {
                  Navigator.pop(context);
                  await widget.session.exportPurchaseBook(format);
                },
          child: Text(format),
        ),
    ],
  );

  Future<void> _showAttention(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Purchase actions',
    detail: 'Resolve exceptions without searching every bill.',
    children: [
      ListTile(
        key: const Key('purchase-attention-due'),
        title: const Text('Supplier payments due'),
        subtitle: const Text('2 bills · next due 25 Jul'),
        trailing: const Badge(label: Text('2')),
        onTap: () {
          Navigator.pop(context);
          widget.session.setPurchaseBookView(RetailerPurchaseBookView.payables);
        },
      ),
      for (final item in const [
        ('gst', 'GST invoice needs correction'),
        ('cost', 'Purchase cost increased'),
        ('reconcile', 'Supplier statement mismatch'),
      ])
        ListTile(
          key: Key('purchase-attention-${item.$1}'),
          title: Text(item.$2),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            widget.session.showNotice('${item.$2} opened for review.');
          },
        ),
    ],
  );

  Future<void> _showAddBill(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Add supplier bill',
    detail: 'Retain the original invoice and review extracted values.',
    children: [
      FilledButton.tonalIcon(
        key: const Key('purchase-scan-invoice'),
        onPressed: () {
          Navigator.pop(context);
          _showExtractedBill(context, source: 'Camera scan');
        },
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan invoice'),
      ),
      FilledButton.tonalIcon(
        key: const Key('purchase-upload-invoice'),
        onPressed: () {
          Navigator.pop(context);
          _showExtractedBill(context, source: 'Uploaded photo');
        },
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Upload photo or PDF'),
      ),
      OutlinedButton.icon(
        key: const Key('purchase-enter-manually'),
        onPressed: () {
          Navigator.pop(context);
          widget.session.showNotice(
            'Manual supplier, invoice, items, tax, payment and received-quantity entry opened.',
          );
        },
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Enter manually'),
      ),
    ],
  );

  Future<void> _showExtractedBill(
    BuildContext context, {
    required String source,
  }) => showWholesaleSheet(
    context,
    title: 'Review extracted purchase',
    detail: '$source · original file retained',
    children: [
      const _PurchaseFact(
        title: 'Jodhpur Dairy Supply',
        detail: 'Supplier · GSTIN verified',
      ),
      const _PurchaseFact(
        title: 'INV-JDS-440 · 11 Jul 2026',
        detail: 'Invoice number and date',
      ),
      const _PurchaseFact(
        title: '₹6,480 · 6 lines',
        detail: 'Total and extracted products',
      ),
      const SizedBox(height: MoolSpacing.sm),
      FilledButton(
        key: const Key('purchase-confirm-extracted'),
        onPressed: () {
          Navigator.pop(context);
          widget.session.showNotice(
            'Purchase added with its original invoice. Stock still awaits received-quantity confirmation.',
          );
        },
        child: const Text('Confirm & add purchase'),
      ),
    ],
  );

  Future<void> _showPurchase(
    BuildContext context,
    RetailerPurchaseRecord purchase,
  ) {
    widget.session.selectPurchase(purchase.id);
    return showWholesaleSheet(
      context,
      title: purchase.supplier,
      detail: '${purchase.poId} · ${purchase.invoiceId}',
      children: [
        _PurchaseFact(
          title: wholesaleMoney(purchase.amount),
          detail: purchase.status,
        ),
        _PurchaseFact(title: purchase.summary, detail: purchase.source),
        _PurchaseFact(title: purchase.grnId, detail: 'Goods receipt / stock'),
        const SizedBox(height: MoolSpacing.sm),
        Wrap(
          spacing: MoolSpacing.xs,
          runSpacing: MoolSpacing.xs,
          children: [
            OutlinedButton(
              key: const Key('purchase-detail-reorder'),
              onPressed: () {
                Navigator.pop(context);
                widget.session.buildLowStockReorder();
                context.go('/app/retailer/wholesale/cart');
              },
              child: const Text('Reorder'),
            ),
            OutlinedButton(
              key: const Key('purchase-detail-return'),
              onPressed: () {
                Navigator.pop(context);
                widget.session.showNotice(
                  'Return flow opened for accepted goods with batch and photo evidence.',
                );
              },
              child: const Text('Return goods'),
            ),
            OutlinedButton(
              key: const Key('purchase-detail-invoice'),
              onPressed: () => widget.session.showNotice(
                'Original supplier invoice opened with reviewed extraction.',
              ),
              child: const Text('Invoice'),
            ),
            FilledButton(
              key: const Key('purchase-detail-pay'),
              onPressed: () {
                Navigator.pop(context);
                context.go('/app/retailer/supplier-bills/INV-RTD-665');
              },
              child: const Text('Open bill'),
            ),
          ],
        ),
      ],
    );
  }
}

class RetailerSupplierBillScreen extends StatelessWidget {
  const RetailerSupplierBillScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Bill & payment',
        subtitle: 'INV-RTD-665 · PO-MS-8178',
        activeDock: 'wholesale',
        returnRoute: '/app/retailer/books/purchases',
        trailing: IconButton.outlined(
          key: const Key('supplier-bill-tools'),
          tooltip: 'Supplier bill tools',
          onPressed: () => _showTools(context),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
        bottomAction: FilledButton(
          key: const Key('supplier-review-payment'),
          onPressed: session.busy ? null : () => _reviewPayment(context),
          child: const Text('Review payment · ₹2,568'),
        ),
        body: ListView(
          key: const Key('supplier-bill-screen'),
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            RetailerSectionTitle(
              title: 'Supplier bill',
              detail: 'Verified before money moves',
              trailing: const RetailerPill(label: 'DUE 25 JUL'),
            ),
            const SizedBox(height: MoolSpacing.sm),
            RetailerCard(
              keyName: 'supplier-detail',
              onTap: () => showWholesaleSheet(
                context,
                title: 'Rajasthan Tea Distribution',
                detail: 'Verified supplier relationship',
                children: const [
                  _PurchaseFact(title: '₹2,568', detail: 'Outstanding'),
                  _PurchaseFact(title: '15-day credit', detail: 'Payment term'),
                  _PurchaseFact(
                    title: '96% on time',
                    detail: 'Delivery performance',
                  ),
                  _PurchaseFact(
                    title: '08AABCR7781M1ZP',
                    detail: 'GSTIN · beneficiary verified',
                  ),
                ],
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('RT')),
                title: Text('Rajasthan Tea Distribution'),
                subtitle: Text('GSTIN verified · Jodhpur'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            RetailerCard(
              keyName: 'supplier-view-invoice',
              onTap: () => showWholesaleSheet(
                context,
                title: 'Tax invoice INV-RTD-665',
                detail: 'Original image and reviewed extraction',
                children: const [
                  _PurchaseFact(title: '₹2,568', detail: 'Invoice total'),
                  _PurchaseFact(title: '12 Jul 2026', detail: 'Invoice date'),
                  _PurchaseFact(
                    title: 'Original retained',
                    detail: 'GST extraction matched',
                  ),
                ],
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.receipt_long_outlined),
                title: Text('Tax invoice INV-RTD-665'),
                subtitle: Text('Original retained · GST matched'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Three-way match',
              detail: 'Purchase order, goods receipt and tax invoice',
            ),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                for (final item in const [
                  ('po', 'PO', '1 case'),
                  ('grn', 'GRN', '12 packs'),
                  ('gst', 'GST', 'Valid'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: MoolSpacing.xxs),
                      child: RetailerCard(
                        keyName: 'supplier-match-${item.$1}',
                        onTap: () => session.showNotice(
                          '${item.$2} is matched with no quantity or amount difference.',
                        ),
                        padding: const EdgeInsets.all(MoolSpacing.xs),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: MoolColors.success,
                            ),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(item.$3, style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            const RetailerCard(
              child: Column(
                children: [
                  _PurchaseFact(
                    title: '₹2,568',
                    detail: 'Outstanding supplier obligation',
                  ),
                  _PurchaseFact(
                    title: '25 Jul 2026',
                    detail: 'Due date · full payment',
                  ),
                  _PurchaseFact(
                    title: 'Verified beneficiary',
                    detail: 'Payment account',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            RetailerCard(
              color: const Color(0xFFEAF7E8),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: MoolColors.success),
                  const SizedBox(width: MoolSpacing.xs),
                  const Expanded(
                    child: Text(
                      'Bill is ready for payment',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    key: const Key('supplier-report-issue'),
                    onPressed: () => _showIssue(context),
                    child: const Text('Report issue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTools(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Bill tools',
    detail: 'Controls for this supplier obligation.',
    children: [
      for (final item in const [
        ('external', 'Record paid elsewhere'),
        ('reminder', 'Set payment reminder'),
        ('share', 'Share supplier bill'),
        ('download', 'Download invoice'),
      ])
        ListTile(
          key: Key('supplier-tool-${item.$1}'),
          title: Text(item.$2),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            session.showNotice(
              item.$1 == 'external'
                  ? 'External payment entry requires method, date, reference and evidence; no transfer was triggered.'
                  : '${item.$2} completed for INV-RTD-665.',
            );
          },
        ),
    ],
  );

  Future<void> _showIssue(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Report bill issue',
    detail: 'The affected obligation is held before payment.',
    children: [
      for (final issue in const [
        'Wrong amount',
        'Quantity mismatch',
        'GST issue',
        'Return goods',
      ])
        ListTile(
          key: Key(
            'supplier-issue-${issue.toLowerCase().replaceAll(' ', '-')}',
          ),
          title: Text(issue),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            session.showNotice(
              '$issue case opened. The affected supplier payment is on hold.',
            );
          },
        ),
    ],
  );

  Future<void> _reviewPayment(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Review supplier payment',
    detail: 'Authorize only after checking beneficiary, amount and bill.',
    children: [
      const _PurchaseFact(title: '₹2,568', detail: 'Full outstanding'),
      const _PurchaseFact(
        title: 'Rajasthan Tea Distribution',
        detail: 'Verified beneficiary',
      ),
      const _PurchaseFact(title: 'PO & GRN matched', detail: 'No open dispute'),
      const SizedBox(height: MoolSpacing.sm),
      SegmentedButton<RetailerSupplierPaymentMethod>(
        key: const Key('supplier-payment-method'),
        segments: const [
          ButtonSegment(
            value: RetailerSupplierPaymentMethod.upi,
            label: Text('UPI'),
          ),
          ButtonSegment(
            value: RetailerSupplierPaymentMethod.bankTransfer,
            label: Text('Bank transfer'),
          ),
        ],
        selected: {session.supplierPaymentMethod},
        onSelectionChanged: (selection) =>
            session.chooseSupplierPaymentMethod(selection.first),
      ),
      const SizedBox(height: MoolSpacing.sm),
      FilledButton(
        key: const Key('supplier-authorize-payment'),
        onPressed: session.busy
            ? null
            : () async {
                Navigator.pop(context);
                if (await session.authorizeSupplierPayment() &&
                    context.mounted) {
                  context.go(
                    '/app/retailer/supplier-payments/PAY-RTD-2568/status',
                  );
                }
              },
        child: const Text('Authorize ₹2,568'),
      ),
      const SizedBox(height: MoolSpacing.xs),
      OutlinedButton(
        key: const Key('supplier-cancel-payment'),
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
}

class RetailerSupplierPaymentStatusScreen extends StatelessWidget {
  const RetailerSupplierPaymentStatusScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final state = session.supplierPaymentState;
        return RetailerPageScaffold(
          session: session,
          title: 'Payment status',
          subtitle: 'PAY-RTD-2568 · INV-RTD-665',
          activeDock: 'wholesale',
          returnRoute: '/app/retailer/supplier-bills/INV-RTD-665',
          trailing: IconButton.outlined(
            key: const Key('supplier-payment-help'),
            tooltip: 'Payment help',
            onPressed: () => showWholesaleSheet(
              context,
              title: 'Payment status help',
              detail: 'Authorization and settlement are different events.',
              children: const [
                _PurchaseFact(
                  title: 'Processing',
                  detail: 'Do not authorize another payment',
                ),
                _PurchaseFact(
                  title: 'Paid',
                  detail: 'Only after partner settlement',
                ),
                _PurchaseFact(
                  title: 'Failed or reversed',
                  detail: 'Supplier bill becomes due again',
                ),
              ],
            ),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          bottomAction: state == RetailerSupplierPaymentState.settled
              ? FilledButton(
                  key: const Key('supplier-open-purchase-book'),
                  onPressed: () => context.go('/app/retailer/books/purchases'),
                  child: const Text('View Purchase Book'),
                )
              : FilledButton(
                  key: const Key('supplier-refresh-payment'),
                  onPressed: session.busy
                      ? null
                      : session.refreshSupplierPayment,
                  child: Text(
                    state == RetailerSupplierPaymentState.failed ||
                            state == RetailerSupplierPaymentState.reversed
                        ? 'Check latest status'
                        : 'Refresh status',
                  ),
                ),
          body: ListView(
            key: const Key('supplier-payment-status-screen'),
            padding: const EdgeInsets.all(MoolSpacing.md),
            children: [
              _PaymentStateCard(state: state),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Payment updates',
                detail: 'Verified and deduplicated partner events',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                child: Column(
                  children: [
                    const _PaymentEvent(
                      title: 'Authorized',
                      detail: 'Verified beneficiary · INV-RTD-665',
                      time: '9:41',
                      complete: true,
                    ),
                    _PaymentEvent(
                      title: switch (state) {
                        RetailerSupplierPaymentState.settled => 'Settled',
                        RetailerSupplierPaymentState.failed => 'Failed',
                        RetailerSupplierPaymentState.reversed => 'Reversed',
                        _ => 'Settlement confirmation',
                      },
                      detail: 'Payment partner event',
                      time: state == RetailerSupplierPaymentState.processing
                          ? 'Pending'
                          : '9:43',
                      complete:
                          state != RetailerSupplierPaymentState.processing,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Payment details',
                detail: 'Supplier bill remains linked',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                child: Column(
                  children: [
                    const _PurchaseFact(
                      title: 'PAY-RTD-2568',
                      detail: 'Payment reference',
                    ),
                    _PurchaseFact(
                      title: state == RetailerSupplierPaymentState.settled
                          ? 'UTR2407112568'
                          : 'Awaiting UTR',
                      detail: 'Bank reference',
                    ),
                    const _PurchaseFact(
                      title: 'PO-MS-8178 · GRN matched',
                      detail: 'Purchase and received quantity',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('supplier-status-view-bill'),
                      onPressed: () => context.go(
                        '/app/retailer/supplier-bills/INV-RTD-665',
                      ),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('View bill'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('supplier-status-receipt'),
                      onPressed: () => session.showNotice(
                        state == RetailerSupplierPaymentState.settled
                            ? 'Final payment receipt opened with UTR.'
                            : 'Payment acknowledgement opened. A final receipt is available only after settlement.',
                      ),
                      icon: const Icon(Icons.description_outlined),
                      label: Text(
                        state == RetailerSupplierPaymentState.settled
                            ? 'Receipt'
                            : 'Acknowledgement',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentStateCard extends StatelessWidget {
  const _PaymentStateCard({required this.state});

  final RetailerSupplierPaymentState state;

  @override
  Widget build(BuildContext context) {
    final (title, detail, icon, color) = switch (state) {
      RetailerSupplierPaymentState.settled => (
        'Payment settled',
        'Supplier balance and Purchase Book are updated.',
        Icons.check_circle_rounded,
        MoolColors.success,
      ),
      RetailerSupplierPaymentState.failed => (
        'Payment failed',
        'The supplier bill remains due. No settlement was recorded.',
        Icons.error_outline_rounded,
        const Color(0xFFB42318),
      ),
      RetailerSupplierPaymentState.reversed => (
        'Payment reversed',
        'The supplier obligation is due again with reversal evidence.',
        Icons.replay_circle_filled_rounded,
        MoolColors.orange,
      ),
      _ => (
        'Payment is processing',
        'Authorization was received. Do not pay again while settlement is pending.',
        Icons.hourglass_top_rounded,
        MoolColors.navy,
      ),
    };
    return RetailerCard(
      keyName: 'supplier-payment-state',
      color: color.withValues(alpha: .1),
      child: Row(
        children: [
          Icon(icon, color: color, size: 44),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(detail),
                const SizedBox(height: 4),
                const Text(
                  '₹2,568',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentEvent extends StatelessWidget {
  const _PaymentEvent({
    required this.title,
    required this.detail,
    required this.time,
    required this.complete,
  });

  final String title;
  final String detail;
  final String time;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        complete ? Icons.check_circle_rounded : Icons.more_horiz_rounded,
        color: complete ? MoolColors.success : MoolColors.muted,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(detail),
      trailing: Text(time),
    );
  }
}

class _PurchaseFact extends StatelessWidget {
  const _PurchaseFact({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Text(
              detail,
              textAlign: TextAlign.right,
              style: const TextStyle(color: MoolColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
