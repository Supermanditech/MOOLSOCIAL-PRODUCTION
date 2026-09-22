import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'fixtures/store_public_handoff_v1.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'HANDOFF Store-origin projection covers every current public product field',
    () {
      for (final channel in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final p = handoffStock();
        final projected = p.toBuyPublicProduct(
          storeId: 'fixture-store-a',
          storeName: 'Same display name',
          channel: channel,
        );
        expect(
          handoffPublicProduct(projected).keys.toSet(),
          WorkspacePublicationContract.productBindings.keys.toSet(),
        );
        expect(
          WorkspacePublicationContract.productIssues(
            p,
            storeId: 'fixture-store-a',
            storeName: 'Same display name',
            channel: channel,
          ),
          isEmpty,
        );
        expect(projected.catalogueListing, isTrue);
        expect(projected.price, channel == BuyV2Destination.shop ? 264 : 250);
        expect(
          projected.minimumOrder,
          channel == BuyV2Destination.shop ? 1 : 6,
        );
        expect(
          projected.mediaAssets.single.binding!.storeId,
          'fixture-store-a',
        );
        expect(projected.mediaAssets.single.binding!.skuId, p.id);
      }
    },
  );
  test(
    'HANDOFF variants and same-name stores retain distinct offer identities',
    () {
      final products = [
        handoffStock(),
        handoffStock(litres: 5),
        handoffStock(store: 'b'),
      ];
      expect(products.map((p) => p.id).toSet(), hasLength(3));
      expect(products.map((p) => p.canonicalId).toSet(), hasLength(1));
      for (final p in products) {
        expect(p.cataloguePhoto!.matches(p), isTrue);
        expect(p.compliance!.netQuantity, '${p.packMeasure!.quantityText} L');
      }
      expect(
        handoffStock(litres: 5).packMeasure!.pricePerUnit(1320),
        '₹264.00/L',
      );
    },
  );
  test(
    'HANDOFF private missing-photo wholesale-only and out-of-stock stay distinct',
    () {
      BuyV2Product project(WorkspaceCatalogueItem p) => p.toBuyPublicProduct(
        storeId: 'fixture-store-a',
        storeName: 'Same display name',
      );
      expect(project(handoffStock(private: true)).catalogueListing, isFalse);
      expect(project(handoffStock(retail: false)).catalogueListing, isFalse);
      expect(
        project(
          handoffStock().copyWith(clearCataloguePhoto: true),
        ).catalogueListing,
        isFalse,
      );
      expect(handoffStock(stock: 0).canSellAtCounter, isFalse);
      expect(project(handoffStock(stock: 0)).catalogueListing, isTrue);
      expect(
        project(handoffStock().copyWith(pack: '5 L')).mediaAssets,
        isEmpty,
      );
      expect(
        project(
          handoffStock(revision: 'r2'),
        ).mediaAssets.single.binding!.assetRevision,
        'r2',
      );
    },
  );
  test(
    'HANDOFF pickup off, stale and wrong-store capability must not follow address alone',
    () {
      BuyV2StoreCollectionCapability capability({
        bool on = true,
        String store = 'a',
        bool stale = false,
      }) => BuyV2StoreCollectionCapability(
        storeId: 'fixture-store-$store',
        supportsCollection: on,
        sourceId: 'fixture-source',
        observedAt: handoffTime.subtract(const Duration(hours: 1)),
        validUntil: stale
            ? handoffTime
            : handoffTime.add(const Duration(hours: 1)),
      );
      for (final c in [
        capability(on: false),
        capability(stale: true),
        capability(store: 'b'),
      ]) {
        final store = handoffStoreDetails().toPublicStore(
          id: 'fixture-store-a',
          name: 'Same display name',
          area: 'Jaipur',
          collection: c,
        );
        expect(store.address, isNotEmpty);
        expect(c.isSupportedFor(store.id, now: handoffTime), isFalse);
      }
      expect(
        capability().isSupportedFor('fixture-store-a', now: handoffTime),
        isTrue,
      );
    },
  );
  test(
    'HANDOFF scope and money units survive JSON without private data or authority',
    () {
      final data = storePublicHandoffV1();
      final encoded = jsonEncode(data);
      expect(jsonDecode(encoded)['testOnly'], isTrue);
      expect(data['publicationConfirmed'], isFalse);
      final cases = data['cases'] as List;
      expect(cases, hasLength(8));
      for (final c in cases.cast<Map<String, Object?>>()) {
        for (final p
            in (c['projections'] as List).cast<Map<String, Object?>>()) {
          expect(p.containsKey('purchasePrice'), isFalse);
          expect(p.containsKey('settlementBankAccount'), isFalse);
        }
        expect(c['publicOrderable'], isFalse);
      }
      if (const bool.fromEnvironment('EMIT_STORE_HANDOFF')) {
        // Machine-readable test output; copied to the handoff with apply_patch.
        // ignore: avoid_print
        print('STORE_HANDOFF_JSON:$encoded');
      } else {
        expect(
          jsonDecode(
            File(
              '../../docs/quality/store-public-test-handoff-v1.json',
            ).readAsStringSync(),
          ),
          data,
          reason:
              'Regenerate the exported handoff from the actual Store projection.',
        );
      }
    },
  );
  test(
    'SELLING structured quantity conversion round trip and fractional units',
    () {
      final inputs = WorkspaceSellingInputs.parse({
        'quantityPerPack': '0.125',
        'quantityUnit': 'kg',
      });
      expect(inputs.measure!.quantityMilli, 125);
      expect(inputs.measure!.pricePerUnit(33), '₹264.00/kg');
      expect(inputs.measure!.quantityText, '0.125');
      expect(
        WorkspacePackMeasure.fromJson(inputs.measure!.toJson())!.toJson(),
        inputs.measure!.toJson(),
      );
      final overridden = WorkspaceSellingInputs.parse({
        'unitsPerCase': '12',
      }, existingMeasure: inputs.measure);
      expect(overridden.measure!.quantityMilli, 125);
      expect(overridden.measure!.unitsPerCase, 12);
      for (final q in ['0', '-1', '1.0001', 'NaN', '1000000']) {
        expect(
          () => WorkspaceSellingInputs.parse({
            'quantityPerPack': q,
            'quantityUnit': 'kg',
          }),
          throwsFormatException,
        );
      }
      expect(
        () => WorkspaceSellingInputs.parse({
          'quantityPerPack': '1.5',
          'quantityUnit': 'unit',
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'SELLING tiers preserve units validate steps and support explicit clear',
    () {
      final inputs = WorkspaceSellingInputs.parse({
        'sellingChannels': 'both',
        'wholesalePrice': '250',
        'wholesaleMinimum': '6',
        'wholesaleIncrement': '6',
        'wholesaleTiers': '12:240; 24:230',
      });
      final offer = inputs.wholesale!;
      expect(offer.priceAt(6), 250);
      expect(offer.priceAt(12), 240);
      expect(offer.priceAt(24), 230);
      expect(() => offer.priceAt(7), throwsFormatException);
      expect(
        WorkspaceWholesaleOffer.fromJson(offer.toJson())!.toJson(),
        offer.toJson(),
      );
      expect(
        WorkspaceSellingInputs.parse(
          {},
          existingWholesale: offer,
        ).wholesale!.tiers,
        hasLength(2),
      );
      expect(
        WorkspaceSellingInputs.parse({
          'wholesaleTiers': '',
        }, existingWholesale: offer, clearBlankTiers: true).wholesale!.tiers,
        isEmpty,
      );
      expect(WorkspaceSellingInputs.parse({'wholesaleTiers': ''},
        existingWholesale: offer).wholesale!.tiers, hasLength(2));
      expect(
        WorkspaceSellingInputs.parse({
          'sellingChannels': 'retail',
        }, existingWholesale: offer).wholesale!.enabled,
        isFalse,
      );
      for (final tiers in [
        '12:240;24:245',
        '7:240',
        '12:260',
        '12:1.25',
        '12:240;12:230',
      ]) {
        expect(
          () => WorkspaceSellingInputs.parse({
            'wholesaleTiers': tiers,
          }, existingWholesale: offer),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'SELLING CSV uses same parser, field-specific errors and private-save rule',
    () {
      WorkspaceProductImport parse(
        String quantity,
        String price,
      ) => WorkspaceProductImport.parse(
        'title,brand,pack,purchasePrice,sellingPrice,stock,quantityPerPack,quantityUnit,sellingChannels,wholesalePrice,wholesaleMinimum,wholesaleIncrement\n'
        'Test oil,Test maker,1 L,190,264,48,$quantity,L,both,$price,6,6',
        catalogue: [],
        owned: [],
      );
      final row = parse('1', '250').rows.single;
      expect(row.issue, isNull);
      expect(row.product!.packMeasure!.quantityMilli, 1000);
      expect(row.product!.wholesaleOffer!.priceRupees, 250);
      expect(row.product!.publicListing, isFalse);
      expect(
        parse('wrong', '250').rows.single.issueValues.keys,
        contains('quantityPerPack'),
      );
      expect(
        parse('1', 'wrong').rows.single.issueValues.keys,
        contains('wholesalePrice'),
      );
      for (final field in WorkspaceSellingInputs.labels.keys) {
        expect(WorkspaceProductImport.columns, contains(field));
        expect(WorkspaceProductImport.csvTemplate, contains(field));
      }
    },
  );
  test(
    'HANDOFF field inventory preserves 400 distinct historical field IDs without claiming implementation',
    () {
      final data =
          jsonDecode(
                File(
                  '../../docs/quality/store-public-field-register-v1.json',
                ).readAsStringSync(),
              )
              as Map;
      final rows = (data['entries'] as List).cast<Map>();
      expect(rows, hasLength(400));
      expect(rows.map((row) => row['id']).toSet(), hasLength(400));
      expect(rows.every((row) => row['implementationStatus'] != null), isTrue);
    },
  );
  test('SELLING invalid price is reported without a projection crash', () {
    for (final amount in [-1, 1000000000]) {
      final product = handoffStock().copyWith(sellingPrice: amount);
      final issues = WorkspacePublicationContract.productIssues(product,
        storeId: 'fixture-store-a', storeName: 'Same display name');
      expect(issues.any((issue) => issue.field.endsWith(':sellingPrice')), isTrue);
    }
    final large = WorkspaceSellingInputs.parse({'sellingChannels': 'wholesale',
      'wholesalePrice': '10000000', 'wholesaleMinimum': '1', 'wholesaleIncrement': '1'});
    expect(large.wholesale!.priceAt(1), 10000000);
    for (final field in ['wholesaleMinimum', 'wholesaleIncrement']) {
      expect(() => WorkspaceSellingInputs.parse({field: '0'},
        existingWholesale: handoffStock().wholesaleOffer),
        throwsA(isA<FormatException>().having((error) => error.message, 'field', startsWith('$field:'))));
    }
  });
}
