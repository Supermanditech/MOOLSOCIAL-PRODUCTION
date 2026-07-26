import 'dart:math';

import 'package:flutter/foundation.dart';

import 'youtube_private_dev_app_check.dart';
import 'youtube_private_dev_client.dart';
import 'youtube_private_dev_models.dart';
import 'youtube_private_dev_transport.dart';
import 'youtube_private_dev_uploader.dart';
import 'youtube_private_dev_workflow.dart';

const _proofProfile = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_PROFILE',
);
const _proofConfirmation = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_CONFIRMATION',
);
const _candidateId = String.fromEnvironment('MOOLSOCIAL_CANDIDATE_ID');
const _useEmulators = bool.fromEnvironment(
  'MOOLSOCIAL_USE_EMULATORS',
  defaultValue: true,
);
const _firebaseProjectId = String.fromEnvironment(
  'MOOLSOCIAL_FIREBASE_PROJECT_ID',
);
const _publicRegionCode = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_REGION_CODE',
);
const _publicPlaylistId = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_PLAYLIST_ID',
);
const _publicSearchQuery = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_SEARCH_QUERY',
);
const _expectedChannelId = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_EXPECTED_CHANNEL_ID',
);
const _uploadTitle = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_TITLE',
);
const _uploadDescription = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_DESCRIPTION',
);
const _uploadCategoryId = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_CATEGORY_ID',
);
const _uploadMadeForKids = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_MADE_FOR_KIDS',
);
const _uploadContainsSyntheticMedia = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_CONTAINS_SYNTHETIC_MEDIA',
);
const _uploadContainsPaidPromotion = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_CONTAINS_PAID_PROMOTION',
);
const _uploadNotifySubscribers = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_NOTIFY_SUBSCRIBERS',
);
const _uploadRightsConfirmed = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_RIGHTS_CONFIRMED',
);
const _uploadPolicyConfirmed = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_UPLOAD_POLICY_CONFIRMED',
);
const _analyticsStartDate = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_ANALYTICS_START_DATE',
);
const _analyticsEndDate = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_ANALYTICS_END_DATE',
);
const _analyticsPresets = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_ANALYTICS_PRESETS',
);
const _analyticsRetentionVideoId = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROOF_ANALYTICS_RETENTION_VIDEO_ID',
);

const _googleAuthorizationOriginAndPath =
    'https://accounts.google.com/o/oauth2/v2/auth';
const _youtubeOAuthCallback =
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
    'youtubeOAuthCallback';
const _youtubeReadonlyScope =
    'https://www.googleapis.com/auth/youtube.readonly';
const _youtubeForceSslScope =
    'https://www.googleapis.com/auth/youtube.force-ssl';
const _youtubeUploadScope = 'https://www.googleapis.com/auth/youtube.upload';
const _youtubeAnalyticsReadonlyScope =
    'https://www.googleapis.com/auth/yt-analytics.readonly';
const _youtubeManageScope = 'https://www.googleapis.com/auth/youtube';
const _youtubeMembershipsCreatorScope =
    'https://www.googleapis.com/auth/youtube.channel-memberships.creator';

enum YouTubePrivateDevProofProfile {
  publicData,
  ownerConnect,
  privateUpload,
  ownerAnalytics,
  live,
  disconnectDelete,
}

extension YouTubePrivateDevProofProfileWireValue
    on YouTubePrivateDevProofProfile {
  String get wireValue => switch (this) {
    YouTubePrivateDevProofProfile.publicData => 'publicData',
    YouTubePrivateDevProofProfile.ownerConnect => 'ownerConnect',
    YouTubePrivateDevProofProfile.privateUpload => 'privateUpload',
    YouTubePrivateDevProofProfile.ownerAnalytics => 'ownerAnalytics',
    YouTubePrivateDevProofProfile.live => 'live',
    YouTubePrivateDevProofProfile.disconnectDelete => 'disconnectDelete',
  };
}

class YouTubePrivateDevProofConfiguration {
  const YouTubePrivateDevProofConfiguration._({
    required this.profile,
    required this.candidateId,
    required this.regionCode,
    required this.playlistId,
    required this.searchQuery,
    required this.expectedChannelId,
    required this.uploadMetadata,
    required this.analyticsStartDate,
    required this.analyticsEndDate,
    required this.analyticsPresets,
    required this.analyticsRetentionVideoId,
  });

