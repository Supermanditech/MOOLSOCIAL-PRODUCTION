import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'commerce_invoice_document.dart';

/// Shared renderer for all three reference formats. Never fetches mutable Store
/// settings, creates fees/taxes, changes payment state or issues a document.
Future<Uint8List> renderCommerceInvoicePdf(
  CommerceInvoiceDocumentDetails details,
) async {
  if (!details.valid) throw const FormatException('Invalid invoice document.');
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Inter-Variable.ttf'),
  );
  final doc = pw.Document(
    title: details.documentId,
    author: 'MoolSocial',
    creator: 'MoolSocial invoice preview',
  );
  final navy = PdfColor.fromHex('#080078');
  final muted = PdfColor.fromHex('#596078');
  final bandColor = PdfColor.fromHex('#EEF0F6');
  final lineColor = PdfColor.fromHex('#C8CDDA');
  final format = details.format;
  final taxReady = details.taxBreakdownProvided;
  final summary = format == CommerceInvoiceFormat.summary;
  final fee = format == CommerceInvoiceFormat.platformFee;
  final title = summary
      ? (details.receivedMinor == details.totalMinor
            ? 'Order summary & receipt'
            : 'Order summary')
      : fee
      ? (taxReady ? 'Platform fee tax invoice' : 'Platform fee invoice')
      : (taxReady ? 'Tax invoice' : 'Order invoice');
  final issuer = details.issuer;
  final rows = details.lines;
  final total = details.totalMinor;
  final gross = details.grossMinor;
  final discount = details.discountMinor;
  final taxes = details.taxMinor;
  final taxNames = [
    for (final name in const ['CGST', 'SGST', 'IGST', 'Cess'])
      if (rows.any((l) => l.taxes.any((t) => t.label == name))) name,
  ];
  final documentId = details.documentId;
  final date = details.issuedAt;
  String dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  final customer = {
    ...details.recipient,
    if (details.deliveryAddress.isNotEmpty)
      'Delivery address': details.deliveryAddress,
    if (details.placeOfSupply.isNotEmpty)
      'Place of supply': details.placeOfSupply,
  };
  final payment = details.receivedMinor == null
      ? details.paymentStatus
      : '${details.receivedMinor == total
                ? 'Paid'
                : details.receivedMinor == 0
                ? 'Unpaid'
                : 'Part paid'}'
            ' | Received ${commerceInvoiceMoney(details.receivedMinor!)} | Due ${commerceInvoiceMoney(total - details.receivedMinor!)}';
  final dynamicText = [
    details.sellerName,
    ...issuer.fields.values,
    issuer.signatory,
    issuer.communicationAddress,
    documentId,
    details.orderId,
    ...customer.values,
    payment,
    details.itemsSummary,
    ...rows.expand((l) => [l.description, l.pack, l.classification]),
    details.terms,
    details.supplyStatement,
    details.deliveryPartner,
    details.paymentReference,
  ].join('\n');
  final embedded = font.getFont(pw.Context(document: doc.document));
  if (dynamicText.runes.any(
    (r) => r != 10 && r != 13 && !embedded.isRuneSupported(r),
  )) {
    return Future<Uint8List>.error(
      const FormatException('unsupported invoice characters'),
    );
  }
  pw.Widget band(String label) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    decoration: pw.BoxDecoration(
      color: bandColor,
      border: pw.Border.all(color: lineColor, width: .5),
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: navy,
      ),
    ),
  );
  pw.Widget fields(Map<String, String> values) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final e in values.entries)
        if (e.value.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${e.key}: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(text: e.value),
                ],
                style: const pw.TextStyle(fontSize: 9, height: 1.2),
              ),
            ),
          ),
    ],
  );
  String taxCell(CommerceInvoiceDocumentLine row, String name) {
    final matches = row.taxes.where((t) => t.label == name);
    return matches.isEmpty
        ? '-'
        : '${matches.single.rateLabel}\n${commerceInvoiceMoney(matches.single.amountMinor)}';
  }

  final headers = summary
      ? ['Item / pack', 'Qty', 'Unit price', 'Gross value']
      : fee
      ? [
          '#',
          'Particulars',
          taxReady ? 'Taxable amount' : 'Net value',
          ...taxNames.map((n) => '$n\nRate / amount'),
          'Total',
        ]
      : [
          'Particulars',
          'Qty',
          'Gross value',
          'Discount',
          taxReady ? 'Taxable value' : 'Net value',
          ...taxNames.map((n) => '$n\nRate / amount'),
          'Total',
        ];
  final data = <List<String>>[];
  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final name = [
      row.description,
      if (row.pack.isNotEmpty) row.pack,
      if (row.classification.isNotEmpty) 'HSN/SAC ${row.classification}',
    ].join('\n');
    data.add(
      summary
          ? [
              name,
              '${row.quantity}',
              commerceInvoiceMoney(row.unitPriceMinor),
              commerceInvoiceMoney(row.grossMinor),
            ]
          : fee
          ? [
              '${index + 1}',
              name,
              commerceInvoiceMoney(row.netMinor),
              ...taxNames.map((t) => taxCell(row, t)),
              commerceInvoiceMoney(row.totalMinor),
            ]
          : [
              name,
              '${row.quantity}',
              commerceInvoiceMoney(row.grossMinor),
              commerceInvoiceMoney(row.discountMinor),
              commerceInvoiceMoney(row.netMinor),
              ...taxNames.map((t) => taxCell(row, t)),
              commerceInvoiceMoney(row.totalMinor),
            ],
    );
  }
  final descriptionColumn = fee ? 1 : 0;
  pw.Widget moneyRow(String label, int value, {bool strong = false}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        color: strong ? bandColor : null,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(fontSize: strong ? 11 : 9, color: navy),
              ),
            ),
            pw.Text(
              commerceInvoiceMoney(value),
              style: pw.TextStyle(
                fontSize: strong ? 12 : 9,
                color: navy,
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      maxPages: 100,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                'MoolSocial',
                style: pw.TextStyle(
                  fontSize: 23,
                  color: navy,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'PREVIEW - NOT ISSUED',
                  style: pw.TextStyle(fontSize: 8, color: muted),
                ),
                pw.Text(
                  'For recipient review',
                  style: pw.TextStyle(fontSize: 8, color: muted),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: (c) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: lineColor, width: .5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Preview only - not issued or proof of payment',
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
            pw.Text(
              '${c.pageNumber} / ${c.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ),
      ),
      build: (_) => [
        band(fee ? 'Platform / service issuer' : 'Seller details'),
        if (issuer.fields.values.join().length > 700)
          fields({
            if (!fee && details.sellerName.isNotEmpty)
              'Store': details.sellerName,
            ...issuer.fields,
            'Document no.': documentId,
            'Date': dateLabel(date),
            'Order ID': details.orderId,
          })
        else
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: fields({
                  if (!fee && details.sellerName.isNotEmpty)
                    'Store': details.sellerName,
                  'Legal name': issuer.legalName,
                  'Address': issuer.address,
                  'State': issuer.state,
                  'Email': issuer.email,
                }),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                flex: 2,
                child: fields({
                  'Document no.': documentId,
                  'Date': dateLabel(date),
                  'Order ID': details.orderId,
                  'GSTIN': issuer.gstin,
                  'PAN': issuer.pan,
                  'CIN': issuer.cin,
                  'FSSAI': issuer.fssai,
                }),
              ),
            ],
          ),
        band('Recipient details - ${details.recipientRole.name}'),
        fields(customer),
        if (details.deliveryPartner.isNotEmpty == true)
          fields({'Delivery partner': details.deliveryPartner}),
        band(fee ? 'Service details' : '${summary ? 'Order' : 'Item'} details'),
        if (!taxReady)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Text(
              'Tax breakdown not supplied. This preview is not a tax invoice.',
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
          ),
        if (rows.isEmpty)
          pw.Text(details.itemsSummary, style: const pw.TextStyle(fontSize: 9))
        else
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            columnWidths: {
              for (var i = 0; i < headers.length; i++)
                i: pw.FlexColumnWidth(
                  i == descriptionColumn
                      ? 3.4
                      : (!summary && i == (fee ? 0 : 1))
                      ? .55
                      : 1.2,
                ),
            },
            cellAlignments: {
              for (var i = 0; i < headers.length; i++)
                i: i == descriptionColumn
                    ? pw.Alignment.centerLeft
                    : pw.Alignment.centerRight,
            },
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: navy,
            ),
            headerDecoration: pw.BoxDecoration(color: bandColor),
            cellStyle: const pw.TextStyle(fontSize: 8, height: 1.15),
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(color: lineColor, width: .4),
          ),
        pw.SizedBox(height: 10),
        // A Container inherits Column's spanning behavior. Explicitly keep the
        // financial summary and its payment state on the same physical page.
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 290,
                  child: pw.Column(
                    children: [
                      moneyRow('Gross value', gross),
                      if (discount > 0) moneyRow('Item discounts', -discount),
                      if (taxReady) moneyRow('Taxes', taxes),
                      for (final a in details.adjustments)
                        moneyRow(a.label, a.amountMinor),
                      moneyRow('Total', total, strong: true),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              fields({'Amount in words': commerceInvoiceAmountInWords(total)}),
              pw.SizedBox(height: 6),
              fields({
                'Payment': payment,
                if (details.paymentReference.isNotEmpty == true)
                  'Payment reference': details.paymentReference,
              }),
            ],
          ),
        ),
        if (!summary && details.reverseCharge != null)
          fields({'Reverse charge': details.reverseCharge! ? 'Yes' : 'No'}),
        if (!summary && details.supplyStatement.isNotEmpty)
          fields({'Supply note': details.supplyStatement}),
        if (!summary && issuer.signatory.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          fields({
            'For': issuer.legalName,
            'Authorised signatory (supplied)': issuer.signatory,
          }),
        ],
        if (details.terms.isNotEmpty == true) ...[
          band('Terms and information'),
          pw.Text(
            details.terms,
            style: const pw.TextStyle(fontSize: 8, height: 1.3),
          ),
        ],
        if (issuer.communicationAddress.isNotEmpty)
          fields({'Communication address': issuer.communicationAddress}),
      ],
    ),
  );
  return doc.save();
}
