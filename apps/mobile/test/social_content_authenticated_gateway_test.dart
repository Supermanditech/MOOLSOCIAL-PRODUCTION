import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';

void main() {
  test(
    'authenticated gateway uses limited App Check and verified media bytes',
    () async {
      final credentials = _Credentials();
      final transport = _Transport((body) {
        expect(body['operation'], 'publish');
        final media =
            (body['media']! as List<Object?>).single as Map<String, Object?>;
        expect(media['contentType'], 'image/png');
        expect(media['sha256'], hasLength(64));
        expect(base64Decode(media['bytesBase64']! as String), isNotEmpty);
        return _postEnvelope(
          mediaUrls: const ['https://example.test/image.png'],
        );
      });
      final gateway = AuthenticatedSocialContentGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
        ),
        credentials: credentials,
        transport: transport,
      );

      final item = await gateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'social-publish-retry-0001',
          type: SocialPublishedContentType.post,
          authorName: 'Ignored client author',
          authorHandle: '@ignored',
          body: 'Verified image post',
          audience: 'Public',
          mediaPaths: ['assets/prototype/social-market-grocery.png'],
          mediaAreAssets: false,
          choices: [],
        ),
      );

      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
      expect(item.authorName, 'Server verified author');
      expect(item.mediaPaths, ['https://example.test/image.png']);
      expect(transport.headers.single['authorization'], 'Bearer id-token');
      expect(transport.headers.single['x-firebase-appcheck'], 'limited-token');
    },
  );

  test('Feed uses standard App Check and maps the durable cursor', () async {
    final credentials = _Credentials();
    final transport = _Transport((body) {
      expect(body, {'operation': 'feed', 'limit': 20});
      return jsonEncode({
        'ok': true,
        'data': {
          'items': [jsonDecode(_postData())],
          'nextCursor': '2026-08-11T12:00:00.000Z_post-1',
        },
      });
    });
    final gateway = AuthenticatedSocialContentGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
      ),
      credentials: credentials,
      transport: transport,
    );

    final page = await gateway.feed();

    expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
    expect(page.items.single.id, 'post-1');
    expect(page.nextCursor, '2026-08-11T12:00:00.000Z_post-1');
    expect(credentials.idTokenRequests, 0);
    expect(transport.headers.single, isNot(contains('authorization')));
  });

  test('quoted publish and repost map only server-acknowledged truth', () async {
    final credentials = _Credentials();
    var call = 0;
    final transport = _Transport((body) {
      call += 1;
      if (call == 1) {
        expect(body['operation'], 'publish');
        expect(body['quotedPostId'], 'original-post-1');
      } else {
        expect(body, {
          'operation': 'interact',
          'postId': 'post-1',
          'interaction': 'repost',
        });
      }
      return jsonEncode({
        'ok': true,
        'data': {
          ...jsonDecode(_postData()) as Map<String, Object?>,
          'quotedPost': {
            'id': 'original-post-1',
            'authorName': 'Original author',
            'authorHandle': '@original',
            'body': 'Original public post',
          },
          'reposted': call == 2,
          'repostCount': call == 2 ? 1 : 0,
        },
      });
    });
    final gateway = AuthenticatedSocialContentGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
      ),
      credentials: credentials,
      transport: transport,
    );

    final published = await gateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'quoted-publish-0001',
        type: SocialPublishedContentType.post,
        authorName: 'Ignored client author',
        authorHandle: '@ignored',
        body: 'My thoughts',
        audience: 'Public',
        mediaPaths: [],
        mediaAreAssets: false,
        choices: [],
        quotedPostId: 'original-post-1',
      ),
    );
    expect(published.quotedPost?.id, 'original-post-1');
    expect(published.reposted, isFalse);

    final reposted = await gateway.interact(
      postId: published.id,
      interaction: 'repost',
    );
    expect(reposted.reposted, isTrue);
    expect(reposted.repostCount, 1);
  });

  test('comments use standard App Check without an identity token', () async {
    final credentials = _Credentials();
    final transport = _Transport((body) {
      expect(body, {'operation': 'comments', 'postId': 'post-1', 'limit': 30});
      return jsonEncode({
        'ok': true,
        'data': {
          'items': [_commentData()],
          'nextCursor': '2026-08-13T12:00:00.000Z_comment-1',
        },
      });
    });
    final gateway = AuthenticatedSocialContentGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
      ),
      credentials: credentials,
      transport: transport,
    );

    final page = await gateway.comments(postId: 'post-1');

    expect(page.items.single.body, 'A public reply');
    expect(page.nextCursor, '2026-08-13T12:00:00.000Z_comment-1');
    expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
    expect(credentials.idTokenRequests, 0);
    expect(transport.headers.single, isNot(contains('authorization')));
  });

  test(
    'reply uses limited App Check and maps only server acknowledgement',
    () async {
      final credentials = _Credentials();
      final transport = _Transport((body) {
        expect(body, {
          'operation': 'reply',
          'postId': 'post-1',
          'idempotencyKey': 'social-reply-retry-0001',
          'body': 'My durable reply',
        });
        return jsonEncode({
          'ok': true,
          'data': {
            'comment': _commentData(body: 'My durable reply'),
            'post': {
              ...jsonDecode(_postData()) as Map<String, Object?>,
              'replyCount': 1,
            },
          },
        });
      });
      final gateway = AuthenticatedSocialContentGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
        ),
        credentials: credentials,
        transport: transport,
      );

      final result = await gateway.reply(
        const SocialReplyDraft(
          postId: 'post-1',
          idempotencyKey: 'social-reply-retry-0001',
          body: 'My durable reply',
        ),
      );

      expect(result.comment.body, 'My durable reply');
      expect(result.post.replyCount, 1);
      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
      expect(credentials.idTokenRequests, 1);
      expect(transport.headers.single['authorization'], 'Bearer id-token');
    },
  );

  test('author profile is a public read with bounded public fields', () async {
    final credentials = _Credentials();
    final transport = _Transport((body) {
      expect(body, {
        'operation': 'author',
        'authorId': 'author-1',
        'limit': 12,
      });
      return jsonEncode({'ok': true, 'data': _profileData()});
    });
    final gateway = AuthenticatedSocialContentGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
      ),
      credentials: credentials,
      transport: transport,
    );

    final profile = await gateway.author(authorId: 'author-1');

    expect(profile.authorHandle, '@publicauthor');
    expect(profile.posts.single.authorId, 'author-1');
    expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
    expect(credentials.idTokenRequests, 0);
    expect(transport.headers.single, isNot(contains('authorization')));
  });

  test(
    'follow uses limited App Check and server-acknowledged relationship',
    () async {
      final credentials = _Credentials();
      final transport = _Transport((body) {
        expect(body, {
          'operation': 'follow',
          'authorId': 'author-1',
          'followed': true,
        });
        return jsonEncode({
          'ok': true,
          'data': _profileData(followed: true, followerCount: 5),
        });
      });
      final gateway = AuthenticatedSocialContentGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
        ),
        credentials: credentials,
        transport: transport,
      );

      final profile = await gateway.follow(
        authorId: 'author-1',
        followed: true,
      );

      expect(profile.followed, isTrue);
      expect(profile.followerCount, 5);
      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
      expect(credentials.idTokenRequests, 1);
    },
  );

  test('author rejects a profile owned by a different author', () async {
    final gateway = AuthenticatedSocialContentGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
      ),
      credentials: _Credentials(),
      transport: _Transport(
        (_) => jsonEncode({
          'ok': true,
          'data': {..._profileData(), 'authorId': 'different-author'},
        }),
      ),
    );

    await expectLater(
      gateway.author(authorId: 'author-1'),
      throwsA(
        isA<SocialContentGatewayException>().having(
          (error) => error.code,
          'code',
          'invalid_response',
        ),
      ),
    );
  });

  test(
    'SharedSession changes Follow only after server acknowledgement',
    () async {
      final pending = Completer<SocialAuthorProfile>();
      final gateway = _PendingFollowGateway(pending.future);
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);
      expect(await session.loadSocialAuthor('author-1'), isTrue);
      expect(session.socialAuthorProfile('author-1')?.followed, isFalse);

      final follow = session.setSocialFollow('author-1', true);
      await Future<void>.delayed(Duration.zero);

      expect(session.socialFollowBusy('author-1'), isTrue);
      expect(session.socialAuthorProfile('author-1')?.followed, isFalse);
      pending.complete(_profile(followed: true, followerCount: 5));
      expect(await follow, isTrue);
      expect(session.socialAuthorProfile('author-1')?.followed, isTrue);
      expect(session.socialAuthorProfile('author-1')?.followerCount, 5);
    },
  );

  test(
    'SharedSession contains offline and rejected Follow before retry',
    () async {
      final gateway = _RetryFollowGateway();
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);
      expect(await session.loadSocialAuthor('author-1'), isTrue);
      session.online = false;

      expect(await session.setSocialFollow('author-1', true), isFalse);
      expect(gateway.followCalls, 0);
      expect(session.socialAuthorProfile('author-1')?.followed, isFalse);
      expect(session.socialAuthorError('author-1'), contains('offline'));
      session.online = true;

      expect(await session.setSocialFollow('author-1', true), isFalse);
      expect(gateway.followCalls, 1);
      expect(session.socialAuthorProfile('author-1')?.followed, isFalse);
      expect(await session.setSocialFollow('author-1', true), isTrue);
      expect(gateway.followCalls, 2);
      expect(session.socialAuthorProfile('author-1')?.followed, isTrue);
    },
  );

  test(
    'SharedSession keeps content local until server acknowledgement',
    () async {
      final pending = Completer<SocialPublishedItem>();
      final gateway = _PendingGateway(pending.future);
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);

      final publish = session.publishSocialContent(
        type: SocialPublishedContentType.post,
        authorName: 'Client name',
        authorHandle: '@client',
        body: 'Pending post',
      );
      await Future<void>.delayed(Duration.zero);

      expect(session.socialPublishedItems, isEmpty);
      expect(session.busy, isTrue);
      pending.complete(_post(body: 'Pending post'));
      expect(await publish, isNotNull);
      expect(session.socialPublishedItems.single.body, 'Pending post');
    },
  );

  test(
    'SharedSession uses quote-specific empty-thoughts recovery before Post validation',
    () async {
      final gateway = _CountingPublishGateway();
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);

      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.post,
          authorName: 'Client name',
          authorHandle: '@client',
          body: '   ',
          quotedPostId: 'original-post-1',
        ),
        isNull,
      );

      expect(
        session.errorMessage,
        'Add your thoughts before sharing this post.',
      );
      expect(gateway.publishCalls, 0);
      expect(session.socialPublishedItems, isEmpty);
    },
  );

  test(
    'SharedSession retains generic recovery for an ordinary empty Post',
    () async {
      final gateway = _CountingPublishGateway();
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);

      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.post,
          authorName: 'Client name',
          authorHandle: '@client',
          body: '   ',
        ),
        isNull,
      );

      expect(
        session.errorMessage,
        'Write something or add an image before posting.',
      );
      expect(gateway.publishCalls, 0);
      expect(session.socialPublishedItems, isEmpty);
    },
  );

  test('comments reject rows owned by a different post', () async {
    final gateway = AuthenticatedSocialContentGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
      ),
      credentials: _Credentials(),
      transport: _Transport(
        (_) => jsonEncode({
          'ok': true,
          'data': {
            'items': [_commentData(postId: 'different-post')],
          },
        }),
      ),
    );

    await expectLater(
      gateway.comments(postId: 'post-1'),
      throwsA(
        isA<SocialContentGatewayException>().having(
          (error) => error.code,
          'code',
          'invalid_response',
        ),
      ),
    );
  });

  test('Report sends the exact private moderation contract', () async {
    final credentials = _Credentials();
    final transport = _Transport((body) {
      expect(body, {
        'operation': 'report',
        'postId': 'post-1',
        'reason': 'harassment',
        'idempotencyKey': 'social-report-0001',
      });
      return jsonEncode({
        'ok': true,
        'data': {'postId': 'post-1', 'reported': true},
      });
    });
    final gateway = AuthenticatedSocialContentGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
      ),
      credentials: credentials,
      transport: transport,
    );

    await gateway.reportPost(
      postId: 'post-1',
      reason: SocialReportReason.harassment,
      idempotencyKey: 'social-report-0001',
    );

    expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
    expect(transport.headers.single['authorization'], 'Bearer id-token');
  });

  test('reply rejects an acknowledged post owned by another request', () async {
    final gateway = AuthenticatedSocialContentGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent',
      ),
      credentials: _Credentials(),
      transport: _Transport(
        (_) => jsonEncode({
          'ok': true,
          'data': {
            'comment': _commentData(),
            'post': {
              ...jsonDecode(_postData()) as Map<String, Object?>,
              'id': 'different-post',
              'replyCount': 1,
            },
          },
        }),
      ),
    );

    await expectLater(
      gateway.reply(
        const SocialReplyDraft(
          postId: 'post-1',
          idempotencyKey: 'social-reply-retry-0001',
          body: 'My durable reply',
        ),
      ),
      throwsA(
        isA<SocialContentGatewayException>().having(
          (error) => error.code,
          'code',
          'invalid_response',
        ),
      ),
    );
  });

  test(
    'SharedSession reuses its idempotency key after a retryable failure',
    () async {
      final gateway = _RetryGateway();
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);

      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.post,
          authorName: 'Client name',
          authorHandle: '@client',
          body: 'Retry this post',
        ),
        isNull,
      );
      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.post,
          authorName: 'Client name',
          authorHandle: '@client',
          body: 'Retry this post',
        ),
        isNotNull,
      );
      expect(gateway.keys, hasLength(2));
      expect(gateway.keys[0], gateway.keys[1]);
    },
  );

  test(
    'SharedSession sends at most one interaction per post at a time',
    () async {
      final pending = Completer<SocialPublishedItem>();
      final gateway = _PendingInteractionGateway(pending.future);
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);
      expect(await session.loadSocialFeed(refresh: true), isTrue);

      final first = session.toggleSocialLike('post-1');
      await Future<void>.delayed(Duration.zero);
      expect(session.socialInteractionBusy('post-1'), isTrue);
      expect(await session.toggleSocialSave('post-1'), isFalse);
      expect(gateway.interactionCalls, 1);

      pending.complete(_post().copyWith(liked: true, likeCount: 1));
      expect(await first, isTrue);
      expect(session.socialInteractionBusy('post-1'), isFalse);
      expect(session.socialPublishedItems.single.liked, isTrue);
      expect(session.socialPublishedItems.single.likeCount, 1);
    },
  );

  test(
    'SharedSession exposes public comments and waits for reply acknowledgement',
    () async {
      final pending = Completer<SocialReplyResult>();
      final gateway = _PendingReplyGateway(pending.future);
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);
      expect(await session.loadSocialFeed(refresh: true), isTrue);
      expect(await session.loadSocialComments('post-1', refresh: true), isTrue);
      expect(session.socialComments('post-1').single.body, 'A public reply');
      session.saveSocialReplyDraft('post-1', 'My durable reply');

      final posting = session.postSocialReply('post-1', 'My durable reply');
      await Future<void>.delayed(Duration.zero);

      expect(session.socialReplyBusy('post-1'), isTrue);
      expect(session.socialComments('post-1'), hasLength(1));
      expect(session.socialPublishedItems.single.replyCount, 0);
      pending.complete(
        SocialReplyResult(
          comment: _comment(body: 'My durable reply', id: 'comment-created'),
          post: _post().copyWith(replyCount: 1),
        ),
      );
      expect(await posting, isTrue);
      expect(session.socialComments('post-1').first.body, 'My durable reply');
      expect(session.socialPublishedItems.single.replyCount, 1);
      expect(session.socialReplyDraft('post-1'), isEmpty);
    },
  );

  test(
    'SharedSession retains reply draft and idempotency key across retry',
    () async {
      final gateway = _RetryReplyGateway();
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);
      expect(await session.loadSocialFeed(refresh: true), isTrue);
      session.saveSocialReplyDraft('post-1', 'Retry my reply');

      expect(
        await session.postSocialReply('post-1', 'Retry my reply'),
        isFalse,
      );
      expect(session.socialReplyDraft('post-1'), 'Retry my reply');
      expect(session.socialPublishedItems.single.replyCount, 0);
      expect(await session.postSocialReply('post-1', 'Retry my reply'), isTrue);

      expect(gateway.keys, hasLength(2));
      expect(gateway.keys[0], gateway.keys[1]);
      expect(session.socialReplyDraft('post-1'), isEmpty);
      expect(session.socialPublishedItems.single.replyCount, 1);
    },
  );

  test(
    'SharedSession preserves an offline reply without a network call',
    () async {
      final gateway = _RetryReplyGateway();
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);
      expect(await session.loadSocialFeed(refresh: true), isTrue);
      session.saveSocialReplyDraft('post-1', 'Post after reconnecting');
      session.online = false;

      expect(
        await session.postSocialReply('post-1', 'Post after reconnecting'),
        isFalse,
      );
      expect(gateway.keys, isEmpty);
      expect(session.socialReplyDraft('post-1'), 'Post after reconnecting');
      expect(
        session.socialCommentError('post-1'),
        'You are offline. Your reply is still here. Reconnect and try again.',
      );
      expect(session.socialPublishedItems.single.replyCount, 0);
    },
  );

  test(
    'SharedSession retains reply draft and retry identity after timeout',
    () async {
      final gateway = _RetryReplyGateway(
        firstFailure: TimeoutException('private reply timeout'),
      );
      final session = SharedSession(socialContentGateway: gateway);
      addTearDown(session.dispose);
      expect(await session.loadSocialFeed(refresh: true), isTrue);
      session.saveSocialReplyDraft('post-1', 'Retry after timeout');

      expect(
        await session.postSocialReply('post-1', 'Retry after timeout'),
        isFalse,
      );
      expect(session.socialReplyDraft('post-1'), 'Retry after timeout');
      expect(
        session.socialCommentError('post-1'),
        'Your reply could not be posted. It is still here. Please try again.',
      );
      expect(
        await session.postSocialReply('post-1', 'Retry after timeout'),
        isTrue,
      );

      expect(gateway.keys, hasLength(2));
      expect(gateway.keys[0], gateway.keys[1]);
      expect(session.socialPublishedItems.single.replyCount, 1);
    },
  );

  test(
    'gateway rejects every endpoint outside the exact Dev content owner',
    () {
      expect(
        () => AuthenticatedSocialContentGateway(
          endpoint: Uri.parse('https://example.com/moolSocialContent'),
          credentials: _Credentials(),
          transport: _Transport((_) => '{}'),
        ),
        throwsArgumentError,
      );
    },
  );
}

