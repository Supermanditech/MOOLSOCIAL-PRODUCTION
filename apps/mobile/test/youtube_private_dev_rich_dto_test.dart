import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_app_check.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_client.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_transport.dart';

void main() {
  group('YouTube provider rich DTOs', () {
    test('preserves public video policy, metadata, caption and live truth', () {
      final page = YouTubeVideoPage.fromJson(<String, Object?>{
        'items': <Object?>[_richVideoJson()],
        'filtered': <String, Object?>{
          'total': 2,
          'reasons': <String, Object?>{
            'region_restricted': 1,
            'not_embeddable': 1,
          },
        },
      });

      final video = page.items.single;
      expect(video.source, YouTubeProviderSource.youtube);
      expect(video.categoryId, '22');
      expect(video.tags, <String>['craft', 'india']);
      expect(video.defaultLanguage, 'en-IN');
      expect(video.localized?.description, 'Localized description');
      expect(video.captionAvailable, isTrue);
      expect(video.definition, YouTubeVideoDefinition.hd);
      expect(video.projection, YouTubeVideoProjection.rectangular);
      expect(video.regionRestriction?.allowed, <String>['IN', 'US']);
      expect(video.availability?.broadcastState, YouTubeBroadcastState.live);
      expect(video.liveStreamingDetails?.concurrentViewers, '48');
      expect(
        video.liveStreamingDetails?.actualStartTime,
        DateTime.parse('2026-07-25T10:00:00.000Z'),
      );
      expect(page.filtered?.total, 2);
      expect(
        page.filtered?.reasons[YouTubePublicVideoUnavailableReason
            .regionRestricted],
        1,
      );
    });

    test('rejects conflicting restrictions and fabricated attribution', () {
      final malformedVideo = _richVideoJson()
        ..['regionRestriction'] = <String, Object?>{
          'allowed': <String>['IN'],
          'blocked': <String>['US'],
        };
      expect(
        () => YouTubeVideoSummary.fromJson(malformedVideo),
        throwsFormatException,
      );
      expect(
        () => YouTubeOwnerAttribution.fromJson(<String, Object?>{
          'source': 'moolsocial',
          'channelId': 'channel-1',
          'channelTitle': 'Channel',
        }),
        throwsFormatException,
      );
      expect(
        () => YouTubeVideoSummary.fromJson(
          _richVideoJson()..['publishedAt'] = 'not-a-timestamp',
        ),
        throwsFormatException,
      );
      expect(
        () => YouTubeConnectionStart.fromJson(<String, Object?>{
          'authorizationUrl': '/relative/oauth',
          'expiresAt': '2026-07-25T10:00:00.000Z',
        }),
        throwsFormatException,
      );
    });

    test('preserves verification and reconnect timing', () {
      final connected =
          YouTubeConnectionStatus.fromJson(<String, Object?>{
                'connected': true,
                'channelId': 'channel-1',
                'channelTitle': 'Channel',
                'grantedScopes': <String>['scope-readonly'],
                'lastVerifiedAt': '2026-07-25T10:00:00.000Z',
                'nextVerificationDueAt': '2026-08-24T10:00:00.000Z',
                'verificationState': 'current',
              })
              as YouTubeConnected;
      final disconnected =
          YouTubeConnectionStatus.fromJson(<String, Object?>{
                'connected': false,
                'lastVerifiedAt': '2026-07-24T10:00:00.000Z',
                'nextVerificationDueAt': '2026-07-25T10:00:00.000Z',
                'verificationState': 'reconnect_required',
              })
              as YouTubeDisconnected;

      expect(
        connected.nextVerificationDueAt,
        DateTime.parse('2026-08-24T10:00:00.000Z'),
      );
      expect(
        disconnected.verificationState,
        YouTubeConnectionVerificationState.reconnectRequired,
      );
      expect(
        () => YouTubeConnectionStatus.fromJson(<String, Object?>{
          'connected': true,
          'channelId': 'channel-1',
          'channelTitle': 'Channel',
          'grantedScopes': <String>['scope-readonly'],
          'verificationState': 'current',
        }),
        throwsFormatException,
      );
    });
  });

  group('YouTube provider Phase-A client parity', () {
    late _FakeTransport transport;
    late _FakeCredentials credentials;
    late YouTubePrivateDevClient client;

    setUp(() {
      transport = _FakeTransport();
      credentials = _FakeCredentials();
      client = YouTubePrivateDevClient.forTesting(
        providerEndpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
          'youtubeProvider',
        ),
        transport: transport,
        credentials: credentials,
        proofEnabled: true,
        firebaseProjectId: youtubePrivateDevProjectId,
        requestId: () => 'rich-dto-request',
      );
    });

    test('exposes batch statistics and every public catalogue owner', () async {
      transport
        ..queue(<String, Object?>{
          'items': <Object?>[
            <String, Object?>{
              'videoId': 'abc123XYZ09',
              'publishTime': '2026-07-25T08:00:00.000Z',
              'viewCount': '12',
              'duration': 'PT1M',
              'durationMillis': '60000',
            },
          ],
          'summary': <String, Object?>{
            'requestedVideoCount': '2',
            'succeededVideoCount': '1',
            'failedVideoCount': '1',
            'failedVideoIds': <String>['missingXYZ1'],
          },
        })
        ..queue(_channelJson())
        ..queue(_channelJson())
        ..queue(_playlistJson())
        ..queue(<String, Object?>{
          'items': <Object?>[_playlistJson()],
          'nextPageToken': 'playlist-next',
        })
        ..queue(<Object?>[
          <String, Object?>{'regionCode': 'IN', 'name': 'India'},
        ])
        ..queue(<Object?>[
          <String, Object?>{'languageCode': 'en-IN', 'name': 'English India'},
        ])
        ..queue(<Object?>[
          <String, Object?>{
            'categoryId': '22',
            'title': 'People & Blogs',
            'assignable': true,
          },
        ]);

      final batch = await client.batchVideoStatistics(<String>[
        'abc123XYZ09',
        'missingXYZ1',
      ]);
      final channel = await client.channelDetails(channelId: 'channel-1');
      final handle = await client.channelByHandle(handle: '@channel');
      final playlist = await client.playlistDetails(playlistId: 'PL-1');
      final playlists = await client.channelPlaylists(
        channelId: 'channel-1',
        pageToken: 'page-1',
        maxResults: 20,
      );
      final regions = await client.regions();
      final languages = await client.languages();
      final categories = await client.videoCategories(regionCode: 'IN');

      expect(batch.summary.failedVideoIds, <String>['missingXYZ1']);
      expect(channel.statistics.subscriberCount, '100');
      expect(handle.source, YouTubeProviderSource.youtube);
      expect(playlist.localized?.title, 'Localized playlist');
      expect(playlists.nextPageToken, 'playlist-next');
      expect(regions.single.regionCode, 'IN');
      expect(languages.single.languageCode, 'en-IN');
      expect(categories.single.assignable, isTrue);
      expect(transport.operations, <String>[
        'publicBatchVideoStatistics',
        'publicChannelDetails',
        'publicChannelByHandle',
        'publicPlaylistDetails',
        'publicChannelPlaylists',
        'publicRegions',
        'publicLanguages',
        'publicVideoCategories',
      ]);
      expect(transport.bodies[4], <String, Object?>{
        'operation': 'publicChannelPlaylists',
        'channelId': 'channel-1',
        'pageToken': 'page-1',
        'maxResults': 20,
      });
      expect(credentials.idTokenCalls, 0);
      expect(
        credentials.appCheckModes,
        List<YouTubeAppCheckTokenMode>.filled(
          8,
          YouTubeAppCheckTokenMode.standard,
        ),
      );
    });

    test(
      'preserves full comment text, reply state and YouTube attribution',
      () async {
        final top = _commentJson(
          'comment-top',
          text: 'Complete public comment',
        );
        final reply = _commentJson(
          'comment-reply',
          text: 'Complete reply',
          parentId: 'comment-top',
        );
        transport
          ..queue(<String, Object?>{
            'attribution': _commentAttributionJson(),
            'items': <Object?>[
              <String, Object?>{
                'threadId': 'thread-1',
                'videoId': 'abc123XYZ09',
                'channelId': 'channel-1',
                'topLevelComment': top,
                'replies': <Object?>[reply],
                'totalReplyCount': 2,
                'includedReplyCount': 1,
                'repliesComplete': false,
                'isPublic': true,
              },
            ],
            'nextPageToken': 'thread-next',
          })
          ..queue(<String, Object?>{
            'attribution': <String, Object?>{
              ..._commentAttributionJson(),
              'threadId': 'thread-1',
              'parentCommentId': 'comment-top',
            },
            'items': <Object?>[reply],
          });

        final threads = await client.commentThreads(
          videoId: 'abc123XYZ09',
          regionCode: 'IN',
          pageToken: 'comments-1',
          maxResults: 25,
          order: YouTubeCommentOrder.relevance,
        );
        final replies = await client.commentReplies(
          videoId: 'abc123XYZ09',
          threadId: 'thread-1',
          parentCommentId: 'comment-top',
          regionCode: 'IN',
        );

        expect(threads.attribution.source, YouTubeProviderSource.youtube);
        expect(
          threads.items.single.topLevelComment.textDisplay,
          'Complete public comment',
        );
        expect(threads.items.single.repliesComplete, isFalse);
        expect(replies.attribution.parentCommentId, 'comment-top');
        expect(transport.bodies.first['order'], 'relevance');
        expect(credentials.idTokenCalls, 0);
      },
    );

    test('exposes owner inventory using Auth and standard App Check', () async {
      transport
        ..queue(<String, Object?>{
          'attribution': _ownerAttributionJson(),
          'items': <Object?>[
            <String, Object?>{
              'state': 'available',
              'playlistItemId': 'playlist-item-1',
              'playlistPublishedAt': '2026-07-25T08:00:00.000Z',
              'position': 0,
              'video': _richVideoJson(),
            },
            <String, Object?>{
              'state': 'unavailable',
              'playlistItemId': 'playlist-item-2',
              'videoId': 'missingXYZ1',
              'position': 1,
            },
          ],
          'nextPageToken': 'owner-videos-next',
        })
        ..queue(<String, Object?>{
          'attribution': _ownerAttributionJson(),
          'items': <Object?>[
            <String, Object?>{
              'subscriptionId': 'subscription-1',
              'channelId': 'subscribed-channel',
              'channelTitle': 'Subscribed Channel',
              'description': '',
              'publishedAt': '2026-07-24T08:00:00.000Z',
            },
          ],
        })
        ..queue(<String, Object?>{
          'attribution': _ownerAttributionJson(),
          'items': <Object?>[
            <String, Object?>{
              'playlistId': 'PL-owner',
              'title': 'Owner playlist',
              'description': '',
              'publishedAt': '2026-07-24T08:00:00.000Z',
              'channelId': 'channel-1',
              'channelTitle': 'MoolSocial Dev Channel',
              'itemCount': 4,
              'privacyStatus': 'private',
            },
          ],
        });

      final videos = await client.ownerVideos(
        pageToken: 'owner-page',
        maxResults: 10,
      );
      final subscriptions = await client.ownerSubscriptions(
        maxResults: 20,
        order: YouTubeOwnerSubscriptionOrder.alphabetical,
      );
      final playlists = await client.ownerPlaylists(maxResults: 20);

      expect(videos.items.first, isA<YouTubeOwnerAvailableVideo>());
      expect(videos.items.last, isA<YouTubeOwnerUnavailableVideo>());
      expect(
        (videos.items.first as YouTubeOwnerAvailableVideo)
            .video
            .captionAvailable,
        isTrue,
      );
      expect(subscriptions.items.single.channelTitle, 'Subscribed Channel');
      expect(playlists.items.single.privacyStatus, 'private');
      expect(transport.operations, <String>[
        'ownerVideos',
        'ownerSubscriptions',
        'ownerPlaylists',
      ]);
      expect(transport.bodies[1]['order'], 'alphabetical');
      expect(credentials.idTokenCalls, 3);
      expect(credentials.appCheckModes, <YouTubeAppCheckTokenMode>[
        YouTubeAppCheckTokenMode.standard,
        YouTubeAppCheckTokenMode.standard,
        YouTubeAppCheckTokenMode.standard,
      ]);
    });
  });
}

