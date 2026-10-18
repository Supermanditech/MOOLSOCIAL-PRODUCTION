import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LF12 export keeps normalized address suffix beyond240', () async {
    final source = 'Host address ${List.filled(300, 'a').join()} ORIGINAL-END';
    final result = await _saveAddress(source);
    expect(result.outcome, BuyV2InvoiceDownloadOutcome.saved);
    expect(_addressParts(result.lines).join(), 'Address: $source');
    expect(result.lines.any((line) => line.endsWith('ORIGINAL-END')), isTrue);
  });
  for (final units in [500, 501, 1501]) {
    test('LF12 export splits assembled address losslessly units=$units', () async {
      final source = List.filled(units - 'Address: '.length, 'a').join();
      final result = await _saveAddress(source);
      expect(result.outcome, BuyV2InvoiceDownloadOutcome.saved);
      final parts = _addressParts(result.lines);
      expect(parts.join(), 'Address: $source');
      expect(parts.length, (units / 500).ceil());
      expect(result.lines.every((line) => line.length <= 500), isTrue);
      expect(result.lines, contains(''));
    });
  }
  test('LF12 export does not split surrogate pairs or change normalization', () async {
    final source = '${List.filled(499 - 'Address: '.length, 'x').join()}😀 suffix';
    final result = await _saveAddress(source);
    final parts = _addressParts(result.lines);
    expect(result.outcome, BuyV2InvoiceDownloadOutcome.saved);
    expect(parts.join(), 'Address: $source');
    expect(parts.first.length, 499);
    expect(parts.last.startsWith('😀'), isTrue);
    final normalized = await _saveAddress('  Host\taddress\r\nwith\u0000controls\u007F end  ');
    expect(_addressParts(normalized.lines).join(), 'Address: Host address with controls end');
    expect(normalized.lines, contains(''));
  });
  for (final total in [200, 201]) {
    test('LF12 export enforces complete document line limit total=$total', () async {
      final baseline = await _saveAddress('Host address');
      final chunks = total - baseline.lines.length + 1;
      final source = List.filled(chunks * 500 - 'Address: '.length, 'a').join();
      final result = await _saveAddress(source);
      if (total == 200) {
        expect(result.outcome, BuyV2InvoiceDownloadOutcome.saved);
        expect(result.calls, 1); expect(result.lines.length, 200);
        expect(_addressParts(result.lines).join(), 'Address: $source');
      } else {
        expect(result.outcome, BuyV2InvoiceDownloadOutcome.failed);
        expect(result.calls, 0, reason: 'Never send a successful partial invoice to the native channel');
      }
    });
  }
  test('LF12 export keeps combining graphemes together at a native line boundary', () async {
    final source = '${List.filled(499 - 'Address: '.length, 'x').join()}कि suffix';
    final result = await _saveAddress(source);
    final parts = _addressParts(result.lines);
    expect(result.outcome, BuyV2InvoiceDownloadOutcome.saved);
    expect(parts.join(), 'Address: $source');
    expect(parts.first.length, 499);
    expect(parts.last.startsWith('कि'), isTrue);
  });
  test('LF12 export rejects an indivisible grapheme above the native line limit', () async {
    final source = 'a${List.filled(501, '\u0301').join()}';
    final result = await _saveAddress(source);
    expect(result.outcome, BuyV2InvoiceDownloadOutcome.failed);
    expect(result.calls, 0);
  });
  test('LF12 export retains seller and platform supplied tax text after chunking', () async {
    BuyV2TaxInvoiceDetails facts(String issuer) => BuyV2TaxInvoiceDetails(
      invoiceNumber: 'HOST-$issuer', issuedAt: DateTime.utc(2026, 10, 18),
      sellerLegalName: 'Host $issuer', sellerAddress: '$issuer ${List.filled(300, 'a').join()} ADDRESS-END',
      sellerGstin: 'HOST-NOT-A-REAL-GSTIN', placeOfSupply: 'Host source place', sourceId: 'host-$issuer',
      recipientLegalName: 'Host recipient', recipientBillingAddress: 'Host original recipient address',
      revisionLabel: 'Host correction ${List.filled(300, 'c').join()} CORRECTION-END',
      lines: [BuyV2TaxInvoiceLine(description: '$issuer ${List.filled(1000, 'd').join()} DESCRIPTION-END',
        hsnSac: 'HOST-HSN', quantity: 2, unit: 'packs', unitPrice: _product().price,
        taxableValue: _product().price * 2, gstRate: 0, cgst: 0, sgst: 0, igst: 0, cess: 0)]);
    final seller = facts('seller'), platform = facts('platform');
    final result = await _saveDocument(_placedOrder(tax: seller, platformTax: platform));
    expect(result.outcome, BuyV2InvoiceDownloadOutcome.saved);
    expect(result.lines.every((line) => line.length <= 500), isTrue);
    final text = result.lines.join();
    for (final invoice in [seller, platform]) {
      expect(text, contains(invoice.sellerAddress));
      expect(text, contains('${invoice.lines.single.description} | HSN/SAC HOST-HSN'));
      expect(text, contains('Invoice number: ${invoice.invoiceNumber}'));
    }
    expect(text, contains(seller.revisionLabel!));
    expect(result.lines, contains('MoolSocial service tax invoice'));
    expect(result.lines, contains('Tax breakdown'));
    expect(result.lines, contains('Order total: INR ${_product().price * 2 + 5}'));
  });

  test(
    'Android save sends exact placed-order lines and reports saved',
    () async {
      const channel = MethodChannel('test.moolsocial/invoice-saved');
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            captured = call;
            return 'saved';
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final document = BuyV2InvoiceDocument(order: _placedOrder());

      final outcome = await saveBuyV2InvoiceWithChannel(
        document,
        channel: channel,
        platform: TargetPlatform.android,
      );

      expect(outcome, BuyV2InvoiceDownloadOutcome.saved);
      expect(captured?.method, 'saveInvoice');
      final payload = (captured?.arguments as Map).cast<String, Object>();
      expect(payload.keys.toSet(), <String>{'fileName', 'lines'});
      expect(payload['fileName'], 'MoolSocial-invoice-ORD-TEST-1001.pdf');
      final lines = (payload['lines'] as List).cast<String>();
      expect(lines, contains('Order ID: ORD-TEST-1001'));
      expect(lines.where((line) => line.startsWith('Expected:')), isEmpty);
      final recordedEstimate = lines.singleWhere(
        (line) => line.startsWith('Recorded delivery estimate:'),
      );
      expect(recordedEstimate, contains('Original estimate'));
      expect(recordedEstimate, contains('recorded time unavailable'));
      expect(recordedEstimate, contains('not a live countdown'));

      final subtotal = _product().price * 2;
      expect(
        lines,
        contains(
          '2 x ${_product().title} (${_product().pack}) - INR $subtotal',
        ),
      );
      expect(lines, contains('Items subtotal: INR $subtotal'));
      expect(lines, contains('Delivery tip: INR 5'));
      expect(lines, contains('Order total: INR ${subtotal + 5}'));
      expect(lines.join('\n'), isNot(contains('access_token')));
    },
  );

  test('document-picker cancellation never claims a saved invoice', () async {
    const channel = MethodChannel('test.moolsocial/invoice-cancelled');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'cancelled');
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final outcome = await saveBuyV2InvoiceWithChannel(
      BuyV2InvoiceDocument(order: _placedOrder()),
      channel: channel,
      platform: TargetPlatform.android,
    );

    expect(outcome, BuyV2InvoiceDownloadOutcome.cancelled);
  });

  test('missing exact order lines and non-Android stay unavailable', () async {
    const channel = MethodChannel('test.moolsocial/invoice-unavailable');
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          calls += 1;
          return 'saved';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    expect(
      await saveBuyV2InvoiceWithChannel(
        BuyV2InvoiceDocument(
          order: _placedOrder().copyWithForTest(lines: const []),
        ),
        channel: channel,
        platform: TargetPlatform.android,
      ),
      BuyV2InvoiceDownloadOutcome.unavailable,
    );
    expect(
      await saveBuyV2InvoiceWithChannel(
        BuyV2InvoiceDocument(order: _placedOrder()),
        channel: channel,
        platform: TargetPlatform.iOS,
      ),
      BuyV2InvoiceDownloadOutcome.unavailable,
    );
    expect(calls, 0);
  });

  test('platform write failure is truthful', () async {
    const channel = MethodChannel('test.moolsocial/invoice-failed');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'write_failed'),
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final outcome = await saveBuyV2InvoiceWithChannel(
      BuyV2InvoiceDocument(order: _placedOrder()),
      channel: channel,
      platform: TargetPlatform.android,
    );

    expect(outcome, BuyV2InvoiceDownloadOutcome.failed);
  });
}

