import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../shared/social_media_picker.dart';
import '../shared/social_content_gateway.dart';
import 'chat_models.dart';

const moolSocialChatUrl = String.fromEnvironment('MOOLSOCIAL_CHAT_URL');
const chatPhotoMaximumBytes = 4 * 1024 * 1024;

enum ChatPhotoSource { camera, gallery }

class ChatPickedPhoto {
  const ChatPickedPhoto({
    required this.name,
    required this.contentType,
    required this.bytes,
  });

  final String name;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class ChatPhotoPicker {
  Future<ChatPickedPhoto?> pick(ChatPhotoSource source);

  Future<ChatPickedPhoto?> recoverInterruptedSelection();
}

class NativeChatPhotoPicker implements ChatPhotoPicker {
  NativeChatPhotoPicker({SocialMediaPicker? picker})
    : _picker = picker ?? NativeSocialMediaPicker();

  final SocialMediaPicker _picker;

  @override
  Future<ChatPickedPhoto?> pick(ChatPhotoSource source) async {
    try {
      final selected = await _picker.pickImage(
        source == ChatPhotoSource.camera
            ? SocialMediaSource.camera
            : SocialMediaSource.gallery,
      );
      return selected == null ? null : _load(selected);
    } on PlatformException catch (error) {
      throw switch (error.code) {
        'camera_access_denied' => const ChatServiceException(
          'Camera access was denied. Allow camera access in device settings, then try again.',
          code: 'camera_permission_denied',
        ),
        'camera_access_restricted' => const ChatServiceException(
          'Camera access is restricted on this device. You can choose a photo instead.',
          code: 'camera_permission_restricted',
        ),
        'photo_access_denied' => const ChatServiceException(
          'Photo access was denied. Allow photo access in device settings, then try again.',
          code: 'photo_permission_denied',
        ),
        'photo_access_restricted' => const ChatServiceException(
          'Photo access is restricted on this device. You can take a new photo or continue with a message.',
          code: 'photo_permission_restricted',
        ),
        _ => error,
      };
    }
  }

  @override
  Future<ChatPickedPhoto?> recoverInterruptedSelection() async {
    final recovered = await _picker.recoverInterruptedSelection();
    final selected = recovered
        .where((item) => item.kind == SocialMediaKind.image)
        .firstOrNull;
    return selected == null ? null : _load(selected);
  }

  Future<ChatPickedPhoto> _load(SocialPickedMedia selected) async {
    try {
      final bytes = await File(selected.path).readAsBytes();
      final contentType = _photoContentType(bytes);
      if (contentType == null ||
          bytes.isEmpty ||
          bytes.length > chatPhotoMaximumBytes) {
        throw const ChatServiceException(
          'Choose a JPEG, PNG or WebP photo up to 4 MB.',
          code: 'invalid_photo',
        );
      }
      return ChatPickedPhoto(
        name: _safePhotoName(selected.name, contentType),
        contentType: contentType,
        bytes: bytes,
      );
    } on ChatServiceException {
      rethrow;
    } on Object {
      throw const ChatServiceException(
        'That photo could not be opened. Choose it again.',
        code: 'photo_unavailable',
        retryable: true,
      );
    }
  }
}

class ChatServiceException implements Exception {
  const ChatServiceException(
    this.userMessage, {
    this.code = 'chat_unavailable',
    this.retryable = false,
  });

  final String userMessage;
  final String code;
  final bool retryable;
}

abstract interface class ChatSendGateway {
  Future<void> send({
    required String threadId,
    required String text,
    String? attachmentLabel,
  });
}

abstract interface class ChatGateway {
  Future<List<ChatThread>> listThreads({int limit = 30});

  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  });

  Future<ChatThread> createDirectThread({required String targetUserId});

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  });

  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  });

  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  });

  Future<void> markThreadRead({required String threadId});
}

abstract interface class ChatPhotoGateway {
  Future<ChatMessage> sendPhoto({
    required String threadId,
    required ChatPickedPhoto photo,
    required String caption,
    required String idempotencyKey,
    String? replyToMessageId,
  });
}

abstract interface class ChatPhotoUploadTransport {
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  });
}

