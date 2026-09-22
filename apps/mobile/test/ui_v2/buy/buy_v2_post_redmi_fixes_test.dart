import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_customer_copy.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart'
    show BuyV2ProductPackshot, buyV2DeliveryPromiseSummary;
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

class _EligibilityFacts implements BuyV2ProductFactsAdapter {
  BuyV2OfferEligibility? eligibility;
  bool invalid = false;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      const BuyV2CatalogueProductFactsAdapter()
          .snapshotFor(product)
          .copyWith(
            eligibility: eligibility,
            sourceId: invalid ? '' : 'eligibility-test-facts',
          );
}

void main() {
  testWidgets(
    'pickup sign-in Android Back returns to exact checkout and preserves Cart',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Jodhpur',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(),
        allowGuestReady: true,
      );
      await journey.start();
      addTearDown(journey.dispose);
      await tester.pumpWidget(
        MoolSocialApp(
          key: UniqueKey(),
          session: journey,
          initialLocation: '/app/buy',
        ),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<BuyV2Screen>(find.byType(BuyV2Screen))
          .session;
      expect(session.addProduct('s-tomato'), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.chooseCheckoutCollection(true), isTrue);
      await tester.pumpAndSettle();
      final signIn = find.byKey(
        const ValueKey('buy-checkout-collection-sign-in'),
      );
      await tester.ensureVisible(signIn);
      await tester.tap(signIn);
      await tester.pumpAndSettle();
      final security = find.byKey(const Key('global-security-v2'));
      final uri = GoRouterState.of(tester.element(security)).uri;
      expect(
        Uri.parse(uri.queryParameters['return']!).queryParameters['view'],
        'checkout',
      );
      await tester.tap(find.byKey(const Key('global-security-sign-in')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen03-login-v5')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(security, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.checkout);
      expect(session.checkoutScope, BuyV2CartScope.shop);
      expect(session.collectionCheckoutSelected, isTrue);
      expect(session.quantityFor('s-tomato'), 1);
      expect(
        find.byKey(const ValueKey('buy-checkout-collection-sign-in')),
        findsOneWidget,
      );
      expect(journey.isAuthenticated, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  group('explicit frontend eligibility v1', () {
    final now = DateTime.utc(2026, 9, 22, 10);
    final product = BuyV2Catalogue.products.first.copyWith(storeId: 'store-1');
    Map<String, dynamic> payload() => {
      'schemaVersion': 1,
      'productId': product.id,
      'storeId': 'store-1',
      'sourceRevision': 'store-contract-test-v1',
      'customerLocationKey': 'place|1',
      'observedAt': now.subtract(const Duration(minutes: 1)).toIso8601String(),
      'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
      'offerClass': 'retail',
      'channelEnabled': true,
      'storeReady': true,
      'fleetAvailable': true,
      'customerLocationConfirmed': true,
      'options': ['quick', 'scheduled', 'courier'],
      'scheduledSlotId': 'slot-1',
      'scheduledStart': now.add(const Duration(hours: 1)).toIso8601String(),
      'scheduledEnd': now.add(const Duration(hours: 2)).toIso8601String(),
      'reviewFixture': false,
    };
    Set<BuyV2DeliveryOption> resolve(
      Map<String, dynamic> json, {
      String location = 'place|1',
      DateTime? at,
      BuyV2Product? item,
    }) =>
        BuyV2OfferEligibility.fromJson(json)?.availableFor(
          product: item ?? product,
          locationKey: location,
          now: at ?? now,
        ) ??
        {};

    test(
      'multiple options roundtrip with exact identities and explicit slot',
      () {
        final contract = BuyV2OfferEligibility.fromJson(payload())!;
        expect(
          contract.toJson(),
          payload()..['options'] = ['courier', 'quick', 'scheduled'],
        );
        expect(
          resolve(payload()),
          containsAll([
            BuyV2DeliveryOption.quick,
            BuyV2DeliveryOption.scheduled,
            BuyV2DeliveryOption.courier,
          ]),
        );
        expect(
          () => contract.options.add(BuyV2DeliveryOption.freight),
          throwsUnsupportedError,
        );
      },
    );
    for (final field in ['channelEnabled', 'storeReady']) {
      test('$field false denies all channels', () {
        expect(resolve(payload()..[field] = false), isEmpty);
      });
    }
    test(
      'fleet unavailable denies Quick and Scheduled but preserves courier',
      () {
        expect(resolve(payload()..['fleetAvailable'] = false), {
          BuyV2DeliveryOption.courier,
        });
      },
    );
    for (final field in ['scheduledSlotId', 'scheduledStart', 'scheduledEnd']) {
      test('missing $field never turns courier into Scheduled', () {
        expect(
          resolve(payload()..remove(field)),
          isNot(contains(BuyV2DeliveryOption.scheduled)),
        );
      });
    }
    test(
      'unconfirmed location denies Quick and Scheduled independently of fleet',
      () {
        expect(resolve(payload()..['customerLocationConfirmed'] = false), {
          BuyV2DeliveryOption.courier,
        });
      },
    );
    test('expiry boundary and changed location fail closed', () {
      expect(
        resolve(payload(), at: now.add(const Duration(minutes: 5))),
        isEmpty,
      );
      expect(resolve(payload(), location: 'place|2'), isEmpty);
      expect(
        resolve(
          payload()
            ..['observedAt'] = now
                .add(const Duration(seconds: 1))
                .toIso8601String(),
        ),
        isEmpty,
      );
    });
    test('wrong identity and class cannot grant eligibility', () {
      for (final field in ['productId', 'storeId', 'sourceRevision']) {
        expect(resolve(payload()..[field] = ''), isEmpty);
      }
      expect(resolve(payload()..['offerClass'] = 'bulk'), isEmpty);
    });
    test('review responses are excluded by default', () {
      expect(resolve(payload()..['reviewFixture'] = true), isEmpty);
    });
    test('unknown schema and incomplete payloads never get defaults', () {
      for (final field in [
        'schemaVersion',
        'options',
        'offerClass',
        'expiresAt',
        'fleetAvailable',
      ]) {
        expect(
          BuyV2OfferEligibility.fromJson(payload()..remove(field)),
          isNull,
        );
      }
      expect(
        BuyV2OfferEligibility.fromJson(payload()..['options'] = ['teleport']),
        isNull,
      );
      expect(
        BuyV2OfferEligibility.fromJson(payload()..['schemaVersion'] = 2),
        isNull,
      );
    });
    test(
      'MOQ and copy changes do not change grants or offer classification',
      () {
        final changed = product.copyWith(
          minimumOrder: 400,
          deliveryPromise: '20 minutes',
        );
        expect(changed.offerClass, BuyV2OfferClass.retail);
        expect(resolve(payload(), item: changed), resolve(payload()));
        final wholesale = product.copyWith(
          offerClass: BuyV2OfferClass.wholesale,
          minimumOrder: 100,
        );
        final bulk = product.copyWith(
          offerClass: BuyV2OfferClass.bulk,
          minimumOrder: 1,
        );
        expect(wholesale.offerClass, BuyV2OfferClass.wholesale);
        expect(bulk.offerClass, BuyV2OfferClass.bulk);
        expect(
          buyV2CatalogueFulfilmentModeFor(
            product.copyWith(
              deliveryPromise: '20 minutes',
              reviewDeliveryOptions: {},
            ),
          ),
          isNot(BuyV2FulfilmentMode.quickLocal),
        );
      },
    );
    test('pagination identity changes within the same region', () {
      BuyV2CatalogueQuery query(String location) => BuyV2CatalogueQuery(
        destination: BuyV2Destination.shop,
        regionId: 'jodhpur',
        customerLocationKey: location,
      );
      expect(query('place|1'), isNot(query('place|2')));
    });
    test('production missing eligibility keeps Cart unchanged', () async {
      final core = BuySession();
      final source = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
      );
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: false,
        cataloguePageSource: source,
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final id = source.productIdAt(0, 0);
      expect(await session.openLinkedProduct(id), isTrue);
      expect(session.deliveryOptionsFor(session.product(id)), isEmpty);
      expect(session.addProduct(id), isFalse);
      expect(session.cartLines, isEmpty);
    });
  });

  test(
    'eligibility expiry and location changes invalidate Saved, Add and checkout without losing Cart',
    () async {
      var clock = DateTime.utc(2026, 9, 22, 10);
      final core = BuySession();
      final facts = _EligibilityFacts();
      final source = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
      );
      final session = BuyV2Session(
        core: core,
        cataloguePageSource: source,
        productFactsAdapter: facts,
        catalogueNow: () => clock,
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final id = source.productIdAt(0, 0);
      expect(await session.openLinkedProduct(id), isTrue);
      final product = session.product(id);
      facts.eligibility = BuyV2OfferEligibility(
        productId: id,
        storeId: product.storeId!,
        sourceRevision: 'test-v1',
        customerLocationKey: session.eligibilityLocationKey,
        observedAt: clock,
        expiresAt: clock.add(const Duration(minutes: 5)),
        offerClass: product.offerClass!,
        channelEnabled: true,
        storeReady: true,
        fleetAvailable: true,
        customerLocationConfirmed: true,
        options: {BuyV2DeliveryOption.quick, BuyV2DeliveryOption.scheduled},
        scheduledSlotId: 'test-slot',
        scheduledStart: clock.add(const Duration(hours: 1)),
        scheduledEnd: clock.add(const Duration(hours: 2)),
        reviewFixture: true,
      );
      session.refreshProductFacts(id);
      session.toggleSaved(id);
      expect(session.visibleSavedProducts.map((p) => p.id), contains(id));
      session.chooseShopSaleType(BuyV2ShopSaleType.courier);
      expect(session.visibleSavedProducts.map((p) => p.id), contains(id));
      expect(session.addProduct(id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      final quantity = session.quantityFor(id);
      facts.invalid = true;
      expect(session.refreshProductFacts(id), isFalse);
      expect(session.deliveryOptionsFor(product), isEmpty);
      expect(session.addProduct(id), isFalse);
      expect(session.quantityFor(id), quantity);
      facts.invalid = false;
      expect(session.refreshProductFacts(id), isTrue);
      expect(
        session.deliveryOptionsFor(product),
        contains(BuyV2DeliveryOption.quick),
      );
      clock = clock.add(const Duration(minutes: 5));
      expect(
        session.visibleSavedProducts.map((p) => p.id),
        isNot(contains(id)),
      );
      expect(session.addProduct(id), isFalse);
      expect(session.continueCheckoutFromAddress(), isFalse);
      expect(session.confirmOrder(), isFalse);
      expect(session.quantityFor(id), quantity);
      clock = clock.subtract(const Duration(minutes: 5));
      final query = session.catalogueQuery();
      session.chooseCatalogueArea(null, BuyV2CatalogueAreaScope.allAreas);
      expect(session.catalogueQuery(), isNot(query));
      expect(session.deliveryOptionsFor(product), isEmpty);
      expect(session.addProduct(id), isFalse);
      expect(session.quantityFor(id), quantity);
    },
  );

  test(
    'active estimate normalizes delivered suffix without changing deadline',
    () {
      expect(
        buyV2DeliveryPromiseSummary(
          promise: 'Delivery today by 8:00 pm',
          promisedByLabel: 'Delivered in 30 min',
        ),
        'Delivery today by 8:00 pm · Delivery in 30 min',
      );
    },
  );
  test('group names require one exact Store identity', () {
    final product = BuyV2Catalogue.products.first.copyWith(
      storeId: 'buy-catalogue-dev-v1-shop-store-000001',
    );
    final group = BuyV2FulfilmentGroup(
      groupKey: 'test',
      destination: BuyV2Destination.shop,
      partner: 'Mool Market 000001',
      partnerType: 'Retailer',
      promise: '',
      lines: [BuyV2CartLine(product: product, quantity: 1)],
    );
    expect(group.customerPartner, 'Mool Market 1');
    expect(
      buyV2CustomerStoreName('Store 000001', product.storeId),
      'Store 000001',
    );
    expect(
      buyV2CustomerStoreName('Mool Market 000001', 'real-store'),
      'Mool Market 000001',
    );
  });

  test('historical line prices never replace current Reorder prices', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final current = session.product('s-tomato');
    final old = current.copyWith(price: 1);
    final order = BuyV2Order(
      id: 'historical-price-check',
      destination: current.destination,
      title: 'Previous purchase',
      itemSummary: '2 items',
      total: 2,
      partner: current.seller,
      partnerType: current.sellerType,
      promise: 'Delivered',
      destinationLabel: 'Home',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
      productIds: [current.id],
      lines: [BuyV2CartLine(product: old, quantity: 2)],
    );
    expect(session.productsForOrder(order).single.price, current.price);
    expect(session.reorder(order), isTrue);
    expect(session.cartLines.single.product.price, current.price);
    expect(order.lines.single.total, 2);
  });

  test(
    'Store search uses displayed name and recommendations keep exact seller',
    () async {
      final core = BuySession();
      final source = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
      );
      final session = BuyV2Session(
        core: core,
        cataloguePageSource: source,
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final page = await source.loadStores(
        session.catalogueQuery(search: 'Mool Market 1'),
        pageSize: 40,
      );
      expect(
        page.items.map((store) => store.id),
        contains(source.storeIdAt(0)),
      );
      final first = source.productIdAt(0, 0);
      final second = source.productIdAt(0, 1);
      final outside = source.productIdAt(10, 1);
      for (final id in [first, second, outside]) {
        expect(await session.openLinkedProduct(id), isTrue);
      }
      final products = session.productContinuationsFor(session.product(first));
      expect(products.map((item) => item.id), contains(second));
      expect(
        products.every((item) => item.storeId == source.storeIdAt(0)),
        isTrue,
      );
      session.toggleSaved(first);
      expect(session.notice, '${session.product(first).customerTitle} saved.');
      final media = BuyV2ProductPackshot.resolveMedia(session.product(first));
      final templateMedia = BuyV2ProductPackshot.resolveMedia(
        session.product('s-tomato'),
      );
      expect(media?.assetPath, templateMedia?.assetPath);
      expect(media?.cell, templateMedia?.cell);
    },
  );

  testWidgets(
    'publisher selection restores honestly and All clears MoolSocial',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.featuredOffersMoolSocial = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => r66VisualCaptureRoot(child!),
          home: Scaffold(
            body: BuyV2OffersView(
              session: session,
              source: const BuyV2CataloguePublishedOffersSource(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching offers'), findsOneWidget);
      expect(find.byType(BuyV2ProductCard), findsNothing);
      await tester.tap(find.byKey(const ValueKey('buy-offers-filter')));
      await tester.pumpAndSettle();
      final mool = find.byKey(const ValueKey('buy-offer-filter-moolSocial'));
      expect(mool.hitTestable(), findsOneWidget);
      expect(tester.getRect(mool).bottom, lessThanOrEqualTo(752));
      await captureR66Visual(tester, 'post-redmi-publisher-inset');
      await tester.tap(find.byKey(const ValueKey('buy-offer-filter-all')));
      await tester.pumpAndSettle();
      expect(session.featuredOffersMoolSocial, isFalse);
      expect(find.byType(BuyV2ProductCard), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Saved retains query and excludes products outside Wholesale sale type',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.destination = BuyV2Destination.wholesale;
      final product = session.product('w-tomato');
      session.toggleSaved(product.id);
      session.updateQuery('tomato');
      session.showSavedProducts(true);
      expect(session.query, 'tomato');
      expect(
        session.visibleSavedProducts.map((item) => item.id),
        contains(product.id),
      );
      session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
      expect(
        session.visibleSavedProducts.map((item) => item.id),
        isNot(contains(product.id)),
      );
      session.showSavedProducts(false);
      expect(session.query, 'tomato');
    },
  );

  test(
    'Orders recommendation Back copy names the actual return destination',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.openOrders();
      session.openProduct('s-tomato');
      expect(session.productReturnLabel, 'Orders');
      session.closeProduct();
      expect(session.destination, BuyV2Destination.orders);
    },
  );

  test('customer copy preserves genuine product numbers', () {
    final product = BuyV2Catalogue.products.first;
    expect(product.customerTitle, product.title);
    expect(product.customerSeller('Store 007'), 'Store 007');
  });

  testWidgets(
    'ordered quantity and amount are visible from the recorded lines',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-tomato');
      session.addProduct('s-tomato');
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      final order = session.confirmedOrders.single;
      expect(order.lines.single.quantity, 2);
      session.openOrderItems(order.id);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BuyV2OrderItemsView(session: session)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2 × 500 g'), findsOneWidget);
      expect(find.textContaining('₹74'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
