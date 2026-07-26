import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_app_check.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_proof_harness.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_system_browser.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_uploader.dart';

const _channelId = 'UCabcdefghijklmnopqrstuv';
final _now = DateTime.utc(2026, 7, 25, 12);

void main() {
  group('YouTubePrivateDevProofConfiguration', () {
    test('fails closed outside the dedicated real-service Dev project', () {
      expect(
        () => _configuration(
          profile: 'publicData',
          confirmation: 'PROVE_YOUTUBE_PUBLIC_DATA_PRIVATE_DEV_ONLY',
          useEmulators: true,
        ),
        throwsStateError,
      );
      expect(
        () => _configuration(
          profile: 'publicData',
          confirmation: 'PROVE_YOUTUBE_PUBLIC_DATA_PRIVATE_DEV_ONLY',
          firebaseProjectId: 'moolsocial-staging-503018',
        ),
        throwsStateError,
      );
    });

    test('requires the exact profile confirmation phrase', () {
      expect(
        () => _configuration(
          profile: 'ownerConnect',
          confirmation: 'PROVE_YOUTUBE_PUBLIC_DATA_PRIVATE_DEV_ONLY',
          expectedChannelId: _channelId,
        ),
        throwsStateError,
      );
    });

    test('requires explicit private upload policy fields', () {
      expect(
        () => _configuration(
          profile: 'privateUpload',
          confirmation: 'PROVE_YOUTUBE_PRIVATE_UPLOAD_PRIVATE_DEV_ONLY',
          expectedChannelId: _channelId,
          uploadRightsConfirmed: 'false',
          uploadPolicyConfirmed: 'true',
        ),
        throwsStateError,
      );
    });

    test('rejects analytics retention without a video identifier', () {
      expect(
        () => _configuration(
          profile: 'ownerAnalytics',
          confirmation: 'PROVE_YOUTUBE_OWNER_ANALYTICS_PRIVATE_DEV_ONLY',
          expectedChannelId: _channelId,
          analyticsPresets: 'overview,videoRetention',
          analyticsRetentionVideoId: '',
        ),
        throwsFormatException,
      );
    });

    test('requires an explicit Live profile and exact confirmation', () {
      expect(
        () => _configuration(
          profile: 'live',
          confirmation: 'PROVE_YOUTUBE_OWNER_CONNECT_PRIVATE_DEV_ONLY',
          expectedChannelId: _channelId,
        ),
        throwsStateError,
      );
      expect(
        _configuration(
          profile: 'live',
          confirmation: 'PROVE_YOUTUBE_LIVE_PRIVATE_DEV_ONLY',
          expectedChannelId: _channelId,
        ).profile,
        YouTubePrivateDevProofProfile.live,
      );
    });
  });

  test('PublicData proves pagination and eligible hydrated records', () async {
    final gateway = _FakeGateway(
      capabilitiesValue: _capabilities(publicData: true),
    );
    final evidence = await YouTubePrivateDevProofHarness(
      configuration: _configuration(
        profile: 'publicData',
        confirmation: 'PROVE_YOUTUBE_PUBLIC_DATA_PRIVATE_DEV_ONLY',
      ),
      gateway: gateway,
      now: () => _now,
    ).run();

    expect(evidence.outcome, YouTubePrivateDevProofOutcome.passed);
    expect(evidence.observations['paginationObserved'], isTrue);
    expect(
      evidence.observations['allHydratedVideosPublicAndEmbeddable'],
      isTrue,
    );
    expect(gateway.videoDetailCalls, 1);
  });

  test(
    'OwnerConnect validates OAuth then waits for the expected channel',
    () async {
      final launcher = _RecordingLauncher();
      final gateway = _FakeGateway(
        capabilitiesValue: _capabilities(ownerConnect: true),
        connectionStartValue: _connectionStart(),
        connectionStatusValue: YouTubeConnected(
          channelId: _channelId,
          channelTitle: 'Redacted from evidence',
          grantedScopes: <String>[
            'https://www.googleapis.com/auth/youtube.readonly',
          ],
          lastVerifiedAt: _now,
          nextVerificationDueAt: _now.add(const Duration(hours: 12)),
          verificationState: YouTubeConnectionVerificationState.current,
        ),
      );
      final evidence = await YouTubePrivateDevProofHarness(
        configuration: _configuration(
          profile: 'ownerConnect',
          confirmation: 'PROVE_YOUTUBE_OWNER_CONNECT_PRIVATE_DEV_ONLY',
          expectedChannelId: _channelId,
        ),
        gateway: gateway,
        authorizationLauncher: launcher,
        now: () => _now,
        delay: (_) async {},
      ).run();

      expect(evidence.outcome, YouTubePrivateDevProofOutcome.passed);
      expect(launcher.calls, 1);
      expect(evidence.observations['expectedChannelMatched'], isTrue);
      expect(
        jsonEncode(evidence.toJson()),
        isNot(contains('state-secret-value')),
      );
    },
  );

  test('PrivateUpload records no media path or metadata', () async {
    final gateway = _FakeGateway(
      capabilitiesValue: _capabilities(privateUpload: true),
      connectionStatusValue: _connected(<String>[
        'https://www.googleapis.com/auth/youtube.readonly',
        'https://www.googleapis.com/auth/youtube.upload',
      ]),
      uploadedVideo: _video(
        videoId: 'uploadVid01',
        privacyStatus: 'private',
        uploadStatus: 'processed',
      ),
    );
    final evidence = await YouTubePrivateDevProofHarness(
      configuration: _configuration(
        profile: 'privateUpload',
        confirmation: 'PROVE_YOUTUBE_PRIVATE_UPLOAD_PRIVATE_DEV_ONLY',
        expectedChannelId: _channelId,
      ),
      gateway: gateway,
      mediaSelector: const _FakeMediaSelector(),
      now: () => _now,
      idempotencyKey: () => 'memory-only-idempotency-secret',
    ).run();
    final encoded = jsonEncode(evidence.toJson());

    expect(evidence.outcome, YouTubePrivateDevProofOutcome.passed);
    expect(evidence.observations['directDeviceToProviderWorkflowUsed'], isTrue);
    expect(encoded, isNot(contains('/private/founder/video.mp4')));
    expect(encoded, isNot(contains('Founder private upload title')));
    expect(encoded, isNot(contains('memory-only-idempotency-secret')));
  });

  test(
    'OwnerAnalytics excludes provider metric values from evidence',
    () async {
      final gateway = _FakeGateway(
        capabilitiesValue: _capabilities(ownerAnalytics: true),
        connectionStatusValue: _connected(<String>[
          'https://www.googleapis.com/auth/youtube.readonly',
          'https://www.googleapis.com/auth/yt-analytics.readonly',
        ]),
      );
      final evidence = await YouTubePrivateDevProofHarness(
        configuration: _configuration(
          profile: 'ownerAnalytics',
          confirmation: 'PROVE_YOUTUBE_OWNER_ANALYTICS_PRIVATE_DEV_ONLY',
          expectedChannelId: _channelId,
          analyticsPresets: 'overview,topVideos',
        ),
        gateway: gateway,
        now: () => _now,
      ).run();
      final encoded = jsonEncode(evidence.toJson());

      expect(evidence.outcome, YouTubePrivateDevProofOutcome.passed);
      expect(evidence.observations['presetCount'], 2);
      expect(encoded, isNot(contains('987654321')));
      expect(encoded, isNot(contains('private-dimension')));
    },
  );

  test(
    'Live proves the management scope without executing a mutation',
    () async {
      final gateway = _FakeGateway(
        capabilitiesValue: _capabilities(live: true),
        connectionStatusValue: _connected(<String>[
          'https://www.googleapis.com/auth/youtube',
        ]),
      );
      final evidence = await YouTubePrivateDevProofHarness(
        configuration: _configuration(
          profile: 'live',
          confirmation: 'PROVE_YOUTUBE_LIVE_PRIVATE_DEV_ONLY',
          expectedChannelId: _channelId,
        ),
        gateway: gateway,
        now: () => _now,
      ).run();

      expect(evidence.outcome, YouTubePrivateDevProofOutcome.passed);
      expect(evidence.observations['liveManagementScopeConfirmed'], isTrue);
      expect(evidence.observations['membershipScopeRemainsSeparate'], isTrue);
      expect(evidence.observations['mutationExecuted'], isFalse);
      expect(evidence.observations['streamingProxyCreated'], isFalse);
    },
  );

  test(
    'DisconnectDelete is idempotent and does not overclaim deletion',
    () async {
      final gateway = _FakeGateway(capabilitiesValue: _capabilities());
      final evidence = await YouTubePrivateDevProofHarness(
        configuration: _configuration(
          profile: 'disconnectDelete',
          confirmation: 'PROVE_YOUTUBE_DISCONNECT_DELETE_PRIVATE_DEV_ONLY',
        ),
        gateway: gateway,
        now: () => _now,
      ).run();

      expect(evidence.outcome, YouTubePrivateDevProofOutcome.passed);
      expect(gateway.disconnectCalls, 2);
      expect(evidence.observations['idempotentDisconnectConfirmed'], isTrue);
      expect(evidence.observations['providerAccountDeletionClaimed'], isFalse);
      expect(
        evidence.observations['separateAdministratorStorageEvidenceRequired'],
        isTrue,
      );
    },
  );

  test('errors are redacted to controlled fields', () async {
    final evidence = await YouTubePrivateDevProofHarness(
      configuration: _configuration(
        profile: 'disconnectDelete',
        confirmation: 'PROVE_YOUTUBE_DISCONNECT_DELETE_PRIVATE_DEV_ONLY',
      ),
      gateway: _FakeGateway(capabilitiesValue: _capabilities(publicData: true)),
      now: () => _now,
    ).run();
    final encoded = jsonEncode(evidence.toJson());

    expect(evidence.outcome, YouTubePrivateDevProofOutcome.failed);
    expect(evidence.error?.code, 'provider_profile_mismatch');
    expect(encoded, isNot(contains('authorizationUrl')));
    expect(encoded, isNot(contains('token')));
    expect(encoded, isNot(contains('sessionUrl')));
  });

  test('external launcher rejects any non-Google authorization URL', () async {
    await expectLater(
      const ExternalYouTubePrivateDevSystemBrowser().openInSystemBrowser(
        Uri.parse('https://example.invalid/o/oauth2/v2/auth?code=secret'),
      ),
      throwsA(
        isA<YouTubePrivateDevProofFailure>().having(
          (error) => error.code,
          'code',
          'invalid_authorization_contract',
        ),
      ),
    );
  });
}

