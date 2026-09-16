import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/eat/eat_models.dart';
import 'package:moolsocial/features/eat/eat_services.dart';
import 'package:moolsocial/features/eat/eat_session.dart';
import 'package:moolsocial/features/eat/screens/eat_invoice_screen.dart';

void main() {
  testWidgets('food invoice separates order, restaurant and platform tax', (
    tester,
  ) async {
    final session = EatSession(
      gateway: ReviewEatOrderGateway(latency: Duration.zero),
    );
    addTearDown(session.dispose);
    final restaurant = session.selectedRestaurant;
    final item = session.visibleMenu('').first;
    session.orderReceipt = EatOrderReceipt(
      id: 'MS-EAT-1',
      createdAt: DateTime(2026, 8, 30),
      restaurant: restaurant,
      lines: [EatCartLine(item: item, quantity: 1)],
      subtotal: 666,
      deliveryFee: 23,
      taxes: 35,
      total: 724,
      fulfilment: EatFulfilment.delivery,
      deliveryAddress: 'Jodhpur, Rajasthan 342003',
      promise: 'Delivered',
      paymentMethod: EatPaymentMethod.upi,
      taxInvoiceDetails: _invoice(
        number: 'SMT/FOOD/1',
        issuer: 'SuperMandi Tech Private Limited',
        restaurantFssai: '12214032000146',
        section9Five: true,
      ),
      platformTaxInvoiceDetails: _invoice(
        number: 'SMT/SVC/1',
        issuer: 'SuperMandi Tech Private Limited',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: EatInvoiceScreen(session: session, orderId: 'MS-EAT-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CUSTOMER ORDER SUMMARY'), findsOneWidget);
    final restaurantTax = find.byKey(const Key('eat-restaurant-tax-invoice'));
    await tester.scrollUntilVisible(
      restaurantTax,
      400,
      scrollable: find.descendant(
        of: find.byKey(const Key('eat-invoice-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Restaurant service tax invoice'), findsOneWidget);
    expect(find.text('12214032000146'), findsOneWidget);
    expect(find.textContaining('section 9(5)'), findsOneWidget);
    final platform = find.byKey(const Key('eat-platform-tax-invoice'));
    await tester.scrollUntilVisible(
      platform,
      400,
      scrollable: find.descendant(
        of: find.byKey(const Key('eat-invoice-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MoolSocial service tax invoice'), findsOneWidget);
    expect(find.text('SMT/SVC/1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

EatTaxInvoiceDetails _invoice({
  required String number,
  required String issuer,
  String? restaurantFssai,
  bool section9Five = false,
}) => EatTaxInvoiceDetails(
  invoiceNumber: number,
  issuedAt: DateTime(2026, 8, 30),
  issuerLegalName: issuer,
  issuerAddress: 'Jodhpur, Rajasthan 342003',
  issuerGstin: '08ABCDE1234F1Z5',
  issuerFssaiNumber: '10019064001810',
  restaurantLegalName: 'Sample Restaurant',
  restaurantAddress: 'Jodhpur, Rajasthan 342003',
  restaurantFssaiNumber: restaurantFssai,
  recipientName: 'Customer',
  recipientAddress: 'Jodhpur, Rajasthan 342003',
  placeOfSupply: 'Rajasthan (08)',
  section9FiveSupply: section9Five,
  authorizedSignatory: 'Authorized representative',
  lines: const [
    EatTaxInvoiceLine(
      description: 'Restaurant service',
      sac: '996331',
      taxableValue: 666,
      gstRate: 5,
      cgst: 17,
      sgst: 17,
      igst: 0,
    ),
  ],
);