class _Credentials implements SocialContentCredentials {
  final List<SocialAppCheckTokenMode> modes = [];
  int idTokenRequests = 0;

  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return mode == SocialAppCheckTokenMode.limitedUse
        ? 'limited-token'
        : 'standard-token';
  }

  @override
  Future<String> firebaseIdToken() async {
    idTokenRequests += 1;
    return 'id-token';
  }
}

class _Transport implements SocialContentTransport {
  _Transport(this.respond);

  final String Function(Map<String, Object?> body) respond;
  final List<Map<String, String>> headers = [];

  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    this.headers.add(headers);
    return SocialContentResponse(statusCode: 200, body: respond(body));
  }
}

class _PendingGateway implements SocialContentGateway {
  _PendingGateway(this.pending);

  final Future<SocialPublishedItem> pending;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: []);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) async => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) => pending;
}

class _CountingPublishGateway implements SocialContentGateway {
  int publishCalls = 0;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: []);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) async {
    publishCalls += 1;
    return _post(body: draft.body);
  }
}

class _RetryGateway implements SocialContentGateway {
  final List<String> keys = [];

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: []);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) async => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) async {
    keys.add(draft.idempotencyKey);
    if (keys.length == 1) {
      throw const SocialContentGatewayException(
        code: 'offline',
        message: 'Reconnect and retry.',
        retryable: true,
      );
    }
    return _post(body: draft.body);
  }
}

