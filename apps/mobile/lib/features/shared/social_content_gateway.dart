import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'shared_models.dart';

const moolSocialContentUrl = String.fromEnvironment(
  'MOOLSOCIAL_SOCIAL_CONTENT_URL',
);

class SocialContentGatewayException implements Exception {
  const SocialContentGatewayException({
    required this.code,
    required this.message,
    this.retryable = false,
    this.statusCode,
  });

  final String code;
  final String message;
  final bool retryable;
  final int? statusCode;

  @override
  String toString() => message;
}

class SocialPublishDraft {
  const SocialPublishDraft({
    required this.idempotencyKey,
    required this.type,
    required this.authorName,
    required this.authorHandle,
    required this.body,
    required this.audience,
    required this.mediaPaths,
    required this.mediaAreAssets,
    required this.choices,
    this.correctChoiceIndex,
    this.quotedPostId,
  });

  final String idempotencyKey;
  final SocialPublishedContentType type;
  final String authorName;
  final String authorHandle;
  final String body;
  final String audience;
  final List<String> mediaPaths;
  final bool mediaAreAssets;
  final List<SocialPublishedChoice> choices;
  final int? correctChoiceIndex;
  final String? quotedPostId;
}

class SocialFeedPage {
  const SocialFeedPage({required this.items, this.nextCursor});

  final List<SocialPublishedItem> items;
  final String? nextCursor;
}

class SocialCommentPage {
  const SocialCommentPage({required this.items, this.nextCursor});

  final List<SocialComment> items;
  final String? nextCursor;
}

class SocialReplyDraft {
  const SocialReplyDraft({
    required this.postId,
    required this.idempotencyKey,
    required this.body,
  });

  final String postId;
  final String idempotencyKey;
  final String body;
}

class SocialReplyResult {
  const SocialReplyResult({required this.comment, required this.post});

  final SocialComment comment;
  final SocialPublishedItem post;
}

enum SocialNotificationKind { reply, reaction, follow, messageRequest }

class SocialNotificationItem {
  const SocialNotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.preview,
    required this.publishedAt,
    required this.read,
    this.postId,
    this.authorId,
  });

  final String id;
  final SocialNotificationKind kind;
  final String title;
  final String preview;
  final DateTime publishedAt;
  final bool read;
  final String? postId;
  final String? authorId;

  SocialNotificationItem copyWith({bool? read}) => SocialNotificationItem(
    id: id,
    kind: kind,
    title: title,
    preview: preview,
    publishedAt: publishedAt,
    read: read ?? this.read,
    postId: postId,
    authorId: authorId,
  );
}

class SocialNotificationPage {
  const SocialNotificationPage({required this.items, this.nextCursor});

  final List<SocialNotificationItem> items;
  final String? nextCursor;
}

enum SocialReportReason {
  spam,
  harassment,
  falseInformation,
  harmfulOrIllegal,
  other,
}

extension SocialReportReasonCopy on SocialReportReason {
  String get label => switch (this) {
    SocialReportReason.spam => 'Spam or misleading promotion',
    SocialReportReason.harassment => 'Harassment or abuse',
    SocialReportReason.falseInformation => 'False or deceptive information',
    SocialReportReason.harmfulOrIllegal => 'Harmful or illegal content',
    SocialReportReason.other => 'Something else',
  };
}

abstract interface class SocialContentGateway {
  Future<SocialPublishedItem> publish(SocialPublishDraft draft);

  Future<SocialFeedPage> feed({String? cursor, int limit = 20});

  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  });
}

abstract interface class SocialCommentGateway {
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 30,
  });

  Future<SocialReplyResult> reply(SocialReplyDraft draft);
}

abstract interface class SocialAuthorGateway {
  Future<SocialAuthorProfile> author({
    required String authorId,
    bool authenticated = false,
    int limit = 12,
  });

  Future<SocialAuthorProfile> follow({
    required String authorId,
    required bool followed,
  });
}

abstract interface class SocialModerationGateway {
  Future<void> reportPost({
    required String postId,
    required SocialReportReason reason,
    required String idempotencyKey,
  });

  Future<bool> setAuthorBlocked({
    required String authorId,
    required bool blocked,
  });
}

abstract interface class SocialSavedGateway {
  Future<SocialFeedPage> saved({String? cursor, int limit = 20});
}

