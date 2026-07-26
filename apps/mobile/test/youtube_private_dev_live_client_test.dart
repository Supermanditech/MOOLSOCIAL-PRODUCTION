import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_app_check.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_client.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_transport.dart';

const _endpoint =
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
    'youtubeProvider';
const _chat = YouTubeLiveChatIdentity(
  broadcastId: 'broadcast-1',
  liveChatId: 'live-chat-1',
);

void main() {
  group('private Dev Live capability boundary', () {
    test(
      'compiled client is disabled by default and purposes stay separate',
      () {
        expect(youtubePrivateDevLiveClientEnabled, isFalse);
        expect(YouTubeConnectPurpose.live.wireValue, 'live');
        expect(
          YouTubeConnectPurpose.liveMemberships.wireValue,
          'liveMemberships',
        );
        expect(
          YouTubePrivateDevCapabilities.fromJson(_capabilities()).live,
          isFalse,
        );
        expect(
          YouTubePrivateDevCapabilities.fromJson(
            _capabilities(live: true),
          ).live,
          isTrue,
        );
      },
    );

    test('a disabled client fails before Auth, App Check or transport', () {
      final transport = _FakeTransport();
      final credentials = _FakeCredentials();
      final client = _client(
        transport: transport,
        credentials: credentials,
        liveEnabled: false,
      );

      expect(
        () => client.liveListStreams(),
        throwsA(isA<YouTubeCapabilityUnavailableException>()),
      );
      expect(credentials.idTokenCalls, 0);
      expect(credentials.appCheckModes, isEmpty);
      expect(transport.posts, isEmpty);
    });

    test(
      'Live and memberships request distinct incremental purposes',
      () async {
        final transport = _FakeTransport()
          ..success(<String, Object?>{
            'authorizationUrl': 'https://accounts.google.com/o/oauth2/v2/auth',
            'expiresAt': '2026-07-25T13:00:00.000Z',
          })
          ..success(<String, Object?>{
            'authorizationUrl': 'https://accounts.google.com/o/oauth2/v2/auth',
            'expiresAt': '2026-07-25T13:00:00.000Z',
          });
        final credentials = _FakeCredentials();
        final client = _client(
          transport: transport,
          credentials: credentials,
          liveEnabled: false,
        );

        await client.startConnection(
          purpose: YouTubeConnectPurpose.live,
          promptForConsent: true,
        );
        await client.startConnection(
          purpose: YouTubeConnectPurpose.liveMemberships,
          promptForConsent: true,
        );

        expect(transport.posts[0].body['purpose'], 'live');
        expect(transport.posts[1].body['purpose'], 'liveMemberships');
        _expectPrivileged(credentials, transport, 2);
      },
    );

    test('mismatched destructive confirmation fails before credentials', () {
      final transport = _FakeTransport();
      final credentials = _FakeCredentials();
      final client = _client(transport: transport, credentials: credentials);

      expect(
        () => client.liveDeleteBroadcast(
          broadcastId: 'broadcast-1',
          confirmBroadcastId: 'broadcast-2',
        ),
        throwsArgumentError,
      );
      expect(transport.posts, isEmpty);
      expect(credentials.appCheckModes, isEmpty);
    });
  });

  test(
    'broadcast operations are typed, private and explicitly confirmed',
    () async {
      final transport = _FakeTransport();
      final credentials = _FakeCredentials();
      final client = _client(transport: transport, credentials: credentials);
      transport
        ..success(<String, Object?>{
          'items': <Object?>[_broadcastJson()],
          'nextPageToken': 'broadcast-next',
        })
        ..success(_broadcastJson())
        ..success(_broadcastJson())
        ..success(_broadcastJson(boundStreamId: 'stream-1'))
        ..success(_broadcastJson(lifecycle: 'testing'))
        ..success(<String, Object?>{'deletedBroadcastId': 'broadcast-1'});

      final page = await client.liveListBroadcasts(
        status: YouTubeLiveBroadcastFilter.upcoming,
        pageToken: 'broadcast-page',
        maxResults: 25,
      );
      final inserted = await client.liveInsertBroadcast(
        broadcast: _broadcastWrite,
      );
      await client.liveUpdateBroadcast(
        broadcastId: 'broadcast-1',
        broadcast: _broadcastWrite,
      );
      final bound = await client.liveBindBroadcast(
        broadcastId: 'broadcast-1',
        streamId: 'stream-1',
        confirmBroadcastId: 'broadcast-1',
        confirmStreamId: 'stream-1',
      );
      final transitioned = await client.liveTransitionBroadcast(
        broadcastId: 'broadcast-1',
        targetStatus: YouTubeLiveBroadcastTransition.testing,
        confirmBroadcastId: 'broadcast-1',
        confirmTargetStatus: YouTubeLiveBroadcastTransition.testing,
      );
      final deleted = await client.liveDeleteBroadcast(
        broadcastId: 'broadcast-1',
        confirmBroadcastId: 'broadcast-1',
      );

      expect(page.nextPageToken, 'broadcast-next');
      expect(page.items.single.privacyStatus, YouTubeLivePrivacy.private);
      expect(inserted.description, '');
      expect(bound.boundStreamId, 'stream-1');
      expect(
        transitioned.lifeCycleStatus,
        YouTubeLiveBroadcastLifecycle.testing,
      );
      expect(deleted.broadcastId, 'broadcast-1');
      expect(transport.operations, <String>[
        'liveListBroadcasts',
        'liveInsertBroadcast',
        'liveUpdateBroadcast',
        'liveBindBroadcast',
        'liveTransitionBroadcast',
        'liveDeleteBroadcast',
      ]);
      expect(transport.posts[0].body['status'], 'upcoming');
      expect(
        transport.posts[1].body['scheduledStartTime'],
        '2026-07-26T10:00:00.000Z',
      );
      expect(transport.posts[3].body['confirmStreamId'], 'stream-1');
      expect(transport.posts[4].body['confirmTargetStatus'], 'testing');
      expect(transport.posts[5].body['confirmBroadcastId'], 'broadcast-1');
      _expectPrivileged(credentials, transport, 6);
    },
  );

  test(
    'stream operations preserve typed CDN settings and protect the key',
    () async {
      final transport = _FakeTransport();
      final credentials = _FakeCredentials();
      final client = _client(transport: transport, credentials: credentials);
      transport
        ..success(<String, Object?>{
          'items': <Object?>[_streamJson()],
          'nextPageToken': 'stream-next',
        })
        ..success(_streamJson())
        ..success(_streamJson(status: 'inactive'))
        ..success(<String, Object?>{'deletedStreamId': 'stream-1'});

      final page = await client.liveListStreams(
        pageToken: 'stream-page',
        maxResults: 10,
      );
      final inserted = await client.liveInsertStream(
        stream: _streamWrite,
        resolution: YouTubeLiveStreamResolution.p1080,
        frameRate: YouTubeLiveStreamFrameRate.fps60,
        ingestionType: YouTubeLiveStreamIngestionType.rtmp,
      );
      final updated = await client.liveUpdateStream(
        streamId: 'stream-1',
        stream: _streamWrite,
      );
      final deleted = await client.liveDeleteStream(
        streamId: 'stream-1',
        confirmStreamId: 'stream-1',
      );

      expect(page.nextPageToken, 'stream-next');
      expect(inserted.resolution, YouTubeLiveStreamResolution.p1080);
      expect(inserted.rtmpsIngestionAddress?.scheme, 'rtmps');
      expect(inserted.streamName, 'secret-stream-key');
      expect(inserted.toString(), isNot(contains('secret-stream-key')));
      expect(updated.streamStatus, YouTubeLiveStreamStatus.inactive);
      expect(deleted.streamId, 'stream-1');
      expect(transport.operations, <String>[
        'liveListStreams',
        'liveInsertStream',
        'liveUpdateStream',
        'liveDeleteStream',
      ]);
      expect(transport.posts[1].body['resolution'], '1080p');
      expect(transport.posts[1].body['frameRate'], '60fps');
      expect(transport.posts[1].body['ingestionType'], 'rtmp');
      expect(transport.posts[3].body['confirmStreamId'], 'stream-1');
      _expectPrivileged(credentials, transport, 4);
    },
  );

  test('provider-owned live fields fail closed when trust contracts drift', () {
    expect(
      () => YouTubeLiveStream.fromJson(<String, Object?>{
        ..._streamJson(),
        'ingestionAddress': 'rtmp://attacker.example/live',
      }),
      throwsFormatException,
    );
    expect(
      () => YouTubeLiveMembersPage.fromJson(<String, Object?>{
        'eligibility': 'provider_approved_channel_only',
        'items': <Object?>[_memberJson()],
      }),
      throwsFormatException,
    );
  });

  test(
    'chat uses bounded REST polling and typed contextual poll actions',
    () async {
      final transport = _FakeTransport();
      final credentials = _FakeCredentials();
      final client = _client(transport: transport, credentials: credentials);
      transport
        ..success(<String, Object?>{
          'items': <Object?>[_chatMessageJson()],
          'nextPageToken': 'chat-next',
          'pollingIntervalMillis': 1500,
          'activePoll': _pollMessageJson(),
        })
        ..success(_chatMessageJson())
        ..success(_pollMessageJson())
        ..success(_pollMessageJson(status: 'closed'))
        ..success(<String, Object?>{'deletedMessageId': 'message-1'});

      final page = await client.liveListChatMessages(
        chat: _chat,
        pageToken: 'chat-page',
      );
      final text = await client.liveInsertChatText(
        chat: _chat,
        messageText: 'Welcome to the live stream',
      );
      final poll = await client.liveInsertChatPoll(
        chat: _chat,
        questionText: 'Which product should launch next?',
        options: const <String>['Option A', 'Option B'],
      );
      final closed = await client.liveCloseChatPoll(
        chat: _chat,
        pollMessageId: 'poll-1',
        confirmPollMessageId: 'poll-1',
        confirmStatus: YouTubeLivePollStatus.closed,
      );
      final deleted = await client.liveDeleteChatMessage(
        chat: _chat,
        messageId: 'message-1',
        confirmMessageId: 'message-1',
      );

      expect(page.pollingInterval, const Duration(milliseconds: 1500));
      expect(page.activePoll?.poll?.status, YouTubeLivePollStatus.active);
      expect(text.type, YouTubeLiveChatMessageType.textMessageEvent);
      expect(poll.poll?.options, hasLength(2));
      expect(closed.poll?.status, YouTubeLivePollStatus.closed);
      expect(deleted.messageId, 'message-1');
      expect(transport.posts.first.body['maxResults'], 200);
      expect(transport.operations, <String>[
        'liveListChatMessages',
        'liveInsertChatText',
        'liveInsertChatPoll',
        'liveCloseChatPoll',
        'liveDeleteChatMessage',
      ]);
      expect(transport.operations, isNot(contains('streamList')));
      expect(transport.posts[3].body['confirmStatus'], 'closed');
      expect(transport.posts[4].body['confirmMessageId'], 'message-1');
      _expectPrivileged(credentials, transport, 5);
    },
  );

  test(
    'moderator and ban operations retain exact owner confirmations',
    () async {
      final transport = _FakeTransport();
      final credentials = _FakeCredentials();
      final client = _client(transport: transport, credentials: credentials);
      transport
        ..success(<String, Object?>{
          'items': <Object?>[_moderatorJson()],
          'nextPageToken': 'moderator-next',
        })
        ..success(_moderatorJson())
        ..success(<String, Object?>{'deletedModeratorId': 'moderator-1'})
        ..success(<String, Object?>{
          'banId': 'ban-1',
          'liveChatId': 'live-chat-1',
          'bannedChannelId': 'UCbannedchannel1234567890',
          'type': 'temporary',
          'durationSeconds': 600,
        })
        ..success(<String, Object?>{'deletedBanId': 'ban-1'});

      final page = await client.liveListModerators(
        chat: _chat,
        pageToken: 'moderator-page',
        maxResults: 50,
      );
      final inserted = await client.liveInsertModerator(
        chat: _chat,
        moderatorChannelId: 'UCmoderatorchannel1234567',
      );
      final deletedModerator = await client.liveDeleteModerator(
        chat: _chat,
        moderatorId: 'moderator-1',
        confirmModeratorId: 'moderator-1',
      );
      final ban = await client.liveInsertBan(
        chat: _chat,
        bannedChannelId: 'UCbannedchannel1234567890',
        type: YouTubeLiveBanType.temporary,
        durationSeconds: 600,
      );
      final deletedBan = await client.liveDeleteBan(
        chat: _chat,
        banId: 'ban-1',
        confirmBanId: 'ban-1',
      );

      expect(page.nextPageToken, 'moderator-next');
      expect(inserted.moderatorId, 'moderator-1');
      expect(deletedModerator.moderatorId, 'moderator-1');
      expect(ban.type, YouTubeLiveBanType.temporary);
      expect(deletedBan.banId, 'ban-1');
      expect(transport.operations, <String>[
        'liveListModerators',
        'liveInsertModerator',
        'liveDeleteModerator',
        'liveInsertBan',
        'liveDeleteBan',
      ]);
      expect(transport.posts[2].body['confirmModeratorId'], 'moderator-1');
      expect(transport.posts[4].body['confirmBanId'], 'ban-1');
      _expectPrivileged(credentials, transport, 5);
    },
  );

  test('invalid ban duration fails before credentials or transport', () {
    final transport = _FakeTransport();
    final credentials = _FakeCredentials();
    final client = _client(transport: transport, credentials: credentials);

    expect(
      () => client.liveInsertBan(
        chat: _chat,
        bannedChannelId: 'UCbannedchannel1234567890',
        type: YouTubeLiveBanType.temporary,
        durationSeconds: 59,
      ),
      throwsArgumentError,
    );
    expect(transport.posts, isEmpty);
    expect(credentials.appCheckModes, isEmpty);
  });

  test(
    'monetization reads expose eligibility without claiming access',
    () async {
      final transport = _FakeTransport();
      final credentials = _FakeCredentials();
      final client = _client(transport: transport, credentials: credentials);
      transport
        ..success(<String, Object?>{
          'eligibility': 'provider_approved_channel_only',
          'items': <Object?>[_superChatJson()],
          'nextPageToken': 'super-next',
        })
        ..success(<String, Object?>{
          'eligibility':
              'youtube_representative_and_memberships_enabled_required',
          'items': <Object?>[_memberJson()],
          'nextPageToken': 'member-next',
        })
        ..success(<String, Object?>{
          'eligibility':
              'youtube_representative_and_memberships_enabled_required',
          'items': <Object?>[_membershipLevelJson()],
        });

      final superChats = await client.liveListSuperChatEvents(
        pageToken: 'super-page',
        maxResults: 25,
        language: 'en-IN',
      );
      final members = await client.liveListMembers(
        mode: YouTubeLiveMembershipMode.allCurrent,
        pageToken: 'member-page',
        maxResults: 25,
        memberChannelId: 'UCmemberchannel123456789',
        levelId: 'level-1',
      );
      final levels = await client.liveListMembershipLevels();

      expect(
        superChats.eligibility,
        YouTubeLiveEligibility.providerApprovedChannelOnly,
      );
      expect(superChats.items.single.amountMicros, '2500000');
      expect(
        members.eligibility,
        YouTubeLiveEligibility
            .youtubeRepresentativeAndMembershipsEnabledRequired,
      );
      expect(members.items.single.accessibleLevelIds, <String>[
        'level-1',
        'level-2',
      ]);
      expect(
        levels.eligibility,
        YouTubeLiveEligibility
            .youtubeRepresentativeAndMembershipsEnabledRequired,
      );
      expect(transport.posts[1].body['mode'], 'all_current');
      expect(transport.operations, <String>[
        'liveListSuperChatEvents',
        'liveListMembers',
        'liveListMembershipLevels',
      ]);
      _expectPrivileged(credentials, transport, 3);
    },
  );

  test(
    'Live maps eligibility, status and capability errors precisely',
    () async {
      final transport = _FakeTransport();
      final credentials = _FakeCredentials();
      final client = _client(transport: transport, credentials: credentials);
      transport
        ..failure('eligibility_required', statusCode: 403)
        ..failure('status_conflict', statusCode: 409)
        ..failure('capability_disabled', statusCode: 503);

      await expectLater(
        client.liveListMembers(mode: YouTubeLiveMembershipMode.updates),
        throwsA(isA<YouTubeEligibilityRequiredException>()),
      );
      await expectLater(
        client.liveTransitionBroadcast(
          broadcastId: 'broadcast-1',
          targetStatus: YouTubeLiveBroadcastTransition.live,
          confirmBroadcastId: 'broadcast-1',
          confirmTargetStatus: YouTubeLiveBroadcastTransition.live,
        ),
        throwsA(isA<YouTubeStatusConflictException>()),
      );
      await expectLater(
        client.liveListStreams(),
        throwsA(isA<YouTubeCapabilityUnavailableException>()),
      );
    },
  );
}