YouTubePrivateDevProofConfiguration _configuration({
  required String profile,
  required String confirmation,
  bool useEmulators = false,
  String firebaseProjectId = youtubePrivateDevProjectId,
  String expectedChannelId = '',
  String analyticsPresets = 'overview',
  String? analyticsRetentionVideoId,
  String uploadRightsConfirmed = 'true',
  String uploadPolicyConfirmed = 'true',
}) {
  return YouTubePrivateDevProofConfiguration.forTesting(
    proofEnabled: true,
    useEmulators: useEmulators,
    firebaseProjectId: firebaseProjectId,
    profile: profile,
    confirmation: confirmation,
    candidateId: 'candidate-20260725',
    regionCode: 'IN',
    playlistId: 'PLabcdefghijk',
    searchQuery: 'Rajasthan crafts',
    expectedChannelId: expectedChannelId,
    uploadTitle: 'Founder private upload title',
    uploadDescription: 'Rights-cleared private verification.',
    uploadCategoryId: '22',
    uploadMadeForKids: 'false',
    uploadContainsSyntheticMedia: 'false',
    uploadContainsPaidPromotion: 'false',
    uploadNotifySubscribers: 'false',
    uploadRightsConfirmed: uploadRightsConfirmed,
    uploadPolicyConfirmed: uploadPolicyConfirmed,
    analyticsStartDate: '2026-07-01',
    analyticsEndDate: '2026-07-24',
    analyticsPresets: analyticsPresets,
    analyticsRetentionVideoId:
        analyticsRetentionVideoId ??
        (analyticsPresets.contains('videoRetention') ? 'abc123XYZ09' : ''),
  );
}

