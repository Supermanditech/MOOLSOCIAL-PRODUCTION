import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_shop_chat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    VoidCallback? onOpenChat,
    BuyV2ShopChatActionHandler? onShopChatAction,
    BuyV2ShopChatProvisioningSource shopChatSource =
        const BuyV2SessionShopChatProvisioningSource(),
    VoidCallback? onExit,
    double textScale = 1,
    EdgeInsets safePadding = EdgeInsets.zero,
    bool disableAnimations = true,
    BuyV2Destination initialDestination = BuyV2Destination.shop,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: safePadding,
          viewPadding: safePadding,
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: BuyV2Screen(
        session: session,
        initialDestination: initialDestination,
        onOpenChat: onOpenChat,
        onShopChatAction: onShopChatAction,
        shopChatSource: shopChatSource,
        onExit: onExit,
      ),
    );
  }

  test('Shop Chat route adapter preserves commerce context and return', () {
    const adapter = BuyV2ShopChatRouteAdapter();
    const cases =
        <
          ({
            BuyV2Destination destination,
            bool offersActive,
            String origin,
            String? type,
          })
        >[
          (
            destination: BuyV2Destination.shop,
            offersActive: false,
            origin: '/app/buy',
            type: null,
          ),
          (
            destination: BuyV2Destination.orders,
            offersActive: false,
            origin: '/app/buy?sub=orders',
            type: 'order',
          ),
          (
            destination: BuyV2Destination.wholesale,
            offersActive: false,
            origin: '/app/buy?sub=wholesale',
            type: 'business',
          ),
          (
            destination: BuyV2Destination.shop,
            offersActive: true,
            origin: '/app/buy?sub=offers',
            type: 'support',
          ),
          (
            destination: BuyV2Destination.medicine,
            offersActive: false,
            origin: '/app/book?sub=medicine',
            type: 'business',
          ),
        ];

    for (final entry in cases) {
      final uri = Uri.parse(
        adapter.locationFor(
          currentRoute: entry.origin,
          destination: entry.destination,
          offersActive: entry.offersActive,
        ),
      );
      expect(uri.path, '/app/chat/inbox', reason: entry.origin);
      expect(uri.queryParameters['type'], entry.type, reason: entry.origin);
      expect(uri.queryParameters['return'], entry.origin, reason: entry.origin);
      expect(uri.queryParameters.containsKey('start'), isFalse);
      expect(uri.queryParameters.containsKey('draft'), isFalse);
    }
  });

  testWidgets(
    'Shop Chat opens a conversation and delegates send to production Chat',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      var productionChatCalls = 0;

      await tester.pumpWidget(
        app(
          session,
          safePadding: const EdgeInsets.symmetric(vertical: 24),
          onOpenChat: () => productionChatCalls += 1,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(find.text('Shop Chat'), findsOneWidget);
      expect(find.text('Shop · partners, orders and offers'), findsOneWidget);
      expect(
        find.textContaining(BuyV2ShopChatPresentation.shop.securityMessage),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-chat')),
          matching: find.textContaining(
            RegExp(r'\bsecure(?:ly)?\b|\bencrypt', caseSensitive: false),
          ),
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-search')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-search-band')), findsNothing);
      expect(
        find.byKey(const ValueKey('moolsocial-single-home-launcher-shell')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('mool-global-chat-tap')), findsNothing);
      expect(productionChatCalls, 0);

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-order-MS-240782')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );
      expect(find.text('Order MS-240782'), findsWidgets);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      expect(productionChatCalls, 0);

      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-composer-field')),
        'Please help with this order',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-send')));
      await tester.pump();
      expect(productionChatCalls, 1);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-back')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-open-all')));
      await tester.pump();
      expect(productionChatCalls, 2);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('moolsocial-single-home-launcher-shell')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Shop Chat opens shared Chat and Android Back restores exact Buy origin',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      Uri? handoffUri;
      late final GoRouter router;
      router = GoRouter(
        initialLocation: '/app/buy',
        routes: [
          GoRoute(
            path: '/app/buy',
            builder: (context, state) => BuyV2Screen(session: session),
          ),
          GoRoute(
            path: '/app/chat/inbox',
            builder: (context, state) {
              handoffUri = state.uri;
              return const Scaffold(body: Text('Production Chat inbox'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();

      expect(find.text('Production Chat inbox'), findsOneWidget);
      expect(handoffUri?.path, '/app/chat/inbox');
      expect(handoffUri?.queryParameters.containsKey('type'), isFalse);
      expect(handoffUri?.queryParameters['return'], '/app/buy');
      expect(handoffUri?.queryParameters.containsKey('start'), isFalse);
      expect(handoffUri?.queryParameters.containsKey('draft'), isFalse);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Production Chat inbox'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mool-global-chat-tap')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'live provisioning refreshes the open thread and recovers removed context',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      final source = _LiveShopChatSource();
      addTearDown(source.dispose);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(app(session, shopChatSource: source));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-live-support')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-live-message')),
        findsNothing,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(find.text('Forward to Live order support'), findsOneWidget);

      source.publishIncomingMessage();
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-live-message')),
        findsOneWidget,
      );
      expect(find.text('Your live order update is ready.'), findsOneWidget);

      final liveMessage = find.byKey(
        const ValueKey('buy-shop-chat-message-live-message'),
      );
      await tester.longPress(liveMessage);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Forward to message actions'), findsOneWidget);

      source.publishIncomingMessage(body: 'Your updated live order is ready.');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-reply')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
          matching: find.text('Your updated live order is ready.'),
        ),
        findsOneWidget,
      );

      source.removeConversation();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-shop-chat-thread')), findsNothing);
      expect(
        find.text('No Shop conversations are available yet'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'async provisioning shows truthful loading failure and retry states',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      final source = _LoadingShopChatSource();
      addTearDown(source.dispose);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(app(session, shopChatSource: source));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Loading Shop conversations'), findsOneWidget);
      expect(
        find.text('No Shop conversations are available yet'),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Loading Shop conversations'), findsOneWidget);

      source.failLoading();
      await tester.pumpAndSettle();
      expect(find.text('Shop conversations couldn’t load'), findsOneWidget);
      expect(
        find.text('Chat service is unavailable right now. Try again.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new-retry')));
      await tester.pumpAndSettle();
      expect(source.retryCalls, 1);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-new-live-support')),
        findsOneWidget,
      );
      expect(find.text('Loading Shop conversations'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Shop subactions seed the matching Chat filter and return cleanly',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();

      final ordersChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('buy-shop-chat-filter-orders')),
      );
      expect(ordersChip.selected, isTrue);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-entry-order-MS-240782')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      final offersChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('buy-shop-chat-filter-offers')),
      );
      expect(offersChip.selected, isTrue);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-entry-offer-details')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      final sellersChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('buy-shop-chat-filter-sellers')),
      );
      expect(sellersChip.selected, isTrue);
      expect(
        find.text('Wholesale · partners, orders and offers'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Medicine global Chat opens the isolated Care conversation context',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        app(session, initialDestination: BuyV2Destination.medicine),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('care-local-destination-tabs')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      expect(find.text('Care Chat'), findsOneWidget);
      expect(find.text('Medicine · appointments and services'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('buy-shop-chat-filter-medicine')),
            )
            .selected,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-entry-care-medicine-desk')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-care-medicine-desk')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-commerce-context')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      expect(
        find.byKey(const ValueKey('care-local-destination-tabs')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Shop Chat navigation uses finite directional motion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(app(session, disableAnimations: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pump();
    final forward = tester.widget<Transform>(
      find.byKey(const ValueKey('buy-navigation-surface-translation')),
    );
    expect(forward.transform.getTranslation().x, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
    await tester.pump();
    final back = tester.widget<Transform>(
      find.byKey(const ValueKey('buy-navigation-surface-translation')),
    );
    expect(back.transform.getTranslation().x, lessThan(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop Chat filters and searches truthful conversation starters', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-filter-sellers')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-partner')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-shop-chat-entry-wholesale-partner')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('buy-shop-chat-search')),
      'wholesale',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-partner')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-shop-chat-entry-wholesale-partner')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('buy-shop-chat-search')),
      'missing conversation',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No conversations match “missing conversation”'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-shop-chat-empty-clear-search')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop Chat back gesture returns to the exact Shop surface', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    var exitCalls = 0;

    await tester.pumpWidget(app(session, onExit: () => exitCalls += 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.text('Fresh picks'), findsOneWidget);
    expect(session.destination, BuyV2Destination.shop);
    expect(exitCalls, 0);
  });

  testWidgets('Shop Chat remains usable at compact and accessible viewports', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final viewport in const [
      (size: Size(320, 568), scale: 1.4),
      (size: Size(390, 844), scale: 1.0),
      (size: Size(430, 932), scale: 1.4),
    ]) {
      tester.view.physicalSize = viewport.size;
      final core = BuySession();
      final session = BuyV2Session(core: core);
      await tester.pumpWidget(
        app(
          session,
          shopChatSource: const _RichShopChatSource(),
          textScale: viewport.scale,
          safePadding: const EdgeInsets.symmetric(vertical: 24),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '${viewport.size}');
      for (final key in const [
        'buy-shop-chat-back',
        'buy-shop-chat-open-all',
        'buy-shop-chat-search',
        'buy-shop-chat-new',
      ]) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
        expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
      }

      await tester.ensureVisible(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'thread ${viewport.size}');
      for (final key in const [
        'buy-shop-chat-thread-back',
        'buy-shop-chat-voice-call',
        'buy-shop-chat-video-call',
        'buy-shop-chat-thread-more',
        'buy-shop-chat-attach',
        'buy-shop-chat-composer-field',
        'buy-shop-chat-voice',
      ]) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
        expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
      }
      final forwardMessage = find.byKey(
        const ValueKey('buy-shop-chat-forward-received-text'),
      );
      await tester.ensureVisible(forwardMessage);
      final forwardMessageSize = tester.getSize(forwardMessage);
      expect(forwardMessageSize.width, greaterThanOrEqualTo(44));
      expect(forwardMessageSize.height, greaterThanOrEqualTo(44));
      expect(
        tester.takeException(),
        isNull,
        reason: 'message ${viewport.size}',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
      core.dispose();
    }
  });

  testWidgets('empty Chat inbox and picker provide one-tap global recovery', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    var openAllCalls = 0;

    await tester.pumpWidget(
      app(
        session,
        shopChatSource: const _EmptyShopChatSource(),
        textScale: 1.4,
        onOpenChat: () => openAllCalls += 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();

    expect(
      find.text('No Shop conversations are available yet'),
      findsOneWidget,
    );
    final inboxRecovery = find.byKey(
      const ValueKey('buy-shop-chat-empty-open-all'),
    );
    expect(tester.getSize(inboxRecovery).height, greaterThanOrEqualTo(44));
    await tester.tap(inboxRecovery);
    await tester.pumpAndSettle();
    expect(openAllCalls, 1);

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
    await tester.pumpAndSettle();
    expect(find.text('No Shop conversation choices yet'), findsOneWidget);
    final pickerRecovery = find.byKey(
      const ValueKey('buy-shop-chat-new-open-all'),
    );
    expect(tester.getSize(pickerRecovery).height, greaterThanOrEqualTo(44));
    await tester.tap(pickerRecovery);
    await tester.pumpAndSettle();
    expect(openAllCalls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chat search and filter misses recover in one tap', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(
      app(session, shopChatSource: const _RichShopChatSource()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('buy-shop-chat-search')),
      'no such partner',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No conversations match “no such partner”'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-empty-clear-search')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-filter-orders')));
    await tester.pumpAndSettle();
    expect(find.text('No Orders conversations yet'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-empty-show-all')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'composer keeps keyboard emoji and attachment surfaces mutually exclusive',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        app(
          session,
          shopChatSource: const _RichShopChatSource(),
          textScale: 1.4,
          safePadding: const EdgeInsets.symmetric(vertical: 24),
          onShopChatAction: (_) async =>
              const BuyV2ShopChatActionResult.accepted(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('buy-shop-chat-composer-field'));
      final composer = find.byKey(const ValueKey('buy-shop-chat-composer'));
      await tester.tap(field);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(composer).dy, lessThanOrEqualTo(328));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-emoji-tray')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-emoji-tray')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsOneWidget,
      );
      final document = find.byKey(
        const ValueKey('buy-shop-chat-attach-selectDocument'),
      );
      expect(tester.getSize(document).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(document).height, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel('Share Document'), findsOneWidget);

      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-emoji-tray')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsNothing,
      );
      expect(tester.getBottomRight(composer).dy, lessThanOrEqualTo(328));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('message semantics expose content status and discoverable actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final actions = <BuyV2ShopChatAction>[];

    await tester.pumpWidget(
      app(
        session,
        shopChatSource: const _RichShopChatSource(),
        onShopChatAction: (action) async {
          actions.add(action);
          return const BuyV2ShopChatActionResult.accepted();
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
    );
    await tester.pumpAndSettle();

    final received = find.bySemanticsLabel(
      'Received message from Mahadev Fresh Mart at 10:36. Your fresh grocery basket is ready to review.',
    );
    expect(received, findsOneWidget);
    final receivedData = tester.getSemantics(received).getSemanticsData();
    expect(receivedData.hint, 'Long press for Reply, Like, Copy, and Forward.');
    expect(receivedData.hasAction(SemanticsAction.longPress), isTrue);
    expect(receivedData.hasAction(SemanticsAction.tap), isFalse);

    final sent = find.bySemanticsLabel(
      'Sent message at 10:38. Can it arrive tomorrow morning? Read.',
    );
    expect(sent, findsOneWidget);
    expect(
      tester
          .getSemantics(sent)
          .getSemanticsData()
          .hasAction(SemanticsAction.longPress),
      isTrue,
    );

    final photo = find.bySemanticsLabel(
      'Received photo from Mahadev Fresh Mart at 10:40. Basket photo. These are the available packs. JPG · 1.8 MB.',
    );
    expect(photo, findsOneWidget);
    final photoData = tester.getSemantics(photo).getSemanticsData();
    expect(
      photoData.hint,
      'Double tap to open. Long press for Reply, Like, Copy, and Forward.',
    );
    expect(photoData.hasAction(SemanticsAction.tap), isTrue);
    expect(photoData.hasAction(SemanticsAction.longPress), isTrue);

    final receivedMessage = find.byKey(
      const ValueKey('buy-shop-chat-message-received-text'),
    );
    await tester.longPress(receivedMessage);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-reply')));
    await tester.pumpAndSettle();
    expect(find.text('Replying to Mahadev Fresh Mart'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Replying to Mahadev Fresh Mart. Your fresh grocery basket is ready to review.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Cancel reply'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel reply'));
    await tester.pumpAndSettle();

    await tester.longPress(receivedMessage);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Like'), findsOneWidget);
    expect(find.byTooltip('React'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-react')));
    await tester.pumpAndSettle();
    expect(actions.single.kind, BuyV2ShopChatActionKind.reactToMessage);
    expect(actions.single.messageId, 'received-text');
    expect(actions.single.text, 'like');
    expect(tester.takeException(), isNull);
  });

  testWidgets('composer media and calls emit exact inline runtime intents', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final actions = <BuyV2ShopChatAction>[];

    await tester.pumpWidget(
      app(
        session,
        shopChatSource: const _RichShopChatSource(),
        onShopChatAction: (action) async {
          actions.add(action);
          return const BuyV2ShopChatActionResult.accepted();
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-attach-selectMedia')),
    );
    await tester.pumpAndSettle();
    expect(actions.last.kind, BuyV2ShopChatActionKind.selectMedia);
    expect(actions.last.threadId, 'retail-live');

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-voice-call')));
    await tester.pumpAndSettle();
    expect(actions.last.kind, BuyV2ShopChatActionKind.startVoiceCall);

    await tester.enterText(
      find.byKey(const ValueKey('buy-shop-chat-composer-field')),
      'Can this arrive tomorrow?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-send')));
    await tester.pumpAndSettle();
    expect(actions.last.kind, BuyV2ShopChatActionKind.sendText);
    expect(actions.last.text, 'Can this arrive tomorrow?');
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('buy-shop-chat-composer-field')),
          )
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('every inline attachment action dispatches on its second tap', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final actions = <BuyV2ShopChatAction>[];

    await tester.pumpWidget(
      app(
        session,
        shopChatSource: const _RichShopChatSource(),
        onShopChatAction: (action) async {
          actions.add(action);
          return const BuyV2ShopChatActionResult.accepted();
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
    );
    await tester.pumpAndSettle();

    for (final kind in const [
      BuyV2ShopChatActionKind.selectDocument,
      BuyV2ShopChatActionKind.captureImage,
      BuyV2ShopChatActionKind.selectMedia,
      BuyV2ShopChatActionKind.shareProduct,
      BuyV2ShopChatActionKind.shareOrder,
      BuyV2ShopChatActionKind.shareLocation,
      BuyV2ShopChatActionKind.shareContact,
    ]) {
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(ValueKey('buy-shop-chat-attach-${kind.name}')),
      );
      await tester.pumpAndSettle();
      expect(actions.last.kind, kind);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsNothing,
      );
    }

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-camera')));
    await tester.pumpAndSettle();
    expect(actions.last.kind, BuyV2ShopChatActionKind.captureImage);
    expect(
      find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-video-call')));
    await tester.pumpAndSettle();
    expect(actions.last.kind, BuyV2ShopChatActionKind.startVideoCall);
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-voice')));
    await tester.pumpAndSettle();
    expect(actions.last.kind, BuyV2ShopChatActionKind.recordVoice);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reply payload belongs to one accepted message-producing action',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final actions = <BuyV2ShopChatAction>[];

      await tester.pumpWidget(
        app(
          session,
          shopChatSource: const _RichShopChatSource(),
          onShopChatAction: (action) async {
            actions.add(action);
            return const BuyV2ShopChatActionResult.accepted();
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();

      final receivedMessage = find.byKey(
        const ValueKey('buy-shop-chat-message-received-text'),
      );
      await tester.ensureVisible(receivedMessage);
      await tester.longPress(receivedMessage);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-reply')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-voice-call')));
      await tester.pumpAndSettle();
      expect(actions.last.kind, BuyV2ShopChatActionKind.startVoiceCall);
      expect(actions.last.replyToMessageId, isNull);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-attach-selectDocument')),
      );
      await tester.pumpAndSettle();
      expect(actions.last.kind, BuyV2ShopChatActionKind.selectDocument);
      expect(actions.last.replyToMessageId, 'received-text');
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'conversation picker stays inside Chat and opens the selected partner',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-shop-chat-new-surface')),
        findsOneWidget,
      );
      expect(find.text('Choose a Shop conversation'), findsOneWidget);
      expect(
        find.textContaining(
          RegExp(r'\bnew\s+Shop\s+conversation\b', caseSensitive: false),
        ),
        findsNothing,
      );
      expect(find.byType(BottomSheet), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Forward to Shop conversation choices'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-new-surface')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-new-manufacturer-partner')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );
      expect(find.text('Mool Manufacturer'), findsWidgets);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('conversation picker exposes every same-type target', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
    await tester.pumpAndSettle();

    final picker = find.byType(Scrollable).last;
    final details = find.byKey(
      const ValueKey('buy-shop-chat-new-offer-details'),
    );
    await tester.scrollUntilVisible(details, 120, scrollable: picker);
    expect(details, findsOneWidget);
    final checkout = find.byKey(
      const ValueKey('buy-shop-chat-new-offer-checkout'),
    );
    await tester.scrollUntilVisible(checkout, 120, scrollable: picker);
    expect(checkout, findsOneWidget);
    expect(tester.getSize(checkout).height, greaterThanOrEqualTo(64));

    await tester.tap(checkout);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat-thread')), findsOneWidget);
    expect(find.text('Offer and checkout help'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conversation picker retains scroll through Back and Forward', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
    await tester.pumpAndSettle();

    final pickerKey = const PageStorageKey<String>(
      'buy-shop-chat-new-list-shop',
    );
    final picker = find.byKey(pickerKey);
    final checkout = find.byKey(
      const ValueKey('buy-shop-chat-new-offer-checkout'),
    );
    await tester.scrollUntilVisible(
      checkout,
      120,
      scrollable: find.descendant(
        of: picker,
        matching: find.byType(Scrollable),
      ),
    );
    final beforeBack = tester
        .state<ScrollableState>(
          find.descendant(of: picker, matching: find.byType(Scrollable)),
        )
        .position
        .pixels;
    expect(beforeBack, greaterThan(0));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-history-forward')),
    );
    await tester.pumpAndSettle();

    final restoredPicker = find.byKey(pickerKey);
    final afterForward = tester
        .state<ScrollableState>(
          find.descendant(
            of: restoredPicker,
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(afterForward, closeTo(beforeBack, 0.1));
    expect(checkout, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'conversation inbox retains its filtered scroll on thread return',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();

      final inboxKey = const PageStorageKey<String>(
        'buy-shop-chat-results-shop-all',
      );
      final inbox = find.byKey(inboxKey);
      final offer = find.byKey(
        const ValueKey('buy-shop-chat-entry-offer-details'),
      );
      await tester.scrollUntilVisible(
        offer,
        120,
        scrollable: find.descendant(
          of: inbox,
          matching: find.byType(Scrollable),
        ),
      );
      final beforeThread = tester
          .state<ScrollableState>(
            find.descendant(of: inbox, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      expect(beforeThread, greaterThan(0));

      await tester.tap(offer);
      await tester.pumpAndSettle();
      expect(find.text('Offer details'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-back')));
      await tester.pumpAndSettle();

      final restoredInbox = find.byKey(inboxKey);
      final afterReturn = tester
          .state<ScrollableState>(
            find.descendant(
              of: restoredInbox,
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;
      expect(afterReturn, closeTo(beforeThread, 0.1));
      expect(offer, findsOneWidget);
      expect(find.text('Forward to Offer details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rejected send keeps the draft and gives a truthful recovery', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(
      app(
        session,
        shopChatSource: const _RichShopChatSource(),
        onShopChatAction: (_) async =>
            const BuyV2ShopChatActionResult.unavailable(
              'Message was not sent. Try again.',
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-shop-chat-composer-field')),
      'Please check this order',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-send')));
    await tester.pumpAndSettle();

    expect(find.text('Message was not sent. Try again.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('buy-shop-chat-composer-field')),
          )
          .controller!
          .text,
      'Please check this order',
    );
  });

  testWidgets('thrown Chat actions restore send direct and info retry paths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final actions = <BuyV2ShopChatAction>[];
    final failures = <BuyV2ShopChatActionKind>{
      BuyV2ShopChatActionKind.sendText,
      BuyV2ShopChatActionKind.captureImage,
      BuyV2ShopChatActionKind.manageNotifications,
    };

    await tester.pumpWidget(
      app(
        session,
        shopChatSource: const _RichShopChatSource(),
        onShopChatAction: (action) async {
          actions.add(action);
          if (failures.remove(action.kind)) {
            throw StateError('runtime detail stays out of customer copy');
          }
          return const BuyV2ShopChatActionResult.accepted();
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('buy-shop-chat-composer-field')),
      'Please retry this message',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('Message wasn’t sent. Try again.'), findsOneWidget);
    expect(find.textContaining('Chat could not continue'), findsNothing);
    expect(find.textContaining('runtime detail'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('buy-shop-chat-composer-field')),
          )
          .controller!
          .text,
      'Please retry this message',
    );
    expect(find.byKey(const ValueKey('buy-shop-chat-send')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-send')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('buy-shop-chat-composer-field')),
          )
          .controller!
          .text,
      isEmpty,
    );

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-camera')));
    await tester.pumpAndSettle();
    expect(find.text('That item wasn’t added. Try again.'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-shop-chat-camera')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-camera')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-info')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.text('Notification settings couldn’t open. Try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(
      actions.where(
        (action) => action.kind == BuyV2ShopChatActionKind.sendText,
      ),
      hasLength(2),
    );
    expect(
      actions.where(
        (action) => action.kind == BuyV2ShopChatActionKind.captureImage,
      ),
      hasLength(2),
    );
    expect(
      actions.where(
        (action) => action.kind == BuyV2ShopChatActionKind.manageNotifications,
      ),
      hasLength(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chat info prevents duplicate actions and restores controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final firstCall = Completer<BuyV2ShopChatActionResult>();
    final actions = <BuyV2ShopChatAction>[];

    await tester.pumpWidget(
      app(
        session,
        shopChatSource: const _RichShopChatSource(),
        textScale: 1.4,
        onShopChatAction: (action) {
          actions.add(action);
          if (actions.length == 1) return firstCall.future;
          return Future.value(const BuyV2ShopChatActionResult.accepted());
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-info')));
    await tester.pumpAndSettle();

    final voice = find.byKey(const ValueKey('buy-shop-chat-info-voice-call'));
    final video = find.byKey(const ValueKey('buy-shop-chat-info-video-call'));
    expect(find.bySemanticsLabel('Start voice call'), findsOneWidget);
    expect(find.bySemanticsLabel('Start video call'), findsOneWidget);
    await tester.tap(voice);
    await tester.pump();
    expect(actions.single.kind, BuyV2ShopChatActionKind.startVoiceCall);
    expect(find.bySemanticsLabel('Starting voice call'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(voice).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(video).onPressed, isNull);
    for (final label in const ['Start voice call', 'Start video call']) {
      final flags = tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData()
          .flagsCollection;
      expect(flags.isButton, isTrue, reason: label);
      expect(flags.isEnabled, Tristate.isFalse, reason: label);
    }
    expect(
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Notifications'),
              matching: find.byType(ListTile),
            ),
          )
          .onTap,
      isNull,
    );

    await tester.tap(voice);
    await tester.tap(video);
    await tester.tap(find.text('Notifications'));
    await tester.pump();
    expect(actions, hasLength(1));

    firstCall.complete(const BuyV2ShopChatActionResult.accepted());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-info-progress')),
      findsNothing,
    );
    expect(tester.widget<OutlinedButton>(voice).onPressed, isNotNull);
    expect(tester.widget<OutlinedButton>(video).onPressed, isNotNull);
    for (final label in const ['Start voice call', 'Start video call']) {
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData()
            .flagsCollection
            .isEnabled,
        Tristate.isTrue,
        reason: label,
      );
    }

    await tester.tap(voice);
    await tester.pumpAndSettle();
    expect(actions, hasLength(2));
    expect(actions.last.kind, BuyV2ShopChatActionKind.startVoiceCall);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'conversation pending action disables competing controls and restores them',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final firstCall = Completer<BuyV2ShopChatActionResult>();
      final actions = <BuyV2ShopChatAction>[];

      await tester.pumpWidget(
        app(
          session,
          shopChatSource: const _RichShopChatSource(),
          textScale: 1.4,
          onShopChatAction: (action) {
            actions.add(action);
            if (actions.length == 1) return firstCall.future;
            return Future.value(const BuyV2ShopChatActionResult.accepted());
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();

      final voice = find.byKey(const ValueKey('buy-shop-chat-voice-call'));
      final video = find.byKey(const ValueKey('buy-shop-chat-video-call'));
      final forward = find.byKey(
        const ValueKey('buy-shop-chat-forward-received-text'),
      );
      await tester.ensureVisible(forward);
      await tester.tap(voice);
      await tester.pump();

      expect(actions.single.kind, BuyV2ShopChatActionKind.startVoiceCall);
      final progress = find.bySemanticsLabel('Starting voice call');
      expect(progress, findsOneWidget);
      expect(
        tester
            .getSemantics(progress)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      expect(tester.widget<IconButton>(voice).onPressed, isNull);
      expect(tester.widget<IconButton>(video).onPressed, isNull);
      for (final key in const [
        'buy-shop-chat-emoji',
        'buy-shop-chat-attach',
        'buy-shop-chat-camera',
      ]) {
        final control = find.byKey(ValueKey(key));
        expect(
          tester
              .widget<IconButton>(
                find.descendant(of: control, matching: find.byType(IconButton)),
              )
              .onPressed,
          isNull,
          reason: key,
        );
      }
      expect(
        tester
            .widget<FloatingActionButton>(
              find.byKey(const ValueKey('buy-shop-chat-voice')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.descendant(of: forward, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pump();
      final notifications = find.byKey(
        const ValueKey('buy-shop-chat-menu-notifications'),
      );
      final safety = find.byKey(const ValueKey('buy-shop-chat-menu-safety'));
      expect(tester.widget<InkWell>(notifications).onTap, isNull);
      expect(tester.widget<InkWell>(safety).onTap, isNull);
      for (final label in const [
        'Notification settings',
        'Safety and support',
      ]) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData()
            .flagsCollection;
        expect(data.isButton, isTrue, reason: label);
        expect(data.isEnabled, Tristate.isFalse, reason: label);
      }

      await tester.tap(voice);
      await tester.tap(video);
      await tester.tap(forward);
      await tester.pump();
      expect(actions, hasLength(1));

      firstCall.complete(const BuyV2ShopChatActionResult.accepted());
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Starting voice call'), findsNothing);
      expect(tester.widget<IconButton>(voice).onPressed, isNotNull);
      expect(tester.widget<IconButton>(video).onPressed, isNotNull);
      for (final label in const [
        'Notification settings',
        'Safety and support',
      ]) {
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(label))
              .getSemanticsData()
              .flagsCollection
              .isEnabled,
          Tristate.isTrue,
          reason: label,
        );
      }
      expect(
        tester
            .widget<IconButton>(
              find.descendant(of: forward, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(forward);
      await tester.pumpAndSettle();
      expect(actions, hasLength(2));
      expect(actions.last.kind, BuyV2ShopChatActionKind.forwardMessage);
      expect(actions.last.messageId, 'received-text');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected-message remote actions share the conversation guard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final firstAction = Completer<BuyV2ShopChatActionResult>();
    final actions = <BuyV2ShopChatAction>[];

    await tester.pumpWidget(
      app(
        session,
        shopChatSource: const _RichShopChatSource(),
        onShopChatAction: (action) {
          actions.add(action);
          return firstAction.future;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
    );
    await tester.pumpAndSettle();

    final message = find.byKey(
      const ValueKey('buy-shop-chat-message-received-text'),
    );
    await tester.ensureVisible(message);
    await tester.longPress(message);
    await tester.pumpAndSettle();
    final like = find.byKey(const ValueKey('buy-shop-chat-menu-react'));
    final forward = find.byKey(const ValueKey('buy-shop-chat-menu-forward'));
    await tester.tap(like);
    await tester.pump();

    expect(actions.single.kind, BuyV2ShopChatActionKind.reactToMessage);
    expect(actions.single.messageId, 'received-text');
    expect(find.bySemanticsLabel('Liking message'), findsOneWidget);
    expect(tester.widget<IconButton>(like).onPressed, isNull);
    expect(tester.widget<IconButton>(forward).onPressed, isNull);

    await tester.tap(like);
    await tester.tap(forward);
    await tester.pump();
    expect(actions, hasLength(1));

    firstAction.complete(const BuyV2ShopChatActionResult.accepted());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-message-actions')),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Liking message'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'text-only capability hides unsupported controls before the first tap',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final actions = <BuyV2ShopChatAction>[];

      await tester.pumpWidget(
        app(
          session,
          shopChatSource: const _TextOnlyShopChatSource(),
          textScale: 1.4,
          onShopChatAction: (action) async {
            actions.add(action);
            return const BuyV2ShopChatActionResult.accepted();
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-text-only')),
      );
      await tester.pumpAndSettle();

      for (final key in const [
        'buy-shop-chat-voice-call',
        'buy-shop-chat-video-call',
        'buy-shop-chat-camera',
        'buy-shop-chat-attach',
        'buy-shop-chat-voice',
      ]) {
        expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
      }
      expect(
        find.byKey(const ValueKey('buy-shop-chat-send-disabled')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Type a message to send'), findsOneWidget);
      expect(
        const BuyV2ShopChatCapabilities(
          camera: false,
          media: false,
          documents: false,
          productSharing: false,
          orderSharing: false,
          locationSharing: false,
          contactSharing: false,
        ).canAttach,
        isFalse,
      );

      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-composer-field')),
        'Text still works',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('buy-shop-chat-send')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-send')));
      await tester.pumpAndSettle();
      expect(actions.single.kind, BuyV2ShopChatActionKind.sendText);
      expect(actions.single.text, 'Text still works');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'thread info and system Back unwind one Shop Chat surface at a time',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        app(session, shopChatSource: const _RichShopChatSource()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-info')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat-info')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-shop-chat-info')), findsNothing);
      expect(find.text('Forward to Mahadev Fresh Mart info'), findsOneWidget);
      final forwardSize = tester.getSize(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      expect(forwardSize.height, greaterThanOrEqualTo(44));
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat-info')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-shop-chat-thread')), findsNothing);
      expect(find.text('Forward to Mahadev Fresh Mart'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );
      expect(find.text('Forward to Mahadev Fresh Mart info'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'message taps expose reply media and conversation search journeys',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      final actions = <BuyV2ShopChatAction>[];
      await tester.pumpWidget(
        app(
          session,
          shopChatSource: const _RichShopChatSource(),
          onShopChatAction: (action) async {
            actions.add(action);
            return const BuyV2ShopChatActionResult.accepted();
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();

      final directForward = find.byKey(
        const ValueKey('buy-shop-chat-forward-received-text'),
      );
      expect(directForward, findsOneWidget);
      for (final messageId in const [
        'received-text',
        'sent-text',
        'received-photo',
        'sent-document',
        'received-voice',
      ]) {
        expect(
          find.byKey(ValueKey('buy-shop-chat-forward-$messageId')),
          findsOneWidget,
          reason: messageId,
        );
      }
      await tester.ensureVisible(directForward);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          'Forward message from Mahadev Fresh Mart at 10:36',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
        findsNothing,
      );
      await tester.tap(directForward);
      await tester.pumpAndSettle();
      expect(actions.last.kind, BuyV2ShopChatActionKind.forwardMessage);
      expect(actions.last.messageId, 'received-text');

      final firstMessage = find.byKey(
        const ValueKey('buy-shop-chat-message-received-text'),
      );
      await tester.ensureVisible(firstMessage);
      await tester.longPress(firstMessage);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-actions')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-reply')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('buy-shop-chat-message-received-photo')),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-message-received-photo')),
      );
      await tester.pumpAndSettle();
      expect(actions.last.kind, BuyV2ShopChatActionKind.openAttachment);
      expect(actions.last.messageId, 'received-photo');

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-search')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-search')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-search')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread-menu')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread-menu')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-emoji-tray')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-emoji-tray')),
        findsNothing,
      );

      await tester.scrollUntilVisible(
        firstMessage,
        -120,
        scrollable: find.descendant(
          of: find.byKey(
            const PageStorageKey<String>(
              'buy-shop-chat-message-list-retail-live-all',
            ),
          ),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.longPress(firstMessage);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-actions')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-actions')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Android Back and Forward restore nested thread history one step at a time',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        app(session, shopChatSource: const _RichShopChatSource()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();

      final message = find.byKey(
        const ValueKey('buy-shop-chat-message-received-text'),
      );
      await tester.ensureVisible(message);
      await tester.longPress(message);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-reply')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-message-search-field')),
        'basket',
      );
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-search')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsOneWidget,
      );
      expect(find.text('Forward to message search'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsNothing,
      );
      expect(find.text('Forward to message reply'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsOneWidget,
      );
      expect(find.text('Forward to message search'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-search')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-message-search-field')),
            )
            .controller!
            .text,
        'basket',
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-message-search-close')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel reply'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread-menu')),
        findsNothing,
      );
      expect(find.text('Forward to conversation options'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread-menu')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsNothing,
      );
      expect(find.text('Forward to sharing options'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-emoji-tray')),
        findsNothing,
      );
      expect(find.text('Forward to emoji choices'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-emoji-tray')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(message);
      await tester.longPress(message);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-actions')),
        findsNothing,
      );
      expect(find.text('Forward to message actions'), findsOneWidget);
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('buy-shop-chat-history-forward')),
            )
            .height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-actions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'visible dismiss controls preserve the same Forward thread history',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        app(session, shopChatSource: const _RichShopChatSource()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();
      expect(find.text('Forward to conversation options'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread-menu')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-message-search-field')),
        'basket',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-message-search-close')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Forward to message search'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-message-search-field')),
            )
            .controller!
            .text,
        'basket',
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-message-search-close')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      expect(find.text('Forward to sharing options'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attachment-tray')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();
      expect(find.text('Forward to emoji choices'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-emoji-tray')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();

      final message = find.byKey(
        const ValueKey('buy-shop-chat-message-received-text'),
      );
      await tester.ensureVisible(message);
      await tester.longPress(message);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-selection-close')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Forward to message actions'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-message-actions')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-reply')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel reply'));
      await tester.pumpAndSettle();
      expect(find.text('Forward to message reply'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('message timeline retains scroll through Chat Info return', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(
      app(session, shopChatSource: const _RichShopChatSource(), textScale: 1.4),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
    );
    await tester.pumpAndSettle();

    final timelineKey = const PageStorageKey<String>(
      'buy-shop-chat-message-list-retail-live-all',
    );
    final timeline = find.byKey(timelineKey);
    final lastMessage = find.byKey(
      const ValueKey('buy-shop-chat-message-received-voice'),
    );
    await tester.scrollUntilVisible(
      lastMessage,
      120,
      scrollable: find.descendant(
        of: timeline,
        matching: find.byType(Scrollable),
      ),
    );
    final beforeInfo = tester
        .state<ScrollableState>(
          find.descendant(of: timeline, matching: find.byType(Scrollable)),
        )
        .position
        .pixels;
    expect(beforeInfo, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-info')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat-info')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-info-back')));
    await tester.pumpAndSettle();

    final restoredTimeline = find.byKey(timelineKey);
    final afterReturn = tester
        .state<ScrollableState>(
          find.descendant(
            of: restoredTimeline,
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(afterReturn, closeTo(beforeInfo, 0.1));
    expect(lastMessage, findsOneWidget);
    expect(find.text('Forward to Mahadev Fresh Mart info'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android Back dismisses inbox search before leaving Chat', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey('buy-shop-chat-search'));
    await tester.tap(search);
    await tester.enterText(search, 'order');
    await tester.pump();
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
    expect(tester.widget<TextField>(search).controller!.text, 'order');
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
    expect(
      find.byKey(const ValueKey('buy-shop-chat-history-forward')),
      findsNothing,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Android Back dismisses the composer keyboard before the thread',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        app(
          session,
          shopChatSource: const _RichShopChatSource(),
          textScale: 1.4,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('buy-shop-chat-composer-field'));
      await tester.enterText(
        field,
        'Keep this draft while hiding the keyboard',
      );
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-thread')),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(field).controller!.text,
        contains('draft'),
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-history-forward')),
        findsNothing,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-shop-chat-thread')), findsNothing);
      expect(find.text('Forward to Mahadev Fresh Mart'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'commerce context returns directly to the connected Orders surface',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-order-MS-240782')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-commerce-context')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      expect(session.destination, BuyV2Destination.orders);
      expect(find.byKey(const PageStorageKey('buy-orders')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'draft reply search and inbox context survive Info and Chat reopen',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        app(session, shopChatSource: const _RichShopChatSource()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-filter-sellers')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-search')),
        'Mahadev',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-composer-field')),
        'Please keep my basket draft',
      );
      await tester.pump();
      await tester.longPress(
        find.byKey(const ValueKey('buy-shop-chat-message-received-text')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-reply')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-message-search-field')),
        'basket',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-info')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat-info')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-composer-field')),
            )
            .controller!
            .text,
        'Please keep my basket draft',
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-message-search-field')),
            )
            .controller!
            .text,
        'basket',
      );

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-message-search-close')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-chat-reply-preview')),
          matching: find.byTooltip('Cancel reply'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('buy-shop-chat-filter-sellers')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-search')),
            )
            .controller!
            .text,
        'Mahadev',
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-retail-live')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-composer-field')),
            )
            .controller!
            .text,
        'Please keep my basket draft',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Shop Chat public labels and default copy remain truthful', (
    tester,
  ) async {
    expect(BuyV2ShopChatFilter.values.map((value) => value.name), [
      'all',
      'orders',
      'sellers',
      'offers',
    ]);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final threads = const BuyV2SessionShopChatProvisioningSource().threads(
      session,
    );
    final customerCopy = <String>[
      BuyV2ShopChatPresentation.shop.securityMessage,
      ...threads.map((thread) => thread.detail),
    ];
    expect(
      customerCopy.where(
        RegExp(r'\bsecure(?:ly)?\b|\bencrypt', caseSensitive: false).hasMatch,
      ),
      isEmpty,
    );
  });
}

class _LiveShopChatSource extends ChangeNotifier
    implements BuyV2ShopChatProvisioningSource {
  _LiveShopChatSource() : _threads = [_thread()];

  List<BuyV2ShopChatThread> _threads;

  @override
  List<BuyV2ShopChatThread> threads(BuyV2Session? _) =>
      List<BuyV2ShopChatThread>.unmodifiable(_threads);

  void publishIncomingMessage({
    String body = 'Your live order update is ready.',
  }) {
    _threads = [
      _thread(
        messages: [
          BuyV2ShopChatMessage(
            id: 'live-message',
            kind: BuyV2ShopChatMessageKind.text,
            fromCurrentUser: false,
            sentAtLabel: 'Now',
            body: body,
          ),
        ],
      ),
    ];
    notifyListeners();
  }

  void removeConversation() {
    _threads = [];
    notifyListeners();
  }

  static BuyV2ShopChatThread _thread({
    List<BuyV2ShopChatMessage> messages = const [],
  }) => BuyV2ShopChatThread(
    id: 'live-support',
    filter: BuyV2ShopChatFilter.orders,
    participantKind: BuyV2ShopChatParticipantKind.orderSupport,
    title: 'Live order support',
    subtitle: 'Current order updates',
    detail: 'Open live order support',
    icon: Icons.local_shipping_outlined,
    accent: BuyV2Colors.navy,
    commerceTarget: BuyV2ShopChatCommerceTarget.orders,
    contextTitle: 'Live order',
    contextDetail: 'Current order and delivery context',
    messages: messages,
  );
}

class _LoadingShopChatSource extends ChangeNotifier
    implements BuyV2ShopChatProvisioningSource, BuyV2ShopChatLoadSource {
  List<BuyV2ShopChatThread> _threads = [];
  @override
  BuyV2ShopChatLoadState loadState = BuyV2ShopChatLoadState.loading;
  @override
  String? loadErrorMessage;
  int retryCalls = 0;

  @override
  List<BuyV2ShopChatThread> threads(BuyV2Session? _) =>
      List<BuyV2ShopChatThread>.unmodifiable(_threads);

  void failLoading() {
    loadState = BuyV2ShopChatLoadState.failed;
    loadErrorMessage = 'Chat service is unavailable right now. Try again.';
    notifyListeners();
  }

  @override
  Future<void> retryLoading() async {
    retryCalls += 1;
    loadState = BuyV2ShopChatLoadState.loading;
    loadErrorMessage = null;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    _threads = [_LiveShopChatSource._thread()];
    loadState = BuyV2ShopChatLoadState.ready;
    notifyListeners();
  }
}

class _RichShopChatSource implements BuyV2ShopChatProvisioningSource {
  const _RichShopChatSource();

  @override
  List<BuyV2ShopChatThread> threads(BuyV2Session? session) => const [
    BuyV2ShopChatThread(
      id: 'retail-live',
      filter: BuyV2ShopChatFilter.sellers,
      participantKind: BuyV2ShopChatParticipantKind.retailer,
      title: 'Mahadev Fresh Mart',
      subtitle: 'Retail partner · Groceries and delivery',
      detail: 'Basket update',
      icon: Icons.storefront_outlined,
      accent: BuyV2Colors.orange,
      commerceTarget: BuyV2ShopChatCommerceTarget.shop,
      contextTitle: 'Fresh grocery basket',
      contextDetail: '5 items · Delivery to your saved address',
      previewTimeLabel: '10:42',
      unreadCount: 1,
      quickReplies: ['Is everything in stock?', 'When can it arrive?'],
      messages: [
        BuyV2ShopChatMessage(
          id: 'received-text',
          kind: BuyV2ShopChatMessageKind.text,
          fromCurrentUser: false,
          sentAtLabel: '10:36',
          body: 'Your fresh grocery basket is ready to review.',
          deliveryState: BuyV2ShopChatDeliveryState.delivered,
        ),
        BuyV2ShopChatMessage(
          id: 'sent-text',
          kind: BuyV2ShopChatMessageKind.text,
          fromCurrentUser: true,
          sentAtLabel: '10:38',
          body: 'Can it arrive tomorrow morning?',
          deliveryState: BuyV2ShopChatDeliveryState.read,
        ),
        BuyV2ShopChatMessage(
          id: 'received-photo',
          kind: BuyV2ShopChatMessageKind.image,
          fromCurrentUser: false,
          sentAtLabel: '10:40',
          attachmentName: 'Basket photo',
          attachmentDetail: 'JPG · 1.8 MB',
          body: 'These are the available packs.',
        ),
        BuyV2ShopChatMessage(
          id: 'sent-document',
          kind: BuyV2ShopChatMessageKind.document,
          fromCurrentUser: true,
          sentAtLabel: '10:41',
          attachmentName: 'Monthly staples.pdf',
          attachmentDetail: 'PDF · 240 KB',
          deliveryState: BuyV2ShopChatDeliveryState.delivered,
        ),
        BuyV2ShopChatMessage(
          id: 'received-voice',
          kind: BuyV2ShopChatMessageKind.voice,
          fromCurrentUser: false,
          sentAtLabel: '10:42',
          attachmentName: 'Voice message',
          attachmentDetail: '0:18',
        ),
      ],
    ),
  ];
}

class _EmptyShopChatSource implements BuyV2ShopChatProvisioningSource {
  const _EmptyShopChatSource();

  @override
  List<BuyV2ShopChatThread> threads(BuyV2Session? session) => const [];
}

class _TextOnlyShopChatSource implements BuyV2ShopChatProvisioningSource {
  const _TextOnlyShopChatSource();

  @override
  List<BuyV2ShopChatThread> threads(BuyV2Session? session) => const [
    BuyV2ShopChatThread(
      id: 'text-only',
      filter: BuyV2ShopChatFilter.sellers,
      participantKind: BuyV2ShopChatParticipantKind.retailer,
      title: 'Text support',
      subtitle: 'Text messages only',
      detail: 'Open text support',
      icon: Icons.chat_bubble_outline_rounded,
      accent: BuyV2Colors.navy,
      contextTitle: 'Text support',
      contextDetail: 'Text-only conversation context',
      capabilities: BuyV2ShopChatCapabilities(
        voiceCall: false,
        videoCall: false,
        camera: false,
        media: false,
        documents: false,
        voiceMessages: false,
        productSharing: false,
        orderSharing: false,
        locationSharing: false,
        contactSharing: false,
      ),
    ),
  ];
}