abstract interface class SocialNotificationGateway {
  Future<SocialNotificationPage> notifications({
    String? cursor,
    int limit = 30,
  });

  Future<void> markNotificationRead(String notificationId);
}

SocialContentGateway buildSocialContentGateway() {
  if (moolSocialContentUrl.trim().isEmpty) {
    return const UnavailableSocialContentGateway();
  }
  return AuthenticatedSocialContentGateway(
    endpoint: Uri.parse(moolSocialContentUrl),
    credentials: FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
  );
}

class UnavailableSocialContentGateway
    implements
        SocialContentGateway,
        SocialCommentGateway,
        SocialAuthorGateway,
        SocialModerationGateway,
        SocialSavedGateway,
        SocialNotificationGateway {
  const UnavailableSocialContentGateway();

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) =>
      Future<SocialFeedPage>.error(_unavailable());

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => Future<SocialPublishedItem>.error(_unavailable());

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      Future<SocialPublishedItem>.error(_unavailable());

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 30,
  }) => Future<SocialCommentPage>.error(_unavailable());

  @override
  Future<SocialReplyResult> reply(SocialReplyDraft draft) =>
      Future<SocialReplyResult>.error(_unavailable());

  @override
  Future<SocialAuthorProfile> author({
    required String authorId,
    bool authenticated = false,
    int limit = 12,
  }) => Future<SocialAuthorProfile>.error(_unavailable());

  @override
  Future<SocialAuthorProfile> follow({
    required String authorId,
    required bool followed,
  }) => Future<SocialAuthorProfile>.error(_unavailable());

  @override
  Future<void> reportPost({
    required String postId,
    required SocialReportReason reason,
    required String idempotencyKey,
  }) => Future<void>.error(_unavailable());

  @override
  Future<bool> setAuthorBlocked({
    required String authorId,
    required bool blocked,
  }) => Future<bool>.error(_unavailable());

  @override
  Future<SocialFeedPage> saved({String? cursor, int limit = 20}) =>
      Future<SocialFeedPage>.error(_unavailable());

  @override
  Future<SocialNotificationPage> notifications({
    String? cursor,
    int limit = 30,
  }) => Future<SocialNotificationPage>.error(_unavailable());

  @override
  Future<void> markNotificationRead(String notificationId) =>
      Future<void>.error(_unavailable());

  static SocialContentGatewayException _unavailable() =>
      const SocialContentGatewayException(
        code: 'service_unavailable',
        message:
            'MoolSocial posting is unavailable right now. Try again later.',
        retryable: true,
      );
}

