import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';
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

  test(
    'durable hydration restores fresh videos and truthful stale Shorts',
    () async {
      final now = DateTime.utc(2026, 8, 25, 6);
      final repository = _CatalogueRepositoryFake()
        ..reads[YouTubePublicCatalogueKind.videos] = YouTubePublicCatalogueRead(
          freshness: YouTubeCatalogueFreshness.fresh,
          snapshot: YouTubePublicCatalogueSnapshot(
            kind: YouTubePublicCatalogueKind.videos,
            capturedAtUtc: now.subtract(const Duration(minutes: 1)),
            items: [
              mapScreen04VideoToYouTubePublicCatalogueItem(
                _publicVideo('durable-video'),
              ),
            ],
          ),
        )
        ..reads[YouTubePublicCatalogueKind.shorts] = YouTubePublicCatalogueRead(
          freshness: YouTubeCatalogueFreshness.stale,
          snapshot: YouTubePublicCatalogueSnapshot(
            kind: YouTubePublicCatalogueKind.shorts,
            capturedAtUtc: now.subtract(const Duration(minutes: 6)),
            items: [
              mapScreen04VideoToYouTubePublicCatalogueItem(
                _publicVideo('durable-short'),
              ),
            ],
          ),
        );
      final store = Screen04YouTubeCatalogueSnapshotStore(now: () => now);

      await store.configureDurability(repository);

      expect(store.readFreshVideos()?.single.videoId, 'durable-video');
      expect(store.readFreshShorts(), isNull);
      expect(store.readShorts()?.single.videoId, 'durable-short');
    },
  );

  test('late hydration cannot overwrite a newer live replacement', () async {
    final now = DateTime.utc(2026, 8, 25, 6);
    final gate = Completer<void>();
    final repository = _CatalogueRepositoryFake()
      ..readGates[YouTubePublicCatalogueKind.videos] = gate
      ..reads[YouTubePublicCatalogueKind.videos] = YouTubePublicCatalogueRead(
        freshness: YouTubeCatalogueFreshness.fresh,
        snapshot: YouTubePublicCatalogueSnapshot(
          kind: YouTubePublicCatalogueKind.videos,
          capturedAtUtc: now,
          items: [
            mapScreen04VideoToYouTubePublicCatalogueItem(
              _publicVideo('old-durable-video'),
            ),
          ],
        ),
      );
    final store = Screen04YouTubeCatalogueSnapshotStore(now: () => now);
    final hydration = store.configureDurability(repository);
    await repository.readStarted[YouTubePublicCatalogueKind.videos]!.future;

    store.replaceVideos([_publicVideo('new-live-video')]);
    gate.complete();
    await hydration;

    expect(store.readVideos()?.single.videoId, 'new-live-video');
  });

  test(
    'new repository and runtime instances restore both process-death lanes',
    () async {
      var now = DateTime.utc(2026, 8, 25, 6);
      final persistence = _CatalogueKeyValueStoreFake();
      final firstRepository = DurableYouTubePublicCatalogueRepository(
        persistence: persistence,
        now: () => now,
      );
      final firstRuntime = Screen04YouTubeCatalogueSnapshotStore(
        now: () => now,
      );
      await firstRuntime.configureDurability(firstRepository);
      firstRuntime.replaceVideos([_publicVideo('process-video')]);
      firstRuntime.replaceShorts([_publicVideo('process-short')]);
      await firstRuntime.settleDurableWrites();

      now = now.add(const Duration(minutes: 5));
      final relaunchedRepository = DurableYouTubePublicCatalogueRepository(
        persistence: persistence,
        now: () => now,
      );
      final relaunchedRuntime = Screen04YouTubeCatalogueSnapshotStore(
        now: () => now,
      );
      await relaunchedRuntime.configureDurability(relaunchedRepository);

      expect(
        relaunchedRuntime.readFreshVideos()?.single.videoId,
        'process-video',
      );
      expect(
        relaunchedRuntime.readFreshShorts()?.single.videoId,
        'process-short',
      );
      now = now.add(const Duration(microseconds: 1));
      expect(relaunchedRuntime.readFreshVideos(), isNull);
      expect(relaunchedRuntime.readVideos()?.single.videoId, 'process-video');
    },
  );

  test('durable mapping preserves every catalogue field exactly', () {
    final source = Screen04YouTubePublicVideo(
      videoId: 'video-full',
      title: 'Full title',
      channelId: 'channel-full',
      channelTitle: 'Full channel',
      description: 'Full description',
      thumbnailUrl: Uri.parse('https://i.ytimg.com/vi/video-full/hq.jpg'),
      publishedAt: DateTime.utc(2026, 8, 24, 1, 2, 3),
      duration: 'PT2M3S',
      captionAvailable: false,
      viewCount: '101',
      likeCount: '11',
      commentCount: '2',
      embeddable: true,
      hasKnownDeviceRegionExclusion: false,
      hashtags: const ['#one', '#two'],
      channelDescription: 'Channel description',
      channelThumbnailUrl: Uri.parse(
        'https://yt3.ggpht.com/channel-full/photo.jpg',
      ),
      subscriberCount: '1001',
      channelVideoCount: '51',
      channelViewCount: '50001',
    );

    final restored = mapYouTubePublicCatalogueItemToScreen04Video(
      mapScreen04VideoToYouTubePublicCatalogueItem(source),
    );

    expect(restored.videoId, source.videoId);
    expect(restored.title, source.title);
    expect(restored.channelId, source.channelId);
    expect(restored.channelTitle, source.channelTitle);
    expect(restored.description, source.description);
    expect(restored.thumbnailUrl, source.thumbnailUrl);
    expect(restored.publishedAt, source.publishedAt);
    expect(restored.duration, source.duration);
    expect(restored.captionAvailable, source.captionAvailable);
    expect(restored.viewCount, source.viewCount);
    expect(restored.likeCount, source.likeCount);
    expect(restored.commentCount, source.commentCount);
    expect(restored.embeddable, source.embeddable);
    expect(
      restored.hasKnownDeviceRegionExclusion,
      source.hasKnownDeviceRegionExclusion,
    );
    expect(restored.hashtags, source.hashtags);
    expect(restored.channelDescription, source.channelDescription);
    expect(restored.channelThumbnailUrl, source.channelThumbnailUrl);
    expect(restored.subscriberCount, source.subscriberCount);
    expect(restored.channelVideoCount, source.channelVideoCount);
    expect(restored.channelViewCount, source.channelViewCount);
  });

  test(
    'live replacements write through while cache failures stay nonfatal',
    () async {
      final repository = _CatalogueRepositoryFake();
      final store = Screen04YouTubeCatalogueSnapshotStore();
      await store.configureDurability(repository);

      store.replaceVideos([_publicVideo('live-video')]);
      store.replaceShorts([_publicVideo('live-short')]);
      await store.settleDurableWrites();
      expect(
        repository.writes[YouTubePublicCatalogueKind.videos]?.single.videoId,
        'live-video',
      );
      expect(
        repository.writes[YouTubePublicCatalogueKind.shorts]?.single.videoId,
        'live-short',
      );

      repository.failWrites = true;
      store.replaceVideos([_publicVideo('memory-still-live')]);
      await store.settleDurableWrites();
      expect(store.readVideos()?.single.videoId, 'memory-still-live');
    },
  );

  test('settleDurableWrites joins both concurrent lane mutations', () async {
    final videosGate = Completer<void>();
    final shortsGate = Completer<void>();
    final repository = _CatalogueRepositoryFake()
      ..writeGates[YouTubePublicCatalogueKind.videos] = videosGate
      ..writeGates[YouTubePublicCatalogueKind.shorts] = shortsGate;
    final store = Screen04YouTubeCatalogueSnapshotStore();
    await store.configureDurability(repository);
    store.replaceVideos([_publicVideo('joined-video')]);
    store.replaceShorts([_publicVideo('joined-short')]);
    await Future.wait([
      repository.writeStarted[YouTubePublicCatalogueKind.videos]!.future,
      repository.writeStarted[YouTubePublicCatalogueKind.shorts]!.future,
    ]);
    var settled = false;
    final settlement = store.settleDurableWrites().then((_) {
      settled = true;
    });

    shortsGate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(settled, isFalse);
    videosGate.complete();
    await settlement;
    expect(settled, isTrue);
  });

  test(
    'one durable read failure is isolated from the valid other lane',
    () async {
      final now = DateTime.utc(2026, 8, 25, 6);
      final repository = _CatalogueRepositoryFake()
        ..failedReads.add(YouTubePublicCatalogueKind.videos)
        ..reads[YouTubePublicCatalogueKind.shorts] = YouTubePublicCatalogueRead(
          freshness: YouTubeCatalogueFreshness.fresh,
          snapshot: YouTubePublicCatalogueSnapshot(
            kind: YouTubePublicCatalogueKind.shorts,
            capturedAtUtc: now,
            items: [
              mapScreen04VideoToYouTubePublicCatalogueItem(
                _publicVideo('valid-short'),
              ),
            ],
          ),
        );
      final store = Screen04YouTubeCatalogueSnapshotStore(now: () => now);

      final hydration = await store.configureDurability(repository);

      expect(store.readVideos(), isNull);
      expect(store.readShorts()?.single.videoId, 'valid-short');
      expect(repository.cleared, isEmpty);
      expect(hydration.degraded, isTrue);
    },
  );

  test('invalid durable Short is rejected and cleared', () async {
    final now = DateTime.utc(2026, 8, 25, 6);
    final invalidShort = mapScreen04VideoToYouTubePublicCatalogueItem(
      Screen04YouTubePublicVideo(
        videoId: 'invalid-short',
        title: 'Declared #Shorts',
        channelId: 'channel-invalid',
        channelTitle: 'Channel',
        description: 'Too long for the accepted Shorts contract.',
        thumbnailUrl: Uri.parse(
          'https://i.ytimg.com/vi/invalid-short/hqdefault.jpg',
        ),
        publishedAt: DateTime.utc(2026, 8, 24),
        duration: 'PT4M',
        captionAvailable: true,
        viewCount: '1',
        likeCount: '1',
        commentCount: '1',
        embeddable: true,
        hasKnownDeviceRegionExclusion: false,
        hashtags: const ['#Shorts'],
      ),
    );
    final repository = _CatalogueRepositoryFake()
      ..reads[YouTubePublicCatalogueKind.shorts] = YouTubePublicCatalogueRead(
        freshness: YouTubeCatalogueFreshness.fresh,
        snapshot: YouTubePublicCatalogueSnapshot(
          kind: YouTubePublicCatalogueKind.shorts,
          capturedAtUtc: now,
          items: [invalidShort],
        ),
      );
    final store = Screen04YouTubeCatalogueSnapshotStore(now: () => now);

    final hydration = await store.configureDurability(repository);

    expect(store.readShorts(), isNull);
    expect(repository.cleared, [YouTubePublicCatalogueKind.shorts]);
    expect(hydration.degraded, isFalse);
  });

  test('inconsistent durable kind or freshness fails closed', () async {
    final now = DateTime.utc(2026, 8, 25, 6);
    final repository = _CatalogueRepositoryFake()
      ..reads[YouTubePublicCatalogueKind.videos] = YouTubePublicCatalogueRead(
        freshness: YouTubeCatalogueFreshness.expired,
        snapshot: YouTubePublicCatalogueSnapshot(
          kind: YouTubePublicCatalogueKind.shorts,
          capturedAtUtc: now,
          items: [
            mapScreen04VideoToYouTubePublicCatalogueItem(
              _publicVideo('inconsistent'),
            ),
          ],
        ),
      );
    final store = Screen04YouTubeCatalogueSnapshotStore(now: () => now);

    await store.configureDurability(repository);

    expect(store.readVideos(), isNull);
    expect(repository.cleared, [YouTubePublicCatalogueKind.videos]);
  });

  test('main hydrates the no-cache async repository before runApp', () {
    final source = File('lib/main.dart').readAsStringSync();
    final hydration = source.indexOf(
      'screen04YouTubeCatalogueSnapshots\n'
      '        .configureDurability(',
    );
    final appStart = source.indexOf('runApp(\n    MoolSocialApp(');

    expect(hydration, greaterThan(-1));
    expect(appStart, greaterThan(hydration));
    expect(
      source,
      contains('SharedPreferencesAsyncYouTubePublicCatalogueStore('),
    );
    expect(
      source,
      isNot(contains('SharedPreferencesYouTubePublicCatalogueStore(')),
    );
    expect(
      source,
      contains(
        "_recordReleaseBootstrapStage('youtube_catalogue_cache', 'begin')",
      ),
    );
    expect(source, contains("hydration.degraded ? 'degraded' : 'passed'"));
    expect(
      source,
      contains(
        "_recordReleaseBootstrapStage('youtube_catalogue_cache', 'degraded')",
      ),
    );
    expect(
      source,
      isNot(
        contains("_showReleaseBootstrapFailure('youtube_catalogue_cache')"),
      ),
    );
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
    expect(source, contains('_shareYouTubeVideo(video)'));
    expect(source, contains("title: 'Share YouTube video'"));
    expect(source, contains("subject: 'YouTube video'"));
    expect(source, isNot(contains('_copyYouTubeLink')));
    expect(source, isNot(contains("'YouTube link copied'")));
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
    expect(attribution, contains('const _YouTubeAttribution();'));
    expect(attribution, contains("label: 'YouTube content source'"));
    expect(attribution, isNot(contains('VoidCallback onTap')));
    expect(attribution, isNot(contains('button: true')));
    expect(attribution, isNot(contains('link: true')));
    expect(attribution, isNot(contains('Icons.open_in_new_rounded')));
    expect(attribution, isNot(contains('InkWell(')));
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

final class _CatalogueRepositoryFake
    implements YouTubePublicCatalogueRepository {
  final Map<YouTubePublicCatalogueKind, YouTubePublicCatalogueRead> reads = {};
  final Map<YouTubePublicCatalogueKind, List<YouTubePublicCatalogueItem>>
  writes = {};
  final Set<YouTubePublicCatalogueKind> failedReads = {};
  final Map<YouTubePublicCatalogueKind, Completer<void>> readGates = {};
  final Map<YouTubePublicCatalogueKind, Completer<void>> readStarted = {
    YouTubePublicCatalogueKind.videos: Completer<void>(),
    YouTubePublicCatalogueKind.shorts: Completer<void>(),
  };
  final Map<YouTubePublicCatalogueKind, Completer<void>> writeGates = {};
  final Map<YouTubePublicCatalogueKind, Completer<void>> writeStarted = {
    YouTubePublicCatalogueKind.videos: Completer<void>(),
    YouTubePublicCatalogueKind.shorts: Completer<void>(),
  };
  final List<YouTubePublicCatalogueKind> cleared = [];
  bool failWrites = false;

  @override
  Future<YouTubePublicCatalogueRead> read(
    YouTubePublicCatalogueKind kind,
  ) async {
    final started = readStarted[kind]!;
    if (!started.isCompleted) started.complete();
    final gate = readGates[kind];
    if (gate != null) await gate.future;
    if (failedReads.contains(kind)) throw StateError('sanitized test failure');
    return reads[kind] ??
        const YouTubePublicCatalogueRead(
          freshness: YouTubeCatalogueFreshness.missing,
        );
  }

  @override
  Future<void> replace(
    YouTubePublicCatalogueKind kind,
    List<YouTubePublicCatalogueItem> items,
  ) async {
    final started = writeStarted[kind]!;
    if (!started.isCompleted) started.complete();
    final gate = writeGates[kind];
    if (gate != null) await gate.future;
    if (failWrites) throw StateError('sanitized test failure');
    writes[kind] = List<YouTubePublicCatalogueItem>.unmodifiable(items);
  }

  @override
  Future<void> clear(YouTubePublicCatalogueKind kind) async {
    cleared.add(kind);
  }

  @override
  Future<void> clearAll() async {
    cleared
      ..add(YouTubePublicCatalogueKind.videos)
      ..add(YouTubePublicCatalogueKind.shorts);
  }
}

final class _CatalogueKeyValueStoreFake
    implements YouTubePublicCatalogueKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<bool> writeString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
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
