import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  test('catalogue snapshots are immutable and expire after the short TTL', () {
    var now = DateTime.utc(2026, 8, 11, 12);
    final store = Screen04YouTubeCatalogueSnapshotStore(
      timeToLive: const Duration(minutes: 5),
      now: () => now,
    );
    final source = <Screen04YouTubePublicVideo>[_publicVideo('snapshot')];

    store.replaceVideos(source);
    store.replaceShorts(source);
    source.clear();

    expect(store.readFreshVideos(), hasLength(1));
    expect(store.readFreshShorts(), hasLength(1));
    expect(
      () => store.readFreshVideos()!.add(_publicVideo('mutation')),
      throwsUnsupportedError,
    );

    now = now.add(const Duration(minutes: 5));
    expect(store.readFreshVideos(), hasLength(1));
    now = now.add(const Duration(microseconds: 1));
    expect(store.readFreshVideos(), isNull);
    expect(store.readFreshShorts(), isNull);
  });

  test('private-Dev public review restores Screen 04 after safe boot', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains("pendingRoute: '/app/social?sub=videos'"));
    expect(source, contains('youtubeConnectReturnLocation('));
    expect(
      source,
      contains(
        'emailLinkInitialLocation =\n'
        '        youtubeInitialLocation == null &&\n'
        '        !socialAuthInitialLocation &&\n'
        '        await session\n'
        '            .prepareEmailLinkReturn(platformRouteName)\n'
        '            .timeout(_releasePlatformStageTimeout);',
      ),
      reason:
          'YouTube and social-provider returns remain authoritative before '
          'the email-link handoff is considered.',
    );
    expect(
      source,
      contains(
        'initialLocation:\n'
        '          youtubeInitialLocation ??\n'
        '          (socialAuthInitialLocation || emailLinkInitialLocation\n'
        "              ? '/sign-in'\n"
        "              : '/boot'),",
      ),
      reason:
          'Safe boot must remain the final fallback after exact provider and '
          'passwordless email-link returns.',
    );
    expect(
      source,
      isNot(contains('initialLocation: _youtubePublicReviewMode')),
      reason:
          'A protected initial route persists an empty boot snapshot before '
          'the preseeded review session is restored.',
    );
  });

  test('reviewer YouTube surfaces stay provider-clear and user initiated', () {
    final source = File(
      'lib/ui_v2/social/social_v2_consumer.dart',
    ).readAsStringSync();
    final buildShortsStart = source.indexOf('Widget _buildShorts()');
    final buildShortsEnd = source.indexOf(
      'Widget _buildLiveYouTubeShort(',
      buildShortsStart,
    );
    expect(buildShortsStart, greaterThanOrEqualTo(0));
    expect(buildShortsEnd, greaterThan(buildShortsStart));
    final buildShorts = source.substring(buildShortsStart, buildShortsEnd);

    final liveShortStart = buildShortsEnd;
    final liveShortEnd = source.indexOf(
      'List<_VideoData> _eligibleLiveYouTubeVideos()',
      liveShortStart,
    );
    expect(liveShortStart, greaterThanOrEqualTo(0));
    expect(liveShortEnd, greaterThan(liveShortStart));
    final liveShort = source.substring(liveShortStart, liveShortEnd);

    expect(buildShorts, contains('_eligibleLiveYouTubeShorts()'));
    expect(buildShorts, contains('_buildLiveYouTubeShort('));
    expect(
      buildShorts,
      contains('screen04-youtube-shorts-state-provider-access'),
    );
    expect(buildShorts, contains('screen04-youtube-shorts-state-loading'));
    expect(buildShorts, contains('screen04-youtube-shorts-state-error'));
    expect(buildShorts, contains('screen04-youtube-shorts-state-empty'));
    expect(buildShorts, contains('_YouTubeShortsStatusView'));
    expect(buildShorts, isNot(contains('socialPublishedItems')));
    expect(buildShorts, isNot(contains('_screen04Shorts')));
    expect(buildShorts, isNot(contains('_buildMoolSocialReel')));

    expect(liveShort, contains('SizedBox.expand('));
    expect(liveShort, contains('_Screen04OfficialYouTubePlayer('));
    expect(liveShort, contains('onOpenProvider:'));
    expect(liveShort, contains('screen04-youtube-shorts-stage'));
    expect(liveShort, contains('screen04-short-media-youtube-live'));
    expect(liveShort, isNot(contains('ClipRRect(')));
    expect(liveShort, isNot(contains('Stack(')));
    expect(liveShort, isNot(contains('_YouTubeShortsStageHeader(')));
    expect(liveShort, isNot(contains('_YouTubeShortsStageMetadata(')));
    expect(liveShort, isNot(contains('_YouTubeShortActionRail')));
    expect(liveShort, isNot(contains("'Following'")));
    expect(liveShort, isNot(contains("'Nearby'")));
    expect(liveShort, isNot(contains("'Promoted'")));
    expect(liveShort, isNot(contains('_ShortCommerceCard(')));
    expect(liveShort, isNot(contains('_openComments(reel.title)')));
    expect(source, isNot(contains('screen04-youtube-short-channel')));
    expect(source, isNot(contains('screen04-youtube-short-save')));
    expect(source, isNot(contains('screen04-youtube-short-discuss')));
    expect(source, isNot(contains('screen04-youtube-short-share')));
    expect(source, contains('screen04-youtube-player-retry'));
    expect(source, contains('screen04-youtube-player-open-provider'));
    expect(source, contains('snapshot.failure?.retryable == true'));
    expect(source, contains('controller.retryPlayerFailureFromUser()'));
    expect(liveShort, isNot(contains("label: 'Like'")));
    expect(liveShort, isNot(contains("label: 'Comment'")));
    expect(liveShort, isNot(contains("label: 'Subscribe'")));
    expect(liveShort, isNot(contains("label: 'Remix'")));
    expect(liveShort, isNot(contains("label: 'Upload'")));
    expect(source, isNot(contains('Fresh basket packed this morning')));
    expect(source, isNot(contains('Meet Rajasthan makers this week')));
    expect(source, isNot(contains('attemptVerifiedShortAutoplay();')));

    final videoImageStart = source.indexOf('class _VideoImage');
    final providerThumbnailStart = source.indexOf(
      'return Image.network(',
      videoImageStart,
    );
    final providerThumbnailEnd = source.indexOf(
      'class _Screen04OfficialYouTubePlayer',
      providerThumbnailStart,
    );
    expect(videoImageStart, greaterThanOrEqualTo(0));
    expect(providerThumbnailStart, greaterThan(videoImageStart));
    expect(providerThumbnailEnd, greaterThan(providerThumbnailStart));
    final providerThumbnail = source.substring(
      providerThumbnailStart,
      providerThumbnailEnd,
    );
    expect(
      providerThumbnail,
      contains('screen04-youtube-thumbnail-unavailable'),
    );
    expect(
      providerThumbnail,
      isNot(contains('assets/prototype/social-market-grocery.png')),
    );

    final buildVideosStart = source.indexOf('Widget _buildVideos()');
    final buildVideosEnd = source.indexOf(
      'Widget _buildFeed()',
      buildVideosStart,
    );
    expect(buildVideosStart, greaterThanOrEqualTo(0));
    expect(buildVideosEnd, greaterThan(buildVideosStart));
    final buildVideos = source.substring(buildVideosStart, buildVideosEnd);
    expect(buildVideos, contains('_eligibleLiveYouTubeVideos()'));
    expect(buildVideos, contains('_InlineVideoWatch('));
    expect(
      buildVideos,
      contains('screen04-youtube-videos-state-provider-access'),
    );
    expect(buildVideos, contains('screen04-youtube-videos-state-loading'));
    expect(buildVideos, contains('screen04-youtube-videos-state-error'));
    expect(buildVideos, contains('screen04-youtube-videos-state-empty'));
    expect(buildVideos, isNot(contains('_videoCatalog')));
    expect(buildVideos, isNot(contains('_videosForMode')));
    final videoWatchStart = source.indexOf('class _InlineVideoWatch');
    final videoWatchEnd = source.indexOf(
      'class _VideoThumbnail',
      videoWatchStart,
    );
    expect(videoWatchStart, greaterThanOrEqualTo(0));
    expect(videoWatchEnd, greaterThan(videoWatchStart));
    final videoWatch = source.substring(videoWatchStart, videoWatchEnd);
    expect(videoWatch, contains('Available actions for this YouTube video'));
    expect(videoWatch, isNot(contains('screen04-video-save')));
    expect(videoWatch, isNot(contains('screen04-video-discuss')));
    expect(videoWatch, contains('screen04-video-share'));
    expect(videoWatch, contains('screen04-video-details'));
    expect(videoWatch, isNot(contains("label: 'Like'")));
    expect(videoWatch, isNot(contains("label: 'Comment'")));
    expect(videoWatch, isNot(contains("label: 'Subscribe'")));
    expect(videoWatch, isNot(contains("label: 'Upload'")));
    expect(source, contains('Clipboard.setData'));
    expect(source, contains("'YouTube link copied'"));
    expect(source, contains("hintText: 'Search YouTube'"));
    expect(source, contains('class _YouTubeSearchSurface'));
    expect(source, isNot(contains('Filter loaded videos')));
    expect(source, isNot(contains('Loaded title, channel or topic')));
    expect(source, contains("title: 'Loading YouTube videos'"));
    expect(source, contains("'YouTube videos'"));
    expect(source, contains("'YouTube Shorts'"));
    expect(
      source,
      isNot(contains("child: Text(\n                  'Videos',")),
    );
    final attributionStart = source.indexOf('class _YouTubeAttribution');
    final attributionEnd = source.indexOf(
      '@immutable\nclass _ShortData',
      attributionStart,
    );
    expect(attributionStart, greaterThanOrEqualTo(0));
    expect(attributionEnd, greaterThan(attributionStart));
    final attribution = source.substring(attributionStart, attributionEnd);
    expect(
      attribution,
      contains(
        'const _YouTubeAttribution({this.onDark = true, required this.onTap})',
      ),
    );
    expect(attribution, contains('final VoidCallback onTap'));
    expect(attribution, isNot(contains('final VoidCallback? onTap')));
    expect(attribution, isNot(contains("Uri.https('www.youtube.com', '/'),")));
    expect(source, isNot(contains('Comment posted on MoolSocial')));
    expect(source, isNot(contains('class _VideoWatchScreen')));
    expect(source, isNot(contains('TextScaler.linear')));
    expect(source, isNot(contains('5-minute morning mobility')));
    expect(source, isNot(contains('How Jodhpur makers prepare block prints')));
  });

  test('maps only provider-returned public video and channel metadata', () {
    final video = YouTubeVideoSummary(
      videoId: 'abc123XYZ09',
      title: 'Public title',
      channelId: 'UC123',
      channelTitle: 'Public channel',
      publishedAt: DateTime.utc(2026, 7, 25),
      description: 'Public description',
      thumbnail: YouTubeThumbnail(
        url: Uri.parse('https://i.ytimg.com/vi/abc123XYZ09/hqdefault.jpg'),
        width: 480,
        height: 360,
      ),
      tags: const ['India', '#Makers'],
      duration: 'PT5M4S',
      captionAvailable: true,
      viewCount: '1234567',
      likeCount: '45678',
      commentCount: '321',
      embeddable: true,
      privacyStatus: 'public',
      uploadStatus: 'processed',
      availability: const YouTubePublicVideoAvailability(
        regionCode: 'IN',
        broadcastState: YouTubeBroadcastState.none,
        syndication: 'search_filter_confirmed',
      ),
    );
    final channel = YouTubePublicChannelDetails(
      channelId: 'UC123',
      title: 'Public channel',
      description: 'Public channel description',
      publishedAt: DateTime.utc(2020),
      thumbnail: YouTubeThumbnail(
        url: Uri.parse('https://yt3.ggpht.com/channel'),
      ),
      statistics: const YouTubePublicChannelStatistics(
        viewCount: '7654321',
        subscriberCount: '654321',
        videoCount: '123',
        hiddenSubscriberCount: false,
      ),
      topicCategories: const [],
    );

    final mapped = mapScreen04YouTubePublicVideo(video, channel: channel);

    expect(mapped.videoId, 'abc123XYZ09');
    expect(mapped.title, 'Public title');
    expect(mapped.channelTitle, 'Public channel');
    expect(mapped.description, 'Public description');
    expect(mapped.thumbnailUrl.host, 'i.ytimg.com');
    expect(mapped.duration, 'PT5M4S');
    expect(mapped.captionAvailable, isTrue);
    expect(mapped.viewCount, '1234567');
    expect(mapped.subscriberCount, '654321');
    expect(mapped.channelDescription, 'Public channel description');
    expect(mapped.hashtags, ['#India', '#Makers']);
    expect(mapped.embeddable, isTrue);
    expect(mapped.hasKnownDeviceRegionExclusion, isFalse);
  });

  test(
    'keeps an eligible-empty provider page distinct from transport error',
    () {
      final source = File(
        'lib/ui_v2/social/social_v2_youtube_public_runtime.dart',
      ).readAsStringSync();

      expect(source, contains('collectScreen04YouTubeCatalogue('));
      expect(source, isNot(contains('No public videos are available.')));
      expect(
        source,
        contains('List<YouTubeVideoSummary>.unmodifiable(collected)'),
        reason: 'An eligible-empty page must reach the native empty state.',
      );
    },
  );

  test('formats compact public counts without leaking regex groups', () {
    expect(formatScreen04YouTubeCount('2100', 'comments'), '2.1K comments');
    expect(formatScreen04YouTubeCount('21100', 'comments'), '21.1K comments');
    expect(formatScreen04YouTubeCount('2100000', 'views'), '2.1M views');
    expect(formatScreen04YouTubeCount(null, 'likes'), 'likes');
  });

  test('detects both blocked and allow-list region exclusions', () {
    expect(
      hasScreen04YouTubeRegionExclusion(
        YouTubeRegionRestriction(blocked: const ['IN']),
        'IN',
      ),
      isTrue,
    );
    expect(
      hasScreen04YouTubeRegionExclusion(
        YouTubeRegionRestriction(allowed: const ['US', 'GB']),
        'IN',
      ),
      isTrue,
    );
    expect(
      hasScreen04YouTubeRegionExclusion(
        YouTubeRegionRestriction(allowed: const ['IN', 'US']),
        'IN',
      ),
      isFalse,
    );
  });

  test('admits only creator-declared Shorts within the Shorts duration', () {
    YouTubeVideoSummary video({
      required String title,
      required String duration,
      List<String>? tags,
    }) {
      return YouTubeVideoSummary(
        videoId: 'abc123XYZ09',
        title: title,
        channelId: 'UC123',
        channelTitle: 'Public channel',
        publishedAt: DateTime.utc(2026, 7, 25),
        description: 'Public description',
        thumbnail: YouTubeThumbnail(
          url: Uri.parse('https://i.ytimg.com/vi/abc123XYZ09/hqdefault.jpg'),
        ),
        tags: tags,
        duration: duration,
        embeddable: true,
        privacyStatus: 'public',
        uploadStatus: 'processed',
        availability: const YouTubePublicVideoAvailability(
          regionCode: 'IN',
          broadcastState: YouTubeBroadcastState.none,
          syndication: 'search_filter_confirmed',
        ),
      );
    }

    expect(
      isScreen04CreatorDeclaredYouTubeShort(
        video(
          title: 'A creator-labelled Short',
          duration: 'PT2M59S',
          tags: const ['#Shorts'],
        ),
      ),
      isTrue,
    );
    expect(
      isScreen04CreatorDeclaredYouTubeShort(
        video(title: 'An ordinary brief video', duration: 'PT59S'),
      ),
      isFalse,
      reason: 'Short duration alone must never classify a YouTube Short.',
    );
    expect(
      isScreen04CreatorDeclaredYouTubeShort(
        video(title: 'Creator-labelled #Shorts upload', duration: 'PT3M1S'),
      ),
      isFalse,
    );
    expect(screen04YouTubeDurationSeconds('PT1H2M3S'), 3723);
    expect(screen04YouTubeDurationSeconds('not-a-duration'), isNull);
  });

  test(
    'collects 20 unique eligible items and stops without an extra page',
    () async {
      final requestedTokens = <String?>[];
      final result = await collectScreen04YouTubeCatalogue(
        loadPage: (pageToken) async {
          requestedTokens.add(pageToken);
          if (pageToken == null) {
            return YouTubeVideoPage(
              items: [
                for (var index = 0; index < 12; index += 1)
                  _catalogueVideo(index),
              ],
              nextPageToken: 'page-2',
            );
          }
          return YouTubeVideoPage(
            items: [
              _catalogueVideo(11),
              for (var index = 12; index < 24; index += 1)
                _catalogueVideo(index),
            ],
            nextPageToken: 'page-3',
          );
        },
        isEligible: (video) => video.videoId != 'catalogue00005',
      );

      expect(result, hasLength(20));
      expect(result.map((video) => video.videoId).toSet(), hasLength(20));
      expect(result.any((video) => video.videoId == 'catalogue00005'), isFalse);
      expect(requestedTokens, [null, 'page-2']);
    },
  );

  test('returns a truthful shortfall after the bounded page limit', () async {
    final requestedTokens = <String?>[];
    final result = await collectScreen04YouTubeCatalogue(
      maximumPages: 4,
      loadPage: (pageToken) async {
        requestedTokens.add(pageToken);
        final page = requestedTokens.length;
        return YouTubeVideoPage(
          items: [_catalogueVideo(page)],
          nextPageToken: 'page-${page + 1}',
        );
      },
      isEligible: (_) => true,
    );

    expect(result, hasLength(4));
    expect(requestedTokens, [null, 'page-2', 'page-3', 'page-4']);
  });
}