final _broadcastWrite = YouTubeLiveBroadcastWrite(
  title: 'Founder private live proof',
  description: '',
  scheduledStartTime: _start,
  scheduledEndTime: _end,
  selfDeclaredMadeForKids: false,
  enableEmbed: true,
  enableDvr: true,
  enableAutoStart: false,
  enableAutoStop: true,
  latencyPreference: YouTubeLiveLatencyPreference.low,
);
const _streamWrite = YouTubeLiveStreamWrite(
  title: 'Founder private stream',
  description: '',
  isReusable: false,
);
final _start = DateTime.utc(2026, 7, 26, 10);
final _end = DateTime.utc(2026, 7, 26, 11);

Map<String, Object?> _capabilities({bool live = false}) {
  return <String, Object?>{
    'environment': 'dev',
    'publicData': false,
    'ownerConnect': false,
    'privateUpload': false,
    'ownerAnalytics': false,
    'publicOrUnlistedUpload': false,
    if (live) 'live': true,
  };
}

Map<String, Object?> _broadcastJson({
  String lifecycle = 'ready',
  String? boundStreamId,
}) {
  return <String, Object?>{
    'broadcastId': 'broadcast-1',
    'channelId': 'UCabcdefghijklmnopqrstuv',
    'title': 'Founder private live proof',
    'description': '',
    'scheduledStartTime': '2026-07-26T10:00:00.000Z',
    'scheduledEndTime': '2026-07-26T11:00:00.000Z',
    'liveChatId': 'live-chat-1',
    'lifeCycleStatus': lifecycle,
    'privacyStatus': 'private',
    'recordingStatus': 'notRecording',
    'selfDeclaredMadeForKids': false,
    'boundStreamId': ?boundStreamId,
    'enableEmbed': true,
    'enableDvr': true,
    'recordFromStart': true,
    'enableAutoStart': false,
    'enableAutoStop': true,
    'latencyPreference': 'low',
  };
}