  factory YouTubePrivateDevProofConfiguration.fromBuildConfiguration() {
    return YouTubePrivateDevProofConfiguration.forTesting(
      proofEnabled: youtubePrivateDevProofEnabled,
      useEmulators: _useEmulators,
      firebaseProjectId: _firebaseProjectId,
      profile: _proofProfile,
      confirmation: _proofConfirmation,
      candidateId: _candidateId,
      regionCode: _publicRegionCode,
      playlistId: _publicPlaylistId,
      searchQuery: _publicSearchQuery,
      expectedChannelId: _expectedChannelId,
      uploadTitle: _uploadTitle,
      uploadDescription: _uploadDescription,
      uploadCategoryId: _uploadCategoryId,
      uploadMadeForKids: _uploadMadeForKids,
      uploadContainsSyntheticMedia: _uploadContainsSyntheticMedia,
      uploadContainsPaidPromotion: _uploadContainsPaidPromotion,
      uploadNotifySubscribers: _uploadNotifySubscribers,
      uploadRightsConfirmed: _uploadRightsConfirmed,
      uploadPolicyConfirmed: _uploadPolicyConfirmed,
      analyticsStartDate: _analyticsStartDate,
      analyticsEndDate: _analyticsEndDate,
      analyticsPresets: _analyticsPresets,
      analyticsRetentionVideoId: _analyticsRetentionVideoId,
    );
  }

  @visibleForTesting
  factory YouTubePrivateDevProofConfiguration.forTesting({
    required bool proofEnabled,
    required bool useEmulators,
    required String firebaseProjectId,
    required String profile,
    required String confirmation,
    required String candidateId,
    String regionCode = '',
    String playlistId = '',
    String searchQuery = '',
    String expectedChannelId = '',
    String uploadTitle = '',
    String uploadDescription = '',
    String uploadCategoryId = '',
    String uploadMadeForKids = '',
    String uploadContainsSyntheticMedia = '',
    String uploadContainsPaidPromotion = '',
    String uploadNotifySubscribers = '',
    String uploadRightsConfirmed = '',
    String uploadPolicyConfirmed = '',
    String analyticsStartDate = '',
    String analyticsEndDate = '',
    String analyticsPresets = '',
    String analyticsRetentionVideoId = '',
  }) {
    if (!proofEnabled ||
        useEmulators ||
        firebaseProjectId != youtubePrivateDevProjectId) {
      throw StateError(
        'The supervised proof requires the dedicated real-service Dev project.',
      );
    }

    final parsedProfile = _parseProfile(profile);
    if (confirmation != _confirmationFor(parsedProfile)) {
      throw StateError(
        'The selected supervised proof profile is not explicitly confirmed.',
      );
    }
    final cleanCandidate = candidateId.trim();
    if (!RegExp(r'^[A-Za-z0-9._-]{1,80}$').hasMatch(cleanCandidate)) {
      throw const FormatException('A safe candidate identifier is required.');
    }

    var cleanRegion = '';
    var cleanPlaylist = '';
    var cleanQuery = '';
    var cleanExpectedChannel = '';
    YouTubePrivateUploadMetadata? metadata;
    DateTime? parsedStartDate;
    DateTime? parsedEndDate;
    var parsedPresets = const <YouTubeOwnerAnalyticsPreset>[];
    String? retentionVideoId;

    switch (parsedProfile) {
      case YouTubePrivateDevProofProfile.publicData:
        cleanRegion = _requiredMatch(
          regionCode,
          RegExp(r'^[A-Z]{2}$'),
          'region code',
        );
        cleanPlaylist = _requiredMatch(
          playlistId,
          RegExp(r'^[A-Za-z0-9_-]{10,80}$'),
          'playlist identifier',
        );
        cleanQuery = _requiredText(searchQuery, 'search query', maximum: 100);
      case YouTubePrivateDevProofProfile.ownerConnect:
        cleanExpectedChannel = _channelId(expectedChannelId);
      case YouTubePrivateDevProofProfile.privateUpload:
        cleanExpectedChannel = _channelId(expectedChannelId);
        if (_strictBool(uploadRightsConfirmed, 'rights confirmation') != true ||
            _strictBool(uploadPolicyConfirmed, 'policy confirmation') != true) {
          throw StateError(
            'Rights and private-upload policy must be explicitly confirmed.',
          );
        }
        metadata = YouTubePrivateUploadMetadata(
          title: _requiredText(uploadTitle, 'upload title', maximum: 100),
          description: _requiredText(
            uploadDescription,
            'upload description',
            maximum: 5000,
          ),
          categoryId: _requiredMatch(
            uploadCategoryId,
            RegExp(r'^[0-9]{1,3}$'),
            'upload category',
          ),
          madeForKids: _strictBool(uploadMadeForKids, 'made-for-kids'),
          containsSyntheticMedia: _strictBool(
            uploadContainsSyntheticMedia,
            'synthetic-media',
          ),
          containsPaidPromotion: _strictBool(
            uploadContainsPaidPromotion,
            'paid-promotion',
          ),
          notifySubscribers: _strictBool(
            uploadNotifySubscribers,
            'subscriber-notification',
          ),
        );
      case YouTubePrivateDevProofProfile.ownerAnalytics:
        cleanExpectedChannel = _channelId(expectedChannelId);
        parsedStartDate = _strictDate(analyticsStartDate, 'analytics start');
        parsedEndDate = _strictDate(analyticsEndDate, 'analytics end');
        if (parsedEndDate.isBefore(parsedStartDate)) {
          throw const FormatException(
            'The analytics date range must be chronological.',
          );
        }
        parsedPresets = _parsePresets(analyticsPresets);
        if (parsedPresets.contains(
          YouTubeOwnerAnalyticsPreset.videoRetention,
        )) {
          retentionVideoId = _videoId(analyticsRetentionVideoId);
        } else if (analyticsRetentionVideoId.trim().isNotEmpty) {
          throw const FormatException(
            'A retention video is valid only for the retention preset.',
          );
        }
      case YouTubePrivateDevProofProfile.live:
        cleanExpectedChannel = _channelId(expectedChannelId);
      case YouTubePrivateDevProofProfile.disconnectDelete:
        break;
    }

    return YouTubePrivateDevProofConfiguration._(
      profile: parsedProfile,
      candidateId: cleanCandidate,
      regionCode: cleanRegion,
      playlistId: cleanPlaylist,
      searchQuery: cleanQuery,
      expectedChannelId: cleanExpectedChannel,
      uploadMetadata: metadata,
      analyticsStartDate: parsedStartDate,
      analyticsEndDate: parsedEndDate,
      analyticsPresets: parsedPresets,
      analyticsRetentionVideoId: retentionVideoId,
    );
  }

