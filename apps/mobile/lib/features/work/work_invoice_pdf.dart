import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../shared/commerce/commerce_invoice_document.dart';
import '../../shared/commerce/commerce_invoice_pdf.dart';
export '../../shared/commerce/commerce_invoice_document.dart';

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
    this.details,
  }) : items = List.unmodifiable(items);
  final String accountId, storeId, paymentStatus;
  final CommerceInvoiceDocumentDetails? details;
  final WorkspaceCustomerInvoice invoice;
  final List<WorkspaceOrderItemSnapshot> items;
  String get identity =>
      '$accountId/$storeId/${invoice.id}'
      '${details == null ? '' : '/${details!.format.name}/${details!.documentId}'}';
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

abstract interface class WorkInvoicePrintSource {
  Future<WorkInvoicePdfDocument> forPrint(
    WorkInvoicePdfRequest request,
    PdfPageFormat paper,
    List<int>? pages,
  );
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
class LocalReviewWorkInvoicePdfSource
    implements WorkInvoicePdfSource, WorkInvoicePrintSource {
  const LocalReviewWorkInvoicePdfSource({
    this.printPageFormat,
    this.printPages,
  });
  final PdfPageFormat? printPageFormat;
  final List<int>? printPages;
  @override
  Future<WorkInvoicePdfDocument> forPrint(
    WorkInvoicePdfRequest request,
    PdfPageFormat paper,
    List<int>? pages,
  ) => LocalReviewWorkInvoicePdfSource(
    printPageFormat: paper,
    printPages: pages,
  ).load(request);
  @override
  Future<WorkInvoicePdfDocument> load(WorkInvoicePdfRequest request) async {
    final invoice = request.invoice;
    if (request.accountId.isEmpty ||
        request.storeId.isEmpty ||
        invoice.id.isEmpty ||
        (invoice.seller != null &&
            (!invoice.seller!.valid ||
                invoice.seller!.storeId != request.storeId)) ||
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
    final details = request.details;
    if (details != null &&
        (!details.valid ||
            details.accountId != request.accountId ||
            details.storeId != request.storeId ||
            details.invoiceId != invoice.id ||
            details.orderId != invoice.orderId ||
            (details.format != CommerceInvoiceFormat.platformFee &&
                details.totalMinor != invoice.payableMinor))) {
      throw const WorkInvoicePdfException(
        'The document details do not match this invoice.',
      );
    }
    if (details == null &&
        request.items.isNotEmpty &&
        (request.items.any(
              (l) => l.lineTotalPaise > l.unitPricePaise * l.quantity,
            ) ||
            request.items.fold<int>(0, (s, l) => s + l.lineTotalPaise) !=
                invoice.payableMinor ||
            request.items.fold<int>(
                  0,
                  (s, l) => s + l.unitPricePaise * l.quantity,
                ) !=
                invoice.subtotalMinor)) {
      throw const WorkInvoicePdfException(
        'The invoice item totals do not match.',
      );
    }
    final renderDetails = details ?? _localDocument(request);
    if (!renderDetails.valid) {
      throw const WorkInvoicePdfException(
        'The invoice details are incomplete or inconsistent.',
      );
    }
    try {
      final bytes = await renderCommerceInvoicePdf(
        renderDetails,
        printPageFormat: printPageFormat,
        printPages: printPages,
      );
      final suffix = details == null
          ? ''
          : '-${commerceInvoiceFileComponent(details.documentId)}-${details.format.name}';
      return WorkInvoicePdfDocument(
        identity: request.identity,
        fileName: invoice.pdfFileName.replaceFirst(
          RegExp(r'\.pdf$'),
          '$suffix.pdf',
        ),
        bytes: bytes,
        reviewOnly: true,
      );
    } on FormatException {
      return Future<WorkInvoicePdfDocument>.error(
        const WorkInvoicePdfException(
          'This preview cannot display some invoice characters yet. The invoice details have been preserved.',
        ),
      );
    }
  }
}

/// Adapts existing immutable Counter Sale snapshots, not current Store settings.
CommerceInvoiceDocumentDetails _localDocument(WorkInvoicePdfRequest request) {
  final invoice = request.invoice;
  final billing = invoice.billingDetails;
  return CommerceInvoiceDocumentDetails(
    accountId: request.accountId,
    storeId: request.storeId,
    invoiceId: invoice.id,
    orderId: invoice.orderId,
    documentId: invoice.id,
    sourceId: 'local-review',
    format: CommerceInvoiceFormat.seller,
    issuedAt: invoice.issuedAt,
    totalMinor: invoice.payableMinor,
    sellerName: invoice.sellerName,
    itemsSummary: invoice.items,
    itemBreakdownUnavailable: request.items.isEmpty,
    paymentStatus: request.paymentStatus,
    issuer: CommerceInvoiceIssuer(
      legalName: invoice.seller?.legalName ?? '',
      address: invoice.seller?.invoiceAddress ?? '',
    ),
    recipient: {
      if (billing.business && billing.businessName.isNotEmpty)
        'Business': billing.businessName,
      if (billing.name.isNotEmpty) 'Name': billing.name,
      'Contact': invoice.customer,
      if (billing.address.isNotEmpty) 'Billing address': billing.address,
      if (billing.business && billing.gst.isNotEmpty) 'GSTIN': billing.gst,
    },
    lines: [
      for (final item in request.items)
        CommerceInvoiceDocumentLine(
          description: item.name,
          pack: item.pack,
          quantity: item.quantity,
          unitPriceMinor: item.unitPricePaise,
          discountMinor:
              item.unitPricePaise * item.quantity - item.lineTotalPaise,
        ),
    ],
  );
}
