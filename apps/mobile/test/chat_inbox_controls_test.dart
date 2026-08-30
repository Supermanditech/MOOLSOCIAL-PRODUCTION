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
    String origin = '/app/mool',
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        key: ValueKey(origin),
        session: journey,
        chatSession: chat,
        initialLocation: Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': origin},
        ).toString(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openActions(WidgetTester tester, String threadId) async {
    final more = find.byKey(Key('chat-thread-more-$threadId'));
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-conversation-actions')), findsOneWidget);
  }

  Future<void> dismissFeedback(WidgetTester tester) async {
    final messenger = tester.state<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger).first,
    );
    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.remove);
    await tester.pumpAndSettle();
  }

  test(
    'session controls sort, preserve unread truth and clear at sign-out',
    () {
      final chat = ChatSession();
      addTearDown(chat.dispose);

      final rasoi = chat.thread('rasoi');
      expect(chat.isPinnedForSession('shop-assist'), isTrue);
      expect(chat.visibleThreads().first.id, 'shop-assist');
      chat.setPinnedForSession('shop-assist', pinned: false);
      expect(chat.visibleThreads().first.id, isNot('rasoi'));
      chat.setPinnedForSession('rasoi', pinned: true);
      expect(chat.visibleThreads().first.id, 'rasoi');

      chat.setReducedAttentionForSession('rasoi', reduced: true);
      expect(chat.hasReducedAttentionForSession('rasoi'), isTrue);
      expect(chat.unreadFor(rasoi), 1);
      chat.setReadForSession('rasoi', read: true);
      expect(chat.unreadFor(rasoi), 0);
      chat.setReadForSession('rasoi', read: false);
      expect(chat.unreadFor(rasoi), 1);

      chat.setArchivedForSession('rasoi', archived: true);
      expect(
        chat.visibleThreads().any((thread) => thread.id == 'rasoi'),
        isFalse,
      );
      expect(chat.archivedThreads().single.id, 'rasoi');
      expect(chat.isPinnedForSession('rasoi'), isTrue);
      chat.setArchivedForSession('rasoi', archived: false);
      expect(
        chat.visibleThreads().any((thread) => thread.id == 'rasoi'),
        isTrue,
      );

      chat.setGlobalChatAvailableForSession(available: false);
      chat.setGlobalReviewBeforeSendingForSession(enabled: true);
      chat.setHideMessagePreviewsForSession(hidden: true);
      chat.resetForAuthenticationBoundary();
      expect(chat.isPinnedForSession('rasoi'), isFalse);
      expect(chat.isPinnedForSession('shop-assist'), isTrue);
      expect(chat.hasReducedAttentionForSession('rasoi'), isFalse);
      expect(chat.isArchivedForSession('rasoi'), isFalse);
      expect(chat.globalChatAvailableForSession, isTrue);
      expect(chat.globalReviewBeforeSendingForSession, isFalse);
      expect(chat.hideMessagePreviewsForSession, isFalse);
    },
  );

  testWidgets(
    'MoolSocial Assist starts on top and can be unpinned or restored',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mountInbox(tester, journey: journey, chat: chat);

      final assist = find.byKey(const ValueKey('chat-open-thread-shop-assist'));
      final orderSupport = find.byKey(
        const ValueKey('chat-open-thread-order-support'),
      );
      expect(chat.isPinnedForSession('shop-assist'), isTrue);
      expect(
        tester.getTopLeft(assist).dy,
        lessThan(tester.getTopLeft(orderSupport).dy),
      );

      await openActions(tester, 'shop-assist');
      expect(find.text('Unpin conversation'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-action-pin-shop-assist')));
      await tester.pumpAndSettle();
      expect(chat.isPinnedForSession('shop-assist'), isFalse);
      expect(
        find.text('Conversation unpinned for this app session.'),
        findsOneWidget,
      );
      await dismissFeedback(tester);

      await openActions(tester, 'shop-assist');
      expect(find.text('Pin conversation'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-action-pin-shop-assist')));
      await tester.pumpAndSettle();
      expect(chat.isPinnedForSession('shop-assist'), isTrue);
      expect(
        find.text('Conversation pinned for this app session.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'conversation actions pin, quiet, read, archive, undo and restore safely',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mountInbox(
        tester,
        journey: journey,
        chat: chat,
        size: const Size(360, 800),
      );

      final more = find.byKey(const Key('chat-thread-more-rasoi'));
      expect(tester.getSize(more).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(more).height, greaterThanOrEqualTo(44));

      await openActions(tester, 'rasoi');
      await tester.tap(find.byKey(const Key('chat-action-pin-rasoi')));
      await tester.pumpAndSettle();
      expect(chat.isPinnedForSession('rasoi'), isTrue);
      await tester.fling(
        find.byKey(const PageStorageKey('chat-inbox-scroll')),
        const Offset(0, 2000),
        3000,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('chat-open-thread-rasoi'))).dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const Key('chat-open-thread-order-support')),
              )
              .dy,
        ),
      );
      await dismissFeedback(tester);

      await openActions(tester, 'rasoi');
      await tester.tap(find.byKey(const Key('chat-action-attention-rasoi')));
      await tester.pumpAndSettle();
      expect(chat.hasReducedAttentionForSession('rasoi'), isTrue);
      expect(chat.unreadFor(chat.thread('rasoi')), 1);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('chat-thread-more-rasoi')))
            .icon,
        isA<Icon>().having(
          (icon) => icon.icon,
          'icon',
          Icons.notifications_paused_outlined,
        ),
      );
      await dismissFeedback(tester);

      await openActions(tester, 'rasoi');
      await tester.tap(find.byKey(const Key('chat-action-read-rasoi')));
      await tester.pumpAndSettle();
      expect(chat.unreadFor(chat.thread('rasoi')), 0);
      await dismissFeedback(tester);
      await openActions(tester, 'rasoi');
      expect(find.text('Mark as unread'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-action-read-rasoi')));
      await tester.pumpAndSettle();
      expect(chat.unreadFor(chat.thread('rasoi')), 1);
      await dismissFeedback(tester);

      await openActions(tester, 'rasoi');
      await tester.tap(find.byKey(const Key('chat-action-archive-rasoi')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-open-thread-rasoi')), findsNothing);
      expect(find.byKey(const Key('chat-archive-feedback')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-archive-undo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-open-thread-rasoi')), findsOneWidget);
      expect(chat.isPinnedForSession('rasoi'), isTrue);

      await openActions(tester, 'rasoi');
      await tester.tap(find.byKey(const Key('chat-action-archive-rasoi')));
      await tester.pumpAndSettle();
      expect(chat.isArchivedForSession('rasoi'), isTrue);
      await dismissFeedback(tester);
      await tester.tap(find.byKey(const Key('chat-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-more-archived')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat-archived-screen')), findsOneWidget);
      expect(find.byKey(const Key('chat-archived-open-rasoi')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-archived-open-rasoi')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-archived-screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-archived-restore-rasoi')));
      await tester.pumpAndSettle();
      expect(find.text('No archived conversations'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(find.byKey(const Key('chat-open-thread-rasoi')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact long press opens actions and native Back dismisses first',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mountInbox(
        tester,
        journey: journey,
        chat: chat,
        origin: '/app/work/earn',
        size: const Size(320, 568),
      );

      await tester.longPress(
        find.byKey(const Key('chat-open-thread-work-opportunity')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-actions')),
        findsOneWidget,
      );
      for (final key in const [
        Key('chat-action-pin-work-opportunity'),
        Key('chat-action-attention-work-opportunity'),
        Key('chat-action-read-work-opportunity'),
        Key('chat-action-archive-work-opportunity'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, lessThanOrEqualTo(320));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-conversation-actions')), findsNothing);
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

      chat.setArchivedForSession('work-opportunity', archived: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-more-archived')));
      await tester.pumpAndSettle();
      final restore = find.byKey(
        const Key('chat-archived-restore-work-opportunity'),
      );
      expect(find.byKey(const Key('chat-archived-screen')), findsOneWidget);
      expect(tester.getSize(restore).height, greaterThanOrEqualTo(44));
      expect(tester.getBottomRight(restore).dx, lessThanOrEqualTo(320));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
