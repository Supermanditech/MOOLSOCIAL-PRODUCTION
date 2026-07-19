import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) => widget is Scrollable,
      );
      for (final state
          in scrollables
              .evaluate()
              .whereType<StatefulElement>()
              .map((element) => element.state)
              .whereType<ScrollableState>()) {
        if (state.position.maxScrollExtent <= state.position.minScrollExtent) {
          continue;
        }
        state.position.jumpTo(state.position.minScrollExtent);
        await tester.pump();
        for (
          var attempt = 0;
          attempt < 40 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 240).clamp(
              state.position.minScrollExtent,
              state.position.maxScrollExtent,
            ),
          );
          await tester.pump();
        }
        if (finder.evaluate().isNotEmpty) break;
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return finder;
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  Future<void> openRoute(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical Chat opens every Universal intent, provides direct Mool access and retries one failed message',
    (tester) async {
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Jodhpur',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(
          failNextRequest: true,
          latency: Duration.zero,
        ),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: '/app/chat?sub=business-chat&return=/app/social',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(chat.selectedFilter, ChatThreadType.business);
      expect(find.byKey(const Key('chat-open-thread-mahadev')), findsOneWidget);
      expect(
        find.byKey(const Key('chat-open-thread-home-basket')),
        findsNothing,
      );
      await binding.takeScreenshot('chat-023-business-filter');

      await tapVisible(tester, const Key('chat-open-thread-mahadev'));
      await tapVisible(tester, const Key('chat-thread-mool'));
      expect(find.byKey(const Key('mool-command-palette')), findsOneWidget);
      await binding.takeScreenshot('chat-024-direct-mool');

      for (final branch in const [
        ('people', ChatThreadType.people, 'home-basket'),
        ('orders', ChatThreadType.order, 'rasoi'),
        ('support', ChatThreadType.support, 'order-support'),
      ]) {
        await openRoute(
          tester,
          '/app/chat?sub=${branch.$1}&return=/app/social',
        );
        expect(chat.selectedFilter, branch.$2);
        expect(
          find.byKey(Key('chat-open-thread-${branch.$3}')),
          findsOneWidget,
        );
      }

      await openRoute(
        tester,
        '/app/chat/thread/home-basket?return=/app/social',
      );
      await tapVisible(tester, const Key('chat-mode-media'));
      await tapVisible(tester, const Key('chat-context-primary-media'));
      await tapVisible(tester, const Key('chat-media-open-staples-file'));
      expect(find.text('Monthly Staples.pdf opened.'), findsOneWidget);

      await tapVisible(tester, const Key('chat-mode-poll'));
      await tapVisible(tester, const Key('chat-context-primary-poll'));
      await tapVisible(tester, const Key('chat-poll-option-add'));
      expect(chat.errorMessage, 'Enter a clear poll option.');
      await tester.enterText(
        await reveal(tester, const Key('chat-poll-option-field')),
        'Later this week',
      );
      await tapVisible(tester, const Key('chat-poll-option-add'));
      expect(chat.pollOptions, contains('Later this week'));

      await tapVisible(tester, const Key('chat-mode-invite'));
      await tapVisible(tester, const Key('chat-context-primary-invite'));
      await tapVisible(tester, const Key('chat-invite-prepare'));
      expect(chat.errorMessage, 'Enter a name or mobile number.');
      await tester.enterText(
        await reveal(tester, const Key('chat-invite-field')),
        'Riya Sharma',
      );
      await tapVisible(tester, const Key('chat-invite-prepare'));
      expect(chat.invitedMembers, ['Riya Sharma']);

      await tapVisible(tester, const Key('chat-mode-chat'));
      await tester.enterText(
        await reveal(tester, const Key('chat-message-field')),
        'Please add milk to the basket.',
      );
      await tapVisible(tester, const Key('chat-send'));
      expect(
        chat.messages('home-basket').last.deliveryState,
        ChatDeliveryState.failed,
      );
      expect(
        find.text('Message was not sent. Check your connection and retry.'),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('chat-retry-m11'));
      final replays = chat
          .messages('home-basket')
          .where((message) => message.text == 'Please add milk to the basket.')
          .toList();
      expect(replays, hasLength(1));
      expect(replays.single.deliveryState, ChatDeliveryState.delivered);

      await openRoute(
        tester,
        '/app/chat/thread/order-support?return=/app/social',
      );
      await tapVisible(tester, const Key('chat-mode-details'));
      await tapVisible(tester, const Key('chat-context-primary-details'));
      expect(
        find.byKey(const Key('chat-linked-details-sheet')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('chat-linked-details-done'));
      await tapVisible(tester, const Key('chat-mode-updates'));
      await tapVisible(tester, const Key('chat-context-primary-updates'));
      expect(
        find.text('Conversation updates refreshed just now.'),
        findsOneWidget,
      );
      await binding.takeScreenshot('chat-025-failed-message-retried');
    },
  );
}