class _PendingInteractionGateway implements SocialContentGateway {
  _PendingInteractionGateway(this.pending);

  final Future<SocialPublishedItem> pending;
  int interactionCalls = 0;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      SocialFeedPage(items: [_post()]);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) {
    interactionCalls += 1;
    return pending;
  }

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      throw UnimplementedError();
}

class _PendingReplyGateway
    implements SocialContentGateway, SocialCommentGateway {
  _PendingReplyGateway(this.pending);

  final Future<SocialReplyResult> pending;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      SocialFeedPage(items: [_post()]);

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 30,
  }) async => SocialCommentPage(items: [_comment()]);

  @override
  Future<SocialReplyResult> reply(SocialReplyDraft draft) => pending;

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      throw UnimplementedError();
}

class _PendingFollowGateway
    implements SocialContentGateway, SocialAuthorGateway {
  _PendingFollowGateway(this.pending);

  final Future<SocialAuthorProfile> pending;

  @override
  Future<SocialAuthorProfile> author({
    required String authorId,
    bool authenticated = false,
    int limit = 12,
  }) async => _profile();

  @override
  Future<SocialAuthorProfile> follow({
    required String authorId,
    required bool followed,
  }) => pending;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: []);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      throw UnimplementedError();
}

class _RetryFollowGateway implements SocialContentGateway, SocialAuthorGateway {
  int followCalls = 0;