Map<String, Object?> _richVideoJson() {
  return <String, Object?>{
    'videoId': 'abc123XYZ09',
    'title': 'Made across India',
    'channelId': 'channel-1',
    'channelTitle': 'MoolSocial Dev Channel',
    'publishedAt': '2026-07-25T08:00:00.000Z',
    'description': 'Full provider description.',
    'thumbnail': <String, Object?>{
      'url': 'https://i.ytimg.com/vi/abc123XYZ09/maxresdefault.jpg',
      'width': 1280,
      'height': 720,
    },
    'categoryId': '22',
    'tags': <String>['craft', 'india'],
    'defaultLanguage': 'en-IN',
    'defaultAudioLanguage': 'hi-IN',
    'localized': <String, Object?>{
      'title': 'Localized title',
      'description': 'Localized description',
    },
    'duration': 'PT1M2S',
    'captionAvailable': true,
    'definition': 'hd',
    'licensedContent': false,
    'projection': 'rectangular',
    'regionRestriction': <String, Object?>{
      'allowed': <String>['IN', 'US'],
    },
    'viewCount': '12',
    'likeCount': '2',
    'commentCount': '1',
    'embeddable': true,
    'privacyStatus': 'public',
    'uploadStatus': 'processed',
    'availability': <String, Object?>{
      'state': 'available',
      'regionCode': 'IN',
      'broadcastState': 'live',
      'syndication': 'search_filter_confirmed',
    },
    'liveStreamingDetails': <String, Object?>{
      'actualStartTime': '2026-07-25T10:00:00.000Z',
      'concurrentViewers': '48',
    },
  };
}

