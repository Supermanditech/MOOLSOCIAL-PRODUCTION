import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:excel_community/excel_community.dart' as xls;
import 'package:moolsocial/features/work/work_stock_export.dart';
import 'package:moolsocial/features/work/work_downloads.dart';
import 'package:moolsocial/features/work/work_invoice_pdf.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/shared/commerce/commerce_downloads.dart';
import 'commerce_downloads_test.dart' show pdfBytes;
import 'work_invoice_pdf_test.dart' show request;

class AccountStore implements WorkPendingProofStore {
  @override
  String? accountScope = 'review-account';
  @override
  Future<Map<String, Object?>?> read(String scope) async => null;
  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(String scope) async {}
}

WorkspaceFinanceSnapshot finance({int revision = 1}) =>
    WorkspaceFinanceSnapshot(
      accountScope: 'review-account',
      workspaceId: 'review-store',
      revision: revision,
      asOf: DateTime(2026, 9, 22),
      salesTodayMinor: 0,
      duesMinor: 0,
      availableMinor: 0,
      heldMinor: 0,
      requestedMinor: 0,
      paidOutMinor: 0,
      feesMinor: 0,
      deliveryAdjustmentsMinor: 0,
      refundsMinor: 0,
      taxWithheldMinor: 0,
      payments: const [],
      payouts: const [],
      historyComplete: true,
    );
WorkSession session(AccountStore account) {
  final work =
      WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: account)
        ..activeWorkspace = const WorkWorkspace(
          id: 'review-store',
          name: 'Annapurna Stores',
          profileId: 'retailer-grocery',
          profileLabel: 'Grocery',
          area: 'Jaipur',
          verified: true,
        );
  expect(work.applyWorkspaceFinance(finance()), isTrue);
  final r = request();
  work.workspaceInvoices.add(r.invoice);
  work.workspaceOrders.add(
    WorkspaceOrderRecord(
      id: r.invoice.orderId,
      customer: r.invoice.customer,
      items: r.invoice.items,
      quantities: const {},
      amount: r.invoice.amount,
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'Cash',
      address: '',
      stage: 'New',
      needsDelivery: false,
      createdAt: r.invoice.issuedAt,
      itemSnapshots: r.items,
    ),
  );
  addTearDown(work.dispose);
  return work;
}

