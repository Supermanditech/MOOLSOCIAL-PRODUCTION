import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import '../../shared/commerce/commerce_downloads.dart';
import 'work_invoice_pdf.dart';
import 'work_session.dart';
import 'work_models.dart';
import 'work_stock_export.dart';
import 'screens/store_add_product_sheet.dart' show StoreRecentSearches;

/// A read-only report of saved invoices, not a tax return or audited accounts.
/// The caller supplies the entire scoped register, never its search results.
class StoreSalesStatement {
  StoreSalesStatement({
    required this.accountId,
    required this.storeId,
    required this.storeName,
    required this.from,
    required this.until,
    required this.generatedAt,
    required List<WorkspaceCustomerInvoice> invoices,
    this.finance,
    this.reviewOnly = false,
  }) : invoices = List.unmodifiable(invoices) {
    if (accountId.trim().isEmpty ||
        storeId.trim().isEmpty ||
        !from.isBefore(until) ||
        from.isAfter(generatedAt) ||
        invoices.any(
          (i) =>
              !i.validBillAmounts ||
              i.id.trim().isEmpty ||
              i.orderId.trim().isEmpty ||
              i.issuedAt.isAfter(generatedAt) ||
              (i.seller != null &&
                  (!i.seller!.valid || i.seller!.storeId != storeId)),
        ) ||
        invoices.map((i) => i.id).toSet().length != invoices.length ||
        invoices.map((i) => i.orderId).toSet().length != invoices.length) {
      throw const FormatException(
        'Sales records need reconciliation before export.',
      );
    }
  }
  final String accountId, storeId, storeName;
  final DateTime from, until, generatedAt;
  final List<WorkspaceCustomerInvoice> invoices;
  final WorkspaceFinanceSnapshot? finance;
  final bool reviewOnly;
  static const disclosure =
      'Supporting business records only. Not a bank statement, filed GST return or audited financial statement.';
  bool inPeriod(DateTime date) => !date.isBefore(from) && date.isBefore(until);
  List<WorkspaceCustomerInvoice> get selected =>
      invoices.where((i) => inPeriod(i.issuedAt)).toList()..sort((a, b) {
        final date = a.issuedAt.compareTo(b.issuedAt);
        return date == 0 ? a.id.compareTo(b.id) : date;
      });
  int get billedMinor => selected.fold(0, (sum, i) => sum + i.payableMinor);
  int get discountMinor => selected.fold(0, (sum, i) => sum + i.discountMinor);
  bool get financeReady =>
      finance != null &&
      finance!.valid &&
      finance!.accountScope == accountId &&
      finance!.workspaceId == storeId &&
      !finance!.asOf.isAfter(generatedAt);
  // Even a complete current snapshot does not prove historical receipt coverage.
  // Report only supplied posted entries and label this limitation explicitly.
  int? recorded(WorkspaceLedgerEntryKind kind) =>
      !financeReady || finance!.asOf.isBefore(from) || finance!.customerLedgers.isEmpty
      ? null
      : finance!.customerLedgers
            .expand((l) => l.entries)
            .where(
              (e) =>
                  e.kind == kind &&
                  e.state == WorkspaceLedgerPostingState.posted &&
                  inPeriod(e.occurredAt),
            )
            .fold<int>(0, (sum, e) => sum + e.amountMinor);
  // Use adjustment dates, not invoice dates: a return can follow an earlier sale.
  List<({String customer, WorkspaceCustomerLedgerEntry entry})>
  get adjustments {
    if (!financeReady || finance!.asOf.isBefore(from)) return [];
    final result = [
      for (final ledger in finance!.customerLedgers)
        for (final entry in ledger.entries)
          if (entry.state == WorkspaceLedgerPostingState.posted &&
              inPeriod(entry.occurredAt) &&
              (entry.kind == WorkspaceLedgerEntryKind.creditNote ||
                  entry.kind == WorkspaceLedgerEntryKind.refund ||
                  entry.kind == WorkspaceLedgerEntryKind.creditUsed ||
                  entry.kind == WorkspaceLedgerEntryKind.creditReceived))
            (customer: ledger.customerName, entry: entry),
    ];
    result.sort((a, b) {
      final date = a.entry.occurredAt.compareTo(b.entry.occurredAt);
      return date == 0 ? a.entry.id.compareTo(b.entry.id) : date;
    });
    return result;
  }
  static String date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String get period =>
      '${date(from)} to ${date(until.subtract(const Duration(microseconds: 1)))}';
  String get reference => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            accountId,
            storeId,
            from.toIso8601String(),
            until.toIso8601String(),
            generatedAt.toIso8601String(),
            finance?.revision,
            for (final i in selected) i.toLedgerJson(),
            for (final adjustment in adjustments)
              [adjustment.customer, adjustment.entry.identityData.toString()],
          ]),
        ),
      )
      .toString()
      .substring(0, 16)
      .toUpperCase();
  StoreTabularReport get report {
    final detail = adjustments;
    final monthly = <String, List<int>>{};
    for (final i in selected) {
      final key = date(i.issuedAt.toLocal()).substring(0, 7);
      final values = monthly.putIfAbsent(key, () => [0, 0, 0]);
      values[0]++;
      values[1] += i.discountMinor;
      values[2] += i.payableMinor;
    }
    String amount(int? minor) => minor == null
        ? 'Unavailable'
        : 'INR ${(minor / 100).toStringAsFixed(2)}';
    final sellers = selected
        .where((i) => i.seller != null)
        .map((i) => i.seller!)
        .toList();
    final addresses = sellers
        .map((s) => s.invoiceAddress)
        .where((s) => s.trim().isNotEmpty)
        .toSet();
    final names = sellers
        .map((s) => s.legalName)
        .where((s) => s.trim().isNotEmpty)
        .toSet();
    return StoreTabularReport(
      title: 'Sales & Collections',
      disclosure: disclosure,
      summary: [
        if (reviewOnly)
          [
            'Evaluation only',
            'Test/review environment. Not for submission to banks or authorities.',
          ],
        ['Business', storeName],
        [
          'Legal name at issue',
          names.length == 1
              ? names.single
              : 'See invoice originals; unavailable or varying identities',
        ],
        [
          'Address at issue',
          addresses.length == 1
              ? addresses.single
              : 'See invoice originals; unavailable or varying addresses',
        ],
        ['Seller GSTIN', 'Unavailable in saved seller records'],
        ['Period (phone local dates)', period],
        ['Generated', generatedAt.toIso8601String()],
        ['Ledger records as of', financeReady ? finance!.asOf.toIso8601String() : 'Unavailable'],
        ['Recorded invoices', '${selected.length}'],
        ['Invoice totals after discount', amount(billedMinor)],
        ['Recorded discounts', amount(discountMinor)],
        [
          'Sales excluding GST / taxable / exempt values / GST',
          'Unavailable: saved invoices do not contain a verified tax breakdown',
        ],
        [
          'Recorded collections in period',
          amount(recorded(WorkspaceLedgerEntryKind.collection)),
        ],
        [
          'Recorded credit notes in period',
          amount(recorded(WorkspaceLedgerEntryKind.creditNote)),
        ],
        [
          'Recorded refunds in period',
          amount(recorded(WorkspaceLedgerEntryKind.refund)),
        ],
        if (detail.any((a) => a.entry.kind == WorkspaceLedgerEntryKind.creditReceived))
          ['Customer credit applied (non-cash)', amount(recorded(WorkspaceLedgerEntryKind.creditReceived))],
        [
          'Customer dues (current snapshot, not period closing)',
          financeReady && finance!.historyComplete
              ? '${amount(finance!.duesMinor)} as of ${finance!.asOf.toIso8601String()}'
              : 'Unavailable',
        ],
        [
          'Coverage',
          'Saved Store invoices and supplied ledger entries only. Full business, receipt and adjustment history is not certified complete. No tax or missing balances inferred.',
        ],
        [
          'Accounting treatment',
          'Collections are not sales. Credits and refunds remain separate; consult original vouchers before calculating net sales.',
        ],
        if (detail.isNotEmpty)
          [
            'Adjustment detail',
            'By adjustment date, including earlier invoices. Blank amounts are not applicable. Recorded refunds do not confirm a money transfer.',
          ],
        for (final entry in monthly.entries)
          [
            'Monthly sales · ${entry.key}',
            '${entry.value[0]} invoices · Discounts ${amount(entry.value[1])} · Total ${amount(entry.value[2])}',
          ],
      ],
      metadata: [
        ['Sales & Collections Statement', storeName],
        ['Reference', reference],
        ['Period', period],
        if (reviewOnly) ['EVALUATION ONLY', 'Not for financial submission'],
      ],
      headers: [
        'Date',
        'Invoice number',
        'Customer',
        'Discount (INR)',
        'Invoice total (INR)',
        'Taxable / exempt / GST',
        'Order reference',
        if (detail.isNotEmpty) ...[
          'Entry type',
          'Return reason',
          'Credit (INR)',
          'Refund recorded (INR)',
          'Adjustment reference',
          'Customer credit allocation (INR)',
        ],
      ],
      rows: [
        for (final i in selected)
          [
            date(i.issuedAt.toLocal()),
            i.id,
            i.customer,
            i.discountMinor / 100,
            i.payableMinor / 100,
            null,
            i.orderId,
            if (detail.isNotEmpty) ...['Invoice', '', '', '', '', ''],
          ],
        for (final adjustment in detail)
          [
            date(adjustment.entry.occurredAt.toLocal()),
            adjustment.entry.invoiceId,
            adjustment.customer,
            '',
            '',
            '',
            adjustment.entry.orderId,
            adjustment.entry.kind == WorkspaceLedgerEntryKind.refund ? 'Refund recorded'
                : StoreCustomerStatement.particulars(adjustment.entry.kind),
            adjustment.entry.kind == WorkspaceLedgerEntryKind.creditNote
                ? adjustment.entry.customerReturn?.reason
                : adjustment.entry.kind == WorkspaceLedgerEntryKind.refund
                    ? 'Not linked to a specific return' : 'Non-cash invoice allocation',
            adjustment.entry.kind == WorkspaceLedgerEntryKind.creditNote
                ? adjustment.entry.amountMinor / 100
                : '',
            adjustment.entry.kind == WorkspaceLedgerEntryKind.refund
                ? adjustment.entry.amountMinor / 100
                : '',
            adjustment.entry.id,
            adjustment.entry.kind == WorkspaceLedgerEntryKind.creditUsed ||
                adjustment.entry.kind == WorkspaceLedgerEntryKind.creditReceived
                ? adjustment.entry.amountMinor / 100 : '',
          ],
      ],
      moneyColumns: {3, 4, if (detail.isNotEmpty) ...{9, 10, 12}},
      pdfGroups: [
        StoreReportPdfGroup('Invoices',
            [0, 1, 2, 3, 4, 5, 6, if (detail.isNotEmpty) 7],
            List<int>.generate(selected.length, (i) => i)),
        if (detail.isNotEmpty) ...[
          StoreReportPdfGroup('Returns and recorded refunds',
              [0, 1, 2, 6, 7, 8, 9, 10, 11], [
                for (var i = 0; i < detail.length; i++)
                  if (detail[i].entry.kind == WorkspaceLedgerEntryKind.creditNote ||
                      detail[i].entry.kind == WorkspaceLedgerEntryKind.refund)
                    selected.length + i,
              ]),
          StoreReportPdfGroup('Customer credit allocations - non-cash',
              [0, 1, 2, 6, 7, 8, 11, 12], [
                for (var i = 0; i < detail.length; i++)
                  if (detail[i].entry.kind == WorkspaceLedgerEntryKind.creditUsed ||
                      detail[i].entry.kind == WorkspaceLedgerEntryKind.creditReceived)
                    selected.length + i,
              ]),
        ],
      ],
    );
  }
}