Map<String, Object?> _channelJson() {
  return <String, Object?>{
    'channelId': 'channel-1',
    'title': 'MoolSocial Dev Channel',
    'description': '',
    'publishedAt': '2026-07-01T08:00:00.000Z',
    'customUrl': '@channel',
    'country': 'IN',
    'uploadsPlaylistId': 'UU-channel-1',
    'thumbnail': <String, Object?>{
      'url': 'https://yt3.ggpht.com/channel-image',
      'width': 800,
      'height': 800,
    },
    'statistics': <String, Object?>{
      'viewCount': '1000',
      'subscriberCount': '100',
      'hiddenSubscriberCount': false,
      'videoCount': '8',
    },
    'topicCategories': <String>['https://en.wikipedia.org/wiki/Technology'],
  };
}

Map<String, Object?> _playlistJson() {
  return <String, Object?>{
    'playlistId': 'PL-1',
    'title': 'Public playlist',
    'description': '',
    'publishedAt': '2026-07-01T08:00:00.000Z',
    'channelId': 'channel-1',
    'channelTitle': 'MoolSocial Dev Channel',
    'itemCount': 3,
    'privacyStatus': 'public',
    'defaultLanguage': 'en-IN',
    'localized': <String, Object?>{
      'title': 'Localized playlist',
      'description': '',
    },
  };
}

