import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/youtube/youtube_embedded_player_android.dart';
import '../../core/youtube/youtube_embedded_player_contract.dart';
import '../../core/youtube/youtube_embedded_player_controller.dart';
import '../../core/youtube/youtube_private_dev_app_check.dart';
import '../../features/creator/creator_session.dart';
import '../../features/journey01/journey_session.dart';
import '../../features/retailer/retailer_session.dart';
import '../../features/shared/shared_models.dart';
import '../../features/shared/shared_session.dart';
import '../../features/shared/social_content_gateway.dart';
import '../../features/shared/social_media_picker.dart';
import '../../features/shared/social_create_draft_media_store.dart';
import '../../features/shared/social_create_draft_repository.dart';
import '../../features/shared/youtube_public_catalogue_repository.dart';
import '../../features/shared/youtube_public_search_state_repository.dart';
import '../../features/shared/youtube_public_short_state_repository.dart';
import '../../features/shared/youtube_public_watch_state_repository.dart';
import '../buy/buy_v2_shop_chat.dart';
import '../profile/global_profile_panel_v2.dart';
import '../universal/mool_contextual_chat_v2.dart';
import '../universal/mool_global_navigation_v2.dart';
import 'social_v2_create_workbench.dart';
import 'social_v2_design.dart';
import 'social_v2_public_content.dart';
import 'social_v2_youtube_public_runtime.dart';
import 'screen04_universal_components.dart';

typedef Screen04YouTubePublicVideoLoader =
    Future<List<Screen04YouTubePublicVideo>> Function();
typedef Screen04YouTubePublicSearchLoader =
    Future<List<Screen04YouTubePublicVideo>> Function(String query);
typedef Screen04YouTubePublicChannelLoader =
    Future<Screen04YouTubePublicChannelCatalogue> Function(String channelId);

enum SocialV2ShareOutcome { selected, dismissed, unavailable }

@immutable
class SocialV2ShareRequest {
  const SocialV2ShareRequest({
    required this.uri,
    required this.title,
    required this.sharePositionOrigin,
    this.subject,
  });

  final Uri uri;
  final String title;
  final String? subject;
  final Rect sharePositionOrigin;
}

abstract interface class SocialV2ShareGateway {
  Future<SocialV2ShareOutcome> share(SocialV2ShareRequest request);
}

typedef SocialV2PlatformShareInvoker =
    Future<ShareResult> Function(ShareParams params);

class SocialV2PlatformShareGateway implements SocialV2ShareGateway {
  SocialV2PlatformShareGateway({SocialV2PlatformShareInvoker? invoker})
    : _invoker = invoker ?? SharePlus.instance.share;

  final SocialV2PlatformShareInvoker _invoker;
  Future<SocialV2ShareOutcome>? _inFlight;

  @override
  Future<SocialV2ShareOutcome> share(SocialV2ShareRequest request) {
    final active = _inFlight;
    if (active != null) return active;

    final operation = _shareOnce(request);
    _inFlight = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_inFlight, operation)) _inFlight = null;
      }),
    );
    return operation;
  }

  Future<SocialV2ShareOutcome> _shareOnce(SocialV2ShareRequest request) async {
    final title = request.title.trim();
    final subject = request.subject?.trim();
    final origin = request.sharePositionOrigin;
    if (request.uri.scheme != 'https' ||
        request.uri.host.isEmpty ||
        request.uri.userInfo.isNotEmpty ||
        title.isEmpty ||
        title.length > 120 ||
        title.contains(RegExp(r'[\u0000-\u001F\u007F]')) ||
        (subject != null &&
            (subject.length > 200 ||
                subject.contains(RegExp(r'[\u0000-\u001F\u007F]')))) ||
        !origin.isFinite ||
        origin.width <= 0 ||
        origin.height <= 0) {
      return SocialV2ShareOutcome.unavailable;
    }

    try {
      final result = await _invoker(
        ShareParams(
          uri: request.uri,
          title: title,
          subject: subject == null || subject.isEmpty ? null : subject,
          sharePositionOrigin: origin,
          downloadFallbackEnabled: false,
          mailToFallbackEnabled: false,
        ),
      );
      return switch (result.status) {
        ShareResultStatus.success => SocialV2ShareOutcome.selected,
        ShareResultStatus.dismissed => SocialV2ShareOutcome.dismissed,
        ShareResultStatus.unavailable => SocialV2ShareOutcome.unavailable,
      };
    } on Object {
      return SocialV2ShareOutcome.unavailable;
    }
  }
}

final Expando<_SocialV2RetainedState> _socialV2RetainedStates =
    Expando<_SocialV2RetainedState>();

Future<bool> resetSocialV2RetainedStateForAuthenticationBoundary(
  SharedSession session,
) async {
  _socialV2RetainedStates[session] = _SocialV2RetainedState();
  unawaited(youtubePublicSearchState.clear(detachRepository: true));
  unawaited(youtubePublicWatchState.clear(detachRepository: true));
  unawaited(youtubePublicShortState.clear(detachRepository: true));
  final envelopeClear = socialCreateDraftState.clearConfirmed(
    detachRepository: true,
  );
  final mediaStore = socialCreateDraftMediaStore;
  final mediaPurge = mediaStore?.disableStagingAndPurgeAll();
  final envelopeCleared = await envelopeClear;
  final mediaCleared = mediaPurge == null || await mediaPurge;
  return envelopeCleared && mediaCleared;
}

class _SocialV2RetainedState {
  _SocialV2RetainedState()
    : choiceByWorld = <String, String>{
        for (final world in screen04Worlds) world.id: world.choices.first.id,
      };

  final Map<String, String> choiceByWorld;
  final SocialCreateDraftV2 createDraft = SocialCreateDraftV2();
  final Map<String, BuyV2ShopChatRetainedState> contextualChatStates = {};
  String createView = 'home';
  String feedState = 'empty';
  int activeShortPage = 0;
  double videoHomeScrollOffset = 0;
  double videoWatchScrollOffset = 0;
  double youtubeSearchScrollOffset = 0;
  _VideoData? activeVideo;
  _VideoData? youtubeSearchOriginVideo;
  String videoQuery = '';
  String youtubeSubmittedQuery = '';
  bool youtubeSearchOpen = false;
  bool returnToYouTubeSearchAfterVideo = false;
  String? youtubeSearchError;
  List<_VideoData> youtubeSearchResults = const [];
}

enum _MoolSocialFeedMode { forYou, following, latest }

extension on _MoolSocialFeedMode {
  String get label => switch (this) {
    _MoolSocialFeedMode.forYou => 'For you',
    _MoolSocialFeedMode.following => 'Following',
    _MoolSocialFeedMode.latest => 'Latest',
  };

  IconData get icon => switch (this) {
    _MoolSocialFeedMode.forYou => Icons.auto_awesome_outlined,
    _MoolSocialFeedMode.following => Icons.people_outline_rounded,
    _MoolSocialFeedMode.latest => Icons.schedule_rounded,
  };
}

class SocialUniversalV2 extends StatefulWidget {
  const SocialUniversalV2({
    required this.session,
    required this.creatorSession,
    required this.retailerSession,
    required this.sharedSession,
    this.initialSubAction,
    this.initialState,
    this.initialItem,
    this.initialAction,
    this.initialChoice,
    this.initialWorld = 'social',
    this.onOpenMool,
    this.onOpenMainAction,
    this.onContextualChatAction,
    this.onContextualChatHandoff,
    this.contextualChatSource =
        const MoolDefaultContextualChatProvisioningSource(),
    this.mediaPicker,
    this.enableCreateReviewPreview = false,
    @visibleForTesting this.youtubePublicAccessOverride,
    @visibleForTesting this.youtubeCreatorAccessOverride,
    @visibleForTesting this.youtubeVideosLoader,
    @visibleForTesting this.youtubeShortsLoader,
    @visibleForTesting this.youtubeSearchLoader,
    @visibleForTesting this.youtubeChannelLoader,
    @visibleForTesting this.youtubeCatalogueSnapshotStore,
    @visibleForTesting this.youtubeSearchStateCache,
    @visibleForTesting this.youtubeWatchStateCache,
    @visibleForTesting this.youtubeShortStateCache,
    @visibleForTesting this.createDraftStateCache,
    @visibleForTesting this.createDraftMediaStore,
    @visibleForTesting this.shareGateway,
    @visibleForTesting this.disableLocalDraftMediaPreviewForTesting = false,
    super.key,
  });

  final JourneySession session;
  final CreatorSession creatorSession;
  final RetailerSession retailerSession;
  final SharedSession sharedSession;
  final String? initialSubAction;
  final String? initialState;
  final String? initialItem;
  final String? initialAction;
  final String? initialChoice;
  final String initialWorld;
  final VoidCallback? onOpenMool;
  final ValueChanged<PersonalMoolActionSpec>? onOpenMainAction;
  final BuyV2ShopChatActionHandler? onContextualChatAction;
  final BuyV2ShopChatHandoffHandler? onContextualChatHandoff;
  final MoolContextualChatProvisioningSource contextualChatSource;
  final SocialMediaPicker? mediaPicker;
  final bool enableCreateReviewPreview;

  @visibleForTesting
  final bool? youtubePublicAccessOverride;

  @visibleForTesting
  final bool? youtubeCreatorAccessOverride;

  @visibleForTesting
  final Screen04YouTubePublicVideoLoader? youtubeVideosLoader;

  @visibleForTesting
  final Screen04YouTubePublicVideoLoader? youtubeShortsLoader;

  @visibleForTesting
  final Screen04YouTubePublicSearchLoader? youtubeSearchLoader;

  @visibleForTesting
  final Screen04YouTubePublicChannelLoader? youtubeChannelLoader;

  @visibleForTesting
  final Screen04YouTubeCatalogueSnapshotStore? youtubeCatalogueSnapshotStore;

  @visibleForTesting
  final YouTubePublicSearchStateCache? youtubeSearchStateCache;

  @visibleForTesting
  final YouTubePublicWatchStateCache? youtubeWatchStateCache;

  @visibleForTesting
  final YouTubePublicShortStateCache? youtubeShortStateCache;

  @visibleForTesting
  final SocialCreateDraftStateCache? createDraftStateCache;

  @visibleForTesting
  final SocialCreateDraftMediaStore? createDraftMediaStore;

  @visibleForTesting
  final SocialV2ShareGateway? shareGateway;

  @visibleForTesting
  final bool disableLocalDraftMediaPreviewForTesting;

  @override
  State<SocialUniversalV2> createState() => _SocialUniversalV2State();
}