  @override
  Future<SocialAuthorProfile> author({
    required String authorId,
    bool authenticated = false,
    int limit = 12,
  }) async => _profile();

  @override
  Future<SocialAuthorProfile> follow({
    required String authorId,
    required bool followed,
  }) async {
    followCalls += 1;
    if (followCalls == 1) {
      throw const SocialContentGatewayException(
        code: 'unavailable',
        message: 'Follow is unavailable. Retry.',
        retryable: true,
      );
    }
    return _profile(followed: followed, followerCount: followed ? 5 : 4);
  }

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: []);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      throw UnimplementedError();
}

class _RetryReplyGateway implements SocialContentGateway, SocialCommentGateway {
  _RetryReplyGateway({
    this.firstFailure = const SocialContentGatewayException(
      code: 'offline',
      message: 'Reconnect and retry.',
      retryable: true,
    ),
  });

  final Object firstFailure;
  final List<String> keys = [];

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      SocialFeedPage(items: [_post()]);

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 30,
  }) async => const SocialCommentPage(items: []);

  @override
  Future<SocialReplyResult> reply(SocialReplyDraft draft) async {
    keys.add(draft.idempotencyKey);
    if (keys.length == 1) {
      throw firstFailure;
    }
    return SocialReplyResult(
      comment: _comment(body: draft.body, id: 'comment-created'),
      post: _post().copyWith(replyCount: 1),
    );
  }

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      throw UnimplementedError();
}

