import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_models.dart';
import '../universal/mool_global_navigation_v2.dart';
import 'buy_v2_design.dart';

enum BuyV2InvoiceDownloadOutcome { saved, cancelled, unavailable, failed }

@immutable
class BuyV2InvoiceDocument {
  const BuyV2InvoiceDocument({required this.order});

  final BuyV2Order order;

  String get suggestedFileName => 'MoolSocial-invoice-${order.id}.pdf';

  bool get hasExactLines =>
      order.lines.isNotEmpty &&
      (order.taxInvoiceState == null ||
          ((order.taxInvoiceState == BuyV2TaxInvoiceState.ready ||
                  order.taxInvoiceState == BuyV2TaxInvoiceState.corrected) &&
              order.taxInvoiceDetails != null));
}

typedef BuyV2InvoiceDownloader =
    Future<BuyV2InvoiceDownloadOutcome> Function(BuyV2InvoiceDocument invoice);

Future<void> showBuyV2InvoicePage(
  BuildContext context, {
  required BuyV2Order order,
  BuyV2InvoiceDownloader? downloader,
}) {
  HapticFeedback.selectionClick();
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/app/buy/order/${order.id}/invoice'),
      builder: (_) => BuyV2InvoicePage(order: order, downloader: downloader),
    ),
  );
}

class BuyV2InvoicePage extends StatefulWidget {
  const BuyV2InvoicePage({super.key, required this.order, this.downloader});

  final BuyV2Order order;
  final BuyV2InvoiceDownloader? downloader;

  @override
  State<BuyV2InvoicePage> createState() => _BuyV2InvoicePageState();
}

class _BuyV2InvoicePageState extends State<BuyV2InvoicePage> {
  bool _downloading = false;

