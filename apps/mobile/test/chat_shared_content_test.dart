import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/chat/thread/$threadId?return=/app/mool',
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSharedContent(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-conversation-info')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-info-shared-content')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-shared-content-screen')), findsOneWidget);
  }

  testWidgets('loaded file reference opens truthful recovery and exact Back', (
    tester,
  ) async {
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
      size: const Size(360, 800),
    );
    await openSharedContent(tester);

    expect(find.byKey(const Key('chat-shared-item-file-m2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-shared-item-file-m2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-shared-file-recovery')), findsOneWidget);
    expect(find.text('File opening unavailable'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-conversation-info-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('media, file and link filters complete on compact large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final values = Map<String, Object?>.from(call.arguments as Map);
            copied.add(values['text']! as String);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final journey = await readyJourney();
    final chat = ChatSession.production(gateway: _SharedContentGateway());
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mountThread(
      tester,
      journey: journey,
      chat: chat,
      threadId: 'shared-content-thread',
      size: const Size(320, 568),
    );
    await openSharedContent(tester);

    expect(
      find.byKey(const Key('chat-shared-item-photo-photo-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat-shared-item-file-file-1')),
      findsOneWidget,
    );
    expect(find.text('https://moolsocial.com/help/order'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-shared-filter-media')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-shared-item-photo-photo-1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-shared-item-file-file-1')), findsNothing);
    await tester.tap(find.byKey(const Key('chat-shared-item-photo-photo-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-shared-photo-preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-shared-photo-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-shared-filter-links')));
    await tester.pumpAndSettle();
    final link = find.text('https://moolsocial.com/help/order');
    expect(link, findsOneWidget);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-shared-link-details')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-shared-link-copy')));
    await tester.pumpAndSettle();
    expect(copied, ['https://moolsocial.com/help/order']);
    expect(find.byKey(const Key('chat-shared-content-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SharedContentGateway implements ChatGateway {
  static const thread = ChatThread(
    id: 'shared-content-thread',
    title: 'Order Coordination',
    subtitle: 'Shared content',
    preview: 'Photo, file and link',
    timeLabel: 'Now',
    type: ChatThreadType.support,
  );

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [
    thread,
  ];

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => [
    ChatMessage(
      id: 'photo-1',
      sender: 'Support',
      text: 'Storefront photo',
      timeLabel: '10:10',
      mine: false,
      photo: ChatPhotoAttachment(
        id: 'photo-ref',
        name: 'storefront.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1200,
        readUrl: Uri.parse('https://example.invalid/storefront.jpg'),
        readUrlExpiresAt: DateTime.utc(2026, 8, 29, 12),
      ),
    ),
    const ChatMessage(
      id: 'file-1',
      sender: 'Support',
      text: 'Order document',
      timeLabel: '10:11',
      mine: false,
      attachmentLabel: 'Order-2841.pdf',
    ),
    const ChatMessage(
      id: 'link-1',
      sender: 'Support',
      text: 'Open https://moolsocial.com/help/order for help.',
      timeLabel: '10:12',
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
