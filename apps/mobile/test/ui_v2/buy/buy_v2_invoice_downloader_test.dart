import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

BuyV2Order _placedOrder() => BuyV2Order(
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
  addressLine: 'Jodhpur, Rajasthan',
  deliveryInstruction: 'Call on arrival',
  tip: 5,
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
