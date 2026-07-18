import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_models.dart';
import 'package:moolsocial/features/buy/buy_services.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
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

  Future<void> mount(
    WidgetTester tester, {
    required String route,
    required JourneySession journey,
    required BuySession buy,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(session: journey, buySession: buy, initialLocation: route),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byType(Scrollable);
      expect(
        scrollables,
        findsWidgets,
        reason: 'No scrollable can reveal tap target $key',
      );
      await tester.scrollUntilVisible(
        finder,
        260,
        scrollable: scrollables.first,
      );
      await tester.pumpAndSettle();
    }
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'home delivery completes catalogue through bill and two-party rating',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final buy = BuySession();
      addTearDown(journey.dispose);
      addTearDown(buy.dispose);
      await mount(
        tester,
        route: '/app/buy/grocery',
        journey: journey,
        buy: buy,
      );

      expect(find.byKey(const Key('buy-catalog-screen')), findsOneWidget);
      expect(find.text('Delivering to your home'), findsOneWidget);
      expect(find.textContaining('Wholesale'), findsNothing);
      expect(find.textContaining('Business bulk'), findsNothing);

      await tapVisible(tester, const Key('buy-open-product-tomato'));
      expect(find.byKey(const Key('buy-product-screen')), findsOneWidget);
      expect(find.text('Mahadev Fresh Mart'), findsWidgets);
      await tapVisible(tester, const Key('buy-product-primary'));
      expect(buy.quantityFor('tomato'), 1);
      await tapVisible(tester, const Key('buy-product-primary'));

      expect(find.byKey(const Key('buy-basket-screen')), findsOneWidget);
      await tapVisible(tester, const Key('buy-plus-tomato'));
      expect(buy.quantityFor('tomato'), 2);
      expect(buy.cartLines.length, 1, reason: 'Duplicate add must merge');
      await tapVisible(tester, const Key('buy-delivery-time-1'));
      await tapVisible(tester, const Key('buy-unavailable-remove'));
      expect(buy.fulfilment, BuyFulfilment.homeDelivery);
      expect(buy.unavailableItemRule, UnavailableItemRule.remove);

      await tapVisible(tester, const Key('buy-review-order'));
      expect(find.byKey(const Key('buy-review-screen')), findsOneWidget);
      await tapVisible(tester, const Key('buy-payment-cashOnDelivery'));
      await tapVisible(tester, const Key('buy-place-order'));

      expect(find.byKey(const Key('buy-tracking-screen')), findsOneWidget);
      expect(buy.receipt, isNotNull);
      for (var step = 0; step < 4; step++) {
        await tapVisible(tester, const Key('buy-refresh-status'));
      }
      expect(buy.orderStage, BuyOrderStage.delivered);
      await tapVisible(tester, const Key('buy-check-arrival'));

      expect(find.byKey(const Key('buy-completed-screen')), findsOneWidget);
      await tapVisible(tester, const Key('buy-rate-order'));
      await tapVisible(tester, const Key('buy-submit-rating'));
      expect(
        find.text('Rate both the shop and rider before submitting.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('buy-rate-shop-5'));
      await tapVisible(tester, const Key('buy-rate-rider-5'));
      await tapVisible(tester, const Key('buy-submit-rating'));
      expect(buy.ratingSubmitted, isTrue);
      expect(find.text('Ratings submitted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty, invalid, sold-out and cancelled paths remain safe', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final buy = BuySession();
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await mount(tester, route: '/app/buy/basket', journey: journey, buy: buy);

    expect(find.text('Your basket is empty'), findsOneWidget);
    await tapVisible(tester, const Key('buy-empty-browse'));
    await tester.enterText(
      find.byKey(const Key('buy-search-field')),
      'nothing matches',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching products'), findsOneWidget);
    await tapVisible(tester, const Key('buy-clear-empty-search'));

    await tapVisible(tester, const Key('buy-category-fresh'));
    final soldOut = find.byKey(const Key('buy-add-mango'));
    await tester.ensureVisible(soldOut);
    await tester.pumpAndSettle();
    final soldOutButton = tester.widget<FilledButton>(soldOut);
    expect(soldOutButton.onPressed, isNull);

    await tapVisible(tester, const Key('buy-choose-store-pickup'));
    await tapVisible(tester, const Key('buy-keep-home-delivery'));
    expect(buy.fulfilment, BuyFulfilment.homeDelivery);

    await tapVisible(tester, const Key('buy-choose-store-pickup'));
    await tapVisible(tester, const Key('buy-pickup-mahadev'));
    expect(buy.fulfilment, BuyFulfilment.storePickup);
    expect(buy.pickupStore, contains('Mahadev'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('coupon validation does not mutate the basket falsely', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final buy = BuySession()
      ..addProduct('tomato')
      ..addProduct('atta');
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await mount(tester, route: '/app/buy/basket', journey: journey, buy: buy);

    await tapVisible(tester, const Key('buy-apply-coupon'));
    await tapVisible(tester, const Key('buy-submit-coupon'));
    expect(find.text('Enter a coupon code.'), findsOneWidget);
    expect(buy.discount, 0);
    await tester.enterText(find.byKey(const Key('buy-coupon-field')), 'WRONG');
    await tapVisible(tester, const Key('buy-submit-coupon'));
    expect(find.text('This coupon is not valid.'), findsOneWidget);
    expect(buy.discount, 0);
    await tester.enterText(find.byKey(const Key('buy-coupon-field')), 'MOOL50');
    await tapVisible(tester, const Key('buy-submit-coupon'));
    expect(buy.discount, 50);
    expect(find.textContaining('MOOL50 applied'), findsWidgets);
  });

  testWidgets('failed payment retries once without a duplicate order', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final gateway = ReviewBuyOrderGateway(failNextRequest: true);
    final buy = BuySession(orderGateway: gateway)
      ..addProduct('tomato')
      ..addProduct('atta');
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await mount(tester, route: '/app/buy/review', journey: journey, buy: buy);

    await tapVisible(tester, const Key('buy-place-order'));
    expect(buy.receipt, isNull);
    expect(
      find.text(
        'Payment could not be completed. No money was deducted. Try again.',
      ),
      findsOneWidget,
    );
    await tapVisible(tester, const Key('buy-place-order'));
    expect(find.byKey(const Key('buy-tracking-screen')), findsOneWidget);
    expect(buy.receipt, isNotNull);
    expect(buy.receipt!.lines.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking nested actions validate and complete visibly', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final buy = BuySession(
      orderGateway: ReviewBuyOrderGateway(latency: Duration.zero),
    )..addProduct('tomato');
    await buy.placeOrder();
    buy
      ..refreshOrderStatus()
      ..refreshOrderStatus();
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await mount(
      tester,
      route: '/app/buy/order/${buy.receipt!.id}',
      journey: journey,
      buy: buy,
    );

    await tapVisible(tester, const Key('buy-call-rider'));
    await tapVisible(tester, const Key('buy-confirm-call-rider'));
    expect(find.textContaining('Calling the rider'), findsOneWidget);

    await tapVisible(tester, const Key('buy-edit-instructions'));
    await tester.enterText(find.byKey(const Key('buy-instruction-field')), '');
    await tapVisible(tester, const Key('buy-save-instruction'));
    expect(find.text('Enter at least 3 characters.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('buy-instruction-field')),
      'Gate 2',
    );
    await tapVisible(tester, const Key('buy-save-instruction'));
    expect(find.text('Delivery note updated.'), findsOneWidget);

    await tapVisible(tester, const Key('buy-share-location'));
    await tapVisible(tester, const Key('buy-confirm-share-location'));
    expect(find.textContaining('Live location sharing is on'), findsOneWidget);

    await tapVisible(tester, const Key('buy-report-delay'));
    await tapVisible(tester, const Key('buy-confirm-report-delay'));
    expect(find.textContaining('Support is checking'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed order problem validates, submits and opens support', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final buy = BuySession(
      orderGateway: ReviewBuyOrderGateway(latency: Duration.zero),
    )..addProduct('tomato');
    await buy.placeOrder();
    for (var step = 0; step < 4; step++) {
      buy.refreshOrderStatus();
    }
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await mount(
      tester,
      route: '/app/buy/order/${buy.receipt!.id}/completed',
      journey: journey,
      buy: buy,
    );

    await tapVisible(tester, const Key('buy-report-problem'));
    await tapVisible(tester, const Key('buy-submit-problem'));
    expect(find.text('Choose the item with a problem.'), findsOneWidget);
    await tapVisible(tester, const Key('buy-problem-product-tomato'));
    await tapVisible(tester, const Key('buy-problem-issue-0'));
    await tapVisible(tester, const Key('buy-problem-resolution-0'));
    await tapVisible(tester, const Key('buy-problem-photo'));
    await tapVisible(tester, const Key('buy-submit-problem'));

    expect(
      find.byKey(const Key('buy-problem-submitted-screen')),
      findsOneWidget,
    );
    await tapVisible(tester, const Key('buy-chat-case-support'));
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.text('Order Support'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'explicit store collection completes ready code, handoff and shop rating',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final buy =
          BuySession(
              orderGateway: ReviewBuyOrderGateway(latency: Duration.zero),
            )
            ..chooseStorePickup('Mahadev Fresh Mart · Sardarpura')
            ..addProduct('tomato');
      addTearDown(journey.dispose);
      addTearDown(buy.dispose);
      await mount(tester, route: '/app/buy/review', journey: journey, buy: buy);

      expect(find.text('Collect from store'), findsOneWidget);
      await tapVisible(tester, const Key('buy-place-order'));
      expect(find.byKey(const Key('buy-collection-screen')), findsOneWidget);

      await tapVisible(tester, const Key('buy-confirm-collection'));
      expect(
        find.text('Wait until the shop marks your basket ready.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('buy-refresh-collection'));
      await tapVisible(tester, const Key('buy-refresh-collection'));
      expect(buy.collectionStage, BuyCollectionStage.ready);
      expect(find.text('4 7 2 9'), findsOneWidget);

      await tapVisible(tester, const Key('buy-collection-directions'));
      expect(find.text('Directions opened for the store.'), findsOneWidget);
      await tapVisible(tester, const Key('buy-call-shop'));
      await tapVisible(tester, const Key('buy-confirm-call-shop'));
      expect(find.text('Calling Mahadev Fresh Mart.'), findsOneWidget);

      await tapVisible(tester, const Key('buy-change-collection-person'));
      await tapVisible(tester, const Key('buy-save-collector'));
      expect(find.text('Enter the collector name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('buy-collector-name')),
        'Amit',
      );
      await tapVisible(tester, const Key('buy-save-collector'));
      expect(find.textContaining('Amit can collect'), findsOneWidget);

      await tapVisible(tester, const Key('buy-confirm-collection'));
      expect(
        find.byKey(const Key('buy-collection-completed-screen')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('buy-rate-collection'));
      await tapVisible(tester, const Key('buy-submit-collection-rating'));
      expect(find.text('Rate the shop before submitting.'), findsOneWidget);
      await tapVisible(tester, const Key('buy-rate-collection-shop-5'));
      await tapVisible(tester, const Key('buy-submit-collection-rating'));
      expect(buy.ratingSubmitted, isTrue);
      expect(find.text('Rating submitted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('order dock preserves the selected collection lifecycle', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final buy =
        BuySession(orderGateway: ReviewBuyOrderGateway(latency: Duration.zero))
          ..chooseStorePickup('Mahadev Fresh Mart · Sardarpura')
          ..addProduct('atta');
    await buy.placeOrder();
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await mount(tester, route: '/app/buy/grocery', journey: journey, buy: buy);

    await tapVisible(tester, const Key('buy-dock-orders'));
    expect(find.byKey(const Key('buy-collection-screen')), findsOneWidget);
    expect(find.byKey(const Key('buy-tracking-screen')), findsNothing);
  });

  testWidgets('compact phone keeps primary buy controls tappable', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final journey = await readyJourney();
    final buy = BuySession();
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await mount(
      tester,
      route: '/app/buy/grocery',
      journey: journey,
      buy: buy,
      size: const Size(360, 800),
    );

    for (final key in const [
      Key('buy-back'),
      Key('buy-open-basket'),
      Key('buy-change-address'),
      Key('buy-choose-store-pickup'),
      Key('buy-dock-mool'),
      Key('buy-dock-shop'),
      Key('buy-dock-basket'),
      Key('buy-dock-orders'),
      Key('buy-dock-chat'),
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    expect(tester.takeException(), isNull);
  });
}
