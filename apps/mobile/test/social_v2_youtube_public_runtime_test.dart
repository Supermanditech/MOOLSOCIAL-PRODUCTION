import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  test('private-Dev public review restores Screen 04 after safe boot', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains("pendingRoute: '/app/social?sub=videos'"));
    expect(source, contains('youtubeConnectReturnLocation('));
    expect(source, contains("initialLocation: initialLocation ?? '/boot'"));
    expect(
      source,
      isNot(contains('initialLocation: _youtubePublicReviewMode')),
      reason:
          'A protected initial route persists an empty boot snapshot before '
          'the preseeded review session is restored.',
    );
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
    expect(mapped.viewCount, '1234567');
    expect(mapped.subscriberCount, '654321');
    expect(mapped.channelDescription, 'Public channel description');
    expect(mapped.hashtags, ['#India', '#Makers']);
    expect(mapped.embeddable, isTrue);
    expect(mapped.hasKnownDeviceRegionExclusion, isFalse);
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
}
