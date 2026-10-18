import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'fixtures/store_public_handoff_v1.dart';

// Host-only accepted-source fixture. No production provider or runtime seed.
class _Lf04Catalogue implements BuyV2CataloguePageSource {
  _Lf04Catalogue(this.product);
  final BuyV2Product product;
  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> ids) async =>
      ids.contains(product.id) ? [product] : [];
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected LF04 host catalogue call');
}

// Isolated host readback/consent storage, never runtime policy or customer data.
class _Lf05PolicySource implements BuyV2ProductContentAdapter {
  _Lf05PolicySource(this.value);
  BuyV2ProductContentSnapshot value;
  bool fail = false;
  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    if (fail) throw StateError('Host policy source offline');
    return value;
  }
}
class _Lf05ConsentStore implements BuyV2CustomerStateStore {
  @override
  String get ownerScope => 'host-lf05-buyer';
  BuyV2CustomerStateSnapshot? saved;
  Completer<void>? pending;
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => saved;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    if (pending != null) await pending!.future;
    saved = value;
    return true;
  }
}

void main() {
  test('CONTENT-GUIDE optional descriptive controls follow category without forcing variants', () {
    expect(WorkspaceProductContent.guidedLabelsForCategory('cooking-oil'), [
      'Storage', 'Preparation', 'After opening', 'Contains allergens',
      'May contain allergens', 'Food declaration', 'Nutrition basis',
      'Serving size', 'Nutrition details',
    ]);
    for (final category in ['fruits-vegetables', 'eggs-poultry', 'meat-seafood']) {
      expect(WorkspaceProductContent.guidedLabelsForCategory(category), ['Storage', 'Preparation']);
    }
    expect(WorkspaceProductContent.guidedLabelsForCategory('surface-cleaners'), ['Intended use', 'Usage', 'Dilution', 'Storage', 'Form or material', 'Intended surface']);
    expect(WorkspaceProductContent.guidedLabelsForCategory('hair-care'), ['Intended use', 'Usage', 'Storage', 'Form or material', 'Skin or hair type']);
    expect(WorkspaceProductContent.guidedLabelsForCategory('oral-care'), ['Intended use', 'Usage', 'Storage', 'Form or material']);
    expect(WorkspaceProductContent.guidedLabelsForCategory('baby-care'), ['Intended use', 'Usage', 'Storage', 'Form or material', 'Age or size guidance']);
    expect(WorkspaceProductContent.guidedLabelsForCategory('other'), isEmpty);
    expect(WorkspaceProductContent.guidedLabelsForCategory('unknown-category'), isEmpty);
    expect(const WorkspaceProductContent().withGuidedDetails({'Storage': '', 'Preparation': ' '}).isEmpty, isTrue);
  });
  test('CONTENT-GUIDE electronics and care source details preserve unrelated case through recovery and import', () {
    final original = WorkspaceProductContent.parse({'specifications':
      'model code: Host model\nStorage: Keep dry\nUnknown source field: Retain'});
    const values = {'Model code': 'Host model revised', 'RAM': '8 GB',
      'Storage capacity': '256 GB', 'Compatibility': 'Host supplied standard',
      'In the box': 'Host listed items', 'Form or material': 'Host material'};
    final changed = original.withGuidedDetails(values);
    expect(changed.specifications['model code'], values['Model code']);
    expect(changed.specifications.containsKey('Model code'), isFalse);
    expect(changed.specifications['Storage'], 'Keep dry');
    expect(changed.specifications['Storage capacity'], '256 GB');
    expect(changed.specifications['RAM'], '8 GB');
    expect(changed.specifications['Unknown source field'], 'Retain');
    final base = workspaceMasterCatalogue.first.copyWith(categoryId: 'other', content: changed, publicListing: false);
    final restored = WorkspaceCatalogueItem.fromInventoryJson(base.toInventoryJson());
    expect(restored.content.specifications, changed.specifications);
    final imported = WorkspaceProductImport.parse(jsonEncode([{'title': base.title, 'brand': base.brand,
      'pack': base.pack, 'variant': base.variant, 'canonicalId': base.canonicalId,
      'purchasePrice': '200', 'sellingPrice': '260', 'stock': '0', ...changed.inputValues}]),
      json: true, catalogue: [base], owned: []).rows.single;
    expect(imported.issue, isNull); expect(imported.product!.content.specifications, changed.specifications);
    expect(imported.product!.publicListing, isFalse);
    final cleared = changed.withGuidedDetails({'Model code': ''});
    expect(cleared.specifications.containsKey('model code'), isFalse);
    expect(cleared.specifications['RAM'], '8 GB');
    final full = WorkspaceProductContent(specifications: {
      'model code': 'Original', for (var i = 0; i < 29; i++) 'Host $i': 'Retain'});
    expect(full.withGuidedDetails({'Model code': 'Revised'}).specifications.length, 30);
    expect(() => full.withGuidedDetails({'RAM': '8 GB'}), throwsFormatException);
    expect(WorkspaceProductContent.electronicsGuideLabels.toSet().length, 13);
    for (final label in [...WorkspaceProductContent.electronicsGuideLabels,
      'Form or material', 'Intended surface', 'Skin or hair type', 'Age or size guidance']) {
      expect(WorkspaceProductContent.guidedHintForLabel(label), isNotEmpty);
    }
  });
  test('CONTENT-GUIDE food source values stay separate through save and CSV without default claims', () {
    final base = workspaceMasterCatalogue.first;
    const values = {
      'Contains allergens': 'Milk', 'May contain allergens': 'Peanuts',
      'Food declaration': 'Host pack declaration', 'Nutrition basis': 'Per 100 ml',
      'Serving size': '15 ml', 'Nutrition details': 'Energy 90 kcal per labelled serving',
      'After opening': 'Use within the printed period', 'Storage': 'Keep cool',
      'Preparation': '',
    };
    final content = const WorkspaceProductContent().withGuidedDetails(values);
    final authored = base.copyWith(content: content, publicListing: false);
    final restored = WorkspaceCatalogueItem.fromInventoryJson(authored.toInventoryJson());
    expect(restored.content.specifications, Map.of(values)..remove('Preparation'));
    final raw = {'title': base.title, 'brand': base.brand, 'pack': base.pack, 'variant': base.variant,
      'canonicalId': base.canonicalId, 'purchasePrice': '200', 'sellingPrice': '260',
      'stock': '0', ...content.inputValues};
    final imported = WorkspaceProductImport.parse(jsonEncode([raw]), json: true,
      catalogue: [base], owned: []).rows.single;
    expect(imported.issue, isNull);
    expect(imported.product!.content.specifications, content.specifications);
    expect(imported.product!.publicListing, isFalse);
    final empty = const WorkspaceProductContent().withGuidedDetails({
      for (final label in WorkspaceProductContent.guidedLabelsForCategory('cooking-oil')) label: '',
    });
    expect(empty.isEmpty, isTrue);
    final cleared = content.withGuidedDetails({'Contains allergens': ''});
    expect(cleared.specifications.containsKey('Contains allergens'), isFalse);
    expect(cleared.specifications['May contain allergens'], 'Peanuts');
    expect(cleared.specifications['Nutrition basis'], 'Per 100 ml');
    expect(cleared.specifications['Nutrition details'], values['Nutrition details']);
    final full = WorkspaceProductContent(specifications: {
      'contains allergens': 'Old source',
      for (var i = 0; i < 29; i++) 'Other $i': 'Retain',
    });
    expect(full.withGuidedDetails({'Contains allergens': 'Milk'}).specifications.length, 30);
    expect(full.withGuidedDetails({'Contains allergens': 'Milk'}).specifications['contains allergens'], 'Milk');
    expect(() => full.withGuidedDetails({'May contain allergens': 'Peanuts'}), throwsFormatException);
    expect(full.specifications['contains allergens'], 'Old source');
  });
  test('CONTENT-GUIDE edit and clear retain original case and unrelated source details', () {
    final original = WorkspaceProductContent.parse({'description': 'Host description', 'highlights': 'Host highlight',
      'specifications': 'Container: Pouch\nstorage: Dry\nCustom source detail: Retain'});
    final changed = original.withGuidedDetails({'Storage': ' Cool, dry place ', 'Preparation': ''});
    expect(changed.specifications, {'Container': 'Pouch', 'storage': 'Cool, dry place', 'Custom source detail': 'Retain'});
    expect(changed.description, original.description); expect(changed.highlights, original.highlights);
    final cleared = changed.withGuidedDetails({'Storage': ''});
    expect(cleared.specifications, {'Container': 'Pouch', 'Custom source detail': 'Retain'});
    expect(original.specifications['storage'], 'Dry');
    // Changing the category changes suggestions only; it is never a delete command.
    WorkspaceProductContent.guidedLabelsForCategory('other');
    expect(changed.specifications['storage'], 'Cool, dry place');
  });
  test('CONTENT-GUIDE rejects invalid paragraphs and limits without mutating the source', () {
    final original = WorkspaceProductContent.parse({'specifications': 'Storage: Dry'});
    for (final value in ['One\nTwo', 'One\rTwo', List.filled(501, 'x').join()]) {
      expect(() => original.withGuidedDetails({'Storage': value}), throwsFormatException);
      expect(original.specifications, {'Storage': 'Dry'});
    }
    final full = WorkspaceProductContent(specifications: {for (var i = 0; i < 30; i++) 'Host $i': 'Source $i'});
    expect(() => full.withGuidedDetails({'Storage': 'Dry'}), throwsFormatException);
  });
  test('CONTENT-GUIDE optional cucumber Catalogue manual and CSV paths need no family or phone dimensions', () {
    final cucumber = workspaceMasterCatalogue.first.copyWith(title: 'Host cucumber', brand: '', variant: '',
      categoryId: 'fruits-vegetables', pack: '1 kg', content: const WorkspaceProductContent(),
      sellingPriceMinor: 4025, purchasePriceMinor: 3000, stock: 0, publicListing: false);
    expect(cucumber.variantMembership, isNull);
    expect(cucumber.content.isEmpty, isTrue);
    final roundtrip = WorkspaceCatalogueItem.fromInventoryJson(cucumber.toInventoryJson());
    expect(roundtrip.variantMembership, isNull); expect(roundtrip.content.isEmpty, isTrue);
    const csv = 'title,brand,variant,pack,categoryId,purchasePrice,sellingPrice,stock,sku\n'
      'Host cucumber,,,1 kg,fruits-vegetables,30,40.25,0,HOST-CUCUMBER\n';
    for (final catalogue in [<WorkspaceCatalogueItem>[], [cucumber]]) {
      final row = WorkspaceProductImport.parse(csv, catalogue: catalogue, owned: []).rows.single;
      expect(row.issue, isNull); expect(row.product!.variantMembership, isNull);
      expect(row.product!.content.isEmpty, isTrue); expect(row.product!.sellingPriceMinor, 4025);
      expect(row.product!.publicListing, isFalse);
    }
    const withoutBrandColumn = 'title,pack,categoryId,purchasePrice,sellingPrice,stock,sku\n'
      'Host cucumber,1 kg,fruits-vegetables,30,40.25,0,HOST-CUCUMBER\n';
    final noBrand = WorkspaceProductImport.parse(withoutBrandColumn, catalogue: [], owned: []).rows.single;
    expect(noBrand.issue, isNull); expect(noBrand.product!.brand, isEmpty);
    final applicableBrand = WorkspaceProductImport.parse(withoutBrandColumn.replaceAll('fruits-vegetables', 'surface-cleaners'),
      catalogue: [], owned: []).rows.single;
    expect(applicableBrand.product, isNull); expect(applicableBrand.issueValues.keys, contains('brand'));
  });
  test('CONTENT-GUIDE CSV corrected explicit clear cannot revive catalogue specifications', () {
    final base = workspaceMasterCatalogue.first.copyWith(content: const WorkspaceProductContent(specifications: {'Storage': 'Dry'}));
    final source = {'title': base.title, 'brand': base.brand, 'pack': base.pack,
      'variant': base.variant, 'canonicalId': base.canonicalId, 'purchasePrice': '0',
      'sellingPrice': '260', 'stock': '0', 'specifications': 'Storage: Dry'};
    final original = WorkspaceProductImport.parse(jsonEncode([source]), json: true, catalogue: [base], owned: []).rows.single;
    expect(original.product, isNull);
    final corrected = WorkspaceProductImport.revalidateRow(original,
      {...original.rawValues, 'purchasePrice': '200', 'specifications': ''}, catalogue: [base], owned: []);
    expect(corrected.issue, isNull);
    expect(corrected.product!.content.specifications, isEmpty);
    expect(corrected.sourceValues, original.sourceValues);
  });
  test('CONTENT-GUIDE CSV blank inheritance differs from clear through failed correction retry', () {
    final base = workspaceMasterCatalogue.first.copyWith(content: const WorkspaceProductContent(specifications: {'Storage': 'Dry'}));
    final source = {'title': base.title, 'brand': base.brand, 'pack': base.pack,
      'variant': base.variant, 'canonicalId': base.canonicalId, 'purchasePrice': '0',
      'sellingPrice': '260', 'stock': '0', 'specifications': ''};
    final original = WorkspaceProductImport.parse(jsonEncode([source]), json: true, catalogue: [base], owned: []).rows.single;
    final inherited = WorkspaceProductImport.revalidateRow(original,
      {...original.rawValues, 'purchasePrice': '200'}, catalogue: [base], owned: []);
    expect(inherited.product!.content.specifications, {'Storage': 'Dry'});
    final failed = WorkspaceProductImport.revalidateRow(original, original.rawValues,
      catalogue: [base], owned: [], clearedContentFields: {'specifications'});
    expect(failed.product, isNull); expect(failed.clearedContentFields, {'specifications'});
    final retried = WorkspaceProductImport.revalidateRow(failed,
      {...failed.rawValues, 'purchasePrice': '200'}, catalogue: [base], owned: []);
    expect(retried.product!.content.specifications, isEmpty);
    expect(retried.withReviewedProduct(retried.product!).clearedContentFields, {'specifications'});
    final restored = WorkspaceCatalogueItem.fromInventoryJson(retried.product!.toInventoryJson());
    expect(restored.content.specifications, isEmpty); expect(restored.id, retried.product!.id);
    final refilled = WorkspaceProductImport.revalidateRow(retried,
      {...retried.rawValues, 'specifications': 'Storage: New source'}, catalogue: [base], owned: []);
    expect(refilled.clearedContentFields, isEmpty);
    expect(refilled.product!.content.specifications, {'Storage': 'New source'});
    expect(refilled.sourceValues, original.sourceValues);
    expect(() => WorkspaceProductImport.parse(jsonEncode([source, source]), json: true,
      catalogue: [base], owned: [], clearedContentFields: {'specifications'}), throwsFormatException);
  });
  // Local authoring fixtures only; never injected Stock or reviewed public data.
  WorkspaceVariantFamily ownerFamily({int revision = 1}) => WorkspaceVariantFamily(
    id: 'host-phone-family', revision: revision, title: 'Host phone', brand: 'Host maker',
    categoryId: 'other', content: const WorkspaceProductContent(description: 'Host family facts'),
    options: [for (final colour in ['pink', 'blue']) BuyV2VariantAttribute(
      dimensionId: 'colour', dimensionLabel: 'Colour', optionId: colour,
      optionLabel: colour, kind: BuyV2VariantDimensionKind.colour),
      for (final size in ['128', '256', '512']) BuyV2VariantAttribute(
        dimensionId: 'storage', dimensionLabel: 'Storage', optionId: size,
        optionLabel: '$size GB', kind: BuyV2VariantDimensionKind.storage)]);
  WorkspaceCatalogueItem memberProduct(String id, String colour, String storage,
      {bool shared = true}) {
    final product = WorkspaceCatalogueItem.fromInventoryJson({
      ...workspaceMasterCatalogue.first.toInventoryJson(), 'id': id, 'canonicalId': 'exact-$id',
      'sku': id, 'barcode': '', 'stock': 0, 'cataloguePhoto': null, 'privatePhoto': null,
      'publicListing': false});
    return ownerFamily().applyTo(product.copyWith(variantMembership: WorkspaceVariantMembership(
      familyId: 'host-phone-family', selections: {'colour': colour, 'storage': storage},
      useSharedContent: shared)));
  }
  WorkspaceSavedInventory familyInventory(List<WorkspaceCatalogueItem> products,
      {List<WorkspaceVariantFamily>? families}) => WorkspaceSavedInventory(
    account: 'host-account', store: 'host-store', qa: true, revision: 1,
    savedAt: DateTime.utc(2026, 10, 17), products: products, movements: const [],
    variantFamilies: families ?? [ownerFamily()]);

  test('CONTENT-GUIDE shared family details and SKU exceptions survive saved recovery', () {
    final shared = ownerFamily().copyWith(content: const WorkspaceProductContent()
      .withGuidedDetails({'Storage': 'Shared source instructions'}));
    final a = shared.applyTo(memberProduct('host-a', 'pink', '128'));
    final b = memberProduct('host-b', 'blue', '512', shared: false).copyWith(
      content: const WorkspaceProductContent().withGuidedDetails({'Storage': 'Exact SKU exception'}));
    final recovered = WorkspaceSavedInventory.fromJson(jsonDecode(jsonEncode(familyInventory([a, b], families: [shared]).toJson())));
    expect(recovered.products.first.content.specifications['Storage'], 'Shared source instructions');
    expect(recovered.products.last.content.specifications['Storage'], 'Exact SKU exception');
    expect(recovered.products.map((p) => p.id), ['host-a', 'host-b']);
    expect(recovered.products.every((p) => !p.publicListing), isTrue);
  });

  test('CONTENT-GUIDE CSV shared clear requires explicit SKU exception', () {
    final family = ownerFamily().copyWith(content: const WorkspaceProductContent(specifications: {'Storage': 'Shared source'}));
    final source = {'title': '', 'brand': '', 'pack': '1 unit', 'purchasePrice': '85.10',
      'sellingPrice': '100.25', 'stock': '-1', 'sku': 'HOST-GUIDED-GROUP',
      'productGroup': family.id, 'option:Colour': 'pink', 'option:Storage': '256 GB'};
    final original = WorkspaceProductImport.parse(jsonEncode([source]), json: true,
      catalogue: [], owned: [], variantFamilies: [family]).rows.single;
    final blocked = WorkspaceProductImport.revalidateRow(original,
      {...original.rawValues, 'stock': '0', 'specifications': ''}, catalogue: [], owned: [],
      variantFamilies: [family], clearedContentFields: {'specifications'});
    expect(blocked.product, isNull); expect(blocked.issueValues.keys, contains('shareGroupContent'));
    final exception = WorkspaceProductImport.revalidateRow(blocked,
      {...blocked.rawValues, 'shareGroupContent': 'false'}, catalogue: [], owned: [], variantFamilies: [family]);
    expect(exception.issue, isNull); expect(exception.product!.content.specifications, isEmpty);
    expect(exception.product!.variantMembership!.useSharedContent, isFalse);
    expect(family.content.specifications, {'Storage': 'Shared source'});
  });
  test('LF03 owner family and exact SKU membership survive one v4 aggregate', () {
    final first = memberProduct('host-a', 'pink', '128');
    final second = memberProduct('host-b', 'blue', '512').copyWith(sellingPriceMinor: 10025);
    final raw = familyInventory([first, second]).toJson();
    expect(raw['version'], 4);
    final restored = WorkspaceSavedInventory.fromJson(jsonDecode(jsonEncode(raw)));
    expect(restored.variantFamilies.single.id, 'host-phone-family');
    expect(restored.products.map((p) => p.canonicalId), ['exact-host-a', 'exact-host-b']);
    expect(restored.products[1].variantMembership!.selections['storage'], '512');
    expect(restored.products[1].sellingPriceMinor, 10025);
    expect(restored.products.first.stock, 0);
    expect(restored.products.first.content.description, 'Host family facts');
  });
  test('LF03 owner legacy inventory remains byte-compatible without family fields', () {
    final item = workspaceMasterCatalogue.first;
    final raw = WorkspaceSavedInventory(account: 'host-account', store: 'host-store', qa: true,
      revision: 1, savedAt: DateTime.utc(2026), products: [item], movements: const []).toJson();
    expect(raw['version'], 1);
    expect(raw.containsKey('variantFamilies'), isFalse);
    expect(item.toInventoryJson().containsKey('variantMembership'), isFalse);
    expect(jsonEncode(WorkspaceSavedInventory.fromJson(jsonDecode(jsonEncode(raw))).toJson()), jsonEncode(raw));
  });
  test('LF03 owner aggregate rejects missing family malformed and duplicate combinations', () {
    final a = memberProduct('host-a', 'pink', '128');
    final b = memberProduct('host-b', 'blue', '512');
    final original = familyInventory([a, b]).toJson();
    for (final fault in ['missing', 'tuple', 'definition', 'selection', 'version', 'old-member']) {
      final raw = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      switch (fault) {
        case 'missing': raw['variantFamilies'] = []; break;
        case 'tuple': raw['products'][1]['variantMembership'] = raw['products'][0]['variantMembership']; break;
        case 'definition': raw['variantFamilies'][0]['options'].add(raw['variantFamilies'][0]['options'][0]); break;
        case 'selection': raw['products'][0]['variantMembership']['selections'].remove('colour'); break;
        case 'version': raw['version'] = 99; break;
        case 'old-member': raw['products'][0]['version'] = 1; break;
      }
      expect(() => WorkspaceSavedInventory.fromJson(raw), throwsFormatException, reason: fault);
    }
  });
  test('LF03 owner common facts preserve exact money stock and content exceptions', () {
    final product = memberProduct('host-a', 'pink', '128', shared: false)
      .copyWith(stock: 8, sellingPriceMinor: 10025,
        content: const WorkspaceProductContent(description: 'Exact SKU exception'));
    final family = ownerFamily(revision: 2).copyWith(title: 'Updated common name',
      content: const WorkspaceProductContent(description: 'Updated common content'));
    final result = family.applyTo(product);
    expect(result.id, product.id); expect(result.canonicalId, product.canonicalId);
    expect(result.stock, 8); expect(result.sellingPriceMinor, 10025);
    expect(result.title, 'Updated common name');
    expect(result.content.description, 'Exact SKU exception');
    expect(family.attributesFor(result.variantMembership!).map((a) => a.optionId), ['pink', '128']);
  });
  test('LF03 owner session applies family common edit atomically without quantity movements', () {
    final session = WorkSession()..seedVerifiedWorkspace();
    addTearDown(session.dispose);
    session.workspaceCatalogueItems.clear();
    final a = memberProduct('host-a', 'pink', '128');
    final b = memberProduct('host-b', 'blue', '512').copyWith(sellingPriceMinor: 10025);
    expect(session.addOrUpdateWorkspaceProduct(a, variantFamily: ownerFamily()), isTrue);
    expect(session.addOrUpdateWorkspaceProduct(b), isTrue);
    final before = session.workspaceStockMovements.length;
    final changed = ownerFamily(revision: 2).copyWith(title: 'Changed family name');
    expect(session.addOrUpdateWorkspaceProduct(a, variantFamily: changed), isTrue);
    expect(session.workspaceVariantFamilies.single.revision, 2);
    expect(session.workspaceCatalogueItems.map((p) => p.title).toSet(), {'Changed family name'});
    expect(session.workspaceCatalogueItems.map((p) => p.canonicalId), ['exact-host-a', 'exact-host-b']);
    expect(session.workspaceCatalogueItems[1].sellingPriceMinor, 10025);
    expect(session.workspaceStockMovements.length, before);
    expect(session.workspaceCatalogueItems.every((p) => p.catalogueFactsRequireReview && !p.publicListing), isTrue);
    // Same frozen edit retry does not allocate another SKU, family or movement.
    expect(session.addOrUpdateWorkspaceProduct(a, variantFamily: changed), isTrue);
    expect(session.workspaceCatalogueItems.length, 2);
    expect(session.workspaceStockMovements.length, before);
  });
  test('LF03 owner duplicate and invalid family edits leave entire session unchanged', () {
    final session = WorkSession()..seedVerifiedWorkspace();
    addTearDown(session.dispose);
    session.workspaceCatalogueItems.clear();
    final first = memberProduct('host-a', 'pink', '128');
    expect(session.addOrUpdateWorkspaceProduct(first, variantFamily: ownerFamily()), isTrue);
    String state() => jsonEncode([session.workspaceVariantFamilies.map((f) => f.toJson()).toList(),
      session.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList(),
      session.workspaceStockMovements.map((m) => m.contentIdentity).toList()]);
    final before = state();
    expect(() => session.addOrUpdateWorkspaceProduct(memberProduct('host-b', 'pink', '128')),
      throwsFormatException);
    expect(state(), before);
    expect(() => session.addOrUpdateWorkspaceProduct(first,
      variantFamily: ownerFamily(revision: 3).copyWith(title: 'Stale family edit')), throwsFormatException);
    expect(state(), before);
    expect(() => session.addOrUpdateWorkspaceProduct(first.copyWith(variantMembership:
      WorkspaceVariantMembership(familyId: first.variantMembership!.familyId,
        selections: {'colour': 'blue', 'storage': '128'}))), throwsFormatException);
    expect(state(), before);
    expect(() => session.importWorkspaceProducts([memberProduct('host-b', 'pink', '128')]),
      throwsFormatException);
    expect(state(), before);
  });

  test('LF03 owner adding dimensions requires explicit atomic assignments and preserves choices', () {
    final session = WorkSession()..seedVerifiedWorkspace();
    addTearDown(session.dispose);
    session.workspaceCatalogueItems.clear();
    final a = memberProduct('host-a', 'pink', '128');
    final b = memberProduct('host-b', 'blue', '512');
    session.addOrUpdateWorkspaceProduct(a, variantFamily: ownerFamily());
    session.addOrUpdateWorkspaceProduct(b);
    final expanded = ownerFamily(revision: 2).copyWith(options: [
      ...ownerFamily().options,
      const BuyV2VariantAttribute(dimensionId: 'ram', dimensionLabel: 'RAM',
        optionId: '8', optionLabel: '8 GB', kind: BuyV2VariantDimensionKind.other),
      const BuyV2VariantAttribute(dimensionId: 'ram', dimensionLabel: 'RAM',
        optionId: '16', optionLabel: '16 GB', kind: BuyV2VariantDimensionKind.other),
    ]);
    String state() => jsonEncode([session.workspaceVariantFamilies.map((f) => f.toJson()).toList(),
      session.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList()]);
    final before = state();
    expect(() => session.addOrUpdateWorkspaceProduct(a, variantFamily: expanded), throwsFormatException);
    expect(state(), before);
    expect(() => session.addOrUpdateWorkspaceProduct(a, variantFamily: expanded, variantSelections: {
      a.id: {...a.variantMembership!.selections, 'ram': '8'},
    }), throwsFormatException);
    expect(state(), before);
    expect(() => session.addOrUpdateWorkspaceProduct(a, variantFamily: expanded, variantSelections: {
      a.id: {...a.variantMembership!.selections, 'colour': 'blue', 'ram': '8'},
      b.id: {...b.variantMembership!.selections, 'ram': '16'},
    }), throwsFormatException);
    expect(state(), before);
    final movements = session.workspaceStockMovements.length;
    expect(session.addOrUpdateWorkspaceProduct(a, variantFamily: expanded, variantSelections: {
      a.id: {...a.variantMembership!.selections, 'ram': '8'},
      b.id: {...b.variantMembership!.selections, 'ram': '16'},
    }), isTrue);
    expect(session.workspaceCatalogueItems.map((p) => p.variantMembership!.selections['ram']), ['8', '16']);
    expect(session.workspaceCatalogueItems.map((p) => p.canonicalId), [a.canonicalId, b.canonicalId]);
    expect(session.workspaceStockMovements.length, movements);
    expect(session.workspaceOperationsSyncError, contains('remain on this device'));
  });
  test('LF03 owner first family assignment cannot rewrite saved canonical identity', () {
    final session = WorkSession()..seedVerifiedWorkspace();
    addTearDown(session.dispose);
    session.workspaceCatalogueItems.clear();
    final member = memberProduct('host-a', 'pink', '128');
    final raw = member.toInventoryJson()..remove('variantMembership')..remove('moneyVersion');
    raw['version'] = 1;
    final plain = WorkspaceCatalogueItem.fromInventoryJson(raw);
    session.addOrUpdateWorkspaceProduct(plain);
    expect(() => session.addOrUpdateWorkspaceProduct(member.copyWith(canonicalId: 'different'),
      variantFamily: ownerFamily()), throwsFormatException);
    expect(session.workspaceVariantFamilies, isEmpty);
    expect(session.workspaceCatalogueItems.single.canonicalId, plain.canonicalId);
  });

  test('LF03 CSV saved family inherits facts once and keeps exact actual combination', () {
    final source = {'title': '', 'brand': '', 'pack': '1 unit', 'sku': 'HOST-CSV-BLUE',
      'purchasePrice': '85.10', 'sellingPrice': '100.25', 'stock': '0',
      'productGroup': ownerFamily().title, 'option:Colour': 'blue', 'option:Storage': '512 GB'};
    final review = WorkspaceProductImport.parse(jsonEncode([source]), json: true,
      catalogue: [], owned: [memberProduct('host-a', 'pink', '128')],
      variantFamilies: [ownerFamily()]);
    final row = review.rows.single;
    expect(row.issue, isNull);
    final product = row.product!;
    expect(product.title, ownerFamily().title); expect(product.brand, ownerFamily().brand);
    expect(product.content.description, ownerFamily().content.description);
    expect(product.variantMembership!.familyId, ownerFamily().id);
    expect(product.variantMembership!.selections, {'colour': 'blue', 'storage': '512'});
    expect(product.variant, 'blue · 512 GB');
    expect(product.purchasePriceMinor, 8510); expect(product.sellingPriceMinor, 10025);
    expect(product.publicListing, isFalse); expect(product.catalogueFactsRequireReview, isTrue);
    expect(row.sourceValues, source);
    expect(row.rawValues['title'], ownerFamily().title);
  });
  test('LF03 CSV rejects missing invalid and already-saved group combinations', () {
    final source = {'title': '', 'brand': '', 'pack': '1 unit', 'purchasePrice': '85',
      'sellingPrice': '100', 'stock': '0', 'productGroup': ownerFamily().id,
      'option:Colour': 'blue', 'option:Storage': '512 GB'};
    for (final fault in ['unknown-group', 'missing', 'option', 'extra', 'duplicate', 'common']) {
      final raw = Map<String, String>.of(source);
      final owned = [memberProduct('host-a', 'pink', '128')];
      switch (fault) {
        case 'unknown-group': raw['productGroup'] = 'missing'; break;
        case 'missing': raw.remove('option:Storage'); break;
        case 'option': raw['option:Colour'] = 'green'; break;
        case 'extra': raw['option:RAM'] = '8 GB'; break;
        case 'duplicate': owned.add(memberProduct('host-b', 'blue', '512')); break;
        case 'common': raw['title'] = 'Contradictory group name'; break;
      }
      final row = WorkspaceProductImport.parse(jsonEncode([raw]), json: true,
        catalogue: [], owned: owned, variantFamilies: [ownerFamily()]).rows.single;
      expect(row.product, isNull, reason: fault);
      expect(row.issue, isNotNull, reason: fault);
      expect(row.sourceValues, raw, reason: fault);
    }
  });

  test('LF03 CSV named columns preserve mixed rows correction and source evidence', () {
    const csv = 'title,brand,pack,purchasePrice,sellingPrice,stock,productGroup,option:Storage,option:Colour,sku\n'
      ',,1 unit,85.10,100.25,0,host-a,512 GB,green,HOST-NEW\n'
      'Legacy rice,Host,1 kg,50,60,0,,,,HOST-LEGACY\n';
    final owned = [memberProduct('host-a', 'pink', '128')];
    final review = WorkspaceProductImport.parse(csv, catalogue: [], owned: owned, variantFamilies: [ownerFamily()]);
    final invalid = review.rows.first;
    expect(invalid.product, isNull); expect(invalid.issueValues.keys, ['option:Colour']);
    final corrected = WorkspaceProductImport.revalidateRow(invalid,
      {...invalid.rawValues, 'option:Colour': 'blue'}, catalogue: [], owned: owned,
      variantFamilies: [ownerFamily()], readyRows: [review.rows.last]);
    expect(corrected.issue, isNull); expect(corrected.number, 2);
    expect(corrected.sourceValues['option:Colour'], 'green');
    expect(corrected.sourceValues['title'], ''); expect(corrected.sourceCells, invalid.sourceCells);
    expect(corrected.product!.variantMembership!.selections, {'colour': 'blue', 'storage': '512'});
    expect(review.rows.last.product!.title, 'Legacy rice');
    expect(review.rows.last.product!.variantMembership, isNull);
  });
  test('LF03 CSV references reject namespace ambiguity and repeated actual tuples', () {
    final source = {'title': '', 'brand': '', 'pack': '1 unit', 'purchasePrice': '85',
      'sellingPrice': '100', 'stock': '0', 'productGroup': ownerFamily().id,
      'option:Colour': 'blue', 'option:Storage': '512 GB'};
    final duplicate = WorkspaceProductImport.parse(jsonEncode([source, {...source, 'sku': 'DIFFERENT', 'pack': '2 units'}]),
      json: true, catalogue: [], owned: [], variantFamilies: [ownerFamily()]);
    expect(duplicate.rows.first.issue, isNull);
    expect(duplicate.rows.last.product, isNull);
    expect(duplicate.rows.last.relatedRowNumber, 1);
    final other = WorkspaceVariantFamily(id: 'other-host-family', revision: 1, title: ownerFamily().id,
      brand: ownerFamily().brand, categoryId: ownerFamily().categoryId, options: ownerFamily().options);
    final ambiguous = WorkspaceProductImport.parse(jsonEncode([source]), json: true, catalogue: [],
      owned: [], variantFamilies: [ownerFamily(), other]);
    expect(ambiguous.rows.single.issue, contains('unambiguous'));
    expect(() => WorkspaceProductImport.parse(
      'title,brand,pack,purchasePrice,sellingPrice,stock,option:Colour,option: colour\nA,B,1,1,2,0,pink,pink',
      catalogue: [], owned: []), throwsFormatException);
  });
  test('LF03 CSV content exceptions are explicit and reviewed family snapshots fence save', () {
    final source = {'title': '', 'brand': '', 'pack': '1 unit', 'purchasePrice': '85',
      'sellingPrice': '100', 'stock': '0', 'productGroup': ownerFamily().id,
      'option:Colour': 'blue', 'option:Storage': '512 GB', 'description': 'SKU-only details'};
    WorkspaceProductImport parse(Map<String, String> row) => WorkspaceProductImport.parse(jsonEncode([row]),
      json: true, catalogue: [], owned: [], variantFamilies: [ownerFamily()]);
    expect(parse(source).rows.single.issue, contains('Set false'));
    final review = parse({...source, 'shareGroupContent': 'false'});
    final product = review.rows.single.product!;
    expect(product.content.description, 'SKU-only details');
    expect(product.variantMembership!.useSharedContent, isFalse);
    final session = WorkSession()..seedVerifiedWorkspace();
    addTearDown(session.dispose);
    session.workspaceCatalogueItems.clear();
    final original = memberProduct('host-a', 'pink', '128');
    session.addOrUpdateWorkspaceProduct(original, variantFamily: ownerFamily());
    final changed = ownerFamily(revision: 2).copyWith(options: [...ownerFamily().options,
      const BuyV2VariantAttribute(dimensionId: 'colour', dimensionLabel: 'Colour', optionId: 'green',
        optionLabel: 'green', kind: BuyV2VariantDimensionKind.colour)]);
    session.addOrUpdateWorkspaceProduct(original, variantFamily: changed);
    final before = jsonEncode(session.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList());
    expect(() => session.importWorkspaceProducts([product], addOnly: true,
      stockEntryMethod: WorkspaceStockEntryMethod.csv, variantFamilyFingerprints: review.variantFamilyFingerprints),
      throwsFormatException);
    expect(jsonEncode(session.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList()), before);
  });

  test('LF03 CSV correction recomputes inherited values and preserves explicit input intent', () {
    const csv = 'title,brand,pack,purchasePrice,sellingPrice,stock,productGroup,option:Colour,option:Storage,sku\n'
      ',,1 unit,85,bad,0,host-phone-family,blue,512 GB,HOST-INTENT\n';
    final invalid = WorkspaceProductImport.parse(csv, catalogue: [], owned: [],
      variantFamilies: [ownerFamily()]).rows.single;
    expect(invalid.issueValues.keys, ['sellingPrice']);
    expect(invalid.rawValues['variant'], 'blue · 512 GB');
    expect(invalid.inputValues!.containsKey('variant'), isFalse);
    final corrected = WorkspaceProductImport.revalidateRow(invalid, {...invalid.rawValues,
      'sellingPrice': '100', 'option:Colour': 'pink', 'option:Storage': '128 GB'},
      catalogue: [], owned: [], variantFamilies: [ownerFamily()]);
    expect(corrected.issue, isNull);
    expect(corrected.product!.variant, 'pink · 128 GB');
    expect(corrected.sourceValues['sellingPrice'], 'bad');
    expect(corrected.inputValues!['sellingPrice'], '100');
    expect(corrected.inputValues!['title'], '');
    final edited = corrected.withReviewedProduct(corrected.product!.copyWith(sellingPriceMinor: 10025));
    expect(edited.sourceCells, invalid.sourceCells); expect(edited.sourceHeaders, invalid.sourceHeaders);
    expect(edited.sourceValues, invalid.sourceValues); expect(edited.rawValues, corrected.rawValues);
    expect(edited.inputValues, corrected.inputValues); expect(edited.product!.sellingPriceMinor, 10025);
    expect(edited.product!.publicListing, isFalse);
  });
  test('LF03 CSV exact blank shared content never restores another catalogue description', () {
    final blank = ownerFamily().copyWith(content: const WorkspaceProductContent());
    final raw = memberProduct('host-reviewed', 'blue', '512').toInventoryJson()
      ..remove('variantMembership')..remove('moneyVersion');
    raw['version'] = 1;
    final catalogue = WorkspaceCatalogueItem.fromInventoryJson(raw).copyWith(pack: '1 unit',
      variant: 'blue · 512 GB', content: const WorkspaceProductContent(description: 'Other catalogue details'));
    final row = WorkspaceProductImport.parse(jsonEncode([{'title': '', 'brand': '', 'pack': '1 unit',
      'purchasePrice': '85', 'sellingPrice': '100', 'stock': '0', 'productGroup': blank.id,
      'option:Colour': 'blue', 'option:Storage': '512 GB'}]), json: true,
      catalogue: [catalogue], owned: [], variantFamilies: [blank]).rows.single;
    expect(row.issue, isNull);
    expect(row.matched, isTrue);
    expect(row.product!.content.description, isEmpty);
    expect(() => WorkspaceVariantFamily.validateInventory([blank], [row.product!]), returnsNormally);
  });

  test('LF-PAISE CSV preserves exact prices tiers source rows and legacy amounts', () {
    // Host import review only; these records never seed a device or provider.
    const csv = 'title,brand,pack,purchasePrice,sellingPrice,mrp,stock,sku,sellingChannels,wholesaleSaleType,wholesalePrice,wholesaleMinimum,wholesaleTiers\n'
      'Decimal rice,Host,1 kg,9.25,10.25,12.50,3,HOST-DEC,both,bulk,10.15,1,2:9.95\n'
      'Whole rice,Host,1 kg,9,10,12,3,HOST-WHOLE,retail,,,,\n'
      'Correct rice,Host,1 kg,9.25,10.255,12.50,3,HOST-FIX,retail,,,,';
    final reviewed = WorkspaceProductImport.parse(csv, catalogue: [], owned: []);
    final first = reviewed.rows.first;
    expect(first.issue, isNull);
    final item = first.product!;
    expect(item.purchasePriceMinor, 925);
    expect(item.sellingPriceMinor, 1025);
    expect(item.mrpMinor, 1250);
    expect(item.stock, 3);
    expect(item.unitPrice, '₹10.25/1 kg');
    expect(item.wholesaleOffer!.priceAtMinor(2), 995);
    expect(item.publicListing, isFalse);
    final facts = item.toBuyPublicFacts(storeName: 'Host Store', sourceId: 'Host inputs',
      storeVisible: false, acceptingOrders: false, observedAt: DateTime.utc(2026, 10, 17));
    expect(facts.priceMinor, 1025);
    expect(facts.orderabilityLabel, 'Not listed for customers');
    expect(WorkspaceCatalogueItem.fromInventoryJson(item.toInventoryJson()).sellingPriceMinor, 1025);
    final whole = reviewed.rows[1].product!;
    expect(whole.usesMinorAmounts, isFalse);
    expect(whole.toInventoryJson()['sellingPrice'], 10);
    final invalid = reviewed.rows.last;
    expect(invalid.issueValues.keys, contains('sellingPrice'));
    final fixed = WorkspaceProductImport.revalidateRow(invalid,
      {...invalid.rawValues, 'sellingPrice': '10.25'}, catalogue: [], owned: [],
      readyRows: reviewed.rows.where((row) => row.product != null).toList());
    expect(fixed.issue, isNull);
    expect(fixed.number, invalid.number);
    expect(fixed.sourceCells, invalid.sourceCells);
    expect(fixed.sourceValues, invalid.sourceValues);
    expect(fixed.product!.sku, 'HOST-FIX');
    expect(fixed.product!.sellingPriceMinor, 1025);
  });

  test('LF-PAISE CSV retains exact matched MRP and original independent limits', () {
    final base = handoffStock().copyWith(purchasePriceMinor: 925,
      sellingPriceMinor: 1025, mrpMinor: 1250, clearWholesaleOffer: true);
    WorkspaceProductImportRow decode({String purchase = '9.25', String selling = '10.25',
      String stock = '3', String mrp = ''}) => WorkspaceProductImport.parse(jsonEncode([{
        'title': base.title, 'brand': base.brand, 'variant': base.variant, 'pack': base.pack,
        'canonicalId': base.canonicalId, 'purchasePrice': purchase, 'sellingPrice': selling,
        'stock': stock, 'mrp': mrp,
      }]), json: true, catalogue: [base], owned: []).rows.single;
    final retained = decode();
    expect(retained.issue, isNull);
    expect(retained.product!.id, base.id);
    expect(retained.product!.mrpMinor, 1250);
    expect(retained.product!.purchasePriceMinor, 925);
    expect(decode(selling: '12.51').issueValues.keys, contains('sellingPrice'));
    expect(decode(mrp: '10.24').issueValues.keys, contains('mrp'));
    expect(decode(purchase: '2147483648', selling: '2147483649', mrp: '2147483650')
      .issueValues.keys, contains('purchasePrice'));
    expect(decode(stock: '2147483648').issueValues.keys, contains('stock'));
    expect(decode(stock: '3.5').issueValues.keys, contains('stock'));
    for (final text in ['9.001', '1e2', '-1', 'NaN']) {
      expect(decode(purchase: text).issueValues.keys, contains('purchasePrice'));
    }
  });

  test('LF05 device-state codec retains unresolved holds separately and reads legacy snapshots', () async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final preferences = SharedPreferencesAsync();
    const owner = 'host-policy-codec', key = 'moolsocial.buy.customer-state.host-policy-codec.v1';
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: owner);
    expect(await store.write(const BuyV2CustomerStateSnapshot(
      supplierPolicyUnresolvedProductKeys: {'exact-host-product'}, cartQuantities: {'host-sku': 2})), true);
    final restarted = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: owner);
    final retained = (await restarted.read())!;
    expect(retained.supplierPolicyUnresolvedProductKeys, {'exact-host-product'});
    expect(retained.supplierPolicyRequiredProductKeys, isEmpty);
    expect(retained.supplierPolicyAcceptances, isEmpty);
    expect(retained.cartQuantities, {'host-sku': 2});
    expect(await BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'other-host-owner').read(), isNull);
    final legacy = jsonDecode((await preferences.getString(key))!) as Map<String, dynamic>;
    legacy.remove('supplierPolicyUnresolvedProductKeys');
    await preferences.setString(key, jsonEncode(legacy));
    expect((await restarted.read())!.supplierPolicyUnresolvedProductKeys, isEmpty);
    legacy['supplierPolicyUnresolvedProductKeys'] = 'corrupt-not-an-empty-hold';
    await preferences.setString(key, jsonEncode(legacy));
    await expectLater(restarted.read(), throwsFormatException);
  });
  final policyNow = DateTime.utc(2026, 10, 15, 10);
  test('LF05 unresolved policy at Checkout preserves Cart and creates no order', () async {
    final item = handoffStock(), core = BuySession();
    final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store');
    final source = _Lf05PolicySource(BuyV2ProductContentSnapshot(productId: product.id,
      sourceId: 'host-policy', state: BuyV2ProductContentState.ready,
      observedAt: policyNow, supplierPolicyAcceptanceRequired: false));
    final session = BuyV2Session(core: core, cataloguePageSource: _Lf04Catalogue(product),
      productContentAdapter: source, catalogueNow: () => policyNow);
    addTearDown(session.dispose); addTearDown(core.dispose);
    expect(await session.openLinkedProduct(product.id), true);
    expect(session.addProduct(product.id), true);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), true);
    source.value = BuyV2ProductContentSnapshot(productId: product.id,
      sourceId: 'host-policy', state: BuyV2ProductContentState.unavailable,
      supplierPolicyResolutionPending: true);
    expect(session.confirmOrder(), false);
    expect(session.notice, contains('policy'));
    expect(session.quantityFor(product.id), 1);
    expect(session.confirmedOrders, isEmpty);
    expect(session.pendingSupplierPolicyAdd, isNull);
  });
  for (final state in [BuyV2ProductContentState.ready, BuyV2ProductContentState.unavailable]) {
    test('LF05 first unresolved policy read blocks Add without inventing consent $state', () async {
      final item = handoffStock();
      final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store');
      final source = _Lf05PolicySource(BuyV2ProductContentSnapshot(productId: product.id,
        sourceId: 'host-configured-policy', state: state, observedAt: policyNow,
        supplierPolicyResolutionPending: true));
      final store = _Lf05ConsentStore(), core = BuySession();
      final session = BuyV2Session(core: core, cataloguePageSource: _Lf04Catalogue(product),
        productContentAdapter: source, customerStateStore: store, catalogueNow: () => policyNow);
      addTearDown(session.dispose); addTearDown(core.dispose);
      await session.restoreCustomerState();
      expect(await session.openLinkedProduct(product.id), true);
      expect(session.addProduct(product.id), false);
      expect(session.quantityFor(product.id), 0);
      expect(session.pendingSupplierPolicyAdd, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(store.saved?.supplierPolicyAcceptances ?? {}, isEmpty);
      expect(store.saved!.supplierPolicyUnresolvedProductKeys, isNotEmpty);
      expect(store.saved!.supplierPolicyRequiredProductKeys, isEmpty);
      source.value = BuyV2ProductContentSnapshot(productId: product.id,
        sourceId: 'host-configured-policy', state: BuyV2ProductContentState.ready);
      final restoredCore = BuySession();
      final restored = BuyV2Session(core: restoredCore, cataloguePageSource: _Lf04Catalogue(product),
        productContentAdapter: source, customerStateStore: store, catalogueNow: () => policyNow);
      addTearDown(restored.dispose); addTearDown(restoredCore.dispose);
      await restored.restoreCustomerState();
      expect(await restored.openLinkedProduct(product.id), true);
      expect(restored.addProduct(product.id), false);
      expect(restored.quantityFor(product.id), 0);
      source.value = BuyV2ProductContentSnapshot(productId: product.id,
        sourceId: 'host-configured-policy', state: BuyV2ProductContentState.ready,
        observedAt: policyNow, supplierPolicyAcceptanceRequired: false);
      expect(session.addProduct(product.id), true);
      expect(session.quantityFor(product.id), 1);
    });
  }
  BuyV2ProductContentSnapshot policyReadback(WorkspaceCatalogueItem item, {
    String store = 'a', String? productId, String source = 'host-policy-source',
    String revision = 'host-policy-v1', String body = 'Host supplier purchase terms',
    bool required = true, bool? decision, DateTime? expiry,
    BuyV2ProductContentState state = BuyV2ProductContentState.ready,
    bool omitPolicy = false,
  }) => BuyV2ProductContentSnapshot(
    productId: productId ?? item.id, sourceId: source, state: state,
    supplierPolicyAcceptanceRequired: decision ?? required,
    supplierPolicy: omitPolicy ? null : BuyV2SupplierPolicy(
      id: 'host-supplier-policy', storeId: store, revision: revision,
      title: 'Host supplier policy', body: body,
      productIds: {item.id}, requiresAcceptance: required,
      validUntil: expiry ?? policyNow.add(const Duration(hours: 1))),
  );
  test('LF05 scoped policy readback preserves Store content and rejects unsafe source', () {
    final item = handoffStock().copyWith(content: WorkspaceProductContent.parse(
      {'description': 'Host saved description'}));
    final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store');
    final source = _Lf05PolicySource(policyReadback(item));
    final adapter = WorkspacePublicContentAdapter(storeId: 'a', item: item,
      sourceId: 'host-store-content', policyReadback: source, now: () => policyNow);
    final ready = adapter.snapshotFor(product);
    expect(ready.supplierPolicy!.revision, 'host-policy-v1');
    expect(ready.supplierPolicyAcceptanceRequired, isTrue);
    expect(ready.description, 'Host saved description');
    expect(ready.sourceId, 'host-store-content');
    expect(ready.observedAt, isNull);
    for (final bad in [policyReadback(item, store: 'b'),
      policyReadback(item, productId: 'other'), policyReadback(item, source: ''),
      policyReadback(item, revision: ''), policyReadback(item, body: ''),
      policyReadback(item, expiry: policyNow), policyReadback(item, decision: false),
      policyReadback(item, omitPolicy: true),
      BuyV2ProductContentSnapshot(productId: item.id,
        state: BuyV2ProductContentState.ready, sourceId: 'host-future-policy',
        supplierPolicy: policyReadback(item).supplierPolicy,
        observedAt: policyNow.add(const Duration(minutes: 1))),
      policyReadback(item, state: BuyV2ProductContentState.offline)]) {
      source.value = bad;
      final held = adapter.snapshotFor(product);
      expect(held.state, BuyV2ProductContentState.unavailable);
      expect(held.supplierPolicy, isNull);
      expect(held.supplierPolicyAcceptanceRequired, isNull);
      expect(held.supplierPolicyResolutionPending, isTrue);
    }
    source.fail = true;
    expect(adapter.snapshotFor(product).supplierPolicyResolutionPending, isTrue);
    source.fail = false;
    source.value = policyReadback(item, required: false, omitPolicy: true);
    expect(adapter.snapshotFor(product).supplierPolicyAcceptanceRequired, isFalse);
    expect(adapter.snapshotFor(product).state, BuyV2ProductContentState.ready);
    expect(item.stock, 48);
  });
  test('LF05 required policy without a source blocks actual Add without consent bypass', () async {
    final item = handoffStock();
    final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store');
    final core = BuySession();
    final session = BuyV2Session(core: core, cataloguePageSource: _Lf04Catalogue(product),
      productContentAdapter: WorkspacePublicContentAdapter(storeId: 'a', item: item,
        sourceId: 'host-store-content', policyReadbackRequired: true));
    addTearDown(session.dispose); addTearDown(core.dispose);
    expect(await session.openLinkedProduct(product.id), isTrue);
    expect(session.addProduct(product.id), isFalse);
    expect(session.pendingSupplierPolicyAdd, isNull);
    expect(session.quantityFor(product.id), 0);
    expect(session.notice, contains('policy'));
    expect(item.stock, 48);
  });
  test('LF05 supplied policy reaches actual Buy consent and expiry preserves Cart', () async {
    final item = handoffStock();
    var now = policyNow;
    final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store');
    final source = _Lf05PolicySource(policyReadback(item));
    final store = _Lf05ConsentStore();
    final core = BuySession();
    final session = BuyV2Session(core: core, cataloguePageSource: _Lf04Catalogue(product),
      productContentAdapter: WorkspacePublicContentAdapter(storeId: 'a', item: item,
        sourceId: 'host-store-content', policyReadback: source, now: () => now),
      customerStateStore: store, catalogueNow: () => now);
    addTearDown(session.dispose); addTearDown(core.dispose);
    await session.restoreCustomerState();
    expect(await session.openLinkedProduct(product.id), isTrue);
    expect(session.addProduct(product.id), isFalse);
    final intent = session.pendingSupplierPolicyAdd!;
    expect(intent.policy.body, 'Host supplier purchase terms');
    expect(session.quantityFor(product.id), 0);
    source.value = policyReadback(item, body: 'Changed host terms');
    expect(await session.acceptSupplierPolicyAndAdd(intent), isFalse);
    expect(session.quantityFor(product.id), 0);
    expect(session.addProduct(product.id), isFalse);
    expect(await session.acceptSupplierPolicyAndAdd(session.pendingSupplierPolicyAdd), isTrue);
    expect(session.quantityFor(product.id), 1);
    expect(store.saved!.supplierPolicyAcceptances, hasLength(1));
    now = now.add(const Duration(hours: 2));
    expect(session.addProduct(product.id), isFalse);
    expect(session.quantityFor(product.id), 1);
    expect(item.stock, 48);
  });
  test('LF05 changed policy during consent save cannot add or reuse old acceptance', () async {
    final item = handoffStock();
    final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store');
    final source = _Lf05PolicySource(policyReadback(item));
    final store = _Lf05ConsentStore();
    final core = BuySession();
    final session = BuyV2Session(core: core, cataloguePageSource: _Lf04Catalogue(product),
      productContentAdapter: WorkspacePublicContentAdapter(storeId: 'a', item: item,
        sourceId: 'host-store-content', policyReadback: source, now: () => policyNow),
      customerStateStore: store, catalogueNow: () => policyNow);
    addTearDown(session.dispose); addTearDown(core.dispose);
    await session.restoreCustomerState();
    expect(await session.openLinkedProduct(product.id), isTrue);
    expect(session.addProduct(product.id), isFalse);
    store.pending = Completer<void>();
    final saving = session.acceptSupplierPolicyAndAdd(session.pendingSupplierPolicyAdd);
    source.value = policyReadback(item, body: 'New terms while saving');
    store.pending!.complete();
    expect(await saving, isFalse);
    expect(session.quantityFor(product.id), 0);
    expect(session.addProduct(product.id), isFalse);
    expect(session.pendingSupplierPolicyAdd!.policy.body, 'New terms while saving');
  });
  test('LF04 missing public wholesale terms cannot silently drop steps and tiers', () {
    final item = handoffStock();
    expect(item.wholesaleOffer!.incrementPacks, 6);
    expect(item.wholesaleOffer!.tiers, isNotEmpty);
    expect(() => item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store',
      channel: BuyV2Destination.wholesale), throwsStateError);
    expect(item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store').price, 264);
    expect(item.stock, 48);
    expect(WorkspacePublicationContract.productIssues(item, storeId: 'a', storeName: 'Host Store',
      channel: BuyV2Destination.wholesale).any((issue) => issue.field.endsWith(':packTerms')), isTrue);
  });
  test('LF04 supplied exact terms retain quantity and every tier; invalid source rejects', () {
    final item = handoffStock();
    final now = DateTime.utc(2026, 10, 15, 10);
    BuyV2PackTerms terms({String? sku, String? store, String? pack, int step = 6,
      int tierPrice = 240, int tierMinimum = 12, DateTime? end, DateTime? start}) => BuyV2PackTerms(
      skuId: sku ?? item.id, revision: 'host-contract-only', sellUnit: pack ?? item.pack,
      quantityStep: step, pricingStoreId: store ?? 'a',
      priceObservedAt: start ?? now.subtract(const Duration(hours: 1)),
      priceValidUntil: end ?? now.add(const Duration(hours: 1)),
      priceTiers: [const BuyV2PackPriceTier(minimumPacks: 6, price: 250),
        BuyV2PackPriceTier(minimumPacks: tierMinimum, price: tierPrice)],
    );
    final supplied = terms();
    final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store',
      channel: BuyV2Destination.wholesale, publicPackTerms: supplied, now: now);
    expect(product.hasValidPackTerms, isTrue);
    expect(product.id, item.id);
    expect(product.quantityStep, 6);
    expect(product.minimumOrder, 6);
    expect(product.price, 250);
    expect(product.packTerms!.priceForQuantity(12, product.price), 240);
    expect(product.unitPrice, isEmpty); // No single misleading per-L price for tiers.
    expect(WorkspacePublicationContract.productIssues(item, storeId: 'a', storeName: 'Host Store',
      channel: BuyV2Destination.wholesale, publicPackTerms: supplied, now: now), isEmpty);
    for (final invalid in [terms(sku: 'other'), terms(store: 'other'), terms(pack: '5 L pouch'),
      terms(step: 1), terms(tierPrice: 239), terms(tierMinimum: 13),
      terms(end: now), terms(start: now.add(const Duration(minutes: 1)))]) {
      expect(() => item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store',
        channel: BuyV2Destination.wholesale, publicPackTerms: invalid, now: now), throwsStateError);
    }
    expect(item.toInventoryJson(), handoffStock().toInventoryJson());
  });
  test('LF04 Store terms drive actual Buy Cart MOQ increments and tier totals', () async {
    final item = handoffStock();
    final now = DateTime.utc(2026, 10, 15, 10);
    final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store',
      channel: BuyV2Destination.wholesale, now: now, publicPackTerms: BuyV2PackTerms(
        skuId: item.id, revision: 'host-contract-only', sellUnit: item.pack, quantityStep: 6,
        pricingStoreId: 'a', priceObservedAt: now.subtract(const Duration(hours: 1)),
        priceValidUntil: now.add(const Duration(hours: 1)), priceTiers: const [
          BuyV2PackPriceTier(minimumPacks: 6, price: 250),
          BuyV2PackPriceTier(minimumPacks: 12, price: 240),
        ],
      ));
    final core = BuySession();
    final session = BuyV2Session(core: core, cataloguePageSource: _Lf04Catalogue(product),
      catalogueNow: () => now)..businessVerified = true;
    addTearDown(session.dispose); addTearDown(core.dispose);
    expect(await session.openLinkedProduct(product.id), isTrue);
    expect(session.addProduct(product.id), isTrue);
    expect(session.quantityFor(product.id), 6);
    expect(session.cartLines.single.total, 1500);
    expect(session.setCartQuantity(product.id, '7'), isFalse);
    expect(session.quantityFor(product.id), 6);
    session.increase(product.id);
    expect(session.quantityFor(product.id), 12);
    expect(session.cartLines.single.product.price, 240);
    expect(session.cartLines.single.total, 2880);
    session.decrease(product.id);
    expect(session.quantityFor(product.id), 6);
    expect(session.cartLines.single.total, 1500);
    expect(item.stock, 48);
  });
  test('LF04 MOQ offset and expiry preserve an existing Cart without rewriting Stock', () async {
    final item = handoffStock().copyWith(wholesaleOffer: WorkspaceWholesaleOffer.fromJson({
      'enabled': true, 'saleType': 'bulk', 'priceRupees': 250,
      'minimumPacks': 3, 'incrementPacks': 2,
      'tiers': [{'minimumPacks': 7, 'packPriceMinor': 24000}],
    }));
    var now = DateTime.utc(2026, 10, 15, 10);
    final product = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store',
      channel: BuyV2Destination.wholesale, now: now,
      publicPackTerms: handoffSellingTerms(item, 'a', now: now));
    final core = BuySession();
    final session = BuyV2Session(core: core, cataloguePageSource: _Lf04Catalogue(product),
      catalogueNow: () => now)..businessVerified = true;
    addTearDown(session.dispose); addTearDown(core.dispose);
    expect(await session.openLinkedProduct(product.id), isTrue);
    expect(session.addProduct(product.id), isTrue);
    expect(session.quantityFor(product.id), 3);
    session.increase(product.id);
    expect(session.quantityFor(product.id), 5);
    expect(session.setCartQuantity(product.id, '6'), isFalse);
    expect(session.setCartQuantity(product.id, '7'), isTrue);
    expect(session.cartLines.single.total, 1680);
    now = now.add(const Duration(hours: 2));
    expect(session.setCartQuantity(product.id, '9'), isFalse);
    expect(session.addProduct(product.id), isFalse);
    expect(session.quantityFor(product.id), 7);
    expect(item.stock, 48);
    expect(session.productFactsFor(product).stale, isTrue);
  });
  test('LF03 explicit retail wholesale and bulk class reaches public product', () {
    final base = handoffStock();
    for (final sale in [BuyV2WholesaleSaleType.wholesale, BuyV2WholesaleSaleType.bulk]) {
      final item = base.copyWith(wholesaleOffer: WorkspaceWholesaleOffer.fromJson({
        ...base.wholesaleOffer!.toJson(), 'saleType': sale.name,
      }));
      for (final channel in [BuyV2Destination.shop, BuyV2Destination.wholesale]) {
        final expected = channel == BuyV2Destination.shop ? BuyV2OfferClass.retail
            : sale == BuyV2WholesaleSaleType.bulk ? BuyV2OfferClass.bulk : BuyV2OfferClass.wholesale;
        final terms = channel == BuyV2Destination.wholesale ? handoffSellingTerms(item, 'a') : null;
        final public = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store', channel: channel, publicPackTerms: terms);
        expect(public.offerClass, expected);
        expect(public.id, item.id);
        expect(public.pack, item.pack);
        expect(public.price, channel == BuyV2Destination.shop ? item.sellingPrice : item.wholesaleOffer!.priceRupees);
        expect(public.reviewDeliveryOptions, isEmpty);
        expect(public.packTerms, terms); // Explicit host contract, never runtime data.
        expect(WorkspacePublicationContract.productIssues(item, storeId: 'a', storeName: 'Host Store', channel: channel, publicPackTerms: terms), isEmpty);
      }
    }
    final legacy = base.copyWith(wholesaleOffer: WorkspaceWholesaleOffer.fromJson({
      ...base.wholesaleOffer!.toJson(), 'saleType': null,
    }));
    final publicLegacy = legacy.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store', channel: BuyV2Destination.wholesale,
      publicPackTerms: handoffSellingTerms(legacy, 'a'));
    expect(publicLegacy.offerClass, isNull);
    expect(publicLegacy.catalogueListing, isFalse);
    expect(legacy.stock, base.stock);
  });
  test('LF03 complete inventory round trip preserves pack content photo and prices', () {
    final initial = handoffStock();
    final item = initial.copyWith(compliance: WorkspaceProductCompliance.fromJson({
      ...initial.compliance!.toJson(), 'manufacturerAddress': 'Host maker address',
      'packerAddress': 'Host packer address', 'importerAddress': 'Host importer address',
    }));
    final restored = WorkspaceCatalogueItem.fromInventoryJson(jsonDecode(jsonEncode(item.toInventoryJson())));
    expect(restored.toInventoryJson(), item.toInventoryJson());
    expect(restored.cataloguePhoto!.revision, item.cataloguePhoto!.revision);
    expect(restored.content.toJson(), item.content.toJson());
    expect(restored.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store').compliance!.manufacturerAddress, 'Host maker address');
    final oldProduct = item.toBuyPublicProduct(storeId: 'a', storeName: 'Host Store');
    final newer = handoffStock(revision: 'new-approved-image');
    final current = WorkspacePublicContentAdapter(storeId: 'a', item: newer, sourceId: 'host-current-content').snapshotFor(oldProduct);
    expect(current.state, BuyV2ProductContentState.ready);
    expect(current.media.single.binding!.assetRevision, 'new-approved-image');
    expect(current.media.single.binding!.storeId, 'a');
    expect(current.media.single.binding!.skuId, item.id);
    final sibling = WorkspacePublicContentAdapter(storeId: 'a', item: handoffStock(litres: 5), sourceId: 'host-other-pack').snapshotFor(oldProduct);
    expect(sibling.state, BuyV2ProductContentState.unavailable);
    expect(sibling.media, isEmpty);
  });
  const packAddresses = {
    'manufacturerAddress': 'Host fixture maker, Plot 1, Jaipur',
    'packerAddress': 'Host fixture packer, Plot 2, Delhi',
    'importerAddress': 'Host fixture importer, Plot 3, Mumbai',
  };
  test('LF03 pack addresses round trip and project without Store defaults', () {
    final original = handoffStock();
    final saved = WorkspaceProductCompliance.fromJson({
      ...original.compliance!.toJson(), ...packAddresses,
    })!;
    final item = original.copyWith(compliance: saved);
    expect(WorkspaceProductCompliance.fromJson(jsonDecode(jsonEncode(saved.toJson())))!.toJson(), saved.toJson());
    final public = item.toBuyPublicProduct(storeName: 'Selling Store', storeId: 'a');
    for (final field in packAddresses.keys) {
      expect(saved.toJson()[field], packAddresses[field]);
      expect(WorkspaceProductImport.templateLabels, contains(field));
    }
    expect(public.compliance!.manufacturerAddress, packAddresses['manufacturerAddress']);
    expect(public.compliance!.packerAddress, packAddresses['packerAddress']);
    expect(public.compliance!.importerAddress, packAddresses['importerAddress']);
    expect(WorkspacePublicationContract.productIssues(item, storeId: 'a', storeName: 'Selling Store'), isEmpty);
    expect(public.id, original.id);
    expect(public.mediaAssets.single.source, original.toBuyPublicProduct(storeName: '', storeId: 'a').mediaAssets.single.source);
    final cleared = WorkspaceProductCompliance.fromJson({...saved.toJson(), 'manufacturerAddress': '  '})!;
    expect(cleared.toJson(), isNot(contains('manufacturerAddress')));
    final clearedReload = WorkspaceProductCompliance.fromJson(jsonDecode(jsonEncode(cleared.toJson())))!;
    expect(original.copyWith(compliance: clearedReload).toBuyPublicProduct(storeName: 'Selling Store', storeId: 'a').compliance!.manufacturerAddress, isNull);
    expect(cleared.toJson()['packerAddress'], packAddresses['packerAddress']);
    // Historic v1 is intentionally not the transport for these newer fields.
    for (final field in packAddresses.keys) {
      expect(WorkspacePublicationContract.sourceProductValues(item, storeId: 'a', storeName: 'Selling Store'), isNot(contains('compliance.$field')));
      expect(WorkspacePublicationContract.publicProductValues(public), isNot(contains('compliance.$field')));
      expect(WorkspacePublicationContract.publicProductAuditValues(public)['compliance.$field'], packAddresses[field]);
    }
    for (final field in packAddresses.keys) {
      expect(original.compliance!.toJson(), isNot(contains(field)));
    }
    expect(() => WorkspaceProductCompliance.fromJson({'manufacturerAddress': 42}), throwsFormatException);
  });
  test('LF03 CSV prefills pack addresses and accepts explicit matching overrides', () {
    final base = workspaceMasterCatalogue.first;
    final catalogue = base.copyWith(compliance: WorkspaceProductCompliance.fromJson({
      ...?base.compliance?.toJson(), ...packAddresses,
    }));
    WorkspaceProductImport decode(Map<String, String> extras, {bool match = true}) {
      final row = <String, String>{
        'title': base.title, 'brand': base.brand, 'pack': base.pack,
        'variant': base.variant, 'barcode': base.barcode,
        'purchasePrice': '200', 'sellingPrice': '264', 'stock': '4',
        ...extras,
      };
      String cell(String s) => '"${s.replaceAll('"', '""')}"';
      return WorkspaceProductImport.parse('${row.keys.join(',')}\n${row.values.map(cell).join(',')}',
        catalogue: match ? [catalogue] : const [], owned: const []);
    }
    final inherited = decode({}).rows.single;
    expect(inherited.issue, isNull);
    expect(inherited.product!.compliance!.toJson()['manufacturerAddress'], packAddresses['manufacturerAddress']);
    final override = decode({'manufacturerAddress': 'Updated fixture maker, Plot 9'}).rows.single;
    expect(override.issue, isNull);
    expect(override.product!.compliance!.toJson()['manufacturerAddress'], 'Updated fixture maker, Plot 9');
    expect(override.product!.compliance!.toJson()['packerAddress'], packAddresses['packerAddress']);
    expect(override.product!.catalogueFactsRequireReview, isTrue);
    final manual = decode(packAddresses, match: false).rows.single;
    expect(manual.issue, isNull);
    expect(manual.product!.compliance!.toJson()['importerAddress'], packAddresses['importerAddress']);
    expect(() => decode({'manufacturerAddress': 'x' * 4001}), throwsFormatException);
  });
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
          publicPackTerms: channel == BuyV2Destination.wholesale ? handoffSellingTerms(item, 'a') : null,
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
    'CONTENT compatibility keeps provider facts and policy decisions unknown',
    () {
      final item = handoffStock().copyWith(content: content);
      final original = item.content.toJson();
      final adapter = WorkspacePublicContentAdapter(
        storeId: 'a',
        item: item,
        sourceId: 'labelled-host-content-fixture',
      );
      for (final channel in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final product = item.toBuyPublicProduct(
          storeName: 'Store',
          storeId: 'a',
          channel: channel,
          publicPackTerms: channel == BuyV2Destination.wholesale ? handoffSellingTerms(item, 'a') : null,
        );
        final ready = adapter.snapshotFor(product);
        final unavailable = adapter.snapshotFor(product.copyWith(storeId: 'b'));
        expect(ready.state, BuyV2ProductContentState.ready);
        expect(ready.highlights, content.highlights);
        expect(ready.description, content.description);
        expect(unavailable.state, BuyV2ProductContentState.unavailable);
        for (final snapshot in [ready, unavailable]) {
          expect(snapshot.highlightFields, isEmpty);
          expect(snapshot.categoryFacts, isNull);
          expect(snapshot.sizeChart, isNull);
          expect(snapshot.priceHistory, isNull);
          expect(snapshot.supplierPolicy, isNull);
          expect(snapshot.supplierPolicyAcceptanceRequired, isNull);
          expect(snapshot.retryable, isFalse);
          expect(snapshot.observedAt, isNull);
          expect(snapshot.sourceId, 'labelled-host-content-fixture');
        }
      }
      expect(item.content.toJson(), original);
      for (final field in [
        'highlightFields',
        'categoryFacts',
        'sizeChart',
        'priceHistory',
        'supplierPolicy',
        'supplierPolicyAcceptanceRequired',
        'retryable',
      ]) {
        expect(WorkspacePublicationContract.contentBindings[field], isNotEmpty);
      }
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
