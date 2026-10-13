import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/screens/store_add_product_sheet.dart';
import 'package:moolsocial/features/work/work_models.dart';

void main() {
  final master = workspaceMasterCatalogue.first;
  Future<void> open(
    WidgetTester tester, {
    List<WorkspaceCatalogueItem> owned = const [],
    required ValueChanged<WorkspaceCatalogueItem?> result,
    Future<String?> Function()? scan,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result(
                  await Navigator.push<WorkspaceCatalogueItem>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreAddProductSheet(
                        catalogue: [master],
                        ownedProducts: owned,
                        createProduct: (code) => master.copyWith(
                          barcode: code,
                          publicListing: false,
                        ),
                        scanBarcode: scan ?? () async => null,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Selecting a new identity never copies catalogue stock or price into the store',
    (tester) async {
      WorkspaceCatalogueItem? selected;
      await open(tester, result: (value) => selected = value);
      await tester.tap(find.byKey(Key('work-add-product-${master.id}')));
      await tester.pumpAndSettle();
      expect(selected!.canonicalId, master.canonicalId);
      expect(selected!.stock, 0);
      expect(selected!.purchasePrice, 0);
      expect(selected!.sellingPrice, 0);
      expect(selected!.publicListing, isFalse);
      expect(selected!.available, isFalse);
    },
  );

  testWidgets(
    'Existing identity opens the actual owner offer without replacement',
    (tester) async {
      final owned = master.copyWith(sku: 'MY-SKU', sellingPrice: 937, stock: 4);
      WorkspaceCatalogueItem? selected;
      await open(tester, owned: [owned], result: (value) => selected = value);
      expect(find.textContaining('Already in your store'), findsOneWidget);
      await tester.tap(find.byKey(Key('work-add-product-${master.id}')));
      await tester.pumpAndSettle();
      expect(identical(selected, owned), isTrue);
    },
  );

  testWidgets(
    'Unmatched scan carries its barcode only into explicit manual creation',
    (tester) async {
      WorkspaceCatalogueItem? selected;
      await open(
        tester,
        result: (value) => selected = value,
        scan: () async => '99887766',
      );
      await tester.tap(find.byKey(const Key('work-add-products-scan')));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.textContaining('No matching product'), findsOneWidget);
      await tester.tap(find.byKey(const Key('work-add-product-manual')));
      await tester.pumpAndSettle();
      expect(selected!.barcode, '99887766');
    },
  );

  testWidgets('Scanner failure leaves search and manual entry usable', (
    tester,
  ) async {
    await open(
      tester,
      result: (_) {},
      scan: () async => throw StateError('camera unavailable'),
    );
    await tester.tap(find.byKey(const Key('work-add-products-scan')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not scan'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('work-add-products-search')),
      'no such product',
    );
    await tester.pump();
    expect(
      find.byKey(const Key('work-add-product-manual')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Another pack of the same canonical product remains selectable', (
    tester,
  ) async {
    final owned = workspaceMasterCatalogue[1].copyWith(
      canonicalId: master.canonicalId,
      pack: 'Different pack',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StoreAddProductSheet(
          catalogue: [master],
          ownedProducts: [owned],
          createProduct: (_) => master,
          scanBarcode: () async => null,
        ),
      ),
    );
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.textContaining('Already in your store'), findsOneWidget);
  });

  testWidgets(
    'Landscape keyboard keeps product creation reachable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(720, 360);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 170);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          home: StoreAddProductSheet(
            catalogue: [master],
            ownedProducts: const [],
            createProduct: (_) => master,
            scanBarcode: () async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const Key('work-add-product-manual')),
      );
      expect(
        find.byKey(const Key('work-add-product-manual')).hitTestable(),
        findsOneWidget,
      );
    },
  );

  test(
    'Canonical match cannot survive owner replacement of product identity',
    () {
      expect(master.matchesMasterCatalogueIdentity, isTrue);
      expect(
        master
            .copyWith(title: 'Different product')
            .matchesMasterCatalogueIdentity,
        isFalse,
      );
      expect(
        master.copyWith(barcode: 'other').matchesMasterCatalogueIdentity,
        isFalse,
      );
      expect(
        master
            .copyWith(sellingPrice: 123, stock: 8)
            .matchesMasterCatalogueIdentity,
        isTrue,
      );
      expect(
        master.toBuyPublicProduct(storeName: 'My store').sellerType,
        'Store',
      );
    },
  );
}