  final YouTubePrivateDevProofProfile profile;
  final String candidateId;
  final String regionCode;
  final String playlistId;
  final String searchQuery;
  final String expectedChannelId;
  final YouTubePrivateUploadMetadata? uploadMetadata;
  final DateTime? analyticsStartDate;
  final DateTime? analyticsEndDate;
  final List<YouTubeOwnerAnalyticsPreset> analyticsPresets;
  final String? analyticsRetentionVideoId;
}

abstract interface class YouTubePrivateDevProofGateway {
  Future<YouTubePrivateDevCapabilities> capabilities();

  Future<YouTubeVideoPage> mostPopular({String? regionCode, String? pageToken});

  Future<YouTubeVideoPage> playlist({
    required String playlistId,
    String? pageToken,
  });

  Future<YouTubeVideoPage> search({required String query, String? pageToken});

  Future<List<YouTubeVideoSummary>> videoDetails(List<String> videoIds);

  Future<YouTubeConnectionStart> startConnection(YouTubeConnectPurpose purpose);

  Future<YouTubeConnectionStatus> connectionStatus();

  Future<YouTubeVideoSummary> uploadPrivate({
    required String idempotencyKey,
    required YouTubeUploadSource source,
    required YouTubePrivateUploadMetadata metadata,
    YouTubeUploadProgress? onProgress,
  });

  Future<YouTubeOwnerAnalyticsResult> analyticsPreset({
    required YouTubeOwnerAnalyticsPreset preset,
    required DateTime startDate,
    required DateTime endDate,
    String? videoId,
  });

  Future<YouTubeDisconnectResult> disconnect();
}

class RealYouTubePrivateDevProofGateway
    implements YouTubePrivateDevProofGateway {
  factory RealYouTubePrivateDevProofGateway({
    required YouTubePrivateDevClient client,
    required YouTubePrivateDevUploadWorkflow uploadWorkflow,
  }) {
    return RealYouTubePrivateDevProofGateway._(client, uploadWorkflow);
  }

  const RealYouTubePrivateDevProofGateway._(this._client, this._uploadWorkflow);

  final YouTubePrivateDevClient _client;
  final YouTubePrivateDevUploadWorkflow _uploadWorkflow;

  @override
  Future<YouTubePrivateDevCapabilities> capabilities() =>
      _client.capabilities();

  @override
  Future<YouTubeConnectionStatus> connectionStatus() =>
      _client.connectionStatus();

  @override
  Future<YouTubeDisconnectResult> disconnect() => _client.disconnect();

  @override
  Future<YouTubeOwnerAnalyticsResult> analyticsPreset({
    required YouTubeOwnerAnalyticsPreset preset,
    required DateTime startDate,
    required DateTime endDate,
    String? videoId,
  }) {
    return _client.analyticsPreset(
      preset: preset,
      startDate: startDate,
      endDate: endDate,
      videoId: videoId,
    );
  }

  @override
  Future<YouTubeVideoPage> mostPopular({
    String? regionCode,
    String? pageToken,
  }) {
    return _client.mostPopular(regionCode: regionCode, pageToken: pageToken);
  }

  @override
  Future<YouTubeVideoPage> playlist({
    required String playlistId,
    String? pageToken,
  }) {
    return _client.playlist(playlistId: playlistId, pageToken: pageToken);
  }

  @override
  Future<YouTubeVideoPage> search({required String query, String? pageToken}) {
    return _client.search(query: query, pageToken: pageToken);
  }

  @override
  Future<YouTubeConnectionStart> startConnection(
    YouTubeConnectPurpose purpose,
  ) {
    return _client.startConnection(purpose: purpose, promptForConsent: true);
  }

  @override
  Future<YouTubeVideoSummary> uploadPrivate({
    required String idempotencyKey,
    required YouTubeUploadSource source,
    required YouTubePrivateUploadMetadata metadata,
    YouTubeUploadProgress? onProgress,
  }) {
    return _uploadWorkflow.uploadPrivate(
      idempotencyKey: idempotencyKey,
      contentType: 'video/mp4',
      source: source,
      metadata: metadata,
      onProgress: onProgress,
      maximumProcessingAttempts: 60,
      processingInterval: const Duration(seconds: 10),
    );
  }

  @override
  Future<List<YouTubeVideoSummary>> videoDetails(List<String> videoIds) =>
      _client.videoDetails(videoIds);
}