class IoChatPhotoUploadTransport implements ChatPhotoUploadTransport {
  IoChatPhotoUploadTransport({HttpClient? client})
    : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  }) async {
    _requirePrivateStorageUrl(url);
    if (headers['content-length'] != '${bytes.length}') {
      throw const ChatServiceException(
        'Photo upload could not be prepared. Choose the photo again.',
        code: 'invalid_photo_upload',
      );
    }
    try {
      final request = await _client
          .putUrl(url)
          .timeout(const Duration(seconds: 15));
      request.contentLength = bytes.length;
      for (final entry in headers.entries) {
        if (entry.key == 'content-length') continue;
        request.headers.set(entry.key, entry.value);
      }
      request.add(bytes);
      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      await response.drain<void>();
      if ((response.statusCode >= 200 && response.statusCode < 300) ||
          response.statusCode == HttpStatus.preconditionFailed) {
        return;
      }
      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        throw const ChatServiceException(
          'Photo upload expired. Try sending the photo again.',
          code: 'photo_upload_expired',
          retryable: true,
        );
      }
      throw ChatServiceException(
        'Photo could not upload. Check your connection and try again.',
        code: 'photo_upload_failed',
        retryable:
            response.statusCode == HttpStatus.requestTimeout ||
            response.statusCode == HttpStatus.tooManyRequests ||
            response.statusCode >= 500,
      );
    } on ChatServiceException {
      rethrow;
    } on TimeoutException {
      throw const ChatServiceException(
        'Photo upload timed out. Check your connection and try again.',
        code: 'photo_upload_timeout',
        retryable: true,
      );
    } on SocketException {
      throw const ChatServiceException(
        'Photo could not upload. Check your connection and try again.',
        code: 'photo_upload_failed',
        retryable: true,
      );
    } on Object {
      throw const ChatServiceException(
        'Photo could not upload. Try again.',
        code: 'photo_upload_failed',
        retryable: true,
      );
    }
  }
}

ChatGateway buildChatGateway() {
  if (moolSocialChatUrl.trim().isEmpty) {
    return const UnavailableChatGateway();
  }
  return AuthenticatedChatGateway(
    endpoint: Uri.parse(moolSocialChatUrl),
    credentials: FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
  );
}

class UnavailableChatGateway implements ChatGateway {
  const UnavailableChatGateway();

  ChatServiceException get _error => const ChatServiceException(
    'Chat is unavailable right now. Try again later.',
    code: 'service_unavailable',
    retryable: true,
  );

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) async =>
      throw _error;

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => throw _error;

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => throw _error;

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) async => throw _error;

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) async => throw _error;

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) async => throw _error;

  @override
  Future<void> markThreadRead({required String threadId}) async => throw _error;
}

