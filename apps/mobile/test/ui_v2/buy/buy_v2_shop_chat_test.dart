import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        onOpenChat: onOpenChat,
        onShopChatAction: onShopChatAction,
        shopChatSource: shopChatSource,
        onExit: onExit,
      ),
    );
  }

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
    expect(find.text('No Shop chats found'), findsOneWidget);
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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
      core.dispose();
    }
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

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-shop-chat-thread')), findsNothing);

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

      await tester.longPress(
        find.byKey(const ValueKey('buy-shop-chat-message-received-text')),
      );
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
