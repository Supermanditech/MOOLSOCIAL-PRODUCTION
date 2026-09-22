import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

// Approved is simulated ONLY to exercise the local contract. No asset is uploaded.
WorkspaceCatalogueItem fixture({String revision = 'r1'}) {
  final p = workspaceMasterCatalogue.first;
  return p.copyWith(
    publicListing: true,
    available: true,
    stock: 8,
    cataloguePhoto: WorkspaceCataloguePhoto(
      assetId: 'fixture-oil',
      revision: revision,
      source: 'https://example.invalid/$revision/oil.png',
      publisherWorkspaceId: 'fixture-catalogue',
      canonicalId: p.canonicalId,
      brand: p.brand,
      variant: p.variant,
      pack: p.pack,
      barcode: p.barcode,
      status: WorkspaceCataloguePhotoStatus.approved,
      file: const BuyV2MediaFileMetadata(
        mimeType: 'image/png',
        byteLength: 8192,
        width: 1024,
        height: 1024,
        normalized: true,
        frameCount: 1,
      ),
    ),
    compliance: const WorkspaceProductCompliance(
      genericName: 'Oil',
      netQuantity: '1 L',
      manufacturerName: 'Fixture maker',
      packerName: 'Fixture packer',
      importerName: 'Not applicable',
      countryOfOrigin: 'India',
      manufacturedOrPackedOn: '2026-09-01',
      bestBeforeOrUseBy: '2027-03-01',
      fssaiLicenseNumber: '12345678901234',
      consumerCare: 'care@example.invalid',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'DEFAULTS Store scoped preferences do not mutate existing stock or publish',
    () async {
      const a = WorkWorkspace(
        id: 'a',
        name: 'A',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
      const b = WorkWorkspace(
        id: 'b',
        name: 'B',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Delhi',
        verified: true,
      );
      final gateway = ReviewWorkGateway();
      final work = WorkSession(gateway: gateway)..activeWorkspace = a;
      addTearDown(work.dispose);
      final original = fixture().copyWith(publicListing: false);
      work.workspaceCatalogueItems.add(original);
      const defaults = WorkspaceProductDefaults(
        stockMode: WorkspaceStockMode.availabilityOnly,
        lowStockThreshold: 12,
        customerListingRequested: true,
      );
      expect(work.saveWorkspaceProductDefaults(defaults), isTrue);
      expect(work.workspaceCatalogueItems.single, same(original));
      expect(work.workspaceVisibleToCustomers, isFalse);
      final draft = defaults.applyToNew(workspaceMasterCatalogue.first);
      expect(draft.stockMode, WorkspaceStockMode.availabilityOnly);
      expect(draft.lowStockThreshold, 12);
      expect(draft.publicListing, isTrue); // Intent only; not published.
      work.activeWorkspace = b;
      expect(work.workspaceProductDefaults.lowStockThreshold, 5);
      expect(work.workspaceProductDefaults.customerListingRequested, isFalse);
      work.activeWorkspace = a;
      expect(work.workspaceProductDefaults.lowStockThreshold, 12);
      expect(
        work.saveWorkspaceProductDefaults(
          const WorkspaceProductDefaults(lowStockThreshold: -1),
        ),
        isFalse,
      );
      expect(work.workspaceProductDefaults.lowStockThreshold, 12);
      await Future<void>.delayed(Duration.zero);
      expect(
        gateway.lastOperationalSnapshot!.state['productDefaults'],
        defaults.toJson(),
      );
    },
  );

  test(
    'DEFAULTS CSV inherits omitted values, honours overrides and stays private',
    () {
      const defaults = WorkspaceProductDefaults(
        stockMode: WorkspaceStockMode.availabilityOnly,
        lowStockThreshold: 12,
        customerListingRequested: true,
      );
      WorkspaceProductImport parse(
        String suffix,
        String values,
      ) => WorkspaceProductImport.parse(
        'title,brand,pack,purchasePrice,sellingPrice,stock$suffix\nTest product,Test brand,1 kg,40,50,8$values',
        catalogue: [],
        owned: [],
        defaults: defaults,
      );
      final inherited = parse('', '').rows.single.product!;
      expect(inherited.stockMode, WorkspaceStockMode.availabilityOnly);
      expect(inherited.lowStockThreshold, 12);
      expect(inherited.publicListing, isFalse);
      final override = parse(
        ',stockMode,lowStockThreshold',
        ',exactQuantity,2',
      ).rows.single.product!;
      expect(override.stockMode, WorkspaceStockMode.exactQuantity);
      expect(override.lowStockThreshold, 2);
      expect(override.publicListing, isFalse);
      expect(parse(',stockMode', ',mistyped').rows.single.issue, isNotNull);
    },
  );
  const store = WorkWorkspace(
    id: 'store-a',
    name: 'Fixture Store',
    profileId: 'retailer-grocery',
    profileLabel: 'Grocery',
    area: 'Jaipur',
    verified: true,
  );

  List<WorkspacePublicationIssue> audit(
    WorkspaceCatalogueItem p, {
    BuyV2Product? target,
  }) => WorkspacePublicationContract.productIssues(
    p,
    storeId: store.id,
    storeName: store.name,
    projected: target,
  );

  test(
    'PUB every stored Buy product and Store field has an explicit disposition',
    () {
      Set<String> fields(String path, String name) {
        final text = File(path).readAsStringSync();
        final body = text.split('class $name {')[1].split('\nclass ')[0];
        return RegExp(
          r'^  final [^\r\n;=]+? (\w+);',
          multiLine: true,
        ).allMatches(body).map((m) => m[1]!).toSet();
      }

      expect(
        WorkspacePublicationContract.productBindings.keys.toSet(),
        fields('lib/features/buy/buy_v2_models.dart', 'BuyV2Product'),
      );
      expect(
        WorkspacePublicationContract.storeBindings.keys.toSet(),
        fields(
          'lib/features/buy/buy_v2_content_contracts.dart',
          'BuyV2StoreListing',
        ),
      );
    },
  );

  test(
    'PUB exact public product fields and all pack facts match in both directions',
    () {
      final p = fixture();
      final public = p.toBuyPublicProduct(
        storeId: store.id,
        storeName: store.name,
      );
      expect(audit(p), isEmpty);
      expect(
        WorkspacePublicationContract.publicProductValues(public),
        WorkspacePublicationContract.sourceProductValues(
          p,
          storeId: store.id,
          storeName: store.name,
        ),
      );
      expect(public.compliance!.netQuantity, '1 L');
      expect(public.mediaAssets.single.binding!.skuId, p.id);
      expect(public.mediaAssets.single.binding!.productId, p.canonicalId);
      expect(public.mediaAssets.single.binding!.storeId, store.id);
      expect(public.catalogueListing, isTrue);
    },
  );

  test(
    'PUB changed Store variant price and public-only pack facts are rejected',
    () {
      final p = fixture();
      final public = p.toBuyPublicProduct(
        storeId: store.id,
        storeName: store.name,
      );
      for (final changed in [
        public.copyWith(storeId: 'other-store'),
        public.copyWith(price: public.price + 1),
        public.copyWith(pack: '5 L'),
        public.copyWith(variant: 'Other variant'),
        public.copyWith(
          compliance: const BuyV2ProductCompliance(netQuantity: '5 L'),
        ),
      ]) {
        expect(audit(p, target: changed), isNotEmpty);
      }
      final bare = workspaceMasterCatalogue.first;
      final extra = bare
          .toBuyPublicProduct(storeId: store.id, storeName: store.name)
          .copyWith(
            compliance: const BuyV2ProductCompliance(
              importerName: 'Unowned value',
            ),
          );
      expect(
        audit(
          bare,
          target: extra,
        ).any((i) => i.field.endsWith('compliance.importerName')),
        isTrue,
      );
    },
  );

  test(
    'PUB photo revision is shared exactly and replacement cannot reuse old image',
    () {
      final p = fixture();
      final newer = fixture(revision: 'r2');
      expect(audit(newer), isEmpty);
      expect(
        audit(
          newer,
          target: p.toBuyPublicProduct(
            storeId: store.id,
            storeName: store.name,
          ),
        ).any((i) => i.field.endsWith('photo.mapping')),
        isTrue,
      );
      expect(
        audit(p.copyWith(pack: '5 L')).any((i) => i.field.endsWith('photo')),
        isTrue,
      );
    },
  );

  test(
    'PUB private stock and incomplete records never become customer listings',
    () {
      final p = fixture();
      expect(
        p
            .copyWith(publicListing: false)
            .toBuyPublicProduct(storeId: store.id, storeName: store.name)
            .catalogueListing,
        isFalse,
      );
      for (final bad in [
        workspaceMasterCatalogue.first,
        p.copyWith(title: ''),
        p.copyWith(sellingPrice: 0),
        p.copyWith(mrp: 1),
        p.copyWith(catalogueFactsRequireReview: true),
      ]) {
        expect(audit(bad), isNotEmpty);
        expect(bad.published, isFalse);
      }
      final private = p.copyWith(publicListing: false);
      expect(private.canSellAtCounter, isTrue);
    },
  );

  test(
    'PUB private cost and settlement values are not product publication fields',
    () {
      final map = WorkspacePublicationContract.sourceProductValues(
        fixture(),
        storeId: store.id,
        storeName: store.name,
      );
      expect(map.keys, isNot(contains('purchasePrice')));
      expect(map.keys, isNot(contains('bankAccount')));
      expect(map.keys, isNot(contains('stock')));
    },
  );

  test('PUB retail projection cannot invent wholesale eligibility', () {
    expect(
      WorkspacePublicationContract.productIssues(
        fixture(),
        storeId: store.id,
        storeName: store.name,
        channel: BuyV2Destination.wholesale,
      ).any((i) => i.field.endsWith('channel')),
      isTrue,
    );
  });

  test(
    'PUB missing frontend mappings and backend acknowledgement stay explicit',
    () {
      final report = WorkspacePublicationContract.inspect(
        store: store,
        products: [fixture()],
      );
      expect(report.ready, isFalse);
      expect(
        report.issues.map((i) => i.field),
        containsAll([
          'store.address',
          'store.terms',
          'product.quantity',
          'publication.confirmation',
        ]),
      );
      final incomplete = WorkspacePublicationContract.inspect(
        store: store,
        products: [
          fixture(),
          workspaceMasterCatalogue[1].copyWith(publicListing: true, title: ''),
        ],
      );
      expect(
        incomplete.issues.any(
          (i) => i.field == '${workspaceMasterCatalogue[1].id}:title',
        ),
        isTrue,
      );
    },
  );

  test(
    'PUB visibility cannot bypass requirements and private stock stays usable',
    () async {
      final work = WorkSession(gateway: ReviewWorkGateway())
        ..activeWorkspace = store;
      addTearDown(work.dispose);
      work.workspaceCatalogueItems.add(fixture());
      expect(work.setWorkspaceVisibility(true), isFalse);
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.errorMessage, contains('not published'));
      expect(work.workspaceCatalogueItems.single.canSellAtCounter, isTrue);
      expect(work.setWorkspaceVisibility(false), isTrue);
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'PUB existing discovery query identity separates Store region and channel',
    () {
      BuyV2CatalogueQuery query({
        String? storeId,
        String region = 'jaipur',
        BuyV2Destination channel = BuyV2Destination.shop,
      }) => BuyV2CatalogueQuery(
        destination: channel,
        regionId: region,
        storeId: storeId,
      );
      final queries = [
        query(),
        query(storeId: store.id),
        query(storeId: 'store-b'),
        query(region: 'delhi'),
        query(channel: BuyV2Destination.wholesale),
      ];
      expect(queries.map((q) => q.key).toSet(), hasLength(5));
      final page = BuyV2CataloguePage<BuyV2Product>(
        queryKey: queries[1].key,
        snapshotId: 'fixture',
        items: [
          fixture().toBuyPublicProduct(
            storeId: store.id,
            storeName: store.name,
          ),
        ],
        startIndex: 0,
        nextCursor: 'next',
      );
      expect(page.queryKey, isNot(queries[0].key));
      expect(page.items.single.storeId, store.id);
      expect(page.nextCursor, 'next');
    },
  );
}
