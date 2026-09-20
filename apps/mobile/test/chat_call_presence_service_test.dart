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

  Future<(ChatSession, _CallGateway)> mount(
    WidgetTester tester, {
    required String location,
    _CallGateway? gateway,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    final journey = await readyJourney();
    final selectedGateway = gateway ?? _CallGateway();
    final chat = ChatSession.production(gateway: selectedGateway);
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
    return (chat, selectedGateway);
  }

  testWidgets('caller sees when recipient turned voice calls off', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = _CallGateway()..recipientVoiceEnabled = false;
    await mount(
      tester,
      location: '/app/chat/thread/thread-1?return=/app/mool',
      gateway: gateway,
    );

    await tester.tap(find.byKey(const Key('chat-thread-call')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-call-recovery')), findsOneWidget);
    expect(find.text('Member Two has turned off voice calls.'), findsOneWidget);
    expect(gateway.startedCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('available video call starts once and ends explicitly', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (_, gateway) = await mount(
      tester,
      location: '/app/chat/thread/thread-1?return=/app/mool',
    );

    await tester.tap(find.byKey(const Key('chat-thread-video')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-call-status')), findsOneWidget);
    expect(find.text('Calling Member Two'), findsOneWidget);
    expect(gateway.startedCalls.single.$2, ChatCallKind.video);
    await tester.tap(find.byKey(const Key('chat-call-end')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-call-status')), findsNothing);
    expect(gateway.endedCalls, ['call-1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('incoming call can be answered and ended from shared Chat', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = _CallGateway()..incoming.add(incomingCall);
    await mount(
      tester,
      location: '/app/chat/inbox?return=/app/mool',
      gateway: gateway,
    );

    expect(find.byKey(const Key('chat-incoming-call')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-incoming-accept')));
    await tester.pumpAndSettle();
    expect(gateway.responses, [('incoming-1', true)]);
    expect(find.byKey(const Key('chat-active-call')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-active-call-end')));
    await tester.pumpAndSettle();
    expect(gateway.endedCalls, ['incoming-1']);
    expect(tester.takeException(), isNull);
  });
}

class _CallGateway implements ChatGateway, ChatCallGateway {
  bool recipientVoiceEnabled = true;
  ChatCallPreferences preferences = ChatCallPreferences.defaults;
  final presence = <ChatPresenceState>[];
  final startedCalls = <(String, ChatCallKind, String)>[];
  final responses = <(String, bool)>[];
  final endedCalls = <String>[];
  final incoming = <ChatCall>[];

  @override
  Future<ChatCallPreferences> getCallPreferences() async => preferences;

  @override
  Future<ChatCallPreferences> updateCallPreferences(
    ChatCallPreferences requested,
  ) async => preferences = requested;

  @override
  Future<void> setPresence(ChatPresenceState state) async =>
      presence.add(state);

  @override
  Future<ChatCallAvailability> getCallAvailability({
    required String threadId,
    required ChatCallKind kind,
  }) async {
    final enabled = kind == ChatCallKind.video || recipientVoiceEnabled;
    return ChatCallAvailability(
      threadId: threadId,
      kind: kind,
      recipientUserId: 'member-2',
      recipientName: 'Member Two',
      canStart: enabled,
      status: enabled
          ? ChatCallAvailabilityStatus.available
          : ChatCallAvailabilityStatus.callsOff,
      message: enabled
          ? 'Member Two is available.'
          : 'Member Two has turned off voice calls.',
    );
  }

  @override
  Future<ChatCall> startCall({
    required String threadId,
    required ChatCallKind kind,
    required String idempotencyKey,
  }) async {
    startedCalls.add((threadId, kind, idempotencyKey));
    return call(kind: kind);
  }

  @override
  Future<ChatCall> respondToCall({
    required String callId,
    required bool accepted,
  }) async {
    responses.add((callId, accepted));
    incoming.removeWhere((call) => call.id == callId);
    return incomingCall.copyWithStatus(
      accepted ? ChatCallStatus.accepted : ChatCallStatus.declined,
    );
  }

  @override
  Future<ChatCall> endCall({required String callId}) async {
    endedCalls.add(callId);
    final source = callId == incomingCall.id ? incomingCall : call();
    return source.copyWithStatus(ChatCallStatus.ended);
  }

  @override
  Future<List<ChatCall>> listIncomingCalls() async => List.of(incoming);

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
  preview: 'Ready to talk',
  timeLabel: 'Now',
  type: ChatThreadType.people,
  targetUserId: 'member-2',
);

ChatCall call({ChatCallKind kind = ChatCallKind.voice}) => ChatCall(
  id: 'call-1',
  threadId: thread.id,
  kind: kind,
  callerUserId: 'current-user',
  recipientUserId: 'member-2',
  status: ChatCallStatus.ringing,
  createdAt: DateTime.utc(2026, 8, 29),
  updatedAt: DateTime.utc(2026, 8, 29),
);

final incomingCall = ChatCall(
  id: 'incoming-1',
  threadId: thread.id,
  kind: ChatCallKind.voice,
  callerUserId: 'member-2',
  recipientUserId: 'current-user',
  status: ChatCallStatus.ringing,
  createdAt: DateTime.utc(2026, 8, 29),
  updatedAt: DateTime.utc(2026, 8, 29),
);

extension on ChatCall {
  ChatCall copyWithStatus(ChatCallStatus value) => ChatCall(
    id: id,
    threadId: threadId,
    kind: kind,
    callerUserId: callerUserId,
    recipientUserId: recipientUserId,
    status: value,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
