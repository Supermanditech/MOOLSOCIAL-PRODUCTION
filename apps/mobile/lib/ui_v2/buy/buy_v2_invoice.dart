import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_models.dart';
import 'buy_v2_design.dart';

enum BuyV2InvoiceDownloadOutcome { saved, cancelled, unavailable, failed }

@immutable
class BuyV2InvoiceDocument {
  const BuyV2InvoiceDocument({required this.order});

  final BuyV2Order order;

  String get suggestedFileName => 'MoolSocial-invoice-${order.id}.pdf';

  bool get hasExactLines => order.lines.isNotEmpty;
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
    if (_downloading) return;
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
            const Text(
              'Order invoice',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
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
                            order.id,
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
                  if (order.paymentMethod case final payment?)
                    _InvoiceFact(label: 'Payment method', value: payment),
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
              'Keep this invoice with your order records. Download availability depends on the invoice issued for this order.',
              textAlign: TextAlign.center,
              style: context.buyMeta.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: BuyV2Colors.line)),
          ),
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: ValueKey('buy-download-invoice-${order.id}'),
              onPressed: _downloading ? null : _download,
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

class _InvoiceAmountRow extends StatelessWidget {
  const _InvoiceAmountRow({
    required this.label,
    required this.amount,
    this.prominent = false,
  });

  final String label;
  final int amount;
  final bool prominent;

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
          Text(buyV2Money(amount), style: style),
        ],
      ),
    );
  }
}
