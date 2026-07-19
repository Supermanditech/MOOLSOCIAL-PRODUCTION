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
    'inbox completes search, filters, new chat and protected return route',
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
      await tapVisible(tester, const Key('chat-new-business'));
      expect(find.byKey(const Key('chat-open-thread-mahadev')), findsOneWidget);
      expect(find.byKey(const Key('chat-open-thread-rasoi')), findsNothing);
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
      await tapVisible(tester, const Key('chat-back'));
      expect(find.byKey(const Key('buy-catalog-screen')), findsOneWidget);
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
    'people chat completes reactions, reply, attachment and nested actions',
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

      await tapVisible(tester, const Key('chat-like-m1'));
      expect(find.text('Like 1'), findsOneWidget);
      await tapVisible(tester, const Key('chat-reply-m1'));
      expect(find.byKey(const Key('chat-reply-preview')), findsOneWidget);
      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-reply-preview')), findsNothing);

      await tapVisible(tester, const Key('chat-attach'));
      await tapVisible(tester, const Key('chat-attachment-file'));
      expect(find.byKey(const Key('chat-attachment-preview')), findsOneWidget);
      await tapVisible(tester, const Key('chat-send'));
      expect(find.text('Message delivered.'), findsOneWidget);
      expect(chat.messages('home-basket').last.attachmentLabel, 'File');

      await tapVisible(tester, const Key('chat-send'));
      expect(
        find.text('Write a message or add an attachment.'),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('chat-thread-call'));
      await tapVisible(tester, const Key('chat-confirm-call'));
      expect(
        find.textContaining('Call started with Home Basket'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('chat-thread-video'));
      await tapVisible(tester, const Key('chat-confirm-video'));
      expect(
        find.textContaining('Video call started with Home Basket'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('chat-thread-more'));
      await tapVisible(tester, const Key('chat-more-mute'));
      expect(
        find.textContaining('Mute notifications selected'),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('chat-mode-media'));
      await tapVisible(tester, const Key('chat-context-primary-media'));
      expect(find.byKey(const Key('chat-media-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('chat-media-open-staples-file'));
      expect(find.text('Monthly Staples.pdf opened.'), findsOneWidget);

      await tapVisible(tester, const Key('chat-mode-poll'));
      await tapVisible(tester, const Key('chat-context-primary-poll'));
      await tapVisible(tester, const Key('chat-poll-option-add'));
      expect(chat.errorMessage, 'Enter a clear poll option.');
      await tester.enterText(
        find.byKey(const Key('chat-poll-option-field')),
        'Later this week',
      );
      await tapVisible(tester, const Key('chat-poll-option-add'));
      expect(chat.pollOptions, contains('Later this week'));
      await tapVisible(tester, const Key('chat-poll-later-this-week'));
      expect(find.textContaining('Vote recorded for Later'), findsOneWidget);

      await tapVisible(tester, const Key('chat-context-primary-poll'));
      await tester.enterText(
        find.byKey(const Key('chat-poll-option-field')),
        'Later this week',
      );
      await tapVisible(tester, const Key('chat-poll-option-add'));
      expect(chat.errorMessage, 'This poll option is already included.');
      await tapVisible(tester, const Key('chat-poll-option-cancel'));

      await tapVisible(tester, const Key('chat-mode-invite'));
      await tapVisible(tester, const Key('chat-context-primary-invite'));
      await tapVisible(tester, const Key('chat-invite-prepare'));
      expect(chat.errorMessage, 'Enter a name or mobile number.');
      await tester.enterText(
        find.byKey(const Key('chat-invite-field')),
        'Riya Sharma',
      );
      await tapVisible(tester, const Key('chat-invite-prepare'));
      expect(chat.invitedMembers, ['Riya Sharma']);
      expect(find.byKey(const Key('chat-invited-members')), findsOneWidget);

      await tapVisible(tester, const Key('chat-context-primary-invite'));
      await tester.enterText(
        find.byKey(const Key('chat-invite-field')),
        'Riya Sharma',
      );
      await tapVisible(tester, const Key('chat-invite-prepare'));
      expect(chat.errorMessage, 'This person is already invited.');
      await tapVisible(tester, const Key('chat-invite-cancel'));

      await tapVisible(tester, const Key('chat-mode-poll'));
      await tapVisible(tester, const Key('chat-poll-today-evening'));
      expect(find.textContaining('Vote recorded for Today'), findsOneWidget);
      await tapVisible(tester, const Key('chat-thread-mool'));
      expect(find.byKey(const Key('mool-command-palette')), findsOneWidget);

      await mount(
        tester,
        route: '/app/chat/thread/home-basket?return=/app/social',
        journey: journey,
        chat: chat,
      );
      await tapVisible(tester, const Key('chat-mode-basket'));
      await tapVisible(tester, const Key('chat-context-primary-basket'));
      expect(find.byKey(const Key('buy-catalog-screen')), findsOneWidget);
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

    await tapVisible(tester, const Key('chat-mode-details'));
    await tapVisible(tester, const Key('chat-context-primary-details'));
    expect(find.byKey(const Key('chat-linked-details-sheet')), findsOneWidget);
    await tapVisible(tester, const Key('chat-linked-details-done'));
    await tapVisible(tester, const Key('chat-mode-updates'));
    await tapVisible(tester, const Key('chat-context-primary-updates'));
    expect(
      find.text('Conversation updates refreshed just now.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('business and order context actions reach their next intent', (
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

    await tapVisible(tester, const Key('chat-mode-orders'));
    await tapVisible(tester, const Key('chat-context-primary-orders'));
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.text('Order Support'), findsOneWidget);

    await tapVisible(tester, const Key('chat-back'));
    expect(find.text('Mahadev Fresh Mart'), findsOneWidget);
    await tapVisible(tester, const Key('chat-mode-quote'));
    expect(find.text('Mahadev Fresh Mart quote'), findsOneWidget);
    await tapVisible(tester, const Key('chat-quote-buy'));
    expect(find.byKey(const Key('buy-catalog-screen')), findsOneWidget);

    await mount(
      tester,
      route: '/app/chat/thread/mahadev?return=/app/social',
      journey: journey,
      chat: chat,
    );
    await tapVisible(tester, const Key('chat-mode-pay'));
    await tapVisible(tester, const Key('chat-context-primary-pay'));
    expect(find.byKey(const Key('pay-home-screen')), findsOneWidget);
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

    for (final key in const [
      Key('chat-back'),
      Key('chat-thread-call'),
      Key('chat-thread-video'),
      Key('chat-thread-more'),
      Key('chat-thread-mool'),
      Key('chat-attach'),
      Key('chat-camera'),
      Key('chat-send'),
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    expect(tester.takeException(), isNull);
  });
}