/// Deterministic, non-promotable content for the UI-review package only.
///
/// It implements the same frontend contract as the authenticated service so
/// Feed layout and navigation can be reviewed on a device without inventing a
/// backend success. Every write still fails closed.
class UiReviewSocialContentGateway
    implements
        SocialContentGateway,
        SocialCommentGateway,
        SocialAuthorGateway,
        SocialModerationGateway,
        SocialSavedGateway,
        SocialNotificationGateway {
  UiReviewSocialContentGateway({DateTime Function()? now})
    : _now = now ?? DateTime.now {
    final current = _now();
    _items = <SocialPublishedItem>[
      SocialPublishedItem(
        id: 'UI-REVIEW-FEED-001',
        authorId: 'ui-review-asha',
        type: SocialPublishedContentType.post,
        authorName: 'Asha Verma',
        authorHandle: '@ashaverma',
        body:
            'What is one small idea that made your neighbourhood better this week?',
        audience: 'Public',
        publishedAt: current.subtract(const Duration(minutes: 12)),
        likeCount: 148,
        replyCount: 32,
        repostCount: 18,
        shareCount: 11,
      ),
      SocialPublishedItem(
        id: 'UI-REVIEW-FEED-002',
        authorId: 'ui-review-rohan',
        type: SocialPublishedContentType.post,
        authorName: 'Rohan Mehta',
        authorHandle: '@rohanbuilds',
        body:
            'A simple morning market guide for choosing fresher produce and supporting nearby sellers.',
        audience: 'Public',
        publishedAt: current.subtract(const Duration(hours: 1, minutes: 8)),
        mediaPaths: const <String>[
          'assets/prototype/social-market-grocery.png',
        ],
        mediaAreAssets: true,
        likeCount: 326,
        replyCount: 54,
        repostCount: 41,
        shareCount: 29,
      ),
      SocialPublishedItem(
        id: 'UI-REVIEW-FEED-003',
        authorId: 'ui-review-community',
        type: SocialPublishedContentType.quickPoll,
        authorName: 'MoolSocial Community',
        authorHandle: '@moolsocialcommunity',
        body: 'Which local story would you like to explore next?',
        audience: 'Public',
        publishedAt: current.subtract(const Duration(hours: 3)),
        closesAt: current.add(const Duration(days: 2)),
        choices: const <SocialPublishedChoice>[
          SocialPublishedChoice(
            label: 'People building communities',
            votes: 84,
          ),
          SocialPublishedChoice(label: 'Local food and makers', votes: 67),
          SocialPublishedChoice(label: 'Useful work and skills', votes: 51),
        ],
        likeCount: 92,
        replyCount: 21,
        repostCount: 9,
        shareCount: 7,
      ),
    ];
    _comments = <String, List<SocialComment>>{
      'UI-REVIEW-FEED-001': <SocialComment>[
        SocialComment(
          id: 'UI-REVIEW-COMMENT-001',
          postId: 'UI-REVIEW-FEED-001',
          authorId: 'ui-review-neha',
          authorName: 'Neha Jain',
          authorHandle: '@nehajain',
          body: 'A shared book shelf at our community centre.',
          publishedAt: current.subtract(const Duration(minutes: 5)),
        ),
      ],
    };
    _notifications = <SocialNotificationItem>[
      SocialNotificationItem(
        id: 'UI-REVIEW-NOTIFICATION-001',
        kind: SocialNotificationKind.reply,
        title: 'Neha replied to a post',
        preview: 'A shared book shelf at our community centre.',
        publishedAt: current.subtract(const Duration(minutes: 5)),
        read: false,
        postId: 'UI-REVIEW-FEED-001',
        authorId: 'ui-review-neha',
      ),
      SocialNotificationItem(
        id: 'UI-REVIEW-NOTIFICATION-002',
        kind: SocialNotificationKind.follow,
        title: 'Asha followed your public updates',
        preview: 'Open her public profile.',
        publishedAt: current.subtract(const Duration(hours: 1)),
        read: false,
        authorId: 'ui-review-asha',
      ),
      SocialNotificationItem(
        id: 'UI-REVIEW-NOTIFICATION-003',
        kind: SocialNotificationKind.reaction,
        title: 'Rohan liked a post',
        preview: 'A simple morning market guide for choosing fresher produce.',
        publishedAt: current.subtract(const Duration(hours: 2)),
        read: true,
        postId: 'UI-REVIEW-FEED-002',
        authorId: 'ui-review-rohan',
      ),
    ];
  }

  final DateTime Function() _now;
  late final List<SocialPublishedItem> _items;
  late final Map<String, List<SocialComment>> _comments;
  late final List<SocialNotificationItem> _notifications;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async {
    final offset = cursor == null ? 0 : int.tryParse(cursor) ?? 0;
    final safeOffset = offset.clamp(0, _items.length).toInt();
    final end = min(safeOffset + limit, _items.length);
    return SocialFeedPage(
      items: List<SocialPublishedItem>.unmodifiable(
        _items.sublist(safeOffset, end),
      ),
      nextCursor: end < _items.length ? '$end' : null,
    );
  }

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 30,
  }) async {
    final source = _comments[postId] ?? const <SocialComment>[];
    final offset = cursor == null ? 0 : int.tryParse(cursor) ?? 0;
    final safeOffset = offset.clamp(0, source.length).toInt();
    final end = min(safeOffset + limit, source.length);
    return SocialCommentPage(
      items: List<SocialComment>.unmodifiable(source.sublist(safeOffset, end)),
      nextCursor: end < source.length ? '$end' : null,
    );
  }

  @override
  Future<SocialAuthorProfile> author({
    required String authorId,
    bool authenticated = false,
    int limit = 12,
  }) async {
    final posts = _items
        .where((item) => item.authorId == authorId)
        .take(limit)
        .toList(growable: false);
    if (posts.isEmpty) throw _notAvailable();
    final first = posts.first;
    return SocialAuthorProfile(
      authorId: authorId,
      authorName: first.authorName,
      authorHandle: first.authorHandle,
      followerCount: switch (authorId) {
        'ui-review-asha' => 12400,
        'ui-review-rohan' => 8900,
        _ => 28600,
      },
      followed: false,
      isSelf: false,
      posts: List<SocialPublishedItem>.unmodifiable(posts),
    );
  }

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      Future<SocialPublishedItem>.error(_writeUnavailable());

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => Future<SocialPublishedItem>.error(_writeUnavailable());

  @override
  Future<SocialReplyResult> reply(SocialReplyDraft draft) =>
      Future<SocialReplyResult>.error(_writeUnavailable());

  @override
  Future<SocialAuthorProfile> follow({
    required String authorId,
    required bool followed,
  }) => Future<SocialAuthorProfile>.error(_writeUnavailable());

  @override
  Future<void> reportPost({
    required String postId,
    required SocialReportReason reason,
    required String idempotencyKey,
  }) => Future<void>.error(_writeUnavailable());

  @override
  Future<bool> setAuthorBlocked({
    required String authorId,
    required bool blocked,
  }) => Future<bool>.error(_writeUnavailable());

  @override
  Future<SocialFeedPage> saved({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: <SocialPublishedItem>[]);

  @override
  Future<SocialNotificationPage> notifications({
    String? cursor,
    int limit = 30,
  }) async {
    final offset = cursor == null ? 0 : int.tryParse(cursor) ?? 0;
    final safeOffset = offset.clamp(0, _notifications.length).toInt();
    final end = min(safeOffset + limit, _notifications.length);
    return SocialNotificationPage(
      items: List<SocialNotificationItem>.unmodifiable(
        _notifications.sublist(safeOffset, end),
      ),
      nextCursor: end < _notifications.length ? '$end' : null,
    );
  }

  @override
  Future<void> markNotificationRead(String notificationId) =>
      Future<void>.error(_writeUnavailable());

  static SocialContentGatewayException _writeUnavailable() =>
      const SocialContentGatewayException(
        code: 'ui_review_read_only',
        message: 'Sign in to complete this Feed action.',
      );

  static SocialContentGatewayException _notAvailable() =>
      const SocialContentGatewayException(
        code: 'not_found',
        message: 'That MoolSocial author is not available.',
      );
}