YouTubePrivateDevCapabilities _capabilities({
  bool publicData = false,
  bool ownerConnect = false,
  bool privateUpload = false,
  bool ownerAnalytics = false,
  bool live = false,
}) {
  return YouTubePrivateDevCapabilities(
    environment: 'dev',
    publicData: publicData,
    ownerConnect: ownerConnect,
    privateUpload: privateUpload,
    ownerAnalytics: ownerAnalytics,
    publicOrUnlistedUpload: false,
    live: live,
  );
}

YouTubeConnectionStart _connectionStart() {
  final uri = Uri.parse('https://accounts.google.com/o/oauth2/v2/auth').replace(
    queryParameters: <String, String>{
      'client_id': 'public-client-id.apps.googleusercontent.com',
      'redirect_uri':
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
          'youtubeOAuthCallback',
      'response_type': 'code',
      'state': 'state-secret-value',
      'code_challenge': 'pkce-secret-value',
      'code_challenge_method': 'S256',
      'access_type': 'offline',
      'include_granted_scopes': 'true',
      'prompt': 'consent',
      'scope': 'https://www.googleapis.com/auth/youtube.readonly',
    },
  );
  return YouTubeConnectionStart(
    authorizationUrl: uri,
    expiresAt: _now.add(const Duration(minutes: 10)),
  );
}

YouTubeConnected _connected(List<String> scopes) {
  return YouTubeConnected(
    channelId: _channelId,
    channelTitle: 'Redacted from evidence',
    grantedScopes: scopes,
    lastVerifiedAt: _now,
    nextVerificationDueAt: _now.add(const Duration(hours: 12)),
    verificationState: YouTubeConnectionVerificationState.current,
  );
}

