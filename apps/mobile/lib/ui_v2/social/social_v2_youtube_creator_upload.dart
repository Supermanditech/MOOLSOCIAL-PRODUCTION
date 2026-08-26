import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/youtube/youtube_private_dev_client.dart';
import '../../core/youtube/youtube_private_dev_models.dart';
import '../../core/youtube/youtube_private_dev_system_browser.dart';
import '../../core/youtube/youtube_private_dev_transport.dart';
import '../../core/youtube/youtube_private_dev_uploader.dart';
import '../../core/youtube/youtube_private_dev_workflow.dart';
import '../../features/shared/social_media_picker.dart';
import '../../features/shared/youtube_public_watch_state_repository.dart';
import 'social_v2_create_workbench.dart';
import 'social_v2_youtube_public_runtime.dart';

const _youtubeUploadPermission =
    'https://www.googleapis.com/auth/youtube.upload';
final _youtubePrivacyUri = Uri.parse('https://moolsocial.com/privacy');
final _youtubeDisconnectUri = Uri.parse('https://moolsocial.com/disconnect');
final _deleteAccountUri = Uri.parse('https://moolsocial.com/delete-account');
final _googlePermissionsUri = Uri.parse(
  'https://myaccount.google.com/permissions',
);

typedef SocialYouTubeExternalLauncher = Future<void> Function(Uri uri);

@visibleForTesting
bool isTrustedSocialYouTubeExternalUri(Uri uri) {
  if (uri.scheme != 'https' ||
      uri.hasPort ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    return false;
  }
  if (uri.host == 'moolsocial.com') {
    return !uri.hasQuery &&
        const {'/privacy', '/disconnect', '/delete-account'}.contains(uri.path);
  }
  if (uri.host == 'myaccount.google.com') {
    return uri.path == '/permissions' && !uri.hasQuery;
  }
  return false;
}

Future<void> launchTrustedSocialYouTubeExternalUri(Uri uri) async {
  if (!isTrustedSocialYouTubeExternalUri(uri)) {
    throw const FormatException('Unsupported external destination.');
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) throw const FormatException('External destination unavailable.');
}

abstract interface class SocialYouTubeCreatorGateway {
  Future<YouTubePrivateDevCapabilities> capabilities();

  Future<YouTubeConnectionStatus> connectionStatus();

  Future<void> beginChannelConnection({required YouTubeConnectPurpose purpose});

  Future<void> disconnect();

  Future<YouTubeVideoSummary> uploadPrivateShort({
    required String idempotencyKey,
    required String path,
    required String contentType,
    required YouTubePrivateUploadMetadata metadata,
    required YouTubeUploadProgress onProgress,
    required YouTubeUploadCancellation cancellation,
  });

  void dispose();
}

abstract interface class SocialYouTubeChannelBrowserGateway {
  Future<YouTubePublicChannelDetails> channelDetails({
    required String channelId,
  });

  Future<YouTubeVideoPage> playlistVideos({
    required String playlistId,
    String? pageToken,
  });

  Future<YouTubePublicPlaylistPage> channelPlaylists({
    required String channelId,
    String? pageToken,
    int? maxResults,
  });
}

class RealSocialYouTubeCreatorGateway
    implements SocialYouTubeCreatorGateway, SocialYouTubeChannelBrowserGateway {
  RealSocialYouTubeCreatorGateway({
    IoYouTubeHttpTransport? transport,
    ExternalYouTubePrivateDevSystemBrowser? browser,
  }) : _transport = transport ?? IoYouTubeHttpTransport(),
       _browser = browser ?? const ExternalYouTubePrivateDevSystemBrowser();

  final IoYouTubeHttpTransport _transport;
  final ExternalYouTubePrivateDevSystemBrowser _browser;
  YouTubePrivateDevClient? _clientValue;
  YouTubePrivateDevUploadWorkflow? _workflowValue;

  YouTubePrivateDevClient get _client => _clientValue ??=
      YouTubePrivateDevClient.fromBuildConfiguration(transport: _transport);

  YouTubePrivateDevUploadWorkflow get _workflow =>
      _workflowValue ??= YouTubePrivateDevUploadWorkflow(
        client: _client,
        uploader: YouTubeDirectUploader(_transport),
      );

  @override
  Future<YouTubePrivateDevCapabilities> capabilities() =>
      _client.capabilities();

  @override
  Future<YouTubeConnectionStatus> connectionStatus() =>
      _client.connectionStatus();

  @override
  Future<YouTubePublicChannelDetails> channelDetails({
    required String channelId,
  }) => _client.channelDetails(channelId: channelId);

  @override
  Future<YouTubeVideoPage> playlistVideos({
    required String playlistId,
    String? pageToken,
  }) => _client.playlist(playlistId: playlistId, pageToken: pageToken);

  @override
  Future<YouTubePublicPlaylistPage> channelPlaylists({
    required String channelId,
    String? pageToken,
    int? maxResults,
  }) => _client.channelPlaylists(
    channelId: channelId,
    pageToken: pageToken,
    maxResults: maxResults,
  );

  @override
  Future<void> beginChannelConnection({
    required YouTubeConnectPurpose purpose,
  }) async {
    final start = await _client.startConnection(
      purpose: purpose,
      promptForConsent: true,
    );
    await _browser.openInSystemBrowser(start.authorizationUrl);
  }

  @override
  Future<void> disconnect() async {
    await _client.disconnect();
  }

  @override
  Future<YouTubeVideoSummary> uploadPrivateShort({
    required String idempotencyKey,
    required String path,
    required String contentType,
    required YouTubePrivateUploadMetadata metadata,
    required YouTubeUploadProgress onProgress,
    required YouTubeUploadCancellation cancellation,
  }) {
    return _workflow.uploadPrivate(
      idempotencyKey: idempotencyKey,
      contentType: contentType,
      source: FileYouTubeUploadSource(path),
      metadata: metadata,
      onProgress: onProgress,
      cancellation: cancellation,
    );
  }

  @override
  void dispose() {
    _transport.close(force: true);
  }
}

