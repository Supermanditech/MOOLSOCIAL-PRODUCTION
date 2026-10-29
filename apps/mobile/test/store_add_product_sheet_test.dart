import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/screens/store_add_product_sheet.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';

void main() {
  final exportPath = Platform.environment['AGG02_ORIGINAL_RESPONSES'];
  WorkspaceMasterCataloguePage originalPage({String search = '', String? code, bool next = false}) {
    final capture = jsonDecode(File(exportPath!).readAsStringSync()) as Map<String, dynamic>;
    final raw = Map<String, dynamic>.from(capture['page'] as Map);
    raw['query'] = {'search': search, 'code': code};
    if (!next) raw['nextCursor'] = null;
    return WorkspaceMasterCataloguePage.decode(raw, (account: 'owner-two', store: 'store-two', realm: 'evaluation'),
      DateTime.utc(2026, 10, 16, 12), search: search, code: code, pageSize: 30);
  }
  testWidgets('AGG02 original master picker searches and selects descriptive source without saving', (tester) async {
    final calls = <(String, String?, String?)>[];
    WorkspaceMasterCatalogueItem? selected;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StoreAddProductSheet(embedded: true,
      catalogue: const [], ownedProducts: const [], createProduct: (_) => throw StateError('No native Save on source selection'),
      scanBarcode: () async => 'PACK-001', isStoreCurrent: () => true,
      masterLookup: (search, code, cursor) async {calls.add((search, code, cursor)); return originalPage(search: search, code: code);},
      onMasterSelected: (source) => selected = source))));
    await tester.pumpAndSettle();
    expect(find.text('Host fixture oil'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('work-master-search')), 'oil');
    await tester.pump(const Duration(milliseconds: 350)); await tester.pumpAndSettle();
    expect(calls.last, ('oil', null, null));
    await tester.tap(find.text('Host fixture oil')); await tester.pump();
    expect(selected!.title, 'Host fixture oil');
    expect(selected!.toJson().containsKey('channels'), isFalse);
    await tester.tap(find.byTooltip('Scan product barcode')); await tester.pumpAndSettle();
    expect(calls.last, ('', 'PACK-001', null));
    expect(tester.takeException(), isNull);
  }, skip: exportPath == null);
  testWidgets('AGG02 original master picker ignores a late search and keeps narrow enlarged text readable', (tester) async {
    tester.view.physicalSize = const Size(320, 640); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final held = Completer<WorkspaceMasterCataloguePage>();
    await tester.pumpWidget(MaterialApp(home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(body: StoreAddProductSheet(embedded: true, catalogue: const [], ownedProducts: const [],
        createProduct: (_) => throw StateError('No Save'), scanBarcode: () async => null,
        masterLookup: (search, code, cursor) => search.isEmpty ? held.future : Future.value(originalPage(search: search)),
        onMasterSelected: (_) {})))));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('work-master-search')), 'new search');
    await tester.pump(const Duration(milliseconds: 350)); await tester.pumpAndSettle();
    expect(find.text('Host fixture oil'), findsOneWidget);
    held.completeError(StateError('Old request failed after new results'));
    await tester.pumpAndSettle();
    expect(find.text('Host fixture oil'), findsOneWidget);
    expect(find.text('Catalogue details could not be loaded. Try again.'), findsNothing);
    expect(tester.takeException(), isNull);
  }, skip: exportPath == null);
  testWidgets('AGG02 original master error offers retry instead of bundled products', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StoreAddProductSheet(embedded: true,
      catalogue: [workspaceMasterCatalogue.first], ownedProducts: const [], createProduct: (_) => throw StateError('No Save'),
      scanBarcode: () async => null, masterLookup: (search, code, cursor) async {
        calls++; if (calls == 1) throw StateError('Isolated source unavailable'); return originalPage();
      }, onMasterSelected: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.text('Catalogue details could not be loaded. Try again.'), findsOneWidget);
    expect(find.text(workspaceMasterCatalogue.first.title), findsNothing);
    await tester.tap(find.text('Retry')); await tester.pumpAndSettle();
    expect(calls, 2); expect(find.text('Host fixture oil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: exportPath == null);
  WorkspaceMasterCataloguePage capturedPage(String key) {
    final capture = jsonDecode(File(exportPath!).readAsStringSync()) as Map<String, dynamic>;
    final raw = Map<String, dynamic>.from(capture[key] as Map);
    final query = Map<String, dynamic>.from(raw['query'] as Map);
    return WorkspaceMasterCataloguePage.decode(raw, (account: 'owner-two', store: 'store-two', realm: 'evaluation'),
      DateTime.utc(2026, 10, 16, 12), search: query['search'] as String, code: query['code'] as String?, pageSize: 30);
  }
  testWidgets('AGG02 exact complete barcode match opens review once without saving', (tester) async {
    var reviews = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StoreAddProductSheet(embedded: true,
      catalogue: const [], ownedProducts: const [], createProduct: (_) => throw StateError('Review cannot Save'),
      scanBarcode: () async => null, initialMasterCode: 'PACK-002', autoReviewSingleMasterMatch: true,
      masterLookup: (_, __, ___) async => capturedPage('codePage'), onMasterSelected: (_) => reviews++))));
    await tester.pumpAndSettle(); expect(reviews, 1);
    await tester.pump(const Duration(seconds: 1)); expect(reviews, 1);
    expect(tester.takeException(), isNull);
  }, skip: exportPath == null);
  testWidgets('AGG02 paged ambiguous search requires explicit selection after the complete scan', (tester) async {
    var reviews = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StoreAddProductSheet(embedded: true,
      catalogue: const [], ownedProducts: const [], createProduct: (_) => throw StateError('Review cannot Save'),
      scanBarcode: () async => null, initialMasterSearch: 'Host fixture oil', autoReviewSingleMasterMatch: true,
      masterLookup: (_, __, cursor) async => capturedPage(cursor == null ? 'searchPage' : 'searchNext'),
      onMasterSelected: (_) => reviews++))));
    await tester.pumpAndSettle(); expect(reviews, 0);
    await tester.tap(find.text('Load more')); await tester.pumpAndSettle();
    expect(reviews, 0); expect(find.widgetWithText(ListTile, 'Host fixture oil'), findsNWidgets(2));
    await tester.tap(find.text('Host fixture oil').last); await tester.pumpAndSettle();
    expect(reviews, 1); expect(tester.takeException(), isNull);
  }, skip: exportPath == null);
  testWidgets('AGG02 missing original evidence never becomes an automatic match or empty success', (tester) async {
    var reviews = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StoreAddProductSheet(embedded: true,
      catalogue: const [], ownedProducts: const [], createProduct: (_) => throw StateError('No Save'),
      scanBarcode: () async => null, initialMasterCode: 'PACK-002', autoReviewSingleMasterMatch: true,
      masterLookup: (_, __, ___) async => capturedPage('unavailableCode'), onMasterSelected: (_) => reviews++))));
    await tester.pumpAndSettle(); expect(reviews, 0);
    expect(find.text('Refresh catalogue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: exportPath == null);
  final master = workspaceMasterCatalogue.first;
  Future<void> open(
    WidgetTester tester, {
    List<WorkspaceCatalogueItem> owned = const [],
    bool stockOnly = false,
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
                        stockOnly: stockOnly,
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
      expect(find.text('In your store'), findsOneWidget);
      await tester.tap(find.byKey(Key('work-add-product-${master.id}')));
      await tester.pumpAndSettle();
      expect(identical(selected, owned), isTrue);
    },
  );

  testWidgets('LF-PAISE existing exact SKU remains readable and opens its original record', (tester) async {
    final owned = master.copyWith(purchasePriceMinor: 925, sellingPriceMinor: 1025,
      mrpMinor: 1250, sku: 'HOST-EXACT', stock: 3);
    WorkspaceCatalogueItem? selected;
    await open(tester, owned: [owned], stockOnly: true, result: (value) => selected = value);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('₹10.25'), findsWidgets);
    await tester.tap(find.byKey(Key('work-catalogue-add-${master.id}')));
    await tester.pumpAndSettle();
    expect(identical(selected, owned), isTrue);
    expect(selected!.sellingPriceMinor, 1025);
    expect(selected!.stock, 3);
  });

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
    WorkspaceCatalogueItem? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: StoreAddProductSheet(
          catalogue: [master],
          ownedProducts: [owned],
          createProduct: (_) => master,
          scanBarcode: () async => null,
          onSelected: (product) => selected = product,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(Key('work-add-product-${master.id}'));
    expect(action, findsOneWidget);
    await tester.tap(action); await tester.pumpAndSettle();
    expect(selected!.id, master.id);
    expect(selected!.canonicalId, owned.canonicalId);
    expect(selected!.pack, master.pack);
    expect(selected!.pack, isNot(owned.pack));
    expect(selected!.stock, 0);
    expect(identical(selected, owned), isFalse);
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