class AuthenticatedChatGateway implements ChatGateway, ChatPhotoGateway {
  AuthenticatedChatGateway({
    required Uri endpoint,
    required this.credentials,
    required this.transport,
    ChatPhotoUploadTransport? photoUploadTransport,
    Random? random,
  }) : endpoint = _validateChatEndpoint(endpoint),
       photoUploadTransport =
           photoUploadTransport ?? IoChatPhotoUploadTransport(),
       random = random ?? Random.secure();

  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  final ChatPhotoUploadTransport photoUploadTransport;
  final Random random;
  final Map<String, _ChatPhotoUploadState> _photoUploads = {};

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async {
    final data = _list(await _invoke('listThreads', body: {'limit': limit}));
    return data
        .map((item) => _decodeThread(_map(item)))
        .toList(growable: false);
  }

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async {
    final data = _list(
      await _invoke(
        'listMessages',
        body: {'threadId': threadId, 'limit': limit},
      ),
    );
    return data
        .map((item) => _decodeMessage(_map(item)))
        .toList(growable: false);
  }

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) async {
    return _decodeThread(
      _map(
        await _invoke(
          'createDirectThread',
          limitedUseAppCheck: true,
          body: {'targetUserId': targetUserId},
        ),
      ),
    );
  }

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) async {
    return _decodeMessage(
      _map(
        await _invoke(
          'sendMessage',
          limitedUseAppCheck: true,
          body: {
            'threadId': threadId,
            'text': text,
            'idempotencyKey': idempotencyKey,
            'replyToMessageId': ?replyToMessageId,
          },
        ),
      ),
    );
  }

  @override
  Future<ChatMessage> sendPhoto({
    required String threadId,
    required ChatPickedPhoto photo,
    required String caption,
    required String idempotencyKey,
    String? replyToMessageId,
  }) async {
    final fingerprint = sha256.convert(photo.bytes).toString();
    var state = _photoUploads[idempotencyKey];
    if (state != null && state.fingerprint != fingerprint) {
      throw const ChatServiceException(
        'Choose the photo again before retrying.',
        code: 'photo_retry_conflict',
      );
    }
    if (state == null) {
      final prepared = _decodePhotoUploadGrant(
        _map(
          await _invoke(
            'preparePhotoUpload',
            limitedUseAppCheck: true,
            body: {
              'threadId': threadId,
              'fileName': photo.name,
              'contentType': photo.contentType,
              'sizeBytes': photo.bytes.length,
            },
          ),
        ),
        photo,
      );
      state = _ChatPhotoUploadState(fingerprint: fingerprint, grant: prepared);
      _photoUploads[idempotencyKey] = state;
    }
    if (!state.uploaded) {
      try {
        await photoUploadTransport.put(
          url: state.grant.uploadUrl,
          headers: state.grant.requiredHeaders,
          bytes: photo.bytes,
        );
        state.uploaded = true;
      } on ChatServiceException catch (error) {
        if (error.code == 'photo_upload_expired') {
          _photoUploads.remove(idempotencyKey);
        }
        rethrow;
      }
    }
    final delivered = _decodeMessage(
      _map(
        await _invoke(
          'sendPhotoMessage',
          limitedUseAppCheck: true,
          body: {
            'threadId': threadId,
            'uploadId': state.grant.uploadId,
            'fileName': photo.name,
            'contentType': photo.contentType,
            'sizeBytes': photo.bytes.length,
            if (caption.trim().isNotEmpty) 'caption': caption.trim(),
            'idempotencyKey': idempotencyKey,
            'replyToMessageId': ?replyToMessageId,
          },
        ),
      ),
    );
    _photoUploads.remove(idempotencyKey);
    return delivered;
  }

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) async {
    return _decodeMessage(
      _map(
        await _invoke(
          'setReaction',
          limitedUseAppCheck: true,
          body: {
            'threadId': threadId,
            'messageId': messageId,
            'reacted': reacted,
          },
        ),
      ),
    );
  }

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) async {
    return _decodeMessage(
      _map(
        await _invoke(
          'forwardMessage',
          limitedUseAppCheck: true,
          body: {
            'sourceThreadId': sourceThreadId,
            'sourceMessageId': sourceMessageId,
            'targetThreadId': targetThreadId,
            'idempotencyKey': idempotencyKey,
          },
        ),
      ),
    );
  }

  @override
  Future<void> markThreadRead({required String threadId}) async {
    await _invoke(
      'markThreadRead',
      limitedUseAppCheck: true,
      body: {'threadId': threadId},
    );
  }

  Future<Object?> _invoke(
    String operation, {
    required Map<String, Object?> body,
    bool limitedUseAppCheck = false,
  }) async {
    final idToken = await credentials.firebaseIdToken();
    final appCheckToken = await credentials.appCheckToken(
      limitedUseAppCheck
          ? SocialAppCheckTokenMode.limitedUse
          : SocialAppCheckTokenMode.standard,
    );
    final response = await transport.postJson(
      endpoint,
      headers: {
        'accept': 'application/json',
        'authorization': 'Bearer $idToken',
        'x-firebase-appcheck': appCheckToken,
        'x-request-id': _requestId(),
      },
      body: {'operation': operation, ...body},
    );
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ChatServiceException(
        'Chat returned an invalid response. Try again.',
        code: 'invalid_response',
        retryable: true,
      );
    }
    final envelope = _map(decoded);
    if (envelope['ok'] == true) return envelope['data'];
    final error = _map(envelope['error']);
    throw ChatServiceException(
      _requiredString(error['message']),
      code: _requiredString(error['code']),
      retryable: error['retryable'] == true,
    );
  }

  String _requestId() {
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}

class ReviewChatSendGateway implements ChatSendGateway {
  ReviewChatSendGateway({
    this.failNextRequest = false,
    this.latency = const Duration(milliseconds: 100),
  });

