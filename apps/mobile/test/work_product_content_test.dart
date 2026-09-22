import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'fixtures/store_public_handoff_v1.dart';

void main() {
  test(
    'CSV37 duplicate source and original row stay explicit after correction',
    () {
      final review = WorkspaceProductImport.parse(
        'title,brand,pack,purchasePrice,sellingPrice,stock,sku,barcode\n'
        'Rice,Local,1 kg,40,50,4,RICE01,000001\n'
        '\nTea,Local,1 kg,40,50,-1,TEA01,000002\n'
        'Rice,Local,1 kg,40,50,5,rice01,000001',
        catalogue: const [],
        owned: const [],
      );
      final duplicate = review.rows.last;
      expect(duplicate.number, 5);
      expect(duplicate.relatedRowNumber, 2);
      expect(
        duplicate.issueKind,
        WorkspaceProductImportIssueKind.duplicateInFile,
      );
      final invalid = review.rows[1];
      final corrected = WorkspaceProductImport.revalidateRow(
        invalid,
        {...invalid.rawValues, 'stock': '3', 'sku': ' rice01 '},
        catalogue: const [],
        owned: const [],
        readyRows: [review.rows.first],
      );
      expect(corrected.number, 4);
      expect(corrected.relatedRowNumber, 2);
      expect(corrected.issue, contains('CSV row 2'));
      expect(corrected.product, isNull);
      final inStore = WorkspaceProductImport.revalidateRow(
        invalid,
        {...invalid.rawValues, 'stock': '3', 'barcode': '000001'},
        catalogue: const [],
        owned: [review.rows.first.product!],
      );
      expect(
        inStore.issueKind,
        WorkspaceProductImportIssueKind.duplicateInStore,
      );
      expect(inStore.relatedRowNumber, isNull);
      expect(inStore.issue, contains('will not overwrite'));
    },
  );

  test(
    'CSV37 malformed row retains extra cells and never permits correction',
    () {
      final rows = WorkspaceProductImport.parse(
        'title,brand,pack,purchasePrice,sellingPrice,stock\n'
        'Rice,Local,1 kg,40,50,4,DO NOT LOSE\n'
        'Tea,Local,1 kg,40,50',
        catalogue: const [],
        owned: const [],
      ).rows;
      expect(rows.first.sourceCells, hasLength(7));
      expect(rows.first.sourceCells.last, 'DO NOT LOSE');
      expect(rows.first.sourceHeaders, hasLength(6));
      expect(rows.first.issue, contains('expected 6, found 7'));
      expect(rows.last.issue, contains('expected 6, found 5'));
      for (final row in rows) {
        expect(row.canCorrect, isFalse);
        expect(row.product, isNull);
        expect(row.issueKind, WorkspaceProductImportIssueKind.malformedColumns);
        expect(() => row.sourceCells.add('lost'), throwsUnsupportedError);
      }
      expect(
        () => WorkspaceProductImport.csv('title,brand\nRice,"Local'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'row',
            contains('CSV row 2'),
          ),
        ),
      );
    },
  );

  test(
    'CSV35 correction revalidates availability and wholesale metadata in sequence',
    () {
      final values = <String, String>{
        'title': 'Rice',
        'brand': 'Local',
        'pack': '1 kg',
        'variant': 'Long grain',
        'purchasePrice': '40',
        'sellingPrice': '50',
        'stock': '12',
        'stockMode': 'availabilityOnly',
        'available': 'maybe',
        'sellingChannels': 'both',
        'wholesaleSaleType': 'bulk',
        'wholesalePrice': '48',
        'wholesaleMinimum': '10',
        'wholesaleTiers': 'broken',
        'publicListing': 'true',
      };
      final original = WorkspaceProductImport.parse(
        jsonEncode([values]),
        json: true,
        catalogue: const [],
        owned: const [],
      ).rows.single;
      expect(original.issueValues, contains('available'));
      final next = WorkspaceProductImport.revalidateRow(
        original,
        {...original.rawValues, 'available': 'false'},
        catalogue: const [],
        owned: const [],
      );
      expect(next.product, isNull);
      expect(next.issueValues, contains('wholesaleTiers'));
      final ready = WorkspaceProductImport.revalidateRow(
        next,
        {...next.rawValues, 'wholesaleTiers': '20:45'},
        catalogue: const [],
        owned: const [],
      );
      expect(ready.product!.stockMode, WorkspaceStockMode.availabilityOnly);
      expect(ready.product!.available, isFalse);
      expect(ready.product!.wholesaleOffer!.saleType!.name, 'bulk');
      expect(ready.product!.wholesaleOffer!.tiers.single.minimumPacks, 20);
      expect(ready.product!.retailEnabled, isTrue);
      expect(ready.product!.publicListing, isFalse);
      expect(ready.sourceValues, values);
    },
  );
  test(
    'CSV34 raw invalid correction preserves source and every untouched field',
    () {
      final values = <String, String>{
        'title': 'Rice',
        'brand': 'Local',
        'pack': '5 kg',
        'variant': 'Long grain',
        'purchasePrice': '40',
        'sellingPrice': '50',
        'stock': 'not a number',
        'sku': '00027',
        'barcode': '0000123456',
        'description': 'First line\nSecond, "quoted" line',
        'specifications': 'Broken specification',
        'manufacturerName': 'Local maker',
        'netQuantity': '5 kg',
        'quantityPerPack': '5',
        'quantityUnit': 'kg',
        'unitsPerCase': '2',
        'sellingChannels': 'retail',
        'available': 'false',
      };
      final original = WorkspaceProductImport.parse(
        jsonEncode([values]),
        json: true,
        catalogue: const [],
        owned: const [],
      ).rows.single;
      expect(original.product, isNull);
      expect(original.rawValues, values);
      expect(
        () => WorkspaceProductImport.revalidateRow(
          original,
          {...original.rawValues, 'manufacturerName': 'x' * 4001},
          catalogue: const [],
          owned: const [],
        ),
        throwsFormatException,
      );
      expect(() => original.rawValues['stock'] = '2', throwsUnsupportedError);
      final stillBad = WorkspaceProductImport.revalidateRow(
        original,
        {...original.rawValues, 'stock': '12'},
        catalogue: const [],
        owned: const [],
      );
      expect(stillBad.product, isNull);
      expect(stillBad.issueValues, contains('specifications'));
      final corrected = WorkspaceProductImport.revalidateRow(
        stillBad,
        {...stillBad.rawValues, 'specifications': 'Storage: Cool and dry'},
        catalogue: const [],
        owned: const [],
      );
      expect(corrected.issue, isNull);
      expect(corrected.number, original.number);
      expect(corrected.sourceValues, values);
      expect(original.product, isNull);
      final product = corrected.product!;
      expect(product.stock, 12);
      expect(product.sku, '00027');
      expect(product.barcode, '0000123456');
      expect(product.variant, 'Long grain');
      expect(product.pack, '5 kg');
      expect(product.compliance!.manufacturerName, 'Local maker');
      expect(product.content.description, values['description']);
      expect(product.packMeasure!.unitsPerCase, 2);
      expect(product.publicListing, isFalse);
    },
  );

  test(
    'CSV34 corrected exact pack retains catalogue identity and detects duplicates',
    () {
      final item = workspaceMasterCatalogue.first;
      final row = WorkspaceProductImport.parse(
        jsonEncode([
          {
            'title': item.title,
            'brand': item.brand,
            'pack': item.pack,
            'variant': item.variant,
            'barcode': item.barcode,
            'canonicalId': item.canonicalId,
            'purchasePrice': '200',
            'sellingPrice': '264',
            'stock': '-2',
            'publicListing': 'true',
          },
        ]),
        json: true,
        catalogue: [item],
        owned: const [],
      ).rows.single;
      final corrected = WorkspaceProductImport.revalidateRow(
        row,
        {...row.rawValues, 'stock': '8'},
        catalogue: [item],
        owned: const [],
      );
      expect(corrected.matched, isTrue);
      expect(corrected.product!.id, item.id);
      expect(corrected.product!.canonicalId, item.canonicalId);
      expect(corrected.product!.publicListing, isFalse);
      expect(corrected.product!.matchesMasterCatalogueIdentity, isTrue);
      final duplicate = WorkspaceProductImport.revalidateRow(
        row,
        {...row.rawValues, 'stock': '8'},
        catalogue: [item],
        owned: [corrected.product!],
      );
      expect(duplicate.product, isNull);
      expect(duplicate.issue, contains('Already in Store'));
    },
  );

  test('CSV34 malformed columns require source correction without coercion', () {
    final row = WorkspaceProductImport.parse(
      'title,brand,pack,purchasePrice,sellingPrice,stock\nRice,Local,1kg,40,50',
      catalogue: const [],
      owned: const [],
    ).rows.single;
    expect(row.canCorrect, isFalse);
    expect(row.product, isNull);
    expect(
      () => WorkspaceProductImport.revalidateRow(
        row,
        {...row.rawValues, 'stock': '3'},
        catalogue: const [],
        owned: const [],
      ),
      throwsFormatException,
    );
  });

  test(
    'CONTENT every public content snapshot field has an explicit source',
    () {
      final source = File(
        'lib/features/buy/buy_v2_content_contracts.dart',
      ).readAsStringSync();
      final body = source
          .split('class BuyV2ProductContentSnapshot {')[1]
          .split('abstract interface class BuyV2ProductContentAdapter')[0];
      final fields = RegExp(
        r'final\s+[^;\n]+\s+(\w+);',
      ).allMatches(body).map((m) => m.group(1)).toSet();
      expect(fields, isNotEmpty);
      expect(WorkspacePublicationContract.contentBindings.keys.toSet(), fields);
    },
  );
  final content = WorkspaceProductContent.parse({
    'description': 'A pack for everyday cooking.\nStore in a cool, dry place.',
    'highlights': 'Sealed pack\nLabelled net quantity',
    'specifications': 'Container: Pouch\nStorage: Cool: dry place',
  });
  test(
    'CONTENT shared parser retains real copy, optional blank and explicit clear',
    () {
      expect(
        WorkspaceProductContent.parse(content.inputValues).toJson(),
        content.toJson(),
      );
      expect(
        WorkspaceProductContent.parse(
          {},
          existing: content,
          preserveBlank: true,
        ).toJson(),
        content.toJson(),
      );
      expect(
        WorkspaceProductContent.parse({}, existing: content).isEmpty,
        isTrue,
      );
      expect(() => content.highlights.add('Bad'), throwsUnsupportedError);
      expect(
        () => content.specifications['Bad'] = 'Bad',
        throwsUnsupportedError,
      );
      expect(content.specifications['Storage'], 'Cool: dry place');
      for (final values in [
        {'description': 'a' * 4001},
        {'highlights': List.filled(21, 'line').join('\n')},
        {'highlights': 'a' * 241},
        {'specifications': 'Missing separator'},
        {'specifications': 'Name: '},
        {'specifications': 'Name: one\nname: two'},
      ]) {
        expect(
          () => WorkspaceProductContent.parse(values),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'CONTENT exact Store and pack projection covers retail and wholesale',
    () {
      final item = handoffStock().copyWith(content: content);
      final adapter = WorkspacePublicContentAdapter(
        storeId: 'a',
        item: item,
        sourceId: 'test-content-revision',
      );
      for (final channel in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final product = item.toBuyPublicProduct(
          storeName: 'Store',
          storeId: 'a',
          channel: channel,
        );
        final public = adapter.snapshotFor(product);
        expect(public.state, BuyV2ProductContentState.ready);
        expect(public.description, content.description);
        expect(public.highlights, content.highlights);
        expect({
          for (final s in public.specifications) s.label: s.value,
        }, content.specifications);
        for (final wrong in [
          product.copyWith(storeId: 'b'),
          product.copyWith(pack: '5 L'),
          product.copyWith(variant: 'Other'),
          product.copyWith(title: 'Other'),
        ]) {
          final rejected = adapter.snapshotFor(wrong);
          expect(rejected.state, BuyV2ProductContentState.unavailable);
          expect(rejected.description, isNull);
        }
      }
      expect(item.copyWith(stock: 1).content.toJson(), content.toJson());
      final empty = handoffStock()
          .copyWith(content: const WorkspaceProductContent())
          .toBuyPublicContent(storeId: 'a', sourceId: 'test');
      expect(empty.description, isNull);
      expect(empty.highlights, isEmpty); // No fabricated catalogue copy.
    },
  );
  test(
    'CONTENT CSV template, quoted multiline, exact prefill and errors share schema',
    () {
      final template = WorkspaceProductImport.csv(
        WorkspaceProductImport.csvTemplate,
      ).single;
      expect(template, containsAll(WorkspaceProductContent.labels.keys));
      final item = workspaceMasterCatalogue.first.copyWith(content: content);
      Map<String, String> row() => {
        'title': item.title,
        'brand': item.brand,
        'pack': item.pack,
        'variant': item.variant,
        'barcode': item.barcode,
        'purchasePrice': '200',
        'sellingPrice': '264',
        'stock': '4',
      };
      WorkspaceProductImport decode(Map<String, String> r) {
        String cell(String s) => '"${s.replaceAll('"', '""')}"';
        return WorkspaceProductImport.parse(
          '${r.keys.join(',')}\n${r.values.map(cell).join(',')}\n',
          catalogue: [item],
          owned: [],
        );
      }

      final matched = decode(row()).rows.single;
      expect(matched.issue, isNull);
      expect(matched.product!.content.toJson(), content.toJson());
      final changed = decode({
        ...row(),
        'description': 'Updated, quoted "copy"\nSecond line',
        'highlights': 'One\nTwo',
        'specifications': 'Container: Bottle',
      }).rows.single;
      expect(changed.issue, isNull);
      expect(changed.product!.content.highlights, ['One', 'Two']);
      expect(
        changed.product!.content.description,
        contains('"copy"\nSecond line'),
      );
      expect(changed.product!.catalogueFactsRequireReview, isTrue);
      expect(changed.product!.publicListing, isFalse);
      final bad = decode({
        ...row(),
        'specifications': 'Wrong syntax',
      }).rows.single;
      expect(bad.product, isNull);
      expect(bad.issue, contains('specifications:'));
      expect(bad.issueValues, contains('specifications'));
      final payload = jsonEncode(changed.product!.content.toJson());
      expect(payload, isNot(contains('purchasePrice')));
    },
  );
}
