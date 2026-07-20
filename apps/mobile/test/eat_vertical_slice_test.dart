import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/eat/eat_models.dart';
import 'package:moolsocial/features/eat/eat_services.dart';
import 'package:moolsocial/features/eat/eat_session.dart';
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
    required EatSession eat,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        eatSession: eat,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byType(Scrollable);
      for (final element in scrollables.evaluate()) {
        if (finder.evaluate().isNotEmpty) break;
        final scrollable = find.byElementPredicate(
          (candidate) => identical(candidate, element),
        );
        final axis = tester.widget<Scrollable>(scrollable).axisDirection;
        if (axis == AxisDirection.left || axis == AxisDirection.right) {
          for (
            var attempt = 0;
            attempt < 10 && finder.evaluate().isEmpty;
            attempt += 1
          ) {
            await tester.drag(scrollable, const Offset(-220, 0));
            await tester.pumpAndSettle();
          }
        } else {
          for (
            var attempt = 0;
            attempt < 10 && finder.evaluate().isEmpty;
            attempt += 1
          ) {
            await tester.drag(scrollable, const Offset(0, -260));
            await tester.pumpAndSettle();
          }
        }
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'food order completes add, duplicate merge, payment, tracking and rating',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final eat = EatSession(
        gateway: ReviewEatOrderGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(eat.dispose);
      await mount(tester, route: '/app/eat/order', journey: journey, eat: eat);

      expect(find.byKey(const Key('eat-order-screen')), findsOneWidget);
      expect(find.textContaining('Wholesale'), findsNothing);
      await tapVisible(tester, const Key('eat-add-veg-thali'));
      await tapVisible(tester, const Key('eat-plus-veg-thali'));
      expect(eat.quantityFor('veg-thali'), 2);
      expect(eat.cartLines.length, 1, reason: 'Duplicate add must merge');

      await tapVisible(tester, const Key('eat-view-basket'));
      expect(find.byKey(const Key('eat-basket-screen')), findsOneWidget);
      await tapVisible(tester, const Key('eat-review-order'));
      expect(find.byKey(const Key('eat-review-screen')), findsOneWidget);
      await tapVisible(tester, const Key('eat-payment-payAtHandoff'));
      await tapVisible(tester, const Key('eat-place-order'));

      expect(find.byKey(const Key('eat-tracking-screen')), findsOneWidget);
      expect(eat.orderReceipt, isNotNull);
      for (var step = 0; step < 4; step += 1) {
        await tapVisible(tester, const Key('eat-refresh-order'));
      }
      expect(eat.orderStage, EatOrderStage.delivered);
      await tapVisible(tester, const Key('eat-complete-order'));
      expect(find.byKey(const Key('eat-completed-screen')), findsOneWidget);

      await tapVisible(tester, const Key('eat-submit-rating'));
      expect(find.text('Choose a rating before submitting.'), findsOneWidget);
      await tapVisible(tester, const Key('eat-rating-5'));
      await tapVisible(tester, const Key('eat-submit-rating'));
      expect(
        find.text('Thank you. Your meal rating was submitted.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'food empty, search, unavailable and cancellation paths are safe',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final eat = EatSession(
        gateway: ReviewEatOrderGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(eat.dispose);
      await mount(tester, route: '/app/eat/basket', journey: journey, eat: eat);

      expect(find.text('Your food basket is empty'), findsOneWidget);
      await tapVisible(tester, const Key('eat-empty-order'));
      await tester.enterText(
        find.byKey(const Key('eat-menu-search')),
        'nothing matches',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching dishes'), findsOneWidget);
      await tapVisible(tester, const Key('eat-menu-show-all'));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
      await tester.pumpAndSettle();
      final horizontalMenu = find.ancestor(
        of: find.byKey(const Key('eat-menu-bestValue')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('eat-menu-snacks')),
        180,
        scrollable: horizontalMenu.first,
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('eat-menu-snacks'));
      final unavailable = find.byKey(const Key('eat-add-samosa'));
      await tester.ensureVisible(unavailable);
      final unavailableButton = tester.widget<FilledButton>(unavailable);
      expect(unavailableButton.onPressed, isNull);
      expect(eat.addMenuItem('samosa'), isFalse);
      expect(eat.errorMessage, contains('not available'));

      eat
        ..clearMessages()
        ..selectMenuCategory(EatMenuCategory.bestValue)
        ..addMenuItem('veg-thali');
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('eat-view-basket'));
      await tapVisible(tester, const Key('eat-review-order'));
      await tapVisible(tester, const Key('eat-place-order'));
      await tapVisible(tester, const Key('eat-cancel-order'));
      await tapVisible(tester, const Key('eat-cancel-order-keep'));
      expect(eat.foodOrderCancelled, isFalse);
      await tapVisible(tester, const Key('eat-cancel-order'));
      await tapVisible(tester, const Key('eat-cancel-order-confirm'));
      expect(eat.foodOrderCancelled, isTrue);
      expect(find.text('Order cancelled'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('payment failure creates no order and exact retry succeeds', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final gateway = ReviewEatOrderGateway(
      failNextFoodOrder: true,
      latency: Duration.zero,
    );
    final eat = EatSession(gateway: gateway)..addMenuItem('veg-thali');
    addTearDown(journey.dispose);
    addTearDown(eat.dispose);
    await mount(tester, route: '/app/eat/review', journey: journey, eat: eat);

    await tapVisible(tester, const Key('eat-place-order'));
    expect(eat.orderReceipt, isNull);
    expect(find.textContaining('No money was deducted'), findsOneWidget);

    await tapVisible(tester, const Key('eat-place-order'));
    expect(eat.orderReceipt, isNotNull);
    expect(find.byKey(const Key('eat-tracking-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home voice and table QR invalid input stays visible then succeeds',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final eat = EatSession();
      addTearDown(journey.dispose);
      addTearDown(eat.dispose);
      await mount(tester, route: '/app/eat/home', journey: journey, eat: eat);

      await tapVisible(tester, const Key('eat-home-voice'));
      await tapVisible(tester, const Key('eat-voice-continue'));
      expect(
        find.text('Type a dish, restaurant or cuisine to search.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const Key('eat-voice-field')), 'cafe');
      await tapVisible(tester, const Key('eat-voice-continue'));
      expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('eat-home-search')), '');
      await tester.pumpAndSettle();

      await tapVisible(tester, const Key('eat-context-find'));
      final search = tester.widget<TextField>(
        find.byKey(const Key('eat-home-search')),
      );
      expect(search.focusNode?.hasFocus, isTrue);
      await tester.enterText(find.byKey(const Key('eat-home-search')), 'Spice');
      await tester.pumpAndSettle();
      expect(find.text('Spice Darbar'), findsWidgets);

      await tapVisible(tester, const Key('eat-context-offers'));
      expect(find.byKey(const Key('eat-offer-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('eat-offer-close'));
      await tapVisible(tester, const Key('eat-context-offers'));
      await tapVisible(tester, const Key('eat-offer-order'));
      expect(find.byKey(const Key('eat-order-screen')), findsOneWidget);

      await mount(tester, route: '/app/eat/home', journey: journey, eat: eat);
      await tapVisible(tester, const Key('eat-context-qr'));
      await tapVisible(tester, const Key('eat-qr-continue'));
      expect(find.text('Enter or scan a valid table code.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('eat-qr-code')), 'SD-T12');
      await tapVisible(tester, const Key('eat-qr-continue'));
      expect(find.byKey(const Key('eat-order-screen')), findsOneWidget);
      expect(eat.fulfilment, EatFulfilment.tableQr);
    },
  );

  testWidgets('table booking confirms, exposes actions and cancels safely', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final eat = EatSession(
      gateway: ReviewEatOrderGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(eat.dispose);
    await mount(tester, route: '/app/eat/table', journey: journey, eat: eat);

    await tapVisible(tester, const Key('eat-table-people-6'));
    await tapVisible(tester, const Key('eat-table-time-800PM'));
    await tapVisible(tester, const Key('eat-table-choice-family-dining'));
    await tapVisible(tester, const Key('eat-table-parking'));
    expect(find.textContaining('parking'), findsWidgets);
    await tapVisible(tester, const Key('eat-book-table'));

    expect(
      find.byKey(const Key('eat-table-confirmation-screen')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('eat-table-qr')), findsOneWidget);
    await tapVisible(tester, const Key('eat-table-directions'));
    await tapVisible(tester, const Key('eat-table-cancel-booking'));
    await tapVisible(tester, const Key('eat-table-keep-booking'));
    expect(eat.tableBookingCancelled, isFalse);
    await tapVisible(tester, const Key('eat-table-cancel-booking'));
    await tapVisible(tester, const Key('eat-table-confirm-cancel'));
    expect(eat.tableBookingCancelled, isTrue);
    expect(find.text('Your table is released'), findsOneWidget);
  });

  testWidgets('table retry and unavailable restaurant preserve selections', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final gateway = ReviewEatOrderGateway(
      failNextTableBooking: true,
      latency: Duration.zero,
    );
    final eat = EatSession(gateway: gateway);
    addTearDown(journey.dispose);
    addTearDown(eat.dispose);
    await mount(tester, route: '/app/eat/table', journey: journey, eat: eat);

    eat.selectTableRestaurant('closed-kitchen');
    await tester.pumpAndSettle();
    expect(eat.tableRestaurantId, 'spice-darbar');
    expect(find.textContaining('no tables today'), findsOneWidget);
    await tapVisible(tester, const Key('dismiss-eat-message'));

    await tapVisible(tester, const Key('eat-book-table'));
    expect(eat.tableReceipt, isNull);
    expect(find.textContaining('just taken'), findsOneWidget);
    await tapVisible(tester, const Key('eat-book-table'));
    expect(eat.tableReceipt, isNotNull);
    expect(
      find.byKey(const Key('eat-table-confirmation-screen')),
      findsOneWidget,
    );
  });

  testWidgets(
    'tiffin plan starts and supports skip, pause, resume and cancel',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final eat = EatSession(
        gateway: ReviewEatOrderGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(eat.dispose);
      await mount(tester, route: '/app/eat/tiffin', journey: journey, eat: eat);

      await tapVisible(tester, const Key('eat-tiffin-style-jain'));
      await tapVisible(tester, const Key('eat-tiffin-meal-dinner'));
      await tapVisible(tester, const Key('eat-tiffin-slot-800PM'));
      await tapVisible(tester, const Key('eat-tiffin-plan-weekly'));
      await tapVisible(tester, const Key('eat-start-tiffin'));

      expect(
        find.byKey(const Key('eat-tiffin-confirmation-screen')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('eat-tiffin-skip-next'));
      expect(eat.nextMealSkipped, isTrue);
      await tapVisible(tester, const Key('eat-tiffin-toggle-pause'));
      expect(eat.tiffinPaused, isTrue);
      await tapVisible(tester, const Key('eat-tiffin-toggle-pause'));
      expect(eat.tiffinPaused, isFalse);
      await tapVisible(tester, const Key('eat-tiffin-cancel-plan'));
      await tapVisible(tester, const Key('eat-tiffin-keep-plan'));
      expect(eat.tiffinCancelled, isFalse);
      await tapVisible(tester, const Key('eat-tiffin-cancel-plan'));
      await tapVisible(tester, const Key('eat-tiffin-confirm-cancel'));
      expect(eat.tiffinCancelled, isTrue);
      expect(find.text('Ends before next cycle'), findsWidgets);
    },
  );

  testWidgets('tiffin invalid address, paused kitchen and retry are explicit', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final gateway = ReviewEatOrderGateway(
      failNextTiffinStart: true,
      latency: Duration.zero,
    );
    final eat = EatSession(gateway: gateway);
    addTearDown(journey.dispose);
    addTearDown(eat.dispose);
    await mount(tester, route: '/app/eat/tiffin', journey: journey, eat: eat);

    eat.selectTiffinKitchen('paused-kitchen');
    await tester.pumpAndSettle();
    expect(eat.selectedKitchenId, 'maa-tiffin');
    expect(find.textContaining('is paused'), findsOneWidget);
    await tapVisible(tester, const Key('dismiss-eat-message'));

    await tapVisible(tester, const Key('eat-tiffin-change-address'));
    await tester.enterText(
      find.byKey(const Key('eat-tiffin-address-field')),
      'x',
    );
    await tapVisible(tester, const Key('eat-tiffin-save-address'));
    expect(find.text('Enter a complete delivery address.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('eat-tiffin-address-field')),
      'Office · Ratanada, Jodhpur',
    );
    await tapVisible(tester, const Key('eat-tiffin-save-address'));

    await tapVisible(tester, const Key('eat-start-tiffin'));
    expect(eat.tiffinReceipt, isNull);
    expect(find.textContaining('No money was deducted'), findsOneWidget);
    await tapVisible(tester, const Key('eat-start-tiffin'));
    expect(eat.tiffinReceipt, isNotNull);
    expect(
      find.byKey(const Key('eat-tiffin-confirmation-screen')),
      findsOneWidget,
    );
  });

  testWidgets('Food primary controls keep 44px targets on compact phones', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final eat = EatSession();
    addTearDown(journey.dispose);
    addTearDown(eat.dispose);
    await mount(
      tester,
      route: '/app/eat/order',
      journey: journey,
      eat: eat,
      size: const Size(360, 800),
    );

    for (final key in const [
      Key('eat-back'),
      Key('eat-open-basket'),
      Key('eat-fulfilment-delivery'),
      Key('eat-add-veg-thali'),
      Key('eat-dock-order'),
      Key('eat-dock-table'),
      Key('eat-dock-tiffin'),
      Key('eat-dock-chat'),
    ]) {
      final finder = find.byKey(key);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Order notices do not leak into table or tiffin journeys', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final eat = EatSession()..addMenuItem('veg-thali');
    addTearDown(journey.dispose);
    addTearDown(eat.dispose);
    await mount(tester, route: '/app/eat/order', journey: journey, eat: eat);

    expect(find.text('Veg thali added to your food basket.'), findsOneWidget);
    await tapVisible(tester, const Key('eat-dock-table'));
    expect(find.byKey(const Key('eat-table-screen')), findsOneWidget);
    expect(find.text('Veg thali added to your food basket.'), findsNothing);

    eat.showNotice('Table preference saved.');
    await tester.pumpAndSettle();
    await tapVisible(tester, const Key('eat-dock-tiffin'));
    expect(find.byKey(const Key('eat-tiffin-screen')), findsOneWidget);
    expect(find.text('Table preference saved.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