Map<String, Object?> _streamJson({String status = 'ready'}) {
  return <String, Object?>{
    'streamId': 'stream-1',
    'channelId': 'UCabcdefghijklmnopqrstuv',
    'title': 'Founder private stream',
    'description': '',
    'streamStatus': status,
    'resolution': '1080p',
    'frameRate': '60fps',
    'ingestionType': 'rtmp',
    'isReusable': false,
    'ingestionAddress': 'rtmp://a.rtmp.youtube.com/live2',
    'backupIngestionAddress': 'rtmp://b.rtmp.youtube.com/live2',
    'rtmpsIngestionAddress': 'rtmps://a.rtmps.youtube.com/live2',
    'rtmpsBackupIngestionAddress': 'rtmps://b.rtmps.youtube.com/live2',
    'streamName': 'secret-stream-key',
  };
}

Map<String, Object?> _chatMessageJson() {
  return <String, Object?>{
    'messageId': 'message-1',
    'liveChatId': 'live-chat-1',
    'type': 'textMessageEvent',
    'publishedAt': '2026-07-25T12:00:00.000Z',
    'displayMessage': 'Welcome to the live stream',
    'textMessage': 'Welcome to the live stream',
    'author': <String, Object?>{
      'channelId': 'UCauthorchannel1234567890',
      'displayName': 'Live viewer',
      'profileImageUrl': 'https://yt3.ggpht.com/a/viewer',
      'isVerified': false,
      'isChatOwner': false,
      'isChatSponsor': true,
      'isChatModerator': false,
    },
  };
}

