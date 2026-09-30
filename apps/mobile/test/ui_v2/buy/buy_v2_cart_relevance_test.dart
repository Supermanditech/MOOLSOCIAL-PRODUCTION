import 'buy_v2_qualified_provider_fixture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

class QualificationDeliveryFacts implements BuyV2ProductFactsAdapter {
  const QualificationDeliveryFacts({
    this.available = true,
    this.unavailableIds = const {},
    this.closedIds = const {},
    this.priceOverrides = const {},
  });

  final bool available;
  final Set<String> unavailableIds;
  final Set<String> closedIds;
  final Map<String, int> priceOverrides;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      const BuyV2CatalogueProductFactsAdapter()
          .snapshotFor(product)
          .copyWith(
            sourceId: 'qualification-delivery-fixture',
            deliveryPromise: 'Delivery time confirmed at checkout',
            promisedByLabel: available ? '15 Sep 2026, 10 AM–12 PM' : '',
            price: priceOverrides[product.id],
            stale: unavailableIds.contains(product.id),
            storeOperatingState: closedIds.contains(product.id)
                ? BuyV2StoreOperatingState.closed
                : null,
            nextOpeningLabel: closedIds.contains(product.id)
                ? 'Next opening confirmed by the Store'
                : null,
          );
}

void main() {
  test(
    'custom delivery notes stay basket scoped and reach confirmed orders',
    () {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productFactsAdapter: const QualificationDeliveryFacts(),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-tomato');
      session.addProduct('w-notebook');
      expect(
        session.setCustomDeliveryInstruction(
          destination: BuyV2Destination.shop,
          text: '  Use the side entrance  ',
        ),
        isTrue,
      );
      expect(
        session.setCustomDeliveryInstruction(
          destination: BuyV2Destination.wholesale,
          text: 'Call at the warehouse gate',
        ),
        isTrue,
      );
      expect(
        session.setCustomDeliveryInstruction(
          destination: BuyV2Destination.wholesale,
          text: 'x' * 201,
        ),
        isFalse,
      );
      expect(
        session.deliveryInstructionTextFor(BuyV2Destination.wholesale),
        'Call at the warehouse gate',
      );
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      expect(
        session.confirmedOrders
            .singleWhere((o) => o.destination == BuyV2Destination.shop)
            .deliveryInstruction,
        'Use the side entrance',
      );
      expect(
        session.confirmedOrders
            .singleWhere((o) => o.destination == BuyV2Destination.wholesale)
            .deliveryInstruction,
        'Call at the warehouse gate',
      );
    },
  );
  test(
    'blank custom note clears instruction and presets replace custom note',
    () {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productFactsAdapter: const QualificationDeliveryFacts(),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-tomato');
      expect(
        session.setCustomDeliveryInstruction(
          destination: BuyV2Destination.shop,
          text: 'Side gate',
        ),
        isTrue,
      );
      expect(
        session.chooseDeliveryInstruction(
          destination: BuyV2Destination.shop,
          instructionId: 'shop-call-arrival',
        ),
        isTrue,
      );
      expect(
        session.customDeliveryInstructionFor(BuyV2Destination.shop),
        isNull,
      );
      expect(
        session.setCustomDeliveryInstruction(
          destination: BuyV2Destination.shop,
          text: '   ',
        ),
        isTrue,
      );
      expect(session.deliveryInstructionTextFor(BuyV2Destination.shop), isNull);
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      expect(session.confirmedOrders.single.deliveryInstruction, isNull);
    },
  );

  test('missing delivery estimate preserves cart and creates no order', () {
    final session = BuyV2Session(
      core: BuySession(),
      productFactsAdapter: const QualificationDeliveryFacts(available: false),
    );
    addTearDown(session.dispose);
    expect(session.addProduct('s-tomato'), isTrue);
    expect(session.addProduct('w-oil'), isTrue);
    final orderIds = session.orders.map((order) => order.id).toList();
    final quantities = {
      for (final line in session.cartLines) line.product.id: line.quantity,
    };
    final total = session.cartTotal;
    expect(session.openCheckout(), isTrue);
    expect(session.checkoutDeliveryEstimateReviewRequired, isTrue);
    expect(session.confirmOrder(), isFalse);
    expect(session.notice, contains('Delivery estimate unavailable'));
    expect(session.orders.map((order) => order.id), orderIds);
    expect(session.confirmedOrders, isEmpty);
    expect(session.cartTotal, total);
    for (final entry in quantities.entries) {
      expect(session.quantityFor(entry.key), entry.value);
    }
  });

  group('R37 Cart relevance contracts', () {
    test('recommendations stay in-family and exclude Cart products', () async {
      final session = BuyV2Session(core: BuySession());
      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        final product = BuyV2Catalogue.products.firstWhere(
          (candidate) =>
              candidate.destination == destination &&
              !candidate.requiresPrescription,
        );
        expect(session.addProduct(product.id), isTrue);

        final recommendations = session.cartRecommendationsFor(destination);

        expect(recommendations, isNotEmpty);
        expect(
          recommendations.every(
            (candidate) => candidate.destination == destination,
          ),
          isTrue,
        );
        expect(
          recommendations.any((candidate) => candidate.id == product.id),
          isFalse,
        );
        final all = session.cartRecommendationsFor(destination, limit: 1000);
        final sameStore = all.where(product.isFromSameStoreAs).toList();
        expect(
          all.take(sameStore.length).map((candidate) => candidate.id),
          sameStore.map((candidate) => candidate.id),
          reason: 'Basket Stores precede offers from other Stores',
        );
        final excluded = all.first;
        expect(
          session
              .cartRecommendationsFor(
                destination,
                excludedProductIds: {excluded.id},
                limit: 1000,
              )
              .any((candidate) => candidate.id == excluded.id),
          isFalse,
        );
        expect(session.cartRecommendationsFor(destination, limit: 0), isEmpty);
        expect(
          session
              .cartRecommendationsFor(destination, limit: 1000)
              .map((candidate) => candidate.id),
          all.map((candidate) => candidate.id),
        );
      }
      final anchor = BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == BuyV2Destination.shop &&
            BuyV2Catalogue.products.any(
              (other) =>
                  other.id != product.id &&
                  other.destination == product.destination &&
                  product.isFromSameStoreAs(other),
            ),
      );
      session.addProduct(anchor.id);
      final storeFirst = session.cartRecommendationsFor(
        BuyV2Destination.shop,
        limit: 1000,
      );
      expect(storeFirst.any(anchor.isFromSameStoreAs), isTrue);
      expect(storeFirst.first.isFromSameStoreAs(anchor), isTrue);
      final unavailable = session.cartRecommendationsFor(BuyV2Destination.shop);
      final saving = BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == BuyV2Destination.medicine &&
            product.mrp != null &&
            product.mrp! > product.price &&
            !product.requiresPrescription,
      );
      final guarded = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: QualificationDeliveryFacts(
          unavailableIds: {unavailable.first.id},
          closedIds: {unavailable.last.id},
          priceOverrides: {saving.id: saving.mrp!},
        ),
      );
      addTearDown(guarded.dispose);
      expect(
        guarded
            .cartRecommendationsFor(BuyV2Destination.shop, limit: 1000)
            .map((product) => product.id),
        isNot(contains(unavailable.first.id)),
      );
      expect(
        guarded
            .cartRecommendationsFor(BuyV2Destination.shop, limit: 1000)
            .map((product) => product.id),
        isNot(contains(unavailable.last.id)),
      );
      final offers = guarded.cartRecommendationsFor(
        BuyV2Destination.medicine,
        specialOffersOnly: true,
        limit: 1000,
      );
      expect(offers.map((product) => product.id), isNot(contains(saving.id)));
      expect(
        offers.every(
          (product) =>
              product.mrp != null &&
              product.mrp! > guarded.productFactsFor(product).price,
        ),
        isTrue,
      );
      final templates = BuyV2Catalogue.products
          .where((product) => product.destination == BuyV2Destination.shop)
          .toList();
      final source = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
        providerCount: 1,
        skusPerStore: templates.length * 2,
      );
      final pagedCore = BuySession();
      final paged = BuyV2Session(core: pagedCore, cataloguePageSource: source);
      addTearDown(paged.dispose);
      addTearDown(pagedCore.dispose);
      final index = templates.indexWhere(
        (p) => p.packTerms == null && p.variantAttributes.isEmpty,
      );
      final originalId = source.productIdAt(0, index);
      final repeatedId = source.productIdAt(0, index + templates.length);
      final differentId = source.productIdAt(0, (index + 1) % templates.length);
      expect(await paged.openLinkedProduct(originalId), isTrue);
      expect(paged.addProduct(originalId), isTrue);
      expect(await paged.openLinkedProduct(repeatedId), isTrue);
      expect(await paged.openLinkedProduct(differentId), isTrue);
      final retained = paged.cartRecommendationsFor(
        BuyV2Destination.shop,
        limit: 1000,
      );
      expect(retained.map((p) => p.id), isNot(contains(repeatedId)));
      expect(retained.map((p) => p.id), contains(differentId));
      expect(
        retained.first.isFromSameStoreAs(paged.product(originalId)),
        isTrue,
      );
      expect(paged.quantityFor(originalId), 1);
      expect(paged.quantityFor(repeatedId), 0);
      final beforeDiscovery = session.cartTotal;
      for (final type in ['shop', 'wholesale', 'bulk']) {
        final destination = type == 'shop'
            ? BuyV2Destination.shop
            : BuyV2Destination.wholesale;
        final choices = session.cartRecommendationsFor(
          destination,
          purchaseType: type,
          limit: 1000,
        );
        expect(choices, isNotEmpty);
        expect(
          choices.every((p) => session.cartPurchaseTypeFor(p) == type),
          isTrue,
        );
        expect(session.cartTotal, beforeDiscovery);
      }
      expect(
        session.cartRecommendationsFor(
          BuyV2Destination.shop,
          purchaseType: 'bulk',
        ),
        isEmpty,
      );
      final reviewSource = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
        providerCount: 1,
        includeVariantReviewFixtures: true,
      );
      var clockOffset = Duration.zero;
      final reviewCore = BuySession();
      final review = BuyV2Session(
        core: reviewCore,
        cataloguePageSource: reviewSource,
        catalogueNow: () => DateTime.now().add(clockOffset),
      );
      addTearDown(review.dispose);
      addTearDown(reviewCore.dispose);
      final phoneId = reviewSource.productIdAt(0, templates.length);
      expect(await review.openLinkedProduct(phoneId), isTrue);
      BuyV2Product? suppliedPack;
      for (var offset = 1; offset <= 12; offset++) {
        final id = reviewSource.productIdAt(0, templates.length + offset);
        expect(await review.openLinkedProduct(id), isTrue);
        final candidate = review.product(id);
        if (candidate.packTerms?.priceTiers.isNotEmpty == true) {
          suppliedPack = candidate;
          break;
        }
      }
      expect(suppliedPack, isNotNull);
      final pack = suppliedPack!;
      final packId = pack.id;
      expect(pack.hasValidPackTerms, isTrue);
      final packFacts = review.productFactsFor(pack);
      expect(
        review.nextCartDealTierFor(pack)?.minimumPacks,
        5,
        reason:
            'pack=${pack.id} store=${pack.storeId} listing=${pack.catalogueListing} '
            'price=${packFacts.price} state=${packFacts.orderabilityLabel} stale=${packFacts.stale} '
            'terms=${pack.packTerms?.priceTiers.map((t) => "${t.minimumPacks}:${t.price}").join(",")} '
            'current=${pack.packTerms?.pricingCurrentAt(DateTime.now())}',
      );
      expect(review.nextCartDealTierFor(pack)?.price, 380);
      final deals = review.cartRecommendationsFor(
        BuyV2Destination.shop,
        specialOffersOnly: true,
        limit: 1000,
      );
      expect(deals.map((p) => p.id), containsAll([phoneId, packId]));
      expect(deals.every(review.hasCartStoreDeal), isTrue);
      expect(review.cartTotal, 0);
      expect(review.addProduct(packId), isTrue);
      expect(
        review.quantityFor(packId),
        2,
        reason: 'A deal does not auto-add its tier quantity',
      );
      BuyV2Product withTiers(
        List<BuyV2PackPriceTier> tiers, {
        String? pricingStoreId,
      }) {
        final terms = pack.packTerms!;
        return pack.copyWith(
          packTerms: BuyV2PackTerms(
            skuId: pack.id,
            revision: terms.revision,
            sellUnit: terms.sellUnit,
            containedUnits: terms.containedUnits,
            netContentMilli: terms.netContentMilli,
            contentUnit: terms.contentUnit,
            quantityStep: terms.quantityStep,
            pricingStoreId: pricingStoreId ?? terms.pricingStoreId,
            priceObservedAt: terms.priceObservedAt,
            priceValidUntil: terms.priceValidUntil,
            priceTiers: tiers,
          ),
        );
      }

      final rounded = withTiers(const [
        BuyV2PackPriceTier(minimumPacks: 2, price: 400),
        BuyV2PackPriceTier(minimumPacks: 4, price: 380),
      ]);
      expect(review.nextCartDealTierFor(rounded)?.minimumPacks, 5);
      expect(review.nextCartDealTierFor(rounded)?.price, 380);
      expect(
        review.nextCartDealTierFor(
          withTiers(
            rounded.packTerms!.priceTiers,
            pricingStoreId: 'another-store',
          ),
        ),
        isNull,
      );
      expect(
        review.nextCartDealTierFor(
          withTiers(const [
            BuyV2PackPriceTier(minimumPacks: 2, price: 400),
            BuyV2PackPriceTier(minimumPacks: 9007199254740991, price: 380),
          ]),
        ),
        isNull,
        reason: 'An unsafe increased spending commitment is not advertised',
      );
      review.increase(packId);
      expect(review.quantityFor(packId), 5);
      expect(review.cartTotal, 1900);
      expect(review.nextCartDealTierFor(pack)?.minimumPacks, 8);
      expect(review.nextCartDealTierFor(pack)?.price, 360);
      expect(review.setCartQuantity(packId, '8'), isTrue);
      expect(review.cartTotal, 2880);
      expect(review.nextCartDealTierFor(pack), isNull);
      review.decrease(packId);
      expect(review.cartTotal, 1900);
      expect(review.nextCartDealTierFor(pack)?.minimumPacks, 8);
      clockOffset = const Duration(days: 2);
      expect(review.nextCartDealTierFor(pack), isNull);
      expect(review.hasCartStoreDeal(pack), isFalse);
      final unidentified = BuyV2Catalogue.products.firstWhere(
        (p) => p.storeId == null,
      );
      expect(review.hasCartStoreDeal(unidentified), isFalse);
    });

    test('bill savings derive only from current MRP and quantities', () {
      final session = BuyV2Session(core: BuySession());
      final product = BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.mrp != null &&
            candidate.mrp! > candidate.price &&
            !candidate.requiresPrescription,
      );

      expect(session.addProduct(product.id), isTrue);
      session.increase(product.id);
      final quantity = session.quantityFor(product.id);

      expect(session.scopedCartTotal, product.price * quantity);
      expect(session.scopedCartListPriceTotal, product.mrp! * quantity);
      expect(
        session.scopedCartSavings,
        (product.mrp! - product.price) * quantity,
      );
    });

    test('coupon and payment adapters fail malformed benefits closed', () {
      final session = BuyV2Session(
        core: BuySession(),
        cartBenefitsAdapter: const _AdversarialBenefitsAdapter(),
      );
      final product = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );
      session.addProduct(product.id);

      final coupons = session.cartBenefits(
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.shop,
      );
      final paymentOffers = session.cartBenefits(
        kind: BuyV2CartBenefitKind.paymentOffer,
        destination: BuyV2Destination.shop,
      );

      expect(coupons.map((benefit) => benefit.id), ['valid-coupon']);
      expect(paymentOffers, isEmpty);
    });

    test('device-review seeds cover every vertical and stay total-neutral', () {
      const adapter = BuyV2SeededCartBenefitsAdapter();
      final session = BuyV2Session(
        core: BuySession(),
        cartBenefitsAdapter: adapter,
      );
      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        final product = BuyV2Catalogue.products.firstWhere(
          (candidate) =>
              candidate.destination == destination &&
              !candidate.requiresPrescription,
        );
        expect(session.addProduct(product.id), isTrue);
        final coupons = adapter.benefitsFor(
          kind: BuyV2CartBenefitKind.coupon,
          destinations: {destination},
          itemTotal: session.totalForDestination(destination),
        );
        final minimumSpend = coupons
            .map((benefit) => benefit.minimumSpend!)
            .reduce((left, right) => left > right ? left : right);
        if (session.totalForDestination(destination) < minimumSpend) {
          expect(
            session.cartBenefits(
              kind: BuyV2CartBenefitKind.coupon,
              destination: destination,
            ),
            isEmpty,
          );
          expect(session.chooseCartBenefit(coupons.first), isFalse);
          final quantity = (minimumSpend / product.price).ceil();
          expect(session.setCartQuantity(product.id, '$quantity'), isTrue);
        }
        expect(
          session.totalForDestination(destination),
          greaterThanOrEqualTo(minimumSpend),
        );
      }
      final originalTotal = session.cartTotal;

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        for (final kind in BuyV2CartBenefitKind.values) {
          final benefits = session.cartBenefits(
            kind: kind,
            destination: destination,
          );
          expect(benefits, hasLength(3));
          expect(
            benefits.map((benefit) => benefit.id).toSet(),
            hasLength(benefits.length),
          );
          for (final benefit in benefits) {
            expect(benefit.destination, destination);
            expect(benefit.kind, kind);
            expect(benefit.sourceId, 'device-seed-v2');
            expect(
              '${benefit.title} ${benefit.detail}',
              isNot(
                matches(
                  RegExp(r'(\bcode\b|\bunlock|\bredeem)', caseSensitive: false),
                ),
              ),
            );
          }
          final benefit = benefits.first;
          expect(benefit.destination, destination);
          expect(benefit.kind, kind);
          expect(session.chooseCartBenefit(benefit), isTrue);
          expect(session.chooseCartBenefit(benefits[1]), isTrue);
          final replaced = session.selectedCartBenefit(
            kind: kind,
            destination: destination,
          );
          expect(replaced?.id, benefits[1].id);
          expect(replaced?.sourceId, benefits[1].sourceId);
          expect(session.chooseCartBenefit(benefit), isTrue);
        }
      }

      expect(
        session.selectedCartBenefitsFor({
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        }),
        hasLength(6),
      );
      expect(session.cartTotal, originalTotal);
      expect(session.scopedCouponSaving, greaterThan(0));
      expect(
        session.scopedPayableTotal,
        originalTotal - session.scopedCouponSaving,
      );
      expect(
        adapter.benefitsFor(
          kind: BuyV2CartBenefitKind.coupon,
          destinations: const {BuyV2Destination.shop},
          itemTotal: 0,
        ),
        isEmpty,
      );
      expect(
        adapter.benefitsFor(
          kind: BuyV2CartBenefitKind.coupon,
          destinations: const {BuyV2Destination.orders},
          itemTotal: 100,
        ),
        isEmpty,
      );
    });

    test('normal test build defaults to fail-closed cart benefits', () {
      expect(buyV2DeviceReviewBenefitSeedsEnabled, isFalse);
      final session = BuyV2Session(core: BuySession());
      final product = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );
      session.addProduct(product.id);

      expect(
        session.cartBenefits(
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
        ),
        isEmpty,
      );
    });

    test('benefit eligibility receives only the selected vertical total', () {
      final adapter = _CapturingBenefitsAdapter();
      final session = BuyV2Session(
        core: BuySession(),
        cartBenefitsAdapter: adapter,
      );
      final shop = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.wholesale,
      );
      session.addProduct(shop.id);
      session.addProduct(wholesale.id);
      session.openCart();

      session.cartBenefits(
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.shop,
      );
      expect(adapter.destinations, {BuyV2Destination.shop});
      expect(adapter.itemTotal, session.totalForDestination(shop.destination));

      session.cartBenefits(
        kind: BuyV2CartBenefitKind.paymentOffer,
        destination: BuyV2Destination.wholesale,
      );
      expect(adapter.destinations, {BuyV2Destination.wholesale});
      expect(
        adapter.itemTotal,
        session.totalForDestination(wholesale.destination),
      );

      session.cartBenefits(kind: BuyV2CartBenefitKind.coupon);
      expect(adapter.destinations, {
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      });
      expect(adapter.itemTotal, session.cartTotal);
    });

    test(
      'benefit selection is kind-owned, total-neutral and fails stale values closed',
      () {
        final adapter = _MutableBenefitsAdapter();
        final session = BuyV2Session(
          core: BuySession(),
          cartBenefitsAdapter: adapter,
        );
        final shop = BuyV2Catalogue.products.firstWhere(
          (candidate) => candidate.destination == BuyV2Destination.shop,
        );
        session.addProduct(shop.id);
        final originalTotal = session.cartTotal;

        final coupon = session
            .cartBenefits(
              kind: BuyV2CartBenefitKind.coupon,
              destination: BuyV2Destination.shop,
            )
            .single;
        final paymentOffer = session
            .cartBenefits(
              kind: BuyV2CartBenefitKind.paymentOffer,
              destination: BuyV2Destination.shop,
            )
            .single;

        expect(session.chooseCartBenefit(coupon), isTrue);
        expect(session.chooseCartBenefit(paymentOffer), isTrue);
        expect(
          session.selectedCartBenefitsFor({BuyV2Destination.shop}),
          hasLength(2),
        );
        expect(session.cartTotal, originalTotal);
        expect(session.scopedPayableTotal, originalTotal);

        session.removeCartBenefit(
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
        );
        expect(
          session.selectedCartBenefit(
            kind: BuyV2CartBenefitKind.coupon,
            destination: BuyV2Destination.shop,
          ),
          isNull,
        );
        expect(
          session.selectedCartBenefit(
            kind: BuyV2CartBenefitKind.paymentOffer,
            destination: BuyV2Destination.shop,
          ),
          isNotNull,
        );

        adapter.exposeBenefits = false;
        expect(
          session.selectedCartBenefit(
            kind: BuyV2CartBenefitKind.paymentOffer,
            destination: BuyV2Destination.shop,
          ),
          isNull,
        );
        expect(session.chooseCartBenefit(paymentOffer), isFalse);
        expect(session.notice, 'This offer is no longer available.');
        expect(session.cartTotal, originalTotal);
      },
    );

    test('delivery instructions stay vertical-owned through confirmation', () {
      final session = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: const QualificationDeliveryFacts(),
      );
      final shop = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.wholesale,
      );
      session.addProduct(shop.id);
      session.addProduct(wholesale.id);

      expect(
        session.chooseDeliveryInstruction(
          destination: BuyV2Destination.shop,
          instructionId: 'shop-call-arrival',
        ),
        isTrue,
      );
      expect(
        session.chooseDeliveryInstruction(
          destination: BuyV2Destination.wholesale,
          instructionId: 'shop-call-arrival',
        ),
        isFalse,
      );
      expect(
        session.chooseDeliveryInstruction(
          destination: BuyV2Destination.wholesale,
          instructionId: 'trade-receiving-desk',
        ),
        isTrue,
      );

      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      final shopOrder = session.confirmedOrders.singleWhere(
        (order) => order.destination == BuyV2Destination.shop,
      );
      final wholesaleOrder = session.confirmedOrders.singleWhere(
        (order) => order.destination == BuyV2Destination.wholesale,
      );
      expect(shopOrder.deliveryInstruction, 'Call on arrival');
      expect(
        wholesaleOrder.deliveryInstruction,
        'Deliver to the receiving desk',
      );
    });

    test('cleared delivery instruction is absent from confirmed order', () {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productFactsAdapter: const QualificationDeliveryFacts(),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final product = BuyV2Catalogue.products.firstWhere(
        (product) => product.destination == BuyV2Destination.shop,
      );
      session.addProduct(product.id);
      expect(
        session.selectedDeliveryInstructionFor(BuyV2Destination.shop),
        isNull,
      );
      expect(
        session.chooseDeliveryInstruction(
          destination: BuyV2Destination.shop,
          instructionId: 'shop-call-arrival',
        ),
        isTrue,
      );
      expect(
        session.chooseDeliveryInstruction(
          destination: BuyV2Destination.shop,
          instructionId: null,
        ),
        isTrue,
      );
      expect(
        session.selectedDeliveryInstructionFor(BuyV2Destination.shop),
        isNull,
      );
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      expect(session.confirmedOrders.single.deliveryInstruction, isNull);
    });

    test('monetary tips fail closed without a quick-delivery policy', () {
      final session = BuyV2Session(core: BuySession());
      for (final destination in BuyV2Destination.values) {
        expect(session.tipOptionsFor(destination), isEmpty);
      }
      final shop = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );
      session.addProduct(shop.id);
      final group = session.scopedCartFulfilmentGroups.single;

      expect(
        session.chooseTip(
          fulfilmentKey: group.key,
          destination: BuyV2Destination.shop,
          amount: 10,
        ),
        isFalse,
      );
      expect(session.scopedTipTotal, 0);
      expect(session.scopedPayableTotal, session.scopedCartTotal);
    });
  });

  group('R37 Saved purchase-intent contracts', () {
    test('store boundary restores only explicit vertical choices', () async {
      final store = _MemorySavedProductsStore();
      final first = BuyV2Session(core: BuySession(), savedProductsStore: store);
      await first.restoreSavedProducts();
      final shop = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == BuyV2Destination.wholesale &&
            candidate.canonicalId == shop.canonicalId,
      );

      expect(first.savedCountFor(BuyV2Destination.shop), 0);
      expect(first.savedCountFor(BuyV2Destination.wholesale), 0);
      first.toggleSaved(shop.id);
      await Future<void>.delayed(Duration.zero);

      final restored = BuyV2Session(
        core: BuySession(),
        savedProductsStore: store,
      );
      await restored.restoreSavedProducts();

      expect(restored.isSaved(shop.id), isTrue);
      expect(restored.isSaved(wholesale.id), isFalse);
    });

    test('clear removes only the selected Saved vertical', () {
      final session = BuyV2Session(core: BuySession());
      final shop = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.medicine,
      );
      session.toggleSaved(shop.id);
      session.toggleSaved(medicine.id);

      session.clearSavedProducts(BuyV2Destination.shop);

      expect(session.isSaved(shop.id), isFalse);
      expect(session.isSaved(medicine.id), isTrue);
    });

    test('productwise Saved add respects Wholesale and prescription gates', () {
      final session = BuyV2Session(core: BuySession());
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.wholesale,
      );
      final otc = BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == BuyV2Destination.medicine &&
            !candidate.requiresPrescription,
      );
      final rx = BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == BuyV2Destination.medicine &&
            candidate.requiresPrescription,
      );
      session.toggleSaved(wholesale.id);
      session.toggleSaved(otc.id);
      session.toggleSaved(rx.id);

      session.businessVerified = false;
      expect(session.addProduct(wholesale.id), isFalse);
      expect(session.quantityFor(wholesale.id), 0);

      expect(session.addProduct(otc.id), isTrue);
      expect(session.quantityFor(otc.id), greaterThan(0));
      expect(session.addProduct(rx.id), isFalse);
      expect(session.quantityFor(rx.id), 0);
      expect(session.isSaved(rx.id), isTrue);
      expect(session.pendingPrescriptionProductId, rx.id);
    });

    test(
      'live coupon eligibility applies only authoritative current savings',
      () async {
        final evaluatedAt = DateTime.utc(2026, 8, 29, 12);
        final adapter = _LiveBenefitsAdapter(
          BuyV2CartBenefitsSnapshot(
            state: BuyV2CartBenefitsLoadState.ready,
            evaluatedAt: evaluatedAt,
            benefits: [
              BuyV2CartBenefit(
                id: 'live-shop-sale',
                kind: BuyV2CartBenefitKind.coupon,
                destination: BuyV2Destination.shop,
                title: 'Weekend basket saving',
                detail: 'Eligible for this Shop basket.',
                sourceId: 'retailer-campaign-1',
                strategy: BuyV2CartBenefitStrategy.timedSale,
                sponsor: BuyV2CartBenefitSponsor.retailer,
                sponsorName: 'Shree Balaji Fresh',
                savingAmount: 10,
                validFrom: evaluatedAt.subtract(const Duration(hours: 1)),
                validUntil: evaluatedAt.add(const Duration(hours: 3)),
              ),
              BuyV2CartBenefit(
                id: 'expired',
                kind: BuyV2CartBenefitKind.coupon,
                destination: BuyV2Destination.shop,
                title: 'Expired campaign',
                detail: 'Must fail closed.',
                sourceId: 'expired-source',
                savingAmount: 5,
                validUntil: evaluatedAt,
              ),
              const BuyV2CartBenefit(
                id: 'invalid-payment-deduction',
                kind: BuyV2CartBenefitKind.paymentOffer,
                destination: BuyV2Destination.shop,
                title: 'Unconfirmed cashback',
                detail: 'Must not reduce the payable total.',
                sourceId: 'bank-source',
                sponsor: BuyV2CartBenefitSponsor.bank,
                sponsorName: 'Partner Bank',
                savingAmount: 10,
              ),
              const BuyV2CartBenefit(
                id: 'free-delivery',
                kind: BuyV2CartBenefitKind.coupon,
                destination: BuyV2Destination.shop,
                title: 'Free delivery',
                detail: 'Delivery is included for this basket.',
                sourceId: 'mool-campaign',
                strategy: BuyV2CartBenefitStrategy.freeDelivery,
                freeDelivery: true,
              ),
            ],
          ),
        );
        final session = BuyV2Session(
          core: BuySession(),
          cartBenefitsAdapter: adapter,
        );
        addTearDown(session.dispose);
        final product = BuyV2Catalogue.products.firstWhere(
          (candidate) => candidate.destination == BuyV2Destination.shop,
        );
        expect(session.addProduct(product.id), isTrue);
        expect(await session.refreshCartBenefits(), isTrue);

        final coupons = session.cartBenefits(
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
        );
        expect(coupons.map((benefit) => benefit.id), [
          'live-shop-sale',
          'free-delivery',
        ]);
        expect(session.chooseCartBenefit(coupons.first), isTrue);
        expect(session.scopedCouponSaving, 10);
        expect(session.scopedPayableTotal, session.scopedCartTotal - 10);

        adapter.snapshot = BuyV2CartBenefitsSnapshot(
          state: BuyV2CartBenefitsLoadState.offline,
          evaluatedAt: evaluatedAt,
          customerMessage: 'Reconnect to check current eligibility.',
        );
        expect(await session.refreshCartBenefits(), isFalse);
        expect(session.scopedCouponSaving, 0);
        expect(
          session.cartBenefitsLoadState,
          BuyV2CartBenefitsLoadState.offline,
        );

        adapter.snapshot = BuyV2CartBenefitsSnapshot(
          state: BuyV2CartBenefitsLoadState.ready,
          evaluatedAt: evaluatedAt,
          benefits: [coupons.first],
        );
        expect(await session.refreshCartBenefits(), isTrue);
        expect(session.scopedCouponSaving, 10);

        adapter.snapshot = BuyV2CartBenefitsSnapshot(
          state: BuyV2CartBenefitsLoadState.ready,
          evaluatedAt: evaluatedAt,
          benefits: [coupons.last],
        );
        expect(await session.refreshCartBenefits(), isFalse);
        expect(
          session.selectedCartBenefitsFor({BuyV2Destination.shop}),
          isEmpty,
        );
        expect(session.scopedCouponSaving, 0);

        // Published opportunities remain separate from applicable coupons.
        var localNow = DateTime.now();
        final opportunityAdapter = _LiveBenefitsAdapter(adapter.snapshot);
        final opportunitySession = BuyV2Session(
          core: BuySession(),
          cartBenefitsAdapter: opportunityAdapter,
          catalogueNow: () => localNow,
          commerceAdapter: _ScopedOpportunityCommerce(),
          productFactsAdapter: QualifiedTestProductFacts({
            for (final p in BuyV2Catalogue.allProducts) p.id,
          }),
          reviewDataEnabled: false,
        );
        addTearDown(opportunitySession.dispose);
        await opportunitySession.restoreCommerce();
        final opportunityProduct = opportunitySession.product(product.id);
        final otherStore = BuyV2Catalogue.products
            .map((p) => opportunitySession.product(p.id))
            .firstWhere(
              (candidate) =>
                  candidate.destination == BuyV2Destination.shop &&
                  candidate.storeId != opportunityProduct.storeId &&
                  !candidate.requiresPrescription,
            );
        expect(opportunitySession.addProduct(opportunityProduct.id), isTrue);
        expect(opportunitySession.addProduct(otherStore.id), isTrue);
        opportunitySession.openCart(scope: BuyV2CartScope.all);
        BuyV2CartBenefit opportunity({
          BuyV2CartBenefitScope scope = BuyV2CartBenefitScope.products,
          int? minimumSpend,
          int? minimumQuantity,
          Set<String> methods = const {},
          DateTime? expiry,
          bool freeDelivery = false,
          String sourceId = 'provider-published-opportunity',
        }) => BuyV2CartBenefit(
          id: 'spend-opportunity',
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
          title: 'Eligible basket saving',
          detail: 'Provider saving on the specified eligible products.',
          sourceId: sourceId,
          savingAmount: 10,
          minimumSpend:
              minimumSpend ??
              opportunityProduct.price * opportunityProduct.minimumOrder + 40,
          minimumQuantity: minimumQuantity,
          eligiblePaymentMethods: methods,
          scope: scope,
          storeId: scope == BuyV2CartBenefitScope.platform
              ? null
              : opportunityProduct.storeId,
          productIds: scope == BuyV2CartBenefitScope.products
              ? {opportunityProduct.id}
              : {},
          validUntil: expiry ?? evaluatedAt.add(const Duration(hours: 1)),
          freeDelivery: freeDelivery,
        );
        Future<bool> publish(List<BuyV2CartBenefit> benefits) {
          opportunityAdapter.snapshot = BuyV2CartBenefitsSnapshot(
            state: BuyV2CartBenefitsLoadState.ready,
            evaluatedAt: evaluatedAt,
            benefits: benefits,
          );
          return opportunitySession.refreshCartBenefits();
        }

        for (final scope in BuyV2CartBenefitScope.values) {
          final matchingTotal = scope == BuyV2CartBenefitScope.platform
              ? opportunitySession.scopedCartTotal
              : opportunityProduct.price * opportunityProduct.minimumOrder;
          final candidate = opportunity(
            scope: scope,
            minimumSpend: matchingTotal + 40,
          );
          await publish([candidate]);
          expect(opportunitySession.cartOfferOpportunity()?.remainingSpend, 40);
          expect(
            opportunitySession.cartBenefits(kind: BuyV2CartBenefitKind.coupon),
            isEmpty,
          );
          expect(opportunitySession.chooseCartBenefit(candidate), isFalse);
          expect(opportunitySession.scopedCouponSaving, 0);
        }
        await publish([opportunity()]);
        opportunitySession.selectCartProduct(otherStore.id, false);
        await opportunitySession.refreshCartBenefits();
        expect(opportunitySession.cartOfferOpportunity()?.remainingSpend, 40);
        opportunitySession.selectCartProduct(opportunityProduct.id, false);
        await opportunitySession.refreshCartBenefits();
        expect(opportunitySession.cartOfferOpportunity(), isNull);
        opportunitySession.selectCartProduct(opportunityProduct.id, true);
        await opportunitySession.refreshCartBenefits();
        expect(opportunitySession.cartOfferOpportunity()?.remainingSpend, 40);

        for (final candidate in [
          opportunity(expiry: evaluatedAt),
          opportunity(minimumQuantity: opportunityProduct.minimumOrder + 10),
          opportunity(methods: {'unsupported-method'}),
          opportunity(freeDelivery: true),
          opportunity(sourceId: ''),
        ]) {
          await publish([candidate]);
          expect(opportunitySession.cartOfferOpportunity(), isNull);
        }
        final threshold = opportunity(
          minimumSpend:
              opportunityProduct.price *
              (opportunityProduct.minimumOrder +
                  opportunityProduct.quantityStep),
        );
        await publish([threshold]);
        expect(
          opportunitySession.cartOfferOpportunity()?.remainingSpend,
          opportunityProduct.price * opportunityProduct.quantityStep,
        );
        opportunitySession.increase(opportunityProduct.id);
        await opportunitySession.refreshCartBenefits();
        expect(opportunitySession.cartOfferOpportunity(), isNull);
        expect(opportunitySession.chooseCartBenefit(threshold), isTrue);
        expect(opportunitySession.scopedCouponSaving, 10);
        opportunitySession.decrease(opportunityProduct.id);
        expect(await opportunitySession.refreshCartBenefits(), isFalse);
        expect(opportunitySession.scopedCouponSaving, 0);
        expect(
          opportunitySession.selectedCartBenefitsFor({BuyV2Destination.shop}),
          isEmpty,
        );

        final applied = BuyV2CartBenefit(
          id: 'already-eligible',
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
          title: 'Current coupon',
          detail: 'Only one coupon for these products.',
          sourceId: 'provider-current',
          savingAmount: 5,
          scope: BuyV2CartBenefitScope.products,
          storeId: opportunityProduct.storeId,
          productIds: {opportunityProduct.id},
        );
        await publish([opportunity(), applied]);
        expect(opportunitySession.chooseCartBenefit(applied), isTrue);
        expect(opportunitySession.cartOfferOpportunity(), isNull);
        expect(opportunitySession.scopedCouponSaving, 5);
        opportunitySession.removeCartBenefit(
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
        );
        expect(opportunitySession.cartOfferOpportunity()?.remainingSpend, 40);
        localNow = localNow.add(const Duration(hours: 2));
        expect(opportunitySession.cartOfferOpportunity(), isNull);
        opportunityAdapter.snapshot = BuyV2CartBenefitsSnapshot(
          state: BuyV2CartBenefitsLoadState.offline,
          evaluatedAt: evaluatedAt,
        );
        await opportunitySession.refreshCartBenefits();
        expect(opportunitySession.cartOfferOpportunity(), isNull);
        opportunitySession.decrease(opportunityProduct.id);
        expect(opportunitySession.cartOfferOpportunity(), isNull);
      },
    );

    test(
      'live coupon is rechecked and retained in placed order totals',
      () async {
        final adapter = _LiveBenefitsAdapter(
          BuyV2CartBenefitsSnapshot(
            state: BuyV2CartBenefitsLoadState.ready,
            evaluatedAt: DateTime.utc(2026, 8, 29, 12),
            benefits: const [
              BuyV2CartBenefit(
                id: 'manufacturer-load-saving',
                kind: BuyV2CartBenefitKind.coupon,
                destination: BuyV2Destination.shop,
                title: 'Load saving',
                detail: 'Eligible quantity reached.',
                sourceId: 'manufacturer-campaign',
                strategy: BuyV2CartBenefitStrategy.loadBased,
                sponsor: BuyV2CartBenefitSponsor.manufacturer,
                sponsorName: 'Approved Manufacturer',
                savingAmount: 10,
                minimumQuantity: 1,
              ),
            ],
          ),
        );
        final session = BuyV2Session(
          core: BuySession(),
          cartBenefitsAdapter: adapter,
        );
        addTearDown(session.dispose);
        final product = BuyV2Catalogue.products.firstWhere(
          (candidate) => candidate.destination == BuyV2Destination.shop,
        );
        expect(session.addProduct(product.id), isTrue);
        await session.refreshCartBenefits();
        final coupon = session
            .cartBenefits(
              kind: BuyV2CartBenefitKind.coupon,
              destination: BuyV2Destination.shop,
            )
            .single;
        expect(session.chooseCartBenefit(coupon), isTrue);
        session.openCart(scope: BuyV2CartScope.shop);
        expect(session.openCheckout(), isTrue);
        expect(session.continueCheckoutFromAddress(), isTrue);
        expect(session.choosePayment('Cash on Delivery'), isTrue);
        expect(session.continueCheckoutFromPayment(), isTrue);
        final expectedTotal = session.checkoutTotal - coupon.savingAmount;

        final submitted = await session.submitOrder();
        expect(
          submitted,
          isTrue,
          reason:
              'notice=${session.notice}; '
              'submission=${session.checkoutSubmissionState}; '
              'promiseReview=${session.checkoutPromiseReviewRequired}; '
              'benefits=${session.cartBenefitsLoadState}',
        );
        expect(session.confirmedTotal, expectedTotal);
        expect(session.confirmedOrders.single.discount, coupon.savingAmount);
        expect(session.confirmedOrders.single.total, expectedTotal);
        expect(adapter.requests, isNotEmpty);
      },
    );
  });
}

