import 'package:flutter/foundation.dart';
import 'buy_v2_design.dart' show buyV2HistoricalOrderEstimate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_customer_copy.dart';
import 'buy_v2_invoice.dart';

const _invoiceChannel = MethodChannel('com.moolsocial.app/invoice');

Future<BuyV2InvoiceDownloadOutcome> saveBuyV2InvoiceToDevice(
  BuyV2InvoiceDocument invoice,
) {
  return saveBuyV2InvoiceWithChannel(invoice);
}

@visibleForTesting
Future<BuyV2InvoiceDownloadOutcome> saveBuyV2InvoiceWithChannel(
  BuyV2InvoiceDocument invoice, {
  MethodChannel channel = _invoiceChannel,
  TargetPlatform? platform,
}) async {
  final target = platform ?? defaultTargetPlatform;
  if (kIsWeb || target != TargetPlatform.android || !invoice.hasExactLines) {
    return BuyV2InvoiceDownloadOutcome.unavailable;
  }

  try {
    final result = await channel.invokeMethod<String>(
      'saveInvoice',
      _platformInvoicePayload(invoice),
    );
    return switch (result) {
      'saved' => BuyV2InvoiceDownloadOutcome.saved,
      'cancelled' => BuyV2InvoiceDownloadOutcome.cancelled,
      'unavailable' => BuyV2InvoiceDownloadOutcome.unavailable,
      _ => BuyV2InvoiceDownloadOutcome.failed,
    };
  } on MissingPluginException {
    return BuyV2InvoiceDownloadOutcome.unavailable;
  } on PlatformException {
    return BuyV2InvoiceDownloadOutcome.failed;
  } on Object {
    return BuyV2InvoiceDownloadOutcome.failed;
  }
}

Map<String, Object> _platformInvoicePayload(BuyV2InvoiceDocument invoice) {
  final order = invoice.order;
  final subtotal = buyV2SumMinor(order.lines.map((line) => line.totalMinor));
  return <String, Object>{
    'fileName': _safeInvoiceFileName(invoice.suggestedFileName),
    'lines': _boundedInvoiceLines(_invoiceLogicalLines(order, subtotal)),
  };
}

