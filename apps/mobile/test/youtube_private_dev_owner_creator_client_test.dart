import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_app_check.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_client.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_transport.dart';

void main() {
  group('owner actions typed client', () {
    late _RecordingTransport transport;
    late _RecordingCredentials credentials;
    late YouTubePrivateDevClient client;

    setUp(() {
      transport = _RecordingTransport();
      credentials = _RecordingCredentials();
      client = _client(transport, credentials);
    });

    test('covers every owner action with replay-protected requests', () async {
      transport.queue(_rating('like'));
      expect(
        (await client.ownerGetRating(videoId: 'video123')).rating,
        YouTubeOwnerRating.like,
      );

      transport.queue(_rating('dislike'));
      expect(
        (await client.ownerSetRating(
          videoId: 'video123',
          rating: YouTubeOwnerRating.dislike,
        )).rating,
        YouTubeOwnerRating.dislike,
      );

      transport.queue(_rating('none'));
      expect(
        (await client.ownerRemoveRating(videoId: 'video123')).rating,
        YouTubeOwnerRating.none,
      );

      transport.queue(<String, Object?>{
        'threadId': 'thread-1',
        'comment': _comment(),
      });
      expect(
        (await client.ownerCreateComment(
          videoId: 'video123',
          text: 'A useful comment',
        )).threadId,
        'thread-1',
      );

      transport.queue(<String, Object?>{'comment': _comment(parent: true)});
      expect(
        (await client.ownerCreateReply(
          parentCommentId: 'comment-parent',
          text: 'A useful reply',
        )).comment.parentId,
        'comment-parent',
      );

      transport.queue(<String, Object?>{'comment': _comment()});
      expect(
        (await client.ownerUpdateComment(
          commentId: 'comment-1',
          text: 'Updated comment',
        )).comment.commentId,
        'comment-1',
      );

      transport.queue(<String, Object?>{
        'deleted': true,
        'commentId': 'comment-1',
      });
      expect(
        (await client.ownerDeleteComment(commentId: 'comment-1')).resourceId,
        'comment-1',
      );

      transport.queue(<String, Object?>{
        'commentId': 'comment-1',
        'moderationStatus': 'rejected',
        'authorBanned': true,
      });
      expect(
        (await client.ownerSetCommentModeration(
          commentId: 'comment-1',
          moderationStatus: YouTubeOwnerCommentModerationStatus.rejected,
          banAuthor: true,
        )).authorBanned,
        isTrue,
      );

      transport.queue(<String, Object?>{
        'subscriptionId': 'subscription-1',
        'actorChannelId': 'channel-owner',
        'targetChannelId': 'channel-target',
      });
      expect(
        (await client.ownerSubscribe(
          channelId: 'channel-target',
        )).targetChannelId,
        'channel-target',
      );

      transport.queue(<String, Object?>{
        'deleted': true,
        'subscriptionId': 'subscription-1',
      });
      await client.ownerUnsubscribe(subscriptionId: 'subscription-1');

      transport.queue(_playlistMutation());
      expect(
        (await client.ownerCreatePlaylist(
          title: 'Useful playlist',
          description: 'Saved videos',
          privacyStatus: YouTubePlaylistPrivacyStatus.private,
        )).privacyStatus,
        YouTubePlaylistPrivacyStatus.private,
      );

      transport.queue(_playlistMutation(title: 'Updated playlist'));
      await client.ownerUpdatePlaylist(
        playlistId: 'playlist-1',
        title: 'Updated playlist',
        privacyStatus: YouTubePlaylistPrivacyStatus.unlisted,
      );

      transport.queue(<String, Object?>{
        'deleted': true,
        'playlistId': 'playlist-1',
      });
      await client.ownerDeletePlaylist(playlistId: 'playlist-1');

      transport.queue(_playlistItem(position: 2));
      expect(
        (await client.ownerCreatePlaylistItem(
          playlistId: 'playlist-1',
          videoId: 'video123',
          position: 2,
        )).position,
        2,
      );

      transport.queue(_playlistItem(position: 4));
      await client.ownerReorderPlaylistItem(
        playlistItemId: 'playlist-item-1',
        position: 4,
      );

      transport.queue(<String, Object?>{
        'deleted': true,
        'playlistItemId': 'playlist-item-1',
      });
      await client.ownerDeletePlaylistItem(playlistItemId: 'playlist-item-1');

      transport.queue(<String, Object?>{
        'videoId': 'video123',
        'actorChannelId': 'channel-owner',
        'title': 'Updated video',
        'description': '',
        'categoryId': '22',
        'tags': <String>['local', 'useful'],
        'privacyStatus': 'private',
      });
      expect(
        (await client.ownerUpdateVideoMetadata(
          videoId: 'video123',
          title: 'Updated video',
          categoryId: '22',
          tags: <String>['local', 'useful'],
        )).tags,
        <String>['local', 'useful'],
      );

      transport.queue(<String, Object?>{
        'deleted': true,
        'videoId': 'video123',
      });
      await client.ownerDeleteVideo(
        videoId: 'video123',
        confirmVideoId: 'video123',
      );

      expect(transport.operations, <String>[
        'ownerGetRating',
        'ownerSetRating',
        'ownerRemoveRating',
        'ownerCreateComment',
        'ownerCreateReply',
        'ownerUpdateComment',
        'ownerDeleteComment',
        'ownerSetCommentModeration',
        'ownerSubscribe',
        'ownerUnsubscribe',
        'ownerCreatePlaylist',
        'ownerUpdatePlaylist',
        'ownerDeletePlaylist',
        'ownerCreatePlaylistItem',
        'ownerReorderPlaylistItem',
        'ownerDeletePlaylistItem',
        'ownerUpdateVideoMetadata',
        'ownerDeleteVideo',
      ]);
      _expectReplayProtected(transport, credentials);
      expect(transport.requests[1].body['rating'], 'dislike');
      expect(transport.requests[7].body['moderationStatus'], 'rejected');
      expect(transport.requests[17].body['confirmVideoId'], 'video123');
    });

    test('rejects none as a set-rating value before network use', () async {
      expect(
        () => client.ownerSetRating(
          videoId: 'video123',
          rating: YouTubeOwnerRating.none,
        ),
        throwsArgumentError,
      );
      expect(transport.requests, isEmpty);
    });
  });

  group('creator assets typed client', () {
    late _RecordingTransport transport;
    late _RecordingCredentials credentials;
    late YouTubePrivateDevClient client;

    setUp(() {
      transport = _RecordingTransport();
      credentials = _RecordingCredentials();
      client = _client(transport, credentials);
    });

    test('covers every creator-assets operation and typed result', () async {
      transport.queue(_assetSession('thumbnail'));
      expect(
        (await client.creatorBeginThumbnailSet(
          videoId: 'video123',
          contentType: 'image/png',
          contentLength: 1000,
        )).resourceKind,
        YouTubeCreatorAssetKind.thumbnail,
      );

      transport.queue(<String, Object?>{
        'videoId': 'video123',
        'items': <Object?>[_caption()],
      });
      expect(
        (await client.creatorListCaptions(
          videoId: 'video123',
        )).items.single.status,
        YouTubeCaptionStatus.serving,
      );

      transport.queue(<String, Object?>{
        'captionId': 'caption-1',
        'videoId': 'video123',
        'format': 'vtt',
        'translatedLanguage': 'hi',
        'encoding': 'base64',
        'data': 'V0VCVlRU',
        'byteLimit': 1048576,
        'contentType': 'text/vtt',
      });
      expect(
        (await client.creatorDownloadCaption(
          videoId: 'video123',
          captionId: 'caption-1',
          format: YouTubeCaptionFormat.vtt,
          translatedLanguage: 'hi',
        )).translatedLanguage,
        'hi',
      );

      transport.queue(_assetSession('caption'));
      await client.creatorBeginCaptionInsert(
        videoId: 'video123',
        language: 'en',
        isDraft: true,
        contentType: 'text/vtt',
        contentLength: 800,
        name: 'English',
      );

      transport.queue(_caption(isDraft: false));
      expect(
        (await client.creatorUpdateCaptionDraft(
          videoId: 'video123',
          captionId: 'caption-1',
          isDraft: false,
        )).isDraft,
        isFalse,
      );

      transport.queue(_assetSession('caption'));
      await client.creatorBeginCaptionReplacement(
        videoId: 'video123',
        captionId: 'caption-1',
        isDraft: false,
        contentType: 'text/vtt',
        contentLength: 900,
      );

      transport.queue(<String, Object?>{
        'deleted': true,
        'captionId': 'caption-1',
      });
      await client.creatorDeleteCaption(
        videoId: 'video123',
        captionId: 'caption-1',
      );

      transport.queue(<String, Object?>{
        'channelId': 'channel-owner',
        'branding': <String, Object?>{
          'country': 'IN',
          'description': 'Connected channel',
        },
      });
      final branding = await client.creatorUpdateChannelBranding(
        patch:
            YouTubeChannelBrandingPatch(<YouTubeChannelBrandingField, String?>{
              YouTubeChannelBrandingField.country: 'IN',
              YouTubeChannelBrandingField.description: 'Connected channel',
            }),
      );
      expect(branding.branding.country, 'IN');

      transport.queue(<String, Object?>{
        'channelId': 'channel-owner',
        'items': <Object?>[_channelSection()],
      });
      expect(
        (await client.creatorListChannelSections()).items.single.type,
        YouTubeChannelSectionType.singlePlaylist,
      );

      transport.queue(_channelSection());
      await client.creatorInsertChannelSection(section: _sectionInput());

      transport.queue(_channelSection(position: 2));
      await client.creatorUpdateChannelSection(
        sectionId: 'section-1',
        section: _sectionInput(position: 2),
      );

      transport.queue(<String, Object?>{
        'deleted': true,
        'sectionId': 'section-1',
      });
      await client.creatorDeleteChannelSection(sectionId: 'section-1');

      transport.queue(_assetSession('channelBanner'));
      await client.creatorBeginChannelBannerInsert(
        contentType: 'image/png',
        contentLength: 2000,
        width: 2560,
        height: 1440,
      );

      transport.queue(<String, Object?>{
        'channelId': 'channel-owner',
        'bannerApplied': true,
      });
      expect(
        (await client.creatorApplyChannelBanner(
          bannerExternalUrl: 'https://yt3.googleusercontent.com/banner-value',
        )).action,
        'bannerApplied',
      );

      transport.queue(_assetSession('watermark', encoding: 'empty'));
      await client.creatorBeginWatermarkSet(
        contentType: 'image/png',
        contentLength: 1000,
        width: 300,
        height: 300,
        offsetMs: 0,
        durationMs: 10000,
        offsetFrom: YouTubeWatermarkOffsetFrom.start,
        corner: YouTubeWatermarkCorner.bottomRight,
      );

      transport.queue(<String, Object?>{
        'channelId': 'channel-owner',
        'watermarkUnset': true,
      });
      await client.creatorUnsetWatermark();

      transport.queue(<String, Object?>{
        'playlistId': 'playlist-1',
        'items': <Object?>[_playlistImage()],
        'nextPageToken': 'next-page',
      });
      expect(
        (await client.creatorListPlaylistImages(
          playlistId: 'playlist-1',
          maxResults: 5,
        )).items.single.width,
        800,
      );

      transport.queue(_assetSession('playlistImage'));
      await client.creatorBeginPlaylistImageInsert(
        playlistId: 'playlist-1',
        contentType: 'image/png',
        contentLength: 1000,
        width: 800,
        height: 800,
      );

      transport.queue(_assetSession('playlistImage'));
      await client.creatorBeginPlaylistImageUpdate(
        playlistId: 'playlist-1',
        playlistImageId: 'playlist-image-1',
        contentType: 'image/png',
        contentLength: 1200,
        width: 900,
        height: 900,
      );

      transport.queue(<String, Object?>{
        'deleted': true,
        'playlistImageId': 'playlist-image-1',
        'playlistId': 'playlist-1',
      });
      final imageDelete = await client.creatorDeletePlaylistImage(
        playlistId: 'playlist-1',
        playlistImageId: 'playlist-image-1',
      );
      expect(imageDelete.parentResourceId, 'playlist-1');

      transport.queue(<String, Object?>{
        'language': 'en',
        'items': <Object?>[
          <String, Object?>{
            'reasonId': 'reason-1',
            'label': 'Reason',
            'secondaryReasons': <Object?>[
              <String, Object?>{
                'reasonId': 'reason-child',
                'label': 'More detail',
              },
            ],
          },
        ],
      });
      expect(
        (await client.creatorListVideoAbuseReasons(
          language: 'en',
        )).items.single.secondaryReasons.single.reasonId,
        'reason-child',
      );

      transport.queue(<String, Object?>{
        'reported': true,
        'videoId': 'video123',
        'reasonId': 'reason-1',
      });
      await client.creatorReportVideoAbuse(
        videoId: 'video123',
        reasonId: 'reason-1',
        confirmVideoId: 'video123',
        confirmReasonId: 'reason-1',
        secondaryReasonId: 'reason-child',
        comments: 'Review this video',
        language: 'en',
      );

      transport.queue(<String, Object?>{
        'submitted': true,
        'subjectTypeId': 'youtube.channel',
        'subjectId': 'channel-1',
        'abuseTypeIds': <String>['spam', 'impersonation'],
      });
      final generalReport = await client.creatorInsertAbuseReport(
        subjectTypeId: 'youtube.channel',
        subjectId: 'channel-1',
        abuseTypeIds: <String>['spam', 'impersonation'],
        confirmSubjectTypeId: 'youtube.channel',
        confirmSubjectId: 'channel-1',
        confirmAbuseTypeIds: <String>['spam', 'impersonation'],
        description: 'Repeated deceptive impersonation.',
        relatedEntities: <Map<String, String>>[
          <String, String>{'typeId': 'youtube.video', 'id': 'video123'},
        ],
      );
      expect(generalReport.subjectTypeId, 'youtube.channel');
      expect(generalReport.abuseTypeIds, <String>['spam', 'impersonation']);

      expect(transport.operations, <String>[
        'creatorBeginThumbnailSet',
        'creatorListCaptions',
        'creatorDownloadCaption',
        'creatorBeginCaptionInsert',
        'creatorUpdateCaptionDraft',
        'creatorBeginCaptionReplacement',
        'creatorDeleteCaption',
        'creatorUpdateChannelBranding',
        'creatorListChannelSections',
        'creatorInsertChannelSection',
        'creatorUpdateChannelSection',
        'creatorDeleteChannelSection',
        'creatorBeginChannelBannerInsert',
        'creatorApplyChannelBanner',
        'creatorBeginWatermarkSet',
        'creatorUnsetWatermark',
        'creatorListPlaylistImages',
        'creatorBeginPlaylistImageInsert',
        'creatorBeginPlaylistImageUpdate',
        'creatorDeletePlaylistImage',
        'creatorListVideoAbuseReasons',
        'creatorReportVideoAbuse',
        'creatorInsertAbuseReport',
      ]);
      _expectReplayProtected(transport, credentials);
      expect(transport.requests[7].body['patch'], <String, Object?>{
        'country': 'IN',
        'description': 'Connected channel',
      });
      expect(transport.requests[14].body['corner'], 'bottomRight');
      expect(transport.requests[21].body['confirmReasonId'], 'reason-1');
      expect(transport.requests[22].body['confirmAbuseTypeIds'], <String>[
        'spam',
        'impersonation',
      ]);
    });

    test('capabilities remain disabled when fields are absent or false', () {
      final absent = YouTubePrivateDevCapabilities.fromJson(_capabilities());
      final explicit = YouTubePrivateDevCapabilities.fromJson(<String, Object?>{
        ..._capabilities(),
        'ownerActions': false,
        'creatorAssets': false,
      });

      expect(absent.ownerActions, isFalse);
      expect(absent.creatorAssets, isFalse);
      expect(explicit.ownerActions, isFalse);
      expect(explicit.creatorAssets, isFalse);
      expect(YouTubeConnectPurpose.write.wireValue, 'write');
      expect(YouTubeConnectPurpose.creatorAssets.wireValue, 'creatorAssets');
    });

    test('typed models reject malformed provider results', () {
      expect(
        () => YouTubeOwnerRatingResult.fromJson(_rating('unknown')),
        throwsFormatException,
      );
      expect(
        () => YouTubeDirectAssetUploadSession.fromJson(<String, Object?>{
          ..._assetSession('thumbnail'),
          'uploadMethod': 'POST',
        }),
        throwsFormatException,
      );
      expect(
        () => YouTubeChannelBrandingPatch(
          const <YouTubeChannelBrandingField, String?>{},
        ),
        throwsFormatException,
      );
    });
  });
}