class SocialYouTubeShortMediaInfo {
  const SocialYouTubeShortMediaInfo({
    required this.width,
    required this.height,
    required this.duration,
    required this.byteLength,
    required this.contentType,
  });

  final double width;
  final double height;
  final Duration duration;
  final int byteLength;
  final String contentType;

  bool get isVertical => height >= width;
  bool get isShortDuration =>
      duration > Duration.zero && duration <= const Duration(minutes: 3);
}

abstract interface class SocialYouTubeShortMediaInspector {
  Future<SocialYouTubeShortMediaInfo> inspect(SocialPickedMedia media);
}

class NativeSocialYouTubeShortMediaInspector
    implements SocialYouTubeShortMediaInspector {
  const NativeSocialYouTubeShortMediaInspector();

  @override
  Future<SocialYouTubeShortMediaInfo> inspect(SocialPickedMedia media) async {
    if (media.kind != SocialMediaKind.video || media.isAsset) {
      throw const FormatException('Choose a video from this device.');
    }
    final file = File(media.path);
    final byteLength = await file.length();
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return SocialYouTubeShortMediaInfo(
        width: controller.value.size.width,
        height: controller.value.size.height,
        duration: controller.value.duration,
        byteLength: byteLength,
        contentType: _videoContentType(media.name),
      );
    } finally {
      await controller.dispose();
    }
  }
}

String _videoContentType(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.endsWith('.mov')) return 'video/quicktime';
  if (normalized.endsWith('.webm')) return 'video/webm';
  if (normalized.endsWith('.m4v')) return 'video/x-m4v';
  return 'video/mp4';
}

class SocialCreatorGatewayV2 extends StatelessWidget {
  const SocialCreatorGatewayV2({
    required this.youtubeCreatorReady,
    required this.onCreateYouTubeShort,
    required this.onCreateMoolSocial,
    super.key,
  });

