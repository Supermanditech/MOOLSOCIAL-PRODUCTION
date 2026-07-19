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
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
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
      await binding.takeScreenshot('chat-025-failed-message-retried');
    },
  );
}