Iterable<String> _invoiceLogicalLines(BuyV2Order order, int subtotal) sync* {
  yield* <String>[
    'MoolSocial order invoice',
    'Order ID: ${_invoiceText(order.id)}',
    if (order.taxInvoiceDetails case final taxInvoice?) ...[
      'Invoice number: ${_invoiceText(taxInvoice.invoiceNumber)}',
      'Invoice date: ${taxInvoice.issuedAt.toIso8601String()}',
      'Seller legal name: ${_invoiceText(taxInvoice.sellerLegalName)}',
      'Seller address: ${_invoiceText(taxInvoice.sellerAddress)}',
      'Seller GSTIN: ${_invoiceText(taxInvoice.sellerGstin)}',
      if (taxInvoice.sellerPan case final value?)
        'Seller PAN: ${_invoiceText(value)}',
      if (taxInvoice.sellerCin case final value?)
        'Seller CIN: ${_invoiceText(value)}',
      if (taxInvoice.sellerFssaiNumber case final value?)
        'Seller FSSAI: ${_invoiceText(value)}',
      if (taxInvoice.recipientLegalName case final value?)
        'Recipient: ${_invoiceText(value)}',
      if (taxInvoice.recipientBillingAddress case final value?)
        'Recipient billing address: ${_invoiceText(value)}',
      if (taxInvoice.buyerGstin case final value?)
        'Buyer GSTIN: ${_invoiceText(value)}',
      'Place of supply: ${_invoiceText(taxInvoice.placeOfSupply)}',
      'Reverse charge: ${taxInvoice.reverseCharge ? 'Yes' : 'No'}',
      if (taxInvoice.irn case final value?) 'IRN: ${_invoiceText(value)}',
      if (taxInvoice.acknowledgementNumber case final value?)
        'Acknowledgement number: ${_invoiceText(value)}',
      if (taxInvoice.authorizedSignatory case final value?)
        'Authorized signatory: ${_invoiceText(value)}',
      if (taxInvoice.supplyStatement case final value?)
        'Tax treatment: ${_invoiceText(value)}',
      if (taxInvoice.revisionLabel case final value?)
        'Correction: ${_invoiceText(value)}',
    ],
    'Order type: ${_destinationLabel(order.destination)}',
    'Seller: ${_invoiceText(order.customerPartner)}',
    'Seller role: ${_invoiceText(order.partnerType)}',
    if (order.buyerName case final value?) 'Buyer: ${_invoiceText(value)}',
    if (order.buyerType case final value?) 'Buyer role: ${_invoiceText(value)}',
    if (order.paymentMethod case final value?)
      'Payment method: ${_invoiceText(value)}',
    if (order.paymentTermLabel case final value?)
      'Payment term: ${_invoiceText(value)}',
    if (order.amountPaidNowMinor case final value?)
      'Amount paid now: INR ${_invoiceMinorNumber(value)}',
    if (order.paymentStatusLabel case final value?)
      'Payment status: ${_invoiceText(value)}',
    if (order.balanceDueMinor > 0)
      'Balance due: INR ${_invoiceMinorNumber(order.balanceDueMinor)} - '
          '${_invoiceText(order.balanceDueLabel ?? 'Due later')}',
    if (order.recipient case final value?) 'Recipient: ${_invoiceText(value)}',
    'Address: ${_invoiceText(order.addressLine ?? order.destinationLabel)}',
    'Recorded delivery estimate: ${_invoiceText(buyV2HistoricalOrderEstimate(order))}',
    if (order.dispatchPromise case final value?)
      'Dispatch promise: ${_invoiceText(value)}',
    if (order.deliveryPartnerName case final value?)
      'Delivery partner: ${_invoiceText(value)}',
    if (order.deliveryServiceLevel case final value?)
      'Delivery service: ${_invoiceText(value)}',
    if (order.trackingReference case final value?)
      'Tracking reference: ${_invoiceText(value)}',
    if (order.deliveryInstruction case final value?)
      'Delivery instruction: ${_invoiceText(value)}',
    '',
    'Items placed',
  ];
  for (final line in order.lines) {
    yield '${line.quantity} x ${_invoiceText(line.product.customerTitle)} '
          '(${_invoiceText(line.product.pack)}) - INR ${_invoiceMinorNumber(line.totalMinor)}';
  }
  if (order.taxInvoiceDetails case final taxInvoice?) {
    yield '';
    yield 'Tax breakdown';
    for (final line in taxInvoice.lines) {
      yield '${_invoiceText(line.description)} | HSN/SAC ${_invoiceText(line.hsnSac)} | '
            '${line.quantity == null ? '' : 'Quantity ${line.quantity}${line.unit == null ? '' : ' ${_invoiceText(line.unit!)}'} | '}'
            '${line.unitPriceMinor == null ? '' : 'Unit INR ${_invoiceMinorNumber(line.unitPriceMinor!)} | '}'
            'Taxable INR ${_invoiceMinorNumber(line.taxableValueMinor)} | GST ${line.gstRate.toStringAsFixed(2)}% | '
            'CGST ${_invoiceMinorNumber(line.cgstMinor)} | SGST ${_invoiceMinorNumber(line.sgstMinor)} | '
            'IGST ${_invoiceMinorNumber(line.igstMinor)} | Cess ${_invoiceMinorNumber(line.cessMinor)}';
    }
  }
  if (order.platformTaxInvoiceDetails case final platformTax?) {
    yield* <String>[
      '',
      'MoolSocial service tax invoice',
      'Invoice number: ${_invoiceText(platformTax.invoiceNumber)}',
      'Invoice date: ${platformTax.issuedAt.toIso8601String()}',
      'Service provider: ${_invoiceText(platformTax.sellerLegalName)}',
      'Provider address: ${_invoiceText(platformTax.sellerAddress)}',
      'Provider GSTIN: ${_invoiceText(platformTax.sellerGstin)}',
      if (platformTax.recipientLegalName case final value?)
        'Recipient: ${_invoiceText(value)}',
      if (platformTax.buyerGstin case final value?)
        'Buyer GSTIN: ${_invoiceText(value)}',
      'Place of supply: ${_invoiceText(platformTax.placeOfSupply)}',
      'Reverse charge: ${platformTax.reverseCharge ? 'Yes' : 'No'}',
    ];
    for (final line in platformTax.lines) {
      yield '${_invoiceText(line.description)} | HSN/SAC ${_invoiceText(line.hsnSac)} | '
            '${line.quantity == null ? '' : 'Quantity ${line.quantity}${line.unit == null ? '' : ' ${_invoiceText(line.unit!)}'} | '}'
            '${line.unitPriceMinor == null ? '' : 'Unit INR ${_invoiceMinorNumber(line.unitPriceMinor!)} | '}'
            'Taxable INR ${_invoiceMinorNumber(line.taxableValueMinor)} | GST ${line.gstRate.toStringAsFixed(2)}% | '
            'CGST ${_invoiceMinorNumber(line.cgstMinor)} | SGST ${_invoiceMinorNumber(line.sgstMinor)} | '
            'IGST ${_invoiceMinorNumber(line.igstMinor)} | Cess ${_invoiceMinorNumber(line.cessMinor)}';
    }
  }
  yield* <String>[
    '',
    'Items subtotal: INR ${_invoiceMinorNumber(subtotal)}',
    if (order.tipMinor > 0)
      'Delivery tip: INR ${_invoiceMinorNumber(order.tipMinor)}',
    if (order.discountMinor > 0)
      'Coupon saving: -INR ${_invoiceMinorNumber(order.discountMinor)}',
    if (order.taxMinor > 0)
      'GST and taxes: INR ${_invoiceMinorNumber(order.taxMinor)}',
    if (order.freightMinor > 0)
      'Freight: INR ${_invoiceMinorNumber(order.freightMinor)}',
    if (order.deliveryFeeMinor > 0)
      'Delivery fee: INR ${_invoiceMinorNumber(order.deliveryFeeMinor)}',
    if (order.paymentChargeMinor > 0)
      'Payment charge: INR ${_invoiceMinorNumber(order.paymentChargeMinor)}',
    'Order total: INR ${_invoiceMinorNumber(order.payableTotalMinor)}',
  ];
}

