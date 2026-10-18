import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/chat/chat_entry_context.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_chat_route_adapter.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_shop_chat.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

class _DraftAttachmentPicker implements ChatAttachmentPicker {
  @override
  Future<ChatPickedAttachment?> pick(ChatAttachmentKind kind) async => ChatPickedAttachment(
      kind: kind, name: 'host-only-draft.pdf', contentType: 'application/pdf', bytes: Uint8List.fromList([1, 2, 3]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Batch02 Store Chat isolates same-name Stores without migrating legacy history', () {
    final seed = BuyV2Catalogue.products.first;
    const adapter = BuyV2ChatRouteAdapter();
    Uri route(BuyV2Product product) => Uri.parse(
      adapter.productQuestionLocationFor(product: product),
    );
    final first = seed.copyWith(storeId: 'store-A', seller: 'Same Store');
    final second = seed.copyWith(storeId: 'store-B', seller: 'Same Store');
    final a = route(first), b = route(second);
    expect(a.path, isNot(b.path));
    expect(a.queryParameters['conversationKey'], isNot(b.queryParameters['conversationKey']));
    expect(a.queryParameters['storeId'], 'store-A');
    expect(b.queryParameters['storeId'], 'store-B');
    final renamed = route(first.copyWith(seller: 'Renamed Store'));
    expect(renamed.path, a.path);
    expect(renamed.queryParameters['conversationKey'], a.queryParameters['conversationKey']);
    final storeQuestion = Uri.parse(adapter.storeQuestionLocationFor(anchor: first));
    expect(storeQuestion.path, a.path);
    expect(storeQuestion.queryParameters['conversationKey'], a.queryParameters['conversationKey']);
    expect(Uri.parse(a.queryParameters['return']!).queryParameters['product'], first.id);
    final legacy = route(seed.copyWith(seller: 'Same Store'));
    expect(legacy.path, '/app/chat/thread/shop-partner-${seed.destination.name}-same-store');
    expect(legacy.queryParameters['conversationKey'], '${seed.destination.name}:same-store');
    expect(legacy.queryParameters.containsKey('storeId'), isFalse);
    expect(a.path, isNot(legacy.path));
    final chat = ChatSession();
    addTearDown(chat.dispose);
    final aThread = a.pathSegments.last, bThread = b.pathSegments.last;
    chat.setDraftTextForSession(aThread, 'Store A draft');
    chat.setDraftTextForSession(bThread, 'Store B draft');
    expect(chat.draftTextForSession(aThread), 'Store A draft');
    expect(chat.draftTextForSession(bThread), 'Store B draft');
  });

  test('Batch02 explicit malformed Store identity cannot fall back to a name', () {
    final seed = BuyV2Catalogue.products.first;
    for (final id in ['', ' ', ' store-A', 'store-A ', 'store-A\n', 'store/A', 'store?A']) {
      final product = seed.copyWith(storeId: id);
      expect(() => const BuyV2ChatRouteAdapter().productQuestionLocationFor(product: product), throwsArgumentError);
      expect(() => const BuyV2ChatRouteAdapter().storeQuestionLocationFor(anchor: product), throwsArgumentError);
    }
  });

  test('Batch02 supplied Store namespaces preserve channel and realm boundaries', () {
    const adapter = BuyV2ChatRouteAdapter();
    final shop = BuyV2Catalogue.products.first;
    final wholesale = BuyV2Catalogue.products.firstWhere((p) => p.destination == BuyV2Destination.wholesale);
    final care = BuyV2Catalogue.products.firstWhere((p) => p.destination == BuyV2Destination.medicine);
    Uri route(BuyV2Product product) => Uri.parse(adapter.productQuestionLocationFor(product: product));
    final unverified = route(shop.copyWith(storeId: 'store-A'));
    expect(route(wholesale.copyWith(storeId: 'store-A')).path, unverified.path);
    expect(route(care.copyWith(storeId: 'store-A')).path, isNot(unverified.path));
    final paths = <String>{unverified.path};
    final listingId = 'listing-${List.filled(64, '0').join()}';
    for (final realm in ['evaluation', 'production']) {
      final product = shop.copyWith(id: listingId, storeId: 'store-A', offerClass: BuyV2OfferClass.retail,
        publicListingIdentity: BuyV2PublicListingIdentity(listingId: listingId, realm: realm,
          storeId: 'store-A', skuId: 'sku-A', canonicalProductId: shop.canonicalId,
          verifiedPackId: 'pack-A', channel: BuyV2OfferClass.retail));
      expect(product.hasValidPublicListingIdentity, isTrue);
      final uri = route(product);
      expect(paths.add(uri.path), isTrue);
      expect(uri.queryParameters['storeRealm'], realm);
      expect(Uri.parse(uri.queryParameters['return']!).queryParameters['product'], listingId);
      final wrongStore = product.copyWith(storeId: 'store-B');
      expect(() => route(wrongStore), throwsArgumentError);
      expect(() => adapter.storeQuestionLocationFor(anchor: wrongStore), throwsArgumentError);
    }
  });

