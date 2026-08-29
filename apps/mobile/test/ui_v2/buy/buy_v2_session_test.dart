import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_catalogue_data.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

final class _T01CDeliveryFactsAdapter implements BuyV2ProductFactsAdapter {
  final promises = <BuyV2Destination, (String, String)>{
    BuyV2Destination.shop: ('within 5 min', 'by 6:35 PM'),
    BuyV2Destination.wholesale: ('within 1 day', 'by tomorrow 4:00 PM'),
  };

  void update(
    BuyV2Destination destination, {
    required String promise,
    required String promisedBy,
  }) {
    promises[destination] = (promise, promisedBy);
  }

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final quote = promises[product.destination];
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          deliveryPromise: quote?.$1 ?? product.deliveryPromise,
          promisedByLabel: quote?.$2,
          sourceId: 'b01-t01c-delivery-quote',
        );
  }
}

final class _ShopCommerceAdapter implements BuyV2CommerceAdapter {
  _ShopCommerceAdapter({required this.snapshot, required this.placement});

  final BuyV2CommerceSnapshot snapshot;
  BuyV2OrderPlacementResult placement;
  BuyV2OrderPlacementResult? reconciliation;
  int placementCalls = 0;
  int reconciliationCalls = 0;
  int reviewCalls = 0;
  int reportCalls = 0;
  int orderRefreshCalls = 0;
  final requests = <BuyV2OrderPlacementRequest>[];
  BuyV2MutationResult reviewResult = const BuyV2MutationResult(
    accepted: true,
    customerMessage: 'Review added.',
  );
  BuyV2MutationResult reportResult = const BuyV2MutationResult(
    accepted: true,
    customerMessage: 'Report received.',
  );
  BuyV2OrderRefreshResult orderRefreshResult = const BuyV2OrderRefreshResult(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: 'Order updates are unavailable right now.',
  );
  BuyV2OrderAlertsResult alertsResult = const BuyV2OrderAlertsResult(
    available: true,
    enabled: false,
    customerMessage: 'Order alerts are paused.',
  );

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => snapshot;

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async {
    placementCalls += 1;
    requests.add(request);
    return placement;
  }

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async {
    reconciliationCalls += 1;
    return reconciliation ?? placement;
  }

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async {
    orderRefreshCalls += 1;
    return orderRefreshResult;
  }

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async => alertsResult;

  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({required bool enabled}) async {
    alertsResult = BuyV2OrderAlertsResult(
      available: true,
      enabled: enabled,
      customerMessage: enabled
          ? 'Order alerts are on.'
          : 'Order alerts are paused.',
    );
    return alertsResult;
  }

  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async => const BuyV2AddressRequestResult(
    customerMessage: 'Address requests are unavailable right now.',
  );

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) async {
    reportCalls += 1;
    return reportResult;
  }

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) async {
    reviewCalls += 1;
    return reviewResult;
  }
}

final class _MemoryCustomerStateStore implements BuyV2CustomerStateStore {
  _MemoryCustomerStateStore(this.ownerScope);

  @override
  final String ownerScope;

  BuyV2CustomerStateSnapshot? snapshot;

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    this.snapshot = snapshot;
    return true;
  }
}

final class _MutableCommerceFactsAdapter implements BuyV2ProductFactsAdapter {
  int? price;
  String orderabilityLabel = 'Available to add';
  bool stale = false;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          price: price ?? product.price,
          orderabilityLabel: orderabilityLabel,
          sourceId: 'shop-live-facts',
          observedAt: DateTime(2026, 8, 29),
          stale: stale,
        );
  }
}

Future<
  ({
    BuyV2Session session,
    _ShopCommerceAdapter adapter,
    BuyV2Product product,
    BuyV2Order order,
  })
>
_openProductionCheckout({
  required BuyV2OrderPlacementOutcome outcome,
  Uri? paymentActionUri,
  String? paymentReference,
  BuyV2ProductFactsAdapter? factsAdapter,
  BuyV2CustomerStateStore? customerStateStore,
  bool productReportsAvailable = false,
  bool productReviewAvailable = false,
  BuyV2BusinessVerificationState businessVerificationState =
      BuyV2BusinessVerificationState.unavailable,
}) async {
  final product = BuyV2Catalogue.products.firstWhere(
    (candidate) => candidate.destination == BuyV2Destination.shop,
  );
  const address = BuyV2Address(
    id: 'server-home',
    kind: BuyV2AddressKind.home,
    label: 'Home',
    recipient: 'Aarav Sharma',
    phone: '9000000000',
    line: '12, Central Avenue',
    area: 'Sardarpura, Jodhpur',
    pinCode: '342003',
    landmark: 'Near the market',
  );
  final order = BuyV2Order(
    id: 'MS-SERVER-1',
    destination: BuyV2Destination.shop,
    title: 'Shop order',
    itemSummary: '1 product',
    total: product.price,
    partner: product.seller,
    partnerType: product.partnerRole,
    promise: product.deliveryPromise,
    destinationLabel: address.shortLine,
    progress: .2,
    status: BuyV2OrderStatus.preparing,
    purchaseId: 'BUY-SERVER-1',
    productIds: [product.id],
    lines: [BuyV2CartLine(product: product, quantity: 1)],
    paymentMethod: 'UPI',
  );
  final placement = BuyV2OrderPlacementResult(
    outcome: outcome,
    customerMessage: switch (outcome) {
      BuyV2OrderPlacementOutcome.paymentActionRequired =>
        'Continue to your payment app.',
      BuyV2OrderPlacementOutcome.paymentPending =>
        'Payment confirmation is pending.',
      BuyV2OrderPlacementOutcome.paymentUnknown =>
        'Payment status could not be confirmed.',
      BuyV2OrderPlacementOutcome.cancelled => 'Payment was cancelled.',
      BuyV2OrderPlacementOutcome.failed => 'Payment failed.',
      BuyV2OrderPlacementOutcome.unavailable => 'Ordering is unavailable.',
      BuyV2OrderPlacementOutcome.confirmed => 'Your order is confirmed.',
    },
    purchaseReference: outcome == BuyV2OrderPlacementOutcome.confirmed
        ? 'BUY-SERVER-1'
        : null,
    paymentReference: paymentReference,
    paymentActionUri: paymentActionUri,
    orders: outcome == BuyV2OrderPlacementOutcome.confirmed
        ? [order]
        : const [],
  );
  final adapter = _ShopCommerceAdapter(
    snapshot: BuyV2CommerceSnapshot(
      state: BuyV2CommerceLoadState.ready,
      products: [product],
      addresses: const [address],
      selectedAddressId: address.id,
      paymentMethods: const {'UPI'},
      businessVerificationState: businessVerificationState,
      productReportsAvailable: productReportsAvailable,
      reviewableProductIds: productReviewAvailable ? {product.id} : const {},
    ),
    placement: placement,
  );
  final session = BuyV2Session(
    core: BuySession(),
    productFactsAdapter:
        factsAdapter ?? const BuyV2CatalogueProductFactsAdapter(),
    commerceAdapter: adapter,
    customerStateStore: customerStateStore,
    reviewDataEnabled: false,
  );
  await session.restoreCommerce();
  session.addProduct(product.id);
  session.openCart(scope: BuyV2CartScope.shop);
  session.openCheckout();
  return (session: session, adapter: adapter, product: product, order: order);
}