// Match the existing native transport limits without silently losing document
// content. Build lazily and reject before invoking the channel, never export a
// partial first200. Kotlin and Dart both measure these limits in UTF-16 units.
List<String> _boundedInvoiceLines(Iterable<String> logicalLines) {
  final output = <String>[];
  void add(String line) {
    if (output.length >= 200) throw const FormatException('Invoice exceeds the complete export limit.');
    output.add(line);
  }
  for (final line in logicalLines) {
    if (line.isEmpty) { add(''); continue; }
    final chunk = StringBuffer();
    var units = 0;
    for (final grapheme in line.characters) {
      if (grapheme.length > 500) {
        throw const FormatException('Invoice text cannot fit a complete native line.');
      }
      if (units + grapheme.length > 500) {
        add(chunk.toString()); chunk.clear(); units = 0;
      }
      chunk.write(grapheme); units += grapheme.length;
    }
    if (units > 0) add(chunk.toString());
  }
  return output;
}

String _invoiceMinorNumber(int minor) {
  final exact = buyV2ExactMinorAmount(minor: minor);
  final fraction = exact % 100;
  return fraction == 0
      ? '${exact ~/ 100}'
      : '${exact ~/ 100}.${fraction.toString().padLeft(2, '0')}';
}

String _invoiceText(String value) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return normalized.isEmpty ? 'Not provided' : normalized;
}

String _destinationLabel(BuyV2Destination destination) => switch (destination) {
  BuyV2Destination.shop => 'Shop',
  BuyV2Destination.wholesale => 'Wholesale',
  BuyV2Destination.medicine => 'Medicine',
  BuyV2Destination.orders => 'Orders',
};

String _safeInvoiceFileName(String value) {
  final normalized = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final base = normalized.toLowerCase().endsWith('.pdf')
      ? normalized.substring(0, normalized.length - 4)
      : normalized;
  final bounded = base.isEmpty
      ? 'MoolSocial-invoice'
      : base.substring(0, base.length > 100 ? 100 : base.length);
  return '$bounded.pdf';
}