enum SocialAppCheckTokenMode { standard, limitedUse }

abstract interface class SocialContentCredentials {
  Future<String> appCheckToken(SocialAppCheckTokenMode mode);

  Future<String> firebaseIdToken();
}

class FirebaseSocialContentCredentials implements SocialContentCredentials {
  FirebaseSocialContentCredentials({
    FirebaseAuth? auth,
    FirebaseAppCheck? appCheck,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _appCheck = appCheck ?? FirebaseAppCheck.instance;

  final FirebaseAuth _auth;
  final FirebaseAppCheck _appCheck;

  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    final token = switch (mode) {
      SocialAppCheckTokenMode.standard => await _appCheck.getToken(),
      SocialAppCheckTokenMode.limitedUse =>
        await _appCheck.getLimitedUseToken(),
    };
    if (token == null || token.isEmpty) {
      throw const SocialContentGatewayException(
        code: 'app_verification_required',
        message: 'App verification is unavailable. Try again.',
      );
    }
    return token;
  }

  @override
  Future<String> firebaseIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SocialContentGatewayException(
        code: 'authentication_required',
        message: 'Sign in to continue.',
        statusCode: 401,
      );
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const SocialContentGatewayException(
        code: 'authentication_required',
        message: 'Sign in to continue.',
        statusCode: 401,
      );
    }
    return token;
  }
}

class SocialContentResponse {
  const SocialContentResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

abstract interface class SocialContentTransport {
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  });
}

class IoSocialContentTransport implements SocialContentTransport {
  IoSocialContentTransport({
    HttpClient? client,
    this.timeout = const Duration(seconds: 45),
    this.maximumResponseBytes = 2 * 1024 * 1024,
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;
  final int maximumResponseBytes;

  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    final encoded = utf8.encode(jsonEncode(body));
    try {
      final request = await _client.postUrl(endpoint).timeout(timeout);
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      request.contentLength = encoded.length;
      request.add(encoded);
      final response = await request.close().timeout(timeout);
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        if (bytes.length + chunk.length > maximumResponseBytes) {
          throw const SocialContentGatewayException(
            code: 'response_too_large',
            message: 'The Feed response is too large.',
          );
        }
        bytes.addAll(chunk);
      }
      return SocialContentResponse(
        statusCode: response.statusCode,
        body: utf8.decode(bytes),
      );
    } on SocialContentGatewayException {
      rethrow;
    } on TimeoutException {
      throw const SocialContentGatewayException(
        code: 'request_timeout',
        message: 'MoolSocial did not respond in time. Try again.',
        retryable: true,
      );
    } on SocketException {
      throw const SocialContentGatewayException(
        code: 'offline',
        message: 'You appear to be offline. Reconnect and try again.',
        retryable: true,
      );
    } on HttpException {
      throw const SocialContentGatewayException(
        code: 'service_unavailable',
        message:
            'MoolSocial posting is unavailable right now. Try again later.',
        retryable: true,
      );
    }
  }