  test('LF-PAISE product Chat preserves exact editable context and return identity', () {
    final product = BuyV2Catalogue.products.first.copyWith(priceMinor: 1025, mrpMinor: 1250);
    final uri = Uri.parse(const BuyV2ChatRouteAdapter().productQuestionLocationFor(product: product, quantity: 3));
    expect(uri.queryParameters['priceMinor'], '1025');
    expect(uri.queryParameters['mrpMinor'], '1250');
    expect(uri.queryParameters.containsKey('price'), isFalse);
    expect(uri.queryParameters['draft'], contains('Price: ₹10.25'));
    expect(uri.queryParameters['draft'], contains('MRP: ₹12.50'));
    final snapshot = jsonDecode(uri.queryParameters['productSnapshot']!) as Map;
    expect(snapshot['priceMinor'], 1025); expect(snapshot['mrpMinor'], 1250);
    expect(snapshot.containsKey('price'), isFalse);
    final context = ChatCommerceContext.fromUri(uri);
    final facts = {for (final fact in context.decisionFacts) fact.label: fact.value};
    expect(facts['Price'], '₹10.25'); expect(facts['MRP'], '₹12.50');
    expect(context.skuId, product.id);
    expect(Uri.parse(uri.queryParameters['return']!).queryParameters['product'], product.id);
  });
  test('LF-PAISE order Chat shows payable override while preserving legacy total and exact lines', () {
    final product = BuyV2Catalogue.products.first.copyWith(priceMinor: 1025, mrpMinor: 1250);
    final order = BuyV2Order(id: 'host-exact-order', destination: product.destination,
      title: 'Host order', itemSummary: product.title, total: 10, totalMinor: 1025,
      partner: product.seller, partnerType: product.sellerType, promise: 'Host estimate',
      destinationLabel: 'Host address', progress: .3, status: BuyV2OrderStatus.confirmed,
      productIds: [product.id], lines: [BuyV2CartLine(product: product, quantity: 1)]);
    final uri = Uri.parse(const BuyV2ChatRouteAdapter().orderHelpLocationFor(order: order));
    expect(uri.queryParameters['orderTotal'], '10');
    expect(uri.queryParameters['orderTotalMinor'], '1025');
    final line = (jsonDecode(uri.queryParameters['orderLines']!) as List).single as Map;
    expect(line['priceMinor'], 1025); expect(line['lineTotalMinor'], 1025);
    expect(line.containsKey('lineTotal'), isFalse);
    final context = ChatCommerceContext.fromUri(uri);
    expect(context.orderTotal, '10.25');
    expect(context.decisionFacts.singleWhere((fact) => fact.label == 'Order total').value, '₹10.25');
    expect(Uri.parse(uri.queryParameters['return']!).queryParameters['order'], order.id);
    expect(order.total, 10); expect(order.payableTotalMinor, 1025);
    final minorOrder = BuyV2Order.minor(id: 'host-minor-only-order', destination: product.destination,
      title: 'Host order', itemSummary: product.title, totalMinor: 3075,
      partner: product.seller, partnerType: product.sellerType, promise: 'Host estimate',
      destinationLabel: 'Host address', progress: .3, status: BuyV2OrderStatus.confirmed,
      productIds: [product.id], lines: [BuyV2CartLine(product: product, quantity: 3)]);
    final minorUri = Uri.parse(const BuyV2ChatRouteAdapter().orderHelpLocationFor(order: minorOrder));
    expect(minorUri.queryParameters.containsKey('orderTotal'), isFalse);
    expect(minorUri.queryParameters['orderTotalMinor'], '3075');
    expect(ChatCommerceContext.fromUri(minorUri).orderTotal, '30.75');
    expect(((jsonDecode(minorUri.queryParameters['orderLines']!) as List).single as Map)['lineTotalMinor'], 3075);
  });
  test('LF-PAISE invalid explicit Chat money never falls back to legacy context', () {
    for (final value in ['', '1.5', '-1', 'NaN', '9007199254740992']) {
      final context = ChatCommerceContext.fromUri(Uri(path: '/app/chat/thread/host', queryParameters: {
        'context': 'supplier-product', 'price': '99', 'mrp': '100', 'orderTotal': '199',
        'priceMinor': value, 'mrpMinor': value, 'orderTotalMinor': value,
      }));
      expect(context.price, isNull, reason: value);
      expect(context.mrp, isNull, reason: value);
      expect(context.orderTotal, isNull, reason: value);
      expect(context.decisionFacts.where((fact) => ['Price', 'MRP', 'Order total'].contains(fact.label)), isEmpty);
    }
    final snapshot = ChatCommerceContext.fromUri(Uri(path: '/app/chat/thread/host', queryParameters: {
      'context': 'supplier-product', 'productSnapshot': jsonEncode({'priceMinor': 1025.0, 'price': 10,
        'mrpMinor': null, 'mrp': 99}),
    }));
    expect(snapshot.price, isNull); expect(snapshot.mrp, isNull);
    final legacy = ChatCommerceContext.fromUri(Uri(path: '/app/chat/thread/host', queryParameters: {'price': '260'}));
    expect(legacy.price, '260');
    expect(ChatCommerceContext.fromUri(Uri.parse('/app/chat/thread/host?price=99&priceMinor=1025&priceMinor=1026')).price, isNull);
    expect(ChatCommerceContext.fromUri(Uri.parse('/app/chat/thread/host?priceMinor=9007199254740991')).price,
      '90071992547409.91');
  });

  const freshnessOrder = BuyV2Order(
    id: 'RV6-D003',
    destination: BuyV2Destination.shop,
    title: 'Shop order',
    itemSummary: 'One pack',
    total: 100,
    partner: 'Store A',
    partnerType: 'Retailer',
    promise: 'Delivery in12min',
    destinationLabel: 'Home',
    progress: .3,
    status: BuyV2OrderStatus.confirmed,
  );
  for (final entry in <(BuyV2CommerceLoadState?, String)>[
    (null, 'Last recorded estimate'),
    (BuyV2CommerceLoadState.loading, 'Last recorded estimate'),
    (BuyV2CommerceLoadState.ready, 'Updated estimate'),
    (
      BuyV2CommerceLoadState.offline,
      'Last recorded estimate (update unavailable)',
    ),
    (
      BuyV2CommerceLoadState.unavailable,
      'Last recorded estimate (update unavailable)',
    ),
  ]) {
    test('RV6 D003 Chat preserves estimate freshness ${entry.$1}', () {
      final summary = buyV2OrderEstimateSummary(
        freshnessOrder,
        refreshState: entry.$1,
      );
      expect(summary, startsWith(entry.$2));
      final uri = Uri.parse(
        const BuyV2ChatRouteAdapter().orderHelpLocationFor(
          order: freshnessOrder,
          deliverySummary: summary,
        ),
      );
      expect(uri.queryParameters['delivery'], summary);
      expect(
        uri.queryParameters['draft'],
        'Hello, I need help with order ${freshnessOrder.id}.',
      );
      expect(uri.queryParameters['orderId'], freshnessOrder.id);
      expect(uri.queryParameters['return'], contains('order=RV6-D003'));
      final thread = BuyV2ShopChatThreadFactory.fromOrder(
        freshnessOrder,
        deliverySummary: summary,
      );
      expect(thread.detail, summary);
      expect(thread.contextDetail, contains(summary));
    });
  }
  test(
    'RV6 D003 missing refresh evidence stays recorded and refresh stays pending',
    () {
      final uri = Uri.parse(
        const BuyV2ChatRouteAdapter().orderHelpLocationFor(
          order: freshnessOrder,
        ),
      );
      expect(
        uri.queryParameters['delivery'],
        startsWith('Last recorded estimate'),
      );
      expect(
        BuyV2ShopChatThreadFactory.fromOrder(freshnessOrder).detail,
        startsWith('Last recorded estimate'),
      );
      expect(
        buyV2OrderEstimateSummary(
          freshnessOrder,
          refreshState: BuyV2CommerceLoadState.ready,
          refreshing: true,
        ),
        startsWith('Updating · last recorded estimate'),
      );
      expect(
        buyV2HistoricalOrderEstimate(freshnessOrder),
        contains('recorded time unavailable'),
      );
      expect(
        buyV2HistoricalOrderEstimate(freshnessOrder),
        contains('not a live countdown'),
      );
    },
  );