/// Read-only report preview. Any session notification invalidates this captured
/// snapshot before download/print; the user can reopen it with fresh records.
class StoreSalesStatementPanel extends StatefulWidget {
  const StoreSalesStatementPanel({
    super.key,
    required this.statement,
    required this.isCurrent,
    required this.changes,
    this.saveFile = saveStoreStockFile,
  });
  final StoreSalesStatement statement;
  final bool Function() isCurrent;
  final Listenable changes;
  final StoreStockFileSaver saveFile;
  @override
  State<StoreSalesStatementPanel> createState() =>
      _StoreSalesStatementPanelState();
}

class _StoreSalesStatementPanelState extends State<StoreSalesStatementPanel> {
  bool _changed = false, _busy = false;
  String? _notice;
  final _printChanges = ValueNotifier<int>(0);
  bool get current => mounted && !_changed && widget.isCurrent();
  @override
  void initState() {
    super.initState();
    widget.changes.addListener(_invalidate);
  }

  void _invalidate() {
    _changed = true;
    _printChanges.value++;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.changes.removeListener(_invalidate);
    _changed = true;
    _printChanges.value++;
    _printChanges.dispose();
    super.dispose();
  }

  Future<void> _export({bool print = false}) async {
    if (_busy || !current) {
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final report = widget.statement.report;
      if (print) {
        final status = await StoreDocumentPrinter.print(
          name: 'Sales & Collections Statement',
          initialFormat: StorePrintPaper.a4.initialFormat,
          isCurrent: () => current,
          scopeChanges: _printChanges,
          render: report.forPrint,
        );
        if (current) {
          setState(
            () => _notice = switch (status) {
              StorePrintState.completed =>
                'The print service reports completion. Check your printer.',
              StorePrintState.cancelled => 'Printing cancelled.',
              StorePrintState.submitted =>
                'Sent to the print queue. Check your printer.',
              StorePrintState.unavailable =>
                'No compatible print service is available.',
              StorePrintState.failed =>
                'Printing failed. Check the printer and retry.',
              StorePrintState.blocked =>
                'The print queue needs attention. Check your printer.',
              StorePrintState.unknown =>
                'Print status is unconfirmed. Check the queue before retrying.',
            },
          );
        }
      } else {
        final bytes = await report.generate(StoreStockExportFormat.pdf);
        if (!current) return;
        final saved = await widget.saveFile(
          bytes,
          'sales-collections-${widget.statement.reference}.pdf',
          StoreStockExportFormat.pdf,
        );
        if (current) {
          setState(
            () => _notice = saved ? 'PDF saved.' : 'Download cancelled.',
          );
        }
      }
    } catch (e) {
      if (current) {
        setState(
          () => _notice = e is FormatException
              ? e.message
              : 'Could not prepare the statement. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!current) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Records changed. Close and reopen the statement.'),
      );
    }
    final statement = widget.statement;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales & Collections Statement',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (statement.reviewOnly)
            const Text('Evaluation only — not for financial submission'),
          const SizedBox(height: 8),
          Text('${statement.storeName}\n${statement.period}'),
          const SizedBox(height: 12),
          Text(
            '${statement.selected.length} recorded ${statement.selected.length == 1 ? 'invoice' : 'invoices'} · INR ${(statement.billedMinor / 100).toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          const Text(
            'A4 summary and complete invoice annexure. Search filters do not limit this statement.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Tax details and missing ledger coverage are marked unavailable. Collections and current customer dues are shown separately from sales.',
          ),
          const SizedBox(height: 8),
          const Text(
            StoreSalesStatement.disclosure,
            style: TextStyle(fontSize: 12),
          ),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                key: const Key('sales-statement-download'),
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download PDF'),
              ),
              TextButton.icon(
                key: const Key('sales-statement-print'),
                onPressed: _busy ? null : () => _export(print: true),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print'),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_notice != null) Text(_notice!, semanticsLabel: _notice),
        ],
      ),
    );
  }
}