  void close({bool force = false}) => _client.close(force: force);
}

class AuthenticatedSocialContentGateway
    implements
        SocialContentGateway,
        SocialCommentGateway,
        SocialAuthorGateway,
        SocialModerationGateway,
        SocialSavedGateway,
        SocialNotificationGateway {
  AuthenticatedSocialContentGateway({
    required Uri endpoint,
    required this._credentials,
    required this._transport,
    Random? random,
  }) : _endpoint = _validateEndpoint(endpoint),
       _random = random ?? Random.secure();

  final Uri _endpoint;
  final SocialContentCredentials _credentials;
  final SocialContentTransport _transport;
  final Random _random;

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) async {
    final encoded = await _encodeMedia(draft);
    final data = await _invoke(
      'publish',
      limitedUseAppCheck: true,
      body: {
        'idempotencyKey': draft.idempotencyKey,
        'contentType': draft.type.name,
        'body': draft.body,
        'audience': draft.audience,
        'mediaSlots': encoded.mediaSlots,
        'media': encoded.media,
        'choices': encoded.choices,
        'correctChoiceIndex': ?draft.correctChoiceIndex,
        'quotedPostId': ?draft.quotedPostId,
      },
    );
    return _decodePost(_map(data));
  }

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async {
    final data = _map(
      await _invoke(
        'feed',
        authenticated: false,
        body: {'limit': limit, 'cursor': ?cursor},
      ),
    );
    final items = _list(
      data['items'],
    ).map((item) => _decodePost(_map(item))).toList(growable: false);
    return SocialFeedPage(
      items: List.unmodifiable(items),
      nextCursor: _optionalString(data['nextCursor']),
    );
  }

  @override
  Future<SocialFeedPage> saved({String? cursor, int limit = 20}) async {
    final data = _map(
      await _invoke('saved', body: {'limit': limit, 'cursor': ?cursor}),
    );
    final items = _list(
      data['items'],
    ).map((item) => _decodePost(_map(item))).toList(growable: false);
    if (items.any((item) => !item.saved)) {
      throw const SocialContentGatewayException(
        code: 'invalid_response',
        message: 'MoolSocial returned content that is not saved.',
      );
    }
    return SocialFeedPage(
      items: List.unmodifiable(items),
      nextCursor: _optionalString(data['nextCursor']),
    );
  }

  @override
  Future<SocialNotificationPage> notifications({
    String? cursor,
    int limit = 30,
  }) async {
    final data = _map(
      await _invoke('notifications', body: {'limit': limit, 'cursor': ?cursor}),
    );
    final items = _list(
      data['items'],
    ).map((item) => _decodeNotification(_map(item))).toList(growable: false);
    return SocialNotificationPage(
      items: List.unmodifiable(items),
      nextCursor: _optionalString(data['nextCursor']),
    );
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final data = _map(
      await _invoke(
        'notificationRead',
        limitedUseAppCheck: true,
        body: {'notificationId': notificationId},
      ),
    );
    if (data['read'] != true ||
        _requiredString(data['notificationId']) != notificationId) {
      throw const SocialContentGatewayException(
        code: 'invalid_response',
        message: 'MoolSocial could not confirm this notification.',
      );
    }
  }

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) async {
    final data = await _invoke(
      'interact',
      limitedUseAppCheck: true,
      body: {
        'postId': postId,
        'interaction': interaction,
        'choiceIndex': ?choiceIndex,
      },
    );
    return _decodePost(_map(data));
  }

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 30,
  }) async {
    final data = _map(
      await _invoke(
        'comments',
        authenticated: false,
        body: {'postId': postId, 'limit': limit, 'cursor': ?cursor},
      ),
    );
    final items = _list(
      data['items'],
    ).map((item) => _decodeComment(_map(item))).toList(growable: false);
    if (items.any((item) => item.postId != postId)) {
      throw const SocialContentGatewayException(
        code: 'invalid_response',
        message: 'MoolSocial returned replies for a different post.',
      );
    }
    return SocialCommentPage(
      items: List.unmodifiable(items),
      nextCursor: _optionalString(data['nextCursor']),
    );
  }

  @override
  Future<SocialReplyResult> reply(SocialReplyDraft draft) async {
    final data = _map(
      await _invoke(
        'reply',
        limitedUseAppCheck: true,
        body: {
          'postId': draft.postId,
          'idempotencyKey': draft.idempotencyKey,
          'body': draft.body,
        },
      ),
    );
    final comment = _decodeComment(_map(data['comment']));
    final post = _decodePost(_map(data['post']));
    if (comment.postId != draft.postId || post.id != draft.postId) {
      throw const SocialContentGatewayException(
        code: 'invalid_response',
        message: 'MoolSocial returned a reply for a different post.',
      );
    }
    return SocialReplyResult(comment: comment, post: post);
  }

  @override
  Future<SocialAuthorProfile> author({
    required String authorId,
    bool authenticated = false,
    int limit = 12,
  }) async {
    final profile = _decodeAuthorProfile(
      _map(
        await _invoke(
          'author',
          authenticated: authenticated,
          body: {'authorId': authorId, 'limit': limit},
        ),
      ),
    );
    _validateAuthorProfileOwner(profile, authorId);
    return profile;
  }

  @override
  Future<SocialAuthorProfile> follow({
    required String authorId,
    required bool followed,
  }) async {
    final profile = _decodeAuthorProfile(
      _map(
        await _invoke(
          'follow',
          limitedUseAppCheck: true,
          body: {'authorId': authorId, 'followed': followed},
        ),
      ),
    );
    _validateAuthorProfileOwner(profile, authorId);
    return profile;
  }

  @override
  Future<void> reportPost({
    required String postId,
    required SocialReportReason reason,
    required String idempotencyKey,
  }) async {
    final data = _map(
      await _invoke(
        'report',
        limitedUseAppCheck: true,
        body: {
          'postId': postId,
          'reason': reason.name,
          'idempotencyKey': idempotencyKey,
        },
      ),
    );
    if (data['reported'] != true || _requiredString(data['postId']) != postId) {
      throw const SocialContentGatewayException(
        code: 'invalid_response',
        message: 'MoolSocial could not confirm this report.',
      );
    }
  }

  @override
  Future<bool> setAuthorBlocked({
    required String authorId,
    required bool blocked,
  }) async {
    final data = _map(
      await _invoke(
        'blockAuthor',
        limitedUseAppCheck: true,
        body: {'authorId': authorId, 'blocked': blocked},
      ),
    );
    if (_requiredString(data['authorId']) != authorId ||
        data['blocked'] != blocked) {
      throw const SocialContentGatewayException(
        code: 'invalid_response',
        message: 'MoolSocial could not confirm this block setting.',
      );
    }
    return blocked;
  }

  Future<Object?> _invoke(
    String operation, {
    Map<String, Object?> body = const {},
    bool limitedUseAppCheck = false,
    bool authenticated = true,
  }) async {
    final idToken = authenticated ? await _credentials.firebaseIdToken() : null;
    final appCheck = await _credentials.appCheckToken(
      limitedUseAppCheck
          ? SocialAppCheckTokenMode.limitedUse
          : SocialAppCheckTokenMode.standard,
    );
    final response = await _transport.postJson(
      _endpoint,
      headers: {
        'accept': 'application/json',
        if (idToken != null) 'authorization': 'Bearer $idToken',
        'x-firebase-appcheck': appCheck,
        'x-request-id': _requestId(),
      },
      body: {'operation': operation, ...body},
    );
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw SocialContentGatewayException(
        code: 'invalid_response',
        message: 'MoolSocial returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
    final envelope = _map(decoded);
    if (envelope['ok'] == true) return envelope['data'];
    final error = _map(envelope['error']);
    throw SocialContentGatewayException(
      code: _requiredString(error['code']),
      message: _requiredString(error['message']),
      retryable: error['retryable'] == true,
      statusCode: response.statusCode,
    );
  }

  Future<_EncodedSocialMedia> _encodeMedia(SocialPublishDraft draft) async {
    if (draft.mediaAreAssets ||
        draft.choices.any((choice) => choice.imageIsAsset)) {
      throw const SocialContentGatewayException(
        code: 'asset_media_not_publishable',
        message: 'Choose images from your device before publishing.',
      );
    }
    final paths = <String, String>{};
    for (var index = 0; index < draft.mediaPaths.length; index += 1) {
      paths['media:$index'] = draft.mediaPaths[index];
    }
    final choices = <Map<String, Object?>>[];
    for (var index = 0; index < draft.choices.length; index += 1) {
      final choice = draft.choices[index];
      final slot = choice.imagePath == null ? null : 'choice:$index';
      if (slot != null) paths[slot] = choice.imagePath!;
      choices.add({'label': choice.label, 'mediaSlot': ?slot});
    }
    final media = <Map<String, Object?>>[];
    var totalBytes = 0;
    for (final entry in paths.entries) {
      final file = File(entry.value);
      late final List<int> bytes;
      try {
        bytes = await file.readAsBytes();
      } on FileSystemException {
        throw const SocialContentGatewayException(
          code: 'media_unavailable',
          message:
              'One selected image is no longer available. Choose it again.',
        );
      }
      totalBytes += bytes.length;
      if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
        throw const SocialContentGatewayException(
          code: 'media_too_large',
          message: 'Each image must be 8 MB or smaller.',
        );
      }
      if (totalBytes > 20 * 1024 * 1024) {
        throw const SocialContentGatewayException(
          code: 'media_too_large',
          message: 'The selected images must be 20 MB or smaller in total.',
        );
      }
      final contentType = _imageContentType(entry.value);
      media.add({
        'slot': entry.key,
        'fileName': entry.value.split(RegExp(r'[/\\]')).last,
        'contentType': contentType,
        'byteLength': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
        'bytesBase64': base64Encode(bytes),
      });
    }
    return _EncodedSocialMedia(
      mediaSlots: [
        for (var index = 0; index < draft.mediaPaths.length; index += 1)
          'media:$index',
      ],
      media: media,
      choices: choices,
    );
  }

  String _requestId() =>
      List.generate(24, (_) => '0123456789abcdef'[_random.nextInt(16)]).join();

  static Uri _validateEndpoint(Uri endpoint) {
    const requiredHost = 'asia-south1-moolsocial-dev-503018.cloudfunctions.net';
    if (endpoint.scheme != 'https' ||
        endpoint.host != requiredHost ||
        endpoint.path != '/moolSocialContent' ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.hasPort ||
        endpoint.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        endpoint,
        'serviceAddress',
        'must use the secure MoolSocial Dev content service address',
      );
    }
    return endpoint;
  }
}

