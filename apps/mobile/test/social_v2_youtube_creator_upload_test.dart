import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_uploader.dart';
import 'package:moolsocial/features/shared/social_media_picker.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_creator_upload.dart';

const _uploadPermission = 'https://www.googleapis.com/auth/youtube.upload';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production routes keep YouTube upload unreachable', () {
    final router = File(
      'lib/features/journey01/journey_router.dart',
    ).readAsStringSync();
    final consumer = File(
      'lib/ui_v2/social/social_v2_consumer.dart',
    ).readAsStringSync();
    final creatorOwner = File(
      'lib/ui_v2/social/social_v2_youtube_creator_upload.dart',
    ).readAsStringSync();
    final connectRoute = router.substring(
      router.indexOf("path: '/app/creator/youtube-connect'"),
      router.indexOf("path: '/app/creator/content'"),
    );
    final createOwner = consumer.substring(
      consumer.indexOf('Widget _buildCreate()'),
      consumer.indexOf('String get _publicAuthorName'),
    );

    expect(creatorOwner, contains('this.uploadCapabilityAuthorized = false'));
    expect(connectRoute, contains('SocialYouTubeCreatorUploadScreen('));
    expect(connectRoute, isNot(contains('uploadCapabilityAuthorized')));
    expect(createOwner, isNot(contains('onCreateYouTubeShort')));
    expect(router, isNot(contains('uploadCapabilityAuthorized: true')));
    expect(consumer, isNot(contains('uploadCapabilityAuthorized: true')));
  });

  testWidgets('creator gateway separates YouTube hosting from MoolSocial', (
    tester,
  ) async {
    var youtubeCalls = 0;
    var moolSocialCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialCreatorGatewayV2(
            youtubeCreatorReady: true,
            onCreateYouTubeShort: () => youtubeCalls += 1,
            onCreateMoolSocial: (_) => moolSocialCalls += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('social-create-youtube-short')));
    await tester.tap(find.byKey(const Key('social-create-moolsocial-post')));

    expect(youtubeCalls, 1);
    expect(moolSocialCalls, 1);
    expect(find.textContaining('hosted'), findsOneWidget);
  });

  testWidgets(
    'creator gateway exposes truthful YouTube connection when not ready',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialCreatorGatewayV2(
              youtubeCreatorReady: false,
              onCreateYouTubeShort: () {},
              onCreateMoolSocial: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('social-create-youtube-short')),
        findsOneWidget,
      );
      expect(
        find.text('Connect your YouTube channel to continue'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('social-create-moolsocial-post')),
        findsOneWidget,
      );
    },
  );

  testWidgets('fails closed when creator capabilities are unavailable', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(ownerConnect: false, privateUpload: false),
      connection: const YouTubeDisconnected(),
    );

    await _pumpScreen(tester, gateway: gateway);

    expect(
      find.byKey(const Key('youtube-creator-unavailable')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('youtube-creator-connect')), findsNothing);
  });

  testWidgets('read-only owner profile exposes connection without upload', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(ownerConnect: true, privateUpload: false),
      connection: const YouTubeDisconnected(),
    );

    await _pumpScreen(tester, gateway: gateway);

    expect(
      find.byKey(const Key('youtube-creator-disconnected')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('youtube-creator-connect')), findsOneWidget);
    expect(find.byKey(const Key('youtube-creator-pick-gallery')), findsNothing);
    expect(
      find.textContaining('cannot upload, edit or delete'),
      findsOneWidget,
    );
    expect(find.textContaining('existing Google account'), findsOneWidget);
    expect(find.textContaining('youtube.readonly'), findsWidgets);
    expect(gateway.connectionStatusCalls, 1);
  });

  testWidgets('opens real channel connection only from disconnected state', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: const YouTubeDisconnected(),
    );

    await _pumpScreen(tester, gateway: gateway);
    await tester.tap(find.byKey(const Key('youtube-creator-connect')));
    await tester.pump();

    expect(gateway.connectCalls, 1);
    expect(gateway.lastConnectPurpose, YouTubeConnectPurpose.readonly);
    expect(
      find.text('Finish connecting in Google, then return here.'),
      findsOneWidget,
    );
  });

  testWidgets('shows privacy deletion and revocation controls before consent', (
    tester,
  ) async {
    final opened = <Uri>[];
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: const YouTubeDisconnected(),
    );

    await _pumpScreen(
      tester,
      gateway: gateway,
      externalLauncher: (uri) async => opened.add(uri),
    );

    expect(
      find.byKey(const Key('youtube-creator-readonly-access')),
      findsOneWidget,
    );
    expect(find.textContaining('Before connecting'), findsOneWidget);
    await _reveal(tester, const Key('youtube-creator-privacy'));
    await tester.tap(find.byKey(const Key('youtube-creator-privacy')));
    await tester.pump();
    await _reveal(tester, const Key('youtube-creator-google-permissions'));
    await tester.tap(
      find.byKey(const Key('youtube-creator-google-permissions')),
    );
    await tester.pump();
    await _reveal(tester, const Key('youtube-creator-delete-account'));
    await tester.tap(find.byKey(const Key('youtube-creator-delete-account')));
    await tester.pump();

    expect(opened, <Uri>[
      Uri.parse('https://moolsocial.com/privacy'),
      Uri.parse('https://myaccount.google.com/permissions'),
      Uri.parse('https://moolsocial.com/delete-account'),
    ]);
    expect(gateway.connectCalls, 0);
  });

  testWidgets('shows exact connected channel and read-only user controls', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: _connected(scopes: const ['youtube-read']),
    );

    await _pumpScreen(tester, gateway: gateway);

    expect(find.text('MoolSocial News'), findsOneWidget);
    expect(
      find.byKey(const Key('youtube-creator-readonly-access')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('youtube-creator-privacy')), findsOneWidget);
    expect(
      find.byKey(const Key('youtube-creator-disconnect-help')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('youtube-creator-google-permissions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('youtube-creator-delete-account')),
      findsOneWidget,
    );
    expect(find.textContaining('cannot upload, edit, delete'), findsOneWidget);
    expect(find.byKey(const Key('youtube-creator-pick-gallery')), findsNothing);
  });

  testWidgets(
    'connected channel browses details uploads playlists and returns locally',
    (tester) async {
      final gateway = _FakeCreatorGateway(
        capabilities: _capabilities(),
        connection: _connected(scopes: const ['youtube-read']),
      );

      await _pumpScreen(tester, gateway: gateway);
      expect(
        find.byKey(const Key('youtube-creator-browse-channel')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('youtube-creator-browse-channel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('youtube-channel-browser')), findsOneWidget);
      expect(
        find.byKey(const Key('youtube-channel-browser-title')),
        findsOneWidget,
      );
      expect(find.text('District bulletin one'), findsOneWidget);
      expect(find.text('Local reports'), findsOneWidget);
      expect(gateway.channelDetailsCalls, 1);
      expect(gateway.playlistVideosCalls, 1);
      expect(gateway.channelPlaylistsCalls, 1);

      await _reveal(tester, const Key('youtube-channel-load-more'));
      await tester.tap(find.byKey(const Key('youtube-channel-load-more')));
      await tester.pumpAndSettle();

      expect(find.text('District bulletin two'), findsOneWidget);
      expect(gateway.playlistVideosCalls, 2);
      expect(gateway.channelPlaylistsCalls, 1);

      await _reveal(tester, const Key('youtube-channel-load-more-playlists'));
      await tester.tap(
        find.byKey(const Key('youtube-channel-load-more-playlists')),
      );
      await tester.pumpAndSettle();

      expect(find.text('National reports'), findsOneWidget);
      expect(gateway.channelPlaylistsCalls, 2);

      await tester.tap(find.byKey(const Key('youtube-creator-back')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('youtube-creator-connected')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('youtube-channel-browser')), findsNothing);
    },
  );

  testWidgets('root channel return has an explicit route back to Social', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: _connected(scopes: const ['youtube-read']),
    );
    final router = GoRouter(
      initialLocation: '/connect',
      routes: [
        GoRoute(
          path: '/connect',
          builder: (_, _) => SocialYouTubeCreatorUploadScreen(gateway: gateway),
        ),
        GoRoute(
          path: '/app/social',
          builder: (_, _) =>
              const Scaffold(body: Text('Social videos destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('youtube-creator-back')));
    await tester.pumpAndSettle();

    expect(find.text('Social videos destination'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/app/social?sub=videos',
    );
  });

  testWidgets('opens exact privacy revocation and deletion destinations', (
    tester,
  ) async {
    final opened = <Uri>[];
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: _connected(scopes: const ['youtube-read']),
    );

    await _pumpScreen(
      tester,
      gateway: gateway,
      externalLauncher: (uri) async => opened.add(uri),
    );

    const controls = <Key>[
      Key('youtube-creator-privacy'),
      Key('youtube-creator-disconnect-help'),
      Key('youtube-creator-google-permissions'),
      Key('youtube-creator-delete-account'),
    ];
    for (final key in controls) {
      await _reveal(tester, key);
      await tester.tap(find.byKey(key));
      await tester.pump();
    }

    expect(opened, <Uri>[
      Uri.parse('https://moolsocial.com/privacy'),
      Uri.parse('https://moolsocial.com/disconnect'),
      Uri.parse('https://myaccount.google.com/permissions'),
      Uri.parse('https://moolsocial.com/delete-account'),
    ]);
  });

  testWidgets('keeps the channel connected when disconnect is cancelled', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: _connected(scopes: const ['youtube-read']),
    );

    await _pumpScreen(tester, gateway: gateway);
    await tester.tap(find.byKey(const Key('youtube-creator-disconnect')));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect YouTube?'), findsOneWidget);

    await tester.tap(find.text('Keep connected'));
    await tester.pumpAndSettle();

    expect(gateway.disconnectCalls, 0);
    expect(find.byKey(const Key('youtube-creator-connected')), findsOneWidget);
  });

  testWidgets('disconnects and refreshes to the truthful disconnected state', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: _connected(scopes: const ['youtube-read']),
    );

    await _pumpScreen(tester, gateway: gateway);
    await tester.tap(find.byKey(const Key('youtube-creator-disconnect')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Disconnect'));
    await tester.pumpAndSettle();

    expect(gateway.disconnectCalls, 1);
    expect(
      find.byKey(const Key('youtube-creator-disconnected')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('youtube-creator-connected')), findsNothing);
  });

  test('disconnect continuation rechecks screen ownership before setState', () {
    final source = File(
      'lib/ui_v2/social/social_v2_youtube_creator_upload.dart',
    ).readAsStringSync();
    final start = source.indexOf('Future<void> _disconnect() async');
    final end = source.indexOf('Future<void> _openExternal', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final disconnectSource = source.substring(start, end);
    expect(
      disconnectSource,
      matches(
        RegExp(
          r'if \(confirmed != true\) return;\s+if \(!mounted\) return;\s+setState',
        ),
      ),
    );
  });

  testWidgets(
    'uploads a validated vertical video privately with required review',
    (tester) async {
      final gateway = _FakeCreatorGateway(
        capabilities: _capabilities(),
        connection: _connected(scopes: const [_uploadPermission]),
      );
      final picker = _FakeVideoPicker();
      const inspector = _FakeMediaInspector();

      await _pumpScreen(
        tester,
        gateway: gateway,
        mediaPicker: picker,
        mediaInspector: inspector,
        uploadCapabilityAuthorized: true,
      );
      await tester.tap(find.byKey(const Key('youtube-creator-pick-gallery')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('youtube-creator-selected-video')),
        findsOneWidget,
      );
      await _reveal(tester, const Key('youtube-creator-not-kids'));
      await tester.tap(find.byKey(const Key('youtube-creator-not-kids')));
      await _reveal(tester, const Key('youtube-creator-rights'));
      await tester.tap(find.byKey(const Key('youtube-creator-rights')));
      await _reveal(tester, const Key('youtube-creator-upload'));
      await tester.tap(find.byKey(const Key('youtube-creator-upload')));
      await tester.pumpAndSettle();

      expect(gateway.uploadCalls, 1);
      expect(gateway.lastMetadata?.title, 'district bulletin');
      expect(gateway.lastMetadata?.madeForKids, isFalse);
      expect(gateway.lastContentType, 'video/mp4');
      expect(
        find.byKey(const Key('youtube-creator-upload-complete')),
        findsOneWidget,
      );
      expect(find.text('Uploaded privately to YouTube'), findsOneWidget);
    },
  );

  testWidgets('cancel keeps an in-flight upload from presenting success', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: _connected(scopes: const [_uploadPermission]),
      waitForCancellation: true,
    );

    await _pumpScreen(
      tester,
      gateway: gateway,
      mediaPicker: _FakeVideoPicker(),
      mediaInspector: const _FakeMediaInspector(),
      uploadCapabilityAuthorized: true,
    );
    await tester.tap(find.byKey(const Key('youtube-creator-pick-gallery')));
    await tester.pumpAndSettle();
    await _reveal(tester, const Key('youtube-creator-not-kids'));
    await tester.tap(find.byKey(const Key('youtube-creator-not-kids')));
    await _reveal(tester, const Key('youtube-creator-rights'));
    await tester.tap(find.byKey(const Key('youtube-creator-rights')));
    await _reveal(tester, const Key('youtube-creator-upload'));
    await tester.tap(find.byKey(const Key('youtube-creator-upload')));
    await tester.pump();
    await _reveal(tester, const Key('youtube-creator-cancel-upload'));
    await tester.tap(find.byKey(const Key('youtube-creator-cancel-upload')));
    await tester.pumpAndSettle();

    expect(gateway.observedCancellation, isTrue);
    expect(find.textContaining('Upload cancelled'), findsOneWidget);
    expect(
      find.byKey(const Key('youtube-creator-upload-complete')),
      findsNothing,
    );
  });

  testWidgets('callback failure never claims a channel connection', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: const YouTubeDisconnected(),
    );

    await _pumpScreen(tester, gateway: gateway, youtubeConnectResult: 'failed');

    expect(find.textContaining('YouTube was not connected'), findsOneWidget);
    expect(find.byKey(const Key('youtube-creator-connected')), findsNothing);
  });

  testWidgets('older lifecycle refresh cannot replace newer channel status', (
    tester,
  ) async {
    final first = Completer<YouTubeConnectionStatus>();
    final second = Completer<YouTubeConnectionStatus>();
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: const YouTubeDisconnected(),
      connectionResponses: [first.future, second.future],
    );

    await _pumpScreen(tester, gateway: gateway, settle: false);
    expect(gateway.connectionStatusCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(gateway.connectionStatusCalls, 2);

    second.complete(_connected(scopes: const ['youtube-read']));
    await tester.pump();
    expect(find.text('MoolSocial News'), findsOneWidget);

    first.complete(const YouTubeDisconnected());
    await tester.pump();
    expect(find.text('MoolSocial News'), findsOneWidget);
    expect(find.byKey(const Key('youtube-creator-disconnected')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('callback failure is consumed before a user retry', (
    tester,
  ) async {
    final gateway = _FakeCreatorGateway(
      capabilities: _capabilities(),
      connection: const YouTubeDisconnected(),
    );

    await _pumpScreen(tester, gateway: gateway, youtubeConnectResult: 'failed');
    expect(find.textContaining('YouTube was not connected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('youtube-creator-connect')));
    await tester.pump();
    expect(find.textContaining('YouTube was not connected'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('YouTube was not connected'), findsNothing);
    expect(
      find.byKey(const Key('youtube-creator-disconnected')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeCreatorGateway gateway,
  SocialMediaPicker? mediaPicker,
  SocialYouTubeShortMediaInspector? mediaInspector,
  SocialYouTubeExternalLauncher? externalLauncher,
  String? youtubeConnectResult,
  bool uploadCapabilityAuthorized = false,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: SocialYouTubeCreatorUploadScreen(
        gateway: gateway,
        mediaPicker: mediaPicker,
        mediaInspector: mediaInspector,
        externalLauncher: externalLauncher,
        youtubeConnectResult: youtubeConnectResult,
        uploadCapabilityAuthorized: uploadCapabilityAuthorized,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _reveal(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

YouTubePrivateDevCapabilities _capabilities({
  bool ownerConnect = true,
  bool privateUpload = true,
}) {
  return YouTubePrivateDevCapabilities(
    environment: 'Dev',
    publicData: true,
    ownerConnect: ownerConnect,
    privateUpload: privateUpload,
    ownerAnalytics: false,
    publicOrUnlistedUpload: false,
  );
}

YouTubeConnected _connected({required List<String> scopes}) {
  return YouTubeConnected(
    channelId: 'UCabcdefghijklmnopqrstuv',
    channelTitle: 'MoolSocial News',
    grantedScopes: scopes,
    lastVerifiedAt: DateTime.utc(2026, 8, 11, 10),
    nextVerificationDueAt: DateTime.utc(2026, 9, 10, 10),
  );
}

class _FakeCreatorGateway
    implements SocialYouTubeCreatorGateway, SocialYouTubeChannelBrowserGateway {
  _FakeCreatorGateway({
    required YouTubePrivateDevCapabilities capabilities,
    required YouTubeConnectionStatus connection,
    this.waitForCancellation = false,
    this.connectionResponses,
  }) : capabilityValue = capabilities,
       connectionValue = connection;

  final YouTubePrivateDevCapabilities capabilityValue;
  YouTubeConnectionStatus connectionValue;
  final bool waitForCancellation;
  final List<Future<YouTubeConnectionStatus>>? connectionResponses;
  int connectCalls = 0;
  int disconnectCalls = 0;
  int connectionStatusCalls = 0;
  int channelDetailsCalls = 0;
  int playlistVideosCalls = 0;
  int channelPlaylistsCalls = 0;
  int uploadCalls = 0;
  YouTubeConnectPurpose? lastConnectPurpose;
  bool observedCancellation = false;
  YouTubePrivateUploadMetadata? lastMetadata;
  String? lastContentType;

  @override
  Future<YouTubePrivateDevCapabilities> capabilities() async => capabilityValue;

  @override
  Future<YouTubeConnectionStatus> connectionStatus() async {
    connectionStatusCalls += 1;
    final responses = connectionResponses;
    if (responses != null && connectionStatusCalls <= responses.length) {
      return responses[connectionStatusCalls - 1];
    }
    return connectionValue;
  }

  @override
  Future<YouTubePublicChannelDetails> channelDetails({
    required String channelId,
  }) async {
    channelDetailsCalls += 1;
    return YouTubePublicChannelDetails(
      channelId: channelId,
      title: 'MoolSocial News channel',
      description: 'Public reports from the connected channel.',
      publishedAt: DateTime.utc(2020),
      uploadsPlaylistId: 'UUabcdefghijklmnopqrstuv',
      statistics: const YouTubePublicChannelStatistics(
        hiddenSubscriberCount: false,
        subscriberCount: '1250',
        videoCount: '42',
        viewCount: '9000',
      ),
      topicCategories: const [],
    );
  }

  @override
  Future<YouTubeVideoPage> playlistVideos({
    required String playlistId,
    String? pageToken,
  }) async {
    playlistVideosCalls += 1;
    if (pageToken == 'page-2') {
      return YouTubeVideoPage(
        items: [_channelVideo('video-2', 'District bulletin two')],
      );
    }
    return YouTubeVideoPage(
      items: [_channelVideo('video-1', 'District bulletin one')],
      nextPageToken: 'page-2',
    );
  }

  @override
  Future<YouTubePublicPlaylistPage> channelPlaylists({
    required String channelId,
    String? pageToken,
    int? maxResults,
  }) async {
    channelPlaylistsCalls += 1;
    if (pageToken == 'playlist-page-2') {
      return YouTubePublicPlaylistPage(
        items: [
          YouTubePublicPlaylistDetails(
            playlistId: 'playlist-2',
            title: 'National reports',
            description: 'National reporting playlist.',
            publishedAt: DateTime.utc(2026, 8, 2),
            channelId: channelId,
            channelTitle: 'MoolSocial News channel',
            itemCount: 8,
          ),
        ],
      );
    }
    return YouTubePublicPlaylistPage(
      items: [
        YouTubePublicPlaylistDetails(
          playlistId: 'playlist-1',
          title: 'Local reports',
          description: 'District reporting playlist.',
          publishedAt: DateTime.utc(2026, 8, 1),
          channelId: channelId,
          channelTitle: 'MoolSocial News channel',
          itemCount: 12,
        ),
      ],
      nextPageToken: 'playlist-page-2',
    );
  }

  @override
  Future<void> beginChannelConnection({
    required YouTubeConnectPurpose purpose,
  }) async {
    connectCalls += 1;
    lastConnectPurpose = purpose;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
    connectionValue = const YouTubeDisconnected();
  }

  @override
  Future<YouTubeVideoSummary> uploadPrivateShort({
    required String idempotencyKey,
    required String path,
    required String contentType,
    required YouTubePrivateUploadMetadata metadata,
    required YouTubeUploadProgress onProgress,
    required YouTubeUploadCancellation cancellation,
  }) async {
    uploadCalls += 1;
    lastMetadata = metadata;
    lastContentType = contentType;
    onProgress(1, waitForCancellation ? 10 : 1);
    if (waitForCancellation) {
      while (!cancellation.isCancelled) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      observedCancellation = true;
      throw const YouTubeUploadCancelledException();
    }
    return YouTubeVideoSummary(
      videoId: 'upload12345',
      title: metadata.title,
      channelId: 'UCabcdefghijklmnopqrstuv',
      channelTitle: 'MoolSocial News',
      publishedAt: DateTime.utc(2026, 8, 11, 10),
      description: metadata.description,
      thumbnail: YouTubeThumbnail(
        url: Uri.parse('https://i.ytimg.com/vi/upload12345/hqdefault.jpg'),
      ),
      privacyStatus: 'private',
      uploadStatus: 'processed',
    );
  }

  @override
  void dispose() {}
}

YouTubeVideoSummary _channelVideo(String id, String title) {
  return YouTubeVideoSummary(
    videoId: id,
    title: title,
    channelId: 'UCabcdefghijklmnopqrstuv',
    channelTitle: 'MoolSocial News channel',
    publishedAt: DateTime.utc(2026, 8, 20),
    description: '',
    thumbnail: YouTubeThumbnail(
      url: Uri.parse('https://i.ytimg.com/vi/$id/hqdefault.jpg'),
    ),
    viewCount: '1200',
  );
}

class _FakeVideoPicker implements SocialMediaPicker {
  static const media = SocialPickedMedia(
    path: 'C:/selected/district-bulletin.mp4',
    name: 'district-bulletin.mp4',
    kind: SocialMediaKind.video,
  );

  @override
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source) async => media;

  @override
  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10}) async =>
      const [];

  @override
  Future<SocialPickedMedia?> pickImage(SocialMediaSource source) async => null;

  @override
  Future<List<SocialPickedMedia>> recoverInterruptedSelection() async =>
      const [];
}

class _FakeMediaInspector implements SocialYouTubeShortMediaInspector {
  const _FakeMediaInspector();

  @override
  Future<SocialYouTubeShortMediaInfo> inspect(SocialPickedMedia media) async {
    return const SocialYouTubeShortMediaInfo(
      width: 1080,
      height: 1920,
      duration: Duration(seconds: 42),
      byteLength: 12 * 1024 * 1024,
      contentType: 'video/mp4',
    );
  }
}