  bool failNextRequest;
  final Duration latency;

  @override
  Future<void> send({
    required String threadId,
    required String text,
    String? attachmentLabel,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (failNextRequest) {
      failNextRequest = false;
      throw const ChatServiceException(
        'Message was not sent. Check your connection and retry.',
      );
    }
  }
}

Uri _validateChatEndpoint(Uri endpoint) {
  if (endpoint.scheme != 'https' ||
      endpoint.host != 'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
      endpoint.path != '/moolSocialChat' ||
      endpoint.hasQuery ||
      endpoint.hasFragment) {
    throw ArgumentError('Chat service configuration is unavailable.');
  }
  return endpoint;
}

ChatThread _decodeThread(Map<String, Object?> data) {
  return ChatThread(
    id: _requiredString(data['id']),
    title: _requiredString(data['title']),
    subtitle: _requiredString(data['subtitle']),
    preview: _requiredString(data['preview']),
    timeLabel: _timeLabel(_requiredString(data['updatedAt'])),
    type: switch (_requiredString(data['type'])) {
      'business' => ChatThreadType.business,
      'order' => ChatThreadType.order,
      'support' => ChatThreadType.support,
      _ => ChatThreadType.people,
    },
    unreadCount: _integer(data['unreadCount']),
    verified: data['verified'] == true,
  );
}

ChatMessage _decodeMessage(Map<String, Object?> data) {
  final mine = data['mine'] == true;
  final photo = _decodePhoto(data['photo']);
  final rawText = data['text'];
  if (rawText is! String || (rawText.trim().isEmpty && photo == null)) {
    throw const ChatServiceException(
      'Chat returned an invalid response. Try again.',
      code: 'invalid_response',
      retryable: true,
    );
  }
  return ChatMessage(
    id: _requiredString(data['id']),
    sender: _requiredString(data['senderName']),
    text: rawText.trim(),
    timeLabel: _timeLabel(_requiredString(data['createdAt'])),
    mine: mine,
    deliveryState: mine && data['readByOthers'] == true
        ? ChatDeliveryState.read
        : ChatDeliveryState.delivered,
    reactionCount: _integer(data['reactionCount']),
    reactedByMe: data['reactedByMe'] == true,
    replyTo: _decodeReply(data['replyTo']),
    readCount: _integer(data['readCount']),
    forwarded: data['forwarded'] == true,
    photo: photo,
  );
}

ChatPhotoAttachment? _decodePhoto(Object? value) {
  if (value == null) return null;
  final data = _map(value);
  final contentType = _requiredString(data['contentType']);
  final sizeBytes = _integer(data['sizeBytes']);
  final readUrl = Uri.tryParse(_requiredString(data['readUrl']));
  final readUrlExpiresAt = DateTime.tryParse(
    _requiredString(data['readUrlExpiresAt']),
  );
  if ((contentType != 'image/jpeg' &&
          contentType != 'image/png' &&
          contentType != 'image/webp') ||
      sizeBytes < 1 ||
      sizeBytes > chatPhotoMaximumBytes ||
      readUrl == null ||
      readUrlExpiresAt == null) {
    throw const ChatServiceException(
      'Chat returned an invalid photo. Try again.',
      code: 'invalid_response',
      retryable: true,
    );
  }
  _requirePrivateStorageUrl(readUrl);
  return ChatPhotoAttachment(
    id: _requiredString(data['id']),
    name: _requiredString(data['name']),
    contentType: contentType,
    sizeBytes: sizeBytes,
    readUrl: readUrl,
    readUrlExpiresAt: readUrlExpiresAt,
  );
}

_ChatPhotoUploadGrant _decodePhotoUploadGrant(
  Map<String, Object?> data,
  ChatPickedPhoto photo,
) {
  final uploadUrl = Uri.tryParse(_requiredString(data['uploadUrl']));
  final expiresAt = DateTime.tryParse(_requiredString(data['expiresAt']));
  final requiredHeaders = _stringMap(data['requiredHeaders']);
  if (uploadUrl == null || expiresAt == null) {
    throw const ChatServiceException(
      'Photo upload could not be prepared. Choose the photo again.',
      code: 'invalid_response',
    );
  }
  _requirePrivateStorageUrl(uploadUrl);
  const requiredNames = {
    'content-type',
    'content-length',
    'x-goog-if-generation-match',
    'x-goog-meta-moolsocial-schema',
    'x-goog-meta-moolsocial-owner',
    'x-goog-meta-moolsocial-thread',
    'x-goog-meta-moolsocial-name',
    'x-goog-meta-moolsocial-size',
  };
  if (requiredHeaders.keys.toSet().difference(requiredNames).isNotEmpty ||
      !requiredHeaders.keys.toSet().containsAll(requiredNames) ||
      requiredHeaders['content-type'] != photo.contentType ||
      requiredHeaders['content-length'] != '${photo.bytes.length}' ||
      requiredHeaders['x-goog-if-generation-match'] != '0') {
    throw const ChatServiceException(
      'Photo upload could not be prepared. Choose the photo again.',
      code: 'invalid_response',
    );
  }
  return _ChatPhotoUploadGrant(
    uploadId: _requiredString(data['uploadId']),
    uploadUrl: uploadUrl,
    expiresAt: expiresAt,
    requiredHeaders: requiredHeaders,
  );
}

ChatReplyReference? _decodeReply(Object? value) {
  if (value == null) return null;
  final data = _map(value);
  return ChatReplyReference(
    messageId: _requiredString(data['messageId']),
    sender: _requiredString(data['senderName']),
    text: _requiredString(data['text']),
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const ChatServiceException(
      'Chat returned an invalid response. Try again.',
      code: 'invalid_response',
      retryable: true,
    );
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Object?> _list(Object? value) {
  if (value is! List) {
    throw const ChatServiceException(
      'Chat returned an invalid response. Try again.',
      code: 'invalid_response',
      retryable: true,
    );
  }
  return value.cast<Object?>();
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const ChatServiceException(
      'Chat returned an invalid response. Try again.',
      code: 'invalid_response',
      retryable: true,
    );
  }
  return value.trim();
}

int _integer(Object? value) => value is int ? value : 0;

Map<String, String> _stringMap(Object? value) {
  if (value is! Map ||
      value.length > 12 ||
      value.entries.any(
        (entry) =>
            entry.key is! String ||
            entry.value is! String ||
            entry.key != entry.key.toString().toLowerCase(),
      )) {
    throw const ChatServiceException(
      'Chat returned an invalid response. Try again.',
      code: 'invalid_response',
      retryable: true,
    );
  }
  return value.map((key, item) => MapEntry(key.toString(), item.toString()));
}

void _requirePrivateStorageUrl(Uri value) {
  final host = value.host.toLowerCase();
  if (value.scheme != 'https' ||
      value.userInfo.isNotEmpty ||
      (host != 'storage.googleapis.com' &&
          !host.endsWith('.storage.googleapis.com'))) {
    throw const ChatServiceException(
      'Photo service configuration is unavailable.',
      code: 'invalid_response',
    );
  }
}

String? _photoContentType(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (bytes.length >= png.length &&
      List<int>.generate(png.length, (index) => bytes[index]).join(',') ==
          png.join(',')) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

String _safePhotoName(String value, String contentType) {
  final clean = value.replaceAll(RegExp(r'[\\/\x00-\x1f\x7f]'), '_').trim();
  final fallback = switch (contentType) {
    'image/png' => 'photo.png',
    'image/webp' => 'photo.webp',
    _ => 'photo.jpg',
  };
  if (clean.isEmpty) return fallback;
  return clean.length <= 120 ? clean : clean.substring(clean.length - 120);
}

class _ChatPhotoUploadGrant {
  const _ChatPhotoUploadGrant({
    required this.uploadId,
    required this.uploadUrl,
    required this.expiresAt,
    required this.requiredHeaders,
  });

  final String uploadId;
  final Uri uploadUrl;
  final DateTime expiresAt;
  final Map<String, String> requiredHeaders;
}

class _ChatPhotoUploadState {
  _ChatPhotoUploadState({required this.fingerprint, required this.grant});

  final String fingerprint;
  final _ChatPhotoUploadGrant grant;
  bool uploaded = false;
}

String _timeLabel(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return '';
  final now = DateTime.now();
  if (parsed.year == now.year &&
      parsed.month == now.month &&
      parsed.day == now.day) {
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  return '${parsed.day}/${parsed.month}';
}
