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

  Future<(_NotificationGateway, _NotificationClient, ChatSession)> mount(
    WidgetTester tester, {
    ChatNotificationPermission permission = ChatNotificationPermission.unknown,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    final journey = await readyJourney();
    final gateway = _NotificationGateway();
    final client = _NotificationClient()..status = permission;
    final chat = ChatSession.production(
      gateway: gateway,
      notificationClient: client,
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/chat/inbox?return=/app/mool',
      ),
    );
    await tester.pumpAndSettle();
    return (gateway, client, chat);
  }

  Future<void> openNotifications(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-more-settings')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('chat-settings-list')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    final target = find.byKey(const Key('chat-settings-notifications'));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-notification-settings-screen')),
      findsOneWidget,
    );
  }

  testWidgets(
    'device registration categories previews and quiet hours persist',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final (gateway, client, chat) = await mount(tester);
      await openNotifications(tester);

      await tester.tap(
        find.byKey(const Key('chat-notification-device-enable')),
      );
      await tester.pumpAndSettle();
      expect(client.requests, 1);
      expect(gateway.registered, [(deviceToken, 'android')]);
      expect(chat.deviceNotificationsRegistered, isTrue);

      for (final key in const [
        Key('chat-notification-messages'),
        Key('chat-notification-preview'),
        Key('chat-notification-quiet-hours'),
      ]) {
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
      }
      expect(chat.notificationPreferences.messagesEnabled, isFalse);
      expect(chat.notificationPreferences.showPreview, isFalse);
      expect(chat.notificationPreferences.quietHoursEnabled, isTrue);
      expect(
        find.byKey(const Key('chat-notification-quiet-start')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('chat-notification-quiet-end')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('chat-notification-device-pause')));
      await tester.pumpAndSettle();
      expect(gateway.unregistered, [deviceToken]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('denied device permission preserves saved choices', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (_, _, chat) = await mount(
      tester,
      permission: ChatNotificationPermission.denied,
    );
    await openNotifications(tester);
    await tester.tap(find.byKey(const Key('chat-notification-device-enable')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-notification-device-recovery')),
      findsOneWidget,
    );
    expect(chat.deviceNotificationsRegistered, isFalse);
    expect(chat.notificationPreferences.messagesEnabled, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _NotificationClient implements ChatNotificationClient {
  ChatNotificationPermission status = ChatNotificationPermission.unknown;
  int requests = 0;

  @override
  String get platform => 'android';

  @override
  Future<ChatNotificationPermission> permission({required bool request}) async {
    if (request) {
      requests += 1;
      if (status == ChatNotificationPermission.unknown) {
        status = ChatNotificationPermission.authorized;
      }
    }
    return status;
  }

  @override
  Future<String?> token() async => deviceToken;
}

const deviceToken =
    'device-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

class _NotificationGateway implements ChatGateway, ChatNotificationGateway {
  ChatNotificationPreferences preferences =
      ChatNotificationPreferences.defaults();
  final registered = <(String, String)>[];
  final unregistered = <String>[];

  @override
  Future<ChatNotificationPreferences> getNotificationPreferences() async =>
      preferences;

  @override
  Future<ChatNotificationPreferences> updateNotificationPreferences(
    ChatNotificationPreferences requested,
  ) async => preferences = requested;

  @override
  Future<bool> registerNotificationDevice({
    required String token,
    required String platform,
  }) async {
    registered.add((token, platform));
    return true;
  }

  @override
  Future<bool> unregisterNotificationDevice({required String token}) async {
    unregistered.add(token);
    return false;
  }

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [];

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => const [];

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) =>
      Future.error(UnimplementedError());

  @override
  Future<void> markThreadRead({required String threadId}) async {}

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) => Future.error(UnimplementedError());

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) => Future.error(UnimplementedError());

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) => Future.error(UnimplementedError());
}