class _EncodedSocialMedia {
  const _EncodedSocialMedia({
    required this.mediaSlots,
    required this.media,
    required this.choices,
  });

  final List<String> mediaSlots;
  final List<Map<String, Object?>> media;
  final List<Map<String, Object?>> choices;
}

SocialComment _decodeComment(Map<String, Object?> data) => SocialComment(
  id: _requiredString(data['id']),
  postId: _requiredString(data['postId']),
  authorId: _requiredString(data['authorId']),
  authorName: _requiredString(data['authorName']),
  authorHandle: _requiredString(data['authorHandle']),
  body: _requiredString(data['body']),
  publishedAt: DateTime.parse(_requiredString(data['publishedAt'])),
);

SocialNotificationItem _decodeNotification(Map<String, Object?> data) =>
    SocialNotificationItem(
      id: _requiredString(data['id']),
      kind: switch (_requiredString(data['kind'])) {
        'reply' => SocialNotificationKind.reply,
        'reaction' => SocialNotificationKind.reaction,
        'follow' => SocialNotificationKind.follow,
        'messageRequest' => SocialNotificationKind.messageRequest,
        _ => throw const SocialContentGatewayException(
          code: 'invalid_response',
          message: 'MoolSocial returned an unknown notification type.',
        ),
      },
      title: _requiredString(data['title']),
      preview: _requiredString(data['preview'], allowEmpty: true),
      publishedAt: DateTime.parse(_requiredString(data['publishedAt'])),
      read: data['read'] == true,
      postId: _optionalString(data['postId']),
      authorId: _optionalString(data['authorId']),
    );