String _postEnvelope({List<String> mediaUrls = const []}) => jsonEncode({
  'ok': true,
  'data': jsonDecode(_postData(mediaUrls: mediaUrls)),
});

String _postData({List<String> mediaUrls = const []}) => jsonEncode({
  'id': 'post-1',
  'type': 'post',
  'authorId': 'user-1',
  'authorName': 'Server verified author',
  'authorHandle': '@verified',
  'body': 'Verified image post',
  'audience': 'Public',
  'publishedAt': '2026-08-11T12:00:00.000Z',
  'mediaUrls': mediaUrls,
  'choices': <Object?>[],
  'liked': false,
  'saved': false,
  'likeCount': 0,
  'replyCount': 0,
  'repostCount': 0,
  'shareCount': 0,
});

Map<String, Object?> _profileData({
  bool followed = false,
  int followerCount = 4,
}) => {
  'authorId': 'author-1',
  'authorName': 'Public Author',
  'authorHandle': '@publicauthor',
  'followerCount': followerCount,
  'followed': followed,
  'isSelf': false,
  'posts': [
    {
      ...jsonDecode(_postData()) as Map<String, Object?>,
      'authorId': 'author-1',
      'authorName': 'Public Author',
      'authorHandle': '@publicauthor',
    },
  ],
};

