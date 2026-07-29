import '../../core/youtube/youtube_private_dev_client.dart';
import '../../core/youtube/youtube_private_dev_models.dart';
import '../../core/youtube/youtube_private_dev_transport.dart';

const screen04YouTubeRegionCode = 'IN';
const screen04YouTubeShortsQuery = 'India #Shorts';
const screen04YouTubeShortMaximumSeconds = 180;

class Screen04YouTubePublicVideo {
  const Screen04YouTubePublicVideo({
    required this.videoId,
    required this.title,
    required this.channelId,
    required this.channelTitle,
    required this.description,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.duration,
    required this.captionAvailable,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.embeddable,
    required this.hasKnownDeviceRegionExclusion,
    required this.hashtags,
    this.channelDescription,
    this.channelThumbnailUrl,
    this.subscriberCount,
    this.channelVideoCount,
    this.channelViewCount,
  });

  final String videoId;
  final String title;
  final String channelId;
  final String channelTitle;
  final String description;
  final Uri thumbnailUrl;
  final DateTime publishedAt;
  final String? duration;
  final bool? captionAvailable;
  final String? viewCount;
  final String? likeCount;
  final String? commentCount;
  final bool embeddable;
  final bool hasKnownDeviceRegionExclusion;
  final List<String> hashtags;
  final String? channelDescription;
  final Uri? channelThumbnailUrl;
  final String? subscriberCount;
  final String? channelVideoCount;
  final String? channelViewCount;
}

Future<List<Screen04YouTubePublicVideo>>
loadScreen04YouTubePublicVideos() async {
  final transport = IoYouTubeHttpTransport();
  try {
    final client = YouTubePrivateDevClient.fromBuildConfiguration(
      transport: transport,
    );
    final capabilities = await client.capabilities();
    if (!capabilities.publicData) {
      throw StateError('Public video viewing is unavailable.');
    }

    final page = await client.mostPopular(
      regionCode: screen04YouTubeRegionCode,
    );
    final eligible = page.items
        .where(_isEligiblePublicVideo)
        .take(12)
        .toList(growable: false);
    if (eligible.isEmpty) {
      throw StateError('No public videos are available.');
    }

    final channels = <String, YouTubePublicChannelDetails>{};
    for (final item in eligible) {
      if (channels.containsKey(item.channelId)) continue;
      try {
        channels[item.channelId] = await client.channelDetails(
          channelId: item.channelId,
        );
      } on Object {
        // Channel enrichment is optional. The provider-returned video record
        // remains sufficient for truthful catalogue and playback rendering.
      }
    }

    return eligible
        .map(
          (item) => mapScreen04YouTubePublicVideo(
            item,
            channel: channels[item.channelId],
          ),
        )
        .toList(growable: false);
  } finally {
    transport.close(force: true);
  }
}

Future<List<Screen04YouTubePublicVideo>>
loadScreen04YouTubePublicShorts() async {
  final transport = IoYouTubeHttpTransport();
  try {
    final client = YouTubePrivateDevClient.fromBuildConfiguration(
      transport: transport,
    );
    final capabilities = await client.capabilities();
    if (!capabilities.publicData) {
      throw StateError('Public YouTube Shorts viewing is unavailable.');
    }

    final page = await client.search(query: screen04YouTubeShortsQuery);
    final eligible = page.items
        .where(_isEligiblePublicVideo)
        .where(isScreen04CreatorDeclaredYouTubeShort)
        .take(8)
        .toList(growable: false);
    if (eligible.isEmpty) {
      throw StateError('No confirmed YouTube Shorts are available.');
    }

    return eligible.map(mapScreen04YouTubePublicVideo).toList(growable: false);
  } finally {
    transport.close(force: true);
  }
}

bool _isEligiblePublicVideo(YouTubeVideoSummary item) {
  return item.privacyStatus == 'public' &&
      item.uploadStatus == 'processed' &&
      item.embeddable == true &&
      item.availability != null &&
      !hasScreen04YouTubeRegionExclusion(
        item.regionRestriction,
        screen04YouTubeRegionCode,
      );
}

