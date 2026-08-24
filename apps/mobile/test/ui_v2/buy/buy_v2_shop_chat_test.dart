import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_shop_chat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    VoidCallback? onOpenChat,
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
        onExit: onExit,
      ),
    );
  }

  testWidgets(
    'Shop Chat opens locally and delegates every continuation to production Chat',
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
      expect(find.text('Shop · sellers, orders and offers'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-shop-chat-search')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-search-band')), findsNothing);
      expect(productionChatCalls, 0);

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-order-MS-240782')),
      );
      await tester.pump();
      expect(productionChatCalls, 1);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-open-all')));
      await tester.pump();
      expect(productionChatCalls, 2);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
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
        find.text('Wholesale · sellers, orders and offers'),
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
      find.byKey(const ValueKey('buy-shop-chat-entry-shop-seller')),
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
      find.byKey(const ValueKey('buy-shop-chat-entry-shop-seller')),
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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
      core.dispose();
    }
  });

  testWidgets('Shop Chat public filter labels remain stable', (tester) async {
    expect(BuyV2ShopChatFilter.values.map((value) => value.name), [
      'all',
      'orders',
      'sellers',
      'offers',
    ]);
  });
}