abstract interface class YouTubePrivateDevAuthorizationLauncher {
  Future<void> openInSystemBrowser(Uri authorizationUrl);
}

abstract interface class YouTubePrivateDevMediaSelector {
  Future<YouTubeUploadSource?> selectRightsClearedMp4();
}

enum YouTubePrivateDevProofOutcome { passed, failed }

class YouTubePrivateDevProofEvidence {
  const YouTubePrivateDevProofEvidence({
    required this.candidateId,
    required this.profile,
    required this.startedAt,
    required this.finishedAt,
    required this.outcome,
    required this.observations,
    this.error,
  });

  final String candidateId;
  final YouTubePrivateDevProofProfile profile;
  final DateTime startedAt;
  final DateTime finishedAt;
  final YouTubePrivateDevProofOutcome outcome;
  final Map<String, Object?> observations;
  final YouTubePrivateDevProofError? error;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': 1,
      'candidateId': candidateId,
      'firebaseProjectId': youtubePrivateDevProjectId,
      'profile': profile.wireValue,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'finishedAt': finishedAt.toUtc().toIso8601String(),
      'outcome': outcome.name,
      'observations': observations,
      if (error case final value?) 'error': value.toJson(),
    };
  }
}

class YouTubePrivateDevProofError {
  const YouTubePrivateDevProofError({
    required this.code,
    required this.retryable,
    this.statusCode,
  });

  final String code;
  final bool retryable;
  final int? statusCode;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code,
      'retryable': retryable,
      'statusCode': ?statusCode,
    };
  }
}

class YouTubePrivateDevProofHarness {
  factory YouTubePrivateDevProofHarness({
    required YouTubePrivateDevProofConfiguration configuration,
    required YouTubePrivateDevProofGateway gateway,
    YouTubePrivateDevAuthorizationLauncher? authorizationLauncher,
    YouTubePrivateDevMediaSelector? mediaSelector,
    DateTime Function()? now,
    Future<void> Function(Duration duration)? delay,
    String Function()? idempotencyKey,
  }) {
    return YouTubePrivateDevProofHarness._(
      configuration: configuration,
      gateway: gateway,
      authorizationLauncher: authorizationLauncher,
      mediaSelector: mediaSelector,
      now: now ?? DateTime.now,
      delay: delay ?? Future<void>.delayed,
      idempotencyKey: idempotencyKey ?? _secureIdempotencyKey,
    );
  }

  YouTubePrivateDevProofHarness._({
    required this.configuration,
    required this._gateway,
    required this._authorizationLauncher,
    required this._mediaSelector,
    required this._now,
    required this._delay,
    required this._idempotencyKey,
  });

  final YouTubePrivateDevProofConfiguration configuration;
  final YouTubePrivateDevProofGateway _gateway;
  final YouTubePrivateDevAuthorizationLauncher? _authorizationLauncher;
  final YouTubePrivateDevMediaSelector? _mediaSelector;
  final DateTime Function() _now;
  final Future<void> Function(Duration duration) _delay;
  final String Function() _idempotencyKey;

  Future<YouTubePrivateDevProofEvidence> run() async {
    final started = _now().toUtc();
    try {
      final observations = switch (configuration.profile) {
        YouTubePrivateDevProofProfile.publicData => await _runPublicData(),
        YouTubePrivateDevProofProfile.ownerConnect => await _runOwnerConnect(),
        YouTubePrivateDevProofProfile.privateUpload =>
          await _runPrivateUpload(),
        YouTubePrivateDevProofProfile.ownerAnalytics =>
          await _runOwnerAnalytics(),
        YouTubePrivateDevProofProfile.live => await _runLive(),
        YouTubePrivateDevProofProfile.disconnectDelete =>
          await _runDisconnectDelete(),
      };
      return YouTubePrivateDevProofEvidence(
        candidateId: configuration.candidateId,
        profile: configuration.profile,
        startedAt: started,
        finishedAt: _now().toUtc(),
        outcome: YouTubePrivateDevProofOutcome.passed,
        observations: Map.unmodifiable(observations),
      );
    } catch (error) {
      return YouTubePrivateDevProofEvidence(
        candidateId: configuration.candidateId,
        profile: configuration.profile,
        startedAt: started,
        finishedAt: _now().toUtc(),
        outcome: YouTubePrivateDevProofOutcome.failed,
        observations: const <String, Object?>{},
        error: _redactedError(error),
      );
    }
  }

