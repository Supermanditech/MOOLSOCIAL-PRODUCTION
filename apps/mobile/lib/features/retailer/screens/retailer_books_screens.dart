import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_books_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';
import 'retailer_wholesale_catalog_screens.dart';

class RetailerBusinessBookScreen extends StatelessWidget {
  const RetailerBusinessBookScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (!session.businessBookAuthorized) {
          return RetailerPageScaffold(
            session: session,
            title: 'Business Book',
            subtitle: 'Owner or accountant access required',
            activeDock: 'none',
            returnRoute: '/app/retailer/home',
            body: Center(
              child: RetailerEmptyState(
                keyName: 'business-book-role-denied',
                title: 'Business records are protected',
                detail: 'Ask the shop owner to grant Business Book permission.',
                actionLabel: 'Return to shop',
                onAction: () => context.go('/app/retailer/home'),
              ),
            ),
          );
        }
        return RetailerPageScaffold(
          session: session,
          title: 'Business Book',
          subtitle: 'Sales, purchases, stock and money',
          activeDock: 'none',
          returnRoute: '/app/retailer/home',
          trailing: IconButton.outlined(
            key: const Key('business-book-reports'),
            tooltip: 'Open money and reports',
            onPressed: () => _showReports(context),
            icon: const Icon(Icons.bar_chart_rounded),
          ),
          body: RefreshIndicator(
            key: const Key('business-book-refresh'),
            onRefresh: session.refreshBusinessBook,
            child: ListView(
              key: const Key('business-book-screen'),
              padding: const EdgeInsets.all(MoolSpacing.md),
              children: [
                RetailerSectionTitle(
                  title: 'Business position',
                  detail: 'Working estimate from approved records',
                  trailing: SizedBox(
                    width: 108,
                    child: OutlinedButton(
                      key: const Key('business-period'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: MoolSpacing.xs,
                        ),
                      ),
                      onPressed: () => _showPeriod(context),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(session.businessPeriod.label),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  keyName: 'business-position',
                  color: MoolColors.navy,
                  onTap: () => _showPosition(context),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED OPERATING PROFIT',
                        style: TextStyle(
                          color: Color(0xFFD9DAFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '₹87,300',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '18.1% of net sales · working estimate',
                        style: TextStyle(color: Color(0xFFD9DAFF)),
                      ),
                      SizedBox(height: MoolSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _BookFact(
                              title: '₹4.83L',
                              detail: 'Net sales',
                              light: true,
                            ),
                          ),
                          Expanded(
                            child: _BookFact(
                              title: '₹3.31L',
                              detail: 'Purchases',
                              light: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  color: const Color(0xFFEAF7E8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: MoolColors.success,
                      ),
                      const SizedBox(width: MoolSpacing.xs),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Money records matched',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text('Payments compared with sales and purchases'),
                          ],
                        ),
                      ),
                      RetailerPill(
                        label: '${session.openMoneyExceptions.length} LEFT',
                        color: MoolColors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  keyName: 'business-attention',
                  color: const Color(0xFFFFF4E6),
                  onTap: () => _showAttention(context),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: MoolColors.orange,
                        foregroundColor: Colors.white,
                        child: Text('${session.openMoneyExceptions.length}'),
                      ),
                      const SizedBox(width: MoolSpacing.xs),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Records need attention',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text('Payment, supplier invoice and customer due'),
                          ],
                        ),
                      ),
                      const Text(
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
                RetailerCard(
                  keyName: 'business-ask',
                  color: const Color(0xFFEDEEFF),
                  onTap: () => _showQuestions(context),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: MoolColors.navy,
                        foregroundColor: Colors.white,
                        child: Text('AI'),
                      ),
                      SizedBox(width: MoolSpacing.xs),
                      Expanded(
                        child: Text(
                          'Ask about sales, stock, dues or profit',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                const RetailerSectionTitle(
                  title: 'Your books',
                  detail: 'Open the authoritative detailed records',
                ),
                const SizedBox(height: MoolSpacing.sm),
                for (final book in <(String, String, String, String, IconData)>[
                  (
                    'sales',
                    'Sales Book',
                    'App, counter, phone and Chat sales',
                    '₹4,82,900 · 42 today',
                    Icons.receipt_long_outlined,
                  ),
                  (
                    'purchases',
                    'Purchase Book',
                    'Supplier bills, payments and returns',
                    '₹3,31,400 · 2 due',
                    Icons.shopping_bag_outlined,
                  ),
                  (
                    'stock',
                    'Stock Statement',
                    'Value, movements, checks and incoming stock',
                    '₹3,84,620 · 24 low',
                    Icons.inventory_2_outlined,
                  ),
                ]) ...[
                  RetailerCard(
                    keyName: 'business-open-${book.$1}',
                    onTap: () => context.go(switch (book.$1) {
                      'sales' => '/app/retailer/books/sales',
                      'purchases' => '/app/retailer/books/purchases',
                      _ => '/app/retailer/books/stock',
                    }),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(book.$5, color: MoolColors.navy),
                      title: Text(
                        book.$2,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(book.$3),
                      trailing: SizedBox(
                        width: 100,
                        child: Text(
                          book.$4,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                ],
                const RetailerSectionTitle(
                  title: 'Money position',
                  detail: 'Authoritative receipts and dues',
                ),
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  keyName: 'business-open-money',
                  onTap: () => context.go('/app/retailer/books/money'),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _BookFact(
                              title: '₹4,54,300',
                              detail: 'Customer payments received',
                            ),
                          ),
                          Expanded(
                            child: _BookFact(
                              title: '₹28,600',
                              detail: 'Customer payments due',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _BookFact(
                              title: '₹42,850',
                              detail: 'Supplier payments due',
                            ),
                          ),
                          Expanded(
                            child: _BookFact(
                              title: '₹31,400',
                              detail: 'Recorded expenses',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  keyName: 'business-tax-summary',
                  color: const Color(0xFFEDEEFF),
                  onTap: () => _showTax(context),
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('GST')),
                    title: Text(
                      'GST working summary',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      'Output ₹24,180 · Input ₹18,540 · not filed',
                    ),
                    trailing: Badge(label: Text('2 docs')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPeriod(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Business period',
    detail: 'Choose the records used by this business view.',
    children: [
      for (final period in RetailerBusinessPeriod.values)
        ListTile(
          key: Key('business-period-${period.name}'),
          title: Text(period.label),
          subtitle: Text(
            period == RetailerBusinessPeriod.custom
                ? 'Choose start and end dates'
                : 'Approved records for ${period.label.toLowerCase()}',
          ),
          trailing: session.businessPeriod == period
              ? const Icon(Icons.check_rounded)
              : const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            if (period == RetailerBusinessPeriod.custom) {
              _showCustomPeriod(context);
            } else {
              session.setBusinessPeriod(period);
            }
          },
        ),
    ],
  );

  Future<void> _showCustomPeriod(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => _CustomPeriodSheet(session: session),
      );

  Future<void> _showPosition(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Business position',
    detail: '${session.businessPeriod.label} · working estimate',
    children: const [
      _BookFact(title: '₹4,82,900', detail: 'Net sales'),
      _BookFact(title: '₹3,64,200', detail: 'Cost of goods sold'),
      _BookFact(title: '₹1,18,700', detail: 'Estimated gross margin'),
      _BookFact(title: '₹31,400', detail: 'Recorded expenses'),
      _BookFact(title: '₹87,300', detail: 'Estimated operating profit'),
      _BookFact(title: '18.1%', detail: 'Estimated profit rate'),
    ],
  );

  Future<void> _showAttention(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Needs attention',
    detail: 'Resolve only records that affect money or closing.',
    children: [
      ListTile(
        key: const Key('business-match-payment'),
        title: const Text('Match customer payment'),
        subtitle: const Text('₹1,240 bank transfer · PH-1182'),
        trailing: const Text('Match'),
        onTap: () {
          Navigator.pop(context);
          session.matchCustomerPayment();
        },
      ),
      ListTile(
        key: const Key('business-add-gst-invoice'),
        title: const Text('Add supplier GST invoice'),
        subtitle: const Text('2 accepted purchases missing documents'),
        trailing: const Text('Add'),
        onTap: () {
          Navigator.pop(context);
          context.go('/app/retailer/books/purchases');
        },
      ),
      ListTile(
        key: const Key('business-customer-due'),
        title: const Text('Customer payment due'),
        subtitle: const Text('₹5,600 due today across 3 customers'),
        trailing: const Text('Review'),
        onTap: () {
          Navigator.pop(context);
          context.go('/app/retailer/books/sales');
        },
      ),
    ],
  );

  Future<void> _showQuestions(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Ask Business Book',
    detail: 'Answers use current approved shop records.',
    children: [
      for (final question in const [
        ('collect', 'What should I collect today?'),
        ('margin', 'Which products made more margin?'),
        ('suppliers', 'What should I pay suppliers?'),
      ])
        ListTile(
          key: Key('business-question-${question.$1}'),
          title: Text(question.$2),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            session.showNotice(switch (question.$2) {
              'What should I collect today?' =>
                'Collect ₹3,200 from Sharma Stores first, followed by ₹1,500 and ₹900 dues.',
              'Which products made more margin?' =>
                'Packaged staples led posted margin. Open Sales Book for product evidence.',
              _ =>
                '₹18,400 is due now; ₹7,200 remains protected pending invoice review.',
            });
          },
        ),
    ],
  );

  Future<void> _showTax(BuildContext context) => showWholesaleSheet(
    context,
    title: 'GST working summary',
    detail: 'July 2026 · not a filed return or tax advice',
    children: const [
      _BookFact(title: '₹24,180', detail: 'Output GST'),
      _BookFact(title: '₹18,540', detail: 'Input GST'),
      _BookFact(title: '₹5,640', detail: 'Working difference'),
      _BookFact(title: '2 documents', detail: 'Missing supplier invoices'),
      _BookFact(title: '94%', detail: 'Records ready'),
      _BookFact(title: 'Not filed', detail: 'Current status'),
    ],
  );

  Future<void> _showReports(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Money and reports',
    detail: 'Open money control or create a period-locked report.',
    children: [
      ListTile(
        key: const Key('business-reports-open-money'),
        title: const Text('Open money control'),
        subtitle: const Text('Cash, bank, expenses and reconciliation'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.pop(context);
          context.go('/app/retailer/books/money');
        },
      ),
      for (final format in const ['PDF', 'CSV', 'Accountant link'])
        FilledButton.tonal(
          key: Key(
            'business-export-${format.toLowerCase().replaceAll(' ', '-')}',
          ),
          onPressed: session.busy
              ? null
              : () async {
                  Navigator.pop(context);
                  await session.exportBusinessBook(format);
                },
          child: Text('Create $format report'),
        ),
    ],
  );
}

class _CustomPeriodSheet extends StatefulWidget {
  const _CustomPeriodSheet({required this.session});

  final RetailerSession session;

  @override
  State<_CustomPeriodSheet> createState() => _CustomPeriodSheetState();
}

class _CustomPeriodSheetState extends State<_CustomPeriodSheet> {
  final start = TextEditingController();
  final end = TextEditingController();
  String? error;

  @override
  void dispose() {
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.md,
          0,
          MoolSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
        ),
        child: Column(
          key: const Key('custom-period-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a custom period',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const Text('Enter both dates before applying the period.'),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('custom-period-start'),
              controller: start,
              decoration: const InputDecoration(
                labelText: 'Start date · DD/MM/YYYY',
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            TextField(
              key: const Key('custom-period-end'),
              controller: end,
              decoration: const InputDecoration(
                labelText: 'End date · DD/MM/YYYY',
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: MoolSpacing.xs),
                child: Text(
                  error!,
                  key: const Key('custom-period-error'),
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            const SizedBox(height: MoolSpacing.sm),
            FilledButton(
              key: const Key('custom-period-apply'),
              onPressed: () {
                if (start.text.trim().isEmpty || end.text.trim().isEmpty) {
                  setState(() {
                    error = 'Choose both a start date and an end date.';
                  });
                  return;
                }
                widget.session.setBusinessPeriod(RetailerBusinessPeriod.custom);
                Navigator.pop(context);
              },
              child: const Text('Apply period'),
            ),
          ],
        ),
      ),
    );
  }
}

class RetailerStockStatementScreen extends StatefulWidget {
  const RetailerStockStatementScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  State<RetailerStockStatementScreen> createState() =>
      _RetailerStockStatementScreenState();
}

class _RetailerStockStatementScreenState
    extends State<RetailerStockStatementScreen> {
  late final TextEditingController search = TextEditingController(
    text: widget.session.stockSearchQuery,
  );

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => RetailerPageScaffold(
        session: widget.session,
        title: 'Stock Statement',
        subtitle: 'Every stock change with its source',
        activeDock: 'stock',
        returnRoute: '/app/retailer/books',
        trailing: IconButton.outlined(
          key: const Key('stock-statement-export'),
          tooltip: 'Export stock statement',
          onPressed: () => _showExport(context),
          icon: const Icon(Icons.ios_share_rounded),
        ),
        body: RefreshIndicator(
          key: const Key('stock-statement-refresh'),
          onRefresh: widget.session.refreshStockStatement,
          child: ListView(
            key: const Key('stock-statement-screen'),
            padding: const EdgeInsets.all(MoolSpacing.md),
            children: [
              const RetailerSectionTitle(
                title: 'Stock position',
                detail: 'Physical, reserved, available and incoming',
              ),
              const SizedBox(height: MoolSpacing.sm),
              const RetailerCard(
                color: MoolColors.navy,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _BookFact(
                            title: '₹3,84,620',
                            detail: 'Closing stock value',
                            light: true,
                          ),
                        ),
                        Expanded(
                          child: _BookFact(
                            title: '1,248',
                            detail: 'Physical units',
                            light: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _BookFact(
                            title: '1,186',
                            detail: 'Available to sell',
                            light: true,
                          ),
                        ),
                        Expanded(
                          child: _BookFact(
                            title: '18 cases',
                            detail: 'Incoming',
                            light: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'stock-review-checks',
                color: const Color(0xFFFFF4E6),
                onTap: () => widget.session.setStockStatementView(
                  RetailerStockStatementView.checks,
                ),
                child: const Row(
                  children: [
                    CircleAvatar(child: Text('12')),
                    SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock checks need action',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text('Mismatch, expiry and fast-selling items'),
                        ],
                      ),
                    ),
                    Text(
                      'Review',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              SegmentedButton<RetailerStockStatementView>(
                key: const Key('stock-statement-views'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: RetailerStockStatementView.movements,
                    label: Text('Movements'),
                  ),
                  ButtonSegment(
                    value: RetailerStockStatementView.checks,
                    label: Text('Stock checks'),
                  ),
                ],
                selected: {widget.session.stockStatementView},
                onSelectionChanged: (selection) =>
                    widget.session.setStockStatementView(selection.first),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('stock-statement-search'),
                      controller: search,
                      onChanged: widget.session.searchStockStatement,
                      decoration: InputDecoration(
                        labelText: 'Product, SKU, barcode or source',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: search.text.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('stock-statement-clear-search'),
                                onPressed: () {
                                  search.clear();
                                  widget.session.searchStockStatement('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  IconButton.filled(
                    key: const Key('stock-record-change'),
                    tooltip: 'Record stock change',
                    onPressed: () => _chooseAdjustment(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (widget.session.stockStatementView ==
                  RetailerStockStatementView.movements) ...[
                const SizedBox(height: MoolSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xxs),
                        child: ChoiceChip(
                          key: const Key('stock-filter-all'),
                          label: const Text('All'),
                          selected: widget.session.stockMovementFilter == null,
                          onSelected: (_) =>
                              widget.session.setStockMovementFilter(null),
                        ),
                      ),
                      for (final type in RetailerStockMovementType.values)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: MoolSpacing.xxs,
                          ),
                          child: ChoiceChip(
                            key: Key('stock-filter-${type.name}'),
                            label: Text(type.label),
                            selected:
                                widget.session.stockMovementFilter == type,
                            onSelected: (_) =>
                                widget.session.setStockMovementFilter(type),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                if (widget.session.visibleStockMovements.isEmpty)
                  _stockEmpty(context)
                else
                  for (final movement
                      in widget.session.visibleStockMovements) ...[
                    RetailerCard(
                      keyName: 'stock-movement-${movement.id}',
                      onTap: () => _showMovement(context, movement),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Icon(
                              movement.change > 0
                                  ? Icons.add_rounded
                                  : Icons.remove_rounded,
                            ),
                          ),
                          const SizedBox(width: MoolSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movement.product,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(movement.source),
                                Text(
                                  movement.reference,
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
                                '${movement.change > 0 ? '+' : ''}${movement.change}',
                                style: TextStyle(
                                  color: movement.change > 0
                                      ? MoolColors.success
                                      : MoolColors.orange,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${movement.balance} balance',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
              ] else ...[
                const SizedBox(height: MoolSpacing.md),
                if (widget.session.visibleStockChecks.isEmpty)
                  _stockEmpty(context)
                else
                  for (final check in widget.session.visibleStockChecks) ...[
                    RetailerCard(
                      keyName: 'stock-check-${check.id}',
                      onTap: () => _showCheck(context, check),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.fact_check_outlined,
                          color: MoolColors.orange,
                        ),
                        title: Text(
                          check.product,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(check.reason),
                        trailing: Text(
                          check.action,
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stockEmpty(BuildContext context) => RetailerEmptyState(
    keyName: 'stock-statement-empty',
    title: 'No stock record found',
    detail: 'Clear search and filters to see current stock history.',
    actionLabel: 'Clear filters',
    onAction: () {
      search.clear();
      widget.session.searchStockStatement('');
      widget.session.setStockMovementFilter(null);
    },
  );

  Future<void> _showMovement(
    BuildContext context,
    RetailerStockMovement movement,
  ) {
    widget.session.selectStockMovement(movement.id);
    return showWholesaleSheet(
      context,
      title: movement.product,
      detail: '${movement.source} · ${movement.reference}',
      children: [
        const _BookFact(title: '24', detail: 'Opening stock'),
        _BookFact(
          title: movement.type == RetailerStockMovementType.received
              ? '${movement.change}'
              : '0',
          detail: 'Received',
        ),
        _BookFact(
          title: movement.type == RetailerStockMovementType.sold
              ? '${movement.change.abs()}'
              : '0',
          detail: 'Sold',
        ),
        const _BookFact(title: '2', detail: 'Reserved'),
        _BookFact(title: '${movement.balance}', detail: 'Available to sell'),
        const _BookFact(title: '18 cases', detail: 'Incoming stock'),
      ],
    );
  }

  Future<void> _showCheck(
    BuildContext context,
    RetailerStockCheck check,
  ) => showWholesaleSheet(
    context,
    title: check.product,
    detail: check.reason,
    children: [
      ListTile(
        key: const Key('stock-check-count'),
        title: const Text('Record physical count'),
        subtitle: const Text('Counted quantity, reason and owner approval'),
        onTap: () {
          Navigator.pop(context);
          _openAdjustment(context, RetailerStockAdjustmentKind.physicalCount);
        },
      ),
      ListTile(
        key: const Key('stock-check-damage'),
        title: const Text('Damage or expiry'),
        subtitle: const Text('Move quantity out of sellable stock'),
        onTap: () {
          Navigator.pop(context);
          _openAdjustment(context, RetailerStockAdjustmentKind.damageOrExpiry);
        },
      ),
      ListTile(
        key: const Key('stock-check-track'),
        title: const Text('Track incoming stock'),
        subtitle: const Text('Open linked wholesale delivery'),
        onTap: () {
          Navigator.pop(context);
          context.go('/app/retailer/wholesale/orders/tracking');
        },
      ),
    ],
  );

  Future<void> _chooseAdjustment(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Record stock change',
    detail:
        'Use only when an automatic sale, receipt or return event is unavailable.',
    children: [
      for (final kind in RetailerStockAdjustmentKind.values)
        ListTile(
          key: Key('stock-adjust-${kind.name}'),
          title: Text(kind.label),
          subtitle: Text(
            kind == RetailerStockAdjustmentKind.physicalCount
                ? 'Correct quantity with reason and owner approval'
                : kind == RetailerStockAdjustmentKind.damageOrExpiry
                ? 'Record non-sellable quantity'
                : 'Link quantity to supplier and purchase',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            _openAdjustment(context, kind);
          },
        ),
      ListTile(
        key: const Key('stock-adjust-missing-sale'),
        title: const Text('Unrecorded counter sale'),
        subtitle: const Text(
          'Create the missing sale instead of a stock shortcut',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.pop(context);
          context.go('/app/retailer/orders/new?source=counter');
        },
      ),
    ],
  );

  Future<void> _openAdjustment(
    BuildContext context,
    RetailerStockAdjustmentKind kind,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        _StockAdjustmentSheet(session: widget.session, kind: kind),
  );

  Future<void> _showExport(BuildContext context) => showWholesaleSheet(
    context,
    title: 'Export Stock Statement',
    detail: 'Create a period-locked business record.',
    children: [
      for (final format in const ['PDF', 'CSV', 'Accountant link'])
        FilledButton.tonal(
          key: Key('stock-export-${format.toLowerCase().replaceAll(' ', '-')}'),
          onPressed: widget.session.busy
              ? null
              : () async {
                  Navigator.pop(context);
                  await widget.session.exportStockStatement(format);
                },
          child: Text(format),
        ),
    ],
  );
}

class _StockAdjustmentSheet extends StatefulWidget {
  const _StockAdjustmentSheet({required this.session, required this.kind});

  final RetailerSession session;
  final RetailerStockAdjustmentKind kind;

  @override
  State<_StockAdjustmentSheet> createState() => _StockAdjustmentSheetState();
}

class _StockAdjustmentSheetState extends State<_StockAdjustmentSheet> {
  final quantity = TextEditingController();
  final reason = TextEditingController();
  String? error;

  @override
  void dispose() {
    quantity.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.md,
          0,
          MoolSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
        ),
        child: Column(
          key: const Key('stock-adjustment-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.kind.label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Quantity, reason, operator and owner approval are audited.',
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('stock-adjustment-quantity'),
              controller: quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            TextField(
              key: const Key('stock-adjustment-reason'),
              controller: reason,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: MoolSpacing.xs),
                child: Text(
                  error!,
                  key: const Key('stock-adjustment-error'),
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            const SizedBox(height: MoolSpacing.sm),
            FilledButton(
              key: const Key('stock-adjustment-save'),
              onPressed: widget.session.busy
                  ? null
                  : () async {
                      final completed = await widget.session
                          .recordStockAdjustment(
                            kind: widget.kind,
                            quantity: int.tryParse(quantity.text.trim()) ?? 0,
                            reason: reason.text,
                          );
                      if (!context.mounted) return;
                      if (completed) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          error = widget.session.errorMessage;
                        });
                      }
                    },
              child: const Text('Review and save'),
            ),
          ],
        ),
      ),
    );
  }
}

class RetailerMoneyControlScreen extends StatelessWidget {
  const RetailerMoneyControlScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (!session.businessBookAuthorized) {
          return RetailerPageScaffold(
            session: session,
            title: 'Money control',
            subtitle: 'Owner permission required',
            activeDock: 'none',
            returnRoute: '/app/retailer/books',
            body: Center(
              child: RetailerEmptyState(
                keyName: 'money-role-denied',
                title: 'Money controls are protected',
                detail: 'Ask the shop owner to grant financial permission.',
                actionLabel: 'Return to Business Book',
                onAction: () => context.go('/app/retailer/books'),
              ),
            ),
          );
        }
        return RetailerPageScaffold(
          session: session,
          title: 'Money control',
          subtitle: 'Cash, bank, expenses and reconciliation',
          activeDock: 'none',
          returnRoute: '/app/retailer/books',
          trailing: IconButton.filled(
            key: const Key('money-add-expense'),
            tooltip: 'Add business expense',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (sheetContext) => _ExpenseSheet(session: session),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
          body: ListView(
            key: const Key('money-control-screen'),
            padding: const EdgeInsets.all(MoolSpacing.md),
            children: [
              const RetailerSectionTitle(
                title: 'Money position',
                detail: 'No duplicate entry for captured transactions',
              ),
              const SizedBox(height: MoolSpacing.sm),
              const RetailerCard(
                color: MoolColors.navy,
                child: Row(
                  children: [
                    Expanded(
                      child: _BookFact(
                        title: '₹4,54,300',
                        detail: 'Received this month',
                        light: true,
                      ),
                    ),
                    Expanded(
                      child: _BookFact(
                        title: '₹74,250',
                        detail: 'Payments due',
                        light: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Money received',
                detail: 'From Sales Book and payment events',
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final receipt in const [
                ('upi', 'UPI receipts', '₹1,08,540 gross · ₹1,07,920 settled'),
                ('cash', 'Cash sales', '₹68,420 · owner checked'),
                ('card', 'Card and bank receipts', '₹42,300 · net ₹41,660'),
              ]) ...[
                RetailerCard(
                  keyName: 'money-receipt-${receipt.$1}',
                  onTap: () => context.go('/app/retailer/books/sales'),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(receipt.$1.toUpperCase()),
                    ),
                    title: Text(
                      receipt.$2,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(receipt.$3),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
              ],
              const RetailerSectionTitle(
                title: 'Expenses and payments',
                detail: 'Recorded this month',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'money-view-expenses',
                onTap: () => showWholesaleSheet(
                  context,
                  title: 'Recorded shop expenses',
                  detail: 'Electricity, salary, delivery, repair and supplies',
                  children: [
                    const _BookFact(title: '₹31,400', detail: '42 records'),
                    _BookFact(
                      title: '${36 + session.expenses.length}',
                      detail: 'Bills attached',
                    ),
                    for (final expense in session.expenses)
                      _BookFact(
                        title: '₹${expense.amount} · ${expense.category}',
                        detail: expense.note,
                      ),
                  ],
                ),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.payments_outlined),
                  title: Text(
                    'Recorded shop expenses',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('₹31,400 · 42 records'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'money-supplier-payments',
                onTap: () => context.go('/app/retailer/books/purchases'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.shopping_bag_outlined),
                  title: Text(
                    'Supplier payments',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('₹3.08L paid · ₹42,850 due'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerSectionTitle(
                title: 'Needs reconciliation',
                detail: '${session.openMoneyExceptions.length} open exceptions',
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (session.openMoneyExceptions.isEmpty)
                const RetailerCard(
                  color: Color(0xFFEAF7E8),
                  child: Text(
                    'All visible money exceptions are resolved.',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                )
              else
                for (final exception in session.openMoneyExceptions) ...[
                  RetailerCard(
                    keyName: 'money-exception-${exception.id}',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: MoolColors.orange,
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exception.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(exception.detail),
                            ],
                          ),
                        ),
                        TextButton(
                          key: Key('money-resolve-${exception.id}'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(72, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: MoolSpacing.xs,
                            ),
                          ),
                          onPressed: () => _reviewException(context, exception),
                          child: Text(exception.action),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                ],
              const SizedBox(height: MoolSpacing.sm),
              const RetailerCard(
                color: Color(0xFFEAF7E8),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, color: MoolColors.success),
                    SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: Text(
                        'Sales, purchases and payments already completed in MoolSocial flow here automatically. Manual records retain evidence and operator.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
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

  Future<void> _reviewException(
    BuildContext context,
    RetailerMoneyException exception,
  ) => showWholesaleSheet(
    context,
    title: exception.title,
    detail: exception.detail,
    children: [
      const _BookFact(
        title: 'Source evidence retained',
        detail: 'Provider, counter or expense record',
      ),
      const _BookFact(
        title: 'Owner approval',
        detail: 'Required before resolution',
      ),
      const SizedBox(height: MoolSpacing.sm),
      FilledButton(
        key: const Key('money-confirm-resolution'),
        onPressed: session.busy
            ? null
            : () async {
                final completed = await session.resolveMoneyException(
                  exception.id,
                );
                if (completed && context.mounted) {
                  Navigator.pop(context);
                }
              },
        child: Text(exception.action),
      ),
    ],
  );
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.session});

  final RetailerSession session;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final amount = TextEditingController(text: '850');
  final note = TextEditingController(text: 'Packaging material');
  String method = 'Cash';
  String category = 'Shop expense';
  bool evidence = false;
  String? error;

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.md,
          0,
          MoolSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
        ),
        child: Column(
          key: const Key('expense-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add business expense',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Use only for a genuinely manual expense not already captured.',
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('expense-amount'),
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            DropdownButtonFormField<String>(
              key: const Key('expense-method'),
              initialValue: method,
              items: [
                for (final value in const ['Cash', 'UPI', 'Bank', 'Card'])
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: (value) => setState(() => method = value ?? method),
              decoration: const InputDecoration(labelText: 'Paid through'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            DropdownButtonFormField<String>(
              key: const Key('expense-category'),
              initialValue: category,
              items: [
                for (final value in const [
                  'Shop expense',
                  'Delivery',
                  'Electricity',
                  'Salary',
                  'Repair',
                  'Other',
                ])
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: (value) =>
                  setState(() => category = value ?? category),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            TextField(
              key: const Key('expense-note'),
              controller: note,
              decoration: const InputDecoration(labelText: 'Bill or note'),
            ),
            CheckboxListTile(
              key: const Key('expense-evidence'),
              contentPadding: EdgeInsets.zero,
              value: evidence,
              onChanged: (value) => setState(() => evidence = value ?? false),
              title: const Text('Bill or payment evidence attached'),
            ),
            if (error != null)
              Text(
                error!,
                key: const Key('expense-error'),
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            const SizedBox(height: MoolSpacing.sm),
            FilledButton(
              key: const Key('expense-save'),
              onPressed: widget.session.busy
                  ? null
                  : () async {
                      final completed = await widget.session
                          .saveBusinessExpense(
                            amount: int.tryParse(amount.text.trim()) ?? 0,
                            category: category,
                            note: note.text,
                            method: method,
                            evidenceAttached: evidence,
                          );
                      if (!context.mounted) return;
                      if (completed) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          error = widget.session.errorMessage;
                        });
                      }
                    },
              child: const Text('Save expense'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookFact extends StatelessWidget {
  const _BookFact({
    required this.title,
    required this.detail,
    this.light = false,
  });

  final String title;
  final String detail;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(MoolSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: light ? Colors.white : MoolColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              color: light ? const Color(0xFFD9DAFF) : MoolColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
