// Test-only Store-origin inputs. Never import this file into lib/ or a release.
import 'dart:convert';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';

final handoffTime = DateTime.utc(2026, 9, 22, 9);

WorkspaceStorePublicationDetails handoffStoreDetails() =>
    const WorkspaceStorePublicationDetails(
      street: '1 Test Lane',
      city: 'Jaipur',
      state: 'Rajasthan',
      pinCode: '302001',
      legalName: 'Fixture Retailer',
      retailPaymentMethods: {'PhonePe', 'Cash on Delivery'},
      wholesalePaymentMethods: {'Bank transfer'},
      returnSummary: 'Wrong or damaged item: request review with invoice.',
      dispatchDays: 2,
      shoppingArea: BuyV2ShoppingArea(
        regionId: 'fixture-region-jaipur',
        googlePlaceId: 'fixture-place-not-a-real-google-place',
        label: 'Jaipur',
        countryCode: 'IN',
        postalCode: '302001',
      ),
    );

WorkspaceCatalogueItem handoffStock({
  String store = 'a',
  int litres = 1,
  bool private = false,
  int stock = 48,
  bool retail = true,
  String revision = 'fixture-r1',
}) {
  final pack = '$litres L pouch';
  final id = 'fixture-$store-oil-$litres';
  return WorkspaceCatalogueItem(
    id: id,
    canonicalId: 'fixture-sunflower-oil',
    categoryId: 'grocery',
    brand: 'Fixture brand',
    title: 'Sunflower oil',
    variant: 'Refined',
    pack: pack,
    sku: id,
    content: WorkspaceProductContent(
      description: 'Fixture product description for exact pack $pack.',
      highlights: const ['Fixture highlight'],
      specifications: {'Pack': pack, 'Fixture variant': 'Refined'},
    ),
    barcode: '',
    purchasePrice: 190 * litres,
    sellingPrice: (store == 'a' ? 264 : 260) * litres,
    unitPrice: '',
    stock: stock,
    available: stock > 0,
    mrp: 300 * litres,
    publicListing: !private,
    deliveryPromise: 'Delivery subject to location confirmation',
    origin: 'India',
    visualLabel: 'Fixture sunflower oil, $pack',
    visualKind: 'catalogue-packshot',
    retailEnabled: retail,
    packMeasure: WorkspacePackMeasure(
      unit: BuyV2ComparisonUnit.litre,
      quantityMilli: litres * 1000,
    ),
    wholesaleOffer: WorkspaceWholesaleOffer(
      saleType: BuyV2WholesaleSaleType.wholesale,
      priceRupees: 250 * litres,
      minimumPacks: 6,
      incrementPacks: 6,
      enabled: true,
      tiers: [
        BuyV2ComparisonPriceTier(
          minimumPacks: 12,
          packPriceMinor: 24000 * litres,
        ),
      ],
    ),
    compliance: WorkspaceProductCompliance(
      genericName: 'Sunflower oil',
      netQuantity: '$litres L',
      manufacturerName: 'Fixture maker',
      packerName: 'Fixture packer',
      countryOfOrigin: 'India',
      consumerCare: 'care@example.invalid',
    ),
    cataloguePhoto: WorkspaceCataloguePhoto(
      assetId: 'fixture-oil-$litres',
      revision: revision,
      source: 'https://example.invalid/$revision/oil-$litres.png',
      publisherWorkspaceId: 'fixture-catalogue',
      canonicalId: 'fixture-sunflower-oil',
      brand: 'Fixture brand',
      variant: 'Refined',
      pack: pack,
      barcode: '',
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
  );
}

Map<String, Object?> handoffPublicProduct(BuyV2Product product) {
  final values = WorkspacePublicationContract.publicProductValues(product);
  final packFacts = <String, Object?>{};
  for (final key
      in values.keys.where((key) => key.startsWith('compliance.')).toList()) {
    packFacts[key.substring('compliance.'.length)] = values.remove(key);
  }
  return {
    ...values,
    'destination': product.destination.name,
    'compliance': product.compliance == null ? null : packFacts,
    'merchandisingLabel': product.merchandisingLabel,
    'procurementSupplierGrant':
        null, // Requires an authoritative supplier grant.
    'badge': product.badge, 'confirmedOn': product.confirmedOn,
    'purchaseProtection': product.purchaseProtection == null
        ? null
        : jsonDecode(
            WorkspacePublicationContract.protectionValues(
              product.purchaseProtection,
            )!,
          ),
    'freightIncluded': product.freightIncluded,
    'manufacturerVerified': product.manufacturerVerified,
    'catalogueListing': product.catalogueListing,
    'mediaAssets': [
      for (final asset in product.mediaAssets)
        {
          'id': asset.id,
          'label': asset.label,
          'semanticLabel': asset.semanticLabel,
          'kind': asset.kind.name,
          'source': asset.source,
          'posterSource': asset.posterSource,
          'transcript': asset.transcript,
          if (asset.binding case final b?)
            'binding': {
              'supplierWorkspaceId': b.supplierWorkspaceId,
              'storeId': b.storeId,
              'productId': b.productId,
              'skuId': b.skuId,
              'assetRevision': b.assetRevision,
              'file': {
                'mimeType': b.file.mimeType,
                'byteLength': b.file.byteLength,
                'width': b.file.width,
                'height': b.file.height,
                'normalized': b.file.normalized,
                'frameCount': b.file.frameCount,
                'duration': null,
                'frameRate': null,
                'videoCodec': null,
                'videoProfile': null,
                'audioCodec': null,
              },
              'posterFile': null,
            },
        },
    ],
  };
}

Map<String, Object?> handoffPublicContent(
  WorkspaceCatalogueItem item,
  String storeId,
) {
  final content = item.toBuyPublicContent(
    storeId: storeId,
    sourceId: 'fixture-content-r1',
  );
  return {
    'storeId': storeId,
    'productId': content.productId,
    'sourceId': content.sourceId,
    'state': content.state.name,
    'description': content.description,
    'highlights': content.highlights,
    'specifications': [
      for (final s in content.specifications)
        {'label': s.label, 'value': s.value},
    ],
  };
}

/// JSON is a review/test handoff, NOT the future production API schema.
Map<String, Object?> storePublicHandoffV1() => {
  'schema': 'store-public-test-handoff/v1',
  'testOnly': true,
  'publicationConfirmed': false,
  'generatedFrom': 'WorkspaceCatalogueItem.toBuyPublicProduct',
  'money': {
    'product': 'whole INR rupees',
    'comparisonTiers': 'INR minor units',
  },
  'quantity': 'One selling pack; structured base quantity uses thousandths',
  'providerOwnedButNotPublic': [
    'purchasePrice',
    'lowStockThreshold',
    'settlementBankAccount',
  ],
  'stores': [
    for (final id in ['a', 'b'])
      {
        'id': 'fixture-store-$id',
        'name': 'Same display name',
        'providerDetails': handoffStoreDetails().toJson(),
        'pickupRequested': id == 'a',
        'publicationConfirmed': false,
      },
  ],
  'cases': [
    for (final c in <(String, WorkspaceCatalogueItem, String)>[
      ('retail-and-wholesale', handoffStock(), 'fixture-store-a'),
      ('different-pack', handoffStock(litres: 5), 'fixture-store-a'),
      ('same-name-other-store', handoffStock(store: 'b'), 'fixture-store-b'),
      ('private-stock', handoffStock(private: true), 'fixture-store-a'),
      ('out-of-stock', handoffStock(stock: 0), 'fixture-store-a'),
      ('wholesale-only', handoffStock(retail: false), 'fixture-store-a'),
      (
        'photo-replaced',
        handoffStock(revision: 'fixture-r2'),
        'fixture-store-a',
      ),
      (
        'photo-missing',
        handoffStock().copyWith(clearCataloguePhoto: true),
        'fixture-store-a',
      ),
    ])
      {
        'caseId': c.$1,
        'publicContent': handoffPublicContent(c.$2, c.$3),
        'storeStock': {
          'storeId': c.$3,
          'skuId': c.$2.id,
          'canonicalId': c.$2.canonicalId,
          'sku': c.$2.sku,
          'variant': c.$2.variant,
          'pack': c.$2.pack,
          'stock': c.$2.stock,
          'available': c.$2.available,
          'requestedPublicListing': c.$2.publicListing,
          'retailEnabled': c.$2.retailEnabled,
          'packMeasure': c.$2.packMeasure?.toJson(),
          'wholesaleOffer': c.$2.wholesaleOffer?.toJson(),
        },
        'projections': [
          for (final channel in [
            BuyV2Destination.shop,
            BuyV2Destination.wholesale,
          ])
            handoffPublicProduct(
              c.$2.toBuyPublicProduct(
                storeName: 'Same display name',
                storeId: c.$3,
                channel: channel,
                storeDetails: handoffStoreDetails(),
              ),
            ),
        ],
        'counterOrderable': c.$2.canSellAtCounter,
        'publicOrderable':
            false, // No backend publication/quote acknowledgement.
      },
  ],
  'pendingRuntimeContracts': [
    'Resolved region/location-source wiring and public Store publication readback',
    'Authoritative per-customer payment terms and public policy/content delivery',
    'Supplier grant, publication acknowledgement, discovery index and ranking',
    'Fleet serviceability, fees, expiry/freshness and final checkout quote',
    'Atomic stock reservation, payment confirmation, invoice, dispatch and tracking',
    'Authoritative restore and cross-device synchronization',
  ],
};
