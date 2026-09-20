import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'work_models.dart';

/// Local documents are available only in an explicitly opted-in review build.
const workInvoiceLocalPdfReview =
    kDebugMode &&
    (bool.fromEnvironment('MOOL_LOCAL_INVOICE_PDF_REVIEW') ||
        (bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY') &&
            bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW')));

WorkInvoicePdfSource createWorkInvoicePdfSource() => workInvoiceLocalPdfReview
    ? const LocalReviewWorkInvoicePdfSource()
    : const UnavailableWorkInvoicePdfSource();

/// Immutable request; a future backend adapter must use the scoped invoice ID
/// to retrieve authoritative records, not trust these local preview values.
class WorkInvoicePdfRequest {
  WorkInvoicePdfRequest({
    required this.accountId,
    required this.storeId,
    required this.invoice,
    required List<WorkspaceOrderItemSnapshot> items,
    required this.paymentStatus,
  }) : items = List.unmodifiable(items);
  final String accountId, storeId, paymentStatus;
  final WorkspaceCustomerInvoice invoice;
  final List<WorkspaceOrderItemSnapshot> items;
  String get identity => '$accountId/$storeId/${invoice.id}';
}

class WorkInvoicePdfDocument {
  WorkInvoicePdfDocument({
    required this.identity,
    required this.fileName,
    required Uint8List bytes,
    required this.reviewOnly,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView() {
    if (bytes.length < 8 ||
        bytes.length > 10 * 1024 * 1024 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-' ||
        !fileName.endsWith('.pdf') ||
        fileName.contains(RegExp(r'[/\\\x00-\x1f]'))) {
      throw const WorkInvoicePdfException(
        'The invoice file could not be opened.',
      );
    }
  }
  final String identity, fileName;
  final Uint8List bytes;
  final bool reviewOnly;
}

class WorkInvoicePdfException implements Exception {
  const WorkInvoicePdfException(this.message);
  final String message;
}

abstract interface class WorkInvoicePdfSource {
  Future<WorkInvoicePdfDocument> load(WorkInvoicePdfRequest request);
}

class UnavailableWorkInvoicePdfSource implements WorkInvoicePdfSource {
  const UnavailableWorkInvoicePdfSource();
  @override
  Future<WorkInvoicePdfDocument> load(WorkInvoicePdfRequest request) async {
    throw const WorkInvoicePdfException(
      'PDF invoices are not available yet. Please try again later.',
    );
  }
}

/// Explicit local-review implementation only. No remote fonts, network, writes,
/// payment mutation or implied invoice issuance.
class LocalReviewWorkInvoicePdfSource implements WorkInvoicePdfSource {
  const LocalReviewWorkInvoicePdfSource();
  @override
  Future<WorkInvoicePdfDocument> load(WorkInvoicePdfRequest request) async {
    final invoice = request.invoice;
    if (request.accountId.isEmpty ||
        request.storeId.isEmpty ||
        invoice.id.isEmpty ||
        request.items.length > 500 ||
        request.items.any(
          (line) =>
              line.quantity <= 0 ||
              line.unitPricePaise < 0 ||
              line.lineTotalPaise < 0,
        ) ||
        !invoice.validBillAmounts ||
        (!invoice.discount.isEmpty &&
            (request.items.isEmpty ||
                request.items.fold<int>(
                      0,
                      (sum, line) => sum + line.lineTotalPaise,
                    ) !=
                    invoice.payableMinor ||
                request.items.fold<int>(
                      0,
                      (sum, line) => sum + line.unitPricePaise * line.quantity,
                    ) !=
                    invoice.subtotalMinor))) {
      throw const WorkInvoicePdfException('This invoice cannot be prepared.');
    }
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Variable.ttf'),
    );
    final document = pw.Document(
      title: invoice.id,
      author: 'MoolSocial',
      creator: 'MoolSocial invoice preview',
    );
    final navy = PdfColor.fromHex('#080078');
    final muted = PdfColor.fromHex('#596078');
    String money(int paise) =>
        '₹${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';
    final billing = invoice.billingDetails;
    final date = invoice.issuedAt.toLocal();
    final buyer = {
      if (billing.business && billing.businessName.isNotEmpty)
        billing.businessName,
      if (billing.name.isNotEmpty) billing.name,
      invoice.customer,
      if (billing.business && billing.gst.isNotEmpty) 'GST: ${billing.gst}',
      if (billing.address.isNotEmpty) billing.address,
    }.join('\n');
    final embeddedFont = font.getFont(pw.Context(document: document.document));
    final text = [
      invoice.sellerName,
      invoice.id,
      buyer,
      invoice.items,
      request.paymentStatus,
      ...request.items.expand((line) => [line.name, line.pack]),
    ].join('\n');
    if (text.runes.any(
      (rune) => rune != 10 && rune != 13 && !embeddedFont.isRuneSupported(rune),
    )) {
      return Future.error(
        const WorkInvoicePdfException(
          'This preview cannot display some invoice characters yet. The invoice details have been preserved.',
        ),
      );
    }
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 18),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(fontSize: 22, color: navy),
              ),
              pw.Text(
                'PREVIEW - NOT ISSUED',
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated with MoolSocial',
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Text(
            invoice.sellerName.isEmpty ? 'Store invoice' : invoice.sellerName,
            style: pw.TextStyle(fontSize: 18, color: navy),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${invoice.id}\n${date.day}/${date.month}/${date.year}',
            style: pw.TextStyle(fontSize: 10, color: muted),
          ),
          pw.SizedBox(height: 22),
          pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, color: muted)),
          pw.SizedBox(height: 6),
          pw.Text(buyer, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 22),
          if (request.items.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Item / pack', 'Qty', 'Unit price', 'Amount'],
              data: request.items
                  .map(
                    (line) => [
                      '${line.name}\n${line.pack}',
                      '${line.quantity}',
                      money(line.unitPricePaise),
                      money(
                        invoice.discountMinor == 0
                            ? line.lineTotalPaise
                            : line.unitPricePaise * line.quantity,
                      ),
                    ],
                  )
                  .toList(),
              columnWidths: {
                0: const pw.FlexColumnWidth(5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F0F2FA'),
              ),
              headerStyle: pw.TextStyle(fontSize: 10, color: navy),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.all(8),
              border: null,
            )
          else
            pw.Text(invoice.items),
          pw.SizedBox(height: 20),
          if (invoice.discountMinor > 0) ...[
            pw.Text('Subtotal   ${money(invoice.subtotalMinor)}'),
            pw.Text('Discount   −${money(invoice.discountMinor)}'),
            pw.SizedBox(height: 8),
          ],
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Invoice total   ${money(invoice.payableMinor)}',
              style: pw.TextStyle(fontSize: 18, color: navy),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            request.paymentStatus,
            style: pw.TextStyle(fontSize: 10, color: muted),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Preview only. Not an issued invoice or proof of payment.',
            style: pw.TextStyle(fontSize: 9, color: muted),
          ),
        ],
      ),
    );
    return WorkInvoicePdfDocument(
      identity: request.identity,
      fileName: invoice.pdfFileName,
      bytes: await document.save(),
      reviewOnly: true,
    );
  }
}
