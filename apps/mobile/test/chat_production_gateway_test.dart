import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/chat/screens/chat_inbox_screen.dart';
import 'package:moolsocial/features/chat/screens/chat_thread_screen.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';

void main() {
  test('release Chat cannot retain a review or no-op send fallback', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final sessionSource = File(
      'lib/features/chat/chat_session.dart',
    ).readAsStringSync();
    final productionStart = sessionSource.indexOf('ChatSession.production(');
    final productionEnd = sessionSource.indexOf(
      'final ChatGateway? _gateway;',
      productionStart,
    );

    expect(mainSource, contains('chatSession: ChatSession.production(),'));
    expect(productionStart, greaterThanOrEqualTo(0));
    expect(productionEnd, greaterThan(productionStart));
    final productionConstructor = sessionSource.substring(
      productionStart,
      productionEnd,
    );
    expect(productionConstructor, contains('_reviewSendGateway = null'));
    expect(productionConstructor, isNot(contains('ReviewChatSendGateway')));
  });

  test(
    'authenticated gateway transports reply reaction read and forward state',
    () async {
      final transport = _RecordingTransport([
        SocialContentResponse(
          statusCode: 200,
          body: jsonEncode({
            'ok': true,
            'data': {
              'id': 'message-reply',
              'senderName': 'You',
              'text': 'Reply body',
              'createdAt': '2026-08-14T00:00:00.000Z',
              'mine': true,
              'reactionCount': 2,
              'reactedByMe': true,
              'readCount': 1,
              'readByOthers': true,
              'replyTo': {
                'messageId': 'message-original',
                'senderName': 'Member',
                'text': 'Original body',
              },
            },
          }),
        ),
        SocialContentResponse(
          statusCode: 200,
          body: jsonEncode({
            'ok': true,
            'data': {
              'id': 'message-original',
              'senderName': 'Member',
              'text': 'Original body',
              'createdAt': '2026-08-14T00:00:00.000Z',
              'mine': false,
              'reactionCount': 1,
              'reactedByMe': true,
            },
          }),
        ),
        SocialContentResponse(
          statusCode: 200,
          body: jsonEncode({
            'ok': true,
            'data': {
              'id': 'message-forwarded',
              'senderName': 'You',
              'text': 'Original body',
              'createdAt': '2026-08-14T00:00:00.000Z',
              'mine': true,
              'reactionCount': 0,
              'reactedByMe': false,
              'forwarded': true,
            },
          }),
        ),
        SocialContentResponse(
          statusCode: 200,
          body: jsonEncode({
            'ok': true,
            'data': {'threadId': 'thread-1', 'unreadCount': 0},
          }),
        ),
      ]);
      final credentials = _RecordingCredentials();
      final gateway = AuthenticatedChatGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialChat',
        ),
        credentials: credentials,
        transport: transport,
        random: Random(1),
      );

      final reply = await gateway.sendMessage(
        threadId: 'thread-1',
        text: 'Reply body',
        idempotencyKey: 'chat-message-reply-0004',
        replyToMessageId: 'message-original',
      );
      final reacted = await gateway.setReaction(
        threadId: 'thread-1',
        messageId: 'message-original',
        reacted: true,
      );
      final forwarded = await gateway.forwardMessage(
        sourceThreadId: 'thread-1',
        sourceMessageId: 'message-original',
        targetThreadId: 'thread-2',
        idempotencyKey: 'chat-forward-retry-0004',
      );
      await gateway.markThreadRead(threadId: 'thread-1');

      expect(reply.replyTo?.messageId, 'message-original');
      expect(reply.reactionCount, 2);
      expect(reply.reactedByMe, isTrue);
      expect(reply.readCount, 1);
      expect(reply.deliveryState, ChatDeliveryState.read);
      expect(reacted.reactionCount, 1);
      expect(reacted.reactedByMe, isTrue);
      expect(forwarded.forwarded, isTrue);
      expect(forwarded.text, 'Original body');
      expect(transport.bodies, [
        {
          'operation': 'sendMessage',
          'threadId': 'thread-1',
          'text': 'Reply body',
          'idempotencyKey': 'chat-message-reply-0004',
          'replyToMessageId': 'message-original',
        },
        {
          'operation': 'setReaction',
          'threadId': 'thread-1',
          'messageId': 'message-original',
          'reacted': true,
        },
        {
          'operation': 'forwardMessage',
          'sourceThreadId': 'thread-1',
          'sourceMessageId': 'message-original',
          'targetThreadId': 'thread-2',
          'idempotencyKey': 'chat-forward-retry-0004',
        },
        {'operation': 'markThreadRead', 'threadId': 'thread-1'},
      ]);
      expect(credentials.modes, [
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
      ]);
    },
  );

  test(
    'production Chat loads only gateway-owned threads and messages',
    () async {
      final gateway = _ChatGateway();
      final session = ChatSession.production(gateway: gateway);
      addTearDown(session.dispose);

      expect(session.visibleThreads(), isEmpty);
      expect(await session.loadThreads(), isTrue);
      expect(session.visibleThreads().single.id, 'thread-1');
      expect(await session.loadMessages('thread-1'), isTrue);
      expect(session.messages('thread-1').single.text, 'Server-owned message');
    },
  );

  test(
    'production Chat preserves the retry identity after a failed send',
    () async {
      final gateway = _ChatGateway(failFirstSend: true);
      final session = ChatSession.production(gateway: gateway);
      addTearDown(session.dispose);
      await session.loadThreads();

      expect(await session.send('thread-1', 'Retry safely'), isFalse);
      final failed = session.messages('thread-1').single;
      expect(failed.deliveryState, ChatDeliveryState.failed);
      expect(await session.retry('thread-1', failed.id), isTrue);
      expect(gateway.sendKeys, hasLength(2));
      expect(gateway.sendKeys.first, gateway.sendKeys.last);
    },
  );

  test(
    'production Chat keeps a failed message when retry is requested while busy',
    () async {
      final pendingSend = Completer<ChatMessage>();
      final gateway = _ChatGateway(
        failFirstSend: true,
        pendingSend: pendingSend,
      );
      final session = ChatSession.production(gateway: gateway);
      addTearDown(session.dispose);

      expect(await session.send('thread-1', 'Keep this retry'), isFalse);
      final failed = session.messages('thread-1').single;

      final activeSend = session.send('thread-1', 'Already sending');
      expect(session.busy, isTrue);
      expect(await session.retry('thread-1', failed.id), isFalse);
      expect(gateway.sendKeys, hasLength(2));
      expect(
        session.messages('thread-1'),
        contains(
          predicate<ChatMessage>((message) {
            return message.id == failed.id &&
                message.deliveryState == ChatDeliveryState.failed;
          }),
        ),
      );

      pendingSend.complete(
        const ChatMessage(
          id: 'server-pending-message',
          sender: 'You',
          text: 'Already sending',
          timeLabel: 'Now',
          mine: true,
        ),
      );
      expect(await activeSend, isTrue);
      expect(gateway.sendKeys, hasLength(2));
    },
  );

  test(
    'production Chat preserves exact reply context through failed-send retry',
    () async {
      final gateway = _ChatGateway(failFirstSend: true);
      final session = ChatSession.production(gateway: gateway);
      addTearDown(session.dispose);
      await session.loadMessages('thread-1');

      expect(session.startReply('thread-1', 'message-1'), isTrue);
      expect(await session.send('thread-1', 'Reply with context'), isFalse);
      final failed = session.messages('thread-1').last;
      expect(failed.replyTo?.messageId, 'message-1');
      expect(session.replyTarget('thread-1')?.id, 'message-1');

      expect(await session.retry('thread-1', failed.id), isTrue);
      expect(gateway.sendReplyIds, ['message-1', 'message-1']);
      expect(session.messages('thread-1').last.replyTo?.messageId, 'message-1');
      expect(session.replyTarget('thread-1'), isNull);
    },
  );

  test(
    'production Chat persists authenticated reaction set and clear',
    () async {
      final gateway = _ChatGateway();
      final session = ChatSession.production(gateway: gateway);
      addTearDown(session.dispose);
      await session.loadMessages('thread-1');

      expect(await session.toggleReaction('thread-1', 'message-1'), isTrue);
      expect(session.messages('thread-1').single.reactedByMe, isTrue);
      expect(session.messages('thread-1').single.reactionCount, 1);
      expect(await session.toggleReaction('thread-1', 'message-1'), isTrue);
      expect(session.messages('thread-1').single.reactedByMe, isFalse);
      expect(session.messages('thread-1').single.reactionCount, 0);
      expect(gateway.reactionRequests, [
        ('thread-1', 'message-1', true),
        ('thread-1', 'message-1', false),
      ]);
    },
  );

  test(
    'production Chat acknowledges one thread read and clears its unread overlay',
    () async {
      final gateway = _ChatGateway();
      final session = ChatSession.production(gateway: gateway);
      addTearDown(session.dispose);
      await session.loadThreads();

      expect(session.unreadFor(thread), 2);
      expect(await session.markRead('thread-1'), isTrue);
      expect(gateway.readThreads, ['thread-1']);
      expect(session.unreadFor(thread), 0);
    },
  );

  testWidgets(
    'read outbound message keeps reply and reaction actions plus forward',
    (tester) async {
      const readMessage = ChatMessage(
        id: 'message-read',
        sender: 'You',
        text: 'This message was read.',
        timeLabel: 'Now',
        mine: true,
        deliveryState: ChatDeliveryState.read,
        readCount: 1,
      );
      final gateway = _ChatGateway(loadedMessage: readMessage);
      final session = ChatSession.production(gateway: gateway);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ChatThreadScreen(
            session: session,
            threadId: 'thread-1',
            returnRoute: '/app/social?sub=feed',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Read'), findsOneWidget);
      expect(find.byKey(const Key('chat-message-actions')), findsNothing);
      await tester.longPress(
        find.byKey(const Key('chat-message-message-read')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-message-actions')), findsOneWidget);
      expect(find.byKey(const Key('chat-reply-message-read')), findsOneWidget);
      expect(find.byKey(const Key('chat-react-message-read')), findsOneWidget);
      expect(
        find.byKey(const Key('chat-forward-message-read')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'production Chat reuses one forward key after a recoverable failure',
    () async {
      final gateway = _ChatGateway(
        failFirstForward: true,
        threads: const [thread, targetThread],
      );
      final session = ChatSession.production(gateway: gateway);
      addTearDown(session.dispose);
      await session.loadThreads();
      await session.loadMessages('thread-1');
      await session.loadMessages('thread-2');

      expect(session.availableForwardTargets('thread-1'), [targetThread]);
      expect(
        await session.forwardMessage('thread-1', 'message-1', 'thread-2'),
        isFalse,
      );
      expect(
        await session.forwardMessage('thread-1', 'message-1', 'thread-2'),
        isTrue,
      );
      expect(gateway.forwardRequests, hasLength(2));
      expect(gateway.forwardRequests[0].$4, gateway.forwardRequests[1].$4);
      expect(session.messages('thread-2').last.forwarded, isTrue);
      expect(
        session.threadActionNotice('thread-1'),
        'Message forwarded to Family updates.',
      );
    },
  );

  testWidgets('forward picker excludes source and requires confirmation', (
    tester,
  ) async {
    final gateway = _ChatGateway(threads: const [thread, targetThread]);
    final session = ChatSession.production(gateway: gateway);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadScreen(
          session: session,
          threadId: 'thread-1',
          returnRoute: '/app/social?sub=feed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-message-message-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-forward-message-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-forward-picker')), findsOneWidget);
    expect(find.byKey(const Key('chat-forward-target-thread-1')), findsNothing);
    expect(
      find.byKey(const Key('chat-forward-target-thread-2')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-forward-target-thread-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-forward-confirmation')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-forward-cancel')));
    await tester.pumpAndSettle();
    expect(gateway.forwardRequests, isEmpty);

    await tester.longPress(find.byKey(const Key('chat-message-message-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-forward-message-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-forward-target-thread-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-forward-confirm')));
    await tester.pumpAndSettle();

    expect(gateway.forwardRequests, hasLength(1));
    expect(gateway.forwardRequests.single.$1, 'thread-1');
    expect(gateway.forwardRequests.single.$2, 'message-1');
    expect(gateway.forwardRequests.single.$3, 'thread-2');
    expect(find.text('Message forwarded to Family updates.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production Chat newest thread route owns message loading', (
    tester,
  ) async {
    final oldMessages = Completer<List<ChatMessage>>();
    final gateway = _RouteChangeChatGateway(oldMessages);
    final session = ChatSession.production(gateway: gateway);
    addTearDown(session.dispose);

    Widget screen(String threadId) => MaterialApp(
      home: ChatThreadScreen(
        session: session,
        threadId: threadId,
        returnRoute: '/app/social?sub=feed',
      ),
    );

    await tester.pumpWidget(screen('thread-old'));
    await tester.pump();
    await tester.pump();
    expect(gateway.messageThreads, ['thread-old']);

    await tester.pumpWidget(screen('thread-new'));
    await tester.pump();
    await tester.pump();
    expect(gateway.messageThreads, ['thread-old', 'thread-new']);
    expect(find.text('Newest thread message'), findsOneWidget);
    expect(session.unreadFor(newThread), 0);
    expect(session.unreadFor(oldThread), 1);
    expect(gateway.readThreads, ['thread-new']);

    oldMessages.completeError(StateError('private old-thread failure'));
    await tester.pumpAndSettle();

    expect(find.text('Newest thread message'), findsOneWidget);
    expect(find.text('Late old thread message'), findsNothing);
    expect(
      find.text('Messages could not load. Check your connection and retry.'),
      findsNothing,
    );
    expect(
      session.messageLoadError('thread-old'),
      'Messages could not load. Check your connection and retry.',
    );
    expect(session.messageLoadError('thread-new'), isNull);
    expect(session.unreadFor(oldThread), 1);
    expect(gateway.readThreads, ['thread-new']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production Chat newest inbox start route owns navigation', (
    tester,
  ) async {
    final oldThreadCreation = Completer<ChatThread>();
    final gateway = _InboxRouteChangeChatGateway(oldThreadCreation);
    final session = ChatSession.production(gateway: gateway);
    addTearDown(session.dispose);
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/inbox?start=old-member',
      routes: [
        GoRoute(
          path: '/inbox',
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: const ValueKey('reused-chat-inbox-page'),
            child: ChatInboxScreen(
              key: const ValueKey('reused-chat-inbox'),
              session: session,
              initialTargetUserId: state.uri.queryParameters['start'],
              returnRoute: '/app/social?sub=feed',
            ),
          ),
        ),
        GoRoute(
          path: '/app/chat/thread/:threadId',
          builder: (context, state) => Scaffold(
            body: Text('Opened ${state.pathParameters['threadId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();
    expect(gateway.createdTargets, ['old-member']);

    router.go('/inbox?start=new-member');
    await tester.pump();
    oldThreadCreation.complete(oldThread);
    await tester.pumpAndSettle();

    expect(gateway.createdTargets, ['old-member', 'new-member']);
    expect(find.text('Opened thread-new'), findsOneWidget);
    expect(find.text('Opened thread-old'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production Chat send completion stays with its recipient', (
    tester,
  ) async {
    final pendingSend = Completer<ChatMessage>();
    final gateway = _ChatGateway(pendingSend: pendingSend);
    final session = ChatSession.production(gateway: gateway);
    addTearDown(session.dispose);

    Widget screen(String threadId) => MaterialApp(
      home: ChatThreadScreen(
        session: session,
        threadId: threadId,
        returnRoute: '/app/social?sub=feed',
      ),
    );

    await tester.pumpWidget(screen('thread-1'));
    await tester.pump();
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'Old recipient draft',
    );
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pump();
    expect(session.busy, isTrue);

    await tester.pumpWidget(screen('thread-new'));
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'New recipient draft',
    );

    pendingSend.complete(
      const ChatMessage(
        id: 'server-old-send',
        sender: 'You',
        text: 'Old recipient draft',
        timeLabel: 'Now',
        mine: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller!
          .text,
      'New recipient draft',
    );
    expect(find.text('Message delivered.'), findsNothing);

    await tester.pumpWidget(screen('thread-1'));
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Message delivered.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared Feed link opens as an unsent Chat draft', (tester) async {
    final gateway = _ChatGateway();
    final session = ChatSession.production(gateway: gateway);
    addTearDown(session.dispose);
    const postLink =
        'https://moolsocial.com/app/social?sub=feed&item=public-post-1';

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadScreen(
          session: session,
          threadId: 'thread-1',
          returnRoute: '/app/social?sub=feed&item=public-post-1',
          initialMessageDraft: postLink,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller!
          .text,
      postLink,
    );
    expect(gateway.sendKeys, isEmpty);
    expect(session.messages('thread-1'), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}

class _ChatGateway implements ChatGateway {
  _ChatGateway({
    this.failFirstSend = false,
    this.failFirstForward = false,
    this.pendingSend,
    this.loadedMessage = message,
    this.threads = const [thread],
  });

  final bool failFirstSend;
  final bool failFirstForward;
  final Completer<ChatMessage>? pendingSend;
  final ChatMessage loadedMessage;
  final List<ChatThread> threads;
  final List<String> sendKeys = [];
  final List<String?> sendReplyIds = [];
  final List<(String, String, bool)> reactionRequests = [];
  final List<(String, String, String, String)> forwardRequests = [];
  final List<String> readThreads = [];

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) async =>
      thread;

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => [loadedMessage];

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => threads;

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) async {
    sendKeys.add(idempotencyKey);
    sendReplyIds.add(replyToMessageId);
    if (failFirstSend && sendKeys.length == 1) {
      throw const ChatServiceException(
        'Message was not sent. Check your connection and retry.',
        code: 'service_unavailable',
        retryable: true,
      );
    }
    final pending = pendingSend;
    if (pending != null) return pending.future;
    return ChatMessage(
      id: 'server-message-${sendKeys.length}',
      sender: 'You',
      text: text,
      timeLabel: 'Now',
      mine: true,
      replyTo: replyToMessageId == null
          ? null
          : ChatReplyReference(
              messageId: replyToMessageId,
              sender: message.sender,
              text: message.text,
            ),
    );
  }

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) async {
    reactionRequests.add((threadId, messageId, reacted));
    return message.copyWith(
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
    forwardRequests.add((
      sourceThreadId,
      sourceMessageId,
      targetThreadId,
      idempotencyKey,
    ));
    if (failFirstForward && forwardRequests.length == 1) {
      throw const ChatServiceException(
        'Message could not be forwarded. Try again.',
        code: 'service_unavailable',
        retryable: true,
      );
    }
    return ChatMessage(
      id: 'server-forward-${forwardRequests.length}',
      sender: 'You',
      text: loadedMessage.text,
      timeLabel: 'Now',
      mine: true,
      forwarded: true,
    );
  }

  @override
  Future<void> markThreadRead({required String threadId}) async {
    readThreads.add(threadId);
  }
}

const thread = ChatThread(
  id: 'thread-1',
  title: 'Verified member',
  subtitle: '@member',
  preview: 'Server-owned message',
  timeLabel: 'Now',
  type: ChatThreadType.people,
  unreadCount: 2,
);

const targetThread = ChatThread(
  id: 'thread-2',
  title: 'Family updates',
  subtitle: '3 members',
  preview: 'Existing conversation',
  timeLabel: 'Now',
  type: ChatThreadType.people,
);

const message = ChatMessage(
  id: 'message-1',
  sender: 'Verified member',
  text: 'Server-owned message',
  timeLabel: 'Now',
  mine: false,
);

class _RouteChangeChatGateway implements ChatGateway {
  _RouteChangeChatGateway(this.oldMessages);

  final Completer<List<ChatMessage>> oldMessages;
  final List<String> messageThreads = [];
  final List<String> readThreads = [];

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) =>
      Future.value(newThread);

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) {
    messageThreads.add(threadId);
    if (threadId == 'thread-old') return oldMessages.future;
    return Future.value(const [
      ChatMessage(
        id: 'new-message',
        sender: 'New member',
        text: 'Newest thread message',
        timeLabel: 'Now',
        mine: false,
      ),
    ]);
  }

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [
    oldThread,
    newThread,
  ];

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<void> markThreadRead({required String threadId}) async {
    readThreads.add(threadId);
  }
}

class _InboxRouteChangeChatGateway implements ChatGateway {
  _InboxRouteChangeChatGateway(this.oldThreadCreation);

  final Completer<ChatThread> oldThreadCreation;
  final List<String> createdTargets = [];

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) {
    createdTargets.add(targetUserId);
    if (targetUserId == 'old-member') return oldThreadCreation.future;
    return Future.value(newThread);
  }

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => const [];

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [
    oldThread,
    newThread,
  ];

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<void> markThreadRead({required String threadId}) async {}
}

const oldThread = ChatThread(
  id: 'thread-old',
  title: 'Old member',
  subtitle: '@oldmember',
  preview: 'Old preview',
  timeLabel: 'Now',
  type: ChatThreadType.people,
  unreadCount: 1,
);

const newThread = ChatThread(
  id: 'thread-new',
  title: 'New member',
  subtitle: '@newmember',
  preview: 'New preview',
  timeLabel: 'Now',
  type: ChatThreadType.people,
  unreadCount: 1,
);

class _RecordingCredentials implements SocialContentCredentials {
  final List<SocialAppCheckTokenMode> modes = [];

  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'test-value';
  }

  @override
  Future<String> firebaseIdToken() async => 'test-value';
}

class _RecordingTransport implements SocialContentTransport {
  _RecordingTransport(this.responses);

  final List<SocialContentResponse> responses;
  final List<Map<String, Object?>> bodies = [];

  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    bodies.add(Map<String, Object?>.from(body));
    return responses.removeAt(0);
  }
}