Map<String, Object?> _commentJson(
  String id, {
  required String text,
  String? parentId,
}) {
  return <String, Object?>{
    'commentId': id,
    'textDisplay': text,
    'textFormat': 'plainText',
    'author': <String, Object?>{
      'displayName': 'YouTube user',
      'profileImageUrl': 'https://yt3.ggpht.com/avatar',
      'channelId': 'author-channel',
      'channelUrl': 'https://www.youtube.com/channel/author-channel',
    },
    'associatedChannelId': 'channel-1',
    'likeCount': 2,
    'publishedAt': '2026-07-25T08:00:00.000Z',
    'updatedAt': '2026-07-25T08:00:00.000Z',
    'parentId': ?parentId,
  };
}

Map<String, Object?> _commentAttributionJson() {
  return <String, Object?>{
    'source': 'youtube',
    'videoId': 'abc123XYZ09',
    'videoTitle': 'Made across India',
    'channelId': 'channel-1',
    'channelTitle': 'MoolSocial Dev Channel',
  };
}

Map<String, Object?> _ownerAttributionJson() {
  return <String, Object?>{
    'source': 'youtube',
    'channelId': 'channel-1',
    'channelTitle': 'MoolSocial Dev Channel',
  };
}

class _FakeCredentials implements YouTubeCredentialSource {
  final appCheckModes = <YouTubeAppCheckTokenMode>[];
  var idTokenCalls = 0;

  @override
  Future<String> appCheckToken(YouTubeAppCheckTokenMode mode) async {
    appCheckModes.add(mode);
    return 'app-check';
  }

  @override
  Future<String> firebaseIdToken() async {
    idTokenCalls += 1;
    return 'firebase-id-token';
  }
}

class _FakeTransport implements YouTubeHttpTransport {
  final _responses = <Object?>[];
  final bodies = <Map<String, Object?>>[];

  List<String> get operations => bodies
      .map((body) => body['operation'])
      .whereType<String>()
      .toList(growable: false);

  void queue(Object? data) => _responses.add(data);

  @override
  Future<YouTubeHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    bodies.add(Map.unmodifiable(body));
    return YouTubeHttpResponse(
      statusCode: 200,
      headers: const <String, String>{},
      body: jsonEncode(<String, Object?>{
        'ok': true,
        'data': _responses.removeAt(0),
      }),
    );
  }

  @override
  Future<YouTubeHttpResponse> putStream(
    Uri uri, {
    required Map<String, String> headers,
    required Stream<List<int>> body,
    required int contentLength,
  }) {
    throw UnimplementedError();
  }
}
