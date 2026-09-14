import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatInvoiceScreen extends StatelessWidget {
  const EatInvoiceScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final EatSession session;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final receipt = session.orderReceipt;
    if (receipt == null || receipt.id != orderId) {
      return EatPageScaffold(
        session: session,
        title: 'Bill not found',
        subtitle: 'Return to your food order',
        activeLocalAction: 'order',
        body: Center(
          child: FilledButton(
            key: const Key('eat-invoice-return-missing'),
            onPressed: () => context.go('/app/eat/order'),
            child: const Text('Choose food'),
          ),
        ),
      );
    }
    final subtotal =
        receipt.subtotal ??
        receipt.lines.fold<int>(0, (total, line) => total + line.total);
    return EatPageScaffold(
      key: const Key('eat-invoice-screen'),
      session: session,
      title: 'Food bill',
      subtitle: receipt.id,
      activeLocalAction: 'order',
      fallbackBackRoute: '/app/eat/order/$orderId/completed',
      body: ListView(
        key: const Key('eat-invoice-list'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xxl,
        ),
        children: [
          EatSurfaceCard(
            color: const Color(0xFFEDEEFF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CUSTOMER ORDER SUMMARY',
                  style: TextStyle(
                    color: MoolColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  receipt.restaurant.name,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _InvoiceFact(label: 'Order ID', value: receipt.id),
                _InvoiceFact(
                  label: 'Order date',
                  value: MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(receipt.createdAt),
                ),
                _InvoiceFact(label: 'Delivery', value: receipt.deliveryAddress),
                _InvoiceFact(
                  label: 'Payment',
                  value: receipt.paymentMethod.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          _InvoiceSection(
            title: 'Items',
            child: Column(
              children: [
                for (final line in receipt.lines)
                  _InvoiceFact(
                    label: '${line.quantity} × ${line.item.name}',
                    value: eatMoney(line.total),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          _InvoiceSection(
            title: 'Amount paid',
            child: Column(
              children: [
                _InvoiceAmount(label: 'Food', value: subtotal),
                _InvoiceAmount(label: 'Delivery', value: receipt.deliveryFee),
                _InvoiceAmount(label: 'GST and taxes', value: receipt.taxes),
                const Divider(),
                _InvoiceAmount(
                  label: 'Total',
                  value: receipt.total,
                  strong: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          if (receipt.taxInvoiceDetails case final taxInvoice?)
            _FoodTaxInvoice(
              key: const Key('eat-restaurant-tax-invoice'),
              title: taxInvoice.section9FiveSupply
                  ? 'Restaurant service tax invoice'
                  : 'Seller tax invoice',
              invoice: taxInvoice,
            )
          else
            const EatSurfaceCard(
              color: Color(0xFFFFF6E8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax invoice is not available yet',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'The customer order summary remains available. Return after the authorized issuer provides the final tax document.',
                    style: TextStyle(color: MoolColors.muted),
                  ),
                ],
              ),
            ),
          if (receipt.platformTaxInvoiceDetails
              case final platformInvoice?) ...[
            const SizedBox(height: MoolSpacing.sm),
            _FoodTaxInvoice(
              key: const Key('eat-platform-tax-invoice'),
              title: 'MoolSocial service tax invoice',
              invoice: platformInvoice,
            ),
          ],
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Food-business licence details appear only when supplied by the authorized seller or issuer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FoodTaxInvoice extends StatelessWidget {
  const _FoodTaxInvoice({
    required this.title,
    required this.invoice,
    super.key,
  });

  final String title;
  final EatTaxInvoiceDetails invoice;

  @override
  Widget build(BuildContext context) => _InvoiceSection(
    title: title,
    child: Column(
      children: [
        const _InvoiceFact(
          label: 'Document copy',
          value: 'Original for recipient',
        ),
        _InvoiceFact(label: 'Invoice number', value: invoice.invoiceNumber),
        _InvoiceFact(
          label: 'Invoice date',
          value: MaterialLocalizations.of(
            context,
          ).formatMediumDate(invoice.issuedAt),
        ),
        _InvoiceFact(label: 'Issued by', value: invoice.issuerLegalName),
        _InvoiceFact(label: 'Issuer address', value: invoice.issuerAddress),
        _InvoiceFact(label: 'Issuer GSTIN', value: invoice.issuerGstin),
        if (invoice.issuerPan case final value?)
          _InvoiceFact(label: 'Issuer PAN', value: value),
        if (invoice.issuerCin case final value?)
          _InvoiceFact(label: 'Issuer CIN', value: value),
        if (invoice.issuerFssaiNumber case final value?)
          _InvoiceFact(
            label: 'Issuer FSSAI licence / registration',
            value: value,
          ),
        if (invoice.restaurantLegalName case final value?)
          _InvoiceFact(label: 'Restaurant legal name', value: value),
        if (invoice.restaurantAddress case final value?)
          _InvoiceFact(label: 'Restaurant address', value: value),
        if (invoice.restaurantGstin case final value?)
          _InvoiceFact(label: 'Restaurant GSTIN', value: value),
        if (invoice.restaurantFssaiNumber case final value?)
          _InvoiceFact(
            label: 'Restaurant FSSAI licence / registration',
            value: value,
          ),
        if (invoice.recipientName case final value?)
          _InvoiceFact(label: 'Customer', value: value),
        if (invoice.recipientAddress case final value?)
          _InvoiceFact(label: 'Customer address', value: value),
        _InvoiceFact(label: 'Place of supply', value: invoice.placeOfSupply),
        _InvoiceFact(
          label: 'Reverse charge',
          value: invoice.reverseCharge ? 'Yes' : 'No',
        ),
        if (invoice.section9FiveSupply)
          const _InvoiceFact(
            label: 'Tax treatment',
            value:
                'Restaurant service supplied through an e-commerce operator under section 9(5)',
          ),
        for (final line in invoice.lines) ...[
          const Divider(height: 16),
          _InvoiceFact(label: 'Service', value: line.description),
          _InvoiceFact(label: 'SAC', value: line.sac),
          _InvoiceFact(
            label: 'Taxable value',
            value: eatMoney(line.taxableValue),
          ),
          _InvoiceFact(
            label: 'GST rate',
            value: '${line.gstRate.toStringAsFixed(2)}%',
          ),
          if (line.cgst > 0)
            _InvoiceFact(label: 'CGST', value: eatMoney(line.cgst)),
          if (line.sgst > 0)
            _InvoiceFact(label: 'SGST', value: eatMoney(line.sgst)),
          if (line.igst > 0)
            _InvoiceFact(label: 'IGST', value: eatMoney(line.igst)),
        ],
        if (invoice.authorizedSignatory case final value?) ...[
          const Divider(height: 16),
          _InvoiceFact(label: 'Authorized signatory', value: value),
        ],
      ],
    ),
  );
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => EatSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: MoolColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _InvoiceFact extends StatelessWidget {
  const _InvoiceFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: MoolColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InvoiceAmount extends StatelessWidget {
  const _InvoiceAmount({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) => _InvoiceFact(
    label: label,
    value: value == 0 && label == 'Delivery' ? 'Free' : eatMoney(value),
  );
}