class PdfSource implements WorkInvoicePdfSource {
  PdfSource({this.beforeReturn, this.wrongIdentity = false});
  final void Function()? beforeReturn;
  final bool wrongIdentity;
  WorkInvoicePdfRequest? received;
  @override
  Future<WorkInvoicePdfDocument> load(WorkInvoicePdfRequest request) async {
    received = request;
    beforeReturn?.call();
    return WorkInvoicePdfDocument(
      identity: wrongIdentity ? 'wrong' : request.identity,
      fileName: request.invoice.pdfFileName,
      bytes: pdfBytes(),
      reviewOnly: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'PRINT stock current and complete empty ledger support reported media',
    () async {
      final current = StoreStockSnapshot(
        storeId: 'store',
        storeName: 'QA Store',
        scope: 'Selected QA stock',
        generatedAt: DateTime.utc(2026, 9, 24),
        products: [workspaceMasterCatalogue.first],
      );
      final ledger = StoreStockLedgerSnapshot(
        accountId: 'account',
        storeId: 'store',
        storeName: 'QA Store',
        snapshotId: 'qa-snapshot',
        from: DateTime.utc(2026, 9, 1),
        until: DateTime.utc(2026, 9, 24),
        observedAt: DateTime.utc(2026, 9, 24),
        complete: true,
        reviewOnly: true,
        lines: [],
      );
      for (final paper in [
        StorePrintPaper.a4,
        StorePrintPaper.receipt58,
        StorePrintPaper.receipt80,
      ]) {
        for (final entry in [
          ('current', await current.forPrint(paper.initialFormat, null)),
          ('ledger', await ledger.forPrint(paper.initialFormat, null)),
        ]) {
          expect(ascii.decode(entry.$2.take(5).toList()), '%PDF-');
          const output = String.fromEnvironment(
            'MOOL_CUSTOMER_REPORT_TEST_DIR',
          );
          if (output.isNotEmpty) {
            Directory(output).createSync(recursive: true);
            File(
              '$output/stock-${entry.$1}-${paper.name}.pdf',
            ).writeAsBytesSync(entry.$2);
          }
        }
      }
      await expectLater(
        current.forPrint(PdfPageFormat.a4, [999]),
        throwsFormatException,
      );
    },
  );
  testWidgets('PRINT stock action cancels on source change', (tester) async {
    final changes = ChangeNotifier();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final result = Completer<String>();
    final calls = <String>[];
    messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, (
      call,
    ) async {
      calls.add(call.method);
      return call.method == 'print' ? result.future : null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, null);
      changes.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoreStockDownloadControls(
            storeId: 'store',
            storeName: 'Store',
            accountId: 'account',
            filteredProducts: [workspaceMasterCatalogue.first],
            filterDescription: 'QA selected',
            isCurrent: () => true,
            scopeChanges: changes,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('work-stock-print')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('store-print-paper-receipt58')));
    await tester.pumpAndSettle();
    expect(calls, ['print']);
    changes.notifyListeners();
    await tester.pump();
    expect(calls, ['print', 'cancel']);
    result.complete('completed');
    await tester.pumpAndSettle();
    expect(
      find.text('Stock changed. Reopen the statement before printing.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  WorkspaceCustomerLedger customer({
    String id = 'customer-01',
    String account = 'account',
    int? opening = 1000,
    bool complete = true,
    bool transactions = true,
  }) {
    final kinds = [
      WorkspaceLedgerEntryKind.invoice,
      WorkspaceLedgerEntryKind.collection,
      WorkspaceLedgerEntryKind.creditNote,
      WorkspaceLedgerEntryKind.refund,
      WorkspaceLedgerEntryKind.collection,
      WorkspaceLedgerEntryKind.refund,
    ];
    final amounts = [10000, 4000, 8000, 500, 250, 200];
    return WorkspaceCustomerLedger(
      accountScope: account,
      workspaceId: 'store',
      customerId: id,
      customerName: 'Customer $id',
      revision: 1,
      asOf: DateTime.utc(2026, 9, 10),
      openingBalanceMinor: opening,
      historyComplete: complete,
      entries: transactions
          ? [
              for (var i = 0; i < kinds.length; i++)
                WorkspaceCustomerLedgerEntry(
                  id: 'voucher-$id-$i',
                  operationId: 'operation-$id-$i',
                  invoiceId: 'invoice-$id',
                  orderId: 'order-$id',
                  sequence: i + 1,
                  occurredAt: DateTime.utc(2026, 9, i + 2),
                  kind: kinds[i],
                  amountMinor: amounts[i],
                  state: i == 4
                      ? WorkspaceLedgerPostingState.pending
                      : i == 5
                      ? WorkspaceLedgerPostingState.failed
                      : WorkspaceLedgerPostingState.posted,
                ),
            ]
          : [],
    );
  }

  testWidgets(
    'PRINT customer statement action cancels stale source and never claims queued completion',
    (tester) async {
      final changes = ChangeNotifier();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var result = Completer<String>();
      final calls = <String>[];
      messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'print') return result.future;
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, null);
        changes.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StoreCustomerReportsPanel(
                accountId: 'account',
                storeId: 'store',
                storeName: 'Store',
                ledgers: [customer()],
                isCurrent: () => true,
                scopeChanges: changes,
              ),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('customer-statement-customer-01')),
      );
      await tester.pumpAndSettle();
      Future<void> start() async {
        await tester.tap(find.byKey(const Key('customer-statement-print')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('store-print-paper-a4')));
        await tester.pumpAndSettle();
      }

