import 'package:flutter/material.dart';
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

  Future<void> mountInbox(
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
        initialLocation: '/app/chat/inbox?return=/app/mool',
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openThread(WidgetTester tester, String threadId) async {
    final finder = find.byKey(Key('chat-open-thread-$threadId'));
    if (finder.evaluate().isEmpty) {
      final list = find.byKey(const PageStorageKey('chat-inbox-scroll'));
      await tester.drag(list, const Offset(0, 2000));
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 12 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(list, const Offset(0, -180));
        await tester.pumpAndSettle();
      }
    }
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
  }

  test(
    'draft summary, reply and authentication clearing stay thread-isolated',
    () {
      final chat = ChatSession();
      addTearDown(chat.dispose);

      chat.setDraftTextForSession('home-basket', '  Bring   rice\nand oil  ');
      chat.startReply('home-basket', 'm1');
      chat.setDraftTextForSession('rasoi', 'Ask about lunch');
      expect(chat.draftSummaryForSession('home-basket'), 'Bring rice and oil');
      expect(chat.draftSummaryForSession('rasoi'), 'Ask about lunch');
      expect(chat.replyTarget('home-basket')?.id, 'm1');
      expect(chat.replyTarget('rasoi'), isNull);

      chat.discardDraftForSession('home-basket');
      expect(chat.hasDraftForSession('home-basket'), isFalse);
      expect(chat.hasDraftForSession('rasoi'), isTrue);
      chat.resetForAuthenticationBoundary();
      expect(chat.hasDraftForSession('rasoi'), isFalse);
    },
  );

  testWidgets(
    'text and reply drafts survive Back, Search, Settings and thread changes',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mountInbox(tester, journey: journey, chat: chat);

      await openThread(tester, 'home-basket');
      await tester.longPress(find.byKey(const Key('chat-message-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-reply-m1')));
      await tester.pumpAndSettle();
      const homeDraft = 'Please keep two bags of rice.';
      await tester.enterText(
        find.byKey(const Key('chat-message-field')),
        homeDraft,
      );
      await tester.pump();
      expect(chat.draftTextForSession('home-basket'), homeDraft);
      expect(chat.replyTarget('home-basket')?.id, 'm1');

      await tester.tap(find.byKey(const Key('chat-thread-search')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-message-field')))
            .controller!
            .text,
        homeDraft,
      );
      await tester.tap(find.byKey(const Key('chat-conversation-info')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-info-open-global-settings')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-message-field')))
            .controller!
            .text,
        homeDraft,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Draft: $homeDraft'), findsOneWidget);
      await openThread(tester, 'rasoi');
      const foodDraft = 'Please make the lunch less spicy.';
      await tester.enterText(
        find.byKey(const Key('chat-message-field')),
        foodDraft,
      );
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Draft: $foodDraft'), findsOneWidget);

      await openThread(tester, 'home-basket');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-message-field')))
            .controller!
            .text,
        homeDraft,
      );
      expect(
        find.byKey(const Key('chat-composer-reply-context')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('chat-discard-draft')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-discard-draft')), findsNothing);
      expect(
        find.byKey(const Key('chat-composer-reply-context')),
        findsNothing,
      );
      expect(chat.hasDraftForSession('home-basket'), isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.textContaining('Draft: Please keep'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed send retains draft and successful send clears it', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = ReviewChatSendGateway(
      failNextRequest: true,
      latency: Duration.zero,
    );
    final journey = await readyJourney();
    final chat = ChatSession(sendGateway: gateway);
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mountInbox(
      tester,
      journey: journey,
      chat: chat,
      size: const Size(320, 568),
    );
    await openThread(tester, 'home-basket');
    const draft = 'Confirm the delivery gate.';
    await tester.enterText(find.byKey(const Key('chat-message-field')), draft);
    await tester.pump();
    final discard = find.byKey(const Key('chat-discard-draft'));
    expect(tester.getSize(discard).width, greaterThanOrEqualTo(44));
    expect(tester.getBottomRight(discard).dx, lessThanOrEqualTo(272));

    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(chat.draftTextForSession('home-basket'), draft);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller!
          .text,
      draft,
    );

    final retry = find.byKey(const Key('chat-retry-m11'));
    await tester.scrollUntilVisible(
      retry,
      160,
      scrollable: find.descendant(
        of: find.byKey(const Key('chat-message-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(chat.messages('home-basket').last.text, draft);
    expect(chat.hasDraftForSession('home-basket'), isFalse);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller!
          .text,
      isEmpty,
    );

    const successDraft = 'Send this successfully.';
    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      successDraft,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(chat.hasDraftForSession('home-basket'), isFalse);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
