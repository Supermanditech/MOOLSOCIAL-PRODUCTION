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

  Future<ChatSession> mount(
    WidgetTester tester, {
    String location = '/app/chat/inbox?return=/app/mool',
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: location,
      ),
    );
    await tester.pumpAndSettle();
    return chat;
  }

  Future<void> closeRecovery(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-capability-continue')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'one shared navigation stack completes every conversation utility depth',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await mount(tester, size: const Size(360, 800));
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-open-thread-home-basket')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-thread-search')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-search-screen')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-conversation-info')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-info-screen')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('chat-info-group-info')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-group-info-screen')), findsOneWidget);

      final groupList = find.byKey(const Key('chat-group-info-list'));
      await tester.drag(groupList, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-group-shared-content')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-shared-content-screen')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-group-info-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-info-screen')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('chat-info-open-global-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-settings-screen')), findsOneWidget);
      final notification = find.byKey(const Key('chat-settings-notifications'));
      await tester.drag(
        find.byKey(const Key('chat-settings-list')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(notification);
      await tester.pumpAndSettle();
      await tester.tap(notification);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-notification-settings-screen')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-settings-screen')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-info-screen')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'call voice document and video intents recover without leaving Chat',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final chat = await mount(
        tester,
        location: '/app/chat/thread/mahadev?return=/app/mool',
        size: const Size(360, 800),
      );
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);

      for (final action in const <(Key, Key, String)>[
        (
          Key('chat-thread-video'),
          Key('chat-video-recovery'),
          'Video calling unavailable',
        ),
        (
          Key('chat-thread-call'),
          Key('chat-call-recovery'),
          'Voice calling unavailable',
        ),
        (
          Key('chat-voice-message'),
          Key('chat-voice-message-recovery'),
          'Voice messages unavailable',
        ),
      ]) {
        await tester.tap(find.byKey(action.$1));
        await tester.pumpAndSettle();
        expect(find.byKey(action.$2), findsOneWidget);
        expect(find.text(action.$3), findsOneWidget);
        await closeRecovery(tester);
        expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('chat-attach')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-attachment-tray')), findsOneWidget);
      expect(
        tester.widget<InkWell>(find.byKey(const Key('chat-document'))).onTap,
        isNull,
      );
      expect(
        tester.widget<InkWell>(find.byKey(const Key('chat-video'))).onTap,
        isNull,
      );
      expect(
        find.textContaining(
          'Document, photo, camera and video sharing are unavailable',
        ),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-attachment-tray')), findsNothing);
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(chat.messages('mahadev'), hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
}