  Future<Map<String, Object?>> _runPublicData() async {
    final capabilities = await _gateway.capabilities();
    _requireCapabilities(
      capabilities,
      expected: YouTubePrivateDevProofProfile.publicData,
    );
    final popular = await _gateway.mostPopular(
      regionCode: configuration.regionCode,
    );
    final playlist = await _gateway.playlist(
      playlistId: configuration.playlistId,
    );
    final search = await _gateway.search(query: configuration.searchQuery);
    if (popular.items.isEmpty ||
        playlist.items.isEmpty ||
        search.items.isEmpty) {
      throw const YouTubePrivateDevProofFailure('public_page_empty');
    }

    YouTubeVideoPage? nextPage;
    var paginationSource = '';
    if (_hasText(popular.nextPageToken)) {
      paginationSource = 'mostPopular';
      nextPage = await _gateway.mostPopular(
        regionCode: configuration.regionCode,
        pageToken: popular.nextPageToken,
      );
    } else if (_hasText(playlist.nextPageToken)) {
      paginationSource = 'playlist';
      nextPage = await _gateway.playlist(
        playlistId: configuration.playlistId,
        pageToken: playlist.nextPageToken,
      );
    } else if (_hasText(search.nextPageToken)) {
      paginationSource = 'search';
      nextPage = await _gateway.search(
        query: configuration.searchQuery,
        pageToken: search.nextPageToken,
      );
    }
    if (nextPage == null || nextPage.items.isEmpty) {
      throw const YouTubePrivateDevProofFailure('pagination_unavailable');
    }

    final videoIds = <String>{
      ...popular.items.map((item) => item.videoId),
      ...playlist.items.map((item) => item.videoId),
      ...search.items.map((item) => item.videoId),
      ...nextPage.items.map((item) => item.videoId),
    }.toList(growable: false);
    if (videoIds.length < 2) {
      throw const YouTubePrivateDevProofFailure(
        'insufficient_distinct_public_videos',
      );
    }
    final details = await _gateway.videoDetails(videoIds.take(20).toList());
    if (details.isEmpty ||
        details.any(
          (item) => item.privacyStatus != 'public' || item.embeddable != true,
        )) {
      throw const YouTubePrivateDevProofFailure(
        'ineligible_public_video_returned',
      );
    }

    return <String, Object?>{
      'capabilityProfileMatched': true,
      'mostPopularCount': popular.items.length,
      'playlistCount': playlist.items.length,
      'searchCount': search.items.length,
      'paginationObserved': true,
      'paginationSource': paginationSource,
      'paginationCount': nextPage.items.length,
      'distinctVideoCount': videoIds.length,
      'hydratedVideoCount': details.length,
      'allHydratedVideosPublicAndEmbeddable': true,
    };
  }

  Future<Map<String, Object?>> _runOwnerConnect() async {
    final capabilities = await _gateway.capabilities();
    _requireCapabilities(
      capabilities,
      expected: YouTubePrivateDevProofProfile.ownerConnect,
    );
    final connection = await _ensureOwnerConnection(
      purpose: YouTubeConnectPurpose.readonly,
      forceAuthorization: true,
    );
    return <String, Object?>{
      'capabilityProfileMatched': true,
      'authorizationContractValidated':
          connection.authorizationContractValidated,
      'systemBrowserLaunched': connection.authorizationLaunched,
      'connectionObserved': true,
      'expectedChannelMatched': true,
      'readonlyScopeConfirmed': true,
    };
  }

  Future<Map<String, Object?>> _runPrivateUpload() async {
    final selector = _mediaSelector;
    if (selector == null || configuration.uploadMetadata == null) {
      throw const YouTubePrivateDevProofFailure('media_selector_required');
    }
    final capabilities = await _gateway.capabilities();
    _requireCapabilities(
      capabilities,
      expected: YouTubePrivateDevProofProfile.privateUpload,
    );
    final connection = await _ensureOwnerConnection(
      purpose: YouTubeConnectPurpose.upload,
    );
    final source = await selector.selectRightsClearedMp4();
    if (source == null) {
      throw const YouTubePrivateDevProofFailure('media_selection_cancelled');
    }
    var progressObserved = false;
    final uploaded = await _gateway.uploadPrivate(
      idempotencyKey: _idempotencyKey(),
      source: source,
      metadata: configuration.uploadMetadata!,
      onProgress: (accepted, total) {
        if (accepted > 0 && total > 0 && accepted <= total) {
          progressObserved = true;
        }
      },
    );
    if (uploaded.channelId != configuration.expectedChannelId ||
        uploaded.privacyStatus != 'private' ||
        uploaded.processingOutcome !=
            YouTubeUploadProcessingOutcome.succeeded) {
      throw const YouTubePrivateDevProofFailure(
        'private_upload_completion_not_confirmed',
      );
    }
    return <String, Object?>{
      'capabilityProfileMatched': true,
      'rightsAndPolicyExplicitlyConfirmed': true,
      'incrementalAuthorizationLaunched': connection.authorizationLaunched,
      'requiredOwnerScopesConfirmed': true,
      'mediaSelectedByFounder': true,
      'directDeviceToProviderWorkflowUsed': true,
      'functionsOrMoolSocialStorageMediaBytesUsed': false,
      'progressObserved': progressObserved,
      'expectedChannelMatched': true,
      'privacyPrivateConfirmed': true,
      'providerProcessingSucceeded': true,
    };
  }