Screen04YouTubePublicVideo _publicVideo(String id) =>
    Screen04YouTubePublicVideo(
      videoId: id,
      title: 'Provider title $id',
      channelId: 'channel-$id',
      channelTitle: 'Provider channel',
      description: 'Provider description',
      thumbnailUrl: Uri.parse('https://i.ytimg.com/vi/$id/hqdefault.jpg'),
      publishedAt: DateTime.utc(2026, 8, 11),
      duration: 'PT30S',
      captionAvailable: true,
      viewCount: '100',
      likeCount: '10',
      commentCount: '1',
      embeddable: true,
      hasKnownDeviceRegionExclusion: false,
      hashtags: const ['#Shorts'],
    );

YouTubeVideoSummary _catalogueVideo(int index) {
  final id = 'catalogue${index.toString().padLeft(5, '0')}';
  return YouTubeVideoSummary(
    videoId: id,
    title: 'Catalogue item $index',
    channelId: 'UC$index',
    channelTitle: 'Public channel $index',
    publishedAt: DateTime.utc(2026, 8, 11),
    description: 'Public catalogue item.',
    thumbnail: YouTubeThumbnail(
      url: Uri.parse('https://i.ytimg.com/vi/$id/hqdefault.jpg'),
    ),
    duration: 'PT2M',
    embeddable: true,
    privacyStatus: 'public',
    uploadStatus: 'processed',
    availability: const YouTubePublicVideoAvailability(
      regionCode: 'IN',
      broadcastState: YouTubeBroadcastState.none,
      syndication: 'search_filter_confirmed',
    ),
  );
}