  test(
    'RV6 D003 historical estimate preserves known window and discloses missing estimate',
    () {
      BuyV2Order historical(String promise, {String? window}) => BuyV2Order(
        id: 'RV6-D003-history',
        destination: BuyV2Destination.shop,
        title: 'Order',
        itemSummary: 'One pack',
        total: 100,
        partner: 'Store A',
        partnerType: 'Retailer',
        promise: promise,
        promisedByLabel: window,
        destinationLabel: 'Home',
        progress: 1,
        status: BuyV2OrderStatus.delivered,
      );
      for (final value in ['', 'Delivered', 'Completed']) {
        expect(
          buyV2HistoricalOrderEstimate(historical(value)),
          'Original delivery estimate unavailable',
        );
        expect(
          buyV2OrderEstimateSummary(historical(value)),
          'Original delivery estimate unavailable',
        );
      }
      expect(
        buyV2HistoricalOrderEstimate(
          historical(
            'Delivery in 12 min',
            window: '14 September 2026, 18:00-18:30',
          ),
        ),
        'Original promised window: 14 September 2026, 18:00-18:30',
      );
    },
  );

  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    return session;
  }

  for (final scale in [1.0, 2.0]) {
    for (final remount in [true, false]) {
    testWidgets('LF03 Ask draft retains original product until confirmed replacement at $scale remount $remount', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final journey = await readyJourney(), chat = ChatSession.production(
          gateway: const UnavailableChatGateway(), attachmentPicker: _DraftAttachmentPicker());
      addTearDown(journey.dispose); addTearDown(chat.dispose);
      final products = BuyV2Catalogue.products.where((p) => p.destination == BuyV2Destination.shop).take(2).toList();
      final a = products[0].copyWith(storeId: 'store-draft', seller: 'Host same Store', priceMinor: 1025);
      final b = products[1].copyWith(storeId: 'store-draft', seller: 'Host same Store', priceMinor: 2050);
      const adapter = BuyV2ChatRouteAdapter();
      final aRoute = adapter.productQuestionLocationFor(product: a), bRoute = adapter.productQuestionLocationFor(product: b);
      final thread = Uri.parse(aRoute).pathSegments.last;
      expect(Uri.parse(bRoute).pathSegments.last, thread);
      var opened = false;
      Future<void> open(String route) async {
        if (opened && !remount) {
          GoRouter.of(tester.element(find.byKey(const Key('chat-thread-screen')))).go(route);
          await tester.pumpAndSettle();
          return;
        }
        await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpAndSettle();
        await tester.pumpWidget(r66VisualCaptureRoot(MoolSocialApp(key: UniqueKey(), session: journey, chatSession: chat, initialLocation: route)));
        await tester.pumpAndSettle();
        opened = true;
      }
      await open(aRoute);
      final field = find.byKey(const Key('chat-message-field'));
      await tester.enterText(field, 'Please confirm this original pack');
      final original = chat.commerceContext(thread)!;
      expect(original.productId, a.canonicalId);
      await open(bRoute);
      expect(tester.widget<TextField>(field).controller!.text, 'Please confirm this original pack');
      expect(chat.commerceContext(thread)!.productId, a.canonicalId);
      expect(chat.commerceContext(thread)!.productAppRoute, original.productAppRoute);
      final replace = find.byKey(const Key('chat-use-incoming-product'));
      expect(replace, findsOneWidget);
      if (remount) await captureR66Visual(tester, 'lf03-chat-draft-kept-$scale');
      await tester.ensureVisible(replace); await tester.tap(replace); await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'First replacement confirmation must fit');
      if (remount) await captureR66Visual(tester, 'lf03-chat-draft-confirmation-$scale');
      await tester.tap(find.byKey(const Key('chat-keep-original-draft'))); await tester.pumpAndSettle();
      expect(chat.commerceContext(thread)!.productId, a.canonicalId);
      expect(chat.draftTextForSession(thread), 'Please confirm this original pack');
      await tester.tap(replace); await tester.pumpAndSettle();
      chat.setDraftTextForSession(thread, 'Newer draft while confirmation was open');
      await tester.tap(find.byKey(const Key('chat-replace-original-draft'))); await tester.pumpAndSettle();
      expect(chat.commerceContext(thread)!.productId, a.canonicalId);
      expect(chat.draftTextForSession(thread), 'Newer draft while confirmation was open');
      await tester.enterText(field, 'Please confirm this original pack');
      await tester.tap(replace); await tester.pumpAndSettle();
      expect(await chat.selectAttachment(thread, ChatAttachmentKind.document), isTrue);
      final attachment = chat.selectedAttachment(thread);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Attachment arriving during confirmation must fit');
      await tester.tap(find.byKey(const Key('chat-replace-original-draft'))); await tester.pumpAndSettle();
      expect(chat.selectedAttachment(thread), same(attachment));
      expect(chat.commerceContext(thread)!.productId, a.canonicalId);
      await tester.tap(replace); await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Replacement with staged attachment must fit');
      await tester.tap(find.byKey(const Key('chat-replace-original-draft'))); await tester.pumpAndSettle();
      expect(chat.commerceContext(thread)!.productId, b.canonicalId);
      expect(chat.commerceContext(thread)!.price, '20.50');
      expect(chat.draftTextForSession(thread), Uri.parse(bRoute).queryParameters['draft']);
      expect(replace, findsNothing);
      expect(tester.takeException(), isNull);
    });
    }
  }

  test(
    'Order Help omits shopping prompts while product enquiries retain them',
    () {
      for (final kind in ['supplier-order', 'care-pharmacy-order']) {
        final order = ChatCommerceContext.fromUri(
          Uri.parse(
            '/app/chat/thread/supplier?context=$kind&orderId=order-1'
            '&supplier=Supplier&productTitle=Product&price=10&orderTotal=20'
            '&delivery=Tomorrow',
          ),
        );
        expect(order, isNotNull);
        expect(order.suggestedPrompts, isEmpty);
      }
      final product = ChatCommerceContext.fromUri(
        Uri.parse(
          '/app/chat/thread/supplier?context=product&supplier=Supplier'
          '&productTitle=Product&price=10&delivery=Tomorrow',
        ),
      );
      expect(product, isNotNull);
      expect(product.suggestedPrompts, [
        'Is this product available?',
        'Please confirm the price.',
        'When can this be delivered?',
      ]);
    },
  );

  test('Buy Chat adapter preserves context without a second Chat shell', () {
    const adapter = BuyV2ChatRouteAdapter();
    const cases =
        <
          ({
            BuyV2Destination destination,
            bool offersActive,
            String returnLocation,
            String? type,
          })
        >[
          (
            destination: BuyV2Destination.shop,
            offersActive: false,
            returnLocation: '/app/buy?sub=shop',
            type: null,
          ),
          (
            destination: BuyV2Destination.orders,
            offersActive: false,
            returnLocation: '/app/buy?sub=orders',
            type: 'order',
          ),
          (
            destination: BuyV2Destination.wholesale,
            offersActive: false,
            returnLocation: '/app/buy?sub=wholesale',
            type: 'business',
          ),
          (
            destination: BuyV2Destination.medicine,
            offersActive: false,
            returnLocation: '/app/buy?sub=medicine',
            type: 'business',
          ),
          (
            destination: BuyV2Destination.shop,
            offersActive: true,
            returnLocation: '/app/buy?sub=offers',
            type: 'support',
          ),
        ];

    for (final entry in cases) {
      final uri = Uri.parse(
        adapter.locationFor(
          destination: entry.destination,
          view: BuyV2View.catalogue,
          offersActive: entry.offersActive,
        ),
      );
      expect(uri.path, '/app/chat/inbox', reason: entry.returnLocation);
      expect(
        uri.queryParameters['type'],
        entry.type,
        reason: entry.returnLocation,
      );
      expect(
        uri.queryParameters['return'],
        entry.returnLocation,
        reason: entry.returnLocation,
      );
    }

    final offerProduct = Uri.parse(
      adapter.locationFor(
        destination: BuyV2Destination.shop,
        view: BuyV2View.product,
        offersActive: true,
        productId: 'offer-product',
      ),
    );
    expect(
      offerProduct.queryParameters['return'],
      '/app/buy?sub=offers&view=product&product=offer-product',
    );
  });

  test('every Buy depth has one exact shared Chat return', () {
    const adapter = BuyV2ChatRouteAdapter();
    const cases = <({BuyV2View view, String expected})>[
      (view: BuyV2View.catalogue, expected: '/app/buy?sub=wholesale'),
      (
        view: BuyV2View.product,
        expected: '/app/buy?sub=wholesale&view=product&product=rice-25kg',
      ),
      (
        view: BuyV2View.cart,
        expected: '/app/buy?sub=wholesale&view=cart&scope=wholesale',
      ),
      (
        view: BuyV2View.checkout,
        expected: '/app/buy?sub=wholesale&view=checkout&scope=wholesale',
      ),
      (
        view: BuyV2View.confirmation,
        expected: '/app/buy?sub=wholesale&view=confirmation&scope=wholesale',
      ),
      (
        view: BuyV2View.tracking,
        expected: '/app/buy?sub=orders&view=tracking&order=PO-240783',
      ),
      (
        view: BuyV2View.orderItems,
        expected: '/app/buy?sub=orders&view=items&order=PO-240783',
      ),
      (
        view: BuyV2View.assist,
        expected: '/app/buy?sub=orders&view=tracking&order=PO-240783',
      ),
      (view: BuyV2View.account, expected: '/app/buy?sub=wholesale'),
      (
        view: BuyV2View.recovery,
        expected:
            '/app/buy?sub=wholesale&view=recovery&recovery=delivery-delay',
      ),
    ];

    for (final entry in cases) {
      final uri = Uri.parse(
        adapter.locationFor(
          destination: BuyV2Destination.wholesale,
          view: entry.view,
          offersActive: false,
          cartScope: BuyV2CartScope.wholesale,
          checkoutScope: BuyV2CartScope.wholesale,
          productId: 'rice-25kg',
          orderId: 'PO-240783',
          recoveryKind: BuyV2RecoveryKind.deliveryDelay,
        ),
      );
      expect(
        uri.queryParameters['return'],
        entry.expected,
        reason: entry.view.name,
      );
    }
  });

  test('order Help opens MoolSocial Assist inside shared Chat', () {
    final uri = Uri.parse(
      const BuyV2ChatRouteAdapter().orderHelpLocationFor(orderId: 'PO-240783'),
    );

    expect(uri.path, '/app/chat/thread/shop-assist');
    expect(uri.queryParameters['draft'], 'Help with order PO-240783');
    expect(
      uri.queryParameters['return'],
      '/app/buy?sub=orders&view=tracking&order=PO-240783',
    );
    expect(uri.queryParameters['directReturn'], 'true');
  });

  test('order Help carries the exact supplier and purchased SKU snapshot', () {
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.wholesale,
    );
    final order = BuyV2Order(
      id: 'PO-240783',
      purchaseId: 'PURCHASE-2407',
      destination: BuyV2Destination.wholesale,
      title: 'Wholesale order',
      itemSummary: product.title,
      total: product.price * 3,
      partner: product.seller,
      partnerType: product.sellerType,
      promise: product.deliveryPromise,
      destinationLabel: 'Work receiving',
      progress: .4,
      status: BuyV2OrderStatus.confirmed,
      productIds: [product.id],
      lines: [BuyV2CartLine(product: product, quantity: 3)],
      paymentMethod: 'Bank transfer',
      paymentTermLabel: 'Pay now',
    );
    final uri = Uri.parse(
      const BuyV2ChatRouteAdapter().orderHelpLocationFor(order: order),
    );

    expect(uri.path, startsWith('/app/chat/thread/shop-partner-wholesale-'));
    expect(uri.queryParameters['context'], 'supplier-order');
    expect(uri.queryParameters['conversationKey'], startsWith('wholesale:'));
    expect(uri.queryParameters['supplier'], product.seller);
    expect(uri.queryParameters['supplierType'], product.sellerType);
    expect(uri.queryParameters['orderId'], order.id);
    expect(uri.queryParameters['purchaseId'], order.purchaseId);
    expect(uri.queryParameters['skuIds'], product.id);
    expect(uri.queryParameters['quantities'], '${product.id}:3');
    final orderLines = jsonDecode(uri.queryParameters['orderLines']!) as List;
    final orderLine = orderLines.single as Map<String, dynamic>;
    expect(orderLine['productId'], product.canonicalId);
    expect(orderLine['skuId'], product.id);
    expect(orderLine['title'], product.title);
    expect(orderLine['variant'], product.variant);
    expect(orderLine['pack'], product.pack);
    expect(orderLine['price'], product.price);
    expect(orderLine['quantity'], 3);
    expect(orderLine['lineTotal'], product.price * 3);
    expect(orderLine['returnPolicy'], product.returnPolicy);
    expect(uri.queryParameters['paymentTerms'], 'Pay now');
    expect(
      uri.queryParameters['draft'],
      'Hello, I need help with order ${order.id}.',
    );
    expect(uri.queryParameters['draft'], isNot(contains('Order total:')));
    expect(uri.queryParameters['adminVisible'], 'true');
    expect(uri.queryParameters['escalationReason'], 'supplier-non-response');
    expect(uri.queryParameters['callAuthority'], 'moolsocial-admin-only');
  });

  test('supplier Chat route carries exact published product context', () {
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) =>
          candidate.destination == BuyV2Destination.wholesale &&
          candidate.sellerType.toLowerCase().contains('manufacturer'),
    );
    final uri = Uri.parse(
      const BuyV2ChatRouteAdapter().productQuestionLocationFor(
        product: product,
        quantity: 3,
      ),
    );

    expect(uri.path, startsWith('/app/chat/thread/shop-partner-wholesale-'));
    expect(uri.queryParameters['context'], 'supplier-product');
    expect(uri.queryParameters['conversationKey'], startsWith('wholesale:'));
    expect(uri.queryParameters['supplier'], product.seller);
    expect(uri.queryParameters['supplierType'], product.sellerType);
    expect(uri.queryParameters['supplierRole'], product.partnerRole);
    expect(uri.queryParameters['productId'], product.canonicalId);
    expect(uri.queryParameters['skuId'], product.id);
    expect(uri.queryParameters['brand'], product.brand);
    expect(uri.queryParameters['variant'], product.variant);
    expect(uri.queryParameters['price'], '${product.price}');
    expect(uri.queryParameters['unitPrice'], product.unitPrice);
    expect(uri.queryParameters['quantity'], '3');
    expect(uri.queryParameters['delivery'], product.deliveryPromise);
    expect(uri.queryParameters['policy'], product.returnPolicy);
    expect(uri.queryParameters['adminVisible'], 'true');
    expect(uri.queryParameters['escalationReason'], 'supplier-non-response');
    expect(uri.queryParameters['callAuthority'], 'moolsocial-admin-only');
    expect(uri.queryParameters['draft'], contains(product.seller));
    expect(uri.queryParameters['draft'], contains(product.title));
    expect(uri.queryParameters['draft'], isNot(contains('SKU:')));
    expect(uri.queryParameters['skuId'], product.id);
    expect(uri.queryParameters['draft'], contains('Quantity: 3'));
    expect(uri.queryParameters['draft'], contains('Price:'));
    final snapshot =
        jsonDecode(uri.queryParameters['productSnapshot']!)
            as Map<String, dynamic>;
    expect(snapshot['supplier'], product.seller);
    expect(snapshot['supplierType'], product.sellerType);
    expect(snapshot['skuId'], product.id);
    expect(snapshot['pack'], product.pack);
    expect(snapshot['delivery'], product.deliveryPromise);
  });

  for (final destination in const [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ]) {
    test(
      'supplier Chat shares exact public SKU link for ${destination.name}',
      () {
        final product = BuyV2Catalogue.products
            .firstWhere((candidate) => candidate.destination == destination)
            .copyWith(id: 'supplier/SKU 50g & variant=2?#');
        final chat = Uri.parse(
          const BuyV2ChatRouteAdapter().productQuestionLocationFor(
            product: product,
            quantity: 3,
          ),
        );
        final link = Uri.parse(chat.queryParameters['productLink']!);
        expect(link.scheme, 'https');
        expect(link.host, 'moolsocial.com');
        expect(link.path, '/app/buy');
        expect(link.fragment, isEmpty);
        expect(link.queryParameters, {
          'sub': destination.name,
          'view': 'product',
          'product': product.id,
        });
        expect(link, buyV2SharedProductUri(product));
        expect(
          chat.queryParameters['draft']!.split('\n'),
          contains('Product link: $link'),
        );
        expect(
          chat.queryParameters['draft'],
          isNot(contains('moolsocial.app')),
        );
        final returnRoute = Uri.parse(chat.queryParameters['return']!);
        expect(returnRoute.path, '/app/buy');
        expect(returnRoute.queryParameters, link.queryParameters);
        expect(chat.queryParameters['directReturn'], 'true');
        expect(chat.queryParameters['skuId'], product.id);
        expect(chat.queryParameters['supplier'], product.seller);
        expect(chat.queryParameters['quantity'], '3');
      },
    );
  }

  test('retailer wholesaler and manufacturer all receive supplier Chat', () {
    final products = <BuyV2Product>[
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == BuyV2Destination.shop &&
            product.sellerType.toLowerCase().contains('retailer'),
      ),
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == BuyV2Destination.wholesale &&
            product.sellerType.toLowerCase().contains('wholesaler'),
      ),
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == BuyV2Destination.wholesale &&
            product.sellerType.toLowerCase().contains('manufacturer'),
      ),
    ];

    final supplierThreadPaths = <String>{};
    for (final product in products) {
      final uri = Uri.parse(
        const BuyV2ChatRouteAdapter().productQuestionLocationFor(
          product: product,
        ),
      );
      expect(uri.path, startsWith('/app/chat/thread/shop-partner-'));
      expect(supplierThreadPaths.add(uri.path), isTrue);
      expect(uri.queryParameters['supplier'], product.seller);
      expect(uri.queryParameters['supplierType'], product.sellerType);
      expect(uri.queryParameters['conversationKey'], isNotEmpty);
      expect(uri.queryParameters['adminVisible'], 'true');
      expect(uri.queryParameters['callAuthority'], 'moolsocial-admin-only');
    }
    expect(supplierThreadPaths, hasLength(3));
  });

  test('supplier Chat fails closed when provider identity is missing', () {
    final product = BuyV2Catalogue.products.first.copyWith(seller: '  ');

    expect(
      () => const BuyV2ChatRouteAdapter().productQuestionLocationFor(
        product: product,
      ),
      throwsArgumentError,
    );
  });

  test('Medicine product and order Chat remain Care-owned', () {
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.medicine,
    );
    final adapter = const BuyV2ChatRouteAdapter();
    final productUri = Uri.parse(
      adapter.productQuestionLocationFor(product: product),
    );
    final order = BuyV2Order(
      id: 'RX-CARE-1',
      destination: BuyV2Destination.medicine,
      title: 'Medicine order',
      itemSummary: product.title,
      total: product.price,
      partner: product.seller,
      partnerType: product.partnerRole,
      promise: product.deliveryPromise,
      destinationLabel: 'Home',
      progress: .5,
      status: BuyV2OrderStatus.preparing,
      productIds: [product.id],
      lines: [BuyV2CartLine(product: product, quantity: 1)],
    );
    final orderUri = Uri.parse(adapter.orderHelpLocationFor(order: order));

    for (final uri in [productUri, orderUri]) {
      expect(uri.path, startsWith('/app/chat/thread/care-pharmacy-'));
      expect(
        Uri.parse(uri.queryParameters['return']!).queryParameters['sub'],
        'medicine',
      );
    }
    expect(productUri.queryParameters['context'], 'care-pharmacy-product');
    expect(orderUri.queryParameters['context'], 'care-pharmacy-order');
  });

  test('supplier Chat carries structured purchase-protection fields', () {
    final product = BuyV2Catalogue.products.first.copyWith(
      purchaseProtection: const BuyV2PurchaseProtection(
        summary: 'Replacement available',
        remedies: ['Replacement', 'Refund'],
        windowLabel: 'Within 7 days of delivery',
        conditionsLabel: 'Unused with original packaging',
        verificationLabel: 'Photo or pickup inspection',
        initiationLabel: 'Orders, order details, select issue',
        approvalLabel: 'Approval after condition review',
        pickupLabel: 'Pickup in original packaging',
        refundMethodLabel: 'Original payment method',
        refundTimelineLabel: 'After verification',
        warrantyLabel: 'One-year manufacturer warranty',
        nonReturnableReason: 'Change-of-mind return unavailable',
        policyVersion: 'POLICY-7',
        effectiveFromLabel: 'Shown before purchase',
      ),
    );
    final uri = Uri.parse(
      const BuyV2ChatRouteAdapter().productQuestionLocationFor(
        product: product,
      ),
    );

    expect(uri.queryParameters['policy'], 'Replacement available');
    expect(uri.queryParameters['remedies'], 'Replacement,Refund');
    expect(uri.queryParameters['policyWindow'], 'Within 7 days of delivery');
    expect(uri.queryParameters['policyInitiation'], contains('order details'));
    expect(uri.queryParameters['policyApproval'], contains('condition review'));
    expect(uri.queryParameters['policyPickup'], contains('original packaging'));
    expect(uri.queryParameters['refundMethod'], 'Original payment method');
    expect(uri.queryParameters['warranty'], 'One-year manufacturer warranty');
    expect(uri.queryParameters['policyVersion'], 'POLICY-7');
    expect(uri.queryParameters['draft'], contains('Replacement available'));
    expect(uri.queryParameters['draft'], contains('Replacement, Refund'));
    expect(
      uri.queryParameters['draft'],
      contains('Warranty: One-year manufacturer warranty'),
    );
  });

  test('supplier Chat snapshot carries product compliance facts', () {
    final product = BuyV2Catalogue.products.first.copyWith(
      compliance: const BuyV2ProductCompliance(
        genericName: 'Refined sunflower oil',
        netQuantity: '5 L',
        manufacturerName: 'Surya Oils India',
        countryOfOrigin: 'India',
        fssaiLicenseNumber: '10000000000000',
        consumerCare: 'Surya Oils Consumer Care',
      ),
    );
    final uri = Uri.parse(
      const BuyV2ChatRouteAdapter().productQuestionLocationFor(
        product: product,
      ),
    );
    final snapshot =
        jsonDecode(uri.queryParameters['productSnapshot']!)
            as Map<String, dynamic>;
    final compliance = snapshot['compliance'] as Map<String, dynamic>;

    expect(compliance['genericName'], 'Refined sunflower oil');
    expect(compliance['netQuantity'], '5 L');
    expect(compliance['manufacturer'], 'Surya Oils India');
    expect(compliance['countryOfOrigin'], 'India');
    expect(compliance['fssaiLicenseNumber'], '10000000000000');
    expect(compliance['consumerCare'], 'Surya Oils Consumer Care');
    expect(uri.queryParameters['draft'], contains('Generic name:'));
    expect(uri.queryParameters['draft'], contains('Country of origin: India'));
  });

  test('blank optional supplier facts stay absent from Chat context', () {
    final product = BuyV2Catalogue.products.first.copyWith(
      compliance: const BuyV2ProductCompliance(
        genericName: '  ',
        netQuantity: '',
        manufacturerName: '   ',
      ),
      purchaseProtection: const BuyV2PurchaseProtection(
        summary: ' ',
        remedies: [' ', 'Replacement'],
        warrantyLabel: '  ',
      ),
    );
    final uri = Uri.parse(
      const BuyV2ChatRouteAdapter().productQuestionLocationFor(
        product: product,
      ),
    );
    final snapshot =
        jsonDecode(uri.queryParameters['productSnapshot']!)
            as Map<String, dynamic>;
    final compliance = snapshot['compliance'] as Map<String, dynamic>;
    final protection = snapshot['purchaseProtection'] as Map<String, dynamic>;

    expect(compliance['genericName'], isNull);
    expect(compliance['netQuantity'], isNull);
    expect(compliance['manufacturer'], isNull);
    expect(protection['summary'], isNull);
    expect(protection['remedies'], ['Replacement']);
    expect(protection['warranty'], isNull);
    expect(uri.queryParameters['policy'], product.returnPolicy);
    expect(uri.queryParameters['draft'], isNot(contains('Generic name:')));
    expect(uri.queryParameters['draft'], isNot(contains('Warranty:')));
  });

  testWidgets('Buy Chat action opens only the shared Chat module', (
    tester,
  ) async {
    final journey = await readyJourney();
    final chat = ChatSession();
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/buy',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    expect(find.text('Shop Chat'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
    expect(find.text('Search conversations'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    for (final threadId in const [
      'shop-assist',
      'shop-order',
      'shop-partner',
      'shop-offers',
    ]) {
      expect(
        find.byKey(ValueKey('chat-open-thread-$threadId')),
        findsOneWidget,
        reason: threadId,
      );
    }

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry
      in const <
        ({String location, String title, String threadId, String returnKey})
      >[
        (
          location: '/app/buy?sub=wholesale',
          title: 'Shop Chat',
          threadId: 'shop-partner',
          returnKey: 'buy-catalogue-motion-tween-wholesale',
        ),
        (
          location: '/app/buy?sub=orders',
          title: 'Shop Chat',
          threadId: 'shop-order',
          returnKey: 'buy-orders-section-active',
        ),
        (
          location: '/app/buy?sub=offers',
          title: 'Shop Chat',
          threadId: 'shop-offers',
          returnKey: 'buy-offers-publisher-summary',
        ),
        (
          location: '/app/buy?sub=medicine',
          title: 'Care Chat',
          threadId: 'clinic-care',
          returnKey: 'buy-catalogue-motion-tween-medicine',
        ),
      ]) {
    testWidgets('${entry.location} opens its exact shared Chat and returns', (
      tester,
    ) async {
      final journey = await readyJourney();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: entry.location,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();

      expect(find.text(entry.title), findsOneWidget);
      expect(
        find.byKey(ValueKey('chat-open-thread-${entry.threadId}')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(entry.returnKey)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Offers keeps global Profile and Chat returns usable at compact large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final journey = await readyJourney();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: '/app/buy',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );

      final profile = find.byKey(const ValueKey('buy-open-account'));
      final chatAction = find.byKey(const ValueKey('mool-global-chat-tap'));
      expect(tester.getSize(profile), const Size(44, 44));
      expect(profile.hitTestable(), findsOneWidget);
      expect(find.byTooltip('Open your MoolSocial profile'), findsOneWidget);
      await tester.longPress(profile);
      await tester.pumpAndSettle();
      expect(find.text('Open your MoolSocial profile'), findsOneWidget);
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
      expect(tester.getSize(chatAction).width, greaterThanOrEqualTo(44));
      await tester.tap(profile);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
      expect(
        find.byKey(const Key('global-profile-context-shop-offers')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );

      await tester.tap(chatAction);
      await tester.pumpAndSettle();
      expect(find.text('Shop Chat'), findsOneWidget);
      expect(
        find.byKey(const Key('chat-open-thread-shop-offers')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Offers global Profile destination returns to exact Offers', (
    tester,
  ) async {
    final journey = await readyJourney();
    final chat = ChatSession();
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/buy',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-profile-identity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-personal-profile-v2')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-open-account')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retired Buy Account route resolves to global Profile entry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final journey = await readyJourney();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: '/app/buy?sub=wholesale&view=account',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-account-hub')), findsNothing);
      expect(find.byKey(const ValueKey('buy-open-account')), findsOneWidget);
      final profile = find.byKey(const ValueKey('buy-open-account'));
      expect(find.byTooltip('Open your MoolSocial profile'), findsOneWidget);
      expect(tester.widget<IconButton>(profile).onPressed, isNotNull);
      expect(
        tester.getSemantics(profile).getSemanticsData().tooltip,
        'Open your MoolSocial profile',
      );
      expect(
        find.byKey(const ValueKey('buy-catalogue-motion-tween-wholesale')),
        findsOneWidget,
      );
      await tester.tap(profile);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-catalogue-motion-tween-wholesale')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final id in ['s-dog-food', 'w-notebook']) {
    for (final scale in [1.0, 2.0]) {
      for (final linkedEntry in [false, true]) {
        testWidgets(
          'RV6 D013 Store context stays static $id text $scale linked $linkedEntry',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(390, 844);
            addTearDown(tester.view.reset);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final journey = await readyJourney();
            final chat = ChatSession();
            addTearDown(journey.dispose);
            addTearDown(chat.dispose);
            final shop = id.startsWith('s-');
            final destination = shop ? 'shop' : 'wholesale';
            final location =
                '/app/buy?sub=$destination${linkedEntry ? '&view=product&product=$id' : ''}';
            await tester.pumpWidget(
              r66VisualCaptureRoot(
                MoolSocialApp(
                  session: journey,
                  chatSession: chat,
                  initialLocation: location,
                ),
              ),
            );
            await tester.pumpAndSettle();
            final buy = tester
                .widget<BuyV2Screen>(find.byType(BuyV2Screen))
                .session;
            if (!linkedEntry) {
              expect(buy.openProduct(id), isTrue);
              await tester.pumpAndSettle();
            }
            final store = find.byKey(
              ValueKey(
                '${shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-$id',
              ),
            );
            final productScroll = find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$id')),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .first;
            await tester.scrollUntilVisible(
              store,
              180,
              scrollable: productScroll,
            );
            await Scrollable.ensureVisible(
              tester.element(store),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            expect(store.hitTestable(), findsOneWidget);
            await tester.tap(store);
            await tester.pumpAndSettle();
            final prefix = shop ? 'buy-shop-seller' : 'buy-wholesale-supplier';
            final storeSheet = find.byKey(ValueKey('$prefix-sheet-$id'));
            expect(storeSheet, findsOneWidget);
            String? retainedDraft;
            for (final androidBack in [false, true]) {
              final ask = find.byKey(const ValueKey('buy-public-store-ask'));
              await tester.ensureVisible(ask);
              expect(ask.hitTestable(), findsOneWidget);
              await tester.tap(ask);
              await tester.pumpAndSettle();
              expect(
                find.byKey(const Key('chat-thread-screen')),
                findsOneWidget,
              );
              expect(storeSheet, findsNothing);
              final card = find.byKey(const Key('chat-commerce-context-card'));
              expect(card, findsOneWidget);
              expect(
                find.byKey(const Key('chat-commerce-context-expand')),
                findsNothing,
              );
              final summary = find.byKey(
                const Key('chat-commerce-context-summary'),
              );
              expect(summary, findsOneWidget);
              expect(tester.widget<ListTile>(summary).onTap, isNull);
              expect(tester.widget<ListTile>(summary).trailing, isNull);
              expect(
                find.descendant(of: card, matching: find.byType(Divider)),
                findsNothing,
              );
              expect(find.text('Store conversation'), findsOneWidget);
              expect(
                find.descendant(
                  of: card,
                  matching: find.text(buy.product(id).seller),
                ),
                findsOneWidget,
              );
              final draftField = find.byKey(const Key('chat-message-field'));
              final draft = tester
                  .widget<TextField>(draftField)
                  .controller!
                  .text;
              expect(draft, contains('I have a question for'));
              if (retainedDraft != null) expect(draft, retainedDraft);
              retainedDraft = draft;
              final height = tester.getSize(card).height;
              await tester.tap(find.text('Store conversation'));
              await tester.pumpAndSettle();
              expect(tester.getSize(card).height, height);
              expect(
                tester.widget<TextField>(draftField).controller!.text,
                draft,
              );
              expect(tester.takeException(), isNull);
              if (!linkedEntry && !androidBack) {
                await captureR66Visual(
                  tester,
                  'rv6-d013-static-context-$id-text-$scale',
                );
              }
              if (androidBack) {
                await tester.binding.handlePopRoute();
              } else {
                await tester.tap(find.byKey(const Key('chat-back')));
              }
              await tester.pumpAndSettle();
              expect(find.byKey(const Key('chat-thread-screen')), findsNothing);
              expect(storeSheet, findsOneWidget);
              expect(buy.selectedProductId, id);
              expect(buy.cartLines, isEmpty);
              expect(tester.takeException(), isNull);
              if (!linkedEntry && androidBack) {
                await captureR66Visual(
                  tester,
                  'rv6-d013-store-return-$id-text-$scale',
                );
              }
            }
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(storeSheet, findsNothing);
            expect(buy.view, BuyV2View.product);
            expect(buy.selectedProductId, id);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('product and order-items Chat return to their exact subtap', (
    tester,
  ) async {
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    final routes = <({String location, Finder owner})>[
      (
        location: Uri(
          path: '/app/buy',
          queryParameters: {
            'sub': 'wholesale',
            'view': 'product',
            'product': product.id,
          },
        ).toString(),
        owner: find.byKey(ValueKey('buy-product-media-reveal-${product.id}')),
      ),
      (
        location: '/app/buy?sub=orders&view=items&order=PO-240783',
        owner: find.byKey(const ValueKey('buy-order-items-PO-240783')),
      ),
    ];

    for (final entry in routes) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final journey = await readyJourney();
      final chat = ChatSession();
      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: entry.location,
        ),
      );
      await tester.pumpAndSettle();
      expect(entry.owner, findsOneWidget, reason: entry.location);

      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(entry.owner, findsOneWidget, reason: entry.location);
      expect(tester.takeException(), isNull);
      journey.dispose();
      chat.dispose();
    }
  });

  testWidgets(
    'product supplier Chat keeps exact context above the compact keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.view.viewPadding = const FakeViewPadding(bottom: 44);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final product = BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == BuyV2Destination.wholesale &&
            candidate.sellerType.toLowerCase().contains('manufacturer'),
      );
      final journey = await readyJourney();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: Uri(
            path: '/app/buy',
            queryParameters: {
              'sub': 'wholesale',
              'view': 'product',
              'product': product.id,
            },
          ).toString(),
        ),
      );
      await tester.pumpAndSettle();

      final productScroll = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      final ask = find.bySemanticsLabel('Ask manufacturer');
      await tester.scrollUntilVisible(ask, 220, scrollable: productScroll);
      await tester.pumpAndSettle();
      await tester.ensureVisible(ask);
      await tester.pumpAndSettle();
      expect(ask.hitTestable(), findsOneWidget);
      await tester.tap(ask);
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('chat-message-field'));
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(field, findsOneWidget);
      final draft = tester.widget<TextField>(field).controller?.text ?? '';
      expect(draft, contains(product.seller));
      expect(draft, isNot(contains('SKU:')));
      expect(draft, contains('Quantity: ${product.minimumOrder}'));
      expect(draft, contains('Price:'));

      await tester.tap(field);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.getRect(field).bottom, lessThanOrEqualTo(400));
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(PageStorageKey('buy-product-${product.id}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'order Help stays in one supplier conversation with one composer text $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final journey = await readyJourney();
        final chat = ChatSession();
        addTearDown(journey.dispose);
        addTearDown(chat.dispose);

        await tester.pumpWidget(
          r66VisualCaptureRoot(
            MoolSocialApp(
              session: journey,
              chatSession: chat,
              initialLocation:
                  '/app/buy?sub=orders&view=tracking&order=PO-240783',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buy = tester
            .widget<BuyV2Screen>(find.byType(BuyV2Screen))
            .session;
        await buy.refreshOrder('PO-240783');
        await tester.pumpAndSettle();
        expect(
          buy.orderRefreshState('PO-240783'),
          BuyV2CommerceLoadState.unavailable,
        );
        final help = find.byKey(const ValueKey('buy-tracking-help'));
        await tester.scrollUntilVisible(
          help,
          220,
          scrollable: find.byType(Scrollable).last,
        );
        await Scrollable.ensureVisible(tester.element(help), alignment: .5);
        await tester.pumpAndSettle();
        expect(help.hitTestable(), findsOneWidget);
        await tester.tap(help);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
        expect(find.text('MoolSocial Assist'), findsNothing);
        expect(
          tester.widget<Text>(find.byKey(const Key('chat-page-title'))).data,
          'Marwar Foods Distribution',
        );
        expect(find.text('Conversation'), findsNothing);
        expect(find.text('Metro Wholesale Partner'), findsNothing);
        expect(find.text('Your bulk quote is ready to review.'), findsNothing);
        expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
        expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
        expect(find.text('Search conversations'), findsNothing);
        expect(find.byKey(const Key('chat-suggested-prompts')), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
        final orderDraft = tester
            .widget<TextField>(find.byKey(const Key('chat-message-field')))
            .controller
            ?.text;
        expect(orderDraft, 'Hello, I need help with order PO-240783.');
        final expand = find.byKey(const Key('chat-commerce-context-expand'));
        await tester.ensureVisible(expand);
        await tester.tap(expand);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Last recorded estimate (update unavailable)'),
          findsWidgets,
        );
        await captureR66Visual(tester, 'rv6-d003-chat-context-text-$scale');
        final lastFact = find.text('Booking amount with balance at delivery');
        expect(lastFact, findsOneWidget);
        final messageList = find.byKey(const Key('chat-message-list'));
        for (
          var swipe = 0;
          swipe < 12 && lastFact.hitTestable().evaluate().isEmpty;
          swipe++
        ) {
          await tester.drag(messageList, const Offset(0, -180));
          await tester.pumpAndSettle();
        }
        expect(lastFact.hitTestable(), findsOneWidget);
        await captureR66Visual(
          tester,
          'rv6-d003-chat-context-last-text-$scale',
        );

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat-thread-screen')), findsNothing);
        expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
        expect(
          find.byKey(const PageStorageKey('buy-tracking-PO-240783')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Medicine order Help stays on Care and returns to Care', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = await readyJourney();
    final chat = ChatSession();
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/buy?sub=medicine&view=tracking&order=RX-240784',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('care-local-destination-tabs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsNothing,
    );
    final help = find.byKey(const ValueKey('buy-tracking-help'));
    await tester.scrollUntilVisible(
      help,
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chat-page-title'))).data,
      'Sardarpura Health Pharmacy',
    );
    expect(find.text('Conversation'), findsNothing);
    expect(find.text('Care Chat'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey('buy-tracking-RX-240784')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('care-local-destination-tabs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsNothing,
    );
  });
}