SocialAuthorProfile _decodeAuthorProfile(Map<String, Object?> data) =>
    SocialAuthorProfile(
      authorId: _requiredString(data['authorId']),
      authorName: _requiredString(data['authorName']),
      authorHandle: _requiredString(data['authorHandle']),
      followerCount: _integer(data['followerCount']),
      followed: data['followed'] == true,
      isSelf: data['isSelf'] == true,
      posts: List.unmodifiable(
        _list(data['posts']).map((item) => _decodePost(_map(item))),
      ),
    );

void _validateAuthorProfileOwner(
  SocialAuthorProfile profile,
  String requestedAuthorId,
) {
  if (profile.authorId != requestedAuthorId ||
      profile.posts.any((post) => post.authorId != requestedAuthorId)) {
    throw const SocialContentGatewayException(
      code: 'invalid_response',
      message: 'MoolSocial returned a different author profile.',
    );
  }
}

SocialPublishedItem _decodePost(Map<String, Object?> data) {
  final choices = _list(data['choices'])
      .map((value) {
        final choice = _map(value);
        return SocialPublishedChoice(
          label: _requiredString(choice['label']),
          imagePath: _optionalString(choice['imageUrl']),
          votes: _integer(choice['votes']),
        );
      })
      .toList(growable: false);
  return SocialPublishedItem(
    id: _requiredString(data['id']),
    authorId: _requiredString(data['authorId']),
    type: _contentType(_requiredString(data['type'])),
    authorName: _requiredString(data['authorName']),
    authorHandle: _requiredString(data['authorHandle']),
    body: _requiredString(data['body'], allowEmpty: true),
    audience: _requiredString(data['audience']),
    publishedAt: DateTime.parse(_requiredString(data['publishedAt'])),
    mediaPaths: List.unmodifiable(
      _list(data['mediaUrls']).map(_requiredString),
    ),
    choices: List.unmodifiable(choices),
    correctChoiceIndex: _optionalInteger(data['correctChoiceIndex']),
    selectedChoiceIndex: _optionalInteger(data['selectedChoiceIndex']),
    closesAt: _optionalDateTime(data['closesAt']),
    quotedPost: switch (data['quotedPost']) {
      final Map<Object?, Object?> value => SocialQuotedPost(
        id: _requiredString(value['id']),
        authorName: _requiredString(value['authorName']),
        authorHandle: _requiredString(value['authorHandle']),
        body: _requiredString(value['body'], allowEmpty: true),
        mediaPath: _optionalString(value['mediaUrl']),
      ),
      _ => null,
    },
    liked: data['liked'] == true,
    saved: data['saved'] == true,
    reposted: data['reposted'] == true,
    likeCount: _integer(data['likeCount']),
    replyCount: _integer(data['replyCount']),
    repostCount: _integer(data['repostCount']),
    shareCount: _integer(data['shareCount']),
  );
}