bool isScreen04CreatorDeclaredYouTubeShort(YouTubeVideoSummary item) {
  final durationSeconds = screen04YouTubeDurationSeconds(item.duration);
  if (durationSeconds == null ||
      durationSeconds <= 0 ||
      durationSeconds > screen04YouTubeShortMaximumSeconds) {
    return false;
  }

  final declaration = <String>[
    item.title,
    item.localized?.title ?? '',
    item.description,
    item.localized?.description ?? '',
    ...?item.tags,
  ].join(' ').toLowerCase();
  return RegExp(
    r'(^|[^a-z0-9])#?(?:youtube\s*)?shorts?(?=$|[^a-z0-9])',
  ).hasMatch(declaration);
}

int? screen04YouTubeDurationSeconds(String? duration) {
  if (duration == null || duration.trim().isEmpty) return null;
  final match = RegExp(
    r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$',
  ).firstMatch(duration.trim().toUpperCase());
  if (match == null) return null;
  final hours = int.tryParse(match.group(1) ?? '') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
  final seconds = int.tryParse(match.group(3) ?? '') ?? 0;
  return (hours * 3600) + (minutes * 60) + seconds;
}

Screen04YouTubePublicVideo mapScreen04YouTubePublicVideo(
  YouTubeVideoSummary item, {
  YouTubePublicChannelDetails? channel,
}) {
  return Screen04YouTubePublicVideo(
    videoId: item.videoId,
    title: item.localized?.title ?? item.title,
    channelId: item.channelId,
    channelTitle: item.channelTitle,
    description: item.localized?.description ?? item.description,
    thumbnailUrl: item.thumbnail.url,
    publishedAt: item.publishedAt,
    duration: item.duration,
    captionAvailable: item.captionAvailable,
    viewCount: item.viewCount,
    likeCount: item.likeCount,
    commentCount: item.commentCount,
    embeddable: item.embeddable == true,
    hasKnownDeviceRegionExclusion: hasScreen04YouTubeRegionExclusion(
      item.regionRestriction,
      screen04YouTubeRegionCode,
    ),
    hashtags: List.unmodifiable(
      (item.tags ?? const <String>[])
          .where((tag) => tag.trim().isNotEmpty)
          .take(3)
          .map((tag) => tag.startsWith('#') ? tag : '#$tag'),
    ),
    channelDescription: channel?.description,
    channelThumbnailUrl: channel?.thumbnail?.url,
    subscriberCount: channel?.statistics.subscriberCount,
    channelVideoCount: channel?.statistics.videoCount,
    channelViewCount: channel?.statistics.viewCount,
  );
}

String formatScreen04YouTubeCount(
  String? raw,
  String label, {
  String? unavailable,
}) {
  if (raw == null || raw.trim().isEmpty) {
    return unavailable ?? label;
  }
  final count = int.tryParse(raw);
  if (count == null) return '${raw.trim()} $label';
  final formatted = switch (count) {
    >= 1000000000 => '${_compactScreen04YouTubeNumber(count / 1000000000)}B',
    >= 1000000 => '${_compactScreen04YouTubeNumber(count / 1000000)}M',
    >= 1000 => '${_compactScreen04YouTubeNumber(count / 1000)}K',
    _ => '$count',
  };
  return '$formatted $label';
}

String _compactScreen04YouTubeNumber(double value) {
  final precision = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
  return value
      .toStringAsFixed(precision)
      .replaceFirst(RegExp(r'\.0+$'), '')
      .replaceFirstMapped(
        RegExp(r'(\.\d*[1-9])0+$'),
        (match) => match.group(1)!,
      );
}

bool hasScreen04YouTubeRegionExclusion(
  YouTubeRegionRestriction? restriction,
  String regionCode,
) {
  if (restriction == null) return false;
  final normalized = regionCode.toUpperCase();
  final blocked = restriction.blocked;
  if (blocked != null) {
    return blocked.any((value) => value.toUpperCase() == normalized);
  }
  final allowed = restriction.allowed;
  return allowed != null &&
      !allowed.any((value) => value.toUpperCase() == normalized);
}
