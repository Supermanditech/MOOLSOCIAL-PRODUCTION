import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_store_address.dart';

BuyV2StoreListing store(String address) => BuyV2StoreListing(
  id: 'branch-1',
  name: 'Store & Sons',
  area: 'Area',
  address: address,
  regionId: 'region-1',
);

void main() {
  test('Maps keeps exact Store address and encodes reserved characters', () {
    final uri = buyV2StoreMapUri(store('12/A, Road #2 & Market'))!;
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters, {
      'api': '1',
      'query': 'Store & Sons, 12/A, Road #2 & Market',
    });
    expect(uri.fragment, isEmpty);
    expect(buyV2StoreMapUri(store('  ')), isNull);
  });

  testWidgets(
    'long address at 320px and large text remains visible; failed Maps can retry',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final address =
          '12/A, First Floor, Long Market Road, Jaipur, Rajasthan 302001';
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: BuyV2StoreAddress(
                store: store(address),
                openMap: (uri) async {
                  calls++;
                  expect(
                    uri.queryParameters['query'],
                    'Store & Sons, $address',
                  );
                  return false;
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text(address), findsOneWidget);
      final pin = find.byTooltip('Open store in Google Maps');
      expect(tester.getSize(pin).width, greaterThanOrEqualTo(48));
      await tester.tap(pin);
      await tester.pumpAndSettle();
      expect(
        find.text('Could not open Google Maps. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(pin);
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing address never opens a map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BuyV2StoreAddress(store: store(''))),
      ),
    );
    expect(find.text('Store address unavailable'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });
}
