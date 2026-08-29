import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/chat/screens/chat_thread_screen.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/shared/social_media_picker.dart';

void main() {
  test(
    'native picker maps camera and photo permission failures truthfully',
    () async {
      const cases = <(ChatPhotoSource, String, String, String)>[
        (
          ChatPhotoSource.camera,
          'camera_access_denied',
          'camera_permission_denied',
          'Camera access was denied.',
        ),
        (
          ChatPhotoSource.camera,
          'camera_access_restricted',
          'camera_permission_restricted',
          'Camera access is restricted',
        ),
        (
          ChatPhotoSource.gallery,
          'photo_access_denied',
          'photo_permission_denied',
          'Photo access was denied.',
        ),
        (
          ChatPhotoSource.gallery,
          'photo_access_restricted',
          'photo_permission_restricted',
          'Photo access is restricted',
        ),
      ];

      for (final entry in cases) {
        final picker = NativeChatPhotoPicker(
          picker: _PermissionFailureMediaPicker(entry.$2),
        );
        await expectLater(
          picker.pick(entry.$1),
          throwsA(
            isA<ChatServiceException>()
                .having((error) => error.code, 'code', entry.$3)
                .having(
                  (error) => error.userMessage,
                  'message',
                  contains(entry.$4),
                ),
          ),
        );
      }
    },
  );

  test(
    'authenticated photo send prepares, uploads and finalizes once',
    () async {
      final transport = _RecordingTransport([
        _preparedResponse(),
        _photoMessageResponse(),
      ]);
      final upload = _RecordingPhotoUploadTransport();
      final credentials = _RecordingCredentials();
      final gateway = AuthenticatedChatGateway(
        endpoint: _chatEndpoint,
        credentials: credentials,
        transport: transport,
        photoUploadTransport: upload,
        random: Random(1),
      );

      final delivered = await gateway.sendPhoto(
        threadId: 'thread-1',
        photo: _pickedPhoto,
        caption: 'Market receipt',
        idempotencyKey: 'photo-send-0001',
        replyToMessageId: 'message-1',
      );

      expect(delivered.photo?.id, 'photo-1');
      expect(delivered.text, 'Market receipt');
      expect(upload.calls, hasLength(1));
      expect(upload.calls.single.url.host, 'storage.googleapis.com');
      expect(upload.calls.single.bytes, _photoBytes);
      expect(upload.calls.single.headers, _requiredHeaders);
      expect(transport.bodies, [
        {
          'operation': 'preparePhotoUpload',
          'threadId': 'thread-1',
          'fileName': 'receipt.png',
          'contentType': 'image/png',
          'sizeBytes': _photoBytes.length,
        },
        {
          'operation': 'sendPhotoMessage',
          'threadId': 'thread-1',
          'uploadId': 'upload-1',
          'fileName': 'receipt.png',
          'contentType': 'image/png',
          'sizeBytes': _photoBytes.length,
          'caption': 'Market receipt',
          'idempotencyKey': 'photo-send-0001',
          'replyToMessageId': 'message-1',
        },
      ]);
      expect(credentials.modes, [
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
      ]);
    },
  );

  test('finalize retry reuses one staged upload and idempotency key', () async {
    final transport = _RecordingTransport([
      _preparedResponse(),
      SocialContentResponse(
        statusCode: 503,
        body: jsonEncode({
          'ok': false,
          'error': {
            'message': 'Photo could not finish sending. Try again.',
            'code': 'service_unavailable',
            'retryable': true,
          },
        }),
      ),
      _photoMessageResponse(),
    ]);
    final upload = _RecordingPhotoUploadTransport();
    final gateway = AuthenticatedChatGateway(
      endpoint: _chatEndpoint,
      credentials: _RecordingCredentials(),
      transport: transport,
      photoUploadTransport: upload,
      random: Random(2),
    );

    await expectLater(
      gateway.sendPhoto(
        threadId: 'thread-1',
        photo: _pickedPhoto,
        caption: '',
        idempotencyKey: 'photo-retry-0001',
      ),
      throwsA(isA<ChatServiceException>()),
    );
    final delivered = await gateway.sendPhoto(
      threadId: 'thread-1',
      photo: _pickedPhoto,
      caption: '',
      idempotencyKey: 'photo-retry-0001',
    );

    expect(delivered.photo, isNotNull);
    expect(upload.calls, hasLength(1));
    expect(transport.bodies.map((body) => body['operation']), [
      'preparePhotoUpload',
      'sendPhotoMessage',
      'sendPhotoMessage',
    ]);
    expect(
      transport.bodies.skip(1).map((body) => body['idempotencyKey']),
      everyElement('photo-retry-0001'),
    );
  });

  test('upload failure retries one grant before finalize', () async {
    final transport = _RecordingTransport([
      _preparedResponse(),
      _photoMessageResponse(),
    ]);
    final upload = _RecoverablePhotoUploadTransport();
    final gateway = AuthenticatedChatGateway(
      endpoint: _chatEndpoint,
      credentials: _RecordingCredentials(),
      transport: transport,
      photoUploadTransport: upload,
      random: Random(3),
    );

    await expectLater(
      gateway.sendPhoto(
        threadId: 'thread-1',
        photo: _pickedPhoto,
        caption: 'Market receipt',
        idempotencyKey: 'photo-upload-retry-0001',
      ),
      throwsA(isA<ChatServiceException>()),
    );
    final delivered = await gateway.sendPhoto(
      threadId: 'thread-1',
      photo: _pickedPhoto,
      caption: 'Market receipt',
      idempotencyKey: 'photo-upload-retry-0001',
    );

    expect(delivered.photo, isNotNull);
    expect(upload.attempts, 2);
    expect(transport.bodies.map((body) => body['operation']), [
      'preparePhotoUpload',
      'sendPhotoMessage',
    ]);
  });

  test(
    'session retains photo, caption, reply and one key through failed send',
    () async {
      final gateway = _PhotoChatGateway(failFirstPhoto: true);
      final picker = _PhotoPicker(choices: [_pickedPhoto]);
      final session = ChatSession.production(
        gateway: gateway,
        photoPicker: picker,
      );
      addTearDown(session.dispose);
      await session.loadThreads();
      await session.loadMessages('thread-1');
      expect(session.startReply('thread-1', 'message-1'), isTrue);
      expect(
        await session.selectPhoto('thread-1', ChatPhotoSource.gallery),
        isTrue,
      );

      expect(
        await session.sendSelectedPhoto('thread-1', 'Market receipt'),
        isFalse,
      );
      expect(session.selectedPhoto('thread-1'), same(_pickedPhoto));
      expect(session.replyTarget('thread-1')?.id, 'message-1');
      expect(session.messages('thread-1'), hasLength(1));

      expect(
        await session.sendSelectedPhoto('thread-1', 'Changed caption'),
        isFalse,
      );
      expect(gateway.photoRequests, hasLength(1));
      expect(
        session.threadActionError('thread-1'),
        'This retry keeps the original caption. Remove the photo to change it.',
      );

      final retried = await session.sendSelectedPhoto(
        'thread-1',
        'Market receipt',
      );
      expect(
        retried,
        isTrue,
        reason:
            'busy=${session.busy}; error=${session.threadActionError('thread-1')}; '
            'notice=${session.threadActionNotice('thread-1')}; '
            'pending=${session.selectedPhoto('thread-1') != null}; '
            'requests=${gateway.photoRequests.length}',
      );
      expect(gateway.photoRequests, hasLength(2));
      expect(
        gateway.photoRequests.first.idempotencyKey,
        gateway.photoRequests.last.idempotencyKey,
      );
      expect(
        gateway.photoRequests.map((request) => request.replyToMessageId),
        everyElement('message-1'),
      );
      expect(
        gateway.photoRequests.map((request) => request.caption),
        everyElement('Market receipt'),
      );
      expect(session.selectedPhoto('thread-1'), isNull);
      expect(session.replyTarget('thread-1'), isNull);
      expect(session.messages('thread-1').last.photo, isNotNull);
    },
  );

  test('interrupted selection stages a photo without sending it', () async {
    final gateway = _PhotoChatGateway();
    final picker = _PhotoPicker(recovered: _pickedPhoto);
    final session = ChatSession.production(
      gateway: gateway,
      photoPicker: picker,
    );
    addTearDown(session.dispose);

    expect(await session.recoverInterruptedPhotoSelection('thread-1'), isTrue);
    expect(session.selectedPhoto('thread-1'), same(_pickedPhoto));
    expect(gateway.photoRequests, isEmpty);
  });

  test(
    'cancel is non-mutating and camera stages only after confirmation',
    () async {
      final gateway = _PhotoChatGateway();
      final picker = _PhotoPicker(choices: [null, _pickedPhoto]);
      final session = ChatSession.production(
        gateway: gateway,
        photoPicker: picker,
      );
      addTearDown(session.dispose);

      expect(
        await session.selectPhoto('thread-1', ChatPhotoSource.gallery),
        isFalse,
      );
      expect(session.selectedPhoto('thread-1'), isNull);
      expect(gateway.photoRequests, isEmpty);
      expect(
        await session.selectPhoto('thread-1', ChatPhotoSource.camera),
        isTrue,
      );
      expect(session.selectedPhoto('thread-1'), same(_pickedPhoto));
      expect(picker.sources, [ChatPhotoSource.gallery, ChatPhotoSource.camera]);
      expect(gateway.photoRequests, isEmpty);
    },
  );

  testWidgets('photo source stages, confirms, sends and renders in thread', (
    tester,
  ) async {
    final gateway = _PhotoChatGateway();
    final picker = _PhotoPicker(choices: [_pickedPhoto]);
    final session = ChatSession.production(
      gateway: gateway,
      photoPicker: picker,
    );
    addTearDown(session.dispose);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadScreen(
          session: session,
          threadId: 'thread-1',
          returnRoute: '/app/chat/inbox',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-attach')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-attachment-tray')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-gallery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-selected-photo')), findsOneWidget);
    expect(find.byKey(const Key('chat-send-photo')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'Market receipt',
    );
    final sendPhoto = find.byKey(const Key('chat-send-photo'));
    await tester.ensureVisible(sendPhoto);
    await tester.pump();
    await tester.tap(sendPhoto);
    await tester.pumpAndSettle();

    expect(
      gateway.photoRequests,
      hasLength(1),
      reason:
          'busy=${session.busy}; error=${session.threadActionError('thread-1')}; '
          'notice=${session.threadActionNotice('thread-1')}; '
          'pending=${session.selectedPhoto('thread-1') != null}',
    );
    expect(find.text('Photo delivered.'), findsOneWidget);
    expect(find.byKey(const Key('chat-selected-photo')), findsNothing);
    expect(find.byKey(const Key('chat-photo-server-photo-1')), findsOneWidget);
    expect(
      find.byKey(const Key('chat-photo-refresh-server-photo-1')),
      findsOneWidget,
    );
    await tester.longPress(
      find.byKey(const Key('chat-message-server-photo-1')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-actions')), findsOneWidget);
    expect(find.byKey(const Key('chat-reply-server-photo-1')), findsOneWidget);
    expect(find.byKey(const Key('chat-react-server-photo-1')), findsOneWidget);
    expect(find.byKey(const Key('chat-forward-server-photo-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera permission denial stays in Chat with recovery guidance', (
    tester,
  ) async {
    final session = ChatSession.production(
      gateway: _PhotoChatGateway(),
      photoPicker: NativeChatPhotoPicker(
        picker: _PermissionFailureMediaPicker('camera_access_denied'),
      ),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadScreen(
          session: session,
          threadId: 'thread-1',
          returnRoute: '/app/chat/inbox',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-composer-camera')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(
      find.text(
        'Camera access was denied. Allow camera access in device settings, then try again.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-composer-camera')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late photo completion stays with its originating thread', (
    tester,
  ) async {
    final pending = Completer<ChatMessage>();
    final gateway = _PhotoChatGateway(pendingPhoto: pending);
    final picker = _PhotoPicker(choices: [_pickedPhoto, _pickedPhoto]);
    final session = ChatSession.production(
      gateway: gateway,
      photoPicker: picker,
    );
    addTearDown(session.dispose);
    await session.loadThreads();
    await session.loadMessages('thread-1');
    await session.loadMessages('thread-2');
    expect(
      await session.selectPhoto('thread-1', ChatPhotoSource.gallery),
      isTrue,
    );
    expect(
      await session.selectPhoto('thread-2', ChatPhotoSource.camera),
      isTrue,
    );

    Widget screen(String threadId) => MaterialApp(
      home: ChatThreadScreen(
        key: const ValueKey('route-stable-chat-thread'),
        session: session,
        threadId: threadId,
        returnRoute: '/app/chat/inbox',
      ),
    );

    await tester.pumpWidget(screen('thread-1'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'Receipt for this chat',
    );
    final firstSend = find.byKey(const Key('chat-send-photo'));
    await tester.ensureVisible(firstSend);
    await tester.tap(firstSend);
    await tester.pump();
    expect(gateway.photoRequests, hasLength(1));

    await tester.pumpWidget(screen('thread-2'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'Family photo caption',
    );
    pending.complete(
      _deliveredPhotoMessage(
        photo: _pickedPhoto,
        caption: 'Receipt for this chat',
        id: 'late-thread-1-photo',
      ),
    );
    await tester.pumpAndSettle();

    expect(session.selectedPhoto('thread-1'), isNull);
    expect(session.selectedPhoto('thread-2'), same(_pickedPhoto));
    expect(session.messages('thread-1').last.id, 'late-thread-1-photo');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller!
          .text,
      'Family photo caption',
    );
    expect(find.byKey(const Key('chat-selected-photo')), findsOneWidget);
  });
}

final _chatEndpoint = Uri.parse(
  'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialChat',
);

final _photoBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
);

final _pickedPhoto = ChatPickedPhoto(
  name: 'receipt.png',
  contentType: 'image/png',
  bytes: _photoBytes,
);

final _requiredHeaders = <String, String>{
  'content-type': 'image/png',
  'content-length': '${_photoBytes.length}',
  'x-goog-if-generation-match': '0',
  'x-goog-meta-moolsocial-schema': 'chat-photo-v1',
  'x-goog-meta-moolsocial-owner': 'owner-binding',
  'x-goog-meta-moolsocial-thread': 'thread-binding',
  'x-goog-meta-moolsocial-name': 'name-binding',
  'x-goog-meta-moolsocial-size': '${_photoBytes.length}',
};

SocialContentResponse _preparedResponse() => SocialContentResponse(
  statusCode: 200,
  body: jsonEncode({
    'ok': true,
    'data': {
      'uploadId': 'upload-1',
      'uploadUrl':
          'https://storage.googleapis.com/moolsocial-private/chat-private/v1/00000000-0000-4000-8000-000000000001?X-Goog-Signature=test',
      'expiresAt': '2026-08-15T03:30:00.000Z',
      'requiredHeaders': _requiredHeaders,
    },
  }),
);

SocialContentResponse _photoMessageResponse() => SocialContentResponse(
  statusCode: 200,
  body: jsonEncode({
    'ok': true,
    'data': {
      'id': 'server-photo-1',
      'senderName': 'You',
      'text': 'Market receipt',
      'createdAt': '2026-08-15T03:28:00.000Z',
      'mine': true,
      'reactionCount': 0,
      'reactedByMe': false,
      'photo': {
        'id': 'photo-1',
        'name': 'receipt.png',
        'contentType': 'image/png',
        'sizeBytes': _photoBytes.length,
        'readUrl':
            'https://storage.googleapis.com/moolsocial-private/chat-private/v1/00000000-0000-4000-8000-000000000001?X-Goog-Signature=read',
        'readUrlExpiresAt': '2026-08-15T03:35:00.000Z',
      },
    },
  }),
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

class _PhotoUploadCall {
  const _PhotoUploadCall({
    required this.url,
    required this.headers,
    required this.bytes,
  });

  final Uri url;
  final Map<String, String> headers;
  final Uint8List bytes;
}

class _RecordingPhotoUploadTransport implements ChatPhotoUploadTransport {
  final List<_PhotoUploadCall> calls = [];

  @override
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  }) async {
    calls.add(_PhotoUploadCall(url: url, headers: headers, bytes: bytes));
  }
}

class _RecoverablePhotoUploadTransport implements ChatPhotoUploadTransport {
  int attempts = 0;

  @override
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  }) async {
    attempts += 1;
    if (attempts == 1) {
      throw const ChatServiceException(
        'Photo could not upload. Check your connection and try again.',
        code: 'photo_upload_failed',
        retryable: true,
      );
    }
  }
}

class _PhotoPicker implements ChatPhotoPicker {
  _PhotoPicker({List<ChatPickedPhoto?>? choices, this.recovered})
    : choices = choices ?? [];

  final List<ChatPickedPhoto?> choices;
  final ChatPickedPhoto? recovered;
  final List<ChatPhotoSource> sources = [];

  @override
  Future<ChatPickedPhoto?> pick(ChatPhotoSource source) async {
    sources.add(source);
    return choices.isEmpty ? null : choices.removeAt(0);
  }

  @override
  Future<ChatPickedPhoto?> recoverInterruptedSelection() async => recovered;
}

class _PhotoRequest {
  const _PhotoRequest({
    required this.threadId,
    required this.photo,
    required this.caption,
    required this.idempotencyKey,
    required this.replyToMessageId,
  });

  final String threadId;
  final ChatPickedPhoto photo;
  final String caption;
  final String idempotencyKey;
  final String? replyToMessageId;
}

class _PermissionFailureMediaPicker implements SocialMediaPicker {
  const _PermissionFailureMediaPicker(this.code);

  final String code;

  @override
  Future<SocialPickedMedia?> pickImage(SocialMediaSource source) =>
      Future.error(PlatformException(code: code));

  @override
  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10}) =>
      Future.error(UnsupportedError('Carousel is outside this Chat test.'));

  @override
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source) =>
      Future.error(UnsupportedError('Video is outside this Chat test.'));

  @override
  Future<List<SocialPickedMedia>> recoverInterruptedSelection() async =>
      const [];
}

class _PhotoChatGateway implements ChatGateway, ChatPhotoGateway {
  _PhotoChatGateway({this.failFirstPhoto = false, this.pendingPhoto});

  final bool failFirstPhoto;
  final Completer<ChatMessage>? pendingPhoto;
  final List<_PhotoRequest> photoRequests = [];
  final List<(String, String, String, String)> forwardRequests = [];

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [
    _thread,
    _targetThread,
  ];

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => threadId == _thread.id ? const [_message] : const [];

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) async =>
      _thread;

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessage> sendPhoto({
    required String threadId,
    required ChatPickedPhoto photo,
    required String caption,
    required String idempotencyKey,
    String? replyToMessageId,
  }) async {
    photoRequests.add(
      _PhotoRequest(
        threadId: threadId,
        photo: photo,
        caption: caption,
        idempotencyKey: idempotencyKey,
        replyToMessageId: replyToMessageId,
      ),
    );
    if (failFirstPhoto && photoRequests.length == 1) {
      throw const ChatServiceException(
        'Photo could not finish sending. Try again.',
        code: 'service_unavailable',
        retryable: true,
      );
    }
    final pending = pendingPhoto;
    if (pending != null) return pending.future;
    return _deliveredPhotoMessage(
      photo: photo,
      caption: caption,
      id: 'server-photo-1',
      replyToMessageId: replyToMessageId,
    );
  }

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) async =>
      _message.copyWith(reactedByMe: reacted, reactionCount: reacted ? 1 : 0);

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
    return _message;
  }

  @override
  Future<void> markThreadRead({required String threadId}) async {}
}