class _LiveBenefitsAdapter implements BuyV2LiveCartBenefitsAdapter {
  _LiveBenefitsAdapter(this.snapshot);

  BuyV2CartBenefitsSnapshot snapshot;
  final List<BuyV2CartBenefitsRequest> requests = [];

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) => const [];

  @override
  Future<BuyV2CartBenefitsSnapshot> loadEligibility(
    BuyV2CartBenefitsRequest request,
  ) async {
    requests.add(request);
    return snapshot;
  }
}

class _AdversarialBenefitsAdapter implements BuyV2CartBenefitsAdapter {
  const _AdversarialBenefitsAdapter();

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) => [
    const BuyV2CartBenefit(
      id: 'valid-coupon',
      kind: BuyV2CartBenefitKind.coupon,
      destination: BuyV2Destination.shop,
      title: 'Account coupon',
      detail: 'Validated by coupon source.',
      sourceId: 'coupon-source-1',
    ),
    const BuyV2CartBenefit(
      id: 'cross-vertical',
      kind: BuyV2CartBenefitKind.coupon,
      destination: BuyV2Destination.medicine,
      title: 'Wrong vertical',
      detail: 'Must fail closed.',
      sourceId: 'coupon-source-2',
    ),
    const BuyV2CartBenefit(
      id: '',
      kind: BuyV2CartBenefitKind.coupon,
      destination: BuyV2Destination.shop,
      title: 'Missing identity',
      detail: 'Must fail closed.',
      sourceId: 'coupon-source-3',
    ),
  ];
}