      await start();
      expect(calls, ['print']);
      changes.notifyListeners();
      await tester.pump();
      expect(calls, ['print', 'cancel']);
      result.complete('completed');
      await tester.pumpAndSettle();
      expect(
        find.text('Records changed. Reopen the statement before printing.'),
        findsOneWidget,
      );
      expect(find.textContaining('reports completion'), findsNothing);
      result = Completer<String>();
      await start();
      result.complete('submitted');
      await tester.pumpAndSettle();
      expect(
        find.text('Sent to the print queue. Check the printer for completion.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'D2 ledger uses posted entries and preserves vouchers and pending amounts',
    () {
      final report = StoreCustomerStatement(
        ledger: customer(),
        storeName: 'Store',
      );
      expect(report.ready, isTrue);
      expect(report.opening, 1000);
      expect(report.closing, -500);
      expect(report.rows.last[5], 5);
      expect(report.rows.last[6], 'Cr');
      expect(report.rows[1][2], 'voucher-customer-01-0');
      expect(report.rows[5][3], isNull);
      expect(report.rows[5][4], isNull);
      expect(report.rows[5][5], 5);
      expect(report.rows[5][11], 2.5);
      expect(
        report.rows.every(
          (r) => r.length == StoreCustomerStatement.headers.length,
        ),
        isTrue,
      );
    },
  );
  test(
    'D2 dated opening includes prior posted activity and rejects missing coverage',
    () {
      final report = StoreCustomerStatement(
        ledger: customer(),
        storeName: 'Store',
        coverageFrom: DateTime.utc(2026, 9, 1),
        from: DateTime.utc(2026, 9, 4),
        until: DateTime.utc(2026, 9, 6),
      );
      expect(report.ready, isTrue);
      expect(report.opening, 7000);
      expect(report.closing, -500);
      expect(report.entries.length, 2);
      final missing = StoreCustomerStatement(
        ledger: customer(),
        storeName: 'Store',
        from: report.from,
        until: report.until,
      );
      expect(missing.ready, isFalse);
      expect(missing.opening, isNull);
      expect(() => missing.document, throwsFormatException);
      expect(
        StoreCustomerStatement(
          ledger: customer(),
          storeName: 'Store',
          coverageFrom: DateTime.utc(2026, 9, 3),
          from: report.from,
          until: report.until,
        ).ready,
        isFalse,
      );
    },
  );
  test(
    'D2 incomplete history never invents balances or becomes downloadable',
    () {
      final report = StoreCustomerStatement(
        ledger: customer(opening: null, complete: false),
        storeName: 'Store',
      );
      expect(report.ledger.valid, isTrue);
      expect(report.entries.length, 6);
      expect(report.closing, isNull);
      expect(report.rows.every((r) => r[5] == null), isTrue);
      expect(() => report.document, throwsFormatException);
    },
  );
  test(
    'D2 outstanding separates receivables from credit and requires complete scope',
    () {
      final ledgers = [
        customer(),
        customer(id: 'other', opening: 2000, transactions: false),
      ];
      StoreTabularReport build(
        List<WorkspaceCustomerLedger> rows,
        bool complete,
      ) => customerOutstandingReport(
        accountId: 'account',
        storeId: 'store',
        storeName: 'Store',
        ledgers: rows,
        allCustomersComplete: complete,
      );
      expect(build(ledgers, true).rows.last.sublist(2, 4), [20, 5]);
      expect(() => build(ledgers, false), throwsFormatException);
      expect(
        () => build([customer(account: 'wrong')], true),
        throwsFormatException,
      );
      expect(
        () => build([customer(), customer()], true),
        throwsFormatException,
      );
      expect(
        () => build([customer(complete: false)], true),
        throwsFormatException,
      );
    },
  );
  test(
    'PRINT statement A4 and thermal retain scoped report and validate selection',
    () async {
      final report = StoreCustomerStatement(
        ledger: customer(),
        storeName: 'QA Store',
      ).document;
      final original = jsonEncode(report.rows);
      for (final paper in [
        PdfPageFormat.a4,
        StorePrintPaper.receipt58.initialFormat,
        StorePrintPaper.receipt80.initialFormat,
      ]) {
        final bytes = await report.forPrint(paper, null);
        expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
        expect(jsonEncode(report.rows), original);
        final selected = await report.forPrint(paper, [0]);
        expect(selected, isNotEmpty);
        const output = String.fromEnvironment('MOOL_CUSTOMER_REPORT_TEST_DIR');
        if (output.isNotEmpty) {
          final dir = Directory(output)..createSync(recursive: true);
          File(
            '${dir.path}/print-statement-${(paper.width / PdfPageFormat.mm).round()}.pdf',
          ).writeAsBytesSync(bytes);
        }
      }
      await expectLater(
        report.forPrint(PdfPageFormat.a4, [999]),
        throwsFormatException,
      );
      await expectLater(
        report.forPrint(const PdfPageFormat(10, 200), null),
        throwsFormatException,
      );
      for (final row in <List<Object?>>[
        ['missing fields'],
        [...report.rows.first, 'unexpected field'],
      ]) {
        final malformed = StoreTabularReport(
          title: report.title,
          disclosure: report.disclosure,
          metadata: report.metadata,
          headers: report.headers,
          rows: [row],
          moneyColumns: report.moneyColumns,
        );
        await expectLater(
          malformed.forPrint(PdfPageFormat.a4, null),
          throwsFormatException,
        );
      }
    },
  );

  test('D2 exports preserve typed values and all statement fields', () async {
    final document = StoreCustomerStatement(
      ledger: customer(),
      storeName: '=Unsafe name',
    ).document;
    final csv = utf8.decode(
      await document.generate(StoreStockExportFormat.csv),
    );
    expect(csv, contains("'=Unsafe name"));
    expect(csv, contains('Opening Balance'));
    expect(csv, contains('Closing Balance'));
    expect(csv, contains('voucher-customer-01-0'));
    final excel = await document.generate(StoreStockExportFormat.excel);
    final sheet = xls.Excel.decodeBytes(excel)['Customer statement'];
    expect(sheet.cell(xls.CellIndex.indexByString('A7')).value, isNull);
    expect(sheet.cell(xls.CellIndex.indexByString('J8')).value, isNull);
    expect(
      sheet.cell(xls.CellIndex.indexByString('D8')).value,
      xls.IntCellValue(100),
    );
    expect(
      sheet.cell(xls.CellIndex.indexByString('G14')).value,
      xls.TextCellValue('Cr'),
    );
    final pdf = await document.generate(StoreStockExportFormat.pdf);
    expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
    const output = String.fromEnvironment('MOOL_CUSTOMER_REPORT_TEST_DIR');
    if (output.isNotEmpty) {
      final summary = customerOutstandingReport(
        accountId: 'account',
        storeId: 'store',
        storeName: 'Test Store',
        ledgers: [
          customer(),
          customer(id: '002', opening: 2000, transactions: false),
        ],
        allCustomersComplete: true,
      );
      await Directory(output).create(recursive: true);
      for (final entry in [
        ('customer-statement', document),
        ('customer-outstanding', summary),
      ]) {
        for (final format in StoreStockExportFormat.values) {
          await File(
            '$output/${entry.$1}.${format.extension}',
          ).writeAsBytes(await entry.$2.generate(format));
        }
      }
    }
  });
  test(
    'D2 outstanding period uses period closing rather than current closing',
    () {
      final l = customer();
      final period = StoreCustomerStatement(
        ledger: l,
        storeName: 'Store',
        from: DateTime.utc(2026, 9, 1),
        until: DateTime.utc(2026, 9, 4),
        coverageFrom: DateTime.utc(2026, 9, 1),
      );
      final report = customerOutstandingReport(
        accountId: 'account',
        storeId: 'store',
        storeName: 'Store',
        ledgers: [l],
        allCustomersComplete: true,
        periodStatements: {l.customerId: period},
      );
      expect(report.rows.last.sublist(2, 4), [70, 0]);
      expect(
        () => customerOutstandingReport(
          accountId: 'account',
          storeId: 'store',
          storeName: 'Store',
          ledgers: [l],
          allCustomersComplete: true,
          periodStatements: {},
        ),
        throwsFormatException,
      );
      expect(
        () => customerOutstandingReport(
          accountId: 'account',
          storeId: 'store',
          storeName: 'Store',
          ledgers: [],
          allCustomersComplete: true,
        ),
        throwsFormatException,
      );
      expect(
        customerOutstandingReport(
          accountId: 'account',
          storeId: 'store',
          storeName: 'Store',
          ledgers: [],
          allCustomersComplete: true,
          emptyAsOf: l.asOf,
        ).rows.single[2],
        0,
      );
    },
  );
  const scope = CommerceDownloadScope('review-account', store: 'review-store');
  const query = CommerceDownloadQuery(scope: scope);
  test(
    'Store adapter uses saved seller, exact rows and scoped approved PDF request',
    () async {
      final account = AccountStore();
      final work = session(account);
      final pdf = PdfSource();
      final source = StoreCommerceDownloadSource(work, pdfSource: pdf);
      final page = await source.load(query);
      expect(page.items, hasLength(1));
      final download = await page.items.single.load();
      expect(download.valid, isTrue);
      expect(
        pdf.received!.invoice.toLedgerJson(),
        request().invoice.toLedgerJson(),
      );
      expect(pdf.received!.items.length, 2);
      expect(pdf.received!.accountId, scope.account);
      expect(pdf.received!.storeId, scope.store);
      expect(pdf.received!.paymentStatus, 'Payment status unavailable');
      expect(download.bytes, pdfBytes());
      account.accountScope = 'different-account';
      await expectLater(page.items.single.load(), throwsFormatException);
      await expectLater(source.load(query), throwsFormatException);
    },
  );
  test('release source does not silently mint an issued invoice', () async {
    final source = StoreCommerceDownloadSource(session(AccountStore()));
    final page = await source.load(query);
    expect(page.items.single.unavailableReason, 'PDF not available yet');
    expect(page.items.single.notice, isNull);
  });
  test(
    'Store paging 50 records with query and revision-bound cursor',
    () async {
      final work = session(AccountStore());
      for (var i = 0; i < 55; i++) {
        work.workspaceInvoices.add(
          WorkspaceCustomerInvoice(
            id: 'INV-$i',
            orderId: 'order-$i',
            customer: 'Review customer',
            items: '1 item',
            amount: 100,
            payment: 'Cash',
            issuedAt: DateTime(2026, 9, 22),
          ),
        );
      }
      final source = StoreCommerceDownloadSource(work);
      final first = await source.load(query);
      expect(first.items.length, 50);
      final second = await source.load(query, cursor: first.nextCursor);
      expect(second.items.length, 6);
      expect(second.nextCursor, isNull);
      expect(
        {
          ...first.items.map((i) => i.id),
          ...second.items.map((i) => i.id),
        }.length,
        56,
      );
      await expectLater(
        source.load(
          const CommerceDownloadQuery(scope: scope, search: 'changed'),
          cursor: first.nextCursor,
        ),
        throwsFormatException,
      );
      work.workspaceInvoices.removeLast();
      await expectLater(
        source.load(query, cursor: first.nextCursor),
        throwsFormatException,
      );
      expect(
        (await source.load(
          const CommerceDownloadQuery(
            scope: scope,
            kind: CommerceDownloadKind.platformFee,
          ),
        )).items,
        isEmpty,
      );
    },
  );
  test(
    'rejects response after payment revision changes or wrong document identity',
    () async {
      final work = session(AccountStore());
      for (final source in [
        PdfSource(wrongIdentity: true),
        PdfSource(
          beforeReturn: () {
            expect(work.applyWorkspaceFinance(finance(revision: 2)), isTrue);
          },
        ),
      ]) {
        final page = await StoreCommerceDownloadSource(
          work,
          pdfSource: source,
        ).load(query);
        await expectLater(page.items.single.load(), throwsFormatException);
      }
    },
  );
}
