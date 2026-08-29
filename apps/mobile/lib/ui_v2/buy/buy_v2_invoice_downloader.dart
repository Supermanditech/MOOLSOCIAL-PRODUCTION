import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_models.dart';
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
  final subtotal = order.lines.fold<int>(
    0,
    (total, line) => total + line.total,
  );
  final lines = <String>[
    'MoolSocial order invoice',
    'Order ID: ${_invoiceText(order.id)}',
    'Order type: ${_destinationLabel(order.destination)}',
    'Seller: ${_invoiceText(order.partner)}',
    'Seller role: ${_invoiceText(order.partnerType)}',
    if (order.paymentMethod case final value?)
      'Payment method: ${_invoiceText(value)}',
    if (order.paymentTermLabel case final value?)
      'Payment term: ${_invoiceText(value)}',
    if (order.amountPaidNow case final value?) 'Amount paid now: INR $value',
    if (order.balanceDue > 0)
      'Balance due: INR ${order.balanceDue} - '
          '${_invoiceText(order.balanceDueLabel ?? 'Due later')}',
    if (order.recipient case final value?) 'Recipient: ${_invoiceText(value)}',
    'Address: ${_invoiceText(order.addressLine ?? order.destinationLabel)}',
    'Expected: ${_invoiceText(order.promise)}',
    if (order.deliveryInstruction case final value?)
      'Delivery instruction: ${_invoiceText(value)}',
    '',
    'Items placed',
    for (final line in order.lines)
      '${line.quantity} x ${_invoiceText(line.product.title)} '
          '(${_invoiceText(line.product.pack)}) - INR ${line.total}',
    '',
    'Items subtotal: INR $subtotal',
    if (order.tip > 0) 'Delivery tip: INR ${order.tip}',
    if (order.discount > 0) 'Coupon saving: -INR ${order.discount}',
    'Order total: INR ${order.total}',
  ];
  return <String, Object>{
    'fileName': _safeInvoiceFileName(invoice.suggestedFileName),
    'lines': lines,
  };
}

String _invoiceText(String value) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final safe = normalized.isEmpty ? 'Not provided' : normalized;
  return safe.length <= 240 ? safe : safe.substring(0, 240);
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