/// Adapter over the existing ledger, not a second transaction or payment owner.
/// Dated reports need the provider's opening-balance coverage date. A first
/// visible transaction is not evidence of that date.
class StoreCustomerStatement {
  const StoreCustomerStatement({
    required this.ledger,
    required this.storeName,
    this.coverageFrom,
    this.from,
    this.until,
  });
  final WorkspaceCustomerLedger ledger;
  final String storeName;
  final DateTime? coverageFrom, from, until;
  bool get ready =>
      ledger.valid &&
      ledger.historyComplete &&
      ((from == null && until == null) ||
          (from != null &&
              until != null &&
              coverageFrom != null &&
              !from!.isBefore(coverageFrom!) &&
              from!.isBefore(until!) &&
              !from!.isAfter(ledger.asOf) &&
              !until!.isAfter(
                ledger.asOf.add(const Duration(microseconds: 1)),
              ) &&
              ledger.entries.every(
                (e) => !e.occurredAt.isBefore(coverageFrom!),
              )));
  int? get opening => !ready
      ? null
      : ledger.entries
            .where((e) => from != null && e.occurredAt.isBefore(from!))
            .fold<int>(
              ledger.openingBalanceMinor!,
              (sum, e) => sum + e.balanceDeltaMinor,
            );
  List<WorkspaceCustomerLedgerEntry> get entries => !ledger.valid
      ? []
      : ledger.entries
            .where(
              (e) =>
                  (from == null || !e.occurredAt.isBefore(from!)) &&
                  (until == null || e.occurredAt.isBefore(until!)),
            )
            .toList();
  int? get closing => opening == null
      ? null
      : entries.fold<int>(opening!, (sum, e) => sum + e.balanceDeltaMinor);
  static const headers = [
    'Date (UTC)',
    'Particulars',
    'Voucher No.',
    'Debit (₹)',
    'Credit (₹)',
    'Balance (₹)',
    'Dr / Cr',
    'Status',
    'Order ID',
    'Reference',
    'Invoice ID',
    'Entry amount (₹)',
  ];
  static String particulars(WorkspaceLedgerEntryKind kind) => switch (kind) {
    WorkspaceLedgerEntryKind.invoice => 'Sales invoice',
    WorkspaceLedgerEntryKind.collection => 'Receipt',
    WorkspaceLedgerEntryKind.creditNote => 'Credit note',
    WorkspaceLedgerEntryKind.refund => 'Refund',
    WorkspaceLedgerEntryKind.creditUsed => 'Customer credit used',
    WorkspaceLedgerEntryKind.creditReceived => 'Customer credit applied',
  };
  List<List<Object?>> get rows {
    int? balance = opening;
    List<Object?> balanceRow(String label) => [
      '',
      label,
      '',
      null,
      null,
      balance == null ? null : balance.abs() / 100,
      balance == null
          ? ''
          : balance < 0
          ? 'Cr'
          : balance > 0
          ? 'Dr'
          : '',
      '',
      '',
      '',
      '',
      null,
    ];
    final result = <List<Object?>>[balanceRow('Opening Balance')];
    for (final e in entries) {
      if (balance != null) balance += e.balanceDeltaMinor;
      final posted = e.state == WorkspaceLedgerPostingState.posted;
      final debit =
          e.kind == WorkspaceLedgerEntryKind.invoice ||
          e.kind == WorkspaceLedgerEntryKind.refund ||
          e.kind == WorkspaceLedgerEntryKind.creditUsed;
      result.add([
        e.occurredAt.toUtc().toIso8601String(),
        particulars(e.kind),
        e.id,
        posted && debit ? e.amountMinor / 100 : null,
        posted && !debit ? e.amountMinor / 100 : null,
        balance == null ? null : balance.abs() / 100,
        balance == null
            ? ''
            : balance < 0
            ? 'Cr'
            : balance > 0
            ? 'Dr'
            : '',
        e.state.name,
        e.orderId,
        e.paymentReference ?? '',
        e.invoiceId,
        e.amountMinor / 100,
      ]);
    }
    result.add(balanceRow('Closing Balance'));
    return result;
  }

