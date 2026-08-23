/// Closed, disabled-by-default contract for the future official YouTube
/// embedded-player boundary.
///
/// This file deliberately has no Flutter widget, WebView plugin or Screen 04
/// dependency. Platform adapters may consume it only after provider proof and
/// the remaining founder/release gates pass.
const youtubeEmbeddedPlayerBaseUrl = 'https://com.moolsocial.app/';
const youtubeEmbeddedPlayerOrigin = 'https://com.moolsocial.app';

const youtubeEmbeddedPlayerEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED',
  defaultValue: false,
);
const youtubeShortsAutoplayEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_SHORTS_AUTOPLAY_ENABLED',
  defaultValue: false,
);

class YouTubeEmbeddedPlayerFeatureConfig {
  const YouTubeEmbeddedPlayerFeatureConfig({
    required this.enabled,
    required this.shortsAutoplayEnabled,
  }) : assert(
         enabled || !shortsAutoplayEnabled,
         'Shorts autoplay cannot be enabled while the player is disabled.',
       );

  const YouTubeEmbeddedPlayerFeatureConfig.disabled()
    : enabled = false,
      shortsAutoplayEnabled = false;

  const YouTubeEmbeddedPlayerFeatureConfig.fromBuildConfiguration()
    : enabled = youtubeEmbeddedPlayerEnabled,
      shortsAutoplayEnabled =
          youtubeEmbeddedPlayerEnabled && youtubeShortsAutoplayEnabled;

  final bool enabled;
  final bool shortsAutoplayEnabled;
}

enum YouTubePlayerAspect { standardVideo, verifiedVerticalShort }

class YouTubePlayerGeometry {
  const YouTubePlayerGeometry({
    required this.width,
    required this.height,
    required this.aspect,
  });

  static const minimumCssDimension = 200.0;

  final double width;
  final double height;
  final YouTubePlayerAspect aspect;

  static YouTubePlayerGeometry forAvailableWidth({
    required double availableWidth,
    required YouTubePlayerAspect aspect,
  }) {
    if (!availableWidth.isFinite || availableWidth < minimumCssDimension) {
      throw ArgumentError.value(
        availableWidth,
        'availableWidth',
        'The official player requires at least 200 CSS pixels.',
      );
    }

    final aspectHeight = switch (aspect) {
      YouTubePlayerAspect.standardVideo => availableWidth * 9 / 16,
      YouTubePlayerAspect.verifiedVerticalShort => availableWidth * 16 / 9,
    };
    return YouTubePlayerGeometry(
      width: availableWidth,
      height: aspectHeight < minimumCssDimension
          ? minimumCssDimension
          : aspectHeight,
      aspect: aspect,
    );
  }
}

class YouTubeEmbeddedVideoRecord {
  const YouTubeEmbeddedVideoRecord({
    required this.videoId,
    required this.hasCurrentDataApiRecord,
    required this.embeddable,
    required this.hasKnownDeviceRegionExclusion,
    required this.isVerifiedVerticalShort,
  });

  final String videoId;
  final bool hasCurrentDataApiRecord;
  final bool embeddable;
  final bool hasKnownDeviceRegionExclusion;
  final bool isVerifiedVerticalShort;
}

enum YouTubePlayerEligibilityReason {
  eligible,
  invalidVideoId,
  missingCurrentDataApiRecord,
  embeddingDisabled,
  knownDeviceRegionExclusion,
}

class YouTubePlayerEligibility {
  const YouTubePlayerEligibility({
    required this.eligible,
    required this.reason,
  });

  final bool eligible;
  final YouTubePlayerEligibilityReason reason;
}

class YouTubePlayerEligibilityPolicy {
  const YouTubePlayerEligibilityPolicy._();

  static final RegExp _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');

  static YouTubePlayerEligibility evaluate(YouTubeEmbeddedVideoRecord record) {
    if (!_videoId.hasMatch(record.videoId)) {
      return const YouTubePlayerEligibility(
        eligible: false,
        reason: YouTubePlayerEligibilityReason.invalidVideoId,
      );
    }
    if (!record.hasCurrentDataApiRecord) {
      return const YouTubePlayerEligibility(
        eligible: false,
        reason: YouTubePlayerEligibilityReason.missingCurrentDataApiRecord,
      );
    }
    if (!record.embeddable) {
      return const YouTubePlayerEligibility(
        eligible: false,
        reason: YouTubePlayerEligibilityReason.embeddingDisabled,
      );
    }
    if (record.hasKnownDeviceRegionExclusion) {
      return const YouTubePlayerEligibility(
        eligible: false,
        reason: YouTubePlayerEligibilityReason.knownDeviceRegionExclusion,
      );
    }
    return const YouTubePlayerEligibility(
      eligible: true,
      reason: YouTubePlayerEligibilityReason.eligible,
    );
  }
}

enum YouTubeProviderPlayerState {
  initializing(-1),
  ended(0),
  playing(1),
  paused(2),
  buffering(3),
  cued(5);

  const YouTubeProviderPlayerState(this.providerCode);

  final int providerCode;

  static YouTubeProviderPlayerState? fromProviderCode(int code) {
    for (final state in values) {
      if (state.providerCode == code) return state;
    }
    return null;
  }
}

enum YouTubePlayerRecoveryAction {
  reportIntegrationDefect,
  recreateOnceThenOpenInYouTube,
  refreshMetadataAndRemoveStaleResult,
  openInYouTube,
  blockReleaseForIdentityConfiguration,
  showTruthfulUnavailableState,
}

class YouTubePlayerErrorDisposition {
  const YouTubePlayerErrorDisposition({
    required this.providerCode,
    required this.retryableInPlayer,
    required this.action,
  });

  final int providerCode;
  final bool retryableInPlayer;
  final YouTubePlayerRecoveryAction action;
}

class YouTubePlayerErrorPolicy {
  const YouTubePlayerErrorPolicy._();

  static YouTubePlayerErrorDisposition evaluate(
    int code, {
    required bool recreationAlreadyUsed,
  }) {
    return switch (code) {
      2 => const YouTubePlayerErrorDisposition(
        providerCode: 2,
        retryableInPlayer: false,
        action: YouTubePlayerRecoveryAction.reportIntegrationDefect,
      ),
      5 => YouTubePlayerErrorDisposition(
        providerCode: 5,
        retryableInPlayer: !recreationAlreadyUsed,
        action: YouTubePlayerRecoveryAction.recreateOnceThenOpenInYouTube,
      ),
      100 => const YouTubePlayerErrorDisposition(
        providerCode: 100,
        retryableInPlayer: false,
        action: YouTubePlayerRecoveryAction.refreshMetadataAndRemoveStaleResult,
      ),
      101 || 150 => YouTubePlayerErrorDisposition(
        providerCode: code,
        retryableInPlayer: false,
        action: YouTubePlayerRecoveryAction.openInYouTube,
      ),
      153 => const YouTubePlayerErrorDisposition(
        providerCode: 153,
        retryableInPlayer: false,
        action:
            YouTubePlayerRecoveryAction.blockReleaseForIdentityConfiguration,
      ),
      _ => YouTubePlayerErrorDisposition(
        providerCode: code,
        retryableInPlayer: false,
        action: YouTubePlayerRecoveryAction.showTruthfulUnavailableState,
      ),
    };
  }
}
