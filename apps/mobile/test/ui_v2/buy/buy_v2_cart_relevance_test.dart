import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
  group('R37 Cart relevance contracts', () {
    test('recommendations stay in-family and exclude Cart products', () {
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
      }
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
      final session = BuyV2Session(core: BuySession());
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
      expect(wholesaleOrder.deliveryInstruction, 'Deliver to receiving');
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