YouTubePrivateDevClient _client(
  _RecordingTransport transport,
  _RecordingCredentials credentials,
) {
  return YouTubePrivateDevClient.forTesting(
    providerEndpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
      'youtubeProvider',
    ),
    transport: transport,
    credentials: credentials,
    proofEnabled: true,
    firebaseProjectId: youtubePrivateDevProjectId,
    requestId: () => 'request-fixed',
  );
}

void _expectReplayProtected(
  _RecordingTransport transport,
  _RecordingCredentials credentials,
) {
  expect(credentials.modes, everyElement(YouTubeAppCheckTokenMode.limitedUse));
  expect(credentials.idTokenCalls, transport.requests.length);
  for (final request in transport.requests) {
    expect(request.headers['authorization'], 'Bearer firebase-token');
    expect(request.headers['x-firebase-appcheck'], 'limited-app-check');
  }
}

Map<String, Object?> _capabilities() {
  return <String, Object?>{
    'environment': 'dev',
    'publicData': false,
    'ownerConnect': false,
    'privateUpload': false,
    'ownerAnalytics': false,
    'publicOrUnlistedUpload': false,
  };
}

Map<String, Object?> _rating(String rating) {
  return <String, Object?>{'videoId': 'video123', 'rating': rating};
}

Map<String, Object?> _comment({bool parent = false}) {
  return <String, Object?>{
    'commentId': 'comment-1',
    'textDisplay': 'Useful comment',
    'textFormat': 'plainText',
    'author': <String, Object?>{
      'displayName': 'Connected creator',
      'channelId': 'channel-owner',
    },
    'associatedChannelId': 'channel-owner',
    'likeCount': 1,
    'publishedAt': '2026-07-25T08:00:00.000Z',
    'updatedAt': '2026-07-25T08:00:00.000Z',
    if (parent) 'parentId': 'comment-parent',
  };
}