class _CapturingBenefitsAdapter implements BuyV2CartBenefitsAdapter {
  Set<BuyV2Destination> destinations = const {};
  int itemTotal = -1;

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) {
    this.destinations = Set.unmodifiable(destinations);
    this.itemTotal = itemTotal;
    return const [];
  }
}

class _MutableBenefitsAdapter implements BuyV2CartBenefitsAdapter {
  bool exposeBenefits = true;

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) {
    if (!exposeBenefits ||
        !destinations.contains(BuyV2Destination.shop) ||
        itemTotal <= 0) {
      return const [];
    }
    return [
      if (kind == BuyV2CartBenefitKind.coupon)
        const BuyV2CartBenefit(
          id: 'selected-coupon',
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
          title: 'Selected coupon',
          detail: 'Provider-owned eligibility.',
          sourceId: 'coupon-provider',
        ),
      if (kind == BuyV2CartBenefitKind.paymentOffer)
        const BuyV2CartBenefit(
          id: 'selected-payment',
          kind: BuyV2CartBenefitKind.paymentOffer,
          destination: BuyV2Destination.shop,
          title: 'Selected payment offer',
          detail: 'Provider-owned compatibility.',
          sourceId: 'payment-provider',
        ),
    ];
  }
}

class _MemorySavedProductsStore implements BuyV2SavedProductsStore {
  Set<String>? _value;

  @override
  String get ownerScope => 'test-owner';

  @override
  Future<Set<String>?> read() async =>
      _value == null ? null : Set.unmodifiable(_value!);

  @override
  Future<bool> write(Set<String> savedProductKeys) async {
    _value = Set.of(savedProductKeys);
    return true;
  }
}

class _ScopedOpportunityCommerce implements BuyV2CommerceAdapter {
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [
      for (final p in BuyV2Catalogue.allProducts)
        p.copyWith(
          storeId: p.id == 's-milk' ? 'store-b' : 'store-a',
          offerClass: p.offerClass ?? BuyV2OfferClass.retail,
        ),
    ],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unused');
}