  Future<Map<String, Object?>> _runOwnerAnalytics() async {
    final capabilities = await _gateway.capabilities();
    _requireCapabilities(
      capabilities,
      expected: YouTubePrivateDevProofProfile.ownerAnalytics,
    );
    final connection = await _ensureOwnerConnection(
      purpose: YouTubeConnectPurpose.analytics,
    );
    final start = configuration.analyticsStartDate!;
    final end = configuration.analyticsEndDate!;
    final results = <Map<String, Object?>>[];
    for (final preset in configuration.analyticsPresets) {
      final result = await _gateway.analyticsPreset(
        preset: preset,
        startDate: start,
        endDate: end,
        videoId: preset == YouTubeOwnerAnalyticsPreset.videoRetention
            ? configuration.analyticsRetentionVideoId
            : null,
      );
      if (result.preset != preset ||
          result.requestedStartDate != _date(start) ||
          result.requestedEndDate != _date(end) ||
          result.empty != result.rows.isEmpty) {
        throw const YouTubePrivateDevProofFailure(
          'analytics_contract_mismatch',
        );
      }
      results.add(<String, Object?>{
        'preset': preset.wireValue,
        'rowCount': result.rows.length,
        'empty': result.empty,
        'providerMayExcludeRecentIncompleteDays':
            result.providerMayExcludeRecentIncompleteDays,
      });
    }
    return <String, Object?>{
      'capabilityProfileMatched': true,
      'incrementalAuthorizationLaunched': connection.authorizationLaunched,
      'requiredOwnerScopesConfirmed': true,
      'requestedRangeMatched': true,
      'presetCount': results.length,
      'presetResults': results,
      'metricValuesExcludedFromEvidence': true,
    };
  }

  Future<Map<String, Object?>> _runLive() async {
    final capabilities = await _gateway.capabilities();
    _requireCapabilities(
      capabilities,
      expected: YouTubePrivateDevProofProfile.live,
    );
    final connection = await _ensureOwnerConnection(
      purpose: YouTubeConnectPurpose.live,
    );
    return <String, Object?>{
      'capabilityProfileMatched': true,
      'incrementalAuthorizationLaunched': connection.authorizationLaunched,
      'liveManagementScopeConfirmed': true,
      'membershipScopeRemainsSeparate': true,
      'mutationExecuted': false,
      'streamingProxyCreated': false,
    };
  }

  Future<Map<String, Object?>> _runDisconnectDelete() async {
    final capabilities = await _gateway.capabilities();
    _requireCapabilities(
      capabilities,
      expected: YouTubePrivateDevProofProfile.disconnectDelete,
    );
    final first = await _gateway.disconnect();
    final second = await _gateway.disconnect();
    if (!first.disconnected || !second.disconnected) {
      throw const YouTubePrivateDevProofFailure(
        'disconnect_idempotency_not_confirmed',
      );
    }
    return <String, Object?>{
      'allProviderProfilesDisabled': true,
      'firstDisconnectConfirmed': first.disconnected,
      'firstProviderRevocationConfirmed': first.providerRevocationConfirmed,
      'secondDisconnectConfirmed': second.disconnected,
      'secondProviderRevocationConfirmed': second.providerRevocationConfirmed,
      'idempotentDisconnectConfirmed': true,
      'providerAccountDeletionClaimed': false,
      'livePostDeleteStorageInspectionIncluded': false,
      'separateAdministratorStorageEvidenceRequired': true,
    };
  }

  void _requireCapabilities(
    YouTubePrivateDevCapabilities value, {
    required YouTubePrivateDevProofProfile expected,
  }) {
    final actual = <YouTubePrivateDevProofProfile>[
      if (value.publicData) YouTubePrivateDevProofProfile.publicData,
      if (value.ownerConnect) YouTubePrivateDevProofProfile.ownerConnect,
      if (value.privateUpload) YouTubePrivateDevProofProfile.privateUpload,
      if (value.ownerAnalytics) YouTubePrivateDevProofProfile.ownerAnalytics,
      if (value.live) YouTubePrivateDevProofProfile.live,
    ];
    final valid =
        value.environment == 'dev' &&
        value.publicOrUnlistedUpload == false &&
        (expected == YouTubePrivateDevProofProfile.disconnectDelete
            ? actual.isEmpty
            : actual.length == 1 && actual.single == expected);
    if (!valid) {
      throw const YouTubePrivateDevProofFailure('provider_profile_mismatch');
    }
  }