Map<String, Object?> _playlistMutation({String title = 'Useful playlist'}) {
  return <String, Object?>{
    'playlistId': 'playlist-1',
    'actorChannelId': 'channel-owner',
    'title': title,
    'description': '',
    'privacyStatus': title == 'Updated playlist' ? 'unlisted' : 'private',
  };
}

Map<String, Object?> _playlistItem({required int position}) {
  return <String, Object?>{
    'playlistItemId': 'playlist-item-1',
    'playlistId': 'playlist-1',
    'videoId': 'video123',
    'position': position,
  };
}

Map<String, Object?> _assetSession(String kind, {String encoding = 'json'}) {
  return <String, Object?>{
    'sessionUrl':
        'https://www.googleapis.com/upload/youtube/v3/$kind'
        '?upload_id=session-1',
    'expiresAt': '2026-07-26T08:00:00.000Z',
    'uploadMethod': 'PUT',
    'contentType': 'image/png',
    'contentLength': 1000,
    'resourceKind': kind,
    'providerResponseEncoding': encoding,
  };
}

Map<String, Object?> _caption({bool isDraft = true}) {
  return <String, Object?>{
    'captionId': 'caption-1',
    'videoId': 'video123',
    'language': 'en',
    'name': '',
    'isDraft': isDraft,
    'status': 'serving',
    'lastUpdated': '2026-07-25T08:00:00.000Z',
    'trackKind': 'standard',
    'isCC': true,
  };
}