  Future<void> _download() async {
    final order = widget.order;
    final legalInvoiceReady =
        order.taxInvoiceState == null ||
        ((order.taxInvoiceState == BuyV2TaxInvoiceState.ready ||
                order.taxInvoiceState == BuyV2TaxInvoiceState.corrected) &&
            order.taxInvoiceDetails != null);
    if (_downloading || !legalInvoiceReady) return;
    HapticFeedback.selectionClick();
    setState(() => _downloading = true);

    var outcome = BuyV2InvoiceDownloadOutcome.unavailable;
    try {
      final downloader = widget.downloader;
      if (downloader != null) {
        outcome = await downloader(BuyV2InvoiceDocument(order: widget.order));
      }
    } catch (_) {
      outcome = BuyV2InvoiceDownloadOutcome.failed;
    }

    if (!mounted) return;
    setState(() => _downloading = false);
    final message = switch (outcome) {
      BuyV2InvoiceDownloadOutcome.saved => 'Invoice saved to this device.',
      BuyV2InvoiceDownloadOutcome.cancelled => 'Invoice save cancelled.',
      BuyV2InvoiceDownloadOutcome.unavailable =>
        'Invoice download is not available for this order yet. You can still view it here.',
      BuyV2InvoiceDownloadOutcome.failed =>
        'Invoice could not be downloaded. Try again.',
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final view = View.of(context);
    final viewPadding = EdgeInsets.fromViewPadding(
      view.viewPadding,
      view.devicePixelRatio,
    );
    final exportedBottomClearance = math.max(
      36.0,
      math.max(
        viewPadding.bottom,
        moolAndroidExportedSemanticsClearance(
          viewPadding: viewPadding,
          platform: defaultTargetPlatform,
        ),
      ),
    );
    final taxInvoice = order.taxInvoiceDetails;
    final legalInvoiceRequired = order.taxInvoiceState != null;
    final legalInvoiceReady =
        !legalInvoiceRequired ||
        ((order.taxInvoiceState == BuyV2TaxInvoiceState.ready ||
                order.taxInvoiceState == BuyV2TaxInvoiceState.corrected) &&
            taxInvoice != null);
    final subtotal = order.lines.fold<int>(
      0,
      (total, line) => total + line.total,
    );
    return Scaffold(
      key: ValueKey('buy-invoice-page-${order.id}'),
      backgroundColor: BuyV2Colors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: BuyV2Colors.navy,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('buy-invoice-back'),
          tooltip: 'Back to order',
          onPressed: Navigator.of(context).pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              legalInvoiceRequired ? 'Tax invoice' : 'Order invoice',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              order.id,
              style: const TextStyle(
                color: BuyV2Colors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: ValueKey('buy-invoice-scroll-${order.id}'),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
          children: [
            Semantics(
              container: true,
              label:
                  '${order.destination.label} order invoice ${order.id}, total ${buyV2Money(order.total)}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10085F), BuyV2Colors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INVOICE',
                            style: TextStyle(
                              color: BuyV2Colors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            taxInvoice?.invoiceNumber ?? order.id,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      buyV2Money(order.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (legalInvoiceRequired) ...[
              const SizedBox(height: 9),
              if (!legalInvoiceReady)
                Container(
                  key: ValueKey(
                    'buy-tax-invoice-${order.taxInvoiceState!.name}',
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: buyV2CardDecoration(
                    color: BuyV2Colors.softOrange,
                    radius: 15,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: BuyV2Colors.navy,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.taxInvoiceState ==
                                      BuyV2TaxInvoiceState.pending
                                  ? 'Tax invoice is being prepared'
                                  : 'Tax invoice is unavailable',
                              style: context.buyTitle.copyWith(fontSize: 13),
                            ),
                            Text(
                              order.taxInvoiceState ==
                                      BuyV2TaxInvoiceState.pending
                                  ? 'Return after the seller issues the final tax document.'
                                  : 'The legal tax details have not been provided for this order.',
                              style: context.buyMeta.copyWith(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (legalInvoiceReady && taxInvoice != null) ...[
                _InvoiceSection(
                  key: ValueKey('buy-tax-invoice-details-${order.id}'),
                  title: order.taxInvoiceState == BuyV2TaxInvoiceState.corrected
                      ? 'Corrected tax invoice'
                      : 'Tax invoice details',
                  child: Column(
                    children: [
                      _InvoiceFact(
                        label: 'Invoice number',
                        value: taxInvoice.invoiceNumber,
                      ),
                      _InvoiceFact(
                        label: 'Invoice date',
                        value: MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(taxInvoice.issuedAt),
                      ),
                      const _InvoiceFact(
                        label: 'Document copy',
                        value: 'Original for recipient',
                      ),
                      _InvoiceFact(
                        label: 'Purchase type',
                        value: order.destination == BuyV2Destination.wholesale
                            ? 'Wholesale / business purchase'
                            : 'Consumer retail purchase',
                      ),
                      _InvoiceFact(
                        label: 'Seller legal name',
                        value: taxInvoice.sellerLegalName,
                      ),
                      _InvoiceFact(
                        label: 'Seller address',
                        value: taxInvoice.sellerAddress,
                      ),
                      _InvoiceFact(
                        label: 'Seller GSTIN',
                        value: taxInvoice.sellerGstin,
                      ),
                      if (taxInvoice.sellerPan case final value?)
                        _InvoiceFact(label: 'Seller PAN', value: value),
                      if (taxInvoice.sellerCin case final value?)
                        _InvoiceFact(label: 'Seller CIN', value: value),
                      if (taxInvoice.sellerFssaiNumber case final value?)
                        _InvoiceFact(
                          label: 'FSSAI licence / registration',
                          value: value,
                        ),
                      if (taxInvoice.recipientLegalName case final value?)
                        _InvoiceFact(label: 'Recipient', value: value),
                      if (taxInvoice.recipientBillingAddress case final value?)
                        _InvoiceFact(
                          label: 'Recipient billing address',
                          value: value,
                        ),
                      if (taxInvoice.buyerGstin case final buyerGstin?)
                        _InvoiceFact(label: 'Buyer GSTIN', value: buyerGstin),
                      _InvoiceFact(
                        label: 'Place of supply',
                        value: taxInvoice.placeOfSupply,
                      ),
                      _InvoiceFact(
                        label: 'Reverse charge',
                        value: taxInvoice.reverseCharge ? 'Yes' : 'No',
                      ),
                      if (taxInvoice.irn case final value?)
                        _InvoiceFact(label: 'IRN', value: value),
                      if (taxInvoice.acknowledgementNumber case final value?)
                        _InvoiceFact(
                          label: 'Acknowledgement number',
                          value: value,
                        ),
                      if (taxInvoice.authorizedSignatory case final value?)
                        _InvoiceFact(
                          label: 'Authorized signatory',
                          value: value,
                        ),
                      if (taxInvoice.supplyStatement case final value?)
                        _InvoiceFact(label: 'Tax treatment', value: value),
                      if (taxInvoice.revisionLabel case final revision?)
                        _InvoiceFact(label: 'Correction', value: revision),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                _InvoiceSection(
                  key: ValueKey('buy-tax-breakdown-${order.id}'),
                  title: 'Tax breakdown',
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < taxInvoice.lines.length;
                        index++
                      ) ...[
                        _TaxInvoiceLine(line: taxInvoice.lines[index]),
                        if (index < taxInvoice.lines.length - 1)
                          const Divider(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
              if (order.platformTaxInvoiceDetails case final platformTax?) ...[
                const SizedBox(height: 9),
                _InvoiceSection(
                  key: ValueKey('buy-platform-tax-invoice-${order.id}'),
                  title: 'MoolSocial service tax invoice',
                  child: Column(
                    children: [
                      _InvoiceFact(
                        label: 'Invoice number',
                        value: platformTax.invoiceNumber,
                      ),
                      _InvoiceFact(
                        label: 'Invoice date',
                        value: MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(platformTax.issuedAt),
                      ),
                      _InvoiceFact(
                        label: 'Service provider',
                        value: platformTax.sellerLegalName,
                      ),
                      _InvoiceFact(
                        label: 'Registered address',
                        value: platformTax.sellerAddress,
                      ),
                      _InvoiceFact(
                        label: 'Provider GSTIN',
                        value: platformTax.sellerGstin,
                      ),
                      if (platformTax.recipientLegalName case final value?)
                        _InvoiceFact(label: 'Recipient', value: value),
                      if (platformTax.buyerGstin case final value?)
                        _InvoiceFact(label: 'Buyer GSTIN', value: value),
                      _InvoiceFact(
                        label: 'Place of supply',
                        value: platformTax.placeOfSupply,
                      ),
                      _InvoiceFact(
                        label: 'Reverse charge',
                        value: platformTax.reverseCharge ? 'Yes' : 'No',
                      ),
                      for (final line in platformTax.lines) ...[
                        const Divider(height: 14),
                        _TaxInvoiceLine(line: line),
                      ],
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 9),
            _InvoiceSection(
              title: 'Order details',
              child: Column(
                children: [
                  _InvoiceFact(label: 'Order ID', value: order.id),
                  _InvoiceFact(
                    label: 'Order type',
                    value: order.destination.label,
                  ),
                  _InvoiceFact(label: 'Seller', value: order.partner),
                  _InvoiceFact(label: 'Seller role', value: order.partnerType),
                  if (order.buyerName case final buyer?)
                    _InvoiceFact(label: 'Buyer', value: buyer),
                  if (order.buyerType case final buyerType?)
                    _InvoiceFact(label: 'Buyer role', value: buyerType),
                  if (order.paymentMethod case final payment?)
                    _InvoiceFact(label: 'Payment method', value: payment),
                  if (order.purchaseOrderReference case final reference?)
                    _InvoiceFact(label: 'Purchase order', value: reference),
                  if (order.paymentTermLabel case final term?)
                    _InvoiceFact(label: 'Payment term', value: term),
                  if (order.amountPaidNow case final paidNow?)
                    _InvoiceFact(
                      label: 'Amount paid now',
                      value: buyV2Money(paidNow),
                    ),
                  if (order.paymentStatusLabel case final paymentStatus?)
                    _InvoiceFact(label: 'Payment status', value: paymentStatus),
                  if (order.balanceDue > 0)
                    _InvoiceFact(
                      label: 'Balance due',
                      value:
                          '${buyV2Money(order.balanceDue)} · '
                          '${order.balanceDueLabel ?? 'Due later'}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            _InvoiceSection(
              key: ValueKey('buy-invoice-items-${order.id}'),
              title: 'Items placed',
              child: order.lines.isEmpty
                  ? _InvoiceUnavailableItems(order: order)
                  : Column(
                      children: [
                        for (var index = 0; index < order.lines.length; index++)
                          _InvoiceLine(
                            line: order.lines[index],
                            showDivider: index < order.lines.length - 1,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 9),
            _InvoiceSection(
              title: 'Amount',
              child: Column(
                children: [
                  if (order.lines.isNotEmpty)
                    _InvoiceAmountRow(
                      label: 'Items subtotal',
                      amount: subtotal,
                    ),
                  if (order.tip > 0)
                    _InvoiceAmountRow(label: 'Delivery tip', amount: order.tip),
                  if (order.discount > 0)
                    _InvoiceAmountRow(
                      label: 'Coupon saving',
                      amount: order.discount,
                      deduction: true,
                    ),
                  if (order.tax > 0)
                    _InvoiceAmountRow(
                      label: 'GST and taxes',
                      amount: order.tax,
                    ),
                  if (order.freight > 0)
                    _InvoiceAmountRow(label: 'Freight', amount: order.freight),
                  if (order.deliveryFee > 0)
                    _InvoiceAmountRow(
                      label: 'Delivery fee',
                      amount: order.deliveryFee,
                    ),
                  if (order.paymentCharge > 0)
                    _InvoiceAmountRow(
                      label: 'Payment charge',
                      amount: order.paymentCharge,
                    ),
                  _InvoiceAmountRow(
                    label: 'Order total',
                    amount: order.total,
                    prominent: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            _InvoiceSection(
              title: 'Delivery',
              child: Column(
                children: [
                  if (order.recipient case final recipient?)
                    _InvoiceFact(label: 'Recipient', value: recipient),
                  _InvoiceFact(
                    label: 'Address',
                    value: order.addressLine ?? order.destinationLabel,
                  ),
                  _InvoiceFact(label: 'Expected', value: order.promise),
                  if (order.dispatchPromise case final dispatchPromise?)
                    _InvoiceFact(
                      label: 'Dispatch promise',
                      value: dispatchPromise,
                    ),
                  if (order.deliveryPartnerName case final partner?)
                    _InvoiceFact(label: 'Delivery partner', value: partner),
                  if (order.deliveryServiceLevel case final serviceLevel?)
                    _InvoiceFact(
                      label: 'Delivery service',
                      value: serviceLevel,
                    ),
                  if (order.trackingReference case final trackingReference?)
                    _InvoiceFact(
                      label: 'Tracking reference',
                      value: trackingReference,
                    ),
                  if (order.deliveryInstruction case final instruction?)
                    _InvoiceFact(
                      label: 'Delivery instruction',
                      value: instruction,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              key: ValueKey('buy-invoice-record-notice-${order.id}'),
              'Keep this invoice with your order records. Download availability depends on the invoice issued for this order.',
              textAlign: TextAlign.center,
              style: context.buyMeta.copyWith(fontSize: 9),
            ),
            const SizedBox(height: 12),
            Padding(
              key: const ValueKey('buy-invoice-bottom-safe-area'),
              padding: EdgeInsets.only(bottom: exportedBottomClearance),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  key: ValueKey('buy-download-invoice-${order.id}'),
                  onPressed: _downloading || !legalInvoiceReady
                      ? null
                      : _download,
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _downloading ? 'Preparing invoice' : 'Download invoice',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.buyTitle.copyWith(fontSize: 13)),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class _InvoiceFact extends StatelessWidget {
  const _InvoiceFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: context.buyMeta.copyWith(fontSize: 9)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.buyBody.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLine extends StatelessWidget {
  const _InvoiceLine({required this.line, required this.showDivider});

  final BuyV2CartLine line;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BuyV2Colors.softBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${line.quantity}×',
                  style: const TextStyle(
                    color: BuyV2Colors.navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.product.title, style: context.buyBody),
                    Text(
                      '${line.product.pack} · ${buyV2Money(line.product.price)} each',
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                buyV2Money(line.total),
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _InvoiceUnavailableItems extends StatelessWidget {
  const _InvoiceUnavailableItems({required this.order});

  final BuyV2Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(order.itemSummary, style: context.buyBody),
    );
  }
}

class _TaxInvoiceLine extends StatelessWidget {
  const _TaxInvoiceLine({required this.line});

  final BuyV2TaxInvoiceLine line;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line.description, style: context.buyBody),
        const SizedBox(height: 3),
        _InvoiceFact(label: 'HSN/SAC', value: line.hsnSac),
        if (line.quantity case final quantity?)
          _InvoiceFact(
            label: 'Quantity',
            value: line.unit == null ? '$quantity' : '$quantity ${line.unit}',
          ),
        if (line.unitPrice case final unitPrice?)
          _InvoiceFact(label: 'Unit price', value: buyV2Money(unitPrice)),
        _InvoiceFact(
          label: 'Taxable value',
          value: buyV2Money(line.taxableValue),
        ),
        _InvoiceFact(
          label: 'GST rate',
          value: '${line.gstRate.toStringAsFixed(2)}%',
        ),
        if (line.cgst > 0)
          _InvoiceFact(label: 'CGST', value: buyV2Money(line.cgst)),
        if (line.sgst > 0)
          _InvoiceFact(label: 'SGST', value: buyV2Money(line.sgst)),
        if (line.igst > 0)
          _InvoiceFact(label: 'IGST', value: buyV2Money(line.igst)),
        if (line.cess > 0)
          _InvoiceFact(label: 'Cess', value: buyV2Money(line.cess)),
      ],
    );
  }
}

class _InvoiceAmountRow extends StatelessWidget {
  const _InvoiceAmountRow({
    required this.label,
    required this.amount,
    this.prominent = false,
    this.deduction = false,
  });

  final String label;
  final int amount;
  final bool prominent;
  final bool deduction;

  @override
  Widget build(BuildContext context) {
    final style = prominent
        ? context.buyTitle.copyWith(fontSize: 15)
        : context.buyBody;
    return Container(
      padding: EdgeInsets.only(top: prominent ? 8 : 4, bottom: 4),
      decoration: prominent
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: BuyV2Colors.line)),
            )
          : null,
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${deduction ? '−' : ''}${buyV2Money(amount)}', style: style),
        ],
      ),
    );
  }
}
