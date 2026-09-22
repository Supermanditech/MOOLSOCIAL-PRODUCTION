import 'package:flutter_test/flutter_test.dart';
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