  Future<_OwnerConnectionProof> _ensureOwnerConnection({
    required YouTubeConnectPurpose purpose,
    bool forceAuthorization = false,
  }) async {
    if (!forceAuthorization) {
      final existing = await _gateway.connectionStatus();
      if (existing is YouTubeConnected) {
        _requireExpectedChannel(existing);
        if (_hasRequiredScopes(existing, purpose)) {
          return const _OwnerConnectionProof(
            authorizationLaunched: false,
            authorizationContractValidated: false,
          );
        }
      }
    }

    final launcher = _authorizationLauncher;
    if (launcher == null) {
      throw const YouTubePrivateDevProofFailure(
        'system_browser_launcher_required',
      );
    }
    final start = await _gateway.startConnection(purpose);
    _validateAuthorizationUrl(start, purpose);
    await launcher.openInSystemBrowser(start.authorizationUrl);

    YouTubeConnected? connected;
    for (var attempt = 0; attempt < 180; attempt += 1) {
      final status = await _gateway.connectionStatus();
      if (status is YouTubeConnected && _hasRequiredScopes(status, purpose)) {
        connected = status;
        break;
      }
      if (!start.expiresAt.isAfter(_now().toUtc())) break;
      await _delay(const Duration(seconds: 5));
    }
    if (connected == null) {
      throw const YouTubePrivateDevProofFailure(
        'owner_connection_not_completed',
        retryable: true,
      );
    }
    _requireExpectedChannel(connected);
    return const _OwnerConnectionProof(
      authorizationLaunched: true,
      authorizationContractValidated: true,
    );
  }

  void _requireExpectedChannel(YouTubeConnected connected) {
    if (connected.channelId != configuration.expectedChannelId) {
      throw const YouTubePrivateDevProofFailure('connected_channel_mismatch');
    }
  }

  bool _hasRequiredScopes(
    YouTubeConnected connected,
    YouTubeConnectPurpose purpose,
  ) {
    final granted = connected.grantedScopes.toSet();
    return _scopesFor(purpose).every(granted.contains);
  }

  void _validateAuthorizationUrl(
    YouTubeConnectionStart start,
    YouTubeConnectPurpose purpose,
  ) {
    final uri = start.authorizationUrl;
    final originAndPath = '${uri.scheme}://${uri.host}${uri.path}';
    final query = uri.queryParameters;
    final scopes = (query['scope'] ?? '')
        .split(' ')
        .where((scope) => scope.isNotEmpty)
        .toSet();
    final expectedScopes = _scopesFor(purpose).toSet();
    final valid =
        originAndPath == _googleAuthorizationOriginAndPath &&
        !uri.hasPort &&
        uri.userInfo.isEmpty &&
        !uri.hasFragment &&
        query['redirect_uri'] == _youtubeOAuthCallback &&
        query['response_type'] == 'code' &&
        _hasText(query['client_id']) &&
        _hasText(query['state']) &&
        _hasText(query['code_challenge']) &&
        query['code_challenge_method'] == 'S256' &&
        query['access_type'] == 'offline' &&
        query['include_granted_scopes'] == 'true' &&
        query['prompt'] == 'consent' &&
        scopes.length == expectedScopes.length &&
        scopes.containsAll(expectedScopes) &&
        !query.containsKey('client_secret') &&
        start.expiresAt.isAfter(_now().toUtc());
    if (!valid) {
      throw const YouTubePrivateDevProofFailure(
        'invalid_authorization_contract',
      );
    }
  }
}

class _OwnerConnectionProof {
  const _OwnerConnectionProof({
    required this.authorizationLaunched,
    required this.authorizationContractValidated,
  });

  final bool authorizationLaunched;
  final bool authorizationContractValidated;
}

class YouTubePrivateDevProofFailure implements Exception {
  const YouTubePrivateDevProofFailure(
    this.code, {
    this.retryable = false,
    this.statusCode,
  });

  final String code;
  final bool retryable;
  final int? statusCode;
}

YouTubePrivateDevProofError _redactedError(Object error) {
  return switch (error) {
    YouTubeProviderClientException() => YouTubePrivateDevProofError(
      code: _safeCode(error.code),
      retryable: error.retryable,
      statusCode: error.statusCode,
    ),
    YouTubeTransportException() => YouTubePrivateDevProofError(
      code: _safeCode(error.code),
      retryable: error.retryable,
      statusCode: error.statusCode,
    ),
    YouTubePrivateDevProofFailure() => YouTubePrivateDevProofError(
      code: _safeCode(error.code),
      retryable: error.retryable,
      statusCode: error.statusCode,
    ),
    FormatException() => const YouTubePrivateDevProofError(
      code: 'invalid_contract',
      retryable: false,
    ),
    StateError() => const YouTubePrivateDevProofError(
      code: 'invalid_runtime_state',
      retryable: false,
    ),
    _ => const YouTubePrivateDevProofError(
      code: 'unexpected_failure',
      retryable: false,
    ),
  };
}

YouTubePrivateDevProofProfile _parseProfile(String value) {
  return switch (value.trim()) {
    'publicData' => YouTubePrivateDevProofProfile.publicData,
    'ownerConnect' => YouTubePrivateDevProofProfile.ownerConnect,
    'privateUpload' => YouTubePrivateDevProofProfile.privateUpload,
    'ownerAnalytics' => YouTubePrivateDevProofProfile.ownerAnalytics,
    'live' => YouTubePrivateDevProofProfile.live,
    'disconnectDelete' => YouTubePrivateDevProofProfile.disconnectDelete,
    _ => throw const FormatException(
      'A supported supervised proof profile is required.',
    ),
  };
}

