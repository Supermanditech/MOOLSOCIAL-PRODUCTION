import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/widgets/store_publication_settings.dart';
import 'fixtures/store_public_handoff_v1.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'offer classification is explicit, survives edits and never follows MOQ',
    () {
      for (final type in ['wholesale', 'bulk']) {
        for (final minimum in ['1', '100']) {
          final input = WorkspaceSellingInputs.parse({
            'sellingChannels': 'both',
            'wholesaleSaleType': type,
            'wholesalePrice': '100',
            'wholesaleMinimum': minimum,
          });
          final offer = input.wholesale!;
          expect(offer.saleType!.name, type);
          expect(
            WorkspaceWholesaleOffer.fromJson(offer.toJson())!.saleType,
            offer.saleType,
          );
          final edited = WorkspaceSellingInputs.parse({
            'wholesalePrice': '99',
          }, existingWholesale: offer);
          expect(edited.wholesale!.saleType, offer.saleType);
          final disabled = WorkspaceSellingInputs.parse({
            'sellingChannels': 'retail',
          }, existingWholesale: offer);
          expect(disabled.wholesale!.enabled, isFalse);
          expect(disabled.wholesale!.saleType, offer.saleType);
        }
      }
      expect(
        () => WorkspaceSellingInputs.parse({'wholesaleSaleType': 'freight'}),
        throwsFormatException,
      );
      final legacy = WorkspaceWholesaleOffer(
        priceRupees: 100,
        minimumPacks: 100,
        enabled: true,
      );
      expect(
        WorkspaceWholesaleOffer.fromJson(legacy.toJson())!.saleType,
        isNull,
      );
      expect(
        () => WorkspaceWholesaleOffer.fromJson({
          ...legacy.toJson(),
          'saleType': 'guessed',
        }),
        throwsFormatException,
      );
      final item = handoffStock().copyWith(wholesaleOffer: legacy);
      expect(
        item
            .toBuyPublicProduct(
              storeId: 'a',
              storeName: 'Store A',
              channel: BuyV2Destination.wholesale,
            )
            .catalogueListing,
        isFalse,
      );
      expect(
        WorkspacePublicationContract.productIssues(
          item,
          storeId: 'a',
          storeName: 'Store A',
          channel: BuyV2Destination.wholesale,
        ).any((issue) => issue.field.contains('wholesaleSaleType')),
        isTrue,
      );
      expect(item.canSellAtCounter, isTrue);
    },
  );
  test(
    'CSV uses the same offer field with exact row error and private output',
    () {
      WorkspaceProductImport parse(
        String value,
      ) => WorkspaceProductImport.parse(
        'title,brand,pack,purchasePrice,sellingPrice,stock,sellingChannels,wholesalePrice,wholesaleMinimum,wholesaleSaleType\nTest rice,Test brand,1 kg,40,50,8,both,45,1,$value',
        catalogue: [],
        owned: [],
      );
      expect(WorkspaceProductImport.csvTemplate, contains('wholesaleSaleType'));
      for (final type in ['wholesale', 'bulk']) {
        final row = parse(type).rows.single;
        expect(row.issue, isNull);
        expect(row.product!.wholesaleOffer!.saleType!.name, type);
        expect(row.product!.publicListing, isFalse);
      }
      expect(
        parse('bad-type').rows.single.issue,
        contains('wholesaleSaleType'),
      );
      expect(parse('').rows.single.product!.wholesaleOffer!.saleType, isNull);
    },
  );
  test(
    'provider facts never infer fleet mode from minutes in retailer text',
    () {
      for (final text in ['20 minutes', 'Tomorrow', 'Bulk freight']) {
        final facts = handoffStock()
            .copyWith(deliveryPromise: text)
            .toBuyPublicFacts(
              storeName: 'Store A',
              sourceId: 'test-store-a',
              storeVisible: true,
              acceptingOrders: true,
              observedAt: DateTime.utc(2026, 9, 22),
            );
        expect(facts.fulfilmentMode, isNull);
      }
    },
  );
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });
  const a = WorkWorkspace(
    id: 'a',
    name: 'Store A',
    profileId: 'retailer-grocery',
    profileLabel: 'Grocery',
    area: 'Jaipur',
    verified: true,
  );
  const b = WorkWorkspace(
    id: 'b',
    name: 'Store B',
    profileId: 'retailer-grocery',
    profileLabel: 'Grocery',
    area: 'Jaipur',
    verified: true,
  );
  WorkspaceStorePublicationDetails details(
    String type,
    bool retail,
    bool wholesale,
  ) => WorkspaceStorePublicationDetails.fromJson({
    ...handoffStoreDetails().toJson(),
    'businessType': type,
    'retailChannelEnabled': retail,
    'wholesaleChannelEnabled': wholesale,
  });

  test(
    'business type and channel choices round trip without guessing from price',
    () {
      for (final type in WorkspaceStorePublicationDetails.businessTypes.keys) {
        for (final retail in [false, true]) {
          for (final wholesale in [false, true]) {
            final d = details(type, retail, wholesale);
            final restored = WorkspaceStorePublicationDetails.fromJson(
              d.toJson(),
            );
            expect(restored.toJson(), d.toJson());
            expect(restored.channelEnabled(BuyV2Destination.shop), retail);
            expect(
              restored.channelEnabled(BuyV2Destination.wholesale),
              wholesale,
            );
            expect(restored.channelEnabled(BuyV2Destination.medicine), isFalse);
          }
        }
      }
      final legacy = WorkspaceStorePublicationDetails.fromJson({});
      expect(legacy.businessType, 'retailer');
      expect(legacy.retailChannelEnabled, isNull);
      expect(legacy.wholesaleChannelEnabled, isNull);
      for (final patch in [
        {'businessType': 'delivery fleet'},
        {'retailChannelEnabled': 'true', 'wholesaleChannelEnabled': false},
        {'retailChannelEnabled': true},
      ]) {
        expect(
          () => WorkspaceStorePublicationDetails.fromJson(patch),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'both public channels map role, pack, price and disable safely on shared stock',
    () {
      final item = handoffStock();
      for (final type in WorkspaceStorePublicationDetails.businessTypes.keys) {
        for (final channel in [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
        ]) {
          for (final enabled in [true, false]) {
            final d = details(type, enabled, enabled);
            final p = item.toBuyPublicProduct(
              storeId: 'a',
              storeName: 'Store A',
              channel: channel,
              storeDetails: d,
            );
            expect(p.sellerType, d.publicSellerType);
            expect(p.id, item.id);
            expect(p.pack, item.pack);
            expect(
              p.price,
              channel == BuyV2Destination.shop
                  ? item.sellingPrice
                  : item.wholesaleOffer!.priceRupees,
            );
            expect(p.catalogueListing, enabled);
            final expected = WorkspacePublicationContract.sourceProductValues(
              item,
              storeId: 'a',
              storeName: 'Store A',
              channel: channel,
              storeDetails: d,
            );
            expect(expected['sellerType'], p.sellerType);
            final issues = WorkspacePublicationContract.productIssues(
              item,
              storeId: 'a',
              storeName: 'Store A',
              channel: channel,
              storeDetails: d,
            );
            expect(
              issues.any((e) => e.message.contains('channel is off')),
              !enabled,
            );
            expect(item.stock, 48);
            expect(item.canSellAtCounter, isTrue);
          }
        }
      }
      final incomplete = item.copyWith(publicListing: false);
      expect(
        incomplete
            .toBuyPublicProduct(
              storeId: 'a',
              storeName: 'Store A',
              storeDetails: details('manufacturer', true, true),
            )
            .catalogueListing,
        isFalse,
      );
    },
  );

  test(
    'preferences remain Store-scoped and do not rewrite products or publish',
    () {
      final work = WorkSession(gateway: ReviewWorkGateway())
        ..activeWorkspace = a;
      addTearDown(work.dispose);
      final item = handoffStock();
      work.workspaceCatalogueItems.add(item);
      expect(
        work.saveWorkspacePublicationDetails(
          details('manufacturer', false, true),
          expectedStoreId: 'a',
        ),
        isTrue,
      );
      expect(work.workspaceCatalogueItems.single, same(item));
      expect(work.workspaceVisibleToCustomers, isFalse);
      work.activeWorkspace = b;
      expect(work.workspacePublicationDetails.businessType, 'retailer');
      expect(
        work.saveWorkspacePublicationDetails(
          details('supplier', true, true),
          expectedStoreId: 'a',
        ),
        isFalse,
      );
      work.activeWorkspace = a;
      expect(work.workspacePublicationDetails.businessType, 'manufacturer');
      expect(work.workspacePublicationDetails.retailChannelEnabled, isFalse);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'existing Settings edits type and both channels at text scale $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);
        final work = WorkSession(gateway: ReviewWorkGateway())
          ..activeWorkspace = a;
        addTearDown(work.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Inter'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: const Key('capture'),
              child: Scaffold(
                appBar: AppBar(title: const Text('Store settings')),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: StorePublicationSettings(session: work),
                ),
              ),
            ),
          ),
        );
        await tester.tap(
          find.byKey(const Key('work-publication-business-type')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Manufacturer').last);
        await tester.pumpAndSettle();
        expect(work.workspacePublicationDetails.businessType, 'manufacturer');
        await tester.tap(
          find.byKey(const Key('work-publication-channel-wholesale')),
        );
        await tester.pumpAndSettle();
        expect(
          work.workspacePublicationDetails.wholesaleChannelEnabled,
          isTrue,
        );
        expect(work.workspacePublicationDetails.retailChannelEnabled, isTrue);
        expect(tester.takeException(), isNull);
        const output = String.fromEnvironment('STORE_CHANNEL_OUTPUT');
        if (output.isNotEmpty) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(output).create(recursive: true);
            await File(
              '$output/store-selling-$scale.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(
          find.byKey(const Key('work-publication-channel-retail')),
        );
        await tester.pumpAndSettle();
        expect(work.workspacePublicationDetails.retailChannelEnabled, isFalse);
        expect(work.workspaceVisibleToCustomers, isFalse);
      },
    );
  }
}
