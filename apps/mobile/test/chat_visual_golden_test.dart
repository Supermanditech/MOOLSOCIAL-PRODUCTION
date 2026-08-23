import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> verifyScreen(
    WidgetTester tester, {
    required String route,
    required String golden,
    required ChatGateway gateway,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
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
    final chat = ChatSession.production(gateway: gateway);
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      chat.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: ValueKey(route),
        session: journey,
        chatSession: chat,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    for (final retiredAction in const [
      Key('chat-call'),
      Key('chat-video'),
      Key('chat-attach'),
      Key('chat-mode-orders'),
      Key('chat-mode-quote'),
      Key('chat-mode-pay'),
    ]) {
      expect(find.byKey(retiredAction), findsNothing);
    }
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(golden));
  }

  final screens = <(String, String, String, ChatGateway Function())>[
    (
      'C30T Chat empty inbox 023',
      '/app/chat/inbox',
      'chat-c30t-023-empty-inbox',
      () => const _GoldenChatGateway(),
    ),
    (
      'C30T Chat unavailable inbox 023',
      '/app/chat/inbox',
      'chat-c30t-023-unavailable-inbox',
      () => const _GoldenChatGateway(unavailable: true),
    ),
    (
      'C31C Chat provider support reply reaction forward 022',
      '/app/chat/thread/provider-support',
      'chat-c31c-022-provider-support-forward-action',
      () => const _GoldenChatGateway(includeProviderData: true),
    ),
    (
      'C31C Chat provider business read forward action 024',
      '/app/chat/thread/provider-business',
      'chat-c31c-024-provider-business-read-forward-action',
      () => const _GoldenChatGateway(includeProviderData: true),
    ),
    (
      'C31C Chat provider people reply reaction forward 025',
      '/app/chat/thread/provider-people',
      'chat-c31c-025-provider-people-forward-action',
      () => const _GoldenChatGateway(includeProviderData: true),
    ),
    (
      'C31C Chat provider business forwarded marker 024',
      '/app/chat/thread/provider-business',
      'chat-c31c-024-provider-business-forwarded',
      () => const _GoldenChatGateway(
        includeProviderData: true,
        includeForwardedMarker: true,
      ),
    ),
  ];

  for (final screen in screens) {
    testWidgets('${screen.$1} phone visual baseline', (tester) async {
      await verifyScreen(
        tester,
        route: screen.$2,
        golden: 'goldens/${screen.$3}-412x915.png',
        gateway: screen.$4(),
      );
    });
  }
}

class _GoldenChatGateway implements ChatGateway {
  const _GoldenChatGateway({
    this.includeProviderData = false,
    this.includeForwardedMarker = false,
    this.unavailable = false,
  });

  final bool includeProviderData;
  final bool includeForwardedMarker;
  final bool unavailable;

  Never _throwUnavailable() => throw const ChatServiceException(
    'Chat is unavailable right now. Try again later.',
    code: 'service_unavailable',
    retryable: true,
  );

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async {
    if (unavailable) _throwUnavailable();
    return includeProviderData ? _providerThreads.take(limit).toList() : [];
  }

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async {
    if (unavailable) _throwUnavailable();
    if (!includeProviderData) return [];
    return [
      ChatMessage(
        id: 'provider-message-$threadId',
        sender: _providerThreads
            .firstWhere((thread) => thread.id == threadId)
            .title,
        text: 'This message was returned by the authenticated Chat provider.',
        timeLabel: 'Now',
        mine: false,
        reactionCount: threadId == 'provider-business' ? 2 : 0,
        reactedByMe: threadId == 'provider-business',
        replyTo: threadId == 'provider-people'
            ? const ChatReplyReference(
                messageId: 'provider-original-message',
                sender: 'Community member',
                text: 'Can everyone meet near the community hall?',
              )
            : null,
      ),
      if (threadId == 'provider-business')
        ChatMessage(
          id: 'provider-read-message',
          sender: 'You',
          text: 'Thank you. I will review the confirmed details.',
          timeLabel: 'Now',
          mine: true,
          deliveryState: ChatDeliveryState.read,
          readCount: 1,
          forwarded: includeForwardedMarker,
        ),
    ].take(limit).toList();
  }

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) async {
    if (unavailable || !includeProviderData) _throwUnavailable();
    return _providerThreads.first;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) async {
    if (unavailable || !includeProviderData) _throwUnavailable();
    return ChatMessage(
      id: 'provider-sent-message',
      sender: 'You',
      text: text,
      timeLabel: 'Now',
      mine: true,
      replyTo: replyToMessageId == null
          ? null
          : const ChatReplyReference(
              messageId: 'provider-message-provider-people',
              sender: 'Jodhpur Community Group',
              text:
                  'This message was returned by the authenticated Chat provider.',
            ),
    );
  }

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) async {
    if (unavailable || !includeProviderData) _throwUnavailable();
    return ChatMessage(
      id: messageId,
      sender: 'Jodhpur Community Group',
      text: 'This message was returned by the authenticated Chat provider.',
      timeLabel: 'Now',
      mine: false,
      reactionCount: reacted ? 1 : 0,
      reactedByMe: reacted,
    );
  }

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) async {
    if (unavailable || !includeProviderData) _throwUnavailable();
    return const ChatMessage(
      id: 'provider-forwarded-message',
      sender: 'You',
      text: 'This message was returned by the authenticated Chat provider.',
      timeLabel: 'Now',
      mine: true,
      forwarded: true,
    );
  }

  @override
  Future<void> markThreadRead({required String threadId}) async {
    if (unavailable) _throwUnavailable();
  }
}

const _providerThreads = <ChatThread>[
  ChatThread(
    id: 'provider-support',
    title: 'MoolSocial Support',
    subtitle: 'Authenticated support conversation',
    preview: 'Your support conversation is ready.',
    timeLabel: 'Now',
    type: ChatThreadType.support,
    verified: true,
  ),
  ChatThread(
    id: 'provider-business',
    title: 'Verified Local Business',
    subtitle: 'Authenticated business conversation',
    preview: 'Your business conversation is ready.',
    timeLabel: 'Now',
    type: ChatThreadType.business,
    verified: true,
  ),
  ChatThread(
    id: 'provider-people',
    title: 'Jodhpur Community Group',
    subtitle: 'Authenticated people conversation',
    preview: 'Your community conversation is ready.',
    timeLabel: 'Now',
    type: ChatThreadType.people,
  ),
];