  StoreTabularReport get document {
    if (!ready) {
      throw const FormatException(
        'Complete opening balance and period coverage are required.',
      );
    }
    return StoreTabularReport(
      title: 'Customer statement',
      nullLabel: '-',
      dateColumns: const {0},
      disclosure: 'Statement of account · not a tax invoice',
      metadata: [
        ['Customer statement', ledger.customerName, ledger.customerId],
        ['Store', storeName, ledger.workspaceId],
        [
          'Period (UTC)',
          from?.toUtc().toIso8601String() ?? 'Recorded history',
          until?.toUtc().toIso8601String() ??
              ledger.asOf.toUtc().toIso8601String(),
        ],
        [
          'As of (UTC)',
          ledger.asOf.toUtc().toIso8601String(),
          'Revision',
          ledger.revision,
        ],
        [
          'Balance',
          'Dr: customer owes Store; Cr: customer credit. Pending/failed entries do not change balances.',
        ],
      ],
      headers: headers,
      rows: rows,
      moneyColumns: const {3, 4, 5, 11},
    );
  }
}

/// Only a provider-confirmed complete customer set may become an all-customer
/// outstanding report. Finance totals alone cannot prove list completeness.
StoreTabularReport customerOutstandingReport({
  required String accountId,
  required String storeId,
  required String storeName,
  required List<WorkspaceCustomerLedger> ledgers,
  required bool allCustomersComplete,
  Map<String, StoreCustomerStatement>? periodStatements,
  DateTime? emptyAsOf,
}) {
  if (!allCustomersComplete ||
      accountId.isEmpty ||
      storeId.isEmpty ||
      (ledgers.isEmpty && emptyAsOf == null) ||
      (periodStatements != null &&
          ledgers.any(
            (l) =>
                periodStatements[l.customerId]?.ready != true ||
                !identical(periodStatements[l.customerId]?.ledger, l),
          )) ||
      ledgers.any(
        (l) =>
            !l.valid ||
            l.closingBalanceMinor == null ||
            l.accountScope != accountId ||
            l.workspaceId != storeId,
      ) ||
      ledgers.map((l) => l.customerId).toSet().length != ledgers.length ||
      ledgers.map((l) => l.asOf.toUtc()).toSet().length > 1) {
    throw const FormatException(
      'A complete customer list with verified balances is required.',
    );
  }
  final rows = <List<Object?>>[];
  var receivable = 0, credit = 0;
  for (final l in ledgers) {
    final statement = periodStatements?[l.customerId];
    final value = statement?.closing ?? l.closingBalanceMinor!;
    receivable += value > 0 ? value : 0;
    credit += value < 0 ? -value : 0;
    if (receivable > 9007199254740991 || credit > 9007199254740991) {
      throw const FormatException(
        'The statement total exceeds the supported exact amount range.',
      );
    }
    rows.add([
      l.customerId,
      l.customerName,
      value > 0 ? value / 100 : 0,
      value < 0 ? -value / 100 : 0,
      (statement?.until?.subtract(const Duration(microseconds: 1)) ?? l.asOf)
          .toUtc()
          .toIso8601String(),
      l.revision,
    ]);
  }
  rows.add(['', 'Total', receivable / 100, credit / 100, '', null]);
  return StoreTabularReport(
    title: 'Customer outstanding',
    nullLabel: '-',
    dateColumns: const {4},
    disclosure: 'Outstanding summary · not a tax invoice',
    metadata: [
      ['Report', 'All-customer outstanding'],
      ['Store', storeName, storeId],
      [
        'Coverage',
        'Complete customer list',
        if (ledgers.isEmpty) emptyAsOf!.toUtc().toIso8601String(),
      ],
      ['Customers', ledgers.length],
      [
        'Balances',
        'Receivables and customer credits are shown separately, not netted.',
      ],
    ],
    headers: const [
      'Customer ID',
      'Customer',
      'Receivable (₹)',
      'Customer credit (₹)',
      'As of (UTC)',
      'Revision',
    ],
    rows: rows,
    moneyColumns: const {2, 3},
  );
}

