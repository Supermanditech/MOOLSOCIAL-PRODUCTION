import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/shared/commerce/commerce_invoice_pdf.dart';
import 'package:moolsocial/features/work/work_invoice_pdf.dart';
import 'package:moolsocial/features/work/work_models.dart';

CommerceInvoiceDocumentDetails sample(
  CommerceInvoiceFormat format, {
  int count = 2,
  String storeId = 'store-a',
  String accountId = 'review-owner',
  int? received,
  int? total,
  bool wholesale = false,
  bool commission = false,
  bool interstate = false,
}) {
  final fee = format == CommerceInvoiceFormat.platformFee;
  final lines = List.generate(
    fee ? 1 : count,
    (i) => CommerceInvoiceDocumentLine(
      description: fee
          ? (commission ? 'Marketplace commission' : 'Platform service fee')
          : i.isEven
          ? 'Basmati rice - premium grain'
          : 'Whole wheat flour',
      quantity: fee ? 1 : 2,
      pack: fee ? '' : '1 kg sealed pack',
      classification: fee ? 'TEST-SERVICE' : 'TEST-GOODS',
      unitPriceMinor: fee ? 1000 : 12500,
      discountMinor: fee ? 0 : 1000,
      taxes: interstate
          ? [CommerceInvoiceTax('IGST', fee ? 1800 : 500, fee ? 180 : 1200)]
          : [
              CommerceInvoiceTax('CGST', fee ? 900 : 250, fee ? 90 : 600),
              CommerceInvoiceTax('SGST', fee ? 900 : 250, fee ? 90 : 600),
            ],
    ),
  );
  final adjustments = format == CommerceInvoiceFormat.summary
      ? const [
          CommerceInvoiceAdjustment(
            CommerceInvoiceAdjustmentKind.delivery,
            2000,
          ),
          CommerceInvoiceAdjustment(
            CommerceInvoiceAdjustmentKind.platform,
            1180,
          ),
          CommerceInvoiceAdjustment(
            CommerceInvoiceAdjustmentKind.deliveryDiscount,
            -2000,
          ),
          CommerceInvoiceAdjustment(CommerceInvoiceAdjustmentKind.coupon, -500),
          CommerceInvoiceAdjustment(CommerceInvoiceAdjustmentKind.rounding, 20),
        ]
      : const <CommerceInvoiceAdjustment>[];
  final computed =
      lines.fold<int>(0, (s, l) => s + l.totalMinor) +
      adjustments.fold<int>(0, (s, a) => s + a.amountMinor);
  return CommerceInvoiceDocumentDetails(
    accountId: accountId,
    storeId: storeId,
    invoiceId: 'INV-REVIEW-0042',
    orderId: 'ORDER-REVIEW-0042',
    documentId: fee ? 'FEE-REVIEW-0042' : 'INV-REVIEW-0042',
    sourceId: 'fictional-fixture-v1',
    format: format,
    issuedAt: DateTime(2026, 9, 22, 10, 30),
    issuerRole: fee
        ? CommerceInvoicePartyRole.platform
        : wholesale
        ? CommerceInvoicePartyRole.supplier
        : CommerceInvoicePartyRole.retailer,
    recipientRole: commission || wholesale
        ? CommerceInvoicePartyRole.retailer
        : CommerceInvoicePartyRole.customer,
    sellerName: wholesale ? 'Demo Wholesale Supplies' : 'Demo Grocery Store',
    issuer: CommerceInvoiceIssuer(
      legalName: fee
          ? 'MoolSocial Platform - fictional review entity'
          : 'Demo Grocery and Wholesale Supplies Private Limited',
      address: 'Unit 12, Market Complex, Civil Lines, Jaipur, Rajasthan 302006',
      state: 'Rajasthan',
      gstin: 'TEST-GSTIN-NOT-VALID',
      pan: fee ? 'TEST-PAN' : '',
      cin: fee ? 'TEST-CIN' : '',
      email: 'accounts@example.invalid',
      signatory: 'Test signatory - no signature applied',
    ),
    recipient: {
      'Name': commission || wholesale ? 'Demo Retailer' : 'Test Customer',
      'Billing address':
          '45 Lake Road, Example Nagar, Jaipur, Rajasthan 302001',
    },
    lines: lines,
    totalMinor: total ?? computed,
    taxBreakdownProvided: true,
    placeOfSupply: interstate
        ? 'Test interstate destination'
        : 'Rajasthan - test data',
    receivedMinor:
        received ?? (format == CommerceInvoiceFormat.summary ? computed : 0),
    adjustments: adjustments,
    reverseCharge: false,
    supplyStatement:
        'Fictional review data. Tax applicability and issuance require verified backend records.',
    terms:
        'Review only. Use confirmed order terms for returns, support and delivery. This document does not issue an invoice or confirm receipt of funds.',
    deliveryPartner: format == CommerceInvoiceFormat.summary
        ? 'Test delivery partner'
        : '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('large amount and long supplied identity remain renderable', () async {
    for (final longIdentity in [false, true]) {
      final d = CommerceInvoiceDocumentDetails(
        accountId: 'review-owner',
        storeId: 'store-a',
        invoiceId: 'INV-LARGE',
        orderId: 'ORDER-LARGE',
        documentId: 'INV-LARGE',
        sourceId: 'fictional-large-v1',
        format: CommerceInvoiceFormat.seller,
        issuedAt: DateTime(2026, 9, 22),
        issuer: CommerceInvoiceIssuer(
          legalName: longIdentity
              ? List.filled(90, 'Long Company Name ').join()
              : 'Demo Large Order Store',
          address: longIdentity
              ? List.filled(90, 'Long Street Address ').join()
              : 'Test address',
        ),
        recipient: const {'Name': 'Demo Retailer'},
        recipientRole: CommerceInvoicePartyRole.retailer,
        lines: [
          CommerceInvoiceDocumentLine(
            description: 'Test bulk order',
            quantity: 1,
            unitPriceMinor: 1000000000,
            discountMinor: 50000000,
          ),
        ],
        totalMinor: 950000000,
        receivedMinor: 0,
      );
      expect(d.valid, isTrue);
      final bytes = await renderCommerceInvoicePdf(d);
      expect(bytes.length, greaterThan(1000));
      const output = String.fromEnvironment('COMMERCE_PDF_OUTPUT');
      if (output.isNotEmpty) {
        final dir = Directory(output)..createSync(recursive: true);
        File(
          '${dir.path}/${longIdentity ? 'long-identity' : 'large-amount'}.pdf',
        ).writeAsBytesSync(bytes);
      }
    }
  });
  test('reference formats preserve roles, exact totals and immutable data', () {
    for (final format in CommerceInvoiceFormat.values) {
      final d = sample(format);
      expect(d.valid, isTrue);
      expect(() => d.lines.clear(), throwsUnsupportedError);
      expect(() => d.recipient['Name'] = 'Changed', throwsUnsupportedError);
      expect(() => d.adjustments.clear(), throwsUnsupportedError);
      expect(sample(format, total: d.totalMinor + 1).valid, isFalse);
      expect(sample(format, received: d.totalMinor + 1).valid, isFalse);
      expect(sample(format, interstate: true).valid, isTrue);
    }
    expect(
      sample(CommerceInvoiceFormat.seller, wholesale: true).issuerRole,
      CommerceInvoicePartyRole.supplier,
    );
    expect(
      sample(
        CommerceInvoiceFormat.platformFee,
        commission: true,
      ).recipient['Name'],
      'Demo Retailer',
    );
  });
  test('fixed-point amounts, Indian words and no floating-point tails', () {
    expect(commerceInvoiceFileComponent('../fee\\2026:42'), 'fee-2026-42');
    expect(
      commerceInvoiceFileComponent('FEE-001'),
      isNot(commerceInvoiceFileComponent('FEE-002')),
    );
    expect(commerceInvoiceMoney(1062), '₹10.62');
    expect(commerceInvoiceMoney(-50), '-₹0.50');
    expect(commerceInvoiceAmountInWords(0), 'Zero Rupees Only');
    expect(
      commerceInvoiceAmountInWords(1062),
      'Ten Rupees and Sixty Two Paise Only',
    );
    expect(commerceInvoiceAmountInWords(1000000000), 'One Crore Rupees Only');
    expect(
      commerceInvoiceAmountInWords(950000000),
      'Ninety Five Lakh Rupees Only',
    );
    expect(() => commerceInvoiceAmountInWords(-1), throwsFormatException);
    expect(
      () => commerceInvoiceAmountInWords(commerceInvoiceMoneyLimit + 1),
      throwsFormatException,
    );
  });
  test(
    'invalid lines, taxes and adjustment direction cannot render as valid',
    () {
      for (final line in [
        CommerceInvoiceDocumentLine(
          description: 'x',
          quantity: 0,
          unitPriceMinor: 100,
        ),
        CommerceInvoiceDocumentLine(
          description: 'x',
          quantity: 1,
          unitPriceMinor: 100,
          discountMinor: 101,
        ),
        CommerceInvoiceDocumentLine(
          description: 'x',
          quantity: 1,
          unitPriceMinor: 10000,
          taxes: [
            const CommerceInvoiceTax('CGST', 900, 900),
            const CommerceInvoiceTax('IGST', 1800, 1800),
          ],
        ),
        CommerceInvoiceDocumentLine(
          description: 'x',
          quantity: 1,
          unitPriceMinor: 10000,
          taxes: [const CommerceInvoiceTax('CGST', 900, 999)],
        ),
        CommerceInvoiceDocumentLine(
          description: 'x',
          quantity: 1,
          unitPriceMinor: 10000,
          taxes: [
            const CommerceInvoiceTax('CGST', 900, 900),
            const CommerceInvoiceTax('CGST', 900, 900),
          ],
        ),
      ]) {
        expect(line.valid, isFalse);
      }
      expect(
        const CommerceInvoiceAdjustment(
          CommerceInvoiceAdjustmentKind.coupon,
          50,
        ).valid,
        isFalse,
      );
      expect(
        const CommerceInvoiceAdjustment(
          CommerceInvoiceAdjustmentKind.rounding,
          101,
        ).valid,
        isFalse,
      );
    },
  );
  test(
    'Store adapter rejects cross-owner and wrong total enriched documents',
    () async {
      final invoice = WorkspaceCustomerInvoice(
        id: 'INV-REVIEW-0042',
        orderId: 'ORDER-REVIEW-0042',
        customer: 'Test Customer',
        items: '2 products',
        amount: 504,
        payment: 'Cash',
        issuedAt: DateTime(2026, 9, 22),
      );
      WorkInvoicePdfRequest req(CommerceInvoiceDocumentDetails d) =>
          WorkInvoicePdfRequest(
            accountId: 'review-owner',
            storeId: 'store-a',
            invoice: invoice,
            items: [],
            paymentStatus: 'Unpaid',
            details: d,
          );
      for (final d in [
        sample(CommerceInvoiceFormat.seller, storeId: 'other'),
        sample(CommerceInvoiceFormat.seller, accountId: 'other'),
        sample(CommerceInvoiceFormat.seller, count: 3),
      ]) {
        await expectLater(
          const LocalReviewWorkInvoicePdfSource().load(req(d)),
          throwsA(isA<WorkInvoicePdfException>()),
        );
      }
      final result = await const LocalReviewWorkInvoicePdfSource().load(
        req(sample(CommerceInvoiceFormat.seller)),
      );
      expect(result.reviewOnly, isTrue);
      expect(result.identity, endsWith('/seller/INV-REVIEW-0042'));
      expect(result.fileName, endsWith('-seller.pdf'));
    },
  );
  test(
    'actual reference layouts and multipage wholesale render from shared code',
    () async {
      final cases = {
        'seller-invoice': sample(CommerceInvoiceFormat.seller),
        'platform-fee-invoice': sample(CommerceInvoiceFormat.platformFee),
        'order-summary': sample(CommerceInvoiceFormat.summary),
        'wholesale-multipage': sample(
          CommerceInvoiceFormat.seller,
          count: 50,
          wholesale: true,
          interstate: true,
        ),
        'platform-retailer-commission': sample(
          CommerceInvoiceFormat.platformFee,
          commission: true,
        ),
      };
      for (final entry in cases.entries) {
        final bytes = await renderCommerceInvoicePdf(entry.value);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(1000));
        const output = String.fromEnvironment('COMMERCE_PDF_OUTPUT');
        if (output.isNotEmpty) {
          final dir = Directory(output)..createSync(recursive: true);
          File('${dir.path}/${entry.key}.pdf').writeAsBytesSync(bytes);
        }
      }
    },
  );
}