Map<String, Object?> _pollMessageJson({String status = 'active'}) {
  return <String, Object?>{
    'messageId': 'poll-1',
    'liveChatId': 'live-chat-1',
    'type': 'pollEvent',
    'publishedAt': '2026-07-25T12:01:00.000Z',
    'displayMessage': 'Which product should launch next?',
    'poll': <String, Object?>{
      'questionText': 'Which product should launch next?',
      'status': status,
      'options': <Object?>[
        <String, Object?>{'optionText': 'Option A', 'tally': '4'},
        <String, Object?>{'optionText': 'Option B', 'tally': '7'},
      ],
    },
  };
}

Map<String, Object?> _moderatorJson() {
  return <String, Object?>{
    'moderatorId': 'moderator-1',
    'liveChatId': 'live-chat-1',
    'channelId': 'UCmoderatorchannel1234567',
    'displayName': 'Moderator',
    'profileImageUrl': 'https://yt3.ggpht.com/a/moderator',
  };
}

Map<String, Object?> _superChatJson() {
  return <String, Object?>{
    'eventId': 'super-1',
    'supporterChannelId': 'UCsupporterchannel1234567',
    'supporterDisplayName': 'Supporter',
    'supporterProfileImageUrl': 'https://yt3.ggpht.com/a/supporter',
    'createdAt': '2026-07-25T12:02:00.000Z',
    'amountMicros': '2500000',
    'currency': 'INR',
    'displayString': '₹2.50',
    'commentText': 'Great stream',
    'isSuperStickerEvent': false,
  };
}