void main() {
  group('BuyV2Session approved contract', () {
    late BuyV2Session session;

    setUp(() {
      session = BuyV2Session(core: BuySession());
    });

    test('keeps definitive Shop, Wholesale and Medicine taxonomies', () {
      expect(BuyV2Catalogue.shopCategories.length, 35);
      expect(BuyV2Catalogue.wholesaleCategories.length, 35);
      expect(BuyV2Catalogue.medicineCategories.length, 14);
      expect(
        sha256.convert(utf8.encode(buyV2CommerceSeedRows.trim())).toString(),
        'bc099e5a1f27fc033259b94ccd0f4be5d40fedcca96bdc14be38b792ce16c0e0',
      );

      const approvedCommerceIds = <String>[
        'tomato',
        'atta',
        'oil',
        'rice',
        'soap',
        'notebook',
        'onion',
        'milk',
        'bread',
        'eggs',
        'chicken',
        'ghee',
        'turmeric',
        'cumin',
        'poha',
        'oats',
        'noodles',
        'pasta',
        'biscuits',
        'namkeen',
        'tea',
        'juice',
        'peas',
        'ice-cream',
        'toothpaste',
        'shampoo',
        'face-wash',
        'floor-cleaner',
        'toilet-cleaner',
        'detergent',
        'dishwash',
        'diapers',
        'baby-wipes',
        'chyawanprash',
        'protein',
        'dog-food',
        'cat-food',
        'foil',
        'paper-cups',
        'thermal-rolls',
        'price-labels',
        'pencils',
        'banana',
        'potato',
        'curd',
        'paneer',
        'fish-fillet',
        'mutton',
        'toor-dal',
        'sugar',
        'mustard-oil',
        'groundnut-oil',
        'red-chilli',
        'coriander-seeds',
        'corn-flakes',
        'idli-mix',
        'ketchup',
        'jam',
        'potato-chips',
        'chocolate',
        'coffee',
        'water',
        'frozen-fries',
        'cheese-slices',
        'toothbrush',
        'handwash',
        'moisturizer',
        'hair-oil',
        'garbage-bags',
        'air-freshener',
        'fabric-conditioner',
        'liquid-detergent',
        'baby-lotion',
        'baby-cereal',
        'glucose',
        'sanitary-pads',
        'dog-treats',
        'cat-litter',
        'tissues',
        'takeaway-containers',
        'barcode-labels',
        'carry-bags',
        'printer-paper',
        'ball-pens',
      ];
      final shopProducts = BuyV2Catalogue.products
          .where((item) => item.destination == BuyV2Destination.shop)
          .toList();
      final wholesaleProducts = BuyV2Catalogue.products
          .where((item) => item.destination == BuyV2Destination.wholesale)
          .toList();
      expect(shopProducts.map((item) => item.canonicalId), approvedCommerceIds);
      expect(
        wholesaleProducts.map((item) => item.canonicalId),
        approvedCommerceIds,
      );
      for (final canonicalId in approvedCommerceIds) {
        final offers = BuyV2Catalogue.products
            .where((item) => item.canonicalId == canonicalId)
            .toList();
        expect(offers, hasLength(2), reason: canonicalId);
        expect(offers.map((item) => item.destination).toSet(), {
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
        }, reason: canonicalId);
      }

      final identities = BuyV2Catalogue.products
          .map((item) => item.id)
          .toList();
      expect(identities.toSet().length, identities.length);
      expect(
        BuyV2Catalogue.shopCategories
            .skip(1)
            .every(
              (category) => BuyV2Catalogue.products.any(
                (product) =>
                    product.destination == BuyV2Destination.shop &&
                    product.categoryId == category.id,
              ),
            ),
        isTrue,
      );
      expect(
        BuyV2Catalogue.wholesaleCategories
            .skip(1)
            .every(
              (category) => BuyV2Catalogue.products.any(
                (product) =>
                    product.destination == BuyV2Destination.wholesale &&
                    product.categoryId == category.id,
              ),
            ),
        isTrue,
      );
    });

    test('supports Shop, Wholesale and Medicine in one cart', () {
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );

      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct(wholesale.id), isTrue);
      expect(session.addProduct(medicine.id), isTrue);

      expect(session.countForDestination(BuyV2Destination.shop), 1);
      expect(
        session.countForDestination(BuyV2Destination.wholesale),
        wholesale.minimumOrder,
      );
      expect(session.countForDestination(BuyV2Destination.medicine), 1);
      expect(
        session.cartLines.map((line) => line.product.id),
        containsAll([shop.id, wholesale.id, medicine.id]),
      );
    });

    test('maps every Buy offer to a customer-facing partner role', () {
      for (final product in BuyV2Catalogue.products) {
        expect(product.partnerRole, startsWith('Mool '), reason: product.id);
        expect(
          product.partnerRole.toLowerCase(),
          isNot(contains('verified')),
          reason: product.id,
        );
      }
      expect(
        BuyV2Catalogue.products
            .firstWhere((item) => item.destination == BuyV2Destination.medicine)
            .regulatoryTrustFact,
        'Licensed pharmacy',
      );
    });

    test('customer reviews and product reports validate and persist', () {
      final product = BuyV2Catalogue.products.first;
      expect(
        session.submitProductReview(
          productId: product.id,
          rating: 0,
          comment: '',
        ),
        isFalse,
      );
      expect(
        session.submitProductReview(
          productId: product.id,
          rating: 5,
          comment: '  Pack arrived in good condition.  ',
        ),
        isTrue,
      );
      expect(session.customerReviewFor(product.id)?.rating, 5);
      expect(
        session.customerReviewFor(product.id)?.comment,
        'Pack arrived in good condition.',
      );
      expect(
        session.reportProduct(
          productId: product.id,
          reason: 'Product image does not match',
        ),
        isTrue,
      );
      expect(session.hasReportedProduct(product.id), isTrue);
    });

    test('order items retain the exact return depth into product detail', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      expect(session.addProduct(product.id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      final order = session.confirmedOrders.single;

      expect(session.openTracking(order.id), isTrue);
      expect(session.openOrderItems(order.id), isTrue);
      final item = session.productsForOrder(session.selectedOrder).first;

      expect(session.openProduct(item.id), isTrue);
      expect(session.view, BuyV2View.product);
      session.goBack();

      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.orderItems);
      expect(session.selectedOrder.id, order.id);
    });

    test(
      'product continuations are deterministic, local and same-catalogue',
      () {
        final current = BuyV2Catalogue.products.firstWhere((product) {
          if (product.destination != BuyV2Destination.shop) return false;
          return BuyV2Catalogue.products
              .where(
                (candidate) =>
                    candidate.destination == product.destination &&
                    candidate.categoryId == product.categoryId &&
                    candidate.id != product.id,
              )
              .isNotEmpty;
        });

        final first = session.productContinuationsFor(current);
        final second = session.productContinuationsFor(current);

        expect(first, isNotEmpty);
        expect(first, hasLength(6));
        expect(first.map((product) => product.id), second.map((p) => p.id));
        expect(first, everyElement(isNot(same(current))));
        expect(
          first,
          everyElement(
            predicate<BuyV2Product>(
              (product) =>
                  product.destination == current.destination &&
                  product.id != current.id,
            ),
          ),
        );
        expect(first.first.categoryId, current.categoryId);
        expect(session.productContinuationsFor(current, limit: 0), isEmpty);
      },
    );

    test('a product chain retains its original query and return depth', () {
      session.updateQuery('tomato');
      final origin = session.visibleProducts.first;
      expect(session.openProduct(origin.id), isTrue);

      final next = session.productContinuationsFor(origin).first;
      expect(session.openProduct(next.id), isTrue);
      final third = session.productContinuationsFor(next).first;
      expect(session.openProduct(third.id), isTrue);

      expect(session.selectedProductId, third.id);
      session.closeProduct();
      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
      expect(session.query, 'tomato');
      expect(
        session.visibleProducts.map((product) => product.id),
        contains(origin.id),
      );
    });

    test('one saved prescription unlocks only its matched medicine lines', () {
      const telmisartan = 'm-telmisartan-40';
      const atorvastatin = 'm-atorvastatin-10';
      const metformin = 'm-metformin-500';

      expect(session.addProduct(telmisartan), isFalse);
      expect(session.pendingPrescriptionProductId, telmisartan);

      session.approveSavedPrescription('meera');

      expect(session.quantityFor(telmisartan), 1);
      expect(session.addProduct(atorvastatin), isTrue);
      expect(session.addProduct(metformin), isFalse);
      expect(session.pendingPrescriptionProductId, metformin);
    });

    test(
      'unknown saved prescription IDs authorize nothing and preserve retry',
      () {
        const metformin = 'm-metformin-500';
        expect(session.addProduct(metformin), isFalse);
        expect(session.pendingPrescriptionProductId, metformin);

        expect(
          session.approveSavedPrescription('missing-prescription'),
          isFalse,
        );

        expect(session.prescriptionAttached, isFalse);
        expect(session.isPrescriptionApproved(metformin), isFalse);
        expect(session.isPrescriptionApproved('m-pantoprazole-40'), isFalse);
        expect(session.quantityFor(metformin), 0);
        expect(session.pendingPrescriptionProductId, metformin);
        expect(session.notice, 'This saved prescription could not be found.');

        expect(session.approveSavedPrescription('arvind'), isTrue);
        expect(session.prescriptionAttached, isTrue);
        expect(session.pendingPrescriptionProductId, isNull);
        expect(session.quantityFor(metformin), 1);
      },
    );

    test('prescription quantity cannot exceed the approved medicine line', () {
      const telmisartan = 'm-telmisartan-40';
      session.approveSavedPrescription('meera');
      expect(session.addProduct(telmisartan), isTrue);

      session.increase(telmisartan);

      expect(session.quantityFor(telmisartan), 1);
      expect(session.notice, contains('Prescription quantity reached'));
    });

    test('new prescription never authorizes every prescription medicine', () {
      session.attachNewPrescription();
      final approved = BuyV2Catalogue.products
          .where(
            (product) =>
                product.requiresPrescription &&
                session.isPrescriptionApproved(product.id),
          )
          .length;
      final allRx = BuyV2Catalogue.products
          .where((product) => product.requiresPrescription)
          .length;

      expect(approved, greaterThan(0));
      expect(approved, lessThan(allRx));
    });

    test('removing the final item returns directly to its catalogue', () {
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );
      session.openDestination(BuyV2Destination.medicine);
      session.addProduct(medicine.id);
      session.openCart(scope: BuyV2CartScope.medicine);

      session.decrease(medicine.id);

      expect(session.itemCount, 0);
      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.catalogue);
    });

    test('all four Buy destinations remain independent from cart scope', () {
      session.openDestination(BuyV2Destination.wholesale);
      session.openCart(scope: BuyV2CartScope.wholesale);
      session.openDestination(BuyV2Destination.shop);

      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
      expect(BuyV2Destination.values, contains(BuyV2Destination.medicine));
      expect(BuyV2Destination.values, contains(BuyV2Destination.orders));
    });

    test(
      'scope checkout confirms only that family and preserves other cart lines',
      () {
        final shop = BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.shop,
        );
        final wholesale = BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.wholesale,
        );
        session.addProduct(shop.id);
        session.addProduct(wholesale.id);

        session.openCart(scope: BuyV2CartScope.wholesale);
        session.openCheckout();
        session.confirmOrder();

        expect(session.confirmedDestinations, {BuyV2Destination.wholesale});
        expect(session.quantityFor(wholesale.id), 0);
        expect(session.quantityFor(shop.id), 1);
      },
    );

    test(
      'mixed checkout projects exact seller groups into traceable orders',
      () {
        final selected = <BuyV2Product>[
          BuyV2Catalogue.products.firstWhere(
            (item) => item.destination == BuyV2Destination.shop,
          ),
          BuyV2Catalogue.products.firstWhere(
            (item) =>
                item.destination == BuyV2Destination.shop &&
                item.seller !=
                    BuyV2Catalogue.products
                        .firstWhere(
                          (candidate) =>
                              candidate.destination == BuyV2Destination.shop,
                        )
                        .seller,
          ),
          BuyV2Catalogue.products.firstWhere(
            (item) => item.destination == BuyV2Destination.wholesale,
          ),
          BuyV2Catalogue.products.firstWhere(
            (item) =>
                item.destination == BuyV2Destination.medicine &&
                !item.requiresPrescription,
          ),
        ];
        for (final product in selected) {
          expect(session.addProduct(product.id), isTrue);
        }
        session.openCart();
        session.openCheckout();

        final checkoutLines = session.checkoutLines;
        final groups = session.checkoutFulfilmentGroups;
        final checkoutItemCount = session.checkoutItemCount;
        final checkoutTotal = session.checkoutTotal;
        final expectedKeys = checkoutLines
            .map(
              (line) =>
                  '${line.product.destination.name}|${line.product.seller}',
            )
            .toSet();

        expect(
          groups
              .map((group) => '${group.destination.name}|${group.partner}')
              .toSet(),
          expectedKeys,
        );
        expect(
          groups.fold<int>(0, (total, group) => total + group.itemCount),
          checkoutItemCount,
        );
        expect(
          groups.fold<int>(0, (total, group) => total + group.total),
          checkoutTotal,
        );
        for (final group in groups) {
          final expectedLines = checkoutLines
              .where(
                (line) =>
                    line.product.destination == group.destination &&
                    line.product.seller == group.partner,
              )
              .toList();
          expect(
            group.productIds,
            expectedLines.map((line) => line.product.id).toList(),
          );
          expect(
            group.itemCount,
            expectedLines.fold<int>(0, (total, line) => total + line.quantity),
          );
          expect(
            group.total,
            expectedLines.fold<int>(0, (total, line) => total + line.total),
          );
          expect(group.partnerType, expectedLines.first.product.partnerRole);
        }

        session.confirmOrder();

        expect(session.confirmedOrders, hasLength(groups.length));
        expect(
          session.confirmedOrders.map((order) => order.id).toSet(),
          hasLength(groups.length),
        );
        expect(session.confirmedItemCount, checkoutItemCount);
        expect(session.confirmedTotal, checkoutTotal);
        expect(session.itemCount, 0);
        for (final group in groups) {
          final order = session.confirmedOrders.singleWhere(
            (candidate) =>
                candidate.destination == group.destination &&
                candidate.partner == group.partner,
          );
          final prefix = switch (group.destination) {
            BuyV2Destination.shop => 'MS-NEW-',
            BuyV2Destination.wholesale => 'PO-NEW-',
            BuyV2Destination.medicine => 'RX-NEW-',
            BuyV2Destination.orders => 'MS-NEW-',
          };
          expect(order.id, startsWith(prefix));
          expect(order.productIds, group.productIds);
          expect(
            order.lines
                .map((line) => (line.product.id, line.quantity, line.total))
                .toList(),
            group.lines
                .map((line) => (line.product.id, line.quantity, line.total))
                .toList(),
          );
          expect(order.total, group.total);
          expect(order.partnerType, group.partnerType);
          expect(order.paymentMethod, 'UPI');
          expect(order.recipient, session.selectedAddress.recipient);
          expect(order.addressLine, contains(session.selectedAddress.pinCode));
        }
      },
    );

    test(
      'T01C preserves one purchase and exact accepted delivery promises',
      () {
        final adapter = _T01CDeliveryFactsAdapter();
        final quoted = BuyV2Session(
          core: BuySession(),
          productFactsAdapter: adapter,
        );
        addTearDown(quoted.dispose);
        final shop = quoted.product('s-tomato');
        final wholesale = quoted.product('w-oil');
        expect(quoted.addProduct(shop.id), isTrue);
        expect(quoted.addProduct(wholesale.id), isTrue);
        quoted.openCart();
        expect(quoted.openCheckout(), isTrue);

        final checkout = quoted.checkoutFulfilmentGroups;
        expect(checkout, hasLength(2));
        expect(
          checkout.singleWhere((group) => group.destination == .shop).promise,
          'within 5 min',
        );
        expect(
          checkout
              .singleWhere((group) => group.destination == .wholesale)
              .promisedByLabel,
          'by tomorrow 4:00 PM',
        );

        expect(quoted.confirmOrder(), isTrue);
        expect(quoted.confirmedPurchaseId, 'BUY-NEW-01');
        expect(quoted.confirmedOrders, hasLength(2));
        expect(
          quoted.confirmedOrders.map((order) => order.purchaseId).toSet(),
          {'BUY-NEW-01'},
        );
        expect(
          quoted.confirmedOrders
              .singleWhere((order) => order.destination == .shop)
              .promise,
          'within 5 min',
        );
        expect(
          quoted.confirmedOrders
              .singleWhere((order) => order.destination == .wholesale)
              .promisedByLabel,
          'by tomorrow 4:00 PM',
        );
      },
    );

    test('T01C blocks a changed promise until the buyer accepts it', () {
      final adapter = _T01CDeliveryFactsAdapter();
      final quoted = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: adapter,
      );
      addTearDown(quoted.dispose);
      final shop = quoted.product('s-tomato');
      expect(quoted.addProduct(shop.id), isTrue);
      quoted.openCart();
      expect(quoted.openCheckout(), isTrue);

      adapter.update(
        BuyV2Destination.shop,
        promise: 'within 10 min',
        promisedBy: 'by 6:40 PM',
      );
      expect(quoted.confirmOrder(), isFalse);
      expect(quoted.checkoutPromiseReviewRequired, isTrue);
      expect(quoted.itemCount, 1);
      expect(quoted.confirmedOrders, isEmpty);
      expect(quoted.checkoutDeliveryPromiseChanges, hasLength(1));
      final change = quoted.checkoutDeliveryPromiseChanges.single;
      expect(change.previousPromise, 'within 5 min');
      expect(change.currentPromise, 'within 10 min');
      expect(change.previousPromisedByLabel, 'by 6:35 PM');
      expect(change.currentPromisedByLabel, 'by 6:40 PM');

      expect(quoted.acceptCheckoutPromiseChanges(), isTrue);
      expect(quoted.checkoutPromiseReviewRequired, isFalse);
      expect(quoted.confirmOrder(), isTrue);
      expect(quoted.confirmedOrders.single.promise, 'within 10 min');
      expect(quoted.confirmedOrders.single.promisedByLabel, 'by 6:40 PM');
    });

    test('confirmation creates traceable orders and exact reorder lines', () {
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.shop &&
            item.canonicalId == 'onion',
      );
      final secondShop = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.shop &&
            item.id != shop.id &&
            item.seller == shop.seller,
      );
      session.addProduct(shop.id);
      session.addProduct(secondShop.id);
      session.openCart(scope: BuyV2CartScope.shop);
      session.openCheckout();

      session.confirmOrder();

      final confirmed = session.confirmedOrders.single;
      expect(confirmed.id, startsWith('MS-NEW-'));
      expect(confirmed.productIds, {shop.id, secondShop.id});
      expect(session.orders.first.id, confirmed.id);

      session.reorder(confirmed);

      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.shop);
      expect(session.cartLines.map((line) => line.product.id).toSet(), {
        shop.id,
        secondShop.id,
      });
    });

    test(
      'reorder rejects stale or cross-vertical IDs before cart mutation',
      () {
        final medicine = BuyV2Catalogue.products.firstWhere(
          (product) =>
              product.destination == BuyV2Destination.medicine &&
              !product.requiresPrescription,
        );
        final wholesale = BuyV2Catalogue.products.firstWhere(
          (product) => product.destination == BuyV2Destination.wholesale,
        );
        session.addProduct(medicine.id);

        final invalidOrder = BuyV2Order(
          id: 'MS-INVALID',
          destination: BuyV2Destination.shop,
          title: 'Shop order',
          itemSummary: 'Invalid restoration fixture',
          total: wholesale.price,
          partner: wholesale.seller,
          partnerType: wholesale.sellerType,
          promise: wholesale.deliveryPromise,
          destinationLabel: 'Sardarpura · 342003',
          progress: 1,
          status: BuyV2OrderStatus.delivered,
          productIds: [wholesale.id, 'missing-product'],
        );

        expect(session.reorder(invalidOrder), isFalse);

        expect(session.destination, BuyV2Destination.shop);
        expect(session.view, BuyV2View.catalogue);
        expect(session.quantityFor(wholesale.id), 0);
        expect(session.quantityFor(medicine.id), 1);
        expect(session.itemCount, 1);
        expect(session.notice, 'Products from this order could not be found.');
      },
    );

    test('Saved ownership stays independent across Buy verticals', () {
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.wholesale &&
            item.canonicalId == shop.canonicalId,
      );

      expect(session.isSaved(shop.id), isFalse);
      expect(session.isSaved(wholesale.id), isFalse);
      expect(session.savedCountFor(BuyV2Destination.medicine), 0);

      session.toggleSaved(wholesale.id);
      expect(session.isSaved(shop.id), isFalse);
      expect(session.isSaved(wholesale.id), isTrue);

      session.toggleSaved(shop.id);
      expect(session.isSaved(shop.id), isTrue);
      expect(session.isSaved(wholesale.id), isTrue);

      session.toggleSaved(wholesale.id);
      expect(session.isSaved(shop.id), isTrue);
      expect(session.isSaved(wholesale.id), isFalse);
    });

    test('scanned catalogue IDs resolve through production search', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );

      session.updateQuery(product.id);

      expect(session.visibleProducts, hasLength(1));
      expect(session.visibleProducts.single.id, product.id);
    });

    test(
      'search suggestions are read-only, truthful and vertical-specific',
      () {
        for (final destination in const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ]) {
          session.openDestination(destination);
          session.chooseCategory('all');

          final suggestions = session.searchSuggestions;
          expect(suggestions, hasLength(4), reason: destination.name);
          expect(
            () => suggestions.add('Unapproved search'),
            throwsUnsupportedError,
          );

          for (final suggestion in suggestions) {
            expect(
              BuyV2Catalogue.products.any(
                (product) =>
                    product.destination == destination &&
                    product.title == suggestion,
              ),
              isTrue,
              reason: '${destination.name}: $suggestion',
            );
            session.updateQuery(suggestion);
            expect(session.visibleProducts, isNotEmpty);
            expect(
              session.visibleProducts.every(
                (product) => product.destination == destination,
              ),
              isTrue,
              reason: '${destination.name}: $suggestion',
            );
            expect(session.searchSuggestions, isEmpty);
            session.updateQuery('');
          }
        }

        session.openDestination(BuyV2Destination.orders);
        expect(session.searchSuggestions, isEmpty);
      },
    );

    test('every destination filter returns a real matching catalogue', () {
      const filters = {
        BuyV2Destination.shop: ['fast', 'today', 'lowest', 'nearby', 'returns'],
        BuyV2Destination.wholesale: [
          'fast',
          'two-days',
          'lowest',
          'freight',
          'moq',
          'manufacturer',
        ],
        BuyV2Destination.medicine: [
          'fast',
          'today',
          'lowest',
          'otc',
          'nearby',
          'manufacturer',
        ],
      };

      for (final entry in filters.entries) {
        session.openDestination(entry.key);
        session.chooseCategory('all');
        for (final filter in entry.value) {
          session.chooseFilter(filter);
          expect(
            session.visibleProducts,
            isNotEmpty,
            reason: '${entry.key.name} filter $filter',
          );
        }
      }
    });

    test('Buy account returns to the exact originating purchase depth', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      session.openProduct(product.id);

      session.openAccount();
      expect(session.view, BuyV2View.account);

      session.closeAccount();
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, product.id);

      session.openTracking('MS-240782');
      session.openAccount();
      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, 'MS-240782');
    });

    test(
      'Account child journeys return through Account to the exact origin',
      () {
        final origin = BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.medicine,
        );
        session.openProduct(origin.id);
        session.updateQuery('paracetamol');
        session.chooseFilter('Under ₹100');
        session.openAccount();

        session.openOrdersFromAccount();
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(session.canReturnToAccount, isTrue);
        expect(session.query, isEmpty);
        expect(session.selectedFilter, isNull);

        expect(session.openTracking('MS-240782'), isTrue);
        session.goBack();
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(session.canReturnToAccount, isTrue);

        session.goBack();
        expect(session.view, BuyV2View.account);
        expect(session.canReturnToAccount, isFalse);
        expect(session.query, 'paracetamol');
        expect(session.selectedFilter, 'Under ₹100');

        session.openWholesaleFromAccount();
        expect(session.destination, BuyV2Destination.wholesale);
        expect(session.view, BuyV2View.catalogue);
        expect(session.canReturnToAccount, isTrue);
        session.goBack();
        expect(session.view, BuyV2View.account);

        session.closeAccount();
        expect(session.destination, BuyV2Destination.medicine);
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, origin.id);
      },
    );

    test('bottom Orders does not acquire an Account parent', () {
      session.updateQuery('milk');
      session.chooseFilter('Under ₹100');
      session.openOrders();

      expect(session.canReturnToAccount, isFalse);
      expect(session.query, isEmpty);
      expect(session.selectedFilter, isNull);
      session.goBack();
      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
    });

    test('successful cart mutations use a dedicated Cart acknowledgement', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );

      expect(session.addProduct(product.id), isTrue);
      expect(session.notice, isNull);
      expect(session.cartAcknowledgement, '${product.title} added · 1 item');

      session.increase(product.id);
      expect(session.notice, isNull);
      expect(session.cartAcknowledgement, '${product.title} · 2 in cart');

      session.clearCartAcknowledgement();
      expect(session.cartAcknowledgement, isNull);
    });

    test('Buy assist returns to the exact originating purchase depth', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      session.openProduct(product.id);

      session.openAssist();
      expect(session.view, BuyV2View.assist);

      session.closeAssist();
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, product.id);

      session.openTracking('MS-240782');
      session.openAssist();
      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, 'MS-240782');
    });

    test('saved address and payment selections change independently', () {
      session.chooseAddress('work');
      expect(session.selectedAddressId, 'work');
      expect(session.selectedPayment, 'UPI');

      expect(session.choosePayment('Bank transfer'), isTrue);
      expect(session.selectedAddressId, 'work');
      expect(session.selectedPayment, 'Bank transfer');

      session.chooseAddress('home');
      expect(session.selectedAddressId, 'home');
      expect(session.selectedPayment, 'Bank transfer');
    });

    test('saved address update preserves identity count and selection', () {
      final before = session.addresses.length;
      final home = session.addresses.firstWhere(
        (address) => address.id == 'home',
      );
      session.chooseAddress('work');

      expect(
        session.updateAddress(
          BuyV2Address(
            id: home.id,
            kind: home.kind,
            label: home.label,
            recipient: 'Asha Verma',
            phone: home.phone,
            line: home.line,
            area: home.area,
            pinCode: home.pinCode,
            landmark: home.landmark,
          ),
        ),
        isTrue,
      );

      expect(session.addresses.length, before);
      expect(session.selectedAddressId, 'work');
      expect(
        session.addresses
            .firstWhere((address) => address.id == 'home')
            .recipient,
        'Asha Verma',
      );
      expect(session.notice, 'Home address updated');
    });

    test('stale saved address update fails without mutation', () {
      final beforeIds = session.addresses.map((address) => address.id).toList();

      expect(
        session.updateAddress(
          const BuyV2Address(
            id: 'missing-address',
            kind: BuyV2AddressKind.other,
            label: 'Other place',
            recipient: 'Meera Sharma',
            phone: '9876543210',
            line: '12 Market Road',
            area: 'Jodhpur',
            pinCode: '342001',
            landmark: 'No nearby landmark',
          ),
        ),
        isFalse,
      );

      expect(session.addresses.map((address) => address.id), beforeIds);
      expect(session.notice, 'This saved address is no longer available.');
    });

    test('unsupported payment identifiers fail closed', () {
      session.chooseAddress('work');
      expect(session.choosePayment('Purchase order'), isTrue);

      expect(session.choosePayment('Card<script>'), isFalse);

      expect(session.selectedAddressId, 'work');
      expect(session.selectedPayment, 'Purchase order');
      expect(session.notice, 'This payment method is not available.');
      expect(BuyV2Session.paymentMethods, {
        'UPI',
        'Bank transfer',
        'Purchase order',
      });
    });

    test('Orders search filters only the current order tab', () {
      session.openDestination(BuyV2Destination.orders);

      session.updateQuery('MS-240782');
      expect(session.visibleOrders.map((order) => order.id), ['MS-240782']);

      session.updateQuery('sardarpura');
      expect(session.visibleOrders, isNotEmpty);
      expect(
        session.visibleOrders.every(
          (order) =>
              '${order.id} ${order.title} ${order.partner} '
                      '${order.partnerType} ${order.itemSummary}'
                  .toLowerCase()
                  .contains('sardarpura'),
        ),
        isTrue,
      );

      session.updateQuery('MS-240782');
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      expect(session.visibleOrders, isEmpty);

      session.updateQuery('');
      expect(
        session.visibleOrders.every(
          (order) => order.status == BuyV2OrderStatus.delivered,
        ),
        isTrue,
      );
    });

    test(
      'unknown external identifiers fail closed without substituting data',
      () {
        final firstProduct = BuyV2Catalogue.products.first;
        final firstProductWasSaved = session.isSaved(firstProduct.id);

        expect(session.openProduct('missing-product'), isFalse);
        expect(session.view, BuyV2View.catalogue);
        expect(session.selectedProductId, isNull);
        expect(session.notice, 'This product could not be found.');

        expect(session.addProduct('missing-product'), isFalse);
        expect(session.itemCount, 0);
        expect(session.quantityFor(firstProduct.id), 0);

        session.toggleSaved('missing-product');
        expect(session.isSaved('missing-product'), isFalse);
        expect(session.isSaved(firstProduct.id), firstProductWasSaved);

        expect(session.openTracking('missing-order'), isFalse);
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(session.selectedOrderId, isNull);
        expect(session.notice, 'This order could not be found.');

        session.chooseAddress('work');
        expect(session.chooseAddress('missing-address'), isFalse);
        expect(session.selectedAddressId, 'work');
        expect(session.notice, 'This saved address could not be found.');
      },
    );

    test(
      'normal runtime starts with no review commerce or customer data',
      () async {
        final production = BuyV2Session(
          core: BuySession(),
          reviewDataEnabled: false,
        );

        expect(production.visibleProducts, isEmpty);
        expect(production.addresses, isEmpty);
        expect(production.orders, isEmpty);
        expect(production.businessVerified, isFalse);
        expect(production.availablePaymentMethods, isEmpty);

        await production.restoreCommerce();

        expect(
          production.commerceLoadState,
          BuyV2CommerceLoadState.unavailable,
        );
        expect(production.confirmOrder(), isFalse);
        expect(production.view, isNot(BuyV2View.confirmation));
        expect(
          production.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.unavailable,
        );
      },
    );

    test(
      'authoritative commerce snapshot and order result own production success',
      () async {
        final product = BuyV2Catalogue.products.firstWhere(
          (candidate) => candidate.destination == BuyV2Destination.shop,
        );
        const address = BuyV2Address(
          id: 'server-home',
          kind: BuyV2AddressKind.home,
          label: 'Home',
          recipient: 'Aarav Sharma',
          phone: '9000000000',
          line: '12, Central Avenue',
          area: 'Sardarpura, Jodhpur',
          pinCode: '342003',
          landmark: 'Near the market',
        );
        final order = BuyV2Order(
          id: 'MS-SERVER-1',
          destination: BuyV2Destination.shop,
          title: 'Shop order',
          itemSummary: '1 product',
          total: product.price,
          partner: product.seller,
          partnerType: product.partnerRole,
          promise: product.deliveryPromise,
          destinationLabel: address.shortLine,
          progress: .2,
          status: BuyV2OrderStatus.preparing,
          purchaseId: 'BUY-SERVER-1',
          productIds: [product.id],
          lines: [BuyV2CartLine(product: product, quantity: 1)],
          paymentMethod: 'UPI',
        );
        final adapter = _ShopCommerceAdapter(
          snapshot: BuyV2CommerceSnapshot(
            state: BuyV2CommerceLoadState.ready,
            products: [product],
            addresses: const [address],
            selectedAddressId: address.id,
            paymentMethods: const {'UPI'},
          ),
          placement: BuyV2OrderPlacementResult(
            outcome: BuyV2OrderPlacementOutcome.confirmed,
            customerMessage: 'Your order is confirmed.',
            purchaseReference: 'BUY-SERVER-1',
            orders: [order],
          ),
        );
        final production = BuyV2Session(
          core: BuySession(),
          commerceAdapter: adapter,
          reviewDataEnabled: false,
        );

        await production.restoreCommerce();
        expect(production.addProduct(product.id), isTrue);
        production.openCart(scope: BuyV2CartScope.shop);
        expect(production.openCheckout(), isTrue);

        expect(await production.submitOrder(), isTrue);
        expect(adapter.placementCalls, 1);
        expect(production.view, BuyV2View.confirmation);
        expect(production.confirmedOrders.single.id, order.id);
        expect(production.itemCount, 0);
      },
    );

    test(
      'customer state restores cart address saved and payment choices',
      () async {
        final store = _MemoryCustomerStateStore('account-1');
        final first = BuyV2Session(
          core: BuySession(),
          customerStateStore: store,
        );
        final product = first.visibleProducts.first;
        first.addProduct(product.id);
        first.toggleSaved(product.id);
        first.addAddress(
          const BuyV2Address(
            id: 'family',
            kind: BuyV2AddressKind.thirdParty,
            label: 'Third party',
            recipient: 'Family recipient',
            phone: '9000000001',
            line: '21, Market Road',
            area: 'Ratanada, Jodhpur',
            pinCode: '342011',
            landmark: 'Near the park',
          ),
        );
        first.choosePayment('Bank transfer');
        await Future<void>.delayed(Duration.zero);

        final restored = BuyV2Session(
          core: BuySession(),
          customerStateStore: store,
        );
        await restored.restoreCustomerState();

        expect(restored.quantityFor(product.id), product.minimumOrder);
        expect(restored.isSaved(product.id), isTrue);
        expect(restored.selectedAddressId, 'family');
        expect(restored.selectedPayment, 'Bank transfer');
      },
    );

    test(
      'payment handoff locks one attempt and reconciliation confirms once',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.paymentActionRequired,
          paymentActionUri: Uri.parse('upi://pay?pa=merchant@mool'),
          paymentReference: 'PAY-1',
        );
        addTearDown(fixture.session.dispose);

        expect(await fixture.session.submitOrder(), isFalse);
        expect(
          fixture.session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentActionRequired,
        );
        final idempotencyKey = fixture.session.checkoutIdempotencyKey;
        expect(idempotencyKey, isNotEmpty);
        expect(await fixture.session.submitOrder(), isFalse);
        expect(fixture.adapter.placementCalls, 1);
        fixture.session.increase(fixture.product.id);
        expect(fixture.session.quantityFor(fixture.product.id), 1);

        Uri? openedUri;
        expect(
          await fixture.session.continuePayment((uri) async {
            openedUri = uri;
            return true;
          }),
          isTrue,
        );
        expect(openedUri, Uri.parse('upi://pay?pa=merchant@mool'));
        expect(
          fixture.session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentPending,
        );

        fixture.adapter.reconciliation = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          customerMessage: 'Your order is confirmed.',
          purchaseReference: 'BUY-SERVER-1',
          paymentReference: 'PAY-1',
          orders: [fixture.order],
        );
        expect(await fixture.session.reconcilePayment(), isTrue);
        expect(fixture.adapter.reconciliationCalls, 1);
        expect(fixture.session.view, BuyV2View.confirmation);
        expect(fixture.session.confirmedOrders.single.id, 'MS-SERVER-1');
        expect(fixture.session.checkoutIdempotencyKey, isNull);
      },
    );

    test(
      'failed retry reuses its idempotency key and cannot duplicate',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
        );
        addTearDown(fixture.session.dispose);

        expect(await fixture.session.submitOrder(), isFalse);
        final firstKey = fixture.adapter.requests.single.idempotencyKey;
        fixture.adapter.placement = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          customerMessage: 'Your order is confirmed.',
          purchaseReference: 'BUY-SERVER-1',
          orders: [fixture.order],
        );

        expect(await fixture.session.submitOrder(), isTrue);
        expect(fixture.adapter.requests, hasLength(2));
        expect(fixture.adapter.requests.last.idempotencyKey, firstKey);
        expect(fixture.session.confirmedOrders, hasLength(1));
      },
    );

    test(
      'cancelled payment creates a new attempt only after customer retry',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.cancelled,
        );
        addTearDown(fixture.session.dispose);

        expect(await fixture.session.submitOrder(), isFalse);
        final cancelledKey = fixture.adapter.requests.single.idempotencyKey;
        expect(fixture.session.checkoutIdempotencyKey, isNull);
        expect(
          fixture.session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.cancelled,
        );
        fixture.adapter.placement = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          customerMessage: 'Your order is confirmed.',
          purchaseReference: 'BUY-SERVER-1',
          orders: [fixture.order],
        );

        expect(await fixture.session.submitOrder(), isTrue);
        expect(
          fixture.adapter.requests.last.idempotencyKey,
          isNot(cancelledKey),
        );
      },
    );

    test(
      'price change updates the Cart and requires explicit acceptance',
      () async {
        final facts = _MutableCommerceFactsAdapter();
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          factsAdapter: facts,
        );
        addTearDown(fixture.session.dispose);
        facts.price = fixture.product.price + 12;

        expect(await fixture.session.submitOrder(), isFalse);
        expect(fixture.adapter.placementCalls, 0);
        expect(fixture.session.checkoutPriceReviewRequired, isTrue);
        expect(
          fixture.session.checkoutPriceChanges.single.previousPrice,
          fixture.product.price,
        );
        expect(
          fixture.session.checkoutPayableTotal,
          fixture.product.price + 12,
        );

        fixture.session.acceptCheckoutPriceChanges();
        expect(await fixture.session.submitOrder(), isTrue);
        expect(fixture.adapter.placementCalls, 1);
      },
    );

    test('pending payment survives restart and keeps the Cart locked', () async {
      final store = _MemoryCustomerStateStore('account-payment');
      final fixture = await _openProductionCheckout(
        outcome: BuyV2OrderPlacementOutcome.paymentPending,
        paymentReference: 'PAY-RESTORE-1',
        customerStateStore: store,
      );
      addTearDown(fixture.session.dispose);

      expect(await fixture.session.submitOrder(), isFalse);
      await Future<void>.delayed(Duration.zero);
      final restored = BuyV2Session(
        core: BuySession(),
        commerceAdapter: fixture.adapter,
        customerStateStore: store,
        reviewDataEnabled: false,
      );
      addTearDown(restored.dispose);
      await restored.restoreCommerce();
      await restored.restoreCustomerState();
      restored.openCart(scope: BuyV2CartScope.shop);
      restored.openCheckout();

      expect(
        restored.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.paymentPending,
      );
      final quantity = restored.quantityFor(fixture.product.id);
      restored.increase(fixture.product.id);
      expect(restored.quantityFor(fixture.product.id), quantity);
      expect(
        restored.notice,
        'Check the current payment before changing your Cart or payment method.',
      );
    });

    test(
      'verified purchase review and product report require real acceptance',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
          productReportsAvailable: true,
          productReviewAvailable: true,
        );
        addTearDown(fixture.session.dispose);

        expect(
          await fixture.session.submitProductReviewOnline(
            productId: fixture.product.id,
            rating: 5,
            comment: 'Fresh and packed carefully.',
          ),
          isTrue,
        );
        expect(fixture.adapter.reviewCalls, 1);
        expect(
          fixture.session.customerReviewFor(fixture.product.id)?.rating,
          5,
        );
        expect(
          await fixture.session.reportProductOnline(
            productId: fixture.product.id,
            reason: 'Product information is incorrect',
          ),
          isTrue,
        );
        expect(fixture.adapter.reportCalls, 1);
        expect(fixture.session.hasReportedProduct(fixture.product.id), isTrue);
      },
    );

    test(
      'ineligible or rejected feedback never records local success',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
          productReportsAvailable: true,
        );
        addTearDown(fixture.session.dispose);

        expect(
          await fixture.session.submitProductReviewOnline(
            productId: fixture.product.id,
            rating: 4,
            comment: 'Useful product.',
          ),
          isFalse,
        );
        expect(fixture.adapter.reviewCalls, 0);
        fixture.adapter.reportResult = const BuyV2MutationResult(
          accepted: false,
          customerMessage: 'This report could not be sent. Try again.',
        );
        expect(
          await fixture.session.reportProductOnline(
            productId: fixture.product.id,
            reason: 'Product image does not match',
          ),
          isFalse,
        );
        expect(fixture.adapter.reportCalls, 1);
        expect(fixture.session.hasReportedProduct(fixture.product.id), isFalse);
        expect(
          fixture.session.notice,
          'This report could not be sent. Try again.',
        );
      },
    );

    test(
      'Workspace verification status remains authoritative for Wholesale',
      () async {
        for (final state in const [
          BuyV2BusinessVerificationState.pending,
          BuyV2BusinessVerificationState.rejected,
          BuyV2BusinessVerificationState.unavailable,
        ]) {
          final fixture = await _openProductionCheckout(
            outcome: BuyV2OrderPlacementOutcome.failed,
            businessVerificationState: state,
          );
          addTearDown(fixture.session.dispose);
          expect(fixture.session.businessVerified, isFalse);
          expect(fixture.session.businessVerificationState, state);
        }
      },
    );

    test(
      'order refresh accepts exact identity and preserves last known failure',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
        );
        addTearDown(fixture.session.dispose);
        expect(await fixture.session.submitOrder(), isTrue);
        final updated = BuyV2Order(
          id: fixture.order.id,
          destination: fixture.order.destination,
          title: fixture.order.title,
          itemSummary: fixture.order.itemSummary,
          total: fixture.order.total,
          partner: fixture.order.partner,
          partnerType: fixture.order.partnerType,
          promise: 'Arriving today by 6:30 pm',
          destinationLabel: fixture.order.destinationLabel,
          progress: .8,
          status: BuyV2OrderStatus.arriving,
          purchaseId: fixture.order.purchaseId,
          productIds: fixture.order.productIds,
          lines: fixture.order.lines,
          paymentMethod: fixture.order.paymentMethod,
          invoiceAvailable: false,
          receiptReference: 'PAY-RECEIPT-1',
        );
        fixture.adapter.orderRefreshResult = BuyV2OrderRefreshResult(
          state: BuyV2CommerceLoadState.ready,
          customerMessage: 'Order updated.',
          order: updated,
        );

        expect(await fixture.session.refreshOrder(fixture.order.id), isTrue);
        expect(fixture.adapter.orderRefreshCalls, 1);
        expect(fixture.session.orders.first.promise, updated.promise);
        expect(fixture.session.orders.first.invoiceAvailable, isFalse);

        fixture.adapter.orderRefreshResult = BuyV2OrderRefreshResult(
          state: BuyV2CommerceLoadState.ready,
          customerMessage: 'Order identity could not be verified.',
          order: BuyV2Order(
            id: 'OTHER-ORDER',
            destination: updated.destination,
            title: updated.title,
            itemSummary: updated.itemSummary,
            total: updated.total,
            partner: updated.partner,
            partnerType: updated.partnerType,
            promise: 'Different promise',
            destinationLabel: updated.destinationLabel,
            progress: .9,
            status: BuyV2OrderStatus.arriving,
          ),
        );
        expect(await fixture.session.refreshOrder(fixture.order.id), isFalse);
        expect(fixture.session.orders.first.promise, updated.promise);
        expect(
          fixture.session.orderRefreshMessage(fixture.order.id),
          'Order identity could not be verified.',
        );
      },
    );

    test(
      'order alerts change only after authoritative acknowledgement',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
        );
        addTearDown(fixture.session.dispose);

        await fixture.session.restoreOrderAlerts();
        expect(fixture.session.trackingAlertsAvailable, isTrue);
        expect(fixture.session.trackingAlertsEnabled, isFalse);

        expect(await fixture.session.setTrackingAlerts(true), isTrue);
        expect(fixture.session.trackingAlertsEnabled, isTrue);

        fixture.adapter.alertsResult = const BuyV2OrderAlertsResult(
          available: false,
          enabled: false,
          customerMessage: 'Order alerts are unavailable right now.',
        );
        await fixture.session.restoreOrderAlerts();
        expect(fixture.session.trackingAlertsAvailable, isFalse);
        expect(fixture.session.trackingAlertsEnabled, isFalse);
      },
    );
  });
}