Map<String, Object?> _commentData({
  String postId = 'post-1',
  String body = 'A public reply',
}) => {
  'id': 'comment-1',
  'postId': postId,
  'authorId': 'reader-1',
  'authorName': 'Public Reader',
  'authorHandle': '@reader',
  'body': body,
  'publishedAt': '2026-08-13T12:00:00.000Z',
};

SocialComment _comment({
  String id = 'comment-1',
  String postId = 'post-1',
  String body = 'A public reply',
}) => SocialComment(
  id: id,
  postId: postId,
  authorId: 'reader-1',
  authorName: 'Public Reader',
  authorHandle: '@reader',
  body: body,
  publishedAt: DateTime.utc(2026, 8, 13, 12),
);

SocialAuthorProfile _profile({bool followed = false, int followerCount = 4}) =>
    SocialAuthorProfile(
      authorId: 'author-1',
      authorName: 'Public Author',
      authorHandle: '@publicauthor',
      followerCount: followerCount,
      followed: followed,
      isSelf: false,
      posts: const [],
    );

SocialPublishedItem _post({String body = 'Body'}) => SocialPublishedItem(
  id: 'post-1',
  authorId: 'user-1',
  type: SocialPublishedContentType.post,
  authorName: 'Server verified author',
  authorHandle: '@verified',
  body: body,
  audience: 'Public',
  publishedAt: DateTime.utc(2026, 8, 11, 12),
);