class StoreCustomerReportsPanel extends StatefulWidget {
  const StoreCustomerReportsPanel({
    super.key,
    required this.accountId,
    required this.storeId,
    required this.storeName,
    required this.ledgers,
    required this.isCurrent,
    this.allCustomersComplete = false,
    this.coverageStarts = const {},
    this.saveFile = saveStoreStockFile,
    this.scopeChanges,
    this.recentSearches,
  });
  final String accountId, storeId, storeName;
  final List<String>? recentSearches;
  final List<WorkspaceCustomerLedger> ledgers;
  final Map<String, DateTime> coverageStarts;
  final bool allCustomersComplete;
  final bool Function() isCurrent;
  final StoreStockFileSaver saveFile;
  final Listenable? scopeChanges;
  @override
  State<StoreCustomerReportsPanel> createState() =>
      _StoreCustomerReportsPanelState();
}

class _StoreCustomerReportsPanelState extends State<StoreCustomerReportsPanel> {
  final _recentSearches = <String>[];
  final _search = TextEditingController(),
      _from = TextEditingController(),
      _to = TextEditingController();
  final _horizontal = ScrollController();
  final _printChanges = ValueNotifier<int>(0);
  int _printRevision = 0;
  String? _customer, _notice;
  String _period = 'Recorded history';
  bool _outstanding = false, _busy = false, _invalidated = false;
  @override
  void initState() {
    super.initState();
    widget.scopeChanges?.addListener(_printScopeChanged);
  }

  void _printScopeChanged() {
    // A session notification can carry changed ledger data before its widget
    // rebuild arrives. Cancel the captured print snapshot conservatively.
    _printRevision++;
    _printChanges.value = _printRevision;
  }

  @override
  void didUpdateWidget(StoreCustomerReportsPanel old) {
    super.didUpdateWidget(old);
    if (old.scopeChanges != widget.scopeChanges) {
      old.scopeChanges?.removeListener(_printScopeChanged);
      widget.scopeChanges?.addListener(_printScopeChanged);
    }
    if (old.accountId != widget.accountId ||
        old.storeId != widget.storeId ||
        old.storeName != widget.storeName ||
        !identical(old.ledgers, widget.ledgers) ||
        !identical(old.coverageStarts, widget.coverageStarts) ||
        old.allCustomersComplete != widget.allCustomersComplete ||
        old.scopeChanges != widget.scopeChanges ||
        !widget.isCurrent()) {
      _printScopeChanged();
    }
    if (old.accountId != widget.accountId ||
        old.storeId != widget.storeId ||
        !widget.isCurrent()) {
      _invalidated = true;
      _customer = null;
    }
  }

