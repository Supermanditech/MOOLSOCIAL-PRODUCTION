import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_chat_route_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
          returnKey: 'buy-orders-tab-active',
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
    expect(
      find.bySemanticsLabel('Open your MoolSocial profile'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-catalogue-motion-tween-wholesale')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('order Help stays in one Assist conversation with one composer', (
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
        initialLocation: '/app/buy?sub=orders&view=tracking&order=PO-240783',
      ),
    );
    await tester.pumpAndSettle();

    final help = find.byKey(const ValueKey('buy-tracking-help'));
    await tester.scrollUntilVisible(
      help,
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.text('MoolSocial Assist'), findsWidgets);
    expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
    expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
    expect(find.text('Search conversations'), findsNothing);
    expect(find.byKey(const Key('chat-suggested-prompts')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller
          ?.text,
      'Help with order PO-240783',
    );

    await tester.tap(find.byKey(const Key('chat-suggested-prompt-0')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller
          ?.text,
      'Help with order PO-240783\nWhere is my order?',
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
  });
}
