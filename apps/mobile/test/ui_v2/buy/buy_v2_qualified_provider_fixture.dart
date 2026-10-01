import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
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

/// Active campaigns for positive behavior tests only. Native review campaign
/// dates and live provider eligibility are never changed by this fixture.
class ActiveTestCartBenefits extends BuyV2SeededCartBenefitsAdapter {
  const ActiveTestCartBenefits();

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) => [
    for (final benefit in super.benefitsFor(
      kind: kind,
      destinations: destinations,
      itemTotal: itemTotal,
    ))
      BuyV2CartBenefit(
        id: benefit.id,
        kind: benefit.kind,
        destination: benefit.destination,
        title: benefit.title,
        detail: benefit.detail,
        sourceId: benefit.sourceId,
        strategy: benefit.strategy,
        sponsor: benefit.sponsor,
        sponsorName: benefit.sponsorName,
        savingAmount: benefit.savingAmount,
        validFrom: benefit.validFrom,
        validUntil: DateTime.now().add(const Duration(days: 1)),
        freeDelivery: benefit.freeDelivery,
        offerId: benefit.offerId,
        minimumSpend: benefit.minimumSpend,
        minimumQuantity: benefit.minimumQuantity,
        eligiblePaymentMethods: {
          for (final method in benefit.eligiblePaymentMethods)
            switch (method) {
              'PhonePe' => 'UPI',
              'Paytm' || 'Pine Labs' => 'Card',
              _ => method,
            },
        },
        scope: benefit.scope,
        storeId: benefit.storeId,
        productIds: benefit.productIds,
        revision: benefit.revision,
      ),
  ];
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
