import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
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
    required ChatSession chat,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        key: ValueKey(route),
        session: journey,
        chatSession: chat,
        initialLocation: route,
      ),
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
      for (final element in scrollables.evaluate()) {
        final scrollable = find.byElementPredicate(
          (candidate) => identical(candidate, element),
        );
        final axis = tester.widget<Scrollable>(scrollable).axisDirection;
        if (axis == AxisDirection.left || axis == AxisDirection.right) {
          await tester.drag(scrollable, const Offset(2000, 0));
          await tester.pumpAndSettle();
          for (
            var attempt = 0;
            attempt < 6 && finder.evaluate().isEmpty;
            attempt += 1
          ) {
            await tester.drag(scrollable, const Offset(-220, 0));
            await tester.pumpAndSettle();
          }
        }
      }
      if (finder.evaluate().isEmpty) {
        for (final element in scrollables.evaluate()) {
          final scrollable = find.byElementPredicate(
            (candidate) => identical(candidate, element),
          );
          final axis = tester.widget<Scrollable>(scrollable).axisDirection;
          if (axis == AxisDirection.up || axis == AxisDirection.down) {
            for (
              var attempt = 0;
              attempt < 8 && finder.evaluate().isEmpty;
              attempt += 1
            ) {
              await tester.drag(scrollable, const Offset(0, -220));
              await tester.pumpAndSettle();
            }
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
    'inbox completes search, filters, consent-safe new chat and protected return route',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mount(
        tester,
        route: '/app/chat/inbox?return=/app/buy/grocery',
        journey: journey,
        chat: chat,
      );

      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('chat-search-field')),
        'not a conversation',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching conversations'), findsOneWidget);
      await tapVisible(tester, const Key('chat-reset-search'));

      await tapVisible(tester, const Key('chat-filter-unread'));
      expect(
        find.byKey(const Key('chat-open-thread-home-basket')),
        findsNothing,
      );
      expect(find.byKey(const Key('chat-open-thread-mahadev')), findsOneWidget);

      await tapVisible(tester, const Key('chat-new'));
      expect(find.byKey(const Key('chat-new-open-feed')), findsOneWidget);
      expect(
        find.textContaining('Open a public MoolSocial post'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-new-business')), findsNothing);
      await tapVisible(tester, const Key('chat-new-cancel'));
      await tapVisible(tester, const Key('chat-filter-all'));

      await tapVisible(tester, const Key('chat-voice-search'));
      await tapVisible(tester, const Key('chat-use-voice-search'));
      expect(find.text('Enter a conversation name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('chat-voice-search-field')),
        'Home Basket',
      );
      await tapVisible(tester, const Key('chat-use-voice-search'));
      expect(
        find.byKey(const Key('chat-open-thread-home-basket')),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('chat-open-thread-home-basket'));
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      await tapVisible(tester, const Key('chat-back'));
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(find.byKey(const Key('chat-back')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Chat keeps a high-contrast new-chat action on a standalone page',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mount(
        tester,
        route: '/app/chat/inbox?return=/app/social',
        journey: journey,
        chat: chat,
        size: const Size(360, 800),
      );

      final newChat = tester.widget<IconButton>(
        find.byKey(const Key('chat-new')),
      );
      final background = newChat.style?.backgroundColor?.resolve(
        const <WidgetState>{},
      );
      final foreground = newChat.style?.foregroundColor?.resolve(
        const <WidgetState>{},
      );
      expect(background, isNotNull);
      expect(foreground, Colors.white);
      expect(background, isNot(foreground));

      expect(
        find.byKey(const Key('chat-global-edge-navigation')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('chat-compact-global-edge-rail')),
        findsNothing,
      );
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
      expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);
      final back = find.byKey(const Key('chat-inbox-back'));
      expect(back, findsOneWidget);
      expect(tester.getSize(back).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(back).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Universal Chat choices open the matching production inbox', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    for (final branch in const [
      ('people', ChatThreadType.people, 'home-basket'),
      ('business-chat', ChatThreadType.business, 'mahadev'),
      ('orders', ChatThreadType.order, 'rasoi'),
      ('support', ChatThreadType.support, 'order-support'),
    ]) {
      await mount(
        tester,
        route: '/app/chat?sub=${branch.$1}&return=/app/social',
        journey: journey,
        chat: chat,
      );
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(chat.selectedFilter, branch.$2);
      expect(find.byKey(Key('chat-open-thread-${branch.$3}')), findsOneWidget);
    }
  });

  testWidgets(
    'people chat supports reply and reaction while excluded actions stay absent',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mount(
        tester,
        route: '/app/chat/thread/home-basket?return=/app/social&stage=basket',
        journey: journey,
        chat: chat,
      );

      expect(
        find.byKey(const Key('chat-attachment-reference-m2')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-open-attachment-m2')), findsNothing);
      expect(find.text('Attachment reference'), findsOneWidget);

      for (final key in const [
        Key('chat-like-m1'),
        Key('chat-attach'),
        Key('chat-camera'),
        Key('chat-thread-call'),
        Key('chat-thread-video'),
        Key('chat-thread-more'),
        Key('chat-mode-media'),
        Key('chat-mode-poll'),
        Key('chat-mode-invite'),
        Key('chat-mode-basket'),
      ]) {
        expect(find.byKey(key), findsNothing, reason: '$key');
      }

      await tapVisible(tester, const Key('chat-react-m1'));
      expect(chat.messages('home-basket').first.reactionCount, 3);
      expect(chat.messages('home-basket').first.reactedByMe, isTrue);
      await tapVisible(tester, const Key('chat-react-m1'));
      expect(chat.messages('home-basket').first.reactionCount, 2);
      expect(chat.messages('home-basket').first.reactedByMe, isFalse);

      await tapVisible(tester, const Key('chat-reply-m1'));
      expect(
        find.byKey(const Key('chat-composer-reply-context')),
        findsOneWidget,
      );
      expect(find.text('Replying to Amit'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('chat-message-field')),
        'Please add rice to the household list.',
      );
      await tapVisible(tester, const Key('chat-send'));
      expect(find.text('Message delivered.'), findsOneWidget);
      expect(
        chat.messages('home-basket').last.text,
        'Please add rice to the household list.',
      );
      expect(
        chat.messages('home-basket').last.deliveryState,
        ChatDeliveryState.delivered,
      );
      expect(chat.messages('home-basket').last.replyTo?.messageId, 'm1');
      expect(
        find.byKey(const Key('chat-composer-reply-context')),
        findsNothing,
      );

      await tapVisible(tester, const Key('chat-send'));
      expect(find.text('Write a message.'), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
      expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed message exact replay delivers once after retry', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(
        failNextRequest: true,
        latency: Duration.zero,
      ),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/thread/order-support?return=/app/buy/grocery',
      journey: journey,
      chat: chat,
    );

    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'The tomato was missing.',
    );
    await tapVisible(tester, const Key('chat-send'));
    expect(
      find.text('Message was not sent. Check your connection and retry.'),
      findsOneWidget,
    );
    expect(
      chat.messages('order-support').last.deliveryState,
      ChatDeliveryState.failed,
    );

    await tapVisible(tester, const Key('chat-retry-m11'));
    final replayed = chat
        .messages('order-support')
        .where((message) => message.text == 'The tomato was missing.')
        .toList();
    expect(replayed, hasLength(1), reason: 'Retry must not duplicate messages');
    expect(replayed.single.deliveryState, ChatDeliveryState.delivered);
    expect(find.text('Message delivered.'), findsOneWidget);

    expect(find.byKey(const Key('chat-mode-details')), findsNothing);
    expect(find.byKey(const Key('chat-mode-updates')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('business and support conversations keep truthful identities', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/thread/mahadev?return=/app/buy/grocery',
      journey: journey,
      chat: chat,
    );

    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.text('Mahadev Fresh Mart'), findsWidgets);
    expect(find.byKey(const Key('chat-mode-orders')), findsNothing);
    expect(find.byKey(const Key('chat-mode-quote')), findsNothing);
    expect(find.byKey(const Key('chat-mode-pay')), findsNothing);

    await tapVisible(tester, const Key('chat-back'));
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

    await mount(
      tester,
      route: '/app/chat/thread/order-support?return=/app/social',
      journey: journey,
      chat: chat,
    );
    expect(find.text('Order Support'), findsWidgets);
    expect(find.text('Case MS-CASE-204'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact phone keeps chat controls tappable without overflow', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/thread/home-basket?return=/app/social',
      journey: journey,
      chat: chat,
      size: const Size(360, 800),
    );

    for (final key in const [Key('chat-back'), Key('chat-send')]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
    expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
