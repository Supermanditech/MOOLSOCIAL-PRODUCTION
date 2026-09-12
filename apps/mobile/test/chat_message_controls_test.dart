import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
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

  Future<void> mountThread(
    WidgetTester tester, {
    required JourneySession journey,
    required ChatSession chat,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/chat/thread/home-basket?return=/app/work/earn',
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMessageActions(WidgetTester tester, String messageId) async {
    await tester.longPress(find.byKey(Key('chat-message-$messageId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-actions')), findsOneWidget);
  }

  Future<void> dismissFeedback(WidgetTester tester) async {
    final messenger = tester.state<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger).first,
    );
    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.remove);
    await tester.pumpAndSettle();
  }

  test(
    'session removal survives reload and clears at authentication reset',
    () async {
      final chat = ChatSession();
      addTearDown(chat.dispose);
      expect(chat.messages('home-basket').map((message) => message.id), [
        'm1',
        'm2',
      ]);

      chat.setMessageHiddenForSession('home-basket', 'm1', hidden: true);
      expect(chat.isMessageHiddenForSession('home-basket', 'm1'), isTrue);
      expect(chat.messages('home-basket').map((message) => message.id), ['m2']);
      await chat.loadMessages('home-basket', refresh: true);
      expect(chat.messages('home-basket').map((message) => message.id), ['m2']);

      chat.setMessageHiddenForSession('home-basket', 'm1', hidden: false);
      expect(chat.messages('home-basket').map((message) => message.id), [
        'm1',
        'm2',
      ]);
      chat.setMessageHiddenForSession('home-basket', 'm1', hidden: true);
      chat.resetForAuthenticationBoundary();
      expect(chat.isMessageHiddenForSession('home-basket', 'm1'), isFalse);
    },
  );

  testWidgets('copy and message details complete without leaving Chat', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final clipboardValues = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final arguments = Map<String, Object?>.from(call.arguments as Map);
            clipboardValues.add(arguments['text']! as String);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mountThread(tester, journey: journey, chat: chat);

    await openMessageActions(tester, 'm1');
    await tester.tap(find.byKey(const Key('chat-copy-m1')));
    await tester.pumpAndSettle();
    expect(clipboardValues, ['Please add atta, rice and oil for this month.']);
    expect(find.byKey(const Key('chat-message-copy-feedback')), findsOneWidget);
    await dismissFeedback(tester);

    await openMessageActions(tester, 'm1');
    await tester.tap(find.byKey(const Key('chat-message-info-action-m1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-info')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-info-sender')), findsOneWidget);
    expect(find.text('Received from'), findsOneWidget);
    expect(find.text('Amit'), findsWidgets);
    expect(find.text('Text message'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-info')), findsNothing);
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remove for me hides thread and search state with exact Undo', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mountThread(tester, journey: journey, chat: chat);

    await openMessageActions(tester, 'm1');
    await tester.scrollUntilVisible(
      find.byKey(const Key('chat-remove-message-m1')),
      160,
      scrollable: find.descendant(
        of: find.byKey(const Key('chat-message-actions')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('chat-remove-message-m1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-m1')), findsNothing);
    expect(chat.isMessageHiddenForSession('home-basket', 'm1'), isTrue);
    expect(
      find.byKey(const Key('chat-message-remove-feedback')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('chat-thread-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chat-conversation-search-field')),
      'rice and oil',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-conversation-search-empty')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-remove-undo')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-message-remove-undo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-m1')), findsOneWidget);
    expect(chat.isMessageHiddenForSession('home-basket', 'm1'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'clipboard failure and compact action scrolling recover truthfully',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              throw PlatformException(code: 'clipboard-unavailable');
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mountThread(
        tester,
        journey: journey,
        chat: chat,
        size: const Size(320, 568),
      );

      await openMessageActions(tester, 'm1');
      final actions = find.byKey(const Key('chat-message-actions'));
      final remove = find.byKey(const Key('chat-remove-message-m1'));
      await tester.scrollUntilVisible(
        remove,
        160,
        scrollable: find.descendant(
          of: actions,
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.getSize(remove).height, greaterThanOrEqualTo(44));
      expect(tester.getBottomRight(remove).dx, lessThanOrEqualTo(320));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(actions, findsNothing);

      await openMessageActions(tester, 'm1');
      await tester.tap(find.byKey(const Key('chat-copy-m1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-message-copy-recovery')),
        findsOneWidget,
      );
      expect(find.text('Copy unavailable'), findsOneWidget);
      expect(find.byKey(const Key('chat-message-copy-feedback')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