YouTubeChannelSectionInput _sectionInput({int position = 1}) {
  return YouTubeChannelSectionInput(
    type: YouTubeChannelSectionType.singlePlaylist,
    title: 'Featured',
    position: position,
    playlistIds: const <String>['playlist-1'],
  );
}

Map<String, Object?> _channelSection({int position = 1}) {
  return <String, Object?>{
    'sectionId': 'section-1',
    'channelId': 'channel-owner',
    'type': 'singlePlaylist',
    'style': 'horizontalRow',
    'position': position,
    'title': 'Featured',
    'playlistIds': <String>['playlist-1'],
  };
}

Map<String, Object?> _playlistImage() {
  return <String, Object?>{
    'playlistImageId': 'playlist-image-1',
    'playlistId': 'playlist-1',
    'type': 'hero',
    'width': 800,
    'height': 800,
    'imageUrl': 'https://i.ytimg.com/playlist-image.jpg',
  };
}

class _RecordingCredentials implements YouTubeCredentialSource {
  final modes = <YouTubeAppCheckTokenMode>[];
  var idTokenCalls = 0;

  @override
  Future<String> appCheckToken(YouTubeAppCheckTokenMode mode) async {
    modes.add(mode);
    return mode == YouTubeAppCheckTokenMode.limitedUse
        ? 'limited-app-check'
        : 'standard-app-check';
  }

  @override
  Future<String> firebaseIdToken() async {
    idTokenCalls += 1;
    return 'firebase-token';
  }
}

class _Request {
  const _Request({required this.headers, required this.body});

  final Map<String, String> headers;
  final Map<String, Object?> body;
}

class _RecordingTransport implements YouTubeHttpTransport {
  final responses = <YouTubeHttpResponse>[];
  final requests = <_Request>[];

  List<String> get operations => requests
      .map((request) => request.body['operation']! as String)
      .toList(growable: false);

  void queue(Map<String, Object?> data) {
    responses.add(
      YouTubeHttpResponse(
        statusCode: 200,
        headers: const <String, String>{},
        body: jsonEncode(<String, Object?>{'ok': true, 'data': data}),
      ),
    );
  }

  @override
  Future<YouTubeHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    requests.add(
      _Request(
        headers: Map.unmodifiable(headers),
        body: Map.unmodifiable(body),
      ),
    );
    return responses.removeAt(0);
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