const _thread = ChatThread(
  id: 'thread-1',
  title: 'Verified member',
  subtitle: '@member',
  preview: 'Server-owned message',
  timeLabel: 'Now',
  type: ChatThreadType.people,
);

const _targetThread = ChatThread(
  id: 'thread-2',
  title: 'Family updates',
  subtitle: '3 members',
  preview: 'Existing conversation',
  timeLabel: 'Now',
  type: ChatThreadType.people,
);

const _message = ChatMessage(
  id: 'message-1',
  sender: 'Verified member',
  text: 'Server-owned message',
  timeLabel: 'Now',
  mine: false,
);

ChatMessage _deliveredPhotoMessage({
  required ChatPickedPhoto photo,
  required String caption,
  required String id,
  String? replyToMessageId,
}) {
  return ChatMessage(
    id: id,
    sender: 'You',
    text: caption,
    timeLabel: 'Now',
    mine: true,
    replyTo: replyToMessageId == null
        ? null
        : const ChatReplyReference(
            messageId: 'message-1',
            sender: 'Verified member',
            text: 'Server-owned message',
          ),
    photo: ChatPhotoAttachment(
      id: 'photo-1',
      name: photo.name,
      contentType: photo.contentType,
      sizeBytes: photo.bytes.length,
      readUrl: Uri.parse(
        'https://storage.googleapis.com/moolsocial-private/chat-private/v1/00000000-0000-4000-8000-000000000001?X-Goog-Signature=read',
      ),
      readUrlExpiresAt: DateTime.parse('2026-08-15T03:35:00.000Z'),
    ),
  );
}