String _confirmationFor(YouTubePrivateDevProofProfile profile) {
  return switch (profile) {
    YouTubePrivateDevProofProfile.publicData =>
      'PROVE_YOUTUBE_PUBLIC_DATA_PRIVATE_DEV_ONLY',
    YouTubePrivateDevProofProfile.ownerConnect =>
      'PROVE_YOUTUBE_OWNER_CONNECT_PRIVATE_DEV_ONLY',
    YouTubePrivateDevProofProfile.privateUpload =>
      'PROVE_YOUTUBE_PRIVATE_UPLOAD_PRIVATE_DEV_ONLY',
    YouTubePrivateDevProofProfile.ownerAnalytics =>
      'PROVE_YOUTUBE_OWNER_ANALYTICS_PRIVATE_DEV_ONLY',
    YouTubePrivateDevProofProfile.live => 'PROVE_YOUTUBE_LIVE_PRIVATE_DEV_ONLY',
    YouTubePrivateDevProofProfile.disconnectDelete =>
      'PROVE_YOUTUBE_DISCONNECT_DELETE_PRIVATE_DEV_ONLY',
  };
}

String _requiredText(String value, String label, {required int maximum}) {
  final clean = value.trim();
  if (clean.isEmpty || clean.length > maximum || clean.contains('\u0000')) {
    throw FormatException('A valid $label is required.');
  }
  return clean;
}

String _requiredMatch(String value, RegExp expression, String label) {
  final clean = value.trim();
  if (!expression.hasMatch(clean)) {
    throw FormatException('A valid $label is required.');
  }
  return clean;
}

String _channelId(String value) {
  return _requiredMatch(
    value,
    RegExp(r'^UC[A-Za-z0-9_-]{20,30}$'),
    'expected channel identifier',
  );
}

String _videoId(String value) {
  return _requiredMatch(
    value,
    RegExp(r'^[A-Za-z0-9_-]{11}$'),
    'retention video identifier',
  );
}

bool _strictBool(String value, String label) {
  return switch (value.trim().toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => throw FormatException('$label must be explicitly true or false.'),
  };
}

DateTime _strictDate(String value, String label) {
  final clean = value.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(clean)) {
    throw FormatException('A valid $label date is required.');
  }
  final parsed = DateTime.tryParse('${clean}T00:00:00.000Z');
  if (parsed == null || _date(parsed) != clean) {
    throw FormatException('A valid $label date is required.');
  }
  return parsed;
}

List<YouTubeOwnerAnalyticsPreset> _parsePresets(String value) {
  final names = value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (names.isEmpty || names.toSet().length != names.length) {
    throw const FormatException(
      'At least one unique analytics preset is required.',
    );
  }
  return names
      .map((name) {
        return switch (name) {
          'overview' => YouTubeOwnerAnalyticsPreset.overview,
          'topVideos' => YouTubeOwnerAnalyticsPreset.topVideos,
          'countries' => YouTubeOwnerAnalyticsPreset.countries,
          'trafficSources' => YouTubeOwnerAnalyticsPreset.trafficSources,
          'devicesOs' => YouTubeOwnerAnalyticsPreset.devicesOs,
          'videoRetention' => YouTubeOwnerAnalyticsPreset.videoRetention,
          _ => throw const FormatException(
            'An unsupported analytics preset was requested.',
          ),
        };
      })
      .toList(growable: false);
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

List<String> _scopesFor(YouTubeConnectPurpose purpose) {
  return switch (purpose) {
    YouTubeConnectPurpose.readonly => const <String>[_youtubeReadonlyScope],
    YouTubeConnectPurpose.write => const <String>[
      _youtubeReadonlyScope,
      _youtubeForceSslScope,
    ],
    YouTubeConnectPurpose.creatorAssets => const <String>[
      _youtubeForceSslScope,
    ],
    YouTubeConnectPurpose.upload => const <String>[
      _youtubeReadonlyScope,
      _youtubeUploadScope,
    ],
    YouTubeConnectPurpose.analytics => const <String>[
      _youtubeReadonlyScope,
      _youtubeAnalyticsReadonlyScope,
    ],
    YouTubeConnectPurpose.live => const <String>[_youtubeManageScope],
    YouTubeConnectPurpose.liveMemberships => const <String>[
      _youtubeMembershipsCreatorScope,
    ],
  };
}

String _date(DateTime value) {
  final utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}

String _safeCode(String value) {
  final clean = value.trim().toLowerCase();
  if (RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(clean)) return clean;
  return 'redacted_failure';
}

String _secureIdempotencyKey() {
  final random = Random.secure();
  final entropy = List<int>.generate(18, (_) => random.nextInt(256));
  final suffix = entropy
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return 'private-dev-${DateTime.now().microsecondsSinceEpoch}-$suffix';
}
