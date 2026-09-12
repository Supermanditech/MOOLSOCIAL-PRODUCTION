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

  Future<void> mountThread(
    WidgetTester tester, {
    required JourneySession journey,
    required ChatSession chat,
    required String threadId,
    required String origin,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: Uri(
          path: '/app/chat/thread/$threadId',
          queryParameters: {'return': origin},
        ).toString(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSearch(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-thread-search')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-conversation-search-screen')),
      findsOneWidget,
    );
  }

  testWidgets(
    'search finds sender, text and attachment then returns to a highlighted result',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
        threadId: 'home-basket',
        origin: '/app/mool',
        size: const Size(360, 800),
      );

      const draft = 'This draft must stay in the composer.';
      await tester.enterText(
        find.byKey(const Key('chat-message-field')),
        draft,
      );
      await tester.pump();
      await openSearch(tester);
      final field = find.byKey(const Key('chat-conversation-search-field'));
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

      await tester.enterText(field, 'Amit');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-search-result-m1')),
        findsOneWidget,
      );
      expect(find.text('1 result'), findsOneWidget);
      await tester.enterText(field, 'Monthly Staples.pdf');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-search-result-m2')),
        findsOneWidget,
      );

      await tester.enterText(field, 'rice and oil');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('chat-conversation-search-result-m1')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      final highlight = find.byKey(const Key('chat-message-highlight-m1'));
      expect(highlight, findsOneWidget);
      final decoration = tester.widget<AnimatedContainer>(highlight).decoration;
      expect((decoration as BoxDecoration).border, isNotNull);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-message-field')))
            .controller!
            .text,
        draft,
      );

      await openSearch(tester);
      await tester.enterText(
        find.byKey(const Key('chat-conversation-search-field')),
        'no matching message',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-search-empty')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('chat-conversation-search-empty-clear')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Find a message'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a distant result scrolls into view and highlights exactly', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession.production(gateway: _LongSearchGateway());
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mountThread(
      tester,
      journey: journey,
      chat: chat,
      threadId: 'search-thread',
      origin: '/app/mool',
      size: const Size(360, 800),
    );

    expect(
      find.byKey(const Key('chat-message-highlight-message-23')),
      findsNothing,
    );
    await openSearch(tester);
    await tester.enterText(
      find.byKey(const Key('chat-conversation-search-field')),
      'needle at the end',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('chat-conversation-search-result-message-23')),
    );
    await tester.pumpAndSettle();

    final highlight = find.byKey(
      const Key('chat-message-highlight-message-23'),
    );
    expect(highlight, findsOneWidget);
    expect(tester.getTopLeft(highlight).dy, greaterThanOrEqualTo(80));
    expect(
      tester.getBottomRight(highlight).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('chat-composer-surface'))).dy,
      ),
    );
    final decoration = tester.widget<AnimatedContainer>(highlight).decoration;
    expect((decoration as BoxDecoration).border, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact Work search is collision-free, keyboard-safe and reduced',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.reset);
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
        threadId: 'work-opportunity',
        origin: '/app/work/earn',
        size: const Size(320, 568),
      );

      final search = find.byKey(const Key('chat-thread-search'));
      final video = find.byKey(const Key('chat-thread-video'));
      final call = find.byKey(const Key('chat-thread-call'));
      for (final finder in [search, video, call]) {
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
        expect(tester.getBottomRight(finder).dx, lessThanOrEqualTo(320));
      }
      expect(tester.getRect(search).overlaps(tester.getRect(video)), isFalse);
      expect(tester.getRect(video).overlaps(tester.getRect(call)), isFalse);

      await openSearch(tester);
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const Key('chat-conversation-search-focus-motion')),
            )
            .duration,
        Duration.zero,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.enterText(
        find.byKey(const Key('chat-conversation-search-field')),
        'eligibility',
      );
      await tester.pumpAndSettle();
      final searchScope = find.byKey(
        const Key('chat-conversation-search-scope'),
      );
      final media = MediaQuery.of(tester.element(searchScope));
      final safeBottom = media.size.height - media.viewInsets.bottom;
      expect(
        tester.getBottomRight(searchScope).dy,
        lessThanOrEqualTo(safeBottom),
      );
      expect(
        find.byKey(
          const Key('chat-conversation-search-result-work-opportunity-1'),
        ),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _LongSearchGateway implements ChatGateway {
  static const thread = ChatThread(
    id: 'search-thread',
    title: 'Long Conversation',
    subtitle: 'Search test',
    preview: 'Twenty-four messages',
    timeLabel: 'Now',
    type: ChatThreadType.people,
  );

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [
    thread,
  ];

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => List.generate(
    24,
    (index) => ChatMessage(
      id: 'message-$index',
      sender: index.isEven ? 'Amit' : 'You',
      text: index == 23
          ? 'This is the needle at the end of the conversation.'
          : 'Conversation message $index with enough text for a normal bubble.',
      timeLabel: '10:${index.toString().padLeft(2, '0')}',
      mine: index.isOdd,
    ),
  );

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) async =>
      thread;

  @override
  Future<void> markThreadRead({required String threadId}) async {}

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) => Future.error(UnsupportedError('Not used by this test.'));

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) => Future.error(UnsupportedError('Not used by this test.'));

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) => Future.error(UnsupportedError('Not used by this test.'));
}
