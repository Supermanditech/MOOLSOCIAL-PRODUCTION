import 'dart:math';

import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';

class ReviewSocialContentGateway
    implements
        SocialContentGateway,
        SocialCommentGateway,
        SocialAuthorGateway,
        SocialModerationGateway,
        SocialSavedGateway,
        SocialNotificationGateway {
  ReviewSocialContentGateway({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final List<SocialPublishedItem> _items = [];
  final Map<String, List<SocialComment>> _comments = {};
  final Map<String, SocialReplyResult> _replyResults = {};
  final Map<String, bool> _followedAuthors = {};
  final Map<String, int> _followerCounts = {};
  int _sequence = 0;
  int _commentSequence = 0;
  final List<(String, SocialReportReason, String)> reports = [];
  final Set<String> readNotifications = {};
  final Map<String, bool> blockedAuthors = {};

  String? get latestItemId => _items.firstOrNull?.id;

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) async {
    final existing = _items
        .where((item) => item.publishIdempotencyKey == draft.idempotencyKey)
        .firstOrNull;
    if (existing != null) return existing;
    final quotedSource = draft.quotedPostId == null
        ? null
        : _items.where((item) => item.id == draft.quotedPostId).firstOrNull;
    if (draft.quotedPostId != null && quotedSource == null) {
      throw const SocialContentGatewayException(
        code: 'not_found',
        message: 'That shared Feed post is no longer available.',
      );
    }
    _sequence += 1;
    final item = SocialPublishedItem(
      id: 'TEST-SOCIAL-${_sequence.toString().padLeft(4, '0')}',
      authorId: 'review-author-${draft.authorHandle.replaceAll('@', '')}',
      publishIdempotencyKey: draft.idempotencyKey,
      type: draft.type,
      authorName: draft.authorName,
      authorHandle: draft.authorHandle,
      body: draft.body,
      audience: draft.audience,
      publishedAt: _now(),
      mediaPaths: List.unmodifiable(draft.mediaPaths),
      mediaAreAssets: draft.mediaAreAssets,
      choices: List.unmodifiable(draft.choices),
      correctChoiceIndex: draft.correctChoiceIndex,
      quotedPost: quotedSource == null
          ? null
          : SocialQuotedPost(
              id: quotedSource.id,
              authorName: quotedSource.authorName,
              authorHandle: quotedSource.authorHandle,
              body: quotedSource.body,
              mediaPath: quotedSource.mediaPaths.firstOrNull,
            ),
      closesAt: draft.choices.isEmpty
          ? null
          : _now().add(const Duration(days: 7)),
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async {
    final offset = cursor == null ? 0 : int.tryParse(cursor) ?? 0;
    final end = min(offset + limit, _items.length);
    return SocialFeedPage(
      items: List.unmodifiable(_items.sublist(offset, end)),
      nextCursor: end < _items.length ? '$end' : null,
    );
  }

  @override
  Future<SocialFeedPage> saved({String? cursor, int limit = 20}) async {
    final savedItems = _items.where((item) => item.saved).toList();
    final offset = cursor == null ? 0 : int.tryParse(cursor) ?? 0;
    final end = min(offset + limit, savedItems.length);
    return SocialFeedPage(
      items: List.unmodifiable(savedItems.sublist(offset, end)),
      nextCursor: end < savedItems.length ? '$end' : null,
    );
  }

  @override
  Future<SocialNotificationPage> notifications({
    String? cursor,
    int limit = 30,
  }) async {
    if (_items.isEmpty || cursor != null) {
      return const SocialNotificationPage(items: []);
    }
    final item = _items.first;
    return SocialNotificationPage(
      items: [
        SocialNotificationItem(
          id: 'TEST-NOTIFICATION-0001',
          kind: SocialNotificationKind.reaction,
          title: '${item.authorName} liked a post',
          preview: item.body,
          publishedAt: _now(),
          read: readNotifications.contains('TEST-NOTIFICATION-0001'),
          postId: item.id,
          authorId: item.authorId,
        ),
      ],
    );
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    readNotifications.add(notificationId);
  }

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) async {
    final index = _items.indexWhere((item) => item.id == postId);
    if (index < 0) throw _notFound();
    final item = _items[index];
    final updated = switch (interaction) {
      'like' => item.copyWith(
        liked: !item.liked,
        likeCount: max(0, item.likeCount + (item.liked ? -1 : 1)),
      ),
      'save' => item.copyWith(saved: !item.saved),
      'repost' => item.copyWith(
        reposted: !item.reposted,
        repostCount: max(0, item.repostCount + (item.reposted ? -1 : 1)),
      ),
      'vote' => _vote(item, choiceIndex),
      _ => throw const SocialContentGatewayException(
        code: 'unsupported_action',
        message: 'That Feed action is not available yet.',
      ),
    };
    _items[index] = updated;
    return updated;
  }

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 30,
  }) async {
    if (!_items.any((item) => item.id == postId)) throw _notFound();
    final items = _comments[postId] ?? const <SocialComment>[];
    final offset = cursor == null ? 0 : int.tryParse(cursor) ?? 0;
    final end = min(offset + limit, items.length);
    return SocialCommentPage(
      items: List.unmodifiable(items.sublist(offset, end)),
      nextCursor: end < items.length ? '$end' : null,
    );
  }

  @override
  Future<SocialReplyResult> reply(SocialReplyDraft draft) async {
    final prior = _replyResults[draft.idempotencyKey];
    if (prior != null) return prior;
    final index = _items.indexWhere((item) => item.id == draft.postId);
    if (index < 0) throw _notFound();
    _commentSequence += 1;
    final comment = SocialComment(
      id: 'TEST-COMMENT-${_commentSequence.toString().padLeft(4, '0')}',
      postId: draft.postId,
      authorId: 'review-user',
      authorName: 'Asha Sharma',
      authorHandle: '@asha',
      body: draft.body,
      publishedAt: _now(),
    );
    final comments = _comments.putIfAbsent(
      draft.postId,
      () => <SocialComment>[],
    );
    comments.insert(0, comment);
    final updated = _items[index].copyWith(
      replyCount: _items[index].replyCount + 1,
    );
    _items[index] = updated;
    final result = SocialReplyResult(comment: comment, post: updated);
    _replyResults[draft.idempotencyKey] = result;
    return result;
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
    if (posts.isEmpty) throw _authorNotFound();
    final first = posts.first;
    return SocialAuthorProfile(
      authorId: authorId,
      authorName: first.authorName,
      authorHandle: first.authorHandle,
      followerCount: _followerCounts[authorId] ?? 0,
      followed: authenticated && (_followedAuthors[authorId] ?? false),
      isSelf: false,
      posts: List.unmodifiable(posts),
    );
  }

  @override
  Future<SocialAuthorProfile> follow({
    required String authorId,
    required bool followed,
  }) async {
    final current = _followedAuthors[authorId] ?? false;
    if (current != followed) {
      _followerCounts[authorId] = max(
        0,
        (_followerCounts[authorId] ?? 0) + (followed ? 1 : -1),
      );
      _followedAuthors[authorId] = followed;
    }
    return author(authorId: authorId, authenticated: true);
  }

  @override
  Future<void> reportPost({
    required String postId,
    required SocialReportReason reason,
    required String idempotencyKey,
  }) async {
    if (!_items.any((item) => item.id == postId)) throw _notFound();
    if (!reports.any((entry) => entry.$3 == idempotencyKey)) {
      reports.add((postId, reason, idempotencyKey));
    }
  }

  @override
  Future<bool> setAuthorBlocked({
    required String authorId,
    required bool blocked,
  }) async {
    if (!_items.any((item) => item.authorId == authorId)) {
      throw _authorNotFound();
    }
    blockedAuthors[authorId] = blocked;
    return blocked;
  }

  SocialPublishedItem _vote(SocialPublishedItem item, int? choiceIndex) {
    if (item.selectedChoiceIndex != null ||
        choiceIndex == null ||
        choiceIndex < 0 ||
        choiceIndex >= item.choices.length) {
      throw const SocialContentGatewayException(
        code: 'conflict',
        message: 'Your vote could not be recorded.',
      );
    }
    final choices = <SocialPublishedChoice>[
      for (var index = 0; index < item.choices.length; index += 1)
        item.choices[index].copyWith(
          votes: item.choices[index].votes + (index == choiceIndex ? 1 : 0),
        ),
    ];
    return item.copyWith(
      choices: List.unmodifiable(choices),
      selectedChoiceIndex: choiceIndex,
    );
  }

  static SocialContentGatewayException _notFound() =>
      const SocialContentGatewayException(
        code: 'not_found',
        message: 'That Feed post is no longer available.',
      );

  static SocialContentGatewayException _authorNotFound() =>
      const SocialContentGatewayException(
        code: 'not_found',
        message: 'That MoolSocial author is no longer available.',
      );
}
