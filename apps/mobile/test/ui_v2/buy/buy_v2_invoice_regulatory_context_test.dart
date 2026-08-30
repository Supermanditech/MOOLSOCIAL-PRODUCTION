import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';

void main() {
  BuyV2TaxInvoiceDetails invoice({
    required String seller,
    required String invoiceNumber,
    String? buyerGstin,
    String? fssai,
    String? recipient,
    String? recipientAddress,
    String? irn,
  }) => BuyV2TaxInvoiceDetails(
    invoiceNumber: invoiceNumber,
    issuedAt: DateTime(2026, 8, 30),
    sellerLegalName: seller,
    sellerAddress: 'Jodhpur, Rajasthan 342003',
    sellerGstin: '08ABCDE1234F1Z5',
    buyerGstin: buyerGstin,
    placeOfSupply: 'Rajasthan (08)',
    sourceId: invoiceNumber,
    recipientLegalName: recipient,
    recipientBillingAddress: recipientAddress,
    sellerFssaiNumber: fssai,
    reverseCharge: false,
    irn: irn,
    authorizedSignatory: 'Authorized representative',
    lines: const [
      BuyV2TaxInvoiceLine(
        description: 'Food products',
        hsnSac: '19059090',
        quantity: 2,
        unit: 'packs',
        unitPrice: 500,
        taxableValue: 1000,
        gstRate: 5,
        cgst: 25,
        sgst: 25,
        igst: 0,
        cess: 0,
      ),
    ],
  );

  BuyV2Order order({
    required BuyV2Destination destination,
    required BuyV2TaxInvoiceDetails sellerInvoice,
    BuyV2TaxInvoiceDetails? platformInvoice,
  }) => BuyV2Order(
    id: destination == BuyV2Destination.wholesale ? 'PO-1' : 'MS-1',
    destination: destination,
    title: '${destination.label} order',
    itemSummary: '2 products',
    total: 1050,
    partner: 'Direct supplier',
    partnerType: 'Verified seller',
    promise: 'Delivered',
    destinationLabel: 'Jodhpur',
    progress: 1,
    status: BuyV2OrderStatus.delivered,
    taxInvoiceState: BuyV2TaxInvoiceState.ready,
    taxInvoiceDetails: sellerInvoice,
    platformTaxInvoiceDetails: platformInvoice,
  );

  Widget app(BuyV2Order order) => MaterialApp(
    theme: MoolTheme.light(),
    home: BuyV2InvoicePage(order: order),
  );

  testWidgets('retail invoice exposes seller and food compliance context', (
    tester,
  ) async {
    final retail = order(
      destination: BuyV2Destination.shop,
      sellerInvoice: invoice(
        seller: 'SuperMandi Tech Private Limited',
        invoiceNumber: 'SMT/2026/001',
        recipient: 'Retail customer',
        recipientAddress: 'Jodhpur, Rajasthan 342003',
        fssai: '12214032000146',
      ),
    );
    await tester.pumpWidget(app(retail));
    await tester.pumpAndSettle();

    expect(find.text('Original for recipient'), findsOneWidget);
    expect(find.text('Consumer retail purchase'), findsOneWidget);
    expect(find.text('SuperMandi Tech Private Limited'), findsOneWidget);
    expect(find.text('FSSAI licence / registration'), findsOneWidget);
    expect(find.text('12214032000146'), findsOneWidget);
    expect(find.text('2 packs'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wholesale invoice keeps buyer GST and platform fee separate', (
    tester,
  ) async {
    final wholesale = order(
      destination: BuyV2Destination.wholesale,
      sellerInvoice: invoice(
        seller: 'Marwar Foods Distribution',
        invoiceNumber: 'MFD/2026/042',
        buyerGstin: '08AAAAA0000A1Z5',
        recipient: 'Jodhpur Retail LLP',
        recipientAddress: 'Basni, Jodhpur, Rajasthan 342005',
        irn: 'IRN-EXAMPLE-001',
      ),
      platformInvoice: invoice(
        seller: 'SuperMandi Tech Private Limited',
        invoiceNumber: 'SMT/SVC/2026/011',
        buyerGstin: '08AAAAA0000A1Z5',
        recipient: 'Jodhpur Retail LLP',
      ),
    );
    await tester.pumpWidget(app(wholesale));
    await tester.pumpAndSettle();

    expect(find.text('Wholesale / business purchase'), findsOneWidget);
    expect(find.text('Buyer GSTIN'), findsWidgets);
    expect(find.text('08AAAAA0000A1Z5'), findsWidgets);
    expect(find.text('IRN-EXAMPLE-001'), findsOneWidget);
    final platformSection = find.byKey(
      const ValueKey('buy-platform-tax-invoice-PO-1'),
    );
    await tester.scrollUntilVisible(
      platformSection,
      400,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-invoice-scroll-PO-1')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MoolSocial service tax invoice'), findsOneWidget);
    expect(find.text('SMT/SVC/2026/011'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