class _SocialUniversalV2State extends State<SocialUniversalV2>
    with WidgetsBindingObserver {
  final GlobalKey<BuyV2ShopChatViewState> _contextualChatKey = GlobalKey();
  late SocialV2Tab _tab;
  late String _world;
  late bool _chatAuthenticated;
  bool _contextualChatActive = false;
  bool _createReviewPreviewActive = false;
  late final _SocialV2RetainedState _retainedState;

  Map<String, String> get _choiceByWorld => _retainedState.choiceByWorld;

  String get _feedState => _retainedState.feedState;
  set _feedState(String value) => _retainedState.feedState = value;
  String get _createView => _retainedState.createView;
  set _createView(String value) => _retainedState.createView = value;
  late bool _contentUnavailable;
  int get _activeShortPage => _retainedState.activeShortPage;
  set _activeShortPage(int value) => _retainedState.activeShortPage = value;
  late final PageController _shortController;
  late final ScrollController _videoHomeController;
  late final ScrollController _videoWatchController;
  late final ScrollController _youtubeSearchResultsController;
  late final TextEditingController _youtubeSearchController;
  late final FocusNode _youtubeSearchFocusNode;
  late final TextEditingController _feedSearchController;
  bool _feedSearchOpen = false;
  String _feedQuery = '';
  _MoolSocialFeedMode _feedMode = _MoolSocialFeedMode.forYou;
  final Set<String> _pendingFeedMessageRequests = <String>{};
  late final SocialMediaPicker _mediaPicker;
  SocialCreateDraftV2 get _createDraft => _retainedState.createDraft;
  late final Screen04YouTubeCatalogueSnapshotStore _youtubeCatalogueSnapshots;
  late final YouTubePublicSearchStateCache _youtubeSearchStateCache;
  late final YouTubePublicWatchStateCache _youtubeWatchStateCache;
  late final YouTubePublicShortStateCache _youtubeShortStateCache;
  late final SocialCreateDraftStateCache _createDraftStateCache;
  late final SocialCreateDraftMediaStore? _createDraftMediaStore;
  late final SocialV2ShareGateway _shareGateway;
  bool _createDraftHydrating = false;
  bool _createDraftMediaLoss = false;
  bool _restoredCreateDraft = false;
  int _createDraftPersistenceRequest = 0;
  int _createDraftHydrationGeneration = 0;
  bool _createBackBusy = false;
  final Map<String, SocialCreateDraftMediaReference> _draftMediaRefs = {};
  final Set<Future<SocialCreateDraftMediaReference?>> _draftStagingOperations =
      {};
  bool _restoredYouTubeSearch = false;
  bool _preserveDurableSearchForNestedWatch = false;
  _VideoData? get _activeVideo => _retainedState.activeVideo;
  set _activeVideo(_VideoData? value) => _retainedState.activeVideo = value;
  _VideoData? get _youtubeSearchOriginVideo =>
      _retainedState.youtubeSearchOriginVideo;
  set _youtubeSearchOriginVideo(_VideoData? value) =>
      _retainedState.youtubeSearchOriginVideo = value;
  String get _videoQuery => _retainedState.videoQuery;
  set _videoQuery(String value) => _retainedState.videoQuery = value;
  String get _youtubeSubmittedQuery => _retainedState.youtubeSubmittedQuery;
  set _youtubeSubmittedQuery(String value) =>
      _retainedState.youtubeSubmittedQuery = value;
  int _visibleVideoCount = 20;
  int _youtubeSearchRequest = 0;
  int _youtubeCatalogueRequest = 0;
  double get _videoHomeScrollOffset => _retainedState.videoHomeScrollOffset;
  set _videoHomeScrollOffset(double value) =>
      _retainedState.videoHomeScrollOffset = value;
  double get _videoWatchScrollOffset => _retainedState.videoWatchScrollOffset;
  set _videoWatchScrollOffset(double value) =>
      _retainedState.videoWatchScrollOffset = value;
  double get _youtubeSearchScrollOffset =>
      _retainedState.youtubeSearchScrollOffset;
  set _youtubeSearchScrollOffset(double value) =>
      _retainedState.youtubeSearchScrollOffset = value;
  bool get _youtubeSearchOpen => _retainedState.youtubeSearchOpen;
  set _youtubeSearchOpen(bool value) =>
      _retainedState.youtubeSearchOpen = value;
  bool _youtubeSearchLoading = false;
  bool get _returnToYouTubeSearchAfterVideo =>
      _retainedState.returnToYouTubeSearchAfterVideo;
  set _returnToYouTubeSearchAfterVideo(bool value) =>
      _retainedState.returnToYouTubeSearchAfterVideo = value;
  String? get _youtubeSearchError => _retainedState.youtubeSearchError;
  set _youtubeSearchError(String? value) =>
      _retainedState.youtubeSearchError = value;
  List<_VideoData> get _youtubeSearchResults =>
      _retainedState.youtubeSearchResults;
  set _youtubeSearchResults(List<_VideoData> value) =>
      _retainedState.youtubeSearchResults = value;
  List<_VideoData> _liveYouTubeVideos = const [];
  List<_ShortData> _liveYouTubeShorts = const [];
  bool _liveYouTubeLoading = false;
  bool _hasYouTubeVideosSnapshot = false;
  String? _liveYouTubeError;
  bool _liveYouTubeShortsLoading = false;
  bool _hasYouTubeShortsSnapshot = false;
  String? _liveYouTubeShortsError;
  List<Screen04YouTubePublicVideo>? _youtubeChannelOriginSnapshot;
  String? _activeYouTubeChannelId;
  String? _activeYouTubeChannelTitle;
  String? _youtubeChannelError;
  bool _youtubeChannelLoading = false;
  int _youtubeChannelRequest = 0;
  int _feedLinkRequest = 0;
  bool _feedLinkResolving = false;
  bool _feedLinkContextActive = false;
  String? _resolvedFeedLinkItem;
  String? _unavailableFeedLinkItem;
  String? _openedInitialAuthorItem;
  bool _openedInitialSaved = false;
  bool _openedInitialNotifications = false;
  String? _handledInitialFeedActionToken;
  static SocialV2Tab _tabFor(String? subAction) => switch (subAction) {
    'shorts' => SocialV2Tab.shorts,
    'videos' => SocialV2Tab.videos,
    'feed' => SocialV2Tab.feed,
    'create' => SocialV2Tab.create,
    _ => SocialV2Tab.videos,
  };

  static String _createViewFor(String? state) => switch (state) {
    'post' ||
    'text' ||
    'image' ||
    'reel-source' ||
    'reel-camera' ||
    'reel-edit' ||
    'carousel' ||
    'image-poll' ||
    'quick-poll' ||
    'quiz' ||
    'shared-post' ||
    'drafts' ||
    'publishing' ||
    'failure' ||
    'success' => state!,
    _ => 'home',
  };

  static String _feedStateFor(String? state) => switch (state) {
    'loading' || 'error' || 'unavailable' => state!,
    _ => 'empty',
  };

  bool get _youtubePublicAccessAvailable =>
      widget.youtubePublicAccessOverride ?? youtubePrivateDevProofEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final retained = _socialV2RetainedStates[widget.sharedSession];
    final hasRetainedState = retained != null;
    if (retained == null) {
      _retainedState = _SocialV2RetainedState();
      _socialV2RetainedStates[widget.sharedSession] = _retainedState;
    } else {
      _retainedState = retained;
    }
    _chatAuthenticated = widget.session.isAuthenticated;
    widget.session.addListener(_handleChatIdentityBoundary);
    _shareGateway = widget.shareGateway ?? SocialV2PlatformShareGateway();
    _youtubeCatalogueSnapshots =
        widget.youtubeCatalogueSnapshotStore ??
        (widget.youtubeVideosLoader == null &&
                widget.youtubeShortsLoader == null
            ? screen04YouTubeCatalogueSnapshots
            : Screen04YouTubeCatalogueSnapshotStore());
    _createDraftStateCache =
        widget.createDraftStateCache ??
        (widget.mediaPicker == null
            ? socialCreateDraftState
            : SocialCreateDraftStateCache());
    _createDraftMediaStore =
        widget.createDraftMediaStore ?? socialCreateDraftMediaStore;
    final restoredCreateDraft = !hasRetainedState
        ? _createDraftStateCache.snapshot
        : null;
    if (restoredCreateDraft == null) {
      _createDraft.setChangeListener(_scheduleCreateDraftPersistence);
    } else {
      _createDraftHydrating = true;
      _restoredCreateDraft = true;
      final hydration = ++_createDraftHydrationGeneration;
      unawaited(_hydrateCreateDraft(restoredCreateDraft, hydration));
    }
    _youtubeSearchStateCache =
        widget.youtubeSearchStateCache ??
        (widget.youtubeSearchLoader == null
            ? youtubePublicSearchState
            : YouTubePublicSearchStateCache());
    final canRestoreDurableSearch =
        !hasRetainedState &&
        widget.initialWorld == 'social' &&
        (widget.initialSubAction == null ||
            widget.initialSubAction == 'videos') &&
        (widget.initialState == null || widget.initialState == 'video-watch');
    final restoredSearch = canRestoreDurableSearch
        ? _youtubeSearchStateCache.snapshot
        : null;
    if (restoredSearch != null && restoredSearch.searchSurfaceOpen) {
      _choiceByWorld['social'] = 'videos';
      _youtubeSubmittedQuery = restoredSearch.submittedQuery;
      _youtubeSearchOpen = true;
      _youtubeSearchResults = restoredSearch.results
          .map(mapYouTubePublicCatalogueItemToScreen04Video)
          .map(_videoDataFromProvider)
          .toList(growable: false);
      _youtubeSearchScrollOffset = restoredSearch.resultsScrollOffset;
      _restoredYouTubeSearch = true;
    }
    _youtubeWatchStateCache =
        widget.youtubeWatchStateCache ??
        (widget.youtubeVideosLoader == null &&
                widget.youtubeSearchLoader == null
            ? youtubePublicWatchState
            : YouTubePublicWatchStateCache());
    final watchCandidate = _youtubeWatchStateCache.snapshot;
    final matchingExplicitWatchRoute =
        widget.initialState == 'video-watch' &&
        widget.initialItem != null &&
        watchCandidate?.selectedVideo.videoId == widget.initialItem;
    final canRestoreDurableWatch =
        !hasRetainedState &&
        widget.initialWorld == 'social' &&
        (widget.initialSubAction == null ||
            widget.initialSubAction == 'videos') &&
        (widget.initialState == null || matchingExplicitWatchRoute);
    final watchSearchOriginAvailable =
        watchCandidate?.origin != YouTubePublicWatchOrigin.search ||
        (restoredSearch != null && restoredSearch.searchSurfaceOpen);
    final restoredWatch = canRestoreDurableWatch && watchSearchOriginAvailable
        ? watchCandidate
        : null;
    if (watchCandidate != null && restoredWatch == null) {
      unawaited(_youtubeWatchStateCache.clear());
    }
    if (restoredWatch != null) {
      _choiceByWorld['social'] = 'videos';
      _activeVideo = _videoDataFromProvider(
        mapYouTubePublicCatalogueItemToScreen04Video(
          restoredWatch.selectedVideo,
        ),
      );
      final searchOriginVideo = restoredWatch.searchOriginVideo;
      _youtubeSearchOriginVideo = searchOriginVideo == null
          ? null
          : _videoDataFromProvider(
              mapYouTubePublicCatalogueItemToScreen04Video(searchOriginVideo),
            );
      _videoHomeScrollOffset = restoredWatch.homeScrollOffset;
      _videoWatchScrollOffset = restoredWatch.watchScrollOffset;
      _returnToYouTubeSearchAfterVideo =
          restoredWatch.origin == YouTubePublicWatchOrigin.search &&
          watchSearchOriginAvailable;
      _youtubeSearchOpen = false;
    } else if (widget.initialState == 'video-watch') {
      _youtubeSearchOpen = false;
    }
    _youtubeShortStateCache =
        widget.youtubeShortStateCache ??
        (widget.youtubeShortsLoader == null
            ? youtubePublicShortState
            : YouTubePublicShortStateCache());
    final shortCandidate = _youtubeShortStateCache.snapshot;
    final canRestoreDurableShort =
        !hasRetainedState &&
        widget.initialWorld == 'social' &&
        (widget.initialSubAction == null ||
            widget.initialSubAction == 'shorts') &&
        widget.initialState == null &&
        _activeVideo == null &&
        !_youtubeSearchOpen;
    final cachedShorts =
        (_youtubeCatalogueSnapshots.readShorts() ??
                const <Screen04YouTubePublicVideo>[])
            .where(_isEligibleYouTubeShortRecord)
            .toList(growable: false);
    final restoredShortIndex = shortCandidate == null
        ? -1
        : cachedShorts.indexWhere(
            (item) =>
                item.videoId == shortCandidate.selectedVideoId &&
                item.embeddable &&
                !item.hasKnownDeviceRegionExclusion,
          );
    if (canRestoreDurableShort && restoredShortIndex >= 0) {
      _choiceByWorld['social'] = 'shorts';
      _activeShortPage = restoredShortIndex;
    } else if (canRestoreDurableShort && shortCandidate != null) {
      if (widget.initialSubAction == 'shorts') {
        _choiceByWorld['social'] = 'shorts';
        _activeShortPage = 0;
      }
      unawaited(_youtubeShortStateCache.clear());
    } else if (shortCandidate != null) {
      unawaited(_youtubeShortStateCache.clear());
    }
    _shortController = PageController(initialPage: _activeShortPage);
    _videoHomeController = ScrollController();
    _videoWatchController = ScrollController(
      initialScrollOffset: _videoWatchScrollOffset,
    )..addListener(_captureYouTubeWatchScrollOffset);
    _youtubeSearchResultsController = ScrollController(
      initialScrollOffset: _youtubeSearchScrollOffset,
    )..addListener(_captureYouTubeSearchScrollOffset);
    _youtubeSearchController = TextEditingController(
      text: _youtubeSubmittedQuery,
    );
    _youtubeSearchFocusNode = FocusNode();
    _feedSearchController = TextEditingController();
    _mediaPicker = widget.mediaPicker ?? NativeSocialMediaPicker();
    _world = screen04Worlds.any((world) => world.id == widget.initialWorld)
        ? widget.initialWorld
        : 'social';
    if (widget.initialSubAction case final subAction?) {
      final activeWorld = screen04World(_world);
      if (activeWorld.choices.any((choice) => choice.id == subAction)) {
        _choiceByWorld[_world] = subAction;
      }
    }
    _tab = _world == 'social'
        ? _tabFor(_choiceByWorld['social'])
        : SocialV2Tab.shorts;
    _createReviewPreviewActive =
        widget.enableCreateReviewPreview &&
        !widget.session.isAuthenticated &&
        _tab == SocialV2Tab.create;
    if (widget.initialState != null) {
      _createView = _createViewFor(widget.initialState);
    } else if (_tab == SocialV2Tab.create && !hasRetainedState) {
      _createView = 'post';
    } else if (_tab == SocialV2Tab.create) {
      _createView = _createDraft.hasMeaningfulContent
          ? _createDraftResumeView()
          : 'post';
    } else if (_tab != SocialV2Tab.create) {
      _createView = 'home';
    }
    if (_tab == SocialV2Tab.feed && widget.initialState != null) {
      _feedState = _feedStateFor(widget.initialState);
    }
    _feedLinkContextActive =
        _tab == SocialV2Tab.feed &&
        (widget.initialItem?.trim().isNotEmpty ?? false);
    _contentUnavailable = widget.initialState == 'unavailable';
    var videosAreFresh = false;
    var shortsAreFresh = false;
    if (_youtubePublicAccessAvailable) {
      final freshVideos = _youtubeCatalogueSnapshots.readFreshVideos();
      final freshShorts = _youtubeCatalogueSnapshots.readFreshShorts();
      final cachedVideos =
          freshVideos ?? _youtubeCatalogueSnapshots.readVideos();
      final cachedShorts =
          freshShorts ?? _youtubeCatalogueSnapshots.readShorts();
      videosAreFresh = freshVideos != null;
      shortsAreFresh = freshShorts != null;
      _hasYouTubeVideosSnapshot = cachedVideos != null;
      _hasYouTubeShortsSnapshot = cachedShorts != null;
      _liveYouTubeVideos =
          cachedVideos?.map(_videoDataFromProvider).toList(growable: false) ??
          const [];
      _liveYouTubeShorts =
          cachedShorts?.map(_shortDataFromProvider).toList(growable: false) ??
          const [];
    }
    _liveYouTubeLoading =
        _youtubePublicAccessAvailable && !_hasYouTubeVideosSnapshot;
    _liveYouTubeShortsLoading =
        _youtubePublicAccessAvailable && !_hasYouTubeShortsSnapshot;
    if (_activeVideo == null &&
        _tab == SocialV2Tab.videos &&
        widget.initialState == 'video-watch') {
      _activeVideo = _videoForProviderId(
        _liveYouTubeVideos,
        widget.initialItem,
      );
    }
    if (_youtubePublicAccessAvailable &&
        (!videosAreFresh ||
            !shortsAreFresh ||
            _liveYouTubeVideos.isEmpty ||
            _liveYouTubeShorts.isEmpty)) {
      unawaited(_loadLiveYouTubeVideos());
    }
    if (widget.sharedSession.socialContentAvailable) {
      if (!widget.sharedSession.socialFeedLoaded &&
          !widget.sharedSession.socialFeedLoading) {
        unawaited(_loadInitialSocialFeed());
      } else if (_hasSharedFeedTarget) {
        unawaited(_resolveSharedFeedItem());
      } else {
        _maybeOpenInitialSaved();
        _maybeOpenInitialNotifications();
      }
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_handleChatIdentityBoundary);
    WidgetsBinding.instance.removeObserver(this);
    _createDraftHydrationGeneration += 1;
    final draftRequest = ++_createDraftPersistenceRequest;
    unawaited(
      _persistCreateDraft(draftRequest)
          .then((persisted) {
            if (!persisted) return Future<void>.value();
            return _createDraftStateCache.settleDurableWrites();
          })
          .catchError((Object _) {}),
    );
    _createDraft.setChangeListener(null);
    if (_videoHomeController.hasClients) {
      _videoHomeScrollOffset = _videoHomeController.offset;
    }
    if (_youtubeSearchResultsController.hasClients) {
      _youtubeSearchScrollOffset = _youtubeSearchResultsController.offset;
      _youtubeSearchStateCache.updateScrollOffset(_youtubeSearchScrollOffset);
    }
    if (_videoWatchController.hasClients) {
      _videoWatchScrollOffset = _videoWatchController.offset;
      _youtubeWatchStateCache.updateWatchScrollOffset(_videoWatchScrollOffset);
    }
    unawaited(_youtubeSearchStateCache.settleDurableWrites());
    unawaited(_youtubeWatchStateCache.settleDurableWrites());
    unawaited(_youtubeShortStateCache.settleDurableWrites());
    _shortController.dispose();
    _videoHomeController.dispose();
    _videoWatchController.dispose();
    _youtubeSearchResultsController.dispose();
    _youtubeSearchController.dispose();
    _youtubeSearchFocusNode.dispose();
    _feedSearchController.dispose();
    _youtubeChannelRequest += 1;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SocialUniversalV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session)) {
      oldWidget.session.removeListener(_handleChatIdentityBoundary);
      widget.session.addListener(_handleChatIdentityBoundary);
      _chatAuthenticated = widget.session.isAuthenticated;
      _retainedState.contextualChatStates.clear();
      _contextualChatActive = false;
    }
    if (oldWidget.initialSubAction != widget.initialSubAction ||
        oldWidget.initialState != widget.initialState ||
        oldWidget.initialItem != widget.initialItem ||
        oldWidget.initialAction != widget.initialAction ||
        oldWidget.initialChoice != widget.initialChoice ||
        oldWidget.initialWorld != widget.initialWorld) {
      final durableWatch = _youtubeWatchStateCache.snapshot;
      final matchingDurableWatch =
          widget.initialWorld == 'social' &&
          (widget.initialSubAction == null ||
              widget.initialSubAction == 'videos') &&
          widget.initialState == 'video-watch' &&
          widget.initialItem == durableWatch?.selectedVideo.videoId &&
          (durableWatch?.origin != YouTubePublicWatchOrigin.search ||
              _youtubeSearchStateCache.snapshot != null);
      if (!matchingDurableWatch) _discardDurableYouTubeWatch();
      _world = screen04Worlds.any((world) => world.id == widget.initialWorld)
          ? widget.initialWorld
          : 'social';
      _contextualChatActive = false;
      final activeWorld = screen04World(_world);
      final requestedChoice = widget.initialSubAction;
      if (requestedChoice != null &&
          activeWorld.choices.any((choice) => choice.id == requestedChoice)) {
        _choiceByWorld[_world] = requestedChoice;
      }
      _tab = _world == 'social'
          ? _tabFor(_choiceByWorld['social'])
          : SocialV2Tab.shorts;
      if (widget.initialState != null) {
        final requestedCreateView = _tab == SocialV2Tab.create
            ? _createViewFor(widget.initialState ?? 'post')
            : 'home';
        if (_tab == SocialV2Tab.create &&
            requestedCreateView != 'home' &&
            _createDraft.hasMeaningfulContent) {
          _createView = _createDraftResumeView();
        } else {
          _createView = requestedCreateView;
          if (_tab == SocialV2Tab.create && _createView != 'home') {
            _createDraft.retargetIntent(_createIntentForView(_createView));
          }
        }
      } else if (_tab != SocialV2Tab.create) {
        _createView = 'home';
      } else {
        _createView = _createDraft.hasMeaningfulContent
            ? _createDraftResumeView()
            : 'post';
      }
      if (_tab == SocialV2Tab.feed) {
        _feedState = _feedStateFor(widget.initialState);
      }
      _feedLinkContextActive =
          _tab == SocialV2Tab.feed &&
          (widget.initialItem?.trim().isNotEmpty ?? false);
      _contentUnavailable = widget.initialState == 'unavailable';
      _activeVideo = matchingDurableWatch
          ? _videoDataFromProvider(
              mapYouTubePublicCatalogueItemToScreen04Video(
                durableWatch!.selectedVideo,
              ),
            )
          : _tab == SocialV2Tab.videos && widget.initialState == 'video-watch'
          ? _videoForProviderId(_liveYouTubeVideos, widget.initialItem)
          : null;
      if (matchingDurableWatch) {
        _returnToYouTubeSearchAfterVideo =
            durableWatch!.origin == YouTubePublicWatchOrigin.search;
        _videoHomeScrollOffset = durableWatch.homeScrollOffset;
        _videoWatchScrollOffset = durableWatch.watchScrollOffset;
      }
      _resolvedFeedLinkItem = null;
      _unavailableFeedLinkItem = null;
      _openedInitialAuthorItem = null;
      if (!matchingDurableWatch) _resetYouTubeSearch();
      _resetShorts();
      if (_hasSharedFeedTarget) unawaited(_resolveSharedFeedItem());
    }
  }

  Future<void> _loadInitialSocialFeed() async {
    await widget.sharedSession.loadSocialFeed(refresh: true);
    await _resolveSharedFeedItem();
    _maybeOpenInitialSaved();
    _maybeOpenInitialNotifications();
  }

  void _maybeOpenInitialSaved() {
    if (_openedInitialSaved ||
        !mounted ||
        _tab != SocialV2Tab.feed ||
        widget.initialState != 'saved' ||
        !widget.session.isAuthenticated) {
      return;
    }
    _openedInitialSaved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSavedPosts();
    });
  }

  void _maybeOpenInitialNotifications() {
    if (_openedInitialNotifications ||
        !mounted ||
        widget.initialState != 'notifications' ||
        !widget.session.isAuthenticated) {
      return;
    }
    _openedInitialNotifications = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openUniversalNotifications();
    });
  }

  bool get _hasSharedFeedTarget =>
      (_tab == SocialV2Tab.feed && _feedLinkContextActive) ||
      (_tab == SocialV2Tab.create && widget.initialState == 'shared-post');

  Future<void> _resolveSharedFeedItem() async {
    final request = ++_feedLinkRequest;
    final itemId = widget.initialItem?.trim();
    if (!mounted ||
        !_hasSharedFeedTarget ||
        itemId == null ||
        itemId.isEmpty ||
        _resolvedFeedLinkItem == itemId ||
        _feedLinkResolving) {
      return;
    }
    _feedLinkResolving = true;
    try {
      var pagesLoaded = 0;
      while (!widget.sharedSession.socialPublishedItems.any(
            (item) => item.id == itemId,
          ) &&
          widget.sharedSession.socialFeedHasMore &&
          widget.sharedSession.socialFeedError == null &&
          pagesLoaded < 5) {
        final loaded = await widget.sharedSession.loadSocialFeed();
        if (!mounted || request != _feedLinkRequest) return;
        if (!loaded) break;
        pagesLoaded += 1;
      }
      if (!mounted || request != _feedLinkRequest) return;
      final found = widget.sharedSession.socialPublishedItems
          .where((item) => item.id == itemId)
          .firstOrNull;
      if (found != null) {
        setState(() {
          _resolvedFeedLinkItem = itemId;
          _unavailableFeedLinkItem = null;
          if (_tab == SocialV2Tab.create &&
              widget.initialState == 'shared-post') {
            _createDraft.prepareQuotedPost(found);
            _createView = 'post';
          }
        });
        if (widget.initialState == 'author' &&
            _openedInitialAuthorItem != itemId) {
          _openedInitialAuthorItem = itemId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openAuthor(found);
          });
        }
        if (widget.session.isAuthenticated &&
            (widget.initialAction?.trim().isNotEmpty ?? false)) {
          unawaited(_resumeInitialFeedAction(found));
        }
      } else if (widget.sharedSession.socialFeedLoaded &&
          !widget.sharedSession.socialFeedHasMore &&
          widget.sharedSession.socialFeedError == null) {
        setState(() => _unavailableFeedLinkItem = itemId);
      }
    } finally {
      _feedLinkResolving = false;
      if (mounted && request != _feedLinkRequest && _hasSharedFeedTarget) {
        unawaited(_resolveSharedFeedItem());
      }
    }
  }

  Future<void> _resumeInitialFeedAction(SocialPublishedItem item) async {
    final actionValue = widget.initialAction?.trim();
    if (actionValue == null || actionValue.isEmpty) return;
    final token = '${item.id}|$actionValue|${widget.initialChoice ?? ''}';
    if (_handledInitialFeedActionToken == token) return;
    _handledInitialFeedActionToken = token;

    final intent = SocialProtectedActionIntent.tryParse(
      actionValue,
      widget.initialChoice,
    );
    _consumeInitialFeedActionRoute(item.id);
    if (intent == null ||
        (intent.action == SocialProtectedAction.vote &&
            intent.choiceIndex! >= item.choices.length)) {
      if (mounted) {
        showSocialV2Message(
          context,
          'That Feed action could not be restored. Nothing changed.',
        );
      }
      return;
    }

    final sharedSession = widget.sharedSession;
    switch (intent.action) {
      case SocialProtectedAction.like:
        if (!item.liked) {
          await _runResumedFeedInteraction(
            item.id,
            () => sharedSession.toggleSocialLike(item.id),
          );
        }
      case SocialProtectedAction.reply:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final currentItem = sharedSession.socialPublishedItems
              .where((candidate) => candidate.id == item.id)
              .firstOrNull;
          if (currentItem != null) _openComments(currentItem);
        });
      case SocialProtectedAction.repost:
        if (!item.reposted) {
          await _runResumedFeedInteraction(
            item.id,
            () => sharedSession.toggleSocialRepost(item.id),
          );
        }
      case SocialProtectedAction.save:
        if (!item.saved) {
          await _runResumedFeedInteraction(
            item.id,
            () => sharedSession.toggleSocialSave(item.id),
          );
        }
      case SocialProtectedAction.vote:
        if (item.selectedChoiceIndex == null) {
          await _runResumedFeedInteraction(
            item.id,
            () =>
                sharedSession.voteOnSocialContent(item.id, intent.choiceIndex!),
          );
        }
      case SocialProtectedAction.follow:
        await _toggleFeedFollow(item, followed: true);
      case SocialProtectedAction.report:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_startPostReport(item));
        });
    }
  }

  void _consumeInitialFeedActionRoute(String itemId) {
    if (GoRouter.maybeOf(context) == null) return;
    final location = Uri(
      path: '/app/social',
      queryParameters: {'sub': 'feed', 'item': itemId},
    ).toString();
    unawaited(GoRouter.of(context).replace<void>(location));
  }

  Future<void> _runResumedFeedInteraction(
    String itemId,
    Future<bool> Function() action,
  ) async {
    final completed = await action();
    if (!completed && mounted) {
      showSocialV2Message(
        context,
        widget.sharedSession.socialInteractionError(itemId) ??
            'That Feed action could not be completed. Nothing changed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final world = screen04World(_world);
    final choice = _choiceByWorld[_world] ?? world.choices.first.id;
    final selectedChoiceIndex = world.choices.indexWhere(
      (item) => item.id == choice,
    );
    final youtubeOwned =
        _world == 'social' &&
        (_tab == SocialV2Tab.videos || _tab == SocialV2Tab.shorts);
    final shortsOwned = _world == 'social' && _tab == SocialV2Tab.shorts;
    final nestedCreateOpen = _world == 'social' && _tab == SocialV2Tab.create;
    final composerOpen = nestedCreateOpen;
    final contextualChatOpen =
        _contextualChatActive && MoolContextualChatCatalog.supports(_world);
    final area =
        widget.session.currentAreaPrimary ??
        widget.session.manualArea?.split(',').first.trim() ??
        'Khema-Ka-Kuwa';

    final hasInlineBack =
        _activeVideo != null ||
        _youtubeSearchOpen ||
        contextualChatOpen ||
        nestedCreateOpen;
    final focusedRibbonBack =
        _world == 'social' &&
        (_tab == SocialV2Tab.feed ||
            (_tab == SocialV2Tab.create && !nestedCreateOpen)) &&
        !hasInlineBack;

    return MediaQuery(
      data: media,
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: SocialV2Colors.navy,
            secondary: SocialV2Colors.green,
            surfaceTint: Colors.transparent,
          ),
        ),
        child: PopScope<Object?>(
          canPop: !(hasInlineBack || focusedRibbonBack),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleScreen04Back();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            key: const Key('screen04-system-ui-style'),
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: shortsOwned
                  ? Colors.transparent
                  : youtubeOwned
                  ? const Color(0xFF0F0F0F)
                  : SocialV2Colors.navy,
              systemNavigationBarColor: youtubeOwned
                  ? const Color(0xFF0F0F0F)
                  : Colors.white,
              systemNavigationBarIconBrightness: youtubeOwned
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarDividerColor: _world == 'social'
                  ? Colors.transparent
                  : null,
              systemNavigationBarContrastEnforced: _world == 'social'
                  ? false
                  : null,
            ),
            child: Scaffold(
              key: const Key('screen04-universal-v2'),
              extendBody: !youtubeOwned && !composerOpen && !contextualChatOpen,
              backgroundColor: youtubeOwned
                  ? const Color(0xFF0F0F0F)
                  : SocialV2Colors.canvas,
              body: SafeArea(
                top: !shortsOwned,
                bottom: true,
                child: contextualChatOpen
                    ? BuyV2ShopChatView(
                        key: _contextualChatKey,
                        originLabel: world.choices
                            .firstWhere((item) => item.id == choice)
                            .label,
                        presentation: MoolContextualChatCatalog.presentationFor(
                          _world,
                        ),
                        initialFilterId:
                            MoolContextualChatCatalog.initialFilterFor(
                              _world,
                              choice,
                            ),
                        provisioningSource: MoolContextualChatSourceAdapter(
                          familyId: _world,
                          source: widget.contextualChatSource,
                        ),
                        retainedState: _retainedState.contextualChatStates
                            .putIfAbsent(
                              '$_world|$choice',
                              BuyV2ShopChatRetainedState.new,
                            ),
                        onAction: widget.onContextualChatAction,
                        onHandoff:
                            widget.onContextualChatHandoff ??
                            _handoffContextualChatAction,
                        onBack: _closeContextualChat,
                        onOpenProductionChat: _openProductionChat,
                        onOpenThreadContext: _openContextualThreadOrigin,
                      )
                    : Column(
                        children: [
                          if (_world != 'social')
                            Screen04Header(
                              area: area,
                              prompt: world.prompt,
                              immersive: false,
                              showChat: _world != 'social',
                              onHome: () => _selectWorld('social'),
                              onArea: _openServiceableArea,
                              onChat: _openChat,
                              onNotifications: _openUniversalNotifications,
                              onProfile: _openAccount,
                              onSearch: _openSearch,
                              onScan: _openUniversalScan,
                              onVoice: _openUniversalVoice,
                            ),
                          Expanded(
                            child: _world == 'social'
                                ? KeyedSubtree(
                                    key: ValueKey(
                                      '${_tab.name}-${_tab == SocialV2Tab.create ? _createView : 'ribbon'}-${_youtubeSearchOpen ? 'search' : _activeVideo?.id ?? 'home'}',
                                    ),
                                    child: switch (_tab) {
                                      SocialV2Tab.shorts => _buildShorts(),
                                      SocialV2Tab.videos => _buildVideos(),
                                      SocialV2Tab.feed => _buildFeed(),
                                      SocialV2Tab.create => _buildCreate(),
                                      _ => const SizedBox.shrink(),
                                    },
                                  )
                                : Screen04WorldBody(
                                    world: world,
                                    choice: choice,
                                    area: area,
                                    onPrimary: () =>
                                        _openWorldDestination(choice),
                                    onPlacement: (title) =>
                                        _openWorldDestination(
                                          choice,
                                          detail: title,
                                        ),
                                    onContextAction: (action) =>
                                        _runContextAction(action, choice),
                                  ),
                          ),
                        ],
                      ),
              ),
              bottomNavigationBar:
                  composerOpen || _youtubeSearchOpen || contextualChatOpen
                  ? null
                  : _world == 'social'
                  ? _SocialOwnershipDock(
                      selected: _tab,
                      onHome: () => _selectChoice('videos'),
                      onShorts: () => _selectChoice('shorts'),
                      onCreate: _openCreationGateway,
                      onFeed: () => _selectChoice('feed'),
                      onMool: _openMool,
                      onOpenAction: _openMainAction,
                      onOpenChat: _openChat,
                    )
                  : MoolDestinationNavigationV2(
                      activeId: _world,
                      destinationLabel: world.label,
                      familyRootSelected:
                          world.choices.isNotEmpty &&
                          choice == world.choices.first.id,
                      selectedLocalIndex: selectedChoiceIndex < 0
                          ? 0
                          : selectedChoiceIndex,
                      localActionCount: world.choices.length,
                      localNavigation: Screen04ContextTabs(
                        world: world,
                        choice: choice,
                        onChoice: _selectChoice,
                      ),
                      onOpenMool: _openMool,
                      onOpenAction: _openMainAction,
                      onOpenChat: _openChat,
                      onPreviousLocalAction: () {
                        final current = selectedChoiceIndex < 0
                            ? 0
                            : selectedChoiceIndex;
                        final previous =
                            (current - 1 + world.choices.length) %
                            world.choices.length;
                        _selectChoice(world.choices[previous].id);
                      },
                      onNextLocalAction: () {
                        final current = selectedChoiceIndex < 0
                            ? 0
                            : selectedChoiceIndex;
                        final next = (current + 1) % world.choices.length;
                        _selectChoice(world.choices[next].id);
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMool() {
    final onOpenMool = widget.onOpenMool;
    if (onOpenMool != null) {
      onOpenMool();
      return;
    }
    if (GoRouter.maybeOf(context) != null) {
      context.push('/app/mool?from=social');
    }
  }

  void _openMainAction(PersonalMoolActionSpec action) {
    final onOpenMainAction = widget.onOpenMainAction;
    if (onOpenMainAction != null) {
      onOpenMainAction(action);
      return;
    }
    if (GoRouter.maybeOf(context) != null) {
      openMoolConnectedRoute(
        context,
        activeFamilyId: 'social',
        route: action.route,
      );
    }
  }

  void _handleChatIdentityBoundary() {
    final authenticated = widget.session.isAuthenticated;
    if (authenticated == _chatAuthenticated) return;
    _chatAuthenticated = authenticated;
    _retainedState.contextualChatStates.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _contextualChatActive = false;
      if (authenticated) _createReviewPreviewActive = false;
    });
  }

  void _handleScreen04Back() {
    if (_contextualChatActive) {
      if (_contextualChatKey.currentState?.handleBack() ?? false) return;
      _closeContextualChat();
      return;
    }
    if (_youtubeSearchOpen) {
      _closeYouTubeSearch();
      return;
    }
    if (_world == 'social' &&
        _tab == SocialV2Tab.create &&
        _createView != 'home') {
      unawaited(_backFromCreateEditor());
      return;
    }
    if (_activeVideo != null) {
      if (_returnToYouTubeSearchAfterVideo) {
        _discardDurableYouTubeWatch();
        setState(() {
          _activeVideo = _youtubeSearchOriginVideo;
          _returnToYouTubeSearchAfterVideo = false;
          _youtubeSearchOpen = true;
        });
        HapticFeedback.selectionClick();
        return;
      }
      final restoreOffset = _videoHomeScrollOffset;
      _discardDurableYouTubeWatch();
      setState(() {
        _activeVideo = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_videoHomeController.hasClients) return;
        final position = _videoHomeController.position;
        _videoHomeController.jumpTo(
          restoreOffset.clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      });
      HapticFeedback.selectionClick();
      return;
    }
    if (_world == 'social' &&
        (_tab == SocialV2Tab.feed ||
            (_tab == SocialV2Tab.create && _createView == 'home'))) {
      _openMool();
    }
  }

  void _selectWorld(String worldId) {
    if (!screen04Worlds.any((world) => world.id == worldId)) return;
    final destination = switch (worldId) {
      'buy' => '/app/buy',
      'eat' => '/app/eat',
      'ride' => '/app/ride',
      'book' => '/app/book',
      'work' => '/app/work',
      _ => null,
    };
    if (destination != null && GoRouter.maybeOf(context) != null) {
      _discardDurableYouTubeWatch();
      _resetShorts();
      HapticFeedback.selectionClick();
      context.go(destination);
      return;
    }
    _discardDurableYouTubeWatch();
    _resetShorts();
    setState(() {
      _contextualChatActive = false;
      _world = worldId;
      _activeVideo = null;
      _resetYouTubeSearch();
      if (worldId == 'social') {
        _tab = _tabFor(_choiceByWorld['social']);
      }
    });
  }

  void _selectChoice(String choiceId) {
    final world = screen04World(_world);
    if (!world.choices.any((choice) => choice.id == choiceId)) return;
    if (_world == 'social' &&
        choiceId == 'create' &&
        !widget.session.isAuthenticated) {
      _resetShorts();
      if (widget.enableCreateReviewPreview) {
        _openCreateReviewComposer();
      } else {
        _beginCreateSignIn();
      }
      return;
    }
    _discardDurableYouTubeWatch();
    final openingShorts = _world == 'social' && choiceId == 'shorts';
    if (!openingShorts) _resetShorts();
    setState(() {
      _contextualChatActive = false;
      _choiceByWorld[_world] = choiceId;
      _activeVideo = null;
      _resetYouTubeSearch();
      if (_world == 'social') {
        _tab = _tabFor(choiceId);
        if (_tab != SocialV2Tab.create) {
          _createReviewPreviewActive = false;
        } else {
          _createView = _createDraft.hasMeaningfulContent
              ? _createDraftResumeView()
              : 'post';
        }
        if (_tab == SocialV2Tab.feed) {
          _feedLinkRequest += 1;
          _feedLinkContextActive = false;
          _resolvedFeedLinkItem = null;
          _unavailableFeedLinkItem = null;
          _openedInitialAuthorItem = null;
        }
        if (_tab == SocialV2Tab.videos) _videoQuery = '';
        if (_tab != SocialV2Tab.create) _createView = 'home';
        if (_tab == SocialV2Tab.shorts) {
          _resetShorts(clearDurable: false);
        }
      }
    });
    if (openingShorts) _persistActiveYouTubeShort(0);
  }

  void _openCreationGateway() {
    if (!widget.session.isAuthenticated) {
      if (widget.enableCreateReviewPreview) {
        _openCreateReviewComposer();
      } else {
        _beginCreateSignIn();
      }
      return;
    }
    _discardDurableYouTubeWatch();
    _resetShorts();
    HapticFeedback.selectionClick();
    setState(() {
      _choiceByWorld['social'] = 'create';
      _activeVideo = null;
      _tab = SocialV2Tab.create;
      _createView = _createDraft.hasMeaningfulContent
          ? _createDraftResumeView()
          : 'post';
      _createReviewPreviewActive = false;
    });
  }

  void _beginCreateSignIn() {
    widget.session.beginSignIn(
      returnLocation: '/app/social?sub=create',
      cancelLocation: '/app/social?sub=${_tab.name}',
      purpose: JourneyAuthenticationPurpose.socialCreate,
    );
  }

  void _openCreateReviewComposer() {
    _discardDurableYouTubeWatch();
    _resetShorts();
    HapticFeedback.selectionClick();
    setState(() {
      _choiceByWorld['social'] = 'create';
      _activeVideo = null;
      _tab = SocialV2Tab.create;
      _createView = _createDraft.hasMeaningfulContent
          ? _createDraftResumeView()
          : 'post';
      _createReviewPreviewActive = true;
    });
  }

  Future<void> _openYouTubeChannelStatus() async {
    HapticFeedback.selectionClick();
    if (!widget.session.isAuthenticated) {
      const cancelLocation = '/app/social?sub=videos';
      final continueToSignIn = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('youtube-connect-auth-explanation'),
          title: const Text('Connect your YouTube channel'),
          content: const Text(
            'First, sign in to your MoolSocial account. This is separate from YouTube. After MoolSocial sign-in, you’ll choose the existing Google account that owns your YouTube channel and review read-only access.',
          ),
          actions: [
            TextButton(
              key: const Key('youtube-connect-auth-cancel'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              key: const Key('youtube-connect-auth-continue'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue to MoolSocial sign-in'),
            ),
          ],
        ),
      );
      if (!mounted || continueToSignIn != true) return;
      widget.session.beginSignIn(
        returnLocation: '/app/creator/youtube-connect',
        cancelLocation: cancelLocation,
        purpose: JourneyAuthenticationPurpose.youtubeChannelConnection,
      );
      return;
    }
    context.push<void>('/app/creator/youtube-connect');
  }

  void _openShortFromHome(int index) {
    final shorts = _eligibleLiveYouTubeShorts();
    if (index < 0 || index >= shorts.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _choiceByWorld['social'] = 'shorts';
      _tab = SocialV2Tab.shorts;
      _activeShortPage = index;
    });
    _persistActiveYouTubeShort(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shortController.hasClients) return;
      _shortController.jumpToPage(index);
    });
  }

  void _captureYouTubeWatchScrollOffset() {
    if (!_videoWatchController.hasClients) return;
    _videoWatchScrollOffset = _videoWatchController.offset;
    _youtubeWatchStateCache.updateWatchScrollOffset(_videoWatchScrollOffset);
  }

  Future<void> _hydrateCreateDraft(
    SocialCreateDraftSnapshot snapshot,
    int hydration,
  ) async {
    final store = _createDraftMediaStore;
    final media = <SocialPickedMedia>[];
    final poll = <SocialPickedMedia?>[];
    var mediaLoss = false;
    if (store == null) {
      mediaLoss =
          snapshot.media.isNotEmpty ||
          snapshot.imagePollMedia.any((item) => item != null);
      poll.addAll(List<SocialPickedMedia?>.filled(4, null));
    } else {
      for (final reference in snapshot.media) {
        final resolved = await store.resolve(reference);
        if (resolved == null) {
          mediaLoss = true;
        } else {
          media.add(resolved);
          _draftMediaRefs[resolved.path] = reference;
        }
      }
      for (final reference in snapshot.imagePollMedia) {
        if (reference == null) {
          poll.add(null);
          continue;
        }
        final resolved = await store.resolve(reference);
        if (resolved == null) {
          mediaLoss = true;
          poll.add(null);
        } else {
          poll.add(resolved);
          _draftMediaRefs[resolved.path] = reference;
        }
      }
    }
    while (poll.length < 4) {
      poll.add(null);
    }
    if (!mounted || hydration != _createDraftHydrationGeneration) return;
    _createDraft.applyPersistenceSnapshot(
      snapshot,
      media: media,
      imagePollMedia: poll,
    );
    _createDraft.setChangeListener(_scheduleCreateDraftPersistence);
    setState(() {
      _createDraftHydrating = false;
      _createDraftMediaLoss = mediaLoss;
    });
    if (mediaLoss) _scheduleCreateDraftPersistence();
  }

  void _scheduleCreateDraftPersistence() {
    final request = ++_createDraftPersistenceRequest;
    unawaited(_persistCreateDraft(request));
  }

  Future<bool> _flushCreateDraft() async {
    final request = ++_createDraftPersistenceRequest;
    if (!await _persistCreateDraft(request)) return false;
    return _createDraftStateCache.settleDurableWritesConfirmed();
  }

  void _closeCreate() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _createView = 'home';
      _choiceByWorld['social'] = 'feed';
      _tab = SocialV2Tab.feed;
      _createReviewPreviewActive = false;
    });
    if (widget.initialSubAction == 'create' && widget.initialState != null) {
      final router = GoRouter.maybeOf(context);
      if (router != null) context.replace('/app/social?sub=feed');
    }
  }

  Future<void> _backFromCreateEditor() async {
    if (_createBackBusy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) setState(() => _createBackBusy = true);
    final persisted = await _flushCreateDraft().catchError((Object _) => false);
    if (mounted) {
      if (persisted) {
        _createBackBusy = false;
        _closeCreate();
      } else {
        setState(() => _createBackBusy = false);
        showSocialV2Message(context, 'Draft save failed. Please try again.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_flushCreateDraft());
    }
  }

  Future<SocialCreateDraftMediaReference?> _stageDraftMedia(
    SocialPickedMedia media,
  ) async {
    final existing = _draftMediaRefs[media.path];
    if (existing != null) return existing;
    if (media.isAsset) {
      try {
        final reference = SocialCreateDraftMediaStore.referenceForBundledAsset(
          media,
        );
        _draftMediaRefs[media.path] = reference;
        return reference;
      } on Object {
        return null;
      }
    }
    final store = _createDraftMediaStore;
    if (store == null) return null;
    late final Future<SocialCreateDraftMediaReference?> operation;
    operation = (() async {
      try {
        return await store.stage(media);
      } on Object {
        return null;
      }
    })();
    _draftStagingOperations.add(operation);
    try {
      final staged = await operation;
      if (staged == null) return null;
      _draftMediaRefs[media.path] = staged;
      return staged;
    } finally {
      _draftStagingOperations.remove(operation);
    }
  }

  Future<bool> _persistCreateDraft(int request) async {
    final media = <SocialCreateDraftMediaReference>[];
    for (final item in _createDraft.media) {
      final staged = await _stageDraftMedia(item);
      if (staged == null) return false;
      media.add(staged);
    }
    final poll = <SocialCreateDraftMediaReference?>[];
    for (final item in _createDraft.imagePollMedia) {
      if (item == null) {
        poll.add(null);
      } else {
        final staged = await _stageDraftMedia(item);
        if (staged == null) return false;
        poll.add(staged);
      }
    }
    if (request != _createDraftPersistenceRequest) return false;
    final prior = _createDraftStateCache.snapshot;
    final snapshot = _createDraft.toPersistenceSnapshot(
      cache: _createDraftStateCache,
      media: media,
      imagePollMedia: poll,
    );
    _createDraftStateCache.replace(snapshot);
    final store = _createDraftMediaStore;
    if (store != null && prior != null) {
      final retainedIds = <String>{
        ...media.map((item) => item.id),
        ...poll.whereType<SocialCreateDraftMediaReference>().map(
          (item) => item.id,
        ),
      };
      final removed = <SocialCreateDraftMediaReference>[
        ...prior.media,
        ...prior.imagePollMedia.whereType<SocialCreateDraftMediaReference>(),
      ].where((item) => !retainedIds.contains(item.id));
      await store.clear(removed);
    }
    return true;
  }

  Future<void> _clearCreateDraftMedia() async {
    _createDraftPersistenceRequest += 1;
    await Future.wait<SocialCreateDraftMediaReference?>(
      _draftStagingOperations.toList(growable: false),
    );
    final snapshot = _createDraftStateCache.snapshot;
    final store = _createDraftMediaStore;
    final references = <SocialCreateDraftMediaReference>{
      ..._draftMediaRefs.values,
      if (snapshot != null) ...snapshot.media,
      if (snapshot != null)
        ...snapshot.imagePollMedia.whereType<SocialCreateDraftMediaReference>(),
    };
    final cleared = await _createDraftStateCache.clearConfirmed();
    if (!cleared) throw StateError('Draft cleanup failed.');
    if (store != null) {
      try {
        await store.clear(references);
      } on Object {
        if (snapshot != null) {
          _createDraftStateCache.replace(snapshot, debounce: false);
          await _createDraftStateCache.settleDurableWritesConfirmed();
        }
        rethrow;
      }
    }
    _draftMediaRefs.clear();
  }

  YouTubePublicCatalogueItem? _publicItemForVideo(_VideoData video) {
    final providerVideoId = video.providerVideoId;
    if (providerVideoId == null || providerVideoId.isEmpty) return null;
    final searchResults = _youtubeSearchStateCache.snapshot?.results;
    if (searchResults != null) {
      for (final item in searchResults) {
        if (item.videoId == providerVideoId) return item;
      }
    }
    final catalogue = <Screen04YouTubePublicVideo>[
      ...?_youtubeCatalogueSnapshots.readVideos(),
      ...?_youtubeCatalogueSnapshots.readShorts(),
    ];
    for (final item in catalogue) {
      if (item.videoId == providerVideoId) {
        return mapScreen04VideoToYouTubePublicCatalogueItem(item);
      }
    }
    final current = _youtubeWatchStateCache.snapshot?.selectedVideo;
    return current?.videoId == providerVideoId ? current : null;
  }

  void _persistYouTubeWatch(_VideoData video, YouTubePublicWatchOrigin origin) {
    final item = _publicItemForVideo(video);
    if (item == null) {
      unawaited(_youtubeWatchStateCache.clear());
      return;
    }
    _videoWatchScrollOffset = 0;
    _youtubeWatchStateCache.replace(
      selectedVideo: item,
      origin: origin,
      searchOriginVideo:
          origin == YouTubePublicWatchOrigin.search &&
              _youtubeSearchOriginVideo != null
          ? _publicItemForVideo(_youtubeSearchOriginVideo!)
          : null,
      homeScrollOffset: _videoHomeScrollOffset,
    );
  }

  void _discardDurableYouTubeWatch() {
    _videoWatchScrollOffset = 0;
    unawaited(_youtubeWatchStateCache.clear());
  }

  void _captureYouTubeSearchScrollOffset() {
    if (!_youtubeSearchResultsController.hasClients) return;
    _youtubeSearchScrollOffset = _youtubeSearchResultsController.offset;
    _youtubeSearchStateCache.updateScrollOffset(_youtubeSearchScrollOffset);
  }

  void _discardDurableYouTubeSearch() {
    _preserveDurableSearchForNestedWatch = false;
    _restoredYouTubeSearch = false;
    _youtubeSearchScrollOffset = 0;
    unawaited(_youtubeSearchStateCache.clear());
  }

  void _resetYouTubeSearch() {
    _discardDurableYouTubeSearch();
    _youtubeSearchRequest += 1;
    _youtubeSearchOpen = false;
    _youtubeSearchLoading = false;
    _returnToYouTubeSearchAfterVideo = false;
    _youtubeSearchError = null;
    _youtubeSubmittedQuery = '';
    _youtubeSearchResults = const [];
    _youtubeSearchOriginVideo = null;
    _youtubeSearchController.clear();
    _youtubeSearchFocusNode.unfocus();
  }

  void _openYouTubeSearch() {
    _preserveDurableSearchForNestedWatch =
        _activeVideo != null &&
        _youtubeWatchStateCache.snapshot?.origin ==
            YouTubePublicWatchOrigin.search &&
        _youtubeSearchStateCache.snapshot != null;
    if (!_preserveDurableSearchForNestedWatch) {
      _discardDurableYouTubeSearch();
    }
    if (_videoHomeController.hasClients && _activeVideo == null) {
      _videoHomeScrollOffset = _videoHomeController.offset;
    }
    setState(() {
      _youtubeSearchRequest += 1;
      _youtubeSearchOriginVideo = _activeVideo;
      _youtubeSearchOpen = true;
      _youtubeSearchLoading = false;
      _returnToYouTubeSearchAfterVideo = false;
      _youtubeSearchError = null;
      _youtubeSubmittedQuery = '';
      _youtubeSearchResults = const [];
      _youtubeSearchController.value = TextEditingValue(
        text: _youtubeSubmittedQuery,
        selection: TextSelection.collapsed(
          offset: _youtubeSubmittedQuery.length,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _youtubeSearchFocusNode.requestFocus();
    });
    HapticFeedback.selectionClick();
  }

  void _closeYouTubeSearch() {
    final preserveSearch = _preserveDurableSearchForNestedWatch;
    final preservedSearch = preserveSearch
        ? _youtubeSearchStateCache.snapshot
        : null;
    if (!preserveSearch) _discardDurableYouTubeSearch();
    final restoredWatch = _youtubeSearchOriginVideo;
    final priorWatch = _youtubeWatchStateCache.snapshot?.searchOriginVideo;
    setState(() {
      _youtubeSearchRequest += 1;
      _youtubeSearchOpen = false;
      _youtubeSearchLoading = false;
      _returnToYouTubeSearchAfterVideo = preserveSearch;
      _youtubeSearchError = null;
      _youtubeSubmittedQuery = preservedSearch?.submittedQuery ?? '';
      _youtubeSearchResults =
          preservedSearch?.results
              .map(mapYouTubePublicCatalogueItemToScreen04Video)
              .map(_videoDataFromProvider)
              .toList(growable: false) ??
          const [];
      _youtubeSearchScrollOffset = preservedSearch?.resultsScrollOffset ?? 0;
      _activeVideo = _youtubeSearchOriginVideo;
      _youtubeSearchOriginVideo = priorWatch == null
          ? null
          : _videoDataFromProvider(
              mapYouTubePublicCatalogueItemToScreen04Video(priorWatch),
            );
      _youtubeSearchController.value = TextEditingValue(
        text: _youtubeSubmittedQuery,
        selection: TextSelection.collapsed(
          offset: _youtubeSubmittedQuery.length,
        ),
      );
    });
    if (restoredWatch != null && !preserveSearch) {
      _persistYouTubeWatch(restoredWatch, YouTubePublicWatchOrigin.home);
    }
    _preserveDurableSearchForNestedWatch = false;
    _youtubeSearchFocusNode.unfocus();
    HapticFeedback.selectionClick();
  }

  void _clearYouTubeSearch() {
    _discardDurableYouTubeSearch();
    setState(() {
      _youtubeSearchRequest += 1;
      _youtubeSearchLoading = false;
      _youtubeSearchError = null;
      _youtubeSubmittedQuery = '';
      _youtubeSearchResults = const [];
      _youtubeSearchController.clear();
    });
    _youtubeSearchFocusNode.requestFocus();
  }

  Future<void> _submitYouTubeSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      _clearYouTubeSearch();
      return;
    }
    _discardDurableYouTubeSearch();
    final request = ++_youtubeSearchRequest;
    setState(() {
      _youtubeSearchLoading = true;
      _youtubeSearchError = null;
      _youtubeSubmittedQuery = query;
      _youtubeSearchResults = const [];
      _youtubeSearchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    });
    _youtubeSearchFocusNode.unfocus();
    try {
      final loader =
          widget.youtubeSearchLoader ?? loadScreen04YouTubePublicSearch;
      final results = await loader(query);
      if (!mounted || request != _youtubeSearchRequest) return;
      final renderedResults = results
          .map(_videoDataFromProvider)
          .toList(growable: false);
      setState(() {
        _youtubeSearchLoading = false;
        _youtubeSearchResults = renderedResults;
        _youtubeSearchScrollOffset = 0;
      });
      _youtubeSearchStateCache.replace(
        submittedQuery: query,
        results: results
            .map(mapScreen04VideoToYouTubePublicCatalogueItem)
            .toList(growable: false),
      );
    } on Object {
      if (!mounted || request != _youtubeSearchRequest) return;
      setState(() {
        _youtubeSearchLoading = false;
        _youtubeSearchError =
            'Search is unavailable right now. Please try again.';
        _youtubeSearchResults = const [];
      });
    }
  }

  void _openVideoFromSearch(_VideoData video) {
    setState(() {
      _activeVideo = video;
      _youtubeSearchOpen = false;
      _returnToYouTubeSearchAfterVideo = true;
      if (_videoWatchController.hasClients) {
        _videoWatchController.jumpTo(0);
      }
    });
    _persistYouTubeWatch(video, YouTubePublicWatchOrigin.search);
    _youtubeSearchFocusNode.unfocus();
    HapticFeedback.selectionClick();
  }

  void _openVideoFromDiscovery(_VideoData video) {
    if (_videoHomeController.hasClients) {
      _videoHomeScrollOffset = _videoHomeController.offset;
    }
    setState(() {
      _activeVideo = video;
      if (_videoWatchController.hasClients) {
        _videoWatchController.jumpTo(0);
      }
    });
    _persistYouTubeWatch(video, YouTubePublicWatchOrigin.home);
    HapticFeedback.selectionClick();
  }

  Future<void> _loadLiveYouTubeVideos() async {
    if (!_youtubePublicAccessAvailable) return;
    final request = ++_youtubeCatalogueRequest;
    setState(() {
      _liveYouTubeLoading = !_hasYouTubeVideosSnapshot;
      _liveYouTubeError = null;
      _liveYouTubeShortsLoading = !_hasYouTubeShortsSnapshot;
      _liveYouTubeShortsError = null;
    });
    List<Screen04YouTubePublicVideo> videos = const [];
    List<Screen04YouTubePublicVideo> shorts = const [];
    Object? videosFailure;
    Object? shortsFailure;
    await Future.wait([
      () async {
        try {
          final loader =
              widget.youtubeVideosLoader ?? loadScreen04YouTubePublicVideos;
          videos = await loader();
        } on Object catch (error) {
          videosFailure = error;
        }
      }(),
      () async {
        try {
          final loader =
              widget.youtubeShortsLoader ?? loadScreen04YouTubePublicShorts;
          shorts = await loader();
        } on Object catch (error) {
          shortsFailure = error;
        }
      }(),
    ]);
    if (!mounted || request != _youtubeCatalogueRequest) return;
    final mappedVideos = videos
        .map(_videoDataFromProvider)
        .toList(growable: false);
    final eligibleShortRecords = shorts
        .where(_isEligibleYouTubeShortRecord)
        .toList(growable: false);
    final mappedShorts = eligibleShortRecords
        .map(_shortDataFromProvider)
        .toList(growable: false);
    final priorSelectedShortId =
        _youtubeShortStateCache.snapshot?.selectedVideoId ??
        (_tab == SocialV2Tab.shorts &&
                _activeShortPage >= 0 &&
                _activeShortPage < _liveYouTubeShorts.length
            ? _liveYouTubeShorts[_activeShortPage].providerVideoId
            : null);
    final mappedShortIds = mappedShorts
        .map((short) => short.providerVideoId)
        .whereType<String>()
        .toList(growable: false);
    final reconciledShortPage =
        shortsFailure == null && priorSelectedShortId != null
        ? mappedShorts.indexWhere(
            (short) => short.providerVideoId == priorSelectedShortId,
          )
        : -1;
    if (videosFailure == null) {
      _youtubeCatalogueSnapshots.replaceVideos(videos);
    }
    if (shortsFailure == null) {
      _youtubeCatalogueSnapshots.replaceShorts(eligibleShortRecords);
    }
    int? restoredShortPage;
    setState(() {
      if (videosFailure == null) {
        _liveYouTubeVideos = mappedVideos;
        _hasYouTubeVideosSnapshot = true;
      }
      if (shortsFailure == null) {
        _liveYouTubeShorts = mappedShorts;
        _hasYouTubeShortsSnapshot = true;
        final nextShortPage = reconciledShortPage >= 0
            ? reconciledShortPage
            : 0;
        if (_activeShortPage != nextShortPage) {
          _activeShortPage = nextShortPage;
          restoredShortPage = nextShortPage;
        }
      }
      _liveYouTubeLoading = false;
      _liveYouTubeShortsLoading = false;
      _liveYouTubeError = videosFailure == null
          ? null
          : 'Videos are unavailable right now. Please try again.';
      _liveYouTubeShortsError = shortsFailure == null
          ? null
          : 'YouTube Shorts are unavailable right now. Please try again.';
      if (_activeVideo == null &&
          _tab == SocialV2Tab.videos &&
          widget.initialState == 'video-watch') {
        _activeVideo = _videoForProviderId(
          _liveYouTubeVideos,
          widget.initialItem,
        );
      }
      _visibleVideoCount = 20;
    });
    if (shortsFailure == null) {
      if (reconciledShortPage >= 0 &&
          mappedShortIds.length == mappedShorts.length) {
        _youtubeShortStateCache.replace(
          selectedVideoId: mappedShortIds[reconciledShortPage],
          activeIndex: reconciledShortPage,
          catalogueVideoIds: mappedShortIds,
        );
      } else if (priorSelectedShortId != null) {
        unawaited(_youtubeShortStateCache.clear());
      }
    }
    if (restoredShortPage case final page?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_shortController.hasClients) return;
        _shortController.jumpToPage(page);
      });
    }
  }

  void _openWorldDestination(String choice, {String? detail}) {
    final route = switch (choice) {
      'shop' => '/app/buy?sub=shop',
      'wholesale' => '/app/buy?sub=wholesale',
      'medicine' => '/app/buy?sub=medicine',
      'orders' => '/app/buy?sub=orders',
      'order-food' => '/app/eat/home',
      'book-table' => '/app/eat/table',
      'bike' || 'auto' || 'cab' => '/app/ride/book?type=$choice',
      'bus' => '/app/book/bus',
      'doctor' => '/app/book/doctor',
      'salon' => '/app/book/salon',
      'earn-today' => '/app/work/earn',
      'workspace' => '/app/work/my-work',
      _ => '/app/$_world',
    };
    final separator = route.contains('?') ? '&' : '?';
    final intent = detail == null
        ? null
        : 'intent=${Uri.encodeQueryComponent(detail)}';
    final target = detail == null ? route : '$route$separator$intent';
    context.push(target);
  }

  void _runContextAction(String action, String choice) {
    switch (action) {
      case 'Chat':
        _openChat();
        return;
      case 'Share':
      case 'Compare':
      case 'Family':
        showSocialV2Message(context, 'Open an item before sharing it.');
        return;
      case 'Scan':
        context.push('/app/pay/scan');
        return;
      case 'Save':
        showSocialV2Message(context, 'Saved');
        return;
      default:
        _openWorldDestination(choice, detail: action);
        return;
    }
  }

  void _openChat() {
    if (_world != 'social' && MoolContextualChatCatalog.supports(_world)) {
      FocusScope.of(context).unfocus();
      HapticFeedback.selectionClick();
      setState(() => _contextualChatActive = true);
      return;
    }
    _openProductionChat();
  }

  void _closeContextualChat() {
    if (!_contextualChatActive) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() => _contextualChatActive = false);
  }

  void _openContextualThreadOrigin(BuyV2ShopChatThread thread) {
    if (!_contextualChatActive) return;
    final world = screen04World(_world);
    final threadChoice = thread.resolvedFilterId;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      if (world.choices.any((choice) => choice.id == threadChoice)) {
        _choiceByWorld[_world] = threadChoice;
      }
      _contextualChatActive = false;
    });
  }

  void _openProductionChat() {
    context.push(
      Uri(
        path: '/app/chat',
        queryParameters: {'return': _productionChatReturnRoute()},
      ).toString(),
    );
  }

  void _openFeedChatSection(String section) {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    context.push(
      Uri(
        path: '/app/chat/inbox',
        queryParameters: {'section': section, 'return': '/app/social?sub=feed'},
      ).toString(),
    );
  }

  void _handoffContextualChatAction(
    BuyV2ShopChatThread thread,
    BuyV2ShopChatAction action,
  ) {
    final draft = action.kind == BuyV2ShopChatActionKind.sendText
        ? action.text?.trim()
        : null;
    context.push(
      Uri(
        path: '/app/chat/inbox',
        queryParameters: {
          'type': thread.productionChatType,
          if (draft != null && draft.isNotEmpty) 'draft': draft,
          'return': _productionChatReturnRoute(
            threadChoice: thread.resolvedFilterId,
          ),
        },
      ).toString(),
    );
  }

  String _productionChatReturnRoute({String? threadChoice}) {
    final world = screen04World(_world);
    final choice =
        threadChoice != null &&
            world.choices.any((candidate) => candidate.id == threadChoice)
        ? threadChoice
        : _choiceByWorld[_world] ?? world.choices.first.id;
    final returnPath = switch (world.id) {
      'eat' => '/app/eat',
      'ride' => '/app/ride',
      'book' => '/app/book',
      'work' => '/app/work',
      _ => '/app/social',
    };
    final returnQuery = <String, String>{
      'sub': choice,
      if (world.id == 'social' && _activeVideo != null) ...{
        'state': 'video-watch',
        'item': _activeVideo!.id,
      },
    };
    return Uri(path: returnPath, queryParameters: returnQuery).toString();
  }

  void _openUniversalNotifications() {
    final previewOnly =
        widget.enableCreateReviewPreview && !widget.session.isAuthenticated;
    if (!widget.session.isAuthenticated && !previewOnly) {
      widget.session.beginSignIn(
        returnLocation: '/app/social?sub=${_tab.name}&state=notifications',
        cancelLocation: '/app/social?sub=${_tab.name}',
      );
      return;
    }
    showSocialV2Sheet(
      context,
      title: 'Notifications',
      subtitle: 'Your recent activity',
      children: [
        _SocialNotificationsPanelV2(
          session: widget.sharedSession,
          previewOnly: previewOnly,
          onOpen: (item) => unawaited(
            _openSocialNotification(item, previewOnly: previewOnly),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _openNotificationSettings,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Notification settings'),
        ),
      ],
    );
  }

  Future<void> _openSocialNotification(
    SocialNotificationItem notification, {
    required bool previewOnly,
  }) async {
    if (!previewOnly && !notification.read) {
      await widget.sharedSession.markSocialNotificationRead(notification.id);
      if (!mounted) return;
    }
    Navigator.of(context).pop();
    if (notification.kind == SocialNotificationKind.messageRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFeedChatSection('discover');
      });
      return;
    }
    final post = notification.postId == null
        ? null
        : widget.sharedSession.socialPublishedItems
              .where((item) => item.id == notification.postId)
              .firstOrNull;
    final authorPost = notification.authorId == null
        ? null
        : widget.sharedSession.socialPublishedItems
              .where((item) => item.authorId == notification.authorId)
              .firstOrNull;
    setState(() {
      _choiceByWorld['social'] = 'feed';
      _tab = SocialV2Tab.feed;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (post != null) {
        _openPostDetail(post);
      } else if (authorPost != null) {
        _openAuthor(authorPost);
      } else {
        showSocialV2Message(
          context,
          'This notification’s content is no longer available.',
        );
      }
      final error = widget.sharedSession.socialNotificationsError;
      if (!previewOnly && error != null) {
        showSocialV2Message(context, error);
      }
    });
  }

  void _openAccount() {
    final authenticated = widget.session.isAuthenticated;
    final socialContext = _world == 'social';
    showGlobalProfilePanelV2(
      context,
      accountAuthenticated: authenticated,
      surfaceTone: socialContext
          ? GlobalProfileSurfaceTone.socialDark
          : GlobalProfileSurfaceTone.light,
      contextAction: socialContext
          ? GlobalProfileContextAction(
              id: 'youtube',
              title: authenticated
                  ? 'Your YouTube channel'
                  : 'Connect your YouTube channel',
              detail: authenticated
                  ? 'Review connection, permissions and eligible channel videos.'
                  : 'Sign in to MoolSocial, then choose the Google account that owns your channel.',
              actionLabel: authenticated
                  ? 'Open channel status'
                  : 'Connect channel',
              icon: Icons.ondemand_video_outlined,
              onPressed: () {
                unawaited(_openYouTubeChannelStatus());
              },
            )
          : null,
      onOpenRoute: (route) => context.push(
        socialContext && route == '/app/account/identity'
            ? '$route?surface=social'
            : route,
      ),
    );
  }

  void _openServiceableArea() {
    final controller = TextEditingController(
      text: widget.session.currentAreaLabel ?? widget.session.manualArea ?? '',
    );
    showSocialV2Sheet(
      context,
      title: 'Serviceable area',
      subtitle: 'Choose where you want nearby products, services and work',
      children: [
        TextField(
          key: const Key('screen04-area-input'),
          controller: controller,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Area, city or PIN code',
          ),
        ),
        FilledButton.icon(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final resolved = await widget.session.resolveCurrentArea();
            if (!mounted) return;
            navigator.pop();
            if (!resolved) {
              showSocialV2Message(
                context,
                widget.session.errorMessage ??
                    'Location is unavailable. Enter your serviceable area.',
              );
            }
          },
          icon: const Icon(Icons.my_location_rounded),
          label: const Text('Use current location'),
        ),
        OutlinedButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isEmpty) {
              showSocialV2Message(context, 'Enter an area, city or PIN code');
              return;
            }
            widget.session.selectArea(AreaChoice.manual, label: value);
            Navigator.of(context).pop();
            setState(() {});
          },
          child: const Text('Save serviceable area'),
        ),
      ],
    );
  }

  void _openUniversalScan() {
    showSocialV2Sheet(
      context,
      title: 'Scan a code',
      subtitle: 'Scan a product, payment or service code',
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/app/pay/scan');
          },
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Open camera'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/app/pay/scan?method=manual');
          },
          icon: const Icon(Icons.keyboard_rounded),
          label: const Text('Enter code'),
        ),
      ],
    );
  }

  void _openUniversalVoice() {
    final controller = TextEditingController();
    showSocialV2Sheet(
      context,
      title: 'Voice search',
      subtitle: 'Say what you want to find or do',
      children: [
        const Center(
          child: CircleAvatar(
            radius: 34,
            backgroundColor: SocialV2Colors.navy,
            child: Icon(Icons.mic_rounded, color: Colors.white, size: 30),
          ),
        ),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(labelText: 'Type instead'),
          onSubmitted: (value) {
            if (value.trim().isEmpty) return;
            Navigator.of(context).pop();
            _openSearchWith(value.trim());
          },
        ),
      ],
    );
  }

  void _openSearchWith(String value) {
    _showSearchResults(value);
  }

  void _openNotificationSettings() {
    final previewOnly =
        widget.enableCreateReviewPreview && !widget.session.isAuthenticated;
    final returnRoute = _productionChatReturnRoute();
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context
            .push(
              Uri(
                path: '/app/chat/notifications',
                queryParameters: {
                  'return': returnRoute,
                  if (previewOnly) 'preview': 'true',
                },
              ).toString(),
            )
            .then((_) {
              if (mounted) _openUniversalNotifications();
            }),
      );
    });
  }

  void _openSearch() {
    final controller = TextEditingController();
    final world = screen04World(_world);
    showSocialV2Sheet(
      context,
      title: 'Search ${world.label}',
      subtitle: world.prompt,
      children: [
        TextField(
          key: const Key('social-v2-search-input'),
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Enter a person, topic or place',
          ),
          onSubmitted: (value) {
            final query = value.trim();
            if (query.isEmpty) {
              showSocialV2Message(context, 'Enter what you want to find');
              return;
            }
            Navigator.of(context).pop();
            _showSearchResults(query);
          },
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Jodhpur', 'Local creators', 'Small business']
              .map(
                (label) => ActionChip(
                  label: Text(label),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSearchResults(label);
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  void _showSearchResults(String query) {
    showSocialV2Sheet(
      context,
      title: 'Results for “$query”',
      subtitle: 'Choose where you want to continue',
      children: [
        for (final choice in screen04World(_world).choices.take(3))
          SocialV2ListTile(
            icon: Icons.arrow_forward_rounded,
            title: choice.label,
            detail: screen04World(_world).label,
            onTap: () {
              Navigator.of(context).pop();
              _selectChoice(choice.id);
            },
          ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Change search'),
        ),
      ],
    );
  }

  Widget _buildShorts() {
    if (_contentUnavailable) {
      return _buildYouTubeShortsStatus(
        _YouTubeShortsStatusView(
          key: const Key('screen04-youtube-shorts-state-unavailable'),
          icon: Icons.smart_display_outlined,
          title: 'YouTube Shorts are unavailable',
          detail: 'This Short isn’t available here right now.',
          actionLabel: _youtubePublicAccessAvailable
              ? 'Try again'
              : 'Open Feed',
          onAction: _youtubePublicAccessAvailable
              ? _loadLiveYouTubeVideos
              : () => _selectChoice('feed'),
        ),
      );
    }
    if (!_youtubePublicAccessAvailable) {
      return _buildYouTubeShortsStatus(
        _YouTubeShortsStatusView(
          key: const Key('screen04-youtube-shorts-state-provider-access'),
          icon: Icons.smart_display_outlined,
          title: 'YouTube Shorts are unavailable right now',
          detail:
              'You can continue in MoolSocial Feed while YouTube is unavailable.',
          actionLabel: 'Open Feed',
          onAction: () => _selectChoice('feed'),
        ),
      );
    }
    if (_liveYouTubeShortsLoading && !_hasYouTubeShortsSnapshot) {
      return _buildYouTubeShortsStatus(
        const _YouTubeShortsStatusView(
          key: Key('screen04-youtube-shorts-state-loading'),
          icon: Icons.smart_display_rounded,
          title: 'Loading YouTube Shorts',
          detail: 'Checking the current public catalogue.',
          loading: true,
        ),
      );
    }
    if (_liveYouTubeShortsError != null && !_hasYouTubeShortsSnapshot) {
      return _buildYouTubeShortsStatus(
        _YouTubeShortsStatusView(
          key: const Key('screen04-youtube-shorts-state-error'),
          icon: Icons.wifi_off_rounded,
          title: 'YouTube Shorts couldn’t load',
          detail: _liveYouTubeShortsError!,
          actionLabel: 'Try again',
          onAction: _loadLiveYouTubeVideos,
        ),
      );
    }
    final shorts = _eligibleLiveYouTubeShorts();
    if (shorts.isEmpty) {
      return _buildYouTubeShortsStatus(
        _YouTubeShortsStatusView(
          key: const Key('screen04-youtube-shorts-state-empty'),
          icon: Icons.video_library_outlined,
          title: 'No Shorts to show',
          detail: 'Check again soon.',
          actionLabel: 'Check again',
          onAction: _loadLiveYouTubeVideos,
        ),
      );
    }
    final topSystemInset = MediaQuery.viewPaddingOf(context).top;
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          key: const Key('screen04-youtube-shorts-top-inset'),
          padding: EdgeInsets.only(top: topSystemInset),
          child: PageView.builder(
            key: const Key('screen04-shorts-page-view'),
            controller: _shortController,
            scrollDirection: Axis.vertical,
            itemCount: shorts.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _activeShortPage = index);
              _persistActiveYouTubeShort(index);
            },
            itemBuilder: (context, index) => _buildLiveYouTubeShort(
              shorts[index],
              active: index == _activeShortPage,
            ),
          ),
        ),
        if (_liveYouTubeShortsError != null)
          Positioned(
            top: topSystemInset + 12,
            left: 12,
            right: 12,
            child: _YouTubeCatalogueRefreshNotice(
              key: const Key('screen04-youtube-shorts-refresh-error'),
              onRetry: _loadLiveYouTubeVideos,
            ),
          ),
      ],
    );
  }

  bool _isEligibleYouTubeShortRecord(Screen04YouTubePublicVideo video) {
    final durationSeconds = screen04YouTubeDurationSeconds(video.duration);
    if (!video.embeddable ||
        video.hasKnownDeviceRegionExclusion ||
        durationSeconds == null ||
        durationSeconds <= 0 ||
        durationSeconds > screen04YouTubeShortMaximumSeconds) {
      return false;
    }
    final declaration = <String>[
      video.title,
      video.description,
      ...video.hashtags,
    ].join(' ').toLowerCase();
    return RegExp(
      r'(^|[^a-z0-9])#?(?:youtube\s*)?shorts?(?=$|[^a-z0-9])',
    ).hasMatch(declaration);
  }

  List<_ShortData> _eligibleLiveYouTubeShorts() {
    return _liveYouTubeShorts
        .where(
          (short) =>
              short.youtube &&
              short.providerVideoId != null &&
              short.embeddable &&
              !short.hasKnownDeviceRegionExclusion,
        )
        .toList(growable: false);
  }

  void _persistActiveYouTubeShort(int index) {
    final shorts = _eligibleLiveYouTubeShorts();
    if (index < 0 || index >= shorts.length) {
      unawaited(_youtubeShortStateCache.clear());
      return;
    }
    final ids = shorts
        .map((short) => short.providerVideoId)
        .whereType<String>()
        .toList(growable: false);
    final selectedVideoId = shorts[index].providerVideoId;
    if (selectedVideoId == null || ids.length != shorts.length) {
      unawaited(_youtubeShortStateCache.clear());
      return;
    }
    _youtubeShortStateCache.replace(
      selectedVideoId: selectedVideoId,
      activeIndex: index,
      catalogueVideoIds: ids,
    );
  }

  void _resetShorts({bool clearDurable = true}) {
    _activeShortPage = 0;
    if (clearDurable) unawaited(_youtubeShortStateCache.clear());
    if (_shortController.hasClients) _shortController.jumpToPage(0);
  }

  Widget _buildLiveYouTubeShort(_ShortData reel, {required bool active}) {
    return Semantics(
      key: Key('screen04-short-${reel.id}'),
      label:
          'YouTube Short, ${reel.title}, ${reel.creator}, '
          '${reel.views}, ${reel.published}. Swipe up for the next Short.',
      child: ColoredBox(
        key: const Key('screen04-youtube-shorts-provider-owned'),
        color: Colors.black,
        child: SizedBox.expand(
          key: const Key('screen04-youtube-shorts-stage'),
          child: ColoredBox(
            key: const Key('screen04-short-media-youtube-live'),
            color: Colors.black,
            child: active
                ? _Screen04OfficialYouTubePlayer(
                    key: ValueKey(
                      'screen04-youtube-short-${reel.providerVideoId}',
                    ),
                    data: _videoDataFromShort(reel),
                    isVerifiedVerticalShort: true,
                    onOpenProvider: () => _openYouTubeShort(reel),
                  )
                : reel.thumbnailUrl != null
                ? Image.network(
                    reel.thumbnailUrl!.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: Colors.black),
                  )
                : const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );
  }

  List<_VideoData> _eligibleLiveYouTubeVideos() {
    return _liveYouTubeVideos
        .where(
          (video) =>
              video.providerVideoId != null &&
              video.embeddable &&
              !video.hasKnownDeviceRegionExclusion,
        )
        .toList(growable: false);
  }

  Widget _buildVideos() {
    final currentCatalog = _eligibleLiveYouTubeVideos();
    if (_youtubeSearchOpen) {
      return _YouTubeSearchSurface(
        controller: _youtubeSearchController,
        resultsController: _youtubeSearchResultsController,
        focusNode: _youtubeSearchFocusNode,
        autofocus: !_restoredYouTubeSearch,
        loading: _youtubeSearchLoading,
        submittedQuery: _youtubeSubmittedQuery,
        error: _youtubeSearchError,
        results: _youtubeSearchResults,
        onBack: _closeYouTubeSearch,
        onClear: _clearYouTubeSearch,
        onSubmitted: _submitYouTubeSearch,
        onRetry: () => _submitYouTubeSearch(_youtubeSubmittedQuery),
        onVideo: _openVideoFromSearch,
      );
    }
    if (_activeVideo case final video?) {
      return ColoredBox(
        color: const Color(0xFF0F0F0F),
        child: Column(
          children: [
            _YouTubeWatchHeader(
              backTooltip: _returnToYouTubeSearchAfterVideo
                  ? 'Back to YouTube Search results'
                  : 'Back to YouTube Home',
              onBack: _handleScreen04Back,
              onSearch: _openYouTubeSearch,
            ),
            Expanded(
              child: _InlineVideoWatch(
                data: video,
                moreVideos: currentCatalog
                    .where((candidate) => candidate.id != video.id)
                    .toList(growable: false),
                controller: _videoWatchController,
                onPlay: () => showSocialV2Message(
                  context,
                  'YouTube playback is temporarily unavailable',
                ),
                onChannel: () => _openVideoChannel(video),
                onOpenChannel: () =>
                    _openYouTubeChannel(video.providerChannelId),
                onDetails: () => _openVideoDetails(video),
                onShare: () => _shareYouTubeVideo(video),
                onOpenProvider: _openYouTubeVideo,
                onSelectVideo: (next) {
                  final origin = _returnToYouTubeSearchAfterVideo
                      ? YouTubePublicWatchOrigin.search
                      : YouTubePublicWatchOrigin.home;
                  setState(() {
                    _activeVideo = next;
                    if (_videoWatchController.hasClients) {
                      _videoWatchController.jumpTo(0);
                    }
                  });
                  _persistYouTubeWatch(next, origin);
                },
              ),
            ),
          ],
        ),
      );
    }
    if (_contentUnavailable) {
      return _buildYouTubeHomeStatus(
        _YouTubeVideosStatusView(
          key: const Key('screen04-youtube-videos-state-unavailable'),
          icon: Icons.smart_display_outlined,
          title: 'YouTube Videos are unavailable',
          detail: 'This video isn’t available here right now.',
          actionLabel: _youtubePublicAccessAvailable
              ? 'Try again'
              : 'Open Feed',
          onAction: _youtubePublicAccessAvailable
              ? _loadLiveYouTubeVideos
              : () => _selectChoice('feed'),
        ),
      );
    }
    if (!_youtubePublicAccessAvailable) {
      return _buildYouTubeHomeStatus(
        _YouTubeVideosStatusView(
          key: Key('screen04-youtube-videos-state-provider-access'),
          icon: Icons.smart_display_outlined,
          title: 'YouTube Videos are unavailable right now',
          detail:
              'You can continue in MoolSocial Feed while YouTube is unavailable.',
          actionLabel: 'Open Feed',
          onAction: () => _selectChoice('feed'),
        ),
      );
    }
    if (_youtubeChannelLoading) {
      return _buildYouTubeHomeStatus(
        const _YouTubeVideosStatusView(
          key: Key('screen04-youtube-channel-state-loading'),
          icon: Icons.video_library_outlined,
          title: 'Loading channel videos',
          detail:
              'Bringing this channel’s eligible public uploads into MoolSocial.',
          loading: true,
        ),
      );
    }
    if (_youtubeChannelError case final error?) {
      return _buildYouTubeHomeStatus(
        _YouTubeVideosStatusView(
          key: const Key('screen04-youtube-channel-state-error'),
          icon: Icons.wifi_off_rounded,
          title: 'Channel videos could not load',
          detail: error,
          actionLabel: 'Try again',
          onAction: () => _openYouTubeChannel(_activeYouTubeChannelId),
        ),
      );
    }
    if (_liveYouTubeLoading && !_hasYouTubeVideosSnapshot) {
      return _buildYouTubeHomeStatus(
        const _YouTubeVideosStatusView(
          key: Key('screen04-youtube-videos-state-loading'),
          icon: Icons.smart_display_rounded,
          title: 'Loading YouTube videos',
          detail: 'Checking the current public catalogue.',
          loading: true,
        ),
      );
    }
    if (_liveYouTubeError != null && !_hasYouTubeVideosSnapshot) {
      return _buildYouTubeHomeStatus(
        _YouTubeVideosStatusView(
          key: const Key('screen04-youtube-videos-state-error'),
          icon: Icons.wifi_off_rounded,
          title: 'YouTube Videos could not load',
          detail: _liveYouTubeError!,
          actionLabel: 'Try again',
          onAction: _loadLiveYouTubeVideos,
        ),
      );
    }
    if (currentCatalog.isEmpty) {
      return _buildYouTubeHomeStatus(
        _YouTubeVideosStatusView(
          key: const Key('screen04-youtube-videos-state-empty'),
          icon: Icons.video_library_outlined,
          title: 'No videos to show',
          detail: 'Check again soon.',
          actionLabel: 'Check again',
          onAction: _loadLiveYouTubeVideos,
        ),
      );
    }
    final query = _videoQuery.toLowerCase();
    final videos = currentCatalog
        .where(
          (video) =>
              query.isEmpty ||
              <String>[
                video.title,
                video.channel,
                video.summary,
                ...video.hashtags,
              ].join(' ').toLowerCase().contains(query),
        )
        .toList(growable: false);
    final shownVideos = videos.take(_visibleVideoCount).toList(growable: false);
    final homeShorts = _eligibleLiveYouTubeShorts();
    return ColoredBox(
      color: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          _YouTubeHomeHeader(
            onSearch: _openYouTubeSearch,
            onNotifications: _openUniversalNotifications,
            onChannelStatus: _openYouTubeChannelStatus,
            onAccount: _openAccount,
          ),
          _YouTubeTopicStrip(
            selectedQuery: _videoQuery,
            onSelected: (query) => setState(() {
              _videoQuery = query;
              _visibleVideoCount = 20;
            }),
          ),
          if (_liveYouTubeError != null)
            _YouTubeCatalogueRefreshNotice(
              key: const Key('screen04-youtube-videos-refresh-error'),
              onRetry: _loadLiveYouTubeVideos,
            ),
          Expanded(
            child: ListView(
              key: const Key('screen04-youtube-home-list'),
              controller: _videoHomeController,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (_activeYouTubeChannelTitle case final channelTitle?)
                  Container(
                    key: const Key('screen04-youtube-channel-catalogue'),
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF202020),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.video_library_outlined,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Videos from $channelTitle',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('screen04-youtube-channel-all-videos'),
                          onPressed: _restoreYouTubePublicCatalogue,
                          child: const Text('All videos'),
                        ),
                      ],
                    ),
                  ),
                if (homeShorts.isNotEmpty)
                  _YouTubeHomeShortsShelf(
                    shorts: homeShorts.take(8).toList(growable: false),
                    onShort: _openShortFromHome,
                  ),
                if (shownVideos.isEmpty)
                  const _YouTubeHomeEmptySearch()
                else
                  for (final video in shownVideos)
                    _VideoCard(
                      data: video,
                      onTap: () => _openVideoFromDiscovery(video),
                    ),
                if (shownVideos.length < videos.length)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                      onPressed: () => setState(
                        () => _visibleVideoCount = (_visibleVideoCount + 10)
                            .clamp(20, videos.length)
                            .toInt(),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      child: const Text('Show more videos'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeHomeStatus(Widget status) {
    return ColoredBox(
      color: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          _YouTubeHomeHeader(
            onSearch: _openYouTubeSearch,
            onNotifications: _openUniversalNotifications,
            onChannelStatus: _openYouTubeChannelStatus,
            onAccount: _openAccount,
          ),
          Expanded(child: status),
        ],
      ),
    );
  }

  Widget _buildYouTubeShortsStatus(Widget status) {
    return ColoredBox(
      color: const Color(0xFF070711),
      child: Column(
        children: [
          _YouTubeHomeHeader(
            title: 'Shorts',
            onSearch: _openYouTubeSearch,
            onNotifications: _openUniversalNotifications,
            onChannelStatus: _openYouTubeChannelStatus,
            onAccount: _openAccount,
          ),
          Expanded(child: status),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    return ListenableBuilder(
      listenable: widget.sharedSession,
      builder: (context, _) {
        final session = widget.sharedSession;
        final normalizedFeedQuery = _feedQuery.trim().toLowerCase();
        final publishedItems = session.socialPublishedItems
            .where((item) => item.type != SocialPublishedContentType.reel)
            .where(
              (item) =>
                  item.authorId == null ||
                  !session.socialAuthorBlocked(item.authorId!),
            )
            .where(
              (item) =>
                  normalizedFeedQuery.isEmpty ||
                  item.authorName.toLowerCase().contains(normalizedFeedQuery) ||
                  item.authorHandle.toLowerCase().contains(
                    normalizedFeedQuery,
                  ) ||
                  item.body.toLowerCase().contains(normalizedFeedQuery),
            )
            .toList();
        if (_feedMode == _MoolSocialFeedMode.following) {
          publishedItems.removeWhere((item) {
            final authorId = item.authorId;
            return authorId == null ||
                session.socialAuthorProfile(authorId)?.followed != true;
          });
        } else if (_feedMode == _MoolSocialFeedMode.latest) {
          publishedItems.sort(
            (left, right) => right.publishedAt.compareTo(left.publishedAt),
          );
        }
        final sharedItemIndex = _feedLinkContextActive
            ? publishedItems.indexWhere(
                (item) => item.id == _resolvedFeedLinkItem,
              )
            : -1;
        if (sharedItemIndex > 0) {
          final sharedItem = publishedItems.removeAt(sharedItemIndex);
          publishedItems.insert(0, sharedItem);
        }
        final runtimeState = _feedState != 'empty'
            ? _feedState
            : session.socialFeedLoading && !session.socialFeedLoaded
            ? 'loading'
            : session.socialFeedError != null && publishedItems.isEmpty
            ? 'error'
            : 'empty';
        return _MoolSocialFeedStatusView(
          state: runtimeState,
          content: [
            if (publishedItems.isNotEmpty &&
                session.socialFeedError != null) ...[
              SocialV2Notice(
                title: 'Feed refresh did not complete',
                detail:
                    '${session.socialFeedError} Your last loaded posts remain visible.',
                warning: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('screen04-feed-cached-retry'),
                  onPressed: session.socialFeedLoading
                      ? null
                      : session.retrySocialFeed,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Feed'),
                ),
              ),
            ],
            if (_feedLinkContextActive &&
                _unavailableFeedLinkItem == widget.initialItem?.trim())
              const SocialV2Notice(
                title: 'This shared post is not available',
                detail:
                    'It may have been removed or is no longer public. You can keep browsing Feed.',
                warning: true,
              ),
            for (final item in publishedItems)
              SocialPublishedContentCardV2(
                item: item,
                session: session,
                onOpenAuthor: _openAuthor,
                onMore: _openPostActions,
                onOpenPost: _openPostDetail,
                onRelationship: (item) => unawaited(_toggleFeedFollow(item)),
                followed: item.authorId == null
                    ? null
                    : session.socialAuthorProfile(item.authorId!)?.followed,
                relationshipBusy:
                    item.authorId != null &&
                    (session.socialAuthorLoading(item.authorId!) ||
                        session.socialFollowBusy(item.authorId!)),
                onReply: () => _openPostDetail(item, focusReplies: true),
                onShare: () => _openShare(item),
                onAuthenticationRequired: widget.session.isAuthenticated
                    ? null
                    : (intent) => _requireFeedAuthentication(item, intent),
              ),
            if (publishedItems.isNotEmpty && session.socialFeedHasMore)
              OutlinedButton.icon(
                key: const Key('screen04-feed-load-more'),
                onPressed: session.socialFeedLoading
                    ? null
                    : session.loadSocialFeed,
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  session.socialFeedLoading ? 'Loading posts' : 'Load more',
                ),
              ),
          ],
          searchOpen: _feedSearchOpen,
          searchController: _feedSearchController,
          query: _feedQuery,
          mode: _feedMode,
          onModeChanged: (mode) => setState(() => _feedMode = mode),
          reviewPreview: widget.enableCreateReviewPreview,
          onSearchChanged: (value) => setState(() => _feedQuery = value),
          onSearch: () => setState(() {
            _feedSearchOpen = !_feedSearchOpen;
            if (!_feedSearchOpen) {
              _feedSearchController.clear();
              _feedQuery = '';
            }
          }),
          onNotifications: _openUniversalNotifications,
          onProfile: _openAccount,
          onCreate: _openCreationGateway,
          onDiscover: () => _openFeedChatSection('discover'),
          onSaved: _openSavedPosts,
          onRetry: () {
            if (_feedState != 'empty') {
              setState(() => _feedState = 'empty');
            } else if (session.socialContentAvailable) {
              unawaited(session.loadSocialFeed(refresh: true));
            } else {
              showSocialV2Message(
                context,
                'Feed could not refresh right now. You can still create, discover people or open Chat.',
              );
            }
          },
        );
      },
    );
  }

  void _openComments(SocialPublishedItem item) {
    _openPostDetail(item, focusReplies: true);
  }

  void _openPostDetail(SocialPublishedItem item, {bool focusReplies = false}) {
    showSocialV2Sheet(
      context,
      title: 'Post',
      subtitle: '${item.authorHandle} · Public conversation',
      children: [
        _SocialPostDetailV2(
          item: item,
          session: widget.sharedSession,
          authenticated: widget.session.isAuthenticated,
          focusReplies: focusReplies,
          onOpenAuthor: () {
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openAuthor(item);
            });
          },
          onMore: () {
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openPostActions(item);
            });
          },
          onRelationship: () {
            if (!widget.session.isAuthenticated) {
              Navigator.of(context).pop();
              _requireFeedAuthentication(
                item,
                const SocialProtectedActionIntent(
                  action: SocialProtectedAction.follow,
                ),
              );
              return;
            }
            unawaited(_toggleFeedFollow(item));
          },
          onShare: () {
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openShare(item);
            });
          },
          onAuthenticationRequired: (intent) {
            Navigator.of(context).pop();
            _requireFeedAuthentication(item, intent);
          },
        ),
      ],
    );
  }

  Future<void> _toggleFeedFollow(
    SocialPublishedItem item, {
    bool? followed,
  }) async {
    final authorId = item.authorId;
    if (authorId == null || authorId.isEmpty) {
      showSocialV2Message(
        context,
        'That MoolSocial author is no longer available.',
      );
      return;
    }
    if (!widget.session.isAuthenticated) {
      _requireFeedAuthentication(
        item,
        const SocialProtectedActionIntent(action: SocialProtectedAction.follow),
      );
      return;
    }
    var profile = widget.sharedSession.socialAuthorProfile(authorId);
    if (profile == null) {
      await widget.sharedSession.loadSocialAuthor(
        authorId,
        authenticated: true,
      );
      if (!mounted) return;
      profile = widget.sharedSession.socialAuthorProfile(authorId);
    }
    if (profile == null) {
      showSocialV2Message(
        context,
        widget.sharedSession.socialAuthorError(authorId) ??
            'Follow is unavailable right now. Nothing changed.',
      );
      return;
    }
    if (profile.isSelf) {
      showSocialV2Message(context, 'This is your MoolSocial profile.');
      return;
    }
    final nextFollowed = followed ?? !profile.followed;
    if (profile.followed == nextFollowed) return;
    final completed = await widget.sharedSession.setSocialFollow(
      authorId,
      nextFollowed,
    );
    if (!mounted || completed) return;
    showSocialV2Message(
      context,
      widget.sharedSession.socialAuthorError(authorId) ??
          'Follow could not be updated. Nothing changed.',
    );
  }

  void _openAuthor(SocialPublishedItem item) {
    final authorId = item.authorId;
    if (authorId == null || authorId.isEmpty) {
      showSocialV2Message(
        context,
        'That MoolSocial author is no longer available.',
      );
      return;
    }
    showSocialV2Sheet(
      context,
      title: item.authorName,
      subtitle: '${item.authorHandle} · Public MoolSocial profile',
      children: [
        _SocialAuthorPanelV2(
          sourceItem: item,
          session: widget.sharedSession,
          authenticated: widget.session.isAuthenticated,
          onRequestMessage: () {
            Navigator.of(context).pop();
            unawaited(_startChatWithAuthor(item));
          },
          onAuthenticationRequired: () {
            Navigator.of(context).pop();
            widget.session.beginSignIn(
              returnLocation: Uri(
                path: '/app/social',
                queryParameters: {
                  'sub': 'feed',
                  'state': 'author',
                  'item': item.id,
                },
              ).toString(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _startChatWithAuthor(SocialPublishedItem item) async {
    final authorId = item.authorId;
    if (authorId == null || authorId.isEmpty) return;
    if (!widget.session.isAuthenticated) {
      widget.session.beginSignIn(
        returnLocation: Uri(
          path: '/app/social',
          queryParameters: {'sub': 'feed', 'item': item.id},
        ).toString(),
        cancelLocation: '/app/social?sub=${_tab.name}',
      );
      return;
    }
    if (_pendingFeedMessageRequests.contains(authorId)) {
      showSocialV2Message(
        context,
        'Message request is still awaiting approval.',
      );
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: Key('social-message-request-dialog-$authorId'),
        title: Text('Request to message ${item.authorName}?'),
        content: const Text(
          'They must approve before a private conversation opens. Following public posts does not grant message access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const Key('social-message-request-send'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    if (!mounted || approved != true) return;
    setState(() => _pendingFeedMessageRequests.add(authorId));
    showSocialV2Message(
      context,
      'Message request is awaiting approval. No private chat was opened.',
    );
  }

  void _requireFeedAuthentication(
    SocialPublishedItem item,
    SocialProtectedActionIntent intent,
  ) {
    assert(intent.isValid);
    final returnLocation = Uri(
      path: '/app/social',
      queryParameters: {
        'sub': 'feed',
        'item': item.id,
        'action': intent.routeValue,
        if (intent.choiceIndex case final choiceIndex?)
          'choice': '$choiceIndex',
      },
    ).toString();
    widget.session.beginSignIn(
      returnLocation: returnLocation,
      cancelLocation: Uri(
        path: '/app/social',
        queryParameters: {'sub': 'feed', 'item': item.id},
      ).toString(),
    );
  }

  Widget _buildCreate() {
    if (_createDraftHydrating) {
      return const Center(
        key: Key('screen04-create-draft-restoring'),
        child: CircularProgressIndicator(),
      );
    }
    final createView = _createView == 'home' ? 'post' : _createView;
    final workbench = SocialCreateWorkbenchV2(
      key: const ValueKey('social-creator-gateway'),
      session: widget.sharedSession,
      mediaPicker: _mediaPicker,
      draft: _createDraft,
      authorName: _publicAuthorName,
      authorHandle: _publicAuthorHandle,
      allowReel: false,
      onBeforeDraftClear: _clearCreateDraftMedia,
      onBeforeClose: _flushCreateDraft,
      recoverInterruptedMedia: !_restoredCreateDraft,
      disableLocalMediaPreviewForTesting:
          widget.disableLocalDraftMediaPreviewForTesting,
      externalOperationLocked: _createBackBusy,
      previewOnly:
          _createReviewPreviewActive && !widget.session.isAuthenticated,
      onPreviewSignIn: _beginCreateSignIn,
      onClose: _closeCreate,
      initialIntent: switch (createView) {
        'image' => SocialCreateIntentV2.image,
        'carousel' => SocialCreateIntentV2.carousel,
        'image-poll' => SocialCreateIntentV2.imagePoll,
        'quick-poll' => SocialCreateIntentV2.quickPoll,
        'quiz' => SocialCreateIntentV2.quiz,
        _ => SocialCreateIntentV2.text,
      },
      initialFormat: switch (createView) {
        'reel' ||
        'reel-source' ||
        'reel-camera' ||
        'reel-edit' => SocialCreateFormatV2.reel,
        'carousel' => SocialCreateFormatV2.carousel,
        _ => SocialCreateFormatV2.post,
      },
      onPublished: (item) {
        HapticFeedback.mediumImpact();
        setState(() {
          if (item.type == SocialPublishedContentType.reel) {
            _choiceByWorld['social'] = 'shorts';
            _tab = SocialV2Tab.shorts;
          } else {
            _choiceByWorld['social'] = 'feed';
            _tab = SocialV2Tab.feed;
          }
        });
        if (item.type == SocialPublishedContentType.reel) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _resetShorts());
        }
      },
    );
    if (!_createDraftMediaLoss) return workbench;
    return Column(
      children: [
        const Material(
          key: Key('screen04-create-draft-media-loss'),
          color: Color(0xFFFFF3CD),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Some draft media was unavailable and was removed. Your text was kept.',
            ),
          ),
        ),
        Expanded(child: workbench),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildCreateHome() {
    final hasDraft = _createDraft.hasMeaningfulContent;
    final hasUserContent = _createDraft.hasUserContent;
    return ListView(
      key: const Key('screen04-create-home'),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
      children: [
        Container(
          key: const Key('screen04-create-hub-header'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF14006B), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Turn an idea into a conversation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start simple, shape it visually and preview the experience before anything becomes public.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.2;
                  if (compact) {
                    return const Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _CreateJourneyStep(number: '1', label: 'Spark'),
                        _CreateJourneyStep(number: '2', label: 'Shape'),
                        _CreateJourneyStep(number: '3', label: 'Preview'),
                      ],
                    );
                  }
                  return const Row(
                    children: [
                      _CreateJourneyStep(number: '1', label: 'Spark'),
                      _CreateJourneyLine(),
                      _CreateJourneyStep(number: '2', label: 'Shape'),
                      _CreateJourneyLine(),
                      _CreateJourneyStep(number: '3', label: 'Preview'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('screen04-create-post-entry'),
                onPressed: hasUserContent
                    ? null
                    : () => _openCreateEditor('post'),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Start from a thought'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: SocialV2Colors.navy,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Choose how it comes alive',
          style: TextStyle(
            color: SocialV2Colors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Every format opens the same creative canvas with tools that match the idea.',
          style: TextStyle(
            color: SocialV2Colors.muted,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final columns = constraints.maxWidth >= 330 && textScale <= 1.15
                ? 3
                : 2;
            const gap = 10.0;
            final width =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: width,
                  child: _SocialCreateFormatTile(
                    key: const Key('screen04-create-photo-entry'),
                    title: 'Photo',
                    detail: 'Frame a moment and add the story behind it',
                    icon: Icons.add_photo_alternate_outlined,
                    accent: Color(0xFFE54878),
                    badge: 'Moment',
                    compact: columns == 3,
                    enabled: !hasUserContent,
                    onTap: () => _openCreateEditor('image'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _SocialCreateFormatTile(
                    key: const Key('screen04-create-carousel-entry'),
                    title: 'Carousel',
                    detail: 'Build a swipeable story, step by step',
                    icon: Icons.view_carousel_outlined,
                    accent: Color(0xFF6D4AFF),
                    badge: 'Story',
                    compact: columns == 3,
                    enabled: !hasUserContent,
                    onTap: () => _openCreateEditor('carousel'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _SocialCreateFormatTile(
                    key: const Key('screen04-create-poll-entry'),
                    title: 'Quick Poll',
                    detail: 'Ask one question with four clear choices',
                    icon: Icons.poll_outlined,
                    accent: Color(0xFF07856A),
                    badge: 'Conversation',
                    compact: columns == 3,
                    enabled: !hasUserContent,
                    onTap: () => _openCreateEditor('quick-poll'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _SocialCreateFormatTile(
                    key: const Key('screen04-create-image-poll-entry'),
                    title: 'Image Poll',
                    detail: 'Let people choose between four visual options',
                    icon: Icons.grid_view_rounded,
                    accent: Color(0xFF006A78),
                    badge: 'Visual vote',
                    compact: columns == 3,
                    enabled: !hasUserContent,
                    onTap: () => _openCreateEditor('image-poll'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _SocialCreateFormatTile(
                    key: const Key('screen04-create-quiz-entry'),
                    title: 'Quiz',
                    detail: 'Turn curiosity into an interactive reveal',
                    icon: Icons.quiz_outlined,
                    accent: Color(0xFFD06A00),
                    badge: 'Play',
                    compact: columns == 3,
                    enabled: !hasUserContent,
                    onTap: () => _openCreateEditor('quiz'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        SocialV2Card(
          key: const Key('screen04-create-draft-card'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEDE8FF),
                foregroundColor: SocialV2Colors.navy,
                child: Icon(Icons.drafts_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDraft ? 'Draft ready to continue' : 'No saved draft',
                      style: const TextStyle(
                        color: SocialV2Colors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasDraft
                          ? 'Your unpublished work remains private.'
                          : 'A draft appears here after you start creating.',
                      style: const TextStyle(
                        color: SocialV2Colors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('screen04-create-draft-entry'),
                onPressed: hasDraft
                    ? () => _openCreateEditor(
                        _createDraftResumeView(),
                        preserveIntent: true,
                      )
                    : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openCreateEditor(String view, {bool preserveIntent = false}) {
    HapticFeedback.selectionClick();
    if (!preserveIntent && !_createDraft.hasUserContent) {
      _createDraft.prepareFreshIntent(_createIntentForView(view));
    }
    setState(() => _createView = view);
  }

  SocialCreateIntentV2 _createIntentForView(String view) => switch (view) {
    'image' => SocialCreateIntentV2.image,
    'carousel' => SocialCreateIntentV2.carousel,
    'image-poll' => SocialCreateIntentV2.imagePoll,
    'quick-poll' => SocialCreateIntentV2.quickPoll,
    'quiz' => SocialCreateIntentV2.quiz,
    _ => SocialCreateIntentV2.text,
  };

  String _createDraftResumeView() {
    if (_createDraft.formatName == SocialCreateFormatV2.carousel.name) {
      return 'carousel';
    }
    return switch (_createDraft.toolName) {
      'image' => 'image',
      'imagePoll' => 'image-poll',
      'quickPoll' => 'quick-poll',
      'quiz' => 'quiz',
      _ => 'post',
    };
  }

  String get _publicAuthorName {
    final email = widget.session.emailAddress?.trim();
    if (email != null && email.contains('@')) {
      final parts = email
          .split('@')
          .first
          .split(RegExp(r'[._-]+'))
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      if (parts.isNotEmpty) {
        return parts
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
      }
    }
    final phone = widget.session.phoneNumber?.replaceAll(RegExp(r'\D'), '');
    if (phone != null && phone.isNotEmpty) return 'MoolSocial member';
    return 'MoolSocial member';
  }

  String get _publicAuthorHandle {
    final email = widget.session.emailAddress?.trim();
    if (email != null && email.contains('@')) {
      final local = email
          .split('@')
          .first
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      if (local.isNotEmpty) return '@$local';
    }
    final phone = widget.session.phoneNumber?.replaceAll(RegExp(r'\D'), '');
    if (phone != null && phone.isNotEmpty) {
      final suffix = phone.length > 4
          ? phone.substring(phone.length - 4)
          : phone;
      return '@member$suffix';
    }
    return '@moolsocial';
  }

  void _openPostActions(SocialPublishedItem item) {
    final reported = widget.sharedSession.socialPostReported(item.id);
    final busy = widget.sharedSession.socialReportBusy(item.id);
    showSocialV2Sheet(
      context,
      title: 'Post options',
      subtitle: '${item.authorHandle} · Choose what you want to do',
      children: [
        SocialV2ListTile(
          key: Key('social-report-post-${item.id}'),
          icon: reported
              ? Icons.check_circle_outline_rounded
              : Icons.flag_outlined,
          title: reported
              ? 'Report sent'
              : busy
              ? 'Sending report…'
              : 'Report post',
          detail: reported
              ? 'MoolSocial has received your report.'
              : 'Tell MoolSocial privately why this post needs review',
          onTap: reported || busy
              ? null
              : () {
                  Navigator.of(context).pop();
                  unawaited(_startPostReport(item));
                },
        ),
      ],
    );
  }

  void _openSavedPosts() {
    if (!widget.session.isAuthenticated) {
      widget.session.beginSignIn(
        returnLocation: '/app/social?sub=feed&state=saved',
        cancelLocation: '/app/social?sub=feed',
      );
      return;
    }
    showSocialV2Sheet(
      context,
      title: 'Saved posts',
      subtitle: 'Private to your MoolSocial account',
      children: [
        _SocialSavedPostsPanelV2(
          session: widget.sharedSession,
          onOpenPost: (item) {
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openPostDetail(item);
            });
          },
        ),
      ],
    );
  }

  Future<void> _startPostReport(SocialPublishedItem item) async {
    if (!widget.session.isAuthenticated) {
      _requireFeedAuthentication(
        item,
        const SocialProtectedActionIntent(action: SocialProtectedAction.report),
      );
      return;
    }
    final reason = await showDialog<SocialReportReason>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        key: Key('social-report-reason-dialog-${item.id}'),
        title: const Text('Why are you reporting this post?'),
        children: [
          for (final value in SocialReportReason.values)
            SimpleDialogOption(
              key: Key('social-report-reason-${value.name}'),
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(value.label),
              ),
            ),
        ],
      ),
    );
    if (!mounted || reason == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: Key('social-report-confirm-${item.id}'),
        title: const Text('Send this report?'),
        content: Text(
          '${reason.label}. Your report is private and does not remove the post before review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const Key('social-report-send'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send report'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final sent = await widget.sharedSession.reportSocialPost(item.id, reason);
    if (!mounted) return;
    if (!sent) {
      showSocialV2Message(
        context,
        widget.sharedSession.socialReportError(item.id) ??
            'The report could not be sent. Nothing changed.',
      );
      return;
    }
    showSocialV2Message(
      context,
      'Report sent. Thank you for helping keep MoolSocial safe.',
    );
  }

  void _openShare(SocialPublishedItem item) {
    final postUri = _publicPostUri(item);
    final postLink = postUri.toString();
    showSocialV2Sheet(
      context,
      title: 'Share',
      subtitle: 'Choose how to share this public Feed post',
      children: [
        SocialV2ListTile(
          key: const Key('social-share-repost'),
          icon: Icons.repeat_rounded,
          title: item.reposted ? 'Undo repost' : 'Repost',
          detail: item.reposted
              ? 'Remove your repost after server confirmation'
              : 'Share with your followers after server confirmation',
          onTap: () => _toggleRepostFromShare(item),
        ),
        SocialV2ListTile(
          key: const Key('social-share-add-thoughts'),
          icon: Icons.edit_note_rounded,
          title: 'Add thoughts',
          detail: 'Write a new post with this original attached',
          onTap: () => _addThoughtsToPost(item),
        ),
        SocialV2ListTile(
          key: const Key('social-share-send-chat'),
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Send in Chat',
          detail: 'Choose a conversation; nothing is sent automatically',
          onTap: () => _sendPostLinkInChat(item, postLink),
        ),
        SocialV2ListTile(
          key: const Key('social-share-other-apps'),
          icon: Icons.share_outlined,
          title: 'Share to another app',
          detail: "Open your phone's share options",
          onTap: () => _sharePostExternally(postUri),
        ),
        SocialV2ListTile(
          key: const Key('social-copy-post-link'),
          icon: Icons.link_rounded,
          title: 'Copy post link',
          detail: 'Copy the public link',
          onTap: () async {
            try {
              await Clipboard.setData(ClipboardData(text: postLink));
            } on Object {
              if (mounted) {
                showSocialV2Message(
                  context,
                  'Post link could not be copied. Try again.',
                );
              }
              return;
            }
            if (!mounted) return;
            Navigator.of(context).pop();
            showSocialV2Message(context, 'Post link copied');
          },
        ),
      ],
    );
  }

  Uri _publicPostUri(SocialPublishedItem item) => Uri.https(
    'moolsocial.com',
    '/app/social',
    {'sub': 'feed', 'item': item.id},
  );

  Rect _sharePositionOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final origin =
          renderObject.localToGlobal(Offset.zero) & renderObject.size;
      if (origin.isFinite && origin.width > 0 && origin.height > 0) {
        return origin;
      }
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }

  Future<void> _sharePostExternally(Uri postUri) async {
    Navigator.of(context).pop();
    final outcome = await _shareGateway.share(
      SocialV2ShareRequest(
        uri: postUri,
        title: 'Share MoolSocial post',
        subject: 'MoolSocial post',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    if (!mounted || outcome != SocialV2ShareOutcome.unavailable) {
      return;
    }
    showSocialV2Message(
      context,
      'Sharing is unavailable right now. You can copy the link instead.',
    );
  }

  Future<void> _toggleRepostFromShare(SocialPublishedItem item) async {
    Navigator.of(context).pop();
    if (!widget.session.isAuthenticated) {
      _requireFeedAuthentication(
        item,
        const SocialProtectedActionIntent(action: SocialProtectedAction.repost),
      );
      return;
    }
    final changed = await widget.sharedSession.toggleSocialRepost(item.id);
    if (!mounted) return;
    if (!changed) {
      showSocialV2Message(
        context,
        widget.sharedSession.errorMessage ?? 'Repost was not changed.',
      );
    }
  }

  void _addThoughtsToPost(SocialPublishedItem item) {
    Navigator.of(context).pop();
    final returnLocation = Uri(
      path: '/app/social',
      queryParameters: {
        'sub': 'create',
        'state': 'shared-post',
        'item': item.id,
      },
    ).toString();
    if (!widget.session.isAuthenticated) {
      widget.session.beginSignIn(
        returnLocation: returnLocation,
        cancelLocation: Uri(
          path: '/app/social',
          queryParameters: {'sub': 'feed', 'item': item.id},
        ).toString(),
      );
      return;
    }
    _createDraft.prepareQuotedPost(item);
    setState(() {
      _choiceByWorld['social'] = 'create';
      _tab = SocialV2Tab.create;
      _createView = 'post';
    });
  }

  void _sendPostLinkInChat(SocialPublishedItem item, String postLink) {
    Navigator.of(context).pop();
    final feedLocation = Uri(
      path: '/app/social',
      queryParameters: {'sub': 'feed', 'item': item.id},
    ).toString();
    final chatLocation = Uri(
      path: '/app/chat',
      queryParameters: {'draft': postLink, 'return': feedLocation},
    ).toString();
    if (!widget.session.isAuthenticated) {
      widget.session.beginSignIn(
        returnLocation: chatLocation,
        cancelLocation: feedLocation,
      );
      return;
    }
    context.push(chatLocation);
  }

  void _openVideoChannel(_VideoData video) {
    showSocialV2Sheet(
      context,
      title: video.channel,
      subtitle: video.subscribers,
      children: [
        _VideoChannelIdentity(
          video: video,
          onProvider: () => _openYouTubeChannel(video.providerChannelId),
        ),
        SocialV2Notice(
          title: 'About ${video.channel}',
          detail: video.channelSummary,
        ),
        _VideoStatRow(
          values: [
            (_channelMetricValue(video.channelVideos), 'Videos'),
            (_channelMetricValue(video.channelViews), 'Views'),
            (video.latestVideoDate, video.channelDateLabel),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Video details'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(_openYouTubeChannel(video.providerChannelId));
                },
                child: const Text('Open YouTube channel'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openYouTubeHome() {
    return _openYouTubeUri(
      Uri.https('www.youtube.com', '/'),
      unavailableMessage: 'YouTube could not be opened',
    );
  }

  Future<void> _openYouTubeVideo(_VideoData video) {
    final videoId = video.providerVideoId;
    if (videoId == null) {
      return _openYouTubeHome();
    }
    return _openYouTubeUri(
      Uri.https('www.youtube.com', '/watch', <String, String>{'v': videoId}),
      unavailableMessage: 'This video could not be opened on YouTube',
    );
  }

  Future<void> _shareYouTubeVideo(_VideoData video) async {
    final videoId = video.providerVideoId?.trim();
    if (videoId == null || videoId.isEmpty) {
      showSocialV2Message(context, 'This YouTube link is unavailable');
      return;
    }
    final url = Uri.https('www.youtube.com', '/watch', <String, String>{
      'v': videoId,
    });
    final outcome = await _shareGateway.share(
      SocialV2ShareRequest(
        uri: url,
        title: 'Share YouTube video',
        subject: 'YouTube video',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    if (!mounted || outcome != SocialV2ShareOutcome.unavailable) {
      return;
    }
    showSocialV2Message(
      context,
      'Sharing is unavailable right now. You can open this video on YouTube instead.',
    );
  }

  Future<void> _openYouTubeShort(_ShortData short) {
    final videoId = short.providerVideoId;
    if (videoId == null) {
      return _openYouTubeHome();
    }
    return _openYouTubeUri(
      Uri.https('www.youtube.com', '/shorts/$videoId'),
      unavailableMessage: 'This Short could not be opened on YouTube',
    );
  }

  Future<void> _openYouTubeChannel(String? channelId) async {
    final selectedChannelId = channelId?.trim();
    if (selectedChannelId == null || selectedChannelId.isEmpty) {
      showSocialV2Message(
        context,
        'This channel’s videos are unavailable in MoolSocial right now.',
      );
      return;
    }
    final request = ++_youtubeChannelRequest;
    _youtubeChannelOriginSnapshot ??= _youtubeCatalogueSnapshots.readVideos();
    setState(() {
      _activeYouTubeChannelId = selectedChannelId;
      _activeYouTubeChannelTitle = null;
      _youtubeChannelError = null;
      _youtubeChannelLoading = true;
      _choiceByWorld['social'] = 'videos';
      _tab = SocialV2Tab.videos;
      _activeVideo = null;
      _youtubeSearchOpen = false;
      _returnToYouTubeSearchAfterVideo = false;
      _videoQuery = '';
      _visibleVideoCount = 20;
    });
    try {
      final loader =
          widget.youtubeChannelLoader ??
          loadScreen04YouTubePublicChannelCatalogue;
      final catalogue = await loader(selectedChannelId);
      if (!mounted || request != _youtubeChannelRequest) return;
      final videos = catalogue.videos
          .map(_videoDataFromProvider)
          .toList(growable: false);
      _youtubeCatalogueSnapshots.replaceVideos(catalogue.videos);
      setState(() {
        _liveYouTubeVideos = videos;
        _hasYouTubeVideosSnapshot = true;
        _activeYouTubeChannelTitle = catalogue.channel.title;
        _youtubeChannelLoading = false;
        _youtubeChannelError = null;
      });
    } on Object {
      if (!mounted || request != _youtubeChannelRequest) return;
      setState(() {
        _youtubeChannelLoading = false;
        _youtubeChannelError =
            'MoolSocial could not load this channel’s public videos. Please try again.';
      });
    }
  }

  void _restoreYouTubePublicCatalogue() {
    _youtubeChannelRequest += 1;
    final origin = _youtubeChannelOriginSnapshot;
    setState(() {
      _activeYouTubeChannelId = null;
      _activeYouTubeChannelTitle = null;
      _youtubeChannelError = null;
      _youtubeChannelLoading = false;
      _youtubeChannelOriginSnapshot = null;
      _videoQuery = '';
      _visibleVideoCount = 20;
      if (origin != null) {
        _liveYouTubeVideos = origin
            .map(_videoDataFromProvider)
            .toList(growable: false);
        _hasYouTubeVideosSnapshot = true;
      }
    });
    if (origin != null) {
      _youtubeCatalogueSnapshots.replaceVideos(origin);
    } else {
      _loadLiveYouTubeVideos();
    }
  }

  Future<void> _openYouTubeUri(
    Uri uri, {
    required String unavailableMessage,
  }) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      opened = false;
    }
    if (!opened && mounted) {
      showSocialV2Message(context, unavailableMessage);
    }
  }

  String _channelMetricValue(String value) => value
      .replaceFirst(RegExp(r'\s+channel views$', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s+videos$', caseSensitive: false), '');

  void _openVideoDetails(_VideoData video) {
    showSocialV2Sheet(
      context,
      title: 'Description',
      subtitle: video.title,
      children: [
        _VideoStatRow(
          values: [
            (video.likes, 'Likes'),
            (video.views, 'Views'),
            (video.published, 'Published'),
          ],
        ),
        SocialV2Notice(title: video.summary, detail: video.hashtags.join('  ')),
        SocialV2ListTile(
          key: const Key('screen04-video-channel-details-sheet'),
          icon: Icons.person_outline_rounded,
          title: video.channel,
          detail: video.subscribers,
          badge: 'Details',
          onTap: () => _openVideoChannel(video),
        ),
        SocialV2ListTile(
          icon: Icons.calendar_today_outlined,
          title: 'Date',
          detail: video.publishedDate,
        ),
        SocialV2ListTile(
          icon: Icons.schedule_outlined,
          title: 'Duration',
          detail: video.duration,
        ),
        SocialV2ListTile(
          icon: Icons.closed_caption_outlined,
          title: 'Captions',
          detail: video.captions,
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue watching'),
        ),
      ],
    );
  }
}

class _CreateJourneyStep extends StatelessWidget {
  const _CreateJourneyStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: SocialV2Colors.navy,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _CreateJourneyLine extends StatelessWidget {
  const _CreateJourneyLine();

  @override
  Widget build(BuildContext context) => const Expanded(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Divider(color: Colors.white38, thickness: 1),
    ),
  );
}

class _SocialCreateFormatTile extends StatelessWidget {
  const _SocialCreateFormatTile({
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.badge,
    required this.compact,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final String badge;
  final bool compact;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: '$title. $detail',
    excludeSemantics: true,
    child: Material(
      color: accent.withValues(alpha: .055),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: .24)),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 100 : 116),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: compact ? 36 : 40,
                      height: compact ? 36 : 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        icon,
                        color: enabled ? accent : SocialV2Colors.muted,
                        size: compact ? 21 : 23,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: enabled ? accent : SocialV2Colors.muted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: compact ? 8 : 12),
                Text(
                  title,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled ? SocialV2Colors.navy : SocialV2Colors.muted,
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SocialV2Colors.muted,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MoolSocialFeedStatusView extends StatelessWidget {
  const _MoolSocialFeedStatusView({
    required this.state,
    required this.content,
    required this.searchOpen,
    required this.searchController,
    required this.query,
    required this.mode,
    required this.onModeChanged,
    required this.reviewPreview,
    required this.onSearchChanged,
    required this.onSearch,
    required this.onNotifications,
    required this.onProfile,
    required this.onCreate,
    required this.onDiscover,
    required this.onSaved,
    required this.onRetry,
  });

  final String state;
  final List<Widget> content;
  final bool searchOpen;
  final TextEditingController searchController;
  final String query;
  final _MoolSocialFeedMode mode;
  final ValueChanged<_MoolSocialFeedMode> onModeChanged;
  final bool reviewPreview;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onCreate;
  final VoidCallback onDiscover;
  final VoidCallback onSaved;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loading = state == 'loading';
    final showStatus = state != 'empty' || content.isEmpty;
    final (icon, title, detail) = switch (state) {
      'loading' => (
        Icons.sync_rounded,
        'Loading your MoolSocial Feed',
        'Checking for real MoolSocial posts. No posts are substituted while you wait.',
      ),
      'error' => (
        Icons.wifi_off_rounded,
        'We couldn’t refresh your Feed',
        'Your Feed stays clear until real MoolSocial posts are available.',
      ),
      'unavailable' => (
        Icons.lock_clock_rounded,
        'Feed isn’t available right now',
        'Try again later or open Create to prepare your next MoolSocial post.',
      ),
      _ => (
        mode == _MoolSocialFeedMode.following
            ? Icons.people_outline_rounded
            : Icons.forum_outlined,
        query.trim().isNotEmpty
            ? 'No matching posts'
            : mode == _MoolSocialFeedMode.following
            ? 'Your Following feed is ready to grow'
            : 'No posts yet',
        query.trim().isNotEmpty
            ? 'Try another search or discover people to continue.'
            : mode == _MoolSocialFeedMode.following
            ? 'Follow people from their public profiles to shape this feed.'
            : 'Create a post or discover people while new public posts arrive.',
      ),
    };

    return SocialV2PageList(
      key: ValueKey('screen04-moolsocial-feed-state-$state'),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
      children: [
        SocialV2Card(
          key: const Key('screen04-moolsocial-feed-brand'),
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B3FD0), SocialV2Colors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.blur_on_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MoolSocial Feed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SocialV2Colors.navy,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      switch (mode) {
                        _MoolSocialFeedMode.forYou => 'Relevant public posts',
                        _MoolSocialFeedMode.following =>
                          'Public posts from people you follow',
                        _MoolSocialFeedMode.latest =>
                          'Newest public posts first',
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SocialV2Colors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('screen04-feed-search-toggle'),
                tooltip: searchOpen ? 'Close Feed search' : 'Search Feed',
                onPressed: onSearch,
                color: SocialV2Colors.navy,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 42,
                ),
                icon: Icon(
                  searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  size: 21,
                ),
              ),
              IconButton(
                key: const Key('screen04-feed-notifications'),
                tooltip: 'Notifications',
                onPressed: onNotifications,
                color: SocialV2Colors.navy,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 42,
                ),
                icon: const Icon(Icons.notifications_none_rounded, size: 21),
              ),
              IconButton(
                key: const Key('screen04-feed-profile'),
                tooltip: 'Open your MoolSocial profile',
                onPressed: onProfile,
                color: SocialV2Colors.navy,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 42,
                ),
                icon: const Icon(Icons.account_circle_outlined, size: 21),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          key: const Key('screen04-feed-mode-selector'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in _MoolSocialFeedMode.values) ...[
                _MoolSocialFeedModeButton(
                  mode: value,
                  selected: mode == value,
                  onPressed: () => onModeChanged(value),
                ),
                if (value != _MoolSocialFeedMode.values.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (reviewPreview && content.isNotEmpty) const _FeedPreviewLabel(),
            OutlinedButton.icon(
              key: const Key('screen04-feed-network-discover'),
              onPressed: onDiscover,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: const Text('Discover people'),
            ),
            OutlinedButton.icon(
              key: const Key('screen04-feed-saved-posts'),
              onPressed: onSaved,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
              label: const Text('Saved posts'),
            ),
          ],
        ),
        if (searchOpen)
          TextField(
            key: const Key('screen04-feed-search-input'),
            controller: searchController,
            autofocus: true,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search posts or people',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('screen04-feed-search-clear'),
                      tooltip: 'Clear Feed search',
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        if (showStatus)
          SocialV2Card(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Semantics(
              liveRegion: true,
              label: title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F0FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: SocialV2Colors.navy, size: 23),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: SocialV2Colors.navy,
                                fontSize: 16,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              detail,
                              style: const TextStyle(
                                color: SocialV2Colors.muted,
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (loading) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(
                      key: Key('screen04-moolsocial-feed-loading'),
                      minHeight: 4,
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    if (state == 'empty') ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              key: const Key('screen04-feed-create-post'),
                              onPressed: onCreate,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create a post'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('screen04-feed-discover-people'),
                              onPressed: onDiscover,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: const Icon(Icons.person_search_outlined),
                              label: const Text('Discover'),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('screen04-feed-refresh-empty'),
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Check for new posts'),
                        ),
                      ),
                    ] else ...[
                      FilledButton.icon(
                        key: const Key('screen04-feed-retry'),
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('screen04-feed-create-post'),
                        onPressed: onCreate,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create a post'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          )
        else
          ...content,
      ],
    );
  }
}

class _MoolSocialFeedModeButton extends StatelessWidget {
  const _MoolSocialFeedModeButton({
    required this.mode,
    required this.selected,
    required this.onPressed,
  });

  final _MoolSocialFeedMode mode;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${mode.label} Feed',
    child: SizedBox(
      height: 48,
      child: FilterChip(
        key: Key('screen04-feed-mode-${mode.name}'),
        selected: selected,
        showCheckmark: false,
        avatar: Icon(mode.icon, size: 18),
        label: Text(mode.label),
        onSelected: (_) => onPressed(),
        selectedColor: const Color(0xFFE9E5FF),
        side: BorderSide(
          color: selected ? const Color(0xFF7C5CFF) : SocialV2Colors.line,
        ),
        labelStyle: TextStyle(
          color: selected ? SocialV2Colors.navy : SocialV2Colors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _FeedPreviewLabel extends StatelessWidget {
  const _FeedPreviewLabel();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('screen04-feed-review-preview-label'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4DE),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFFFFD18A)),
    ),
    child: const Text(
      'UI review content · Read-only',
      style: TextStyle(
        color: Color(0xFF6A3A00),
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SourcePill extends StatelessWidget {
  const _SourcePill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xC9000028),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SocialOwnershipDock extends StatelessWidget {
  const _SocialOwnershipDock({
    required this.selected,
    required this.onHome,
    required this.onShorts,
    required this.onCreate,
    required this.onFeed,
    required this.onMool,
    required this.onOpenAction,
    required this.onOpenChat,
  });

  final SocialV2Tab selected;
  final VoidCallback onHome;
  final VoidCallback onShorts;
  final VoidCallback onCreate;
  final VoidCallback onFeed;
  final VoidCallback onMool;
  final ValueChanged<PersonalMoolActionSpec> onOpenAction;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
      viewPadding: EdgeInsets.fromViewPadding(
        view.viewPadding,
        view.devicePixelRatio,
      ),
      platform: defaultTargetPlatform,
    );
    final horizontalSemanticsClearance =
        moolAndroidExportedHorizontalSemanticsClearance(
          viewPadding: EdgeInsets.fromViewPadding(
            view.viewPadding,
            view.devicePixelRatio,
          ),
          platform: defaultTargetPlatform,
        );
    return Padding(
      key: const Key('social-android-exported-semantics-clearance'),
      padding: EdgeInsets.fromLTRB(
        horizontalSemanticsClearance,
        0,
        horizontalSemanticsClearance,
        exportedSemanticsClearance,
      ),
      child: Material(
        key: const Key('moolsocial-compact-destination-rail'),
        color: const Color(0xFFF6F6FA),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: SafeArea(
          top: false,
          child: SizedBox(
            key: const Key('screen04-context-tabs'),
            height: MoolLocalNavigationTokens.destinationRailHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: MoolGlobalNavigationV2(
                    activeId: 'social',
                    onOpenMool: onMool,
                    onOpenAction: onOpenAction,
                    onOpenChat: onOpenChat,
                    compact: true,
                    compactExpanded: true,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SocialOwnershipDockItem(
                        controlKey: const Key('screen04-rail-videos'),
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: 'Home',
                        selected: selected == SocialV2Tab.videos,
                        ownership: 'YouTube',
                        selectedAccent: const Color(0xFFFF3355),
                        onTap: onHome,
                      ),
                      _SocialOwnershipDockItem(
                        controlKey: const Key('screen04-rail-shorts'),
                        icon: Icons.smart_display_outlined,
                        selectedIcon: Icons.smart_display_rounded,
                        label: 'Shorts',
                        selected: selected == SocialV2Tab.shorts,
                        ownership: 'YouTube',
                        selectedAccent: const Color(0xFFFF3355),
                        onTap: onShorts,
                      ),
                      _SocialOwnershipDockItem(
                        controlKey: const Key('screen04-rail-create'),
                        icon: Icons.add_rounded,
                        selectedIcon: Icons.add_rounded,
                        label: 'Create',
                        selected: selected == SocialV2Tab.create,
                        ownership: 'Create',
                        selectedAccent: const Color(0xFF7C5CFF),
                        onTap: onCreate,
                      ),
                      _SocialOwnershipDockItem(
                        controlKey: const Key('screen04-rail-feed'),
                        icon: Icons.dynamic_feed_outlined,
                        selectedIcon: Icons.dynamic_feed_rounded,
                        label: 'Feed',
                        selected: selected == SocialV2Tab.feed,
                        ownership: 'MoolSocial',
                        selectedAccent: const Color(0xFF41C997),
                        onTap: onFeed,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: MoolGlobalChatNavigationV2(
                    controlKey: const Key('social-global-chat'),
                    onOpenChat: onOpenChat,
                    expandedCell: true,
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

class _SocialOwnershipDockItem extends StatelessWidget {
  const _SocialOwnershipDockItem({
    required this.controlKey,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.ownership,
    required this.selectedAccent,
    required this.onTap,
  });

  final Key controlKey;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final String ownership;
  final Color selectedAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        key: controlKey,
        container: true,
        button: true,
        selected: selected,
        onTap: onTap,
        excludeSemantics: true,
        label: selected
            ? '$label, current, $ownership'
            : 'Open $label, $ownership',
        child: SizedBox.expand(
          child: InkWell(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: MoolMotion.accessible(
                        context,
                        MoolLocalNavigationTokens.selectionDuration,
                      ),
                      width: 38,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? selectedAccent.withValues(alpha: .13)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: selected
                              ? selectedAccent.withValues(alpha: .55)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        selected ? selectedIcon : icon,
                        color: selected
                            ? selectedAccent
                            : const Color(0xFF5E6378),
                        size: 23,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected
                            ? selectedAccent
                            : const Color(0xFF5E6378),
                        fontSize: 10,
                        height: 1,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  child: AnimatedScale(
                    key: ValueKey('social-rail-$label-selected-indicator'),
                    duration: MoolMotion.accessible(
                      context,
                      MoolLocalNavigationTokens.selectionDuration,
                    ),
                    scale: selected ? 1 : 0,
                    child: Container(
                      width: 16,
                      height: 2,
                      decoration: BoxDecoration(
                        color: selectedAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
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

class _YouTubeHomeHeader extends StatelessWidget {
  const _YouTubeHomeHeader({
    this.title = 'YouTube',
    required this.onSearch,
    required this.onNotifications,
    required this.onChannelStatus,
    required this.onAccount,
  });

  final String title;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onChannelStatus;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return ColoredBox(
      color: const Color(0xFF0F0F0F),
      child: SizedBox(
        key: const Key('screen04-youtube-home-header'),
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  compact
                      ? title
                      : title == 'YouTube'
                      ? 'YouTube videos'
                      : title,
                  key: const Key('screen04-youtube-home-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: const Key('screen04-youtube-home-search'),
                tooltip: 'Search YouTube',
                onPressed: onSearch,
                color: Colors.white,
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                key: const Key('screen04-youtube-home-notifications'),
                tooltip: 'MoolSocial notifications',
                onPressed: onNotifications,
                color: Colors.white,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              IconButton(
                key: const Key('screen04-youtube-home-channel-status'),
                tooltip: 'YouTube channel status',
                onPressed: onChannelStatus,
                color: Colors.white,
                icon: const Icon(Icons.ondemand_video_outlined),
              ),
              MoolGlobalProfileShortcutV2(
                keyName: 'screen04-youtube-home-account',
                surfaceTone: GlobalProfileSurfaceTone.socialDark,
                onPressed: onAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YouTubeWatchHeader extends StatelessWidget {
  const _YouTubeWatchHeader({
    required this.backTooltip,
    required this.onBack,
    required this.onSearch,
  });

  final String backTooltip;
  final VoidCallback onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('screen04-youtube-watch-header'),
      height: 48,
      child: Row(
        children: [
          IconButton(
            key: const Key('screen04-youtube-watch-back'),
            tooltip: backTooltip,
            onPressed: onBack,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Spacer(),
          IconButton(
            key: const Key('screen04-youtube-watch-search'),
            tooltip: 'Search YouTube',
            onPressed: onSearch,
            color: Colors.white,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }
}

class _YouTubeSearchSurface extends StatelessWidget {
  const _YouTubeSearchSurface({
    required this.controller,
    required this.resultsController,
    required this.focusNode,
    required this.autofocus,
    required this.loading,
    required this.submittedQuery,
    required this.error,
    required this.results,
    required this.onBack,
    required this.onClear,
    required this.onSubmitted,
    required this.onRetry,
    required this.onVideo,
  });

  final TextEditingController controller;
  final ScrollController resultsController;
  final FocusNode focusNode;
  final bool autofocus;
  final bool loading;
  final String submittedQuery;
  final String? error;
  final List<_VideoData> results;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onRetry;
  final ValueChanged<_VideoData> onVideo;

  @override
  Widget build(BuildContext context) {
    final hasSubmittedQuery = submittedQuery.trim().isNotEmpty;
    return ColoredBox(
      key: const Key('screen04-youtube-search-surface'),
      color: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          SizedBox(
            key: const Key('screen04-youtube-search-header'),
            height: 82,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 10, 8),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('screen04-youtube-search-back'),
                    tooltip: 'Back',
                    onPressed: onBack,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) => TextField(
                        key: const Key('screen04-youtube-search-input'),
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: autofocus,
                        minLines: 1,
                        maxLines: 2,
                        textInputAction: TextInputAction.search,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: Colors.white,
                        onSubmitted: onSubmitted,
                        decoration: InputDecoration(
                          hintText: 'Search YouTube',
                          hintStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: const Color(0xFF272727),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  key: const Key(
                                    'screen04-youtube-search-clear',
                                  ),
                                  tooltip: 'Clear search',
                                  onPressed: onClear,
                                  color: Colors.white70,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final draftQuery = value.text.trim();
                return switch ((loading, error, hasSubmittedQuery, results)) {
                  (true, _, _, _) => const _YouTubeSearchStatus(
                    key: Key('screen04-youtube-search-loading'),
                    icon: Icons.search_rounded,
                    title: 'Searching YouTube',
                    loading: true,
                  ),
                  (false, final failure?, _, _) => _YouTubeSearchStatus(
                    key: const Key('screen04-youtube-search-error'),
                    icon: Icons.wifi_off_rounded,
                    title: 'Search couldn’t load',
                    detail: failure,
                    actionLabel: 'Try again',
                    onAction: onRetry,
                  ),
                  (false, null, true, []) => const _YouTubeSearchStatus(
                    key: Key('screen04-youtube-search-empty'),
                    icon: Icons.search_off_rounded,
                    title: 'No results',
                    detail: 'Try a different search.',
                  ),
                  (false, null, true, final searchResults) => ListView.builder(
                    key: const Key('screen04-youtube-search-results'),
                    controller: resultsController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final video = searchResults[index];
                      return _VideoCard(
                        data: video,
                        onTap: () => onVideo(video),
                      );
                    },
                  ),
                  _ when draftQuery.isNotEmpty => _YouTubeSearchStatus(
                    key: const Key('screen04-youtube-search-draft-ready'),
                    icon: Icons.search_rounded,
                    title: 'Ready to search',
                    detail: 'Review the full query, then search.',
                    actionLabel: 'Search now',
                    onAction: () => onSubmitted(draftQuery),
                  ),
                  _ => const _YouTubeSearchStatus(
                    key: Key('screen04-youtube-search-prompt'),
                    icon: Icons.search_rounded,
                    title: 'Search YouTube',
                    detail: 'Type a topic, creator or video title.',
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YouTubeSearchStatus extends StatelessWidget {
  const _YouTubeSearchStatus({
    required this.icon,
    required this.title,
    this.detail,
    this.loading = false,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            else
              Icon(icon, color: Colors.white54, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (detail case final value?) ...[
              const SizedBox(height: 6),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
            if (actionLabel case final label?) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _YouTubeTopicStrip extends StatelessWidget {
  const _YouTubeTopicStrip({
    required this.selectedQuery,
    required this.onSelected,
  });

  final String selectedQuery;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const topics = <(String, String)>[
      ('', 'All'),
      ('news', 'News'),
      ('live', 'Live'),
      ('business', 'Business'),
      ('music', 'Music'),
    ];
    final selected = selectedQuery.trim().toLowerCase();
    return SizedBox(
      key: const Key('screen04-youtube-topic-strip'),
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final active = selected == topic.$1;
          return ChoiceChip(
            key: Key(
              'screen04-youtube-topic-${topic.$1.isEmpty ? 'all' : topic.$1}',
            ),
            selected: active,
            showCheckmark: false,
            label: Text(topic.$2),
            onSelected: (_) => onSelected(topic.$1),
            selectedColor: Colors.white,
            backgroundColor: const Color(0xFF272727),
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          );
        },
      ),
    );
  }
}

class _YouTubeHomeShortsShelf extends StatelessWidget {
  const _YouTubeHomeShortsShelf({required this.shorts, required this.onShort});

  final List<_ShortData> shorts;
  final ValueChanged<int> onShort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('screen04-youtube-home-shorts-shelf'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(Icons.smart_display_rounded, color: Colors.red, size: 25),
                SizedBox(width: 8),
                Text(
                  'YouTube Shorts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 278,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: shorts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final short = shorts[index];
                return Semantics(
                  button: true,
                  label: 'Watch YouTube Short, ${short.title}',
                  child: InkWell(
                    key: Key('screen04-youtube-home-short-${short.id}'),
                    onTap: () => onShort(index),
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 158,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (short.thumbnailUrl case final thumbnail?)
                              Image.network(
                                thumbnail.toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const ColoredBox(color: Color(0xFF272727)),
                              )
                            else
                              const ColoredBox(color: Color(0xFF272727)),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.center,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 9,
                              right: 9,
                              bottom: 10,
                              child: Text(
                                short.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YouTubeHomeEmptySearch extends StatelessWidget {
  const _YouTubeHomeEmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: Colors.white54, size: 44),
          SizedBox(height: 12),
          Text(
            'No matching videos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another title, channel or topic.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _YouTubeAttribution extends StatelessWidget {
  const _YouTubeAttribution();

  @override
  Widget build(BuildContext context) {
    const foreground = Colors.white;
    return Semantics(
      label: 'YouTube content source',
      child: ConstrainedBox(
        key: const Key('screen04-youtube-attribution'),
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/prototype/provider-youtube.svg',
                width: 18,
                height: 13,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 5),
              Text(
                'YouTube',
                style: TextStyle(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _ShortData {
  const _ShortData({
    required this.id,
    required this.title,
    required this.summary,
    required this.creator,
    required this.creatorMark,
    required this.meta,
    required this.modes,
    this.youtube = false,
    this.subscribers,
    this.views,
    this.likes,
    this.comments,
    this.published,
    this.hashtags,
    this.details,
    this.providerVideoId,
    this.providerChannelId,
    this.thumbnailUrl,
    this.embeddable = false,
    this.hasKnownDeviceRegionExclusion = false,
  });

  final String id;
  final String title;
  final String summary;
  final String creator;
  final String creatorMark;
  final String meta;
  final Set<String> modes;
  final bool youtube;
  final String? subscribers;
  final String? views;
  final String? likes;
  final String? comments;
  final String? published;
  final List<String>? hashtags;
  final String? details;
  final String? providerVideoId;
  final String? providerChannelId;
  final Uri? thumbnailUrl;
  final bool embeddable;
  final bool hasKnownDeviceRegionExclusion;
}

class _YouTubeCatalogueRefreshNotice extends StatelessWidget {
  const _YouTubeCatalogueRefreshNotice({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xEB272727),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 4, 4),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Could not refresh. Showing your last loaded catalogue.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _YouTubeVideosStatusView extends StatelessWidget {
  const _YouTubeVideosStatusView({
    required this.icon,
    required this.title,
    required this.detail,
    this.loading = false,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0F0F0F),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380, minHeight: 300),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/prototype/provider-youtube.svg',
                        width: 24,
                        height: 17,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF272727),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    alignment: Alignment.center,
                    child: loading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.6,
                            ),
                          )
                        : Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 18),
                    FilledButton(
                      key: const Key('screen04-youtube-videos-retry'),
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(132, 44),
                      ),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YouTubeShortsStatusView extends StatelessWidget {
  const _YouTubeShortsStatusView({
    required this.icon,
    required this.title,
    required this.detail,
    this.loading = false,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF070711),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, minHeight: 320),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF11111D),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      alignment: Alignment.center,
                      child: loading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.6,
                              ),
                            )
                          : Icon(icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 7,
                      children: [
                        SvgPicture.asset(
                          'assets/prototype/provider-youtube.svg',
                          width: 20,
                          height: 14,
                        ),
                        const Text(
                          'YouTube Shorts',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 18),
                      FilledButton(
                        key: const Key('screen04-youtube-shorts-retry'),
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(132, 44),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF101018),
                        ),
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoData {
  const _VideoData(
    this.title,
    this.channel,
    this.views,
    this.duration, {
    required this.published,
    required this.publishedDate,
    required this.summary,
    required this.likes,
    required this.comments,
    required this.subscribers,
    required this.channelSummary,
    required this.channelVideos,
    required this.channelViews,
    required this.latestVideoDate,
    required this.hashtags,
    this.providerVideoId,
    this.providerChannelId,
    this.thumbnailUrl,
    this.channelThumbnailUrl,
    this.embeddable = false,
    this.hasKnownDeviceRegionExclusion = false,
    this.channelDateLabel = 'Latest video',
    this.captions = 'Check on YouTube',
  });
  final String title;
  final String channel;
  final String views;
  final String duration;
  final String published;
  final String publishedDate;
  final String summary;
  final String likes;
  final String comments;
  final String subscribers;
  final String channelSummary;
  final String channelVideos;
  final String channelViews;
  final String latestVideoDate;
  final List<String> hashtags;
  final String? providerVideoId;
  final String? providerChannelId;
  final Uri? thumbnailUrl;
  final Uri? channelThumbnailUrl;
  final bool embeddable;
  final bool hasKnownDeviceRegionExclusion;
  final String channelDateLabel;
  final String captions;
  String get id =>
      providerVideoId ??
      title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
}

_VideoData _videoDataFromProvider(Screen04YouTubePublicVideo video) {
  final publishedDate = _formatVideoDate(video.publishedAt);
  final summary = video.description.trim().isEmpty
      ? 'Watch this public video from ${video.channelTitle}.'
      : video.description.trim();
  return _VideoData(
    video.title,
    video.channelTitle,
    formatScreen04YouTubeCount(video.viewCount, 'views'),
    _formatVideoDuration(video.duration),
    published: _formatPublishedAgo(video.publishedAt),
    publishedDate: publishedDate,
    summary: summary,
    likes: formatScreen04YouTubeCount(video.likeCount, 'likes'),
    comments: formatScreen04YouTubeCount(video.commentCount, 'comments'),
    subscribers: formatScreen04YouTubeCount(
      video.subscriberCount,
      'subscribers',
      unavailable: 'Subscriber count on YouTube',
    ),
    channelSummary: video.channelDescription?.trim().isNotEmpty == true
        ? video.channelDescription!.trim()
        : 'Public videos from ${video.channelTitle}.',
    channelVideos: formatScreen04YouTubeCount(
      video.channelVideoCount,
      'videos',
      unavailable: 'Available on YouTube',
    ),
    channelViews: formatScreen04YouTubeCount(
      video.channelViewCount,
      'channel views',
      unavailable: 'Available on YouTube',
    ),
    latestVideoDate: publishedDate,
    hashtags: video.hashtags,
    providerVideoId: video.videoId,
    providerChannelId: video.channelId,
    thumbnailUrl: video.thumbnailUrl,
    channelThumbnailUrl: video.channelThumbnailUrl,
    embeddable: video.embeddable,
    hasKnownDeviceRegionExclusion: video.hasKnownDeviceRegionExclusion,
    channelDateLabel: 'This video',
    captions: switch (video.captionAvailable) {
      true => 'Available',
      false => 'Not available',
      null => 'Check on YouTube',
    },
  );
}

_ShortData _shortDataFromProvider(Screen04YouTubePublicVideo video) {
  final summary = video.description.trim().isEmpty
      ? 'Watch this creator-labelled YouTube Short from ${video.channelTitle}.'
      : video.description.trim();
  final hashtags = video.hashtags.isEmpty ? const ['#Shorts'] : video.hashtags;
  return _ShortData(
    id: 'youtube-${video.videoId}',
    title: video.title,
    summary: summary,
    details: summary,
    creator: video.channelTitle,
    creatorMark: _creatorMark(video.channelTitle),
    meta: 'Creator-labelled Short on YouTube',
    modes: const {'for-you', 'youtube'},
    youtube: true,
    subscribers: formatScreen04YouTubeCount(
      video.subscriberCount,
      'subscribers',
      unavailable: 'Subscribers on YouTube',
    ),
    views: formatScreen04YouTubeCount(video.viewCount, 'views'),
    likes: formatScreen04YouTubeCount(video.likeCount, 'likes'),
    comments: formatScreen04YouTubeCount(video.commentCount, 'comments'),
    published: _formatPublishedAgo(video.publishedAt),
    hashtags: hashtags,
    providerVideoId: video.videoId,
    providerChannelId: video.channelId,
    thumbnailUrl: video.thumbnailUrl,
    embeddable: video.embeddable,
    hasKnownDeviceRegionExclusion: video.hasKnownDeviceRegionExclusion,
  );
}

_VideoData _videoDataFromShort(_ShortData short) {
  return _VideoData(
    short.title,
    short.creator,
    short.views ?? 'Views on YouTube',
    'Short',
    published: short.published ?? 'Published on YouTube',
    publishedDate: short.published ?? 'Published on YouTube',
    summary: short.summary,
    likes: short.likes ?? 'Likes on YouTube',
    comments: short.comments ?? 'Comments on YouTube',
    subscribers: short.subscribers ?? 'Subscribers on YouTube',
    channelSummary: short.details ?? short.summary,
    channelVideos: 'Videos on YouTube',
    channelViews: 'Views on YouTube',
    latestVideoDate: short.published ?? 'Published on YouTube',
    hashtags: short.hashtags ?? const ['#Shorts'],
    providerVideoId: short.providerVideoId,
    providerChannelId: short.providerChannelId,
    thumbnailUrl: short.thumbnailUrl,
    embeddable: short.embeddable,
    hasKnownDeviceRegionExclusion: short.hasKnownDeviceRegionExclusion,
    channelDateLabel: 'This Short',
  );
}

String _creatorMark(String channelTitle) {
  final parts = channelTitle
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'YT';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _formatVideoDuration(String? duration) {
  if (duration == null || duration.trim().isEmpty) return 'Video';
  final match = RegExp(
    r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$',
  ).firstMatch(duration.trim().toUpperCase());
  if (match == null) return duration;
  final hours = int.tryParse(match.group(1) ?? '') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
  final seconds = int.tryParse(match.group(3) ?? '') ?? 0;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _formatVideoDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _formatPublishedAgo(DateTime value) {
  final difference = DateTime.now().toUtc().difference(value.toUtc());
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours} hr ago';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  }
  if (difference.inDays < 35) {
    return '${(difference.inDays / 7).floor()} weeks ago';
  }
  if (difference.inDays < 365) {
    return '${(difference.inDays / 30).floor()} months ago';
  }
  return '${(difference.inDays / 365).floor()} years ago';
}

_VideoData? _videoForProviderId(List<_VideoData> videos, String? id) {
  if (id == null || id.trim().isEmpty) return null;
  for (final video in videos) {
    if (video.id == id) return video;
  }
  return null;
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.data, required this.onTap});
  final _VideoData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Watch ${data.title}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: const Color(0xFF0F0F0F),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _VideoThumbnail(data: data),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
                child: Row(
                  children: [
                    _VideoChannelAvatar(data: data),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${data.channel} · ${data.views} · ${data.published}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    const _YouTubeAttribution(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineVideoWatch extends StatelessWidget {
  const _InlineVideoWatch({
    required this.data,
    required this.moreVideos,
    required this.controller,
    required this.onPlay,
    required this.onChannel,
    required this.onOpenChannel,
    required this.onDetails,
    required this.onShare,
    required this.onOpenProvider,
    required this.onSelectVideo,
  });

  final _VideoData data;
  final List<_VideoData> moreVideos;
  final ScrollController controller;
  final VoidCallback onPlay;
  final VoidCallback onChannel;
  final VoidCallback onOpenChannel;
  final VoidCallback onDetails;
  final VoidCallback onShare;
  final ValueChanged<_VideoData> onOpenProvider;
  final ValueChanged<_VideoData> onSelectVideo;

  @override
  Widget build(BuildContext context) {
    return SocialV2PageList(
      key: const Key('screen04-video-watch'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child:
              data.providerVideoId != null &&
                  youtubeEmbeddedPlayerEnabled &&
                  !kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android
              ? _Screen04OfficialYouTubePlayer(
                  key: ValueKey(
                    'screen04-official-youtube-${data.providerVideoId}',
                  ),
                  data: data,
                  onOpenProvider: () => onOpenProvider(data),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    _VideoImage(data: data),
                    Center(
                      child: IconButton(
                        key: const Key('social-v2-youtube-play'),
                        tooltip: 'Play in the official YouTube player',
                        onPressed: onPlay,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xC8000028),
                          minimumSize: const Size(58, 58),
                          side: const BorderSide(color: Colors.white54),
                        ),
                        iconSize: 30,
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
                    ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _VideoProviderLine(data: data),
              const SizedBox(height: 10),
              InkWell(
                key: const Key('screen04-video-details-trigger'),
                onTap: onDetails,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${data.views} · ${data.published} ',
                              ),
                              const TextSpan(
                                text: 'More',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _VideoCreatorRow(
                data: data,
                onChannel: onChannel,
                onOpenChannel: onOpenChannel,
              ),
              const SizedBox(height: 10),
              Semantics(
                container: true,
                label: 'Available actions for this YouTube video',
                child: Row(
                  children: [
                    _VideoActionButton(
                      key: const Key('screen04-video-share'),
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onPressed: onShare,
                    ),
                    _VideoActionButton(
                      key: const Key('screen04-video-details'),
                      icon: Icons.help_outline_rounded,
                      label: 'Details',
                      onPressed: onDetails,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (moreVideos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Row(
              children: [
                const Text(
                  'More to watch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${moreVideos.length + 1} videos',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          for (final video in moreVideos)
            _VideoCard(data: video, onTap: () => onSelectVideo(video)),
        ],
      ],
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.data});

  final _VideoData data;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _VideoImage(data: data),
          Positioned(right: 8, bottom: 8, child: _SourcePill(data.duration)),
        ],
      ),
    );
  }
}

class _VideoImage extends StatelessWidget {
  const _VideoImage({required this.data});

  final _VideoData data;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = data.thumbnailUrl;
    if (thumbnailUrl == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.smart_display_outlined,
            color: Colors.white54,
            size: 36,
          ),
        ),
      );
    }
    return Image.network(
      thumbnailUrl.toString(),
      key: Key('screen04-youtube-thumbnail-${data.id}'),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        key: Key('screen04-youtube-thumbnail-unavailable'),
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.smart_display_outlined,
            color: Colors.white54,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _Screen04OfficialYouTubePlayer extends StatefulWidget {
  const _Screen04OfficialYouTubePlayer({
    required this.data,
    required this.onOpenProvider,
    this.isVerifiedVerticalShort = false,
    super.key,
  });

  final _VideoData data;
  final VoidCallback onOpenProvider;
  final bool isVerifiedVerticalShort;

  @override
  State<_Screen04OfficialYouTubePlayer> createState() =>
      _Screen04OfficialYouTubePlayerState();
}

class _Screen04OfficialYouTubePlayerState
    extends State<_Screen04OfficialYouTubePlayer>
    with WidgetsBindingObserver {
  YouTubeEmbeddedPlayerController? _controller;
  bool _selectionFailed = false;
  bool _retryAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      _controller?.onAppActiveChanged(state == AppLifecycleState.resumed) ??
          Future<void>.value(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeController());
    super.dispose();
  }

  Future<void> _disposeController() async {
    try {
      await (_controller?.dispose() ?? Future<void>.value());
    } on Object {
      // The platform view can close its native port before the parent State
      // finishes unmounting. Controller disposal still releases its lease.
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoImage(data: widget.data),
              AndroidYouTubeEmbeddedPlayerSurface(
                onPortReady: (port) {
                  final controller = YouTubeEmbeddedPlayerController(
                    port,
                    YouTubePlayerLease(),
                    config:
                        const YouTubeEmbeddedPlayerFeatureConfig.fromBuildConfiguration(),
                    onSnapshot: (snapshot) {
                      if (!mounted) return;
                      setState(() {
                        _selectionFailed =
                            snapshot.status ==
                            YouTubeEmbeddedPlayerStatus.failed;
                        _retryAvailable = snapshot.failure?.retryable == true;
                      });
                    },
                  );
                  _controller = controller;
                  controller.onReducedMotionChanged(
                    MediaQuery.disableAnimationsOf(context),
                  );
                  unawaited(_select(controller, width));
                },
              ),
              if (_selectionFailed)
                ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.white70,
                            size: 34,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.isVerifiedVerticalShort
                                ? 'This YouTube Short cannot be played here right now.'
                                : 'This video cannot be played here right now.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_retryAvailable)
                                OutlinedButton(
                                  key: const Key(
                                    'screen04-youtube-player-retry',
                                  ),
                                  onPressed: _retry,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  child: const Text('Try again'),
                                ),
                              FilledButton(
                                key: const Key(
                                  'screen04-youtube-player-open-provider',
                                ),
                                onPressed: widget.onOpenProvider,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Open YouTube'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _retry() async {
    final controller = _controller;
    if (controller == null || !_retryAvailable) return;
    setState(() {
      _selectionFailed = false;
      _retryAvailable = false;
    });
    try {
      final retried = await controller.retryPlayerFailureFromUser();
      if (!retried && mounted) {
        setState(() => _selectionFailed = true);
      }
    } on Object {
      if (mounted) setState(() => _selectionFailed = true);
    }
  }

  Future<void> _select(
    YouTubeEmbeddedPlayerController controller,
    double width,
  ) async {
    try {
      final eligibility = await controller.select(
        record: YouTubeEmbeddedVideoRecord(
          videoId: widget.data.providerVideoId!,
          hasCurrentDataApiRecord: true,
          embeddable: widget.data.embeddable,
          hasKnownDeviceRegionExclusion:
              widget.data.hasKnownDeviceRegionExclusion,
          isVerifiedVerticalShort: widget.isVerifiedVerticalShort,
        ),
        availableWidth: width,
      );
      if (!eligibility.eligible && mounted) {
        setState(() {
          _selectionFailed = true;
          _retryAvailable = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _selectionFailed = true;
          _retryAvailable = false;
        });
      }
    }
  }
}

class _VideoProviderLine extends StatelessWidget {
  const _VideoProviderLine({required this.data});

  final _VideoData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _YouTubeAttribution(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${data.duration} · ${data.views} · ${data.published}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoChannelAvatar extends StatelessWidget {
  const _VideoChannelAvatar({required this.data});

  final _VideoData data;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = data.channelThumbnailUrl;
    return CircleAvatar(
      radius: 20,
      backgroundColor: SocialV2Colors.navy,
      foregroundImage: thumbnailUrl == null
          ? null
          : NetworkImage(thumbnailUrl.toString()),
      child: Text(
        _creatorMark(data.channel),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VideoCreatorRow extends StatelessWidget {
  const _VideoCreatorRow({
    required this.data,
    required this.onChannel,
    required this.onOpenChannel,
  });

  final _VideoData data;
  final VoidCallback onChannel;
  final VoidCallback onOpenChannel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _VideoChannelAvatar(data: data),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            key: const Key('screen04-video-channel-details'),
            onTap: onChannel,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.channel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    data.subscribers,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        OutlinedButton(
          key: const Key('screen04-video-channel'),
          onPressed: onOpenChannel,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white38),
            minimumSize: const Size(0, 44),
          ),
          child: const Text('View channel', style: TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}

class _VideoActionButton extends StatelessWidget {
  const _VideoActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF272727),
            side: BorderSide.none,
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(fontSize: 8.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoStatRow extends StatelessWidget {
  const _VideoStatRow({required this.values});

  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.indexed
          .expand((entry) {
            final value = entry.$2;
            return [
              if (entry.$1 > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 74),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: SocialV2Colors.canvas,
                    border: Border.all(color: SocialV2Colors.line),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.$1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SocialV2Colors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SocialV2Colors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          })
          .toList(growable: false),
    );
  }
}

class _VideoChannelIdentity extends StatelessWidget {
  const _VideoChannelIdentity({required this.video, required this.onProvider});

  final _VideoData video;
  final VoidCallback onProvider;

  @override
  Widget build(BuildContext context) {
    return SocialV2Card(
      child: Row(
        children: [
          _VideoChannelAvatar(data: video),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.channel,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  video.subscribers,
                  style: const TextStyle(
                    color: SocialV2Colors.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('screen04-video-channel-videos'),
            onPressed: onProvider,
            child: const Text('Videos'),
          ),
        ],
      ),
    );
  }
}

class _SocialNotificationsPanelV2 extends StatefulWidget {
  const _SocialNotificationsPanelV2({
    required this.session,
    required this.previewOnly,
    required this.onOpen,
  });

  final SharedSession session;
  final bool previewOnly;
  final ValueChanged<SocialNotificationItem> onOpen;

  @override
  State<_SocialNotificationsPanelV2> createState() =>
      _SocialNotificationsPanelV2State();
}

class _SocialNotificationsPanelV2State
    extends State<_SocialNotificationsPanelV2> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.session.loadSocialNotifications(refresh: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final items = widget.session.socialNotifications;
      final loading = widget.session.socialNotificationsLoading;
      final error = widget.session.socialNotificationsError;
      return Column(
        key: const Key('social-notifications-panel'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.previewOnly) ...[
            const SocialV2Notice(
              title: 'Notification preview',
              detail:
                  'Open each destination for review. Read status changes only after sign-in and server confirmation.',
            ),
            const SizedBox(height: 8),
          ],
          if (loading && items.isEmpty)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (items.isEmpty)
            const SocialV2Notice(
              title: 'You’re all caught up',
              detail: 'New Social activity will appear here.',
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SocialV2ListTile(
                  key: Key('social-notification-${item.id}'),
                  icon: switch (item.kind) {
                    SocialNotificationKind.reply =>
                      Icons.chat_bubble_outline_rounded,
                    SocialNotificationKind.reaction =>
                      Icons.favorite_border_rounded,
                    SocialNotificationKind.follow =>
                      Icons.person_add_alt_1_rounded,
                    SocialNotificationKind.messageRequest =>
                      Icons.mark_chat_unread_outlined,
                  },
                  title: item.title,
                  detail:
                      '${item.preview} · ${socialPublishedAgeLabel(item.publishedAt)}',
                  badge: item.read ? 'Read' : 'New',
                  onTap: widget.session.socialNotificationReading(item.id)
                      ? null
                      : () => widget.onOpen(item),
                ),
              ),
          if (error != null) ...[
            SocialV2Notice(
              title: 'Notifications did not refresh',
              detail: error,
              warning: true,
            ),
            const SizedBox(height: 8),
          ],
          if (error != null && items.isEmpty)
            OutlinedButton.icon(
              key: const Key('social-notifications-retry'),
              onPressed: loading
                  ? null
                  : () => widget.session.loadSocialNotifications(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry notifications'),
            ),
          if (items.isNotEmpty && widget.session.socialNotificationsHasMore)
            OutlinedButton.icon(
              key: const Key('social-notifications-load-more'),
              onPressed: loading
                  ? null
                  : widget.session.loadSocialNotifications,
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(loading ? 'Loading updates' : 'Load more'),
            ),
        ],
      );
    },
  );
}

class _SocialSavedPostsPanelV2 extends StatefulWidget {
  const _SocialSavedPostsPanelV2({
    required this.session,
    required this.onOpenPost,
  });

  final SharedSession session;
  final ValueChanged<SocialPublishedItem> onOpenPost;

  @override
  State<_SocialSavedPostsPanelV2> createState() =>
      _SocialSavedPostsPanelV2State();
}

class _SocialSavedPostsPanelV2State extends State<_SocialSavedPostsPanelV2> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.session.loadSavedSocialPosts(refresh: true));
      }
    });
  }

  Future<void> _remove(SocialPublishedItem item) async {
    final removed = await widget.session.toggleSocialSave(item.id);
    if (!mounted || removed) return;
    showSocialV2Message(
      context,
      widget.session.socialInteractionError(item.id) ??
          'This post remains saved. Try again.',
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final posts = widget.session.socialSavedPosts;
      final loading = widget.session.socialSavedLoading;
      final error = widget.session.socialSavedError;
      return Column(
        key: const Key('social-saved-posts-panel'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading && posts.isEmpty)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (posts.isEmpty)
            const SocialV2Notice(
              title: 'No saved posts yet',
              detail:
                  'Use Save on a Feed post to keep it private in this list.',
            )
          else ...[
            for (final item in posts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SocialV2Card(
                  key: Key('social-saved-post-${item.id}'),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.bookmark_rounded,
                            color: SocialV2Colors.navy,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.authorName} · ${item.authorHandle}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SocialV2Colors.navy,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body.isEmpty ? 'Media post' : item.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SocialV2Colors.ink,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            key: Key('social-saved-open-${item.id}'),
                            onPressed: () => widget.onOpenPost(item),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open post'),
                          ),
                          const Spacer(),
                          TextButton(
                            key: Key('social-saved-remove-${item.id}'),
                            onPressed:
                                widget.session.socialInteractionBusy(item.id)
                                ? null
                                : () => unawaited(_remove(item)),
                            child: Text(
                              widget.session.socialInteractionBusy(item.id)
                                  ? 'Removing…'
                                  : 'Remove',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (error != null) ...[
            SocialV2Notice(
              title: 'Saved posts did not refresh',
              detail: error,
              warning: true,
            ),
            const SizedBox(height: 8),
          ],
          if (error != null && posts.isEmpty)
            OutlinedButton.icon(
              key: const Key('social-saved-retry'),
              onPressed: loading
                  ? null
                  : () => widget.session.loadSavedSocialPosts(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry saved posts'),
            ),
          if (posts.isNotEmpty && widget.session.socialSavedHasMore)
            OutlinedButton.icon(
              key: const Key('social-saved-load-more'),
              onPressed: loading ? null : widget.session.loadSavedSocialPosts,
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(loading ? 'Loading posts' : 'Load more'),
            ),
        ],
      );
    },
  );
}

class _SocialPostDetailV2 extends StatefulWidget {
  const _SocialPostDetailV2({
    required this.item,
    required this.session,
    required this.authenticated,
    required this.focusReplies,
    required this.onOpenAuthor,
    required this.onMore,
    required this.onRelationship,
    required this.onShare,
    required this.onAuthenticationRequired,
  });

  final SocialPublishedItem item;
  final SharedSession session;
  final bool authenticated;
  final bool focusReplies;
  final VoidCallback onOpenAuthor;
  final VoidCallback onMore;
  final VoidCallback onRelationship;
  final VoidCallback onShare;
  final ValueChanged<SocialProtectedActionIntent> onAuthenticationRequired;

  @override
  State<_SocialPostDetailV2> createState() => _SocialPostDetailV2State();
}

class _SocialPostDetailV2State extends State<_SocialPostDetailV2> {
  final GlobalKey _repliesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusReplies) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showReplies());
    }
  }

  void _showReplies() {
    final repliesContext = _repliesKey.currentContext;
    if (!mounted || repliesContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        repliesContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: .08,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final liveItem = widget.session.socialPublishedItems
          .where((candidate) => candidate.id == widget.item.id)
          .firstOrNull;
      final item = liveItem ?? widget.item;
      final authorId = item.authorId;
      return Column(
        key: Key('social-post-detail-${item.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SocialPublishedContentCardV2(
            item: item,
            session: widget.session,
            onOpenAuthor: (_) => widget.onOpenAuthor(),
            onMore: (_) => widget.onMore(),
            onRelationship: (_) => widget.onRelationship(),
            followed: authorId == null
                ? null
                : widget.session.socialAuthorProfile(authorId)?.followed,
            relationshipBusy:
                authorId != null &&
                (widget.session.socialAuthorLoading(authorId) ||
                    widget.session.socialFollowBusy(authorId)),
            onReply: _showReplies,
            onShare: widget.onShare,
            onAuthenticationRequired: widget.onAuthenticationRequired,
          ),
          const SizedBox(height: 14),
          Text(
            'Conversation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: SocialV2Colors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          KeyedSubtree(
            key: _repliesKey,
            child: _SocialCommentsPanelV2(
              item: item,
              session: widget.session,
              authenticated: widget.authenticated,
              onAuthenticationRequired: () => widget.onAuthenticationRequired(
                const SocialProtectedActionIntent(
                  action: SocialProtectedAction.reply,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SocialAuthorPanelV2 extends StatefulWidget {
  const _SocialAuthorPanelV2({
    required this.sourceItem,
    required this.session,
    required this.authenticated,
    required this.onRequestMessage,
    required this.onAuthenticationRequired,
  });

  final SocialPublishedItem sourceItem;
  final SharedSession session;
  final bool authenticated;
  final VoidCallback onRequestMessage;
  final VoidCallback onAuthenticationRequired;

  @override
  State<_SocialAuthorPanelV2> createState() => _SocialAuthorPanelV2State();
}

class _SocialAuthorPanelV2State extends State<_SocialAuthorPanelV2> {
  String get _authorId => widget.sourceItem.authorId!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          widget.session.loadSocialAuthor(
            _authorId,
            authenticated: widget.authenticated,
          ),
        );
      }
    });
  }

  Future<void> _toggleFollow(SocialAuthorProfile profile) async {
    if (!widget.authenticated) {
      widget.onAuthenticationRequired();
      return;
    }
    await widget.session.setSocialFollow(_authorId, !profile.followed);
  }

  Future<void> _openPaidFollow(SocialAuthorProfile profile) async {
    final price = profile.paidFollowMonthlyPrice;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: Key('social-author-paid-follow-dialog-$_authorId'),
        title: Text(
          price == null
              ? 'Creator membership is not offered'
              : 'Join for ₹$price per month?',
        ),
        content: Text(
          price == null
              ? 'You can still follow public updates. This creator has not enabled a paid following option.'
              : 'Paid following requires a live creator offering, payment and entitlement confirmation. Those services are unavailable right now, so nothing will be charged.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlock(SocialAuthorProfile profile) async {
    if (!widget.authenticated) {
      widget.onAuthenticationRequired();
      return;
    }
    final blocked = widget.session.socialAuthorBlocked(_authorId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: Key('social-author-block-confirm-$_authorId'),
        title: Text(
          blocked
              ? 'Unblock ${profile.authorName}?'
              : 'Block ${profile.authorName}?',
        ),
        content: Text(
          blocked
              ? 'Their public posts can appear again. Private messages still follow your message-request settings.'
              : 'Their posts leave your Feed and Discover. They cannot start a new conversation with you while blocked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const Key('social-author-block-save'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(blocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final saved = await widget.session.setSocialAuthorBlocked(
      _authorId,
      !blocked,
    );
    if (!mounted || saved) return;
    showSocialV2Message(
      context,
      widget.session.socialBlockError(_authorId) ??
          'The block setting did not change.',
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final profile = widget.session.socialAuthorProfile(_authorId);
      final loading = widget.session.socialAuthorLoading(_authorId);
      final followBusy = widget.session.socialFollowBusy(_authorId);
      final blocked = widget.session.socialAuthorBlocked(_authorId);
      final blockBusy = widget.session.socialBlockBusy(_authorId);
      final error =
          widget.session.socialBlockError(_authorId) ??
          widget.session.socialAuthorError(_authorId);
      return Column(
        key: Key('social-author-panel-$_authorId'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile == null && loading)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (profile == null)
            SocialV2Notice(
              title: 'Author profile unavailable',
              detail:
                  error ?? 'This public author profile could not be loaded.',
              warning: true,
            )
          else ...[
            SocialV2Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: SocialV2Colors.navy,
                        foregroundColor: Colors.white,
                        child: Text(
                          profile.authorName
                              .split(RegExp(r'\s+'))
                              .where((part) => part.isNotEmpty)
                              .take(2)
                              .map((part) => part[0])
                              .join()
                              .toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.authorName,
                              style: const TextStyle(
                                color: SocialV2Colors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              profile.authorHandle,
                              style: const TextStyle(
                                color: SocialV2Colors.muted,
                              ),
                            ),
                            Text(
                              '${profile.followerCount} followers · ${profile.posts.length} public posts',
                              style: const TextStyle(
                                color: SocialV2Colors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!profile.isSelf) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            key: Key('social-author-follow-$_authorId'),
                            onPressed: followBusy || blocked
                                ? null
                                : () => _toggleFollow(profile),
                            child: Text(
                              blocked
                                  ? 'Blocked'
                                  : followBusy
                                  ? 'Updating…'
                                  : profile.followed
                                  ? 'Unfollow'
                                  : widget.authenticated
                                  ? 'Follow'
                                  : 'Sign in to follow',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: Key(
                              'social-author-message-request-$_authorId',
                            ),
                            onPressed: blocked ? null : widget.onRequestMessage,
                            icon: const Icon(
                              Icons.mark_chat_unread_outlined,
                              size: 18,
                            ),
                            label: Text(
                              blocked
                                  ? 'Blocked'
                                  : widget.authenticated
                                  ? 'Request chat'
                                  : 'Sign in to message',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: Key('social-author-block-$_authorId'),
                        onPressed: blockBusy
                            ? null
                            : () => _toggleBlock(profile),
                        icon: Icon(
                          blocked
                              ? Icons.lock_open_rounded
                              : Icons.block_rounded,
                        ),
                        label: Text(
                          blockBusy
                              ? 'Updating…'
                              : blocked
                              ? 'Unblock profile'
                              : 'Block profile',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SocialProfileStatusCardV2(
              authorId: _authorId,
              status: profile.publicStatus,
            ),
            const SizedBox(height: 8),
            SocialV2Card(
              key: Key('social-author-paid-follow-$_authorId'),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1D6),
                    foregroundColor: SocialV2Colors.navy,
                    child: Icon(Icons.workspace_premium_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Creator membership',
                          style: TextStyle(
                            color: SocialV2Colors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          profile.paidFollowAvailable
                              ? '₹${profile.paidFollowMonthlyPrice} per month · ${profile.paidFollowBenefits.isEmpty ? 'creator benefits' : profile.paidFollowBenefits.join(' · ')}'
                              : 'Follow public updates free. Paid following is not offered by this creator.',
                          style: const TextStyle(
                            color: SocialV2Colors.muted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: Key('social-author-paid-follow-action-$_authorId'),
                    onPressed: () => _openPaidFollow(profile),
                    child: Text(
                      profile.paidFollowAvailable ? 'View' : 'Details',
                    ),
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              SocialV2Notice(
                title: 'Relationship not changed',
                detail: error,
                warning: true,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Public posts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SocialV2Colors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (final post in profile.posts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SocialV2Card(
                  key: Key('social-author-post-${post.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.body.isEmpty ? post.type.name : post.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post.likeCount} likes · ${post.replyCount} replies · ${socialPublishedAgeLabel(post.publishedAt)}',
                        style: const TextStyle(
                          color: SocialV2Colors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (profile == null && !loading)
            OutlinedButton.icon(
              key: Key('social-author-retry-$_authorId'),
              onPressed: () => widget.session.loadSocialAuthor(
                _authorId,
                authenticated: widget.authenticated,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry profile'),
            ),
        ],
      );
    },
  );
}

class _SocialProfileStatusCardV2 extends StatelessWidget {
  const _SocialProfileStatusCardV2({
    required this.authorId,
    required this.status,
  });

  final String authorId;
  final SocialPublicProfileStatus? status;

  @override
  Widget build(BuildContext context) {
    final value = status;
    return SocialV2Card(
      key: Key('social-author-status-$authorId'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEDE8FF),
                foregroundColor: SocialV2Colors.navy,
                child: Icon(Icons.insights_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value?.publicLabel ?? 'Public profile',
                      style: const TextStyle(
                        color: SocialV2Colors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      value?.publicSummary ??
                          'Public status details are unavailable right now.',
                      style: const TextStyle(
                        color: SocialV2Colors.muted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            value == null
                ? 'Earning status unavailable'
                : _socialEarningStateLabel(value.earningState),
            style: const TextStyle(
              color: SocialV2Colors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value?.earningSummary ??
                'MoolSocial has not supplied an earning program status for this profile.',
            style: const TextStyle(
              color: SocialV2Colors.muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          if (value != null && value.criteria.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final criterion in value.criteria)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      criterion.met
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: criterion.met
                          ? SocialV2Colors.green
                          : SocialV2Colors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${criterion.label} · ${criterion.detail}',
                        style: const TextStyle(
                          color: SocialV2Colors.ink,
                          fontSize: 11,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String _socialEarningStateLabel(SocialEarningState state) => switch (state) {
  SocialEarningState.unavailable => 'Earning program unavailable',
  SocialEarningState.building => 'Building earning readiness',
  SocialEarningState.eligible => 'Eligible to apply',
  SocialEarningState.active => 'Earning program active',
};

class _SocialCommentsPanelV2 extends StatefulWidget {
  const _SocialCommentsPanelV2({
    required this.item,
    required this.session,
    required this.authenticated,
    required this.onAuthenticationRequired,
  });

  final SocialPublishedItem item;
  final SharedSession session;
  final bool authenticated;
  final VoidCallback onAuthenticationRequired;

  @override
  State<_SocialCommentsPanelV2> createState() => _SocialCommentsPanelV2State();
}

class _SocialCommentsPanelV2State extends State<_SocialCommentsPanelV2> {
  late final TextEditingController _replyController;
  late final FocusNode _replyFocusNode;
  final GlobalKey _replySubmitRevealKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController(
      text: widget.session.socialReplyDraft(widget.item.id),
    )..addListener(_saveDraft);
    _replyFocusNode = FocusNode()..addListener(_handleReplyFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.session.socialCommentsLoaded(widget.item.id)) {
        unawaited(
          widget.session.loadSocialComments(widget.item.id, refresh: true),
        );
      }
    });
  }

  void _saveDraft() {
    widget.session.saveSocialReplyDraft(widget.item.id, _replyController.text);
  }

  void _handleReplyFocus() {
    if (mounted) setState(() {});
    if (!_replyFocusNode.hasFocus) return;
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      final submitContext = _replySubmitRevealKey.currentContext;
      if (submitContext == null ||
          !submitContext.mounted ||
          !_replyFocusNode.hasFocus) {
        return;
      }
      final scrollable = Scrollable.maybeOf(submitContext);
      if (scrollable == null) return;
      unawaited(
        scrollable.position.animateTo(
          scrollable.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  void dispose() {
    _replyController.removeListener(_saveDraft);
    _replyController.dispose();
    _replyFocusNode
      ..removeListener(_handleReplyFocus)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.authenticated) {
      widget.onAuthenticationRequired();
      return;
    }
    final posted = await widget.session.postSocialReply(
      widget.item.id,
      _replyController.text,
    );
    if (!mounted || !posted) return;
    _replyFocusNode.unfocus();
    _replyController.clear();
  }

  Widget _buildReplyContext() {
    final item = widget.item;
    return Container(
      key: Key('social-reply-context-${item.id}'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCD5FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.reply_rounded, color: SocialV2Colors.navy, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${item.authorName} · ${item.authorHandle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.body.trim().isEmpty ? 'Public post' : item.body.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SocialV2Colors.muted,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final postId = widget.item.id;
        final comments = widget.session.socialComments(postId);
        final loading = widget.session.socialCommentsLoading(postId);
        final loaded = widget.session.socialCommentsLoaded(postId);
        final posting = widget.session.socialReplyBusy(postId);
        final error = widget.session.socialCommentError(postId);
        final composing = _replyFocusNode.hasFocus;
        return Column(
          key: Key('social-comments-panel-$postId'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!composing && loading && !loaded)
              const Center(child: CircularProgressIndicator.adaptive())
            else if (!composing && comments.isEmpty)
              const SocialV2Notice(
                title: 'No replies yet',
                detail: 'Be the first to add a respectful public reply.',
              )
            else if (!composing)
              for (final comment in comments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SocialV2Card(
                    key: Key('social-comment-${comment.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${comment.authorName} · ${comment.authorHandle}',
                          style: const TextStyle(
                            color: SocialV2Colors.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(comment.body),
                        const SizedBox(height: 4),
                        Text(
                          socialPublishedAgeLabel(comment.publishedAt),
                          style: const TextStyle(
                            color: SocialV2Colors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (!composing && error != null) ...[
              SocialV2Notice(
                title: 'Reply not completed',
                detail: error,
                warning: true,
              ),
              const SizedBox(height: 8),
            ],
            if (!composing &&
                loaded &&
                widget.session.socialCommentsHasMore(postId))
              OutlinedButton.icon(
                key: Key('social-comments-more-$postId'),
                onPressed: loading
                    ? null
                    : () => widget.session.loadSocialComments(postId),
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load older replies'),
              ),
            if (!composing && error != null && !loaded)
              OutlinedButton.icon(
                key: Key('social-comments-retry-$postId'),
                onPressed: loading
                    ? null
                    : () => widget.session.loadSocialComments(
                        postId,
                        refresh: true,
                      ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry replies'),
              ),
            const Divider(height: 24),
            if (composing) ...[
              _buildReplyContext(),
              const SizedBox(height: 10),
            ],
            TextField(
              key: Key('social-reply-field-$postId'),
              controller: _replyController,
              focusNode: _replyFocusNode,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              scrollPadding: const EdgeInsets.only(bottom: 168),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Write a public reply',
                hintText: 'Keep the conversation useful and respectful',
              ),
            ),
            KeyedSubtree(
              key: _replySubmitRevealKey,
              child: FilledButton.icon(
                key: Key('social-reply-submit-$postId'),
                onPressed: posting ? null : _submit,
                icon: Icon(
                  widget.authenticated
                      ? Icons.send_rounded
                      : Icons.login_rounded,
                ),
                label: Text(
                  posting
                      ? 'Posting…'
                      : widget.authenticated
                      ? 'Post reply'
                      : 'Sign in to reply',
                ),
              ),
            ),
            const SizedBox(height: 72),
          ],
        );
      },
    );
  }
}