Map<String, Object?> _memberJson() {
  return <String, Object?>{
    'creatorChannelId': 'UCabcdefghijklmnopqrstuv',
    'memberChannelId': 'UCmemberchannel123456789',
    'memberDisplayName': 'Member',
    'memberProfileImageUrl': 'https://yt3.ggpht.com/a/member',
    'highestAccessibleLevelId': 'level-2',
    'highestAccessibleLevelDisplayName': 'Gold',
    'accessibleLevelIds': <String>['level-1', 'level-2'],
  };
}

Map<String, Object?> _membershipLevelJson() {
  return <String, Object?>{
    'levelId': 'level-2',
    'creatorChannelId': 'UCabcdefghijklmnopqrstuv',
    'displayName': 'Gold',
  };
}

YouTubePrivateDevClient _client({
  required _FakeTransport transport,
  required _FakeCredentials credentials,
  bool liveEnabled = true,
}) {
  return YouTubePrivateDevClient.forTesting(
    providerEndpoint: Uri.parse(_endpoint),
    transport: transport,
    credentials: credentials,
    proofEnabled: true,
    firebaseProjectId: youtubePrivateDevProjectId,
    liveEnabled: liveEnabled,
    requestId: () => 'live-request-fixed',
  );
}

void _expectPrivileged(
  _FakeCredentials credentials,
  _FakeTransport transport,
  int count,
) {
  expect(credentials.idTokenCalls, count);
  expect(
    credentials.appCheckModes,
    List<YouTubeAppCheckTokenMode>.filled(
      count,
      YouTubeAppCheckTokenMode.limitedUse,
    ),
  );
  expect(
    transport.posts.every(
      (request) =>
          request.headers['authorization'] == 'Bearer firebase-id-token' &&
          request.headers['x-firebase-appcheck'] == 'limited-app-check',
    ),
    isTrue,
  );
}