YouTubeVideoSummary _video({
  required String videoId,
  String privacyStatus = 'public',
  String uploadStatus = 'processed',
}) {
  return YouTubeVideoSummary(
    videoId: videoId,
    title: 'Not placed in proof evidence',
    channelId: _channelId,
    channelTitle: 'Not placed in proof evidence',
    publishedAt: _now,
    description: 'Not placed in proof evidence',
    thumbnail: YouTubeThumbnail(
      url: Uri.parse('https://i.ytimg.com/vi/$videoId/hqdefault.jpg'),
    ),
    embeddable: true,
    privacyStatus: privacyStatus,
    uploadStatus: uploadStatus,
  );
}

class _FakeGateway implements YouTubePrivateDevProofGateway {
  _FakeGateway({
    required this.capabilitiesValue,
    this.connectionStartValue,
    this.connectionStatusValue,
    this.uploadedVideo,
  });

  final YouTubePrivateDevCapabilities capabilitiesValue;
  final YouTubeConnectionStart? connectionStartValue;
  final YouTubeConnectionStatus? connectionStatusValue;
  final YouTubeVideoSummary? uploadedVideo;
  int disconnectCalls = 0;
  int videoDetailCalls = 0;

  @override
  Future<YouTubePrivateDevCapabilities> capabilities() async =>
      capabilitiesValue;

  @override
  Future<YouTubeConnectionStatus> connectionStatus() async =>
      connectionStatusValue ??
      const YouTubeDisconnected(
        lastVerifiedAt: null,
        nextVerificationDueAt: null,
      );

  @override
  Future<YouTubeDisconnectResult> disconnect() async {
    disconnectCalls += 1;
    return YouTubeDisconnectResult(
      disconnected: true,
      providerRevocationConfirmed: disconnectCalls == 1,
    );
  }

  @override
  Future<YouTubeOwnerAnalyticsResult> analyticsPreset({
    required YouTubeOwnerAnalyticsPreset preset,
    required DateTime startDate,
    required DateTime endDate,
    String? videoId,
  }) async {
    return YouTubeOwnerAnalyticsResult(
      preset: preset,
      startDate: '2026-07-01',
      endDate: '2026-07-24',
      requestedStartDate: '2026-07-01',
      requestedEndDate: '2026-07-24',
      rows: const <YouTubeAnalyticsRow>[
        YouTubeAnalyticsRow(
          dimensions: <String, String>{'video': 'private-dimension'},
          metrics: <String, num>{'views': 987654321},
        ),
      ],
      empty: false,
      providerMayExcludeRecentIncompleteDays: true,
      videoId: videoId,
    );
  }

  @override
  Future<YouTubeVideoPage> mostPopular({
    String? regionCode,
    String? pageToken,
  }) async {
    return YouTubeVideoPage(
      items: <YouTubeVideoSummary>[
        _video(videoId: pageToken == null ? 'abc123XYZ09' : 'next123XYZ0'),
      ],
      nextPageToken: pageToken == null ? 'next-page' : null,
    );
  }

  @override
  Future<YouTubeVideoPage> playlist({
    required String playlistId,
    String? pageToken,
  }) async {
    return YouTubeVideoPage(
      items: <YouTubeVideoSummary>[_video(videoId: 'ply123XYZ09')],
    );
  }

  @override
  Future<YouTubeVideoPage> search({
    required String query,
    String? pageToken,
  }) async {
    return YouTubeVideoPage(
      items: <YouTubeVideoSummary>[_video(videoId: 'src123XYZ09')],
    );
  }

  @override
  Future<YouTubeConnectionStart> startConnection(
    YouTubeConnectPurpose purpose,
  ) async => connectionStartValue!;

  @override
  Future<YouTubeVideoSummary> uploadPrivate({
    required String idempotencyKey,
    required YouTubeUploadSource source,
    required YouTubePrivateUploadMetadata metadata,
    YouTubeUploadProgress? onProgress,
  }) async {
    onProgress?.call(1, 1);
    return uploadedVideo!;
  }

  @override
  Future<List<YouTubeVideoSummary>> videoDetails(List<String> videoIds) async {
    videoDetailCalls += 1;
    return videoIds.map((videoId) => _video(videoId: videoId)).toList();
  }
}

class _RecordingLauncher implements YouTubePrivateDevAuthorizationLauncher {
  int calls = 0;

  @override
  Future<void> openInSystemBrowser(Uri authorizationUrl) async {
    calls += 1;
  }
}

class _FakeMediaSelector implements YouTubePrivateDevMediaSelector {
  const _FakeMediaSelector();

  @override
  Future<YouTubeUploadSource?> selectRightsClearedMp4() async =>
      const _FakeUploadSource();
}

class _FakeUploadSource implements YouTubeUploadSource {
  const _FakeUploadSource();

  @override
  Future<YouTubeUploadFileIdentity> fileIdentity(String contentType) {
    throw UnimplementedError();
  }

  @override
  Future<int> length() async => 1;

  @override
  Stream<List<int>> openRead(int start, int endExclusive) =>
      const Stream<List<int>>.empty();
}
