import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../shared/commerce/commerce_downloads.dart';
import 'work_invoice_pdf.dart';
import 'work_session.dart';

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