BuyV2Product _product() => BuyV2Catalogue.products.firstWhere(
  (product) => product.destination == BuyV2Destination.shop,
);

// Isolated channel/payload fixtures only; no runtime order or issued invoice.
Future<({BuyV2InvoiceDownloadOutcome outcome, List<String> lines, int calls})> _saveAddress(String address) async {
  return _saveDocument(_placedOrder(address: address));
}
Future<({BuyV2InvoiceDownloadOutcome outcome, List<String> lines, int calls})> _saveDocument(BuyV2Order order) async {
  const channel = MethodChannel('test.moolsocial/lf12-complete-document');
  var calls = 0;
  var lines = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
    calls++;
    lines = List<String>.from((call.arguments as Map)['lines'] as List);
    return 'saved';
  });
  addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
  final outcome = await saveBuyV2InvoiceWithChannel(BuyV2InvoiceDocument(order: order),
    channel: channel, platform: TargetPlatform.android);
  return (outcome: outcome, lines: lines, calls: calls);
}
List<String> _addressParts(List<String> lines) => lines.sublist(
  lines.indexWhere((line) => line.startsWith('Address: ')),
  lines.indexWhere((line) => line.startsWith('Recorded delivery estimate:')));

BuyV2Order _placedOrder({String address = 'Jodhpur, Rajasthan', BuyV2TaxInvoiceDetails? tax, BuyV2TaxInvoiceDetails? platformTax}) => BuyV2Order(
  id: 'ORD-TEST-1001',
  destination: BuyV2Destination.shop,
  title: 'Test order',
  itemSummary: '2 items',
  total: (_product().price * 2) + 5,
  partner: 'Mool Retail Partner',
  partnerType: 'Retail partner',
  promise: 'Today',
  destinationLabel: 'Jodhpur, Rajasthan',
  progress: .2,
  status: BuyV2OrderStatus.confirmed,
  lines: <BuyV2CartLine>[BuyV2CartLine(product: _product(), quantity: 2)],
  paymentMethod: 'Cash on delivery',
  recipient: 'Customer',
  addressLine: address,
  deliveryInstruction: 'Call on arrival',
  tip: 5,
  taxInvoiceState: tax == null ? null : BuyV2TaxInvoiceState.corrected,
  taxInvoiceDetails: tax,
  platformTaxInvoiceDetails: platformTax,
);

extension on BuyV2Order {
  BuyV2Order copyWithForTest({required List<BuyV2CartLine> lines}) =>
      BuyV2Order(
        id: id,
        destination: destination,
        title: title,
        itemSummary: itemSummary,
        total: total,
        partner: partner,
        partnerType: partnerType,
        promise: promise,
        destinationLabel: destinationLabel,
        progress: progress,
        status: status,
        productIds: productIds,
        lines: lines,
        paymentMethod: paymentMethod,
        recipient: recipient,
        addressLine: addressLine,
        deliveryInstruction: deliveryInstruction,
        tip: tip,
      );
}