class _FakeCredentials implements YouTubeCredentialSource {
  final appCheckModes = <YouTubeAppCheckTokenMode>[];
  var idTokenCalls = 0;

  @override
  Future<String> appCheckToken(YouTubeAppCheckTokenMode mode) async {
    appCheckModes.add(mode);
    return mode == YouTubeAppCheckTokenMode.limitedUse
        ? 'limited-app-check'
        : 'standard-app-check';
  }

  @override
  Future<String> firebaseIdToken() async {
    idTokenCalls += 1;
    return 'firebase-id-token';
  }
}

class _PostRequest {
  const _PostRequest({required this.headers, required this.body});

  final Map<String, String> headers;
  final Map<String, Object?> body;
}

class _FakeTransport implements YouTubeHttpTransport {
  final _responses = <YouTubeHttpResponse>[];
  final posts = <_PostRequest>[];

  List<String> get operations => posts
      .map((request) => request.body['operation']! as String)
      .toList(growable: false);

  void success(Object? data) {
    _responses.add(
      YouTubeHttpResponse(
        statusCode: 200,
        headers: const <String, String>{},
        body: jsonEncode(<String, Object?>{'ok': true, 'data': data}),
      ),
    );
  }

  void failure(String code, {required int statusCode}) {
    _responses.add(
      YouTubeHttpResponse(
        statusCode: statusCode,
        headers: const <String, String>{},
        body: jsonEncode(<String, Object?>{
          'ok': false,
          'error': <String, Object?>{
            'code': code,
            'message': 'Redacted provider failure.',
            'retryable': false,
          },
        }),
      ),
    );
  }

  @override
  Future<YouTubeHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    posts.add(
      _PostRequest(
        headers: Map<String, String>.unmodifiable(headers),
        body: Map<String, Object?>.unmodifiable(body),
      ),
    );
    return _responses.removeAt(0);
  }

  @override
  Future<YouTubeHttpResponse> putStream(
    Uri uri, {
    required Map<String, String> headers,
    required Stream<List<int>> body,
    required int contentLength,
  }) {
    throw UnsupportedError('Live client does not proxy media bytes.');
  }
}
