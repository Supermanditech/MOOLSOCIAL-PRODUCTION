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

  Future<(ChatSession, _PrivacyGateway)> mount(
    WidgetTester tester, {
    String location = '/app/chat/inbox?return=/app/mool',
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    final journey = await readyJourney();
    final gateway = _PrivacyGateway();
    final chat = ChatSession.production(gateway: gateway);
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
    return (chat, gateway);
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-more-settings')));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('chat-settings-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('privacy choices persist and message requests resolve', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (chat, gateway) = await mount(tester);
    await openSettings(tester);

    await reveal(tester, const Key('chat-settings-who-can-message'));
    await tester.tap(find.byKey(const Key('chat-settings-who-can-message')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('chat-message-permission-connections')),
    );
    await tester.pumpAndSettle();
    expect(
      chat.privacySettings.whoCanMessage,
      ChatMessagePermission.connections,
    );

    await reveal(tester, const Key('chat-settings-message-requests'));
    await tester.tap(find.byKey(const Key('chat-settings-message-requests')));
    await tester.pumpAndSettle();
    expect(chat.privacySettings.messageRequestsEnabled, isFalse);

    await reveal(tester, const Key('chat-settings-review-message-requests'));
    await tester.tap(
      find.byKey(const Key('chat-settings-review-message-requests')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-message-requests-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('chat-message-request-accept-request-1')),
    );
    await tester.pumpAndSettle();
    expect(gateway.resolvedRequests, [('request-1', true)]);
    expect(
      find.byKey(const Key('chat-message-requests-empty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocked accounts unblock and conversation block is confirmed', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (_, gateway) = await mount(tester);
    await openSettings(tester);
    await reveal(tester, const Key('chat-settings-blocked-accounts'));
    await tester.tap(find.byKey(const Key('chat-settings-blocked-accounts')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-blocked-accounts-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-unblock-blocked-1')));
    await tester.pumpAndSettle();
    expect(gateway.blockChanges, [('blocked-1', false)]);
    expect(
      find.byKey(const Key('chat-blocked-accounts-empty')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-open-thread-thread-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-conversation-info')));
    await tester.pumpAndSettle();
    final block = find.byKey(const Key('chat-info-block-user'));
    await tester.scrollUntilVisible(
      block,
      220,
      scrollable: find.descendant(
        of: find.byKey(const Key('chat-conversation-info-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(block);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-block-confirmation')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-block-confirm')));
    await tester.pumpAndSettle();
    expect(gateway.blockChanges.last, ('member-2', true));
    expect(find.text('Member Two is blocked.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _PrivacyGateway implements ChatGateway, ChatPrivacyGateway {
  ChatPrivacySettings settings = const ChatPrivacySettings(
    whoCanMessage: ChatMessagePermission.everyone,
    messageRequestsEnabled: true,
    shareLastSeen: true,
    readReceipts: true,
  );
  final blockChanges = <(String, bool)>[];
  final resolvedRequests = <(String, bool)>[];
  final blocked = <ChatBlockedAccount>[
    ChatBlockedAccount(
      userId: 'blocked-1',
      name: 'Blocked Member',
      handle: '@blocked',
      blockedAt: DateTime.utc(2026, 8, 29),
    ),
  ];
  final requests = <ChatMessageRequest>[
    ChatMessageRequest(
      thread: requestThread,
      requestedByUserId: 'requester-1',
      requestedAt: DateTime.utc(2026, 8, 29),
    ),
  ];

  @override
  Future<ChatPrivacySettings> getPrivacySettings() async => settings;

  @override
  Future<ChatPrivacySettings> updatePrivacySettings(
    ChatPrivacySettings requested,
  ) async => settings = requested;

  @override
  Future<List<ChatBlockedAccount>> listBlockedAccounts() async =>
      List.of(blocked);

  @override
  Future<bool> setBlockedAccount({
    required String targetUserId,
    required bool blocked,
  }) async {
    blockChanges.add((targetUserId, blocked));
    if (!blocked) {
      this.blocked.removeWhere((item) => item.userId == targetUserId);
    }
    return blocked;
  }

  @override
  Future<List<ChatMessageRequest>> listMessageRequests() async =>
      List.of(requests);

  @override
  Future<bool> resolveMessageRequest({
    required String threadId,
    required bool accepted,
  }) async {
    resolvedRequests.add((threadId, accepted));
    requests.removeWhere((request) => request.thread.id == threadId);
    return accepted;
  }

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [
    thread,
  ];

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => const [
    ChatMessage(
      id: 'message-1',
      sender: 'Member Two',
      text: 'Hello',
      timeLabel: 'Now',
      mine: false,
    ),
  ];

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

const thread = ChatThread(
  id: 'thread-1',
  title: 'Member Two',
  subtitle: '@membertwo',
  preview: 'Hello',
  timeLabel: 'Now',
  type: ChatThreadType.people,
  targetUserId: 'member-2',
);

const requestThread = ChatThread(
  id: 'request-1',
  title: 'New Member',
  subtitle: '@newmember',
  preview: 'Can we talk?',
  timeLabel: 'Now',
  type: ChatThreadType.people,
  targetUserId: 'requester-1',
  messageRequestPending: true,
);