  final bool youtubeCreatorReady;
  final VoidCallback onCreateYouTubeShort;
  final ValueChanged<SocialCreateIntentV2> onCreateMoolSocial;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('social-creator-gateway'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const Text(
          'Create',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose where your content will be hosted.',
          style: TextStyle(color: Color(0xFF606060), fontSize: 15),
        ),
        const SizedBox(height: 18),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: const Key('social-create-youtube-short'),
            onTap: onCreateYouTubeShort,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF0033),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_display_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YouTube Short',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          youtubeCreatorReady
                              ? 'Upload to your connected YouTube channel'
                              : 'Connect your YouTube channel to continue',
                          style: const TextStyle(
                            color: Color(0xFF606060),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Create on MoolSocial',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose a format and start composing in one tap.',
          style: TextStyle(color: Color(0xFF606060), fontSize: 13),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _SocialCreateIntentTile(
              key: const Key('social-create-moolsocial-post'),
              icon: Icons.edit_note_rounded,
              label: 'Text',
              onTap: () => onCreateMoolSocial(SocialCreateIntentV2.text),
            ),
            _SocialCreateIntentTile(
              key: const Key('social-create-moolsocial-image'),
              icon: Icons.image_outlined,
              label: 'Image',
              onTap: () => onCreateMoolSocial(SocialCreateIntentV2.image),
            ),
            _SocialCreateIntentTile(
              key: const Key('social-create-moolsocial-carousel'),
              icon: Icons.view_carousel_outlined,
              label: 'Carousel',
              onTap: () => onCreateMoolSocial(SocialCreateIntentV2.carousel),
            ),
            _SocialCreateIntentTile(
              key: const Key('social-create-moolsocial-image-poll'),
              icon: Icons.grid_view_rounded,
              label: 'Image Poll',
              onTap: () => onCreateMoolSocial(SocialCreateIntentV2.imagePoll),
            ),
            _SocialCreateIntentTile(
              key: const Key('social-create-moolsocial-quick-poll'),
              icon: Icons.poll_outlined,
              label: 'Quick Poll',
              onTap: () => onCreateMoolSocial(SocialCreateIntentV2.quickPoll),
            ),
            _SocialCreateIntentTile(
              key: const Key('social-create-moolsocial-quiz'),
              icon: Icons.check_circle_outline_rounded,
              label: 'Quiz',
              onTap: () => onCreateMoolSocial(SocialCreateIntentV2.quiz),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialCreateIntentTile extends StatelessWidget {
  const _SocialCreateIntentTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create $label on MoolSocial',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0B2447),
                  foregroundColor: Colors.white,
                  child: Icon(icon, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialYouTubeCreatorUploadScreen extends StatefulWidget {
  const SocialYouTubeCreatorUploadScreen({
    this.youtubeConnectResult,
    this.gateway,
    this.mediaPicker,
    this.mediaInspector,
    this.uploadCapabilityAuthorized = false,
    this.externalLauncher,
    super.key,
  });

  final String? youtubeConnectResult;

  @visibleForTesting
  final SocialYouTubeCreatorGateway? gateway;

  @visibleForTesting
  final SocialMediaPicker? mediaPicker;

  @visibleForTesting
  final SocialYouTubeShortMediaInspector? mediaInspector;

  /// Kept false by every production route. A separately authorized future
  /// upload ticket must explicitly opt in and requalify the complete surface.
  final bool uploadCapabilityAuthorized;

  @visibleForTesting
  final SocialYouTubeExternalLauncher? externalLauncher;

  @override
  State<SocialYouTubeCreatorUploadScreen> createState() =>
      _SocialYouTubeCreatorUploadScreenState();
}

class _SocialYouTubeCreatorUploadScreenState
    extends State<SocialYouTubeCreatorUploadScreen>
    with WidgetsBindingObserver {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final SocialYouTubeCreatorGateway _gateway =
      widget.gateway ?? RealSocialYouTubeCreatorGateway();
  late final SocialMediaPicker _mediaPicker =
      widget.mediaPicker ?? NativeSocialMediaPicker();
  late final SocialYouTubeShortMediaInspector _mediaInspector =
      widget.mediaInspector ?? const NativeSocialYouTubeShortMediaInspector();
  late final bool _ownsGateway = widget.gateway == null;

  YouTubePrivateDevCapabilities? _capabilities;
  YouTubeConnectionStatus? _connection;
  YouTubePublicChannelDetails? _channelDetails;
  List<YouTubeVideoSummary> _channelVideos = const [];
  List<YouTubePublicPlaylistDetails> _channelPlaylists = const [];
  String? _channelVideosNextPageToken;
  String? _channelPlaylistsNextPageToken;
  String? _channelBrowseError;
  bool _channelBrowseOpen = false;
  bool _channelBrowseLoading = false;
  bool _channelBrowseLoadingMore = false;
  bool _channelPlaylistsLoadingMore = false;
  String? _activeChannelPlaylistId;
  String? _activeChannelPlaylistTitle;
  int _channelBrowseRequest = 0;
  SocialPickedMedia? _media;
  SocialYouTubeShortMediaInfo? _mediaInfo;
  YouTubeVideoSummary? _uploaded;
  YouTubeUploadCancellation? _cancellation;
  String? _idempotencyKey;
  String? _error;
  bool _loading = true;
  bool _connecting = false;
  bool _selecting = false;
  bool _uploading = false;
  bool _stopping = false;
  double _progress = 0;
  bool? _madeForKids;
  bool _containsSyntheticMedia = false;
  bool _containsPaidPromotion = false;
  bool _notifySubscribers = false;
  bool _rightsConfirmed = false;
  String _categoryId = '22';
  int _connectionRequest = 0;
  late bool _connectFailurePending;

  @override
  void initState() {
    super.initState();
    _connectFailurePending = widget.youtubeConnectResult == 'failed';
    WidgetsBinding.instance.addObserver(this);
    _refreshConnection();
  }

  @override
  void didUpdateWidget(covariant SocialYouTubeCreatorUploadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final result = widget.youtubeConnectResult;
    if (oldWidget.youtubeConnectResult != result &&
        (result == 'complete' || result == 'failed')) {
      _connectFailurePending = result == 'failed';
      _refreshConnection();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_uploading) {
      _refreshConnection(showBusy: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancellation?.cancel();
    _title.dispose();
    _description.dispose();
    if (_ownsGateway) _gateway.dispose();
    super.dispose();
  }

  bool get _providerReady => widget.uploadCapabilityAuthorized
      ? _capabilities?.privateUpload == true
      : _capabilities?.ownerConnect == true;

  YouTubeConnected? get _connected => switch (_connection) {
    YouTubeConnected value => value,
    _ => null,
  };

  SocialYouTubeChannelBrowserGateway? get _channelBrowser => switch (_gateway) {
    SocialYouTubeChannelBrowserGateway value => value,
    _ => null,
  };

  bool get _hasUploadPermission =>
      _connected?.grantedScopes.contains(_youtubeUploadPermission) == true;

  Future<void> _refreshConnection({bool showBusy = true}) async {
    final request = ++_connectionRequest;
    if (showBusy && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final capabilities = await _gateway.capabilities();
      YouTubeConnectionStatus? connection;
      final providerReady = widget.uploadCapabilityAuthorized
          ? capabilities.privateUpload
          : capabilities.ownerConnect;
      if (providerReady) {
        connection = await _gateway.connectionStatus();
      }
      if (!mounted || request != _connectionRequest) return;
      final showConnectFailure = _connectFailurePending;
      _connectFailurePending = false;
      final nextChannelId = switch (connection) {
        YouTubeConnected value => value.channelId,
        _ => null,
      };
      if (_channelDetails?.channelId != nextChannelId) {
        _clearChannelBrowseData();
      }
      setState(() {
        _capabilities = capabilities;
        _connection = connection;
        _loading = false;
        _connecting = false;
        _error = showConnectFailure
            ? 'YouTube was not connected. Try again or choose another Google account.'
            : null;
      });
    } on Object catch (error) {
      if (!mounted || request != _connectionRequest) return;
      setState(() {
        _loading = false;
        _connecting = false;
        _error = _customerMessage(error);
      });
    }
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await _gateway.beginChannelConnection(
        purpose: widget.uploadCapabilityAuthorized
            ? YouTubeConnectPurpose.upload
            : YouTubeConnectPurpose.readonly,
      );
      if (!mounted) return;
      setState(() => _connecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish connecting in Google, then return here.'),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = _customerMessage(error);
      });
    }
  }

  void _clearChannelBrowseData() {
    _channelBrowseRequest += 1;
    _channelBrowseOpen = false;
    _channelBrowseLoading = false;
    _channelBrowseLoadingMore = false;
    _channelPlaylistsLoadingMore = false;
    _channelDetails = null;
    _channelVideos = const [];
    _channelPlaylists = const [];
    _channelVideosNextPageToken = null;
    _channelPlaylistsNextPageToken = null;
    _activeChannelPlaylistId = null;
    _activeChannelPlaylistTitle = null;
    _channelBrowseError = null;
  }

  Future<void> _openChannelBrowser() async {
    if (_connected == null) return;
    setState(() => _channelBrowseOpen = true);
    if (_channelDetails == null && !_channelBrowseLoading) {
      await _loadChannelBrowser();
    }
  }

  Future<void> _loadChannelBrowser({bool loadMore = false}) async {
    final connection = _connected;
    final browser = _channelBrowser;
    if (connection == null || browser == null) {
      if (mounted) {
        setState(() {
          _channelBrowseLoading = false;
          _channelBrowseLoadingMore = false;
          _channelBrowseError =
              'This connected channel cannot be browsed right now.';
        });
      }
      return;
    }
    final pageToken = loadMore ? _channelVideosNextPageToken : null;
    if (loadMore && pageToken == null) return;
    final request = ++_channelBrowseRequest;
    setState(() {
      if (loadMore) {
        _channelBrowseLoadingMore = true;
      } else {
        _channelBrowseLoading = true;
      }
      _channelBrowseError = null;
    });
    try {
      final details = loadMore || _activeChannelPlaylistId != null
          ? _channelDetails!
          : await browser.channelDetails(channelId: connection.channelId);
      final uploadsPlaylistId = details.uploadsPlaylistId;
      if (uploadsPlaylistId == null || uploadsPlaylistId.isEmpty) {
        throw const FormatException(
          'This channel does not expose a public uploads playlist.',
        );
      }
      final selectedPlaylistId = _activeChannelPlaylistId ?? uploadsPlaylistId;
      final videosPage = await browser.playlistVideos(
        playlistId: selectedPlaylistId,
        pageToken: pageToken,
      );
      final playlistsPage = loadMore || _activeChannelPlaylistId != null
          ? null
          : await browser.channelPlaylists(
              channelId: connection.channelId,
              maxResults: 10,
            );
      if (!mounted || request != _channelBrowseRequest) return;
      final videos = loadMore
          ? <YouTubeVideoSummary>[
              ..._channelVideos,
              for (final video in videosPage.items)
                if (!_channelVideos.any(
                  (existing) => existing.videoId == video.videoId,
                ))
                  video,
            ]
          : videosPage.items;
      setState(() {
        _channelDetails = details;
        _channelVideos = List<YouTubeVideoSummary>.unmodifiable(videos);
        if (playlistsPage != null) {
          _channelPlaylists = List<YouTubePublicPlaylistDetails>.unmodifiable(
            playlistsPage.items,
          );
          _channelPlaylistsNextPageToken = playlistsPage.nextPageToken;
        }
        _channelVideosNextPageToken = videosPage.nextPageToken;
        _channelBrowseLoading = false;
        _channelBrowseLoadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted || request != _channelBrowseRequest) return;
      setState(() {
        _channelBrowseLoading = false;
        _channelBrowseLoadingMore = false;
        _channelBrowseError = _customerMessage(error);
      });
    }
  }

  Future<void> _openChannelPlaylist(
    YouTubePublicPlaylistDetails playlist,
  ) async {
    final browser = _channelBrowser;
    if (browser == null) return;
    final request = ++_channelBrowseRequest;
    setState(() {
      _channelBrowseLoading = true;
      _channelBrowseError = null;
    });
    try {
      final page = await browser.playlistVideos(
        playlistId: playlist.playlistId,
      );
      if (!mounted || request != _channelBrowseRequest) return;
      setState(() {
        _activeChannelPlaylistId = playlist.playlistId;
        _activeChannelPlaylistTitle = playlist.title;
        _channelVideos = List<YouTubeVideoSummary>.unmodifiable(page.items);
        _channelVideosNextPageToken = page.nextPageToken;
        _channelBrowseLoading = false;
        _channelBrowseLoadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted || request != _channelBrowseRequest) return;
      setState(() {
        _channelBrowseLoading = false;
        _channelBrowseError = _customerMessage(error);
      });
    }
  }

  void _showChannelUploads() {
    setState(() {
      _activeChannelPlaylistId = null;
      _activeChannelPlaylistTitle = null;
    });
    _loadChannelBrowser();
  }

  Future<void> _loadMoreChannelPlaylists() async {
    final connection = _connected;
    final browser = _channelBrowser;
    final pageToken = _channelPlaylistsNextPageToken;
    if (connection == null || browser == null || pageToken == null) return;
    final request = ++_channelBrowseRequest;
    setState(() {
      _channelPlaylistsLoadingMore = true;
      _channelBrowseError = null;
    });
    try {
      final page = await browser.channelPlaylists(
        channelId: connection.channelId,
        pageToken: pageToken,
        maxResults: 10,
      );
      if (!mounted || request != _channelBrowseRequest) return;
      final existingIds = _channelPlaylists
          .map((playlist) => playlist.playlistId)
          .toSet();
      setState(() {
        _channelPlaylists = List<YouTubePublicPlaylistDetails>.unmodifiable([
          ..._channelPlaylists,
          for (final playlist in page.items)
            if (existingIds.add(playlist.playlistId)) playlist,
        ]);
        _channelPlaylistsNextPageToken = page.nextPageToken;
        _channelPlaylistsLoadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted || request != _channelBrowseRequest) return;
      setState(() {
        _channelPlaylistsLoadingMore = false;
        _channelBrowseError = _customerMessage(error);
      });
    }
  }

  void _handleScreenBack() {
    if (_channelBrowseOpen && _activeChannelPlaylistId != null) {
      _showChannelUploads();
      return;
    }
    if (_channelBrowseOpen) {
      setState(() => _channelBrowseOpen = false);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/social?sub=videos');
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect YouTube?'),
        content: Text(
          widget.uploadCapabilityAuthorized
              ? 'MoolSocial will no longer be able to upload to ${_connected?.channelTitle ?? 'this channel'}.'
              : 'MoolSocial will delete its stored connection to ${_connected?.channelTitle ?? 'this channel'}. You can also review or revoke access in your Google Account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep connected'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _gateway.disconnect();
      await _refreshConnection(showBusy: false);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _customerMessage(error);
      });
    }
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      final launcher = widget.externalLauncher;
      if (launcher != null) {
        await launcher(uri);
      } else {
        await launchTrustedSocialYouTubeExternalUri(uri);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _customerMessage(error));
    }
  }

  Future<void> _pickVideo(SocialMediaSource source) async {
    setState(() {
      _selecting = true;
      _error = null;
      _uploaded = null;
    });
    try {
      final media = await _mediaPicker.pickReel(source);
      if (media == null) {
        if (mounted) setState(() => _selecting = false);
        return;
      }
      final info = await _mediaInspector.inspect(media);
      if (!info.isVertical) {
        throw const FormatException(
          'Choose a vertical video for a YouTube Short.',
        );
      }
      if (!info.isShortDuration) {
        throw const FormatException(
          'Choose a video that is no longer than 3 minutes.',
        );
      }
      if (info.byteLength < 1) {
        throw const FormatException('The selected video is empty.');
      }
      if (!mounted) return;
      final suggestedTitle = media.name
          .replaceFirst(RegExp(r'\.[^.]+$'), '')
          .replaceAll(RegExp(r'[_-]+'), ' ')
          .trim();
      setState(() {
        _media = media;
        _mediaInfo = info;
        _selecting = false;
        _progress = 0;
        _idempotencyKey = null;
        if (_title.text.trim().isEmpty) {
          _title.text = suggestedTitle.length > 100
              ? suggestedTitle.substring(0, 100)
              : suggestedTitle;
        }
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _selecting = false;
        _error = _customerMessage(error);
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_media == null || _mediaInfo == null) {
      setState(() => _error = 'Choose a vertical video first.');
      return;
    }
    if (_madeForKids == null) {
      setState(() => _error = 'Choose whether this video is made for kids.');
      return;
    }
    if (!_rightsConfirmed) {
      setState(() => _error = 'Confirm that you have the rights to upload.');
      return;
    }

    final cancellation = YouTubeUploadCancellation();
    final idempotencyKey = _idempotencyKey ?? _newIdempotencyKey();
    setState(() {
      _cancellation = cancellation;
      _idempotencyKey = idempotencyKey;
      _uploading = true;
      _stopping = false;
      _uploaded = null;
      _error = null;
    });
    try {
      final result = await _gateway.uploadPrivateShort(
        idempotencyKey: idempotencyKey,
        path: _media!.path,
        contentType: _mediaInfo!.contentType,
        metadata: YouTubePrivateUploadMetadata(
          title: _title.text.trim(),
          description: _description.text,
          categoryId: _categoryId,
          madeForKids: _madeForKids!,
          containsSyntheticMedia: _containsSyntheticMedia,
          containsPaidPromotion: _containsPaidPromotion,
          notifySubscribers: _notifySubscribers,
        ),
        onProgress: (accepted, total) {
          if (!mounted || cancellation.isCancelled || total < 1) return;
          setState(() => _progress = accepted / total);
        },
        cancellation: cancellation,
      );
      if (!mounted) return;
      setState(() {
        _uploaded = result;
        _uploading = false;
        _stopping = false;
        _progress = 1;
      });
    } on YouTubeUploadCancelledException {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _stopping = false;
        _progress = 0;
        _error = 'Upload cancelled. Your video was not presented as complete.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _stopping = false;
        _error = _customerMessage(error);
      });
    }
  }

  void _cancelUpload() {
    if (!_uploading || _progress >= 1) return;
    _cancellation?.cancel();
    setState(() => _stopping = true);
  }

  String _newIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return 'yt-short-${base64UrlEncode(bytes).replaceAll('=', '')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('social-youtube-creator-screen'),
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('youtube-creator-back'),
          tooltip: _channelBrowseOpen ? 'Back to channel connection' : 'Back',
          onPressed: _handleScreenBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/prototype/provider-youtube.svg',
              width: 30,
              height: 22,
              semanticsLabel: 'YouTube',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _channelBrowseOpen
                    ? (_channelDetails?.title ??
                          _connected?.channelTitle ??
                          'Channel')
                    : widget.uploadCapabilityAuthorized
                    ? 'Create a Short'
                    : 'YouTube channel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  key: Key('youtube-creator-loading'),
                ),
              )
            : _channelBrowseOpen
            ? _channelBrowserBody()
            : RefreshIndicator(
                onRefresh: _refreshConnection,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Text(
                      widget.uploadCapabilityAuthorized
                          ? 'Upload through MoolSocial. Hosted and managed on YouTube.'
                          : 'Optional read-only connection. Public YouTube videos and Shorts stay hosted, managed and played by YouTube.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      _CreatorNotice(
                        key: const Key('youtube-creator-error'),
                        message: _error!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!_providerReady)
                      _unavailableCard()
                    else if (_connected == null) ...[
                      _connectCard(),
                      if (!widget.uploadCapabilityAuthorized) ...[
                        const SizedBox(height: 14),
                        _connectionControlCard(connected: false),
                      ],
                    ] else ...[
                      _channelCard(_connected!),
                      const SizedBox(height: 14),
                      if (!widget.uploadCapabilityAuthorized)
                        _connectionControlCard(connected: true)
                      else if (!_hasUploadPermission)
                        _permissionCard()
                      else
                        _uploadComposer(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _unavailableCard() {
    return _CreatorCard(
      key: const Key('youtube-creator-unavailable'),
      icon: Icons.cloud_off_outlined,
      title: widget.uploadCapabilityAuthorized
          ? 'YouTube creator tools are unavailable'
          : 'YouTube connection is unavailable',
      detail: widget.uploadCapabilityAuthorized
          ? 'Your MoolSocial posts are unaffected. Try this creator option again later.'
          : 'Your MoolSocial Feed and Create tools are unaffected. Try the optional YouTube connection again later.',
      action: OutlinedButton.icon(
        onPressed: _refreshConnection,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try again'),
      ),
    );
  }

  Widget _connectCard() {
    return _CreatorCard(
      key: const Key('youtube-creator-disconnected'),
      icon: Icons.account_circle_outlined,
      title: 'Connect your YouTube channel',
      detail: widget.uploadCapabilityAuthorized
          ? 'Choose the Google account that owns the channel. You can review access and disconnect at any time.'
          : 'Choose the existing Google account that owns the channel. MoolSocial requests only YouTube read-only (youtube.readonly) access and cannot upload, edit or delete YouTube content.',
      action: FilledButton.icon(
        key: const Key('youtube-creator-connect'),
        onPressed: _connecting ? null : _connect,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF0033),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
        ),
        icon: _connecting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.open_in_browser_rounded),
        label: Text(_connecting ? 'Opening Google…' : 'Connect with Google'),
      ),
    );
  }

  Widget _connectionControlCard({required bool connected}) {
    return _CreatorCard(
      key: const Key('youtube-creator-readonly-access'),
      icon: Icons.verified_user_outlined,
      title: 'Read-only access and your controls',
      detail: connected
          ? 'MoolSocial may read eligible public channel information. It cannot upload, edit, delete, like, comment, subscribe or manage playlists. Disconnect here at any time, or review and revoke access in your Google Account.'
          : 'Before connecting, review how MoolSocial uses YouTube data and your deletion and revocation controls. Connection is optional and uses only youtube.readonly access. It cannot upload, edit, delete, like, comment, subscribe or manage playlists.',
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: const Key('youtube-creator-privacy'),
            onPressed: () => _openExternal(_youtubePrivacyUri),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Privacy and YouTube data use'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('youtube-creator-disconnect-help'),
            onPressed: () => _openExternal(_youtubeDisconnectUri),
            icon: const Icon(Icons.link_off_rounded),
            label: const Text('Disconnect and revoke access'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('youtube-creator-google-permissions'),
            onPressed: () => _openExternal(_googlePermissionsUri),
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Review Google permissions'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('youtube-creator-delete-account'),
            onPressed: () => _openExternal(_deleteAccountUri),
            icon: const Icon(Icons.person_remove_outlined),
            label: const Text('Delete MoolSocial account'),
          ),
        ],
      ),
    );
  }

  Widget _channelCard(YouTubeConnected channel) {
    return Container(
      key: const Key('youtube-creator-connected'),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFFF0033),
                foregroundColor: Colors.white,
                child: Icon(Icons.play_arrow_rounded, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF188038),
                          size: 18,
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Connected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      channel.channelTitle,
                      key: const Key('youtube-creator-channel-title'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      channel.channelId,
                      style: const TextStyle(
                        color: Color(0xFF606060),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('youtube-creator-disconnect'),
                onPressed: _uploading ? null : _disconnect,
                child: const Text('Disconnect'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('youtube-creator-browse-channel'),
            onPressed: _channelBrowser == null ? null : _openChannelBrowser,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF0033),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.video_library_outlined),
            label: const Text('Browse connected channel'),
          ),
        ],
      ),
    );
  }

  Widget _channelBrowserBody() {
    if (_channelBrowseLoading && _channelDetails == null) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('youtube-channel-browser-loading'),
        ),
      );
    }
    if (_channelBrowseError case final error? when _channelDetails == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CreatorNotice(
            key: const Key('youtube-channel-browser-error'),
            message: error,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('youtube-channel-browser-retry'),
            onPressed: _loadChannelBrowser,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      );
    }
    final details = _channelDetails;
    if (details == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: _loadChannelBrowser,
      child: ListView(
        key: const Key('youtube-channel-browser'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _connectedChannelHeader(details),
          if (_channelBrowseError case final error?) ...[
            const SizedBox(height: 12),
            _CreatorNotice(message: error),
          ],
          const SizedBox(height: 20),
          Text(
            _activeChannelPlaylistTitle ?? 'Uploads',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (_activeChannelPlaylistId != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('youtube-channel-back-to-uploads'),
                onPressed: _showChannelUploads,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to channel uploads'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (_channelVideos.isEmpty)
            const _CreatorNotice(
              key: Key('youtube-channel-videos-empty'),
              message: 'No public channel uploads are available.',
            )
          else
            for (final video in _channelVideos) _channelVideoTile(video),
          if (_channelVideosNextPageToken != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('youtube-channel-load-more'),
              onPressed: _channelBrowseLoadingMore
                  ? null
                  : () => _loadChannelBrowser(loadMore: true),
              icon: _channelBrowseLoadingMore
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(
                _channelBrowseLoadingMore ? 'Loading…' : 'Load more videos',
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Playlists',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (_channelPlaylists.isEmpty)
            const _CreatorNotice(
              key: Key('youtube-channel-playlists-empty'),
              message: 'No public playlists are available.',
            )
          else
            for (final playlist in _channelPlaylists)
              _channelPlaylistTile(playlist),
          if (_channelPlaylistsNextPageToken != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('youtube-channel-load-more-playlists'),
              onPressed: _channelPlaylistsLoadingMore
                  ? null
                  : _loadMoreChannelPlaylists,
              icon: _channelPlaylistsLoadingMore
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(
                _channelPlaylistsLoadingMore
                    ? 'Loading…'
                    : 'Load more playlists',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _connectedChannelHeader(YouTubePublicChannelDetails details) {
    final subscriberText = details.statistics.hiddenSubscriberCount
        ? 'Subscribers hidden'
        : '${details.statistics.subscriberCount ?? '0'} subscribers';
    return Container(
      key: const Key('youtube-channel-details'),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _YouTubeNetworkThumbnail(
                url: details.thumbnail?.url,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(32),
                fallback: const Icon(
                  Icons.account_circle_rounded,
                  color: Color(0xFFFF0033),
                  size: 60,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.title,
                      key: const Key('youtube-channel-browser-title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subscriberText · ${details.statistics.videoCount ?? '0'} videos',
                      style: const TextStyle(color: Color(0xFF606060)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (details.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              details.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _channelVideoTile(YouTubeVideoSummary video) {
    return Card(
      key: Key('youtube-channel-video-${video.videoId}'),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openChannelVideoInMoolSocial(video),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _YouTubeNetworkThumbnail(
              url: video.thumbnail.url,
              width: 142,
              height: 80,
              fallback: const Icon(Icons.play_circle_outline_rounded),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _videoMetadata(video),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF606060),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelPlaylistTile(YouTubePublicPlaylistDetails playlist) {
    return Card(
      key: Key('youtube-channel-playlist-${playlist.playlistId}'),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openChannelPlaylist(playlist),
        leading: _YouTubeNetworkThumbnail(
          url: playlist.thumbnail?.url,
          width: 72,
          height: 48,
          fallback: const Icon(Icons.playlist_play_rounded),
        ),
        title: Text(
          playlist.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${playlist.itemCount} videos'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  void _openChannelVideoInMoolSocial(YouTubeVideoSummary selectedVideo) {
    final details = _channelDetails;
    if (details == null) return;
    final videos = _channelVideos
        .map((video) => mapScreen04YouTubePublicVideo(video, channel: details))
        .toList(growable: false);
    Screen04YouTubePublicVideo? selected;
    for (final video in videos) {
      if (video.videoId == selectedVideo.videoId) {
        selected = video;
        break;
      }
    }
    if (selected == null) {
      setState(() {
        _channelBrowseError =
            'This channel video is unavailable in MoolSocial right now.';
      });
      return;
    }
    screen04YouTubeCatalogueSnapshots.replaceVideos(videos);
    youtubePublicWatchState.replace(
      selectedVideo: mapScreen04VideoToYouTubePublicCatalogueItem(selected),
      origin: YouTubePublicWatchOrigin.home,
    );
    context.go(
      '/app/social?sub=videos&state=video-watch&item='
      '${Uri.encodeQueryComponent(selectedVideo.videoId)}',
    );
  }

  String _videoMetadata(YouTubeVideoSummary video) {
    final parts = <String>[];
    if (video.viewCount case final count?) parts.add('$count views');
    parts.add(_relativePublishedDate(video.publishedAt));
    return parts.join(' · ');
  }

  String _relativePublishedDate(DateTime publishedAt) {
    final days = DateTime.now().toUtc().difference(publishedAt.toUtc()).inDays;
    if (days < 1) return 'Today';
    if (days < 30) return '$days day${days == 1 ? '' : 's'} ago';
    final months = days ~/ 30;
    if (months < 12) return '$months month${months == 1 ? '' : 's'} ago';
    final years = days ~/ 365;
    return '$years year${years == 1 ? '' : 's'} ago';
  }

  Widget _permissionCard() {
    return _CreatorCard(
      key: const Key('youtube-creator-reconnect-required'),
      icon: Icons.lock_reset_rounded,
      title: 'Reconnect to upload',
      detail:
          'Review the Google connection again so you can choose this channel for uploads.',
      action: FilledButton.icon(
        onPressed: _connecting ? null : _connect,
        icon: const Icon(Icons.open_in_browser_rounded),
        label: const Text('Reconnect with Google'),
      ),
    );
  }

  Widget _uploadComposer() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '1  Choose a vertical video',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Up to 3 minutes. The video uploads directly from this phone to YouTube.',
                ),
                const SizedBox(height: 14),
                if (_media == null) ...[
                  FilledButton.icon(
                    key: const Key('youtube-creator-pick-gallery'),
                    onPressed: _selecting
                        ? null
                        : () => _pickVideo(SocialMediaSource.gallery),
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(
                      _selecting ? 'Checking video…' : 'Choose from gallery',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('youtube-creator-pick-camera'),
                    onPressed: _selecting
                        ? null
                        : () => _pickVideo(SocialMediaSource.camera),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Record a Short'),
                  ),
                ] else
                  _selectedVideoCard(),
              ],
            ),
          ),
          if (_media != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '2  Add details',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('youtube-creator-title'),
                    controller: _title,
                    enabled: !_uploading,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final title = value?.trim() ?? '';
                      if (title.isEmpty) return 'Enter a title.';
                      if (title.runes.length > 100) {
                        return 'Use 100 characters or fewer.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('youtube-creator-description'),
                    controller: _description,
                    enabled: !_uploading,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => utf8.encode(value ?? '').length > 5000
                        ? 'Use a shorter description.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: const Key('youtube-creator-category'),
                    initialValue: _categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '22',
                        child: Text('People & Blogs'),
                      ),
                      DropdownMenuItem(
                        value: '24',
                        child: Text('Entertainment'),
                      ),
                      DropdownMenuItem(
                        value: '25',
                        child: Text('News & Politics'),
                      ),
                      DropdownMenuItem(value: '27', child: Text('Education')),
                      DropdownMenuItem(
                        value: '28',
                        child: Text('Science & Technology'),
                      ),
                    ],
                    onChanged: _uploading
                        ? null
                        : (value) =>
                              setState(() => _categoryId = value ?? '22'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Audience',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  IgnorePointer(
                    ignoring: _uploading,
                    child: RadioGroup<bool>(
                      groupValue: _madeForKids,
                      onChanged: (value) {
                        if (_uploading) return;
                        setState(() => _madeForKids = value);
                      },
                      child: const Column(
                        children: [
                          RadioListTile<bool>(
                            key: Key('youtube-creator-not-kids'),
                            contentPadding: EdgeInsets.zero,
                            value: false,
                            title: Text('No, it is not made for kids'),
                          ),
                          RadioListTile<bool>(
                            key: Key('youtube-creator-made-for-kids'),
                            contentPadding: EdgeInsets.zero,
                            value: true,
                            title: Text('Yes, it is made for kids'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('youtube-creator-synthetic'),
                    contentPadding: EdgeInsets.zero,
                    value: _containsSyntheticMedia,
                    onChanged: _uploading
                        ? null
                        : (value) => setState(
                            () => _containsSyntheticMedia = value ?? false,
                          ),
                    title: const Text(
                      'Contains realistic altered or synthetic content',
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('youtube-creator-paid-promotion'),
                    contentPadding: EdgeInsets.zero,
                    value: _containsPaidPromotion,
                    onChanged: _uploading
                        ? null
                        : (value) => setState(
                            () => _containsPaidPromotion = value ?? false,
                          ),
                    title: const Text('Contains paid promotion'),
                  ),
                  CheckboxListTile(
                    key: const Key('youtube-creator-notify-subscribers'),
                    contentPadding: EdgeInsets.zero,
                    value: _notifySubscribers,
                    onChanged: _uploading
                        ? null
                        : (value) => setState(
                            () => _notifySubscribers = value ?? false,
                          ),
                    title: const Text('Notify subscribers when eligible'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '3  Review and upload',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_outline_rounded),
                    title: Text(
                      'Visibility: Private',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Only you can view it until you change visibility in YouTube Studio.',
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('youtube-creator-rights'),
                    contentPadding: EdgeInsets.zero,
                    value: _rightsConfirmed,
                    onChanged: _uploading
                        ? null
                        : (value) =>
                              setState(() => _rightsConfirmed = value ?? false),
                    title: const Text('I have the rights to upload this video'),
                  ),
                  if (_uploading || _uploaded != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      key: const Key('youtube-creator-progress'),
                      value: _uploaded != null ? 1 : _progress.clamp(0, 1),
                      minHeight: 8,
                      borderRadius: const BorderRadius.all(Radius.circular(99)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploaded != null
                          ? 'Uploaded privately to YouTube'
                          : _progress >= 1
                          ? 'YouTube is processing your video…'
                          : _stopping
                          ? 'Stopping upload…'
                          : '${(_progress * 100).round()}% uploaded',
                      key: const Key('youtube-creator-progress-label'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_uploaded != null)
                    FilledButton.icon(
                      key: const Key('youtube-creator-upload-complete'),
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Private upload complete'),
                    )
                  else
                    FilledButton.icon(
                      key: const Key('youtube-creator-upload'),
                      onPressed: _uploading ? null : _upload,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF0033),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.upload_rounded),
                      label: Text(
                        _idempotencyKey == null
                            ? 'Upload privately to YouTube'
                            : 'Retry private upload',
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    _CreatorNotice(message: _error!),
                  ],
                  if (_uploading && _progress < 1) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('youtube-creator-cancel-upload'),
                      onPressed: _stopping ? null : _cancelUpload,
                      child: const Text('Cancel upload'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectedVideoCard() {
    final info = _mediaInfo!;
    return Container(
      key: const Key('youtube-creator-selected-video'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.smart_display_rounded,
            color: Color(0xFFFF0033),
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _media!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_formatDuration(info.duration)} • ${info.width.round()}×${info.height.round()} • ${_formatBytes(info.byteLength)}',
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _uploading
                ? null
                : () => _pickVideo(SocialMediaSource.gallery),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E5E5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
}

class _YouTubeNetworkThumbnail extends StatelessWidget {
  const _YouTubeNetworkThumbnail({
    required this.url,
    required this.width,
    required this.height,
    required this.fallback,
    this.borderRadius = BorderRadius.zero,
  });

  final Uri? url;
  final double width;
  final double height;
  final Widget fallback;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: const Color(0xFFE5E5E5),
          child: imageUrl == null
              ? Center(child: fallback)
              : Image.network(
                  imageUrl.toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(child: fallback),
                ),
        ),
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 42, color: const Color(0xFFFF0033)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF606060), height: 1.35),
          ),
          const SizedBox(height: 18),
          action,
        ],
      ),
    );
  }
}

class _CreatorNotice extends StatelessWidget {
  const _CreatorNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC9C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB3261E)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _customerMessage(Object error) {
  if (error is FormatException) return error.message.toString();
  if (error is FileSystemException) {
    return 'The selected video could not be read. Choose it again.';
  }
  if (error is YouTubeTransportException) {
    return switch (error.code) {
      'media_unavailable' || 'content_identity_mismatch' =>
        'The selected video changed or is unavailable. Choose it again.',
      'upload_session_expired' =>
        'The upload session expired. Tap retry to continue safely.',
      'provider_timeout' || 'provider_unavailable' =>
        'YouTube could not be reached. Check your connection and try again.',
      _ when error.retryable => 'The upload paused. Tap retry to continue.',
      _ => 'The video could not be uploaded. Review the details and try again.',
    };
  }
  if (error is YouTubeProviderClientException) {
    return switch (error.code) {
      'authentication_required' =>
        'Sign in to MoolSocial again, then reconnect YouTube.',
      'connection_required' || 'insufficient_scope' =>
        'Reconnect YouTube to allow uploads to this channel.',
      'upload_processing_timeout' =>
        'Your video reached YouTube and is still processing. Tap retry to check again.',
      'upload_processing_failed' =>
        'YouTube could not finish processing this video. Review the video and try again.',
      _ when error.retryable =>
        'YouTube is temporarily unavailable. Try again.',
      _ => 'YouTube could not complete that request. Try again.',
    };
  }
  return 'Something went wrong. Try again.';
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}