  @override
  void dispose() {
    _invalidated = true;
    widget.scopeChanges?.removeListener(_printScopeChanged);
    _printScopeChanged();
    _printChanges.dispose();
    _search.dispose();
    _from.dispose();
    _to.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  bool get current => !_invalidated && widget.isCurrent();
  List<WorkspaceCustomerLedger> get ledgers {
    if (!current) return [];
    final scoped = widget.ledgers
        .where(
          (l) =>
              l.valid &&
              l.accountScope == widget.accountId &&
              l.workspaceId == widget.storeId,
        )
        .toList();
    return scoped.map((l) => l.customerId).toSet().length == scoped.length
        ? scoped
        : [];
  }

  DateTime? date(String s) {
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(s.trim());
    if (m == null) return null;
    final d = int.parse(m[1]!), mo = int.parse(m[2]!), y = int.parse(m[3]!);
    final v = DateTime(y, mo, d);
    return v.year == y && v.month == mo && v.day == d ? v : null;
  }

  StoreCustomerStatement? get statement {
    final ledger = ledgers.where((l) => l.customerId == _customer).firstOrNull;
    if (ledger == null) return null;
    return statementFor(ledger);
  }

  StoreCustomerStatement? statementFor(WorkspaceCustomerLedger ledger) {
    DateTime? from, until;
    if (_period != 'Recorded history') {
      final now = DateTime.now(),
          today = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
      from = switch (_period) {
        'Today' => today,
        'This week' => DateTime(now.year, now.month, now.day - now.weekday + 1),
        'This month' => DateTime(now.year, now.month, 1),
        _ => date(_from.text),
      };
      final end = _period == 'Custom dates' ? date(_to.text) : today;
      if (from == null ||
          end == null ||
          end.isBefore(from) ||
          end.isAfter(today)) {
        return null;
      }
      until = DateTime(end.year, end.month, end.day + 1).toUtc();
      final observedEnd = ledger.asOf.add(const Duration(microseconds: 1));
      if (until.isAfter(observedEnd)) until = observedEnd;
      from = from.toUtc();
    }
    return StoreCustomerStatement(
      ledger: ledger,
      storeName: widget.storeName,
      coverageFrom: widget.coverageStarts[ledger.customerId],
      from: from,
      until: until,
    );
  }

  StoreTabularReport? get document {
    if (!current) return null;
    if (!_outstanding) {
      return statement?.ready == true ? statement!.document : null;
    }
    try {
      Map<String, StoreCustomerStatement>? periods;
      if (_period != 'Recorded history') {
        periods = {};
        for (final l in widget.ledgers) {
          final value = statementFor(l);
          if (value == null || !value.ready) return null;
          periods[l.customerId] = value;
        }
      }
      return customerOutstandingReport(
        accountId: widget.accountId,
        storeId: widget.storeId,
        storeName: widget.storeName,
        ledgers: widget.ledgers,
        allCustomersComplete: widget.allCustomersComplete,
        periodStatements: periods,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> printReport(StorePrintPaper paper) async {
    final report = document;
    if (_busy || report == null) return;
    final revision = _printRevision;
    bool valid() => mounted && current && revision == _printRevision;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final state = await StoreDocumentPrinter.print(
        name: _outstanding ? 'Customer outstanding' : 'Customer statement',
        initialFormat: paper.initialFormat,
        isCurrent: valid,
        scopeChanges: _printChanges,
        render: report.forPrint,
      );
      if (mounted && current) {
        setState(
          () => _notice = valid()
              ? switch (state) {
                  StorePrintState.completed =>
                    'The print service reports completion. Check your printer.',
                  StorePrintState.cancelled => 'Printing cancelled.',
                  StorePrintState.unavailable =>
                    'Printing is unavailable. Enable a compatible print service in phone settings.',
                  StorePrintState.failed =>
                    'Printing failed. Check the printer and retry.',
                  StorePrintState.submitted =>
                    'Sent to the print queue. Check the printer for completion.',
                  StorePrintState.blocked =>
                    'The print queue needs attention. Check the printer connection, paper and ink.',
                  StorePrintState.unknown =>
                    'Print status could not be confirmed. Check the print queue before retrying.',
                }
              : 'Records changed. Reopen the statement before printing.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> download(StoreStockExportFormat format) async {
    final report = document;
    if (_busy || report == null) return;
    final scope = (widget.accountId, widget.storeId);
    final revision = widget.ledgers;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final bytes = await report.generate(format);
      if (!mounted ||
          !current ||
          scope != (widget.accountId, widget.storeId) ||
          !identical(revision, widget.ledgers)) {
        throw const FormatException(
          'Records changed. Reopen the statement before downloading.',
        );
      }
      final id = '${widget.storeId}-${_customer ?? 'all'}'.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final saved = await widget.saveFile(
        bytes,
        'customer-statement-$id.${format.extension}',
        format,
      );
      if (mounted && current) {
        setState(
          () => _notice = saved
              ? '${format.label} saved.'
              : 'Download cancelled.',
        );
      }
    } catch (e) {
      if (mounted && current) {
        setState(
          () => _notice = e is FormatException
              ? e.message
              : 'Could not download. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget table(List<String> headers, List<List<Object?>> rows, Set<int> money) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final widths = [
      for (var i = 0; i < headers.length; i++)
        (i == 0 && headers[0] == 'Date (UTC)'
                ? 88.0
                : i == 1
                ? 128.0
                : money.contains(i)
                ? 104.0
                : 140.0) *
            scale,
    ];
    final order = headers.first == 'Customer ID'
        ? [1, 2, 3, 0, 4, 5]
        : [0, 1, 5, 3, 4, 2, 7, 8, 9, 10, 11];
    String text(Object? value, int column, [List<Object?>? row]) {
      if (value == null) return '—';
      if (column == 0 &&
          headers[0] == 'Date (UTC)' &&
          value is String &&
          value.isNotEmpty) {
        final date = DateTime.tryParse(value);
        if (date != null) {
          return MaterialLocalizations.of(
            context,
          ).formatCompactDate(date.toLocal());
        }
      }
      final displayed = money.contains(column) && value is num
          ? value.toStringAsFixed(2)
          : '$value';
      return column == 5 && headers.first == 'Date (UTC)' && row != null
          ? '$displayed ${row[6]}'.trimRight()
          : displayed;
    }

    double rowHeight(List<Object?> values, bool header) {
      var height = 0.0;
      for (final c in order) {
        final painter = TextPainter(
          text: TextSpan(
            text: header
                ? (values[c] == 'Date (UTC)' ? 'Date' : '${values[c]}')
                : text(values[c], c, values),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: widths[c] - 16);
        if (painter.height > height) height = painter.height;
        painter.dispose();
      }
      return height + 16;
    }

    return SizedBox(
      key: const Key('customer-report-table'),
      height:
          (rowHeight(headers, true) +
                  rows
                      .take(8)
                      .fold<double>(
                        0,
                        (sum, row) => sum + rowHeight(row, false),
                      ) +
                  12)
              .clamp(90, 350)
              .toDouble(),
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: order.fold<double>(0, (sum, c) => sum + widths[c]),
            child: Column(
              children: [
                Container(
                  color: const Color(0xff080078),
                  child: Row(
                    children: [
                      for (final c in order)
                        SizedBox(
                          width: widths[c],
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              headers[c] == 'Date (UTC)' ? 'Date' : headers[c],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    primary: false,
                    itemCount: rows.length,
                    itemBuilder: (_, r) => Container(
                      color: r.isOdd ? const Color(0xfff5f6fb) : Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final c in order)
                            SizedBox(
                              width: widths[c],
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  text(rows[r][c], c, rows[r]),
                                  textAlign: money.contains(c)
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  style: const TextStyle(fontSize: 12),
                                ),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!current) {
      return const Text(
        'Customer records are unavailable. Reopen Reports & Downloads.',
      );
    }
    final selected = statement, report = document;
    final matches = ledgers
        .where(
          (l) => '${l.customerName} ${l.customerId}'.toLowerCase().contains(
            _search.text.trim().toLowerCase(),
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (_customer == null && !_outstanding) ...[
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _outstanding = true;
                    _period = 'Recorded history';
                    _notice = null;
                  }),
            key: const Key('customer-outstanding-open'),
            child: const Text('All-customer outstanding'),
          ),
          StoreRecentSearches(
            controller: _search,
            history: widget.recentSearches ?? _recentSearches,
            isCurrent: widget.isCurrent,
            onChanged: (_) => setState(() {}),
            child: TextField(
              key: const Key('customer-statement-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13, letterSpacing: 0),
              decoration: const InputDecoration(
                hintText: 'Search customer name or ID',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          if (matches.isEmpty)
            Text(
              ledgers.isEmpty
                  ? 'No customer ledger is available yet.'
                  : 'No matching customers.',
            ),
          SizedBox(
            height: (matches.length * 64.0).clamp(0, 350),
            child: ListView.builder(
              primary: false,
              itemCount: matches.length,
              itemBuilder: (_, i) {
                final l = matches[i], value = matches[i].closingBalanceMinor;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  key: ValueKey('customer-statement-${l.customerId}'),
                  title: Text(
                    l.customerName,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    value == null
                        ? 'Balance unavailable'
                        : '₹${(value.abs() / 100).toStringAsFixed(2)} ${value < 0
                              ? 'Cr'
                              : value > 0
                              ? 'Dr'
                              : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _customer = l.customerId;
                    _notice = null;
                  }),
                );
              },
            ),
          ),
        ] else ...[
          TextButton.icon(
            key: const Key('customer-report-back'),
            onPressed: _busy
                ? null
                : () => setState(() {
                    _customer = null;
                    _outstanding = false;
                    _notice = null;
                  }),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(
              _outstanding
                  ? 'All-customer outstanding'
                  : selected?.ledger.customerName ?? 'Customers',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PopupMenuButton<String>(
                key: const Key('customer-statement-period'),
                enabled: !_busy,
                initialValue: _period,
                onSelected: (p) => setState(() {
                  _period = p;
                  _notice = null;
                }),
                itemBuilder: (_) => [
                  for (final p in [
                    'Recorded history',
                    'Today',
                    'This week',
                    'This month',
                    'Custom dates',
                  ])
                    PopupMenuItem(value: p, child: Text(p)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _period,
                        style: const TextStyle(fontSize: 12, letterSpacing: 0),
                      ),
                      const Icon(Icons.expand_more, size: 18),
                    ],
                  ),
                ),
              ),
              for (final f in StoreStockExportFormat.values)
                TextButton(
                  key: Key('customer-statement-download-${f.extension}'),
                  onPressed: report == null || _busy ? null : () => download(f),
                  child: Text(f.label),
                ),
              StorePrintButton(
                key: const Key('customer-statement-print'),
                tooltip: 'Print statement',
                onSelected: report == null || _busy ? null : printReport,
              ),
            ],
          ),
          if (_period == 'Custom dates')
            Wrap(
              spacing: 8,
              children: [
                for (final field in [('From', _from), ('To', _to)])
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: field.$2,
                      enabled: !_busy,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: field.$1,
                        hintText: 'DD/MM/YYYY',
                      ),
                    ),
                  ),
              ],
            ),
          if (report == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _outstanding
                    ? 'Complete customer balances unavailable. Download disabled.'
                    : _period == 'Custom dates' && selected == null
                    ? 'Enter valid dates as DD/MM/YYYY, ending today or earlier.'
                    : selected?.ledger.openingBalanceMinor == null
                    ? 'Opening balance unavailable. Download disabled.'
                    : 'Complete period coverage unavailable. Download disabled.',
                key: const Key('customer-statement-unavailable'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          if (_outstanding && report != null)
            table(report.headers, report.rows, report.moneyColumns),
          if (!_outstanding && selected != null) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'As of ${MaterialLocalizations.of(context).formatShortDate(selected.ledger.asOf.toLocal())}',
                  style: const TextStyle(fontSize: 12),
                ),
                Tooltip(
                  message:
                      'Dr: customer owes Store. Cr: customer credit. Pending and failed entries do not change balances.',
                  triggerMode: TooltipTriggerMode.tap,
                  child: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.info_outline, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            table(StoreCustomerStatement.headers, selected.rows, const {
              3,
              4,
              5,
              11,
            }),
          ],
          if (_busy) const Text('Preparing download…'),
          if (_notice != null)
            Semantics(liveRegion: true, child: Text(_notice!)),
        ],
      ],
    );
  }
}

class StoreCommerceDownloadSource implements CommerceDownloadSource {
  const StoreCommerceDownloadSource(this.session, {this.pdfSource});
  final WorkSession session;
  final WorkInvoicePdfSource? pdfSource;

  bool current(CommerceDownloadScope scope) =>
      scope.valid &&
      scope.store != null &&
      session.activeWorkspace?.id == scope.store &&
      session.workspaceFinance?.accountScope == scope.account &&
      !session.workspaceFinanceStale;

  @override
  Future<CommerceDownloadPage> load(
    CommerceDownloadQuery query, {
    String? cursor,
  }) async {
    final scope = query.scope;
    if (!current(scope)) {
      throw const FormatException(
        'Documents are not available for this Store yet. Please retry.',
      );
    }
    final invoices = session.workspaceInvoices.toList()
      ..sort((a, b) {
        final time = b.issuedAt.compareTo(a.issuedAt);
        return time != 0 ? time : a.id.compareTo(b.id);
      });
    final revision = sha256
        .convert(
          utf8.encode(
            jsonEncode(invoices.map((i) => i.toLedgerJson()).toList()),
          ),
        )
        .toString();
    var offset = 0;
    if (cursor != null) {
      final value = jsonDecode(cursor);
      if (value is! List ||
          value.length != 3 ||
          value[0] != query.key ||
          value[1] != revision ||
          value[2] is! int ||
          (value[2] as int) < 0) {
        throw const FormatException(
          'Your document list changed. Refresh to see the latest records.',
        );
      }
      offset = value[2] as int;
    }
    final entries = <CommerceDownloadItem>[];
    for (final invoice in invoices) {
      final order = session.workspaceOrders
          .where((o) => o.id == invoice.orderId)
          .firstOrNull;
      WorkInvoicePdfRequest requestForCurrentPayment() {
        final payment = session.workspaceFinance?.payments
            .where(
              (p) =>
                  p.valid &&
                  p.invoiceId == invoice.id &&
                  p.orderId == invoice.orderId,
            )
            .firstOrNull;
        return WorkInvoicePdfRequest(
          accountId: scope.account,
          storeId: scope.store!,
          invoice: invoice,
          items: order?.itemSnapshots ?? const [],
          paymentStatus: payment == null
              ? 'Payment status unavailable'
              : '${payment.label} · Received ${commerceInvoiceMoney(payment.paidMinor)} · Due ${commerceInvoiceMoney(payment.dueMinor)}',
        );
      }

      final request = requestForCurrentPayment();
      final source = pdfSource ?? createWorkInvoicePdfSource();
      final item = CommerceDownloadItem(
        scope: scope,
        id: request.identity,
        kind: CommerceDownloadKind.invoice,
        title: 'Sales invoice',
        reference: invoice.id,
        party: invoice.customer,
        date: invoice.issuedAt,
        notice: source is LocalReviewWorkInvoicePdfSource
            ? 'Preview · not issued'
            : null,
        unavailableReason: source is UnavailableWorkInvoicePdfSource
            ? 'PDF not available yet'
            : null,
        load: () async {
          if (!current(scope)) {
            throw const FormatException(
              'Your account or Store changed. Reopen Downloads.',
            );
          }
          final revision = session.workspaceFinance?.revision;
          final pdf = await source.load(requestForCurrentPayment());
          if (!current(scope) || pdf.identity != request.identity) {
            throw const FormatException(
              'The invoice does not match this account or Store.',
            );
          }
          if (revision != session.workspaceFinance?.revision) {
            throw const FormatException(
              'Payment details changed. Tap PDF to download the updated invoice.',
            );
          }
          return CommerceDownloadFile(
            scope: scope,
            id: request.identity,
            bytes: pdf.bytes,
            fileName: commerceDownloadName(invoice.id),
          );
        },
      );
      if (query.matches(item)) entries.add(item);
    }
    if (offset > entries.length) {
      throw const FormatException('Refresh the document list.');
    }
    final page = entries.skip(offset).take(50).toList();
    final end = offset + page.length;
    return CommerceDownloadPage(
      queryKey: query.key,
      items: page,
      nextCursor: end < entries.length
          ? jsonEncode([query.key, revision, end])
          : null,
    );
  }
}
