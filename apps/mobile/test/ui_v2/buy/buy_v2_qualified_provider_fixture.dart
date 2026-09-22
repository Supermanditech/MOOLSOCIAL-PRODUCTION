import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';

/// Simulated provider grants for named test SKUs only. These are not live
/// eligibility and do not enable the session's unrelated review-data shortcuts.
class QualifiedTestProductFacts implements BuyV2ProductFactsAdapter {
  const QualifiedTestProductFacts(this.productIds);
  final Set<String> productIds;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final facts = const BuyV2CatalogueProductFactsAdapter().snapshotFor(
      product,
    );
    if (!productIds.contains(product.id)) return facts;
    final now = DateTime.now();
    return facts.copyWith(
      eligibility: BuyV2OfferEligibility(
        productId: product.id,
        storeId: product.storeId!,
        sourceRevision: 'simulated-test-provider-v1',
        customerLocationKey: '||0',
        observedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now.add(const Duration(hours: 1)),
        offerClass: product.offerClass!,
        channelEnabled: true,
        storeReady: true,
        fleetAvailable: false,
        customerLocationConfirmed: true,
        options: const {BuyV2DeliveryOption.courier},
      ),
    );
  }
}

/// Deterministic substitute for the deferred Google location provider.
class TestCurrentLocationSource implements BuyV2ShoppingAreaSource {
  TestCurrentLocationSource(String region, String label)
    : area = BuyV2ShoppingArea(
        regionId: region,
        googlePlaceId: 'test-place-$region',
        label: label,
        countryCode: 'IN',
      );
  BuyV2ShoppingArea area;

  @override
  Future<BuyV2ShoppingArea?> locate() async => area;
  @override
  Future<BuyV2ShoppingArea?> resolve(String id) async =>
      id == area.googlePlaceId ? area : null;
  @override
  Future<List<BuyV2ShoppingArea>> search(String query) async =>
      throw StateError('The approved popup must request current location.');
}
