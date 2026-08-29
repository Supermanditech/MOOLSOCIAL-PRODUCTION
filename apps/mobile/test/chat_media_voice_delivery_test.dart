import 'dart:typed_data';

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

  Future<(_MediaGateway, _Picker, _Recorder, _Playback)> mount(
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    final journey = await readyJourney();
    final gateway = _MediaGateway();
    final picker = _Picker();
    final recorder = _Recorder();
    final playback = _Playback();
    final chat = ChatSession.production(
      gateway: gateway,
      attachmentPicker: picker,
      voiceRecorder: recorder,
      attachmentPlayback: playback,
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/chat/thread/thread-1?return=/app/mool',
      ),
    );
    await tester.pumpAndSettle();
    return (gateway, picker, recorder, playback);
  }

  Future<void> openTray(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-attachment-tray')), findsOneWidget);
  }

  testWidgets('document and video pick send render and open exactly', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (gateway, picker, _, playback) = await mount(tester);

    for (final entry in const [
      (ChatAttachmentKind.document, 'chat-document'),
      (ChatAttachmentKind.video, 'chat-video'),
    ]) {
      picker.next = picked(entry.$1);
      await openTray(tester);
      await tester.tap(find.byKey(Key(entry.$2)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-selected-attachment')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-send-attachment')));
      await tester.pumpAndSettle();
      final messageId = 'attachment-${gateway.sent.length}';
      expect(find.byKey(Key('chat-attachment-$messageId')), findsOneWidget);
      await tester.tap(find.byKey(Key('chat-attachment-$messageId')));
      await tester.pumpAndSettle();
      expect(playback.opened.last.kind, entry.$1);
    }
    expect(gateway.sent.map((item) => item.kind), [
      ChatAttachmentKind.document,
      ChatAttachmentKind.video,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voice recording stops stages sends and plays', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (gateway, _, recorder, playback) = await mount(tester);

    await tester.tap(find.byKey(const Key('chat-voice-message')));
    await tester.pumpAndSettle();
    expect(recorder.starts, 1);
    expect(find.byKey(const Key('chat-voice-stop')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-voice-stop')));
    await tester.pumpAndSettle();
    expect(recorder.stops, 1);
    expect(find.text('Voice message ready to send'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-send-attachment')));
    await tester.pumpAndSettle();
    expect(gateway.sent.single.kind, ChatAttachmentKind.voice);
    expect(
      find.byKey(const Key('chat-attachment-attachment-1')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-attachment-attachment-1')));
    await tester.pumpAndSettle();
    expect(playback.opened.single.kind, ChatAttachmentKind.voice);
    expect(tester.takeException(), isNull);
  });
}

ChatPickedAttachment picked(ChatAttachmentKind kind) => ChatPickedAttachment(
  kind: kind,
  name: switch (kind) {
    ChatAttachmentKind.document => 'invoice.pdf',
    ChatAttachmentKind.video => 'delivery.mp4',
    ChatAttachmentKind.voice => 'Voice message.m4a',
  },
  contentType: switch (kind) {
    ChatAttachmentKind.document => 'application/pdf',
    ChatAttachmentKind.video => 'video/mp4',
    ChatAttachmentKind.voice => 'audio/mp4',
  },
  bytes: Uint8List.fromList([1, 2, 3, 4]),
  duration: kind == ChatAttachmentKind.voice
      ? const Duration(seconds: 2)
      : null,
);

class _Picker implements ChatAttachmentPicker {
  ChatPickedAttachment? next;

  @override
  Future<ChatPickedAttachment?> pick(ChatAttachmentKind kind) async {
    final selected = next;
    next = null;
    return selected;
  }
}

class _Recorder implements ChatVoiceRecorder {
  int starts = 0;
  int stops = 0;

  @override
  Future<void> start() async => starts += 1;

  @override
  Future<ChatPickedAttachment> stop() async {
    stops += 1;
    return picked(ChatAttachmentKind.voice);
  }

  @override
  Future<void> cancel() async {}

  @override
  void dispose() {}
}

class _Playback implements ChatAttachmentPlayback {
  final opened = <ChatAttachment>[];

  @override
  Future<void> open(ChatAttachment attachment) async => opened.add(attachment);

  @override
  void dispose() {}
}

class _MediaGateway implements ChatGateway, ChatAttachmentGateway {
  final sent = <ChatPickedAttachment>[];

  @override
  Future<ChatMessage> sendAttachment({
    required String threadId,
    required ChatPickedAttachment attachment,
    required String caption,
    required String idempotencyKey,
    String? replyToMessageId,
  }) async {
    sent.add(attachment);
    final index = sent.length;
    return ChatMessage(
      id: 'attachment-$index',
      sender: 'You',
      text: caption,
      timeLabel: 'Now',
      mine: true,
      attachment: ChatAttachment(
        id: 'uploaded-$index',
        kind: attachment.kind,
        name: attachment.name,
        contentType: attachment.contentType,
        sizeBytes: attachment.bytes.length,
        duration: attachment.duration,
        readUrl: Uri.parse('https://storage.googleapis.com/chat/$index'),
        readUrlExpiresAt: DateTime.utc(2026, 8, 29, 12),
      ),
    );
  }

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [
    thread,
  ];

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => const [];

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
  preview: 'Share safely',
  timeLabel: 'Now',
  type: ChatThreadType.people,
);