SocialPublishedContentType _contentType(String value) => switch (value) {
  'post' => SocialPublishedContentType.post,
  'carousel' => SocialPublishedContentType.carousel,
  'imagePoll' => SocialPublishedContentType.imagePoll,
  'quickPoll' => SocialPublishedContentType.quickPoll,
  'quiz' => SocialPublishedContentType.quiz,
  _ => throw const SocialContentGatewayException(
    code: 'invalid_response',
    message: 'MoolSocial returned an unsupported post format.',
  ),
};

String _imageContentType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  throw const SocialContentGatewayException(
    code: 'unsupported_media',
    message: 'Use a JPEG, PNG or WebP image.',
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const SocialContentGatewayException(
      code: 'invalid_response',
      message: 'MoolSocial returned an invalid response.',
    );
  }
  return value.map((key, value) => MapEntry('$key', value));
}

List<Object?> _list(Object? value) {
  if (value is! List) {
    throw const SocialContentGatewayException(
      code: 'invalid_response',
      message: 'MoolSocial returned an invalid response.',
    );
  }
  return value.cast<Object?>();
}

String _requiredString(Object? value, {bool allowEmpty = false}) {
  if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
    throw const SocialContentGatewayException(
      code: 'invalid_response',
      message: 'MoolSocial returned an incomplete response.',
    );
  }
  return value;
}

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int _integer(Object? value) {
  if (value is int) return value;
  throw const SocialContentGatewayException(
    code: 'invalid_response',
    message: 'MoolSocial returned an incomplete response.',
  );
}

int? _optionalInteger(Object? value) => value is int ? value : null;

DateTime? _optionalDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
