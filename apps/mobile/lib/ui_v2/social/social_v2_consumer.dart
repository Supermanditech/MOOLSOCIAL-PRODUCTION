import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/youtube/youtube_embedded_player_android.dart';
import '../../core/youtube/youtube_embedded_player_contract.dart';
import '../../core/youtube/youtube_embedded_player_controller.dart';
import '../../core/youtube/youtube_private_dev_app_check.dart';
import '../../features/creator/creator_session.dart';
import '../../features/journey01/journey_session.dart';
import '../../features/retailer/retailer_session.dart';
import '../../features/shared/shared_models.dart';
import '../../features/shared/shared_session.dart';
import '../../features/shared/social_media_picker.dart';
import 'social_v2_create_workbench.dart';
import 'social_v2_creator.dart';
import 'social_v2_design.dart';
import 'social_v2_plans_promotion.dart';
import 'social_v2_public_content.dart';
import 'social_v2_youtube_public_runtime.dart';
import 'screen04_universal_components.dart';

class SocialUniversalV2 extends StatefulWidget {
  const SocialUniversalV2({
    required this.session,
    required this.creatorSession,
    required this.retailerSession,
    required this.sharedSession,
    this.initialSubAction,
    this.initialState,
    this.initialItem,
    this.initialWorld = 'social',
    this.mediaPicker,
    super.key,
  });

  final JourneySession session;
  final CreatorSession creatorSession;
  final RetailerSession retailerSession;
  final SharedSession sharedSession;
  final String? initialSubAction;
  final String? initialState;
  final String? initialItem;
  final String initialWorld;
  final SocialMediaPicker? mediaPicker;

  @override
  State<SocialUniversalV2> createState() => _SocialUniversalV2State();
}

class _SocialUniversalV2State extends State<SocialUniversalV2> {
  late SocialV2Tab _tab;
  late String _world;
  late final Map<String, String> _choiceByWorld;
  bool _moolOpen = false;

  String _shortMode = youtubePrivateDevProofEnabled ? 'YouTube' : 'For You';
  final String _videoMode = 'All';
  String _feedMode = 'For You';
  late String _createView;
  late bool _contentUnavailable;
  bool _liked = false;
  bool _saved = false;
  bool _followed = false;
  bool _shortChromeVisible = true;
  bool _shortPlaying = false;
  bool _shortDetailsExpanded = false;
  int _activeShortPage = 0;
  late final PageController _shortController;
  late final ScrollController _videoHomeController;
  late final ScrollController _videoWatchController;
  late final SocialMediaPicker _mediaPicker;
  final TextEditingController _quickPostController = TextEditingController();
  final TextEditingController _quickPollFirstController =
      TextEditingController();
  final TextEditingController _quickPollSecondController =
      TextEditingController();
  SocialPickedMedia? _quickPostMedia;
  bool _quickPostPoll = false;
  _VideoData? _activeVideo;
  bool _activeVideoSaved = false;
  String _videoQuery = '';
  int _visibleVideoCount = 3;
  double _videoHomeScrollOffset = 0;
  List<_VideoData> _liveYouTubeVideos = const [];
  List<_ShortData> _liveYouTubeShorts = const [];
  bool _liveYouTubeLoading = youtubePrivateDevProofEnabled;
  String? _liveYouTubeError;
  bool _liveYouTubeShortsLoading = youtubePrivateDevProofEnabled;
  String? _liveYouTubeShortsError;

  static SocialV2Tab _tabFor(String? subAction) => switch (subAction) {
    'videos' => SocialV2Tab.videos,
    'feed' => SocialV2Tab.feed,
    'create' => SocialV2Tab.create,
    _ => SocialV2Tab.shorts,
  };

  static String _createViewFor(String? state) => switch (state) {
    'post' ||
    'reel-source' ||
    'reel-camera' ||
    'reel-edit' ||
    'carousel' ||
    'drafts' ||
    'publishing' ||
    'failure' ||
    'success' => state!,
    _ => 'home',
  };

  @override
  void initState() {
    super.initState();
    _shortController = PageController();
    _videoHomeController = ScrollController();
    _videoWatchController = ScrollController();
    _mediaPicker = widget.mediaPicker ?? NativeSocialMediaPicker();
    _world = screen04Worlds.any((world) => world.id == widget.initialWorld)
        ? widget.initialWorld
        : 'social';
    _choiceByWorld = {
      for (final world in screen04Worlds) world.id: world.choices.first.id,
    };
    if (widget.initialSubAction case final subAction?) {
      final activeWorld = screen04World(_world);
      if (activeWorld.choices.any((choice) => choice.id == subAction)) {
        _choiceByWorld[_world] = subAction;
      }
    }
    _tab = _world == 'social'
        ? _tabFor(_choiceByWorld['social'])
        : SocialV2Tab.shorts;
    _createView = _createViewFor(widget.initialState);
    _contentUnavailable = widget.initialState == 'unavailable';
    _activeVideo =
        _tab == SocialV2Tab.videos && widget.initialState == 'video-watch'
        ? _videoForId(widget.initialItem)
        : null;
    if (widget.initialState == 'promoted') {
      _shortMode = 'Promoted';
      _feedMode = 'Promoted';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _world == 'social' && _tab == SocialV2Tab.shorts) {
        _showShortChrome();
      }
    });
    if (youtubePrivateDevProofEnabled) {
      unawaited(_loadLiveYouTubeVideos());
    }
  }

  @override
  void dispose() {
    _shortController.dispose();
    _videoHomeController.dispose();
    _videoWatchController.dispose();
    _quickPostController.dispose();
    _quickPollFirstController.dispose();
    _quickPollSecondController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SocialUniversalV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubAction != widget.initialSubAction ||
        oldWidget.initialState != widget.initialState ||
        oldWidget.initialItem != widget.initialItem ||
        oldWidget.initialWorld != widget.initialWorld) {
      _world = screen04Worlds.any((world) => world.id == widget.initialWorld)
          ? widget.initialWorld
          : 'social';
      final activeWorld = screen04World(_world);
      final requestedChoice = widget.initialSubAction;
      _choiceByWorld[_world] =
          requestedChoice != null &&
              activeWorld.choices.any((choice) => choice.id == requestedChoice)
          ? requestedChoice
          : activeWorld.choices.first.id;
      _tab = _world == 'social'
          ? _tabFor(_choiceByWorld['social'])
          : SocialV2Tab.shorts;
      _createView = _tab == SocialV2Tab.create
          ? _createViewFor(widget.initialState)
          : 'home';
      _contentUnavailable = widget.initialState == 'unavailable';
      _activeVideo =
          _tab == SocialV2Tab.videos && widget.initialState == 'video-watch'
          ? _videoForId(widget.initialItem)
          : null;
      _activeVideoSaved = false;
      _shortMode = widget.initialState == 'promoted'
          ? 'Promoted'
          : (youtubePrivateDevProofEnabled ? 'YouTube' : 'For You');
      _feedMode = widget.initialState == 'promoted' ? 'Promoted' : 'For You';
      _resetShorts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final requestedTextScale = media.textScaler.scale(1);
    final maximumTextScale = switch (media.size.width) {
      <= 340 => 1.0,
      <= 375 => 1.1,
      <= 412 => 1.2,
      <= 430 => 1.3,
      _ => requestedTextScale,
    };
    final effectiveTextScale = requestedTextScale > maximumTextScale
        ? maximumTextScale
        : requestedTextScale;
    final world = screen04World(_world);
    final choice = _choiceByWorld[_world] ?? world.choices.first.id;
    final immersive = _world == 'social' && choice == 'shorts';
    final area =
        widget.session.currentAreaPrimary ??
        widget.session.manualArea?.split(',').first.trim() ??
        'Khema-Ka-Kuwa';

    final hasInlineBack = _activeVideo != null || !_moolOpen;

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(effectiveTextScale)),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: SocialV2Colors.navy,
            secondary: SocialV2Colors.green,
            surfaceTint: Colors.transparent,
          ),
        ),
        child: PopScope<Object?>(
          canPop: !hasInlineBack,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleScreen04Back();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: SocialV2Colors.navy,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: Scaffold(
              key: const Key('screen04-universal-v2'),
              backgroundColor: SocialV2Colors.canvas,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (_world == 'social' && _tab == SocialV2Tab.videos)
                      Screen04VideoHeader(
                        key: ValueKey(
                          'screen04-video-header-${_activeVideo?.id ?? 'discovery'}',
                        ),
                        onHome: () => _selectWorld('social'),
                        onNotifications: _openUniversalNotifications,
                        onProfile: _openAccount,
                        initialQuery: _videoQuery,
                        onQueryChanged: (query) => setState(() {
                          _videoQuery = query.trim();
                          _visibleVideoCount = 3;
                        }),
                      )
                    else
                      Screen04Header(
                        area: area,
                        prompt: world.prompt,
                        immersive: immersive,
                        onHome: () => _selectWorld('social'),
                        onArea: _openServiceableArea,
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
                                '${_tab.name}-$_createView-${_activeVideo?.id ?? 'home'}',
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
                              onPrimary: () => _openWorldDestination(choice),
                              onPlacement: (title) =>
                                  _openWorldDestination(choice, detail: title),
                              onContextAction: (action) =>
                                  _runContextAction(action, choice),
                            ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: Screen04CapabilityRail(
                world: world,
                choice: choice,
                moolOpen: _moolOpen,
                onMool: () => setState(() => _moolOpen = !_moolOpen),
                onWorld: _selectWorld,
                onChoice: _selectChoice,
                onChat: _openChat,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleScreen04Back() {
    if (_activeVideo != null) {
      final restoreOffset = _videoHomeScrollOffset;
      setState(() {
        _activeVideo = null;
        _activeVideoSaved = false;
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
    if (!_moolOpen) {
      setState(() => _moolOpen = true);
      HapticFeedback.selectionClick();
    }
  }

  void _selectWorld(String worldId) {
    if (!screen04Worlds.any((world) => world.id == worldId)) return;
    if (worldId == 'buy') {
      HapticFeedback.selectionClick();
      context.push('/app/buy');
      return;
    }
    setState(() {
      _world = worldId;
      _moolOpen = false;
      _activeVideo = null;
      _activeVideoSaved = false;
      if (worldId == 'social') {
        _tab = _tabFor(_choiceByWorld['social']);
        if (_tab == SocialV2Tab.shorts) _showShortChrome();
      }
    });
  }

  void _selectChoice(String choiceId) {
    final world = screen04World(_world);
    if (!world.choices.any((choice) => choice.id == choiceId)) return;
    setState(() {
      _choiceByWorld[_world] = choiceId;
      _activeVideo = null;
      _activeVideoSaved = false;
      if (_world == 'social') {
        _tab = _tabFor(choiceId);
        if (_tab == SocialV2Tab.videos) _videoQuery = '';
        if (_tab != SocialV2Tab.create) _createView = 'home';
        if (_tab == SocialV2Tab.shorts) {
          _resetShorts();
        }
      }
    });
  }

  void _openVideoFromDiscovery(_VideoData video) {
    if (_videoHomeController.hasClients) {
      _videoHomeScrollOffset = _videoHomeController.offset;
    }
    setState(() {
      _activeVideo = video;
      _activeVideoSaved = false;
      if (_videoWatchController.hasClients) {
        _videoWatchController.jumpTo(0);
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _loadLiveYouTubeVideos() async {
    if (!youtubePrivateDevProofEnabled) return;
    setState(() {
      _liveYouTubeLoading = true;
      _liveYouTubeError = null;
      _liveYouTubeShortsLoading = true;
      _liveYouTubeShortsError = null;
    });
    List<Screen04YouTubePublicVideo> videos = const [];
    List<Screen04YouTubePublicVideo> shorts = const [];
    Object? videosFailure;
    Object? shortsFailure;
    await Future.wait([
      () async {
        try {
          videos = await loadScreen04YouTubePublicVideos();
        } on Object catch (error) {
          videosFailure = error;
        }
      }(),
      () async {
        try {
          shorts = await loadScreen04YouTubePublicShorts();
        } on Object catch (error) {
          shortsFailure = error;
        }
      }(),
    ]);
    if (!mounted) return;
    setState(() {
      _liveYouTubeVideos = videos
          .map(_videoDataFromProvider)
          .toList(growable: false);
      _liveYouTubeShorts = shorts
          .map(_shortDataFromProvider)
          .toList(growable: false);
      _liveYouTubeLoading = false;
      _liveYouTubeShortsLoading = false;
      _liveYouTubeError = videosFailure == null
          ? null
          : 'Videos are unavailable right now. Please try again.';
      _liveYouTubeShortsError = shortsFailure == null
          ? null
          : 'YouTube Shorts are unavailable right now. Please try again.';
      _visibleVideoCount = 3;
    });
  }

  void _openWorldDestination(String choice, {String? detail}) {
    final route = switch (choice) {
      'grocery' || 'categories' => '/app/buy/grocery',
      'medicine' => '/app/buy/medicine',
      'basket' => '/app/buy/basket',
      'order-food' => '/app/eat/home',
      'book-table' => '/app/eat/table',
      'tiffin' => '/app/eat/tiffin',
      'bike' || 'auto' || 'cab' => '/app/ride/book?type=$choice',
      'get-done' => '/app/book/home',
      'doctor' => '/app/book/doctor',
      'salon' => '/app/book/salon',
      'recharge' => '/app/pay/recharge',
      'bills' => '/app/pay/bills',
      'scan-pay' => '/app/pay/scan',
      'receipts' => '/app/pay/receipts',
      'earn-today' => '/app/work/earn',
      'delivery' => '/app/work/opportunity/delivery',
      'onboard' => '/app/work/choose',
      'verify' => '/app/work/proof',
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
        _openShare();
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
    final world = screen04World(_world);
    final choice = _choiceByWorld[_world] ?? world.choices.first.id;
    final returnQuery = <String, String>{
      'world': world.id,
      'sub': choice,
      if (_activeVideo case final video?) ...{
        'state': 'video-watch',
        'item': video.id,
      },
    };
    final returnRoute = Uri(
      path: '/app/social',
      queryParameters: returnQuery,
    ).toString();
    context.push(
      Uri(
        path: '/app/chat',
        queryParameters: {'return': returnRoute},
      ).toString(),
    );
  }

  void _openUniversalNotifications() {
    showSocialV2Sheet(
      context,
      title: 'Notifications',
      subtitle: 'Your recent activity',
      children: [
        const SocialV2Notice(
          title: 'You’re all caught up',
          detail:
              'New account, order, work and Social updates will appear here.',
        ),
        OutlinedButton.icon(
          onPressed: _openNotificationSettings,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Notification settings'),
        ),
      ],
    );
  }

  void _openAccount() {
    showSocialV2Sheet(
      context,
      title: 'Your MoolSocial account',
      subtitle: 'Profile, language and account safety',
      children: [
        SocialV2ListTile(
          icon: Icons.location_on_outlined,
          title: 'Serviceable area',
          detail:
              widget.session.currentAreaLabel ??
              widget.session.manualArea ??
              'Choose where you want nearby services',
          onTap: () {
            Navigator.of(context).pop();
            _openServiceableArea();
          },
        ),
        SocialV2ListTile(
          icon: Icons.language_rounded,
          title: 'Language',
          detail: 'English',
          onTap: () {
            Navigator.of(context).pop();
            _openLanguage();
          },
        ),
        SocialV2ListTile(
          icon: Icons.workspace_premium_outlined,
          title: 'Creator workspace',
          detail: 'Create, publish, distribute and track earnings',
          onTap: () {
            Navigator.of(context).pop();
            _openCreatorStudio();
          },
        ),
        SocialV2ListTile(
          icon: Icons.card_membership_outlined,
          title: 'Plans & access',
          detail: 'Features, launch access and billing',
          onTap: () {
            Navigator.of(context).pop();
            _openPlans();
          },
        ),
        SocialV2ListTile(
          icon: Icons.shield_outlined,
          title: 'Account and safety',
          detail: 'Sign-in, privacy and support',
          onTap: () {
            Navigator.of(context).pop();
            context.push('/app/account/security');
          },
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/sign-in?intent=sign-out');
          },
          child: const Text('Sign out'),
        ),
      ],
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
    var orders = true;
    var work = true;
    var social = true;
    Navigator.of(context).pop();
    showSocialV2Sheet(
      context,
      title: 'Notification settings',
      subtitle: 'Choose the updates you want to receive',
      children: [
        StatefulBuilder(
          builder: (context, setSheetState) => Column(
            children: [
              SwitchListTile(
                value: orders,
                onChanged: (value) => setSheetState(() => orders = value),
                title: const Text('Orders and bookings'),
              ),
              SwitchListTile(
                value: work,
                onChanged: (value) => setSheetState(() => work = value),
                title: const Text('Work and earnings'),
              ),
              SwitchListTile(
                value: social,
                onChanged: (value) => setSheetState(() => social = value),
                title: const Text('Social activity'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openLanguage() {
    showSocialV2Sheet(
      context,
      title: 'Language',
      subtitle: 'Choose your MoolSocial language',
      children: ['English', 'हिन्दी', 'मराठी', 'ગુજરાતી']
          .map(
            (language) => SocialV2ListTile(
              icon: language == 'English'
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              title: language,
              detail: language == 'English' ? 'Selected' : 'Choose language',
              onTap: () => Navigator.of(context).pop(),
            ),
          )
          .toList(growable: false),
    );
  }

  void _openCreatorStudio() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatorSocialV2Screen(
          session: widget.creatorSession,
          owner: CreatorSocialV2Owner.home,
        ),
      ),
    );
  }

  void _openPlans() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SocialPlansV2Screen(
          sharedSession: widget.sharedSession,
          retailerSession: widget.retailerSession,
          creatorSession: widget.creatorSession,
        ),
      ),
    );
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
    if (_contentUnavailable) return _unavailable('Short');
    if (youtubePrivateDevProofEnabled &&
        _liveYouTubeShortsLoading &&
        _shortMode == 'YouTube') {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Loading YouTube Shorts',
              style: TextStyle(
                color: SocialV2Colors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    if (youtubePrivateDevProofEnabled &&
        _liveYouTubeShortsError != null &&
        _shortMode == 'YouTube') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_collection_outlined,
                color: SocialV2Colors.navy,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                _liveYouTubeShortsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SocialV2Colors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadLiveYouTubeVideos,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: widget.sharedSession,
      builder: (context, _) {
        final publishedReels = widget.sharedSession.socialPublishedItems
            .where((item) => item.type == SocialPublishedContentType.reel)
            .toList(growable: false);
        final reels = _shortsForMode(_shortMode);
        final total = publishedReels.length + reels.length;
        return PageView.builder(
          key: const Key('screen04-shorts-page-view'),
          controller: _shortController,
          scrollDirection: Axis.vertical,
          itemCount: total,
          onPageChanged: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _shortChromeVisible = true;
              _shortPlaying = false;
              _shortDetailsExpanded = false;
              _activeShortPage = index;
            });
          },
          itemBuilder: (context, index) {
            if (index < publishedReels.length) {
              final item = publishedReels[index];
              return SocialPublishedReelV2(
                item: item,
                session: widget.sharedSession,
                onComment: () => _openComments(item.body),
                onShare: _openShare,
              );
            }
            final reel = reels[index - publishedReels.length];
            return reel.youtube
                ? _buildYouTubeShort(
                    reel,
                    index + 1,
                    total,
                    active: index == _activeShortPage,
                  )
                : _buildMoolSocialReel(reel, index + 1, total);
          },
        );
      },
    );
  }

  void _selectShortMode(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      _shortMode = value;
      _shortChromeVisible = true;
      _shortPlaying = false;
      _shortDetailsExpanded = false;
      _activeShortPage = 0;
    });
    if (_shortController.hasClients) _shortController.jumpToPage(0);
  }

  List<_ShortData> _shortsForMode(String mode) {
    if (youtubePrivateDevProofEnabled) {
      if (mode == 'YouTube') return _liveYouTubeShorts;
      final nativeShorts = _screen04Shorts
          .where((reel) => !reel.youtube)
          .toList(growable: false);
      final modeId = switch (mode) {
        'Following' => 'following',
        'Nearby' => 'nearby',
        'Promoted' => 'promoted',
        _ => 'for-you',
      };
      final filteredNative = nativeShorts
          .where((reel) => reel.modes.contains(modeId))
          .toList(growable: false);
      return filteredNative;
    }
    final modeId = switch (mode) {
      'YouTube' => 'youtube',
      'Following' => 'following',
      'Nearby' => 'nearby',
      'Promoted' => 'promoted',
      _ => 'for-you',
    };
    final filtered = mode == 'YouTube'
        ? _screen04Shorts.where((reel) => reel.youtube).toList(growable: false)
        : _screen04Shorts
              .where((reel) => reel.modes.contains(modeId))
              .toList(growable: false);
    return filtered.isEmpty ? _screen04Shorts : filtered;
  }

  void _resetShorts() {
    _shortChromeVisible = true;
    _shortPlaying = false;
    _shortDetailsExpanded = false;
    _activeShortPage = 0;
    if (_shortController.hasClients) _shortController.jumpToPage(0);
  }

  void _showShortChrome() {
    if (!mounted) return;
    setState(() => _shortChromeVisible = true);
  }

  void _toggleShortChrome() {
    setState(() => _shortChromeVisible = !_shortChromeVisible);
  }

  Widget _buildMoolSocialReel(_ShortData reel, int position, int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compact =
            constraints.maxHeight < 545 ||
            (textScale >= 1.25 && constraints.maxHeight < 700);
        final chrome = _shortChromeVisible;
        return GestureDetector(
          key: Key('screen04-short-${reel.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: _toggleShortChrome,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Image(
                key: Key('screen04-short-media-moolsocial'),
                image: AssetImage('assets/prototype/social-market-grocery.png'),
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000020),
                      Color(0x10000020),
                      Color(0xF2000018),
                    ],
                    stops: [0, .38, 1],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  offset: chrome ? Offset.zero : const Offset(0, -.2),
                  duration: const Duration(milliseconds: 220),
                  child: AnimatedOpacity(
                    key: const Key('screen04-short-chrome-moolsocial'),
                    opacity: chrome ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: !chrome,
                      child: _FilterRail(
                        distribute: true,
                        values: const [
                          'For You',
                          'Following',
                          'Nearby',
                          'Promoted',
                          'YouTube',
                        ],
                        selected: _shortMode,
                        onSelected: _selectShortMode,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                top: 57,
                child: AnimatedOpacity(
                  opacity: chrome || reel.promoted ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Row(
                    children: [
                      _SourcePill(
                        reel.promoted
                            ? 'MoolSocial · Promoted Reel'
                            : 'MoolSocial · Reel',
                      ),
                      const Spacer(),
                      if (chrome)
                        Text(
                          '$position of $total',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Center(
                child: AnimatedOpacity(
                  opacity: chrome ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !chrome,
                    child: _ShortPlayControl(
                      playing: _shortPlaying,
                      onPressed: () =>
                          setState(() => _shortPlaying = !_shortPlaying),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  offset: chrome ? Offset.zero : const Offset(0, .08),
                  duration: const Duration(milliseconds: 220),
                  child: AnimatedOpacity(
                    opacity: chrome ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: !chrome,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          10,
                          44,
                          10,
                          compact ? 7 : 10,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ShortCreatorLine(
                              reel: reel,
                              followed: _followed,
                              onFollow: () =>
                                  setState(() => _followed = !_followed),
                              dark: true,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              reel.title,
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 15 : 18,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _ShortDetails(
                              text: _shortDetailsExpanded
                                  ? (reel.details ?? reel.summary)
                                  : reel.summary,
                              expanded: _shortDetailsExpanded,
                              compact: compact,
                              canExpand: reel.details != null,
                              onToggle: () => setState(
                                () => _shortDetailsExpanded =
                                    !_shortDetailsExpanded,
                              ),
                            ),
                            if (reel.commerceLabel != null) ...[
                              const SizedBox(height: 7),
                              _ShortCommerceCard(
                                title: reel.commerceLabel!,
                                detail: reel.commerceMeta!,
                                showDetail: !compact,
                                onTap: () => context.push(reel.commerceRoute!),
                              ),
                            ],
                            if (reel.promoted && !compact) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Sponsored content. The creator may earn commission from eligible delivered orders.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 7),
                            _ShortActionRow(
                              actions: [
                                (
                                  _liked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  _liked ? 'Liked' : 'Like',
                                  () => setState(() => _liked = !_liked),
                                ),
                                (
                                  Icons.chat_bubble_outline_rounded,
                                  'Comment',
                                  () => _openComments(reel.title),
                                ),
                                (Icons.share_outlined, 'Share', _openShare),
                                (
                                  Icons.repeat_rounded,
                                  'Remix',
                                  () => setState(() {
                                    _choiceByWorld['social'] = 'create';
                                    _tab = SocialV2Tab.create;
                                    _createView = 'reel-source';
                                  }),
                                ),
                              ],
                              dark: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYouTubeShort(
    _ShortData reel,
    int position,
    int total, {
    required bool active,
  }) {
    if (reel.providerVideoId != null) {
      return _buildLiveYouTubeShort(reel, position, total, active: active);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compact =
            constraints.maxHeight < 545 ||
            (textScale >= 1.25 && constraints.maxHeight < 700);
        final chrome = _shortChromeVisible;
        return GestureDetector(
          key: Key('screen04-short-${reel.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: _toggleShortChrome,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Image(
                key: Key('screen04-short-media-youtube'),
                image: AssetImage('assets/prototype/social-market-grocery.png'),
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x42000020),
                      Color(0x08000020),
                      Color(0x5C000018),
                      Color(0xFA000018),
                    ],
                    stops: [0, .34, .58, 1],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  offset: chrome ? Offset.zero : const Offset(0, -.2),
                  duration: const Duration(milliseconds: 220),
                  child: AnimatedOpacity(
                    key: const Key('screen04-short-chrome-youtube'),
                    opacity: chrome ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: !chrome,
                      child: _YouTubeSurfaceBar(
                        label: 'Shorts',
                        trailing: '$position of $total',
                        onTap: () => _openYouTubeShort(reel),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                top: 57,
                child: AnimatedOpacity(
                  opacity: chrome ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Row(
                    children: [
                      _YouTubeAttribution(
                        onTap: reel.providerVideoId == null
                            ? null
                            : () => _openYouTubeShort(reel),
                      ),
                      const Spacer(),
                      if (chrome)
                        Text(
                          '$position of $total',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Center(
                child: AnimatedOpacity(
                  opacity: chrome ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !chrome,
                    child: _ShortPlayControl(
                      playing: _shortPlaying,
                      onPressed: () =>
                          setState(() => _shortPlaying = !_shortPlaying),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  offset: chrome ? Offset.zero : const Offset(0, .08),
                  duration: const Duration(milliseconds: 220),
                  child: AnimatedOpacity(
                    opacity: chrome ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: !chrome,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          10,
                          44,
                          10,
                          compact ? 7 : 10,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ShortCreatorLine(
                              reel: reel,
                              followed: _followed,
                              onFollow: () => _openShortChannel(reel),
                              dark: true,
                              youtubeSource: true,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              reel.title,
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 15 : 18,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _ShortDetails(
                              text: reel.summary,
                              expanded: _shortDetailsExpanded,
                              compact: compact,
                              canExpand: true,
                              onToggle: () => setState(
                                () => _shortDetailsExpanded =
                                    !_shortDetailsExpanded,
                              ),
                            ),
                            if (!compact || _shortDetailsExpanded) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 11,
                                runSpacing: 2,
                                children:
                                    [
                                          reel.views,
                                          reel.published,
                                          reel.likes,
                                          reel.comments,
                                        ]
                                        .map(
                                          (value) => Text(
                                            value!,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                reel.hashtags!.join('  '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 7),
                            _ShortActionRow(
                              actions: [
                                (
                                  _saved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_outline_rounded,
                                  _saved ? 'Saved' : 'Save',
                                  () => setState(() => _saved = !_saved),
                                ),
                                (
                                  Icons.chat_bubble_outline_rounded,
                                  'Discuss',
                                  () => _openShortDiscussion(reel),
                                ),
                                (Icons.share_outlined, 'Share', _openShare),
                                (
                                  Icons.help_outline_rounded,
                                  'Details',
                                  () => _openYouTubeDetails(reel),
                                ),
                              ],
                              dark: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveYouTubeShort(
    _ShortData reel,
    int position,
    int total, {
    required bool active,
  }) {
    return Semantics(
      key: Key('screen04-short-${reel.id}'),
      label:
          'YouTube Short, ${reel.title}, ${reel.creator}, '
          '${reel.views}, ${reel.published}',
      child: ColoredBox(
        color: const Color(0xFF050514),
        child: Column(
          children: [
            _YouTubeSurfaceBar(
              label: 'Shorts',
              trailing: '$position of $total',
              onTap: () => _openYouTubeShort(reel),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final playerWidth = (constraints.maxHeight * 9 / 16)
                      .clamp(
                        YouTubePlayerGeometry.minimumCssDimension,
                        constraints.maxWidth,
                      )
                      .toDouble();
                  return Center(
                    child: SizedBox(
                      key: const Key('screen04-short-media-youtube-live'),
                      width: playerWidth,
                      child: active
                          ? _Screen04OfficialYouTubePlayer(
                              key: ValueKey(
                                'screen04-youtube-short-${reel.providerVideoId}',
                              ),
                              data: _videoDataFromShort(reel),
                              isVerifiedVerticalShort: true,
                            )
                          : Image.network(
                              reel.thumbnailUrl.toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const ColoredBox(color: Colors.black),
                            ),
                    ),
                  );
                },
              ),
            ),
            ColoredBox(
              color: const Color(0xFF09092B),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _YouTubeAttribution(
                          onTap: () => _openYouTubeShort(reel),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reel.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$position of $total',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    InkWell(
                      key: const Key('screen04-youtube-short-channel'),
                      onTap: () => _openShortChannel(reel),
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${reel.creator} · ${reel.views} · '
                                '${reel.published}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.white70,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    _ShortActionRow(
                      actions: [
                        (
                          _saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          _saved ? 'Saved' : 'Save',
                          () => setState(() => _saved = !_saved),
                        ),
                        (
                          Icons.chat_bubble_outline_rounded,
                          'Discuss',
                          () => _openShortDiscussion(reel),
                        ),
                        (Icons.share_outlined, 'Share', _openShare),
                        (
                          Icons.help_outline_rounded,
                          'Details',
                          () => _openYouTubeDetails(reel),
                        ),
                      ],
                      dark: true,
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

  void _openYouTubeDetails(_ShortData reel) {
    showSocialV2Sheet(
      context,
      title: reel.title,
      subtitle: 'Public video details',
      children: [
        SocialV2ListTile(
          icon: Icons.visibility_outlined,
          title: reel.views!,
          detail: reel.published!,
          onTap: () => Navigator.of(context).pop(),
        ),
        SocialV2ListTile(
          icon: Icons.thumb_up_alt_outlined,
          title: reel.likes!,
          detail: reel.comments!,
          onTap: () => Navigator.of(context).pop(),
        ),
        SocialV2ListTile(
          icon: Icons.person_outline_rounded,
          title: reel.creator,
          detail: 'Open this channel on YouTube',
          onTap: () {
            Navigator.of(context).pop();
            unawaited(_openYouTubeChannel(reel.providerChannelId));
          },
        ),
        SocialV2ListTile(
          icon: Icons.smart_display_outlined,
          title: 'Content from YouTube',
          detail: 'Playback uses the official YouTube player.',
          onTap: () {
            Navigator.of(context).pop();
            unawaited(_openYouTubeShort(reel));
          },
        ),
      ],
    );
  }

  void _openShortDiscussion(_ShortData short) {
    final controller = TextEditingController();
    showSocialV2Sheet(
      context,
      title: 'MoolSocial discussion',
      subtitle: short.title,
      children: [
        const SocialV2Notice(
          title: 'No MoolSocial replies yet',
          detail: 'Start a discussion about this Short.',
        ),
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Add to the discussion'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) {
              showSocialV2Message(context, 'Write a comment first');
              return;
            }
            Navigator.of(context).pop();
            showSocialV2Message(context, 'Comment posted on MoolSocial');
          },
          child: const Text('Post comment'),
        ),
      ],
    );
  }

  Widget _buildVideos() {
    if (_contentUnavailable) return _unavailable('Video');
    if (youtubePrivateDevProofEnabled && _liveYouTubeLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Loading videos',
              style: TextStyle(
                color: SocialV2Colors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    if (youtubePrivateDevProofEnabled && _liveYouTubeError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.smart_display_outlined,
                color: SocialV2Colors.navy,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                _liveYouTubeError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SocialV2Colors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadLiveYouTubeVideos,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final currentCatalog = youtubePrivateDevProofEnabled
        ? _liveYouTubeVideos
        : _videoCatalog['All']!;
    if (_activeVideo case final video?) {
      return _InlineVideoWatch(
        data: video,
        moreVideos: currentCatalog
            .where((candidate) => candidate.id != video.id)
            .toList(growable: false),
        saved: _activeVideoSaved,
        controller: _videoWatchController,
        onPlay: () => showSocialV2Message(
          context,
          'YouTube playback is temporarily unavailable',
        ),
        onChannel: () => _openVideoChannel(video),
        onOpenChannel: () => _openYouTubeChannel(video.providerChannelId),
        onDetails: () => _openVideoDetails(video),
        onSave: () => setState(() => _activeVideoSaved = !_activeVideoSaved),
        onDiscuss: () => _openVideoDiscussion(video),
        onShare: _openShare,
        onOpenProvider: _openYouTubeVideo,
        onSelectVideo: (next) => setState(() {
          _activeVideo = next;
          _activeVideoSaved = false;
          if (_videoWatchController.hasClients) {
            _videoWatchController.jumpTo(0);
          }
        }),
      );
    }
    final query = _videoQuery.toLowerCase();
    final videos =
        _videosForMode(
              _videoMode,
              liveVideos: youtubePrivateDevProofEnabled
                  ? _liveYouTubeVideos
                  : null,
            )
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
    return Column(
      children: [
        _YouTubeSurfaceBar(
          label: 'Videos',
          trailing: 'India',
          onTap: _openYouTubeHome,
        ),
        Expanded(
          child: SocialV2PageList(
            controller: _videoHomeController,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
            children: [
              if (shownVideos.isEmpty)
                const SocialV2Notice(
                  title: 'No videos found',
                  detail: 'Try a different title, channel or topic.',
                )
              else
                for (final video in shownVideos)
                  _VideoCard(
                    data: video,
                    onTap: () => _openVideoFromDiscovery(video),
                    onProvider: () => _openYouTubeVideo(video),
                  ),
              if (shownVideos.length < videos.length)
                OutlinedButton(
                  onPressed: () => setState(
                    () => _visibleVideoCount = (_visibleVideoCount + 3)
                        .clamp(3, videos.length)
                        .toInt(),
                  ),
                  child: const Text('Show more videos'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _quickPostReady =>
      _quickPostController.text.trim().isNotEmpty ||
      _quickPostMedia != null ||
      (_quickPostPoll &&
          _quickPollFirstController.text.trim().isNotEmpty &&
          _quickPollSecondController.text.trim().isNotEmpty);

  Widget _buildQuickPublicComposer({required bool inCreate}) {
    return _QuickPublicComposer(
      inCreate: inCreate,
      controller: _quickPostController,
      firstPollController: _quickPollFirstController,
      secondPollController: _quickPollSecondController,
      photoPath: _quickPostMedia?.path,
      photoIsAsset: _quickPostMedia?.isAsset ?? false,
      pollSelected: _quickPostPoll,
      canPost: _quickPostReady,
      onChanged: () => setState(() {}),
      onPhoto: _selectQuickPostPhoto,
      onPoll: () => setState(() => _quickPostPoll = !_quickPostPoll),
      onPost: _publishQuickPost,
    );
  }

  Future<void> _selectQuickPostPhoto() async {
    final media = await _mediaPicker.pickImage(SocialMediaSource.gallery);
    if (!mounted || media == null) return;
    setState(() => _quickPostMedia = media);
  }

  Future<void> _publishQuickPost() async {
    if (!_quickPostReady) return;
    final type = _quickPostPoll
        ? SocialPublishedContentType.quickPoll
        : SocialPublishedContentType.post;
    final published = await widget.sharedSession.publishSocialContent(
      type: type,
      authorName: _publicAuthorName,
      authorHandle: _publicAuthorHandle,
      body: _quickPostController.text,
      mediaPaths: _quickPostMedia == null
          ? const <String>[]
          : <String>[_quickPostMedia!.path],
      mediaAreAssets: _quickPostMedia?.isAsset ?? false,
      choices: _quickPostPoll
          ? <SocialPublishedChoice>[
              SocialPublishedChoice(label: _quickPollFirstController.text),
              SocialPublishedChoice(label: _quickPollSecondController.text),
            ]
          : const <SocialPublishedChoice>[],
      closesAt: _quickPostPoll
          ? DateTime.now().add(const Duration(days: 7))
          : null,
    );
    if (!mounted) return;
    if (published == null) {
      showSocialV2Message(
        context,
        widget.sharedSession.errorMessage ?? 'Your post was not published.',
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _quickPostController.clear();
      _quickPollFirstController.clear();
      _quickPollSecondController.clear();
      _quickPostMedia = null;
      _quickPostPoll = false;
    });
    showSocialV2Message(context, 'Posted to Feed');
  }

  Widget _buildFeed() {
    if (_contentUnavailable) return _unavailable('Post');
    final data = switch (_feedMode) {
      'Following' => const _FeedData(
        'Rajasthan Makers',
        '@rajasthanmakers',
        'From carved block to printed cotton',
        'Follow the people, process and craft behind a locally made textile.',
        'Following · Carousel',
        'See products from this maker',
      ),
      'Nearby' => const _FeedData(
        'Mahadev Fresh Mart',
        '@mahadevfresh',
        'Fresh arrivals near Khema-Ka-Kuwa',
        'Today\'s produce, shop timings and delivery coverage from a verified nearby seller.',
        'Nearby · Post',
        'View today\'s fresh basket',
      ),
      'Promoted' => const _FeedData(
        'Rajasthan Makers',
        '@rajasthanmakers',
        'Meet the people behind Rajasthan-made products',
        'Paid placement with sponsor, destination and seller details shown before action.',
        'Promoted on MoolSocial',
        'Explore featured products',
      ),
      _ => const _FeedData(
        'Meera Rathore',
        '@meerajodhpur',
        'A quiet morning above the Blue City',
        'The old lanes wake slowly. Swipe through the colours, courtyards and first cups of chai.',
        'MoolSocial Carousel',
        'Shop the breakfast basket featured in this post',
      ),
    };
    return Column(
      children: [
        _FilterRail(
          values: const ['For You', 'Following', 'Nearby', 'Promoted'],
          selected: _feedMode,
          distribute: true,
          onSelected: (value) => setState(() => _feedMode = value),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: widget.sharedSession,
            builder: (context, _) {
              final published = widget.sharedSession.socialPublishedItems
                  .where((item) => item.type != SocialPublishedContentType.reel)
                  .toList(growable: false);
              return Column(
                children: [
                  Expanded(
                    child: SocialV2PageList(
                      key: ValueKey('social-v2-feed-$_feedMode'),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      children: [
                        for (final item in published)
                          SocialPublishedContentCardV2(
                            item: item,
                            session: widget.sharedSession,
                            onReply: () => _openComments(item.body),
                            onShare: _openShare,
                          ),
                        _FeedPostCard(
                          data: data,
                          promoted: _feedMode == 'Promoted',
                          followed: _followed,
                          liked: _liked,
                          saved: _saved,
                          onProfile: () => _openProfile(data.name, data.handle),
                          onMore: () => _openReport('Post'),
                          onFollow: () =>
                              setState(() => _followed = !_followed),
                          onLike: () => setState(() => _liked = !_liked),
                          onSave: () => setState(() => _saved = !_saved),
                          onComment: () => _openComments(data.title),
                          onShare: _openShare,
                          onCommerce: () => context.push(
                            '/app/buy?intent=basket&source=feed',
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    key: const Key('screen04-feed-thumb-composer'),
                    decoration: const BoxDecoration(
                      color: Color(0xF8FFFFFF),
                      border: Border(
                        top: BorderSide(color: SocialV2Colors.line),
                        bottom: BorderSide(
                          color: SocialV2Colors.saffron,
                          width: 3,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x24000050),
                          blurRadius: 24,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 2, 0, 5),
                      child: _buildQuickPublicComposer(inCreate: false),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _unavailable(String contentType) {
    return SocialV2PageList(
      key: ValueKey('social-v2-${contentType.toLowerCase()}-unavailable'),
      children: [
        SocialV2Hero(
          eyebrow: 'Not available',
          title: 'This $contentType cannot be shown right now',
          detail:
              'It may have been removed, restricted or temporarily unavailable.',
        ),
        FilledButton(
          onPressed: () => setState(() => _contentUnavailable = false),
          child: const Text('Choose another'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _contentUnavailable = false),
          child: const Text('Try again'),
        ),
      ],
    );
  }

  Widget _buildCreate() {
    return SocialCreateWorkbenchV2(
      session: widget.sharedSession,
      mediaPicker: _mediaPicker,
      authorName: _publicAuthorName,
      authorHandle: _publicAuthorHandle,
      initialFormat: switch (_createView) {
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
          _createView = 'home';
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

  void _openComments(String subject) {
    final controller = TextEditingController();
    showSocialV2Sheet(
      context,
      title: 'Comments',
      subtitle: subject,
      children: [
        const SocialV2ListTile(
          icon: Icons.person_outline_rounded,
          title: 'Ravi Kumar',
          detail: 'Useful and beautifully explained. · 8 min',
        ),
        const SocialV2ListTile(
          icon: Icons.person_outline_rounded,
          title: 'Nisha Patel',
          detail: 'Saved this for the weekend. · 3 min',
        ),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Add to the conversation',
          ),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) {
              showSocialV2Message(context, 'Write a comment first');
              return;
            }
            Navigator.of(context).pop();
            showSocialV2Message(context, 'Comment posted on MoolSocial');
          },
          child: const Text('Post comment'),
        ),
      ],
    );
  }

  void _openShare() {
    showSocialV2Sheet(
      context,
      title: 'Share',
      subtitle: 'Choose where to send this',
      children: [
        SocialV2ListTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Share in MoolSocial Chat',
          detail: 'Choose a conversation',
          onTap: () {
            Navigator.of(context).pop();
            context.go('/app/chat');
          },
        ),
        SocialV2ListTile(
          icon: Icons.link_rounded,
          title: 'Copy MoolSocial link',
          detail: 'Share through another app',
          onTap: () {
            Navigator.of(context).pop();
            showSocialV2Message(context, 'MoolSocial link copied');
          },
        ),
      ],
    );
  }

  void _openProfile(String name, String handle) {
    showSocialV2Sheet(
      context,
      title: name,
      subtitle: '$handle · MoolSocial profile',
      children: [
        const SocialV2Notice(
          title: 'Public MoolSocial profile',
          detail: '18.4K followers · 126 posts',
        ),
        FilledButton(
          onPressed: () {
            setState(() => _followed = !_followed);
            Navigator.of(context).pop();
          },
          child: Text(_followed ? 'Following' : 'Follow'),
        ),
      ],
    );
  }

  void _openReport(String kind) {
    showSocialV2Sheet(
      context,
      title: 'Report this $kind',
      subtitle: 'Choose the closest reason',
      children:
          [
                'Spam or misleading',
                'Unsafe or harmful',
                'Harassment',
                'Intellectual property',
                'Something else',
              ]
              .map(
                (reason) => SocialV2ListTile(
                  icon: Icons.flag_outlined,
                  title: reason,
                  detail: 'MoolSocial will assess the content and its context.',
                  onTap: () {
                    Navigator.of(context).pop();
                    showSocialV2Message(
                      context,
                      'Report received. We will let you know what happens next.',
                    );
                  },
                ),
              )
              .toList(growable: false),
    );
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

  void _openShortChannel(_ShortData short) {
    unawaited(_openYouTubeChannel(short.providerChannelId));
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

  Future<void> _openYouTubeChannel(String? channelId) {
    if (channelId == null || channelId.trim().isEmpty) {
      return _openYouTubeHome();
    }
    return _openYouTubeUri(
      Uri.https('www.youtube.com', '/channel/${channelId.trim()}'),
      unavailableMessage: 'This channel could not be opened on YouTube',
    );
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

  void _openVideoDiscussion(_VideoData video) {
    final controller = TextEditingController();
    showSocialV2Sheet(
      context,
      title: 'MoolSocial discussion',
      subtitle: video.title,
      children: [
        const SocialV2Notice(
          title: 'No MoolSocial replies yet',
          detail: 'Start a discussion about this video.',
        ),
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Add to the discussion'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) {
              showSocialV2Message(context, 'Write a comment first');
              return;
            }
            Navigator.of(context).pop();
            showSocialV2Message(context, 'Comment posted on MoolSocial');
          },
          child: const Text('Post comment'),
        ),
      ],
    );
  }
}

class _ShortPlayControl extends StatelessWidget {
  const _ShortPlayControl({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = playing ? 'Pause Short' : 'Play Short';
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x59FFFFFF), Color(0xD100002E)],
            ),
            border: Border.all(color: const Color(0xB8FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5900001C),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x3DFFFFFF),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            constraints: const BoxConstraints.tightFor(width: 50, height: 50),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
            ),
            icon: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 27,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickPublicComposer extends StatelessWidget {
  const _QuickPublicComposer({
    required this.inCreate,
    required this.controller,
    required this.firstPollController,
    required this.secondPollController,
    required this.photoPath,
    required this.photoIsAsset,
    required this.pollSelected,
    required this.canPost,
    required this.onChanged,
    required this.onPhoto,
    required this.onPoll,
    required this.onPost,
  });

  final bool inCreate;
  final TextEditingController controller;
  final TextEditingController firstPollController;
  final TextEditingController secondPollController;
  final String? photoPath;
  final bool photoIsAsset;
  final bool pollSelected;
  final bool canPost;
  final VoidCallback onChanged;
  final VoidCallback onPhoto;
  final VoidCallback onPoll;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final surface = inCreate ? 'create' : 'feed';
    return SocialV2Card(
      padding: const EdgeInsets.all(10),
      child: Column(
        key: Key('screen04-quick-post-$surface'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (inCreate) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Share to Feed',
                    style: TextStyle(
                      color: SocialV2Colors.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minHeight: 28),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: SocialV2Colors.green,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Public',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: SocialV2Colors.navy,
                foregroundColor: Colors.white,
                child: Text(
                  'DC',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  key: Key('screen04-quick-post-input-$surface'),
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1200,
                  onChanged: (_) => onChanged(),
                  style: const TextStyle(
                    color: SocialV2Colors.ink,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: inCreate ? 'Share publicly' : 'Share an update',
                    hintStyle: const TextStyle(
                      color: SocialV2Colors.muted,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.all(11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: SocialV2Colors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: SocialV2Colors.line),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (photoPath case final selectedPath?) ...[
            const SizedBox(height: 8),
            SizedBox(
              key: Key('screen04-quick-post-photo-$surface'),
              height: 96,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SocialMediaPreviewV2(
                  path: selectedPath,
                  isAsset: photoIsAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          if (pollSelected) ...[
            const SizedBox(height: 8),
            TextField(
              key: Key('screen04-quick-post-poll-one-$surface'),
              controller: firstPollController,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(labelText: 'Choice 1'),
            ),
            const SizedBox(height: 7),
            TextField(
              key: Key('screen04-quick-post-poll-two-$surface'),
              controller: secondPollController,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(labelText: 'Choice 2'),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: Key('screen04-quick-post-photo-action-$surface'),
                  onPressed: onPhoto,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: EdgeInsets.zero,
                    backgroundColor: photoPath != null
                        ? const Color(0x12000080)
                        : Colors.white,
                  ),
                  child: const Text(
                    'Photo',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: OutlinedButton(
                  key: Key('screen04-quick-post-poll-action-$surface'),
                  onPressed: onPoll,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: EdgeInsets.zero,
                    backgroundColor: pollSelected
                        ? const Color(0x12138808)
                        : Colors.white,
                  ),
                  child: const Text(
                    'Poll',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: FilledButton(
                  key: Key('screen04-quick-post-publish-$surface'),
                  onPressed: canPost ? onPost : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Post',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.values,
    required this.selected,
    required this.onSelected,
    this.distribute = false,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool distribute;

  @override
  Widget build(BuildContext context) {
    if (distribute) {
      return Container(
        height: 56,
        color: const Color(0xFF050047),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Row(
          children: [
            for (var index = 0; index < values.length; index++) ...[
              if (index > 0) const SizedBox(width: 3),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selected == values[index],
                  child: InkWell(
                    onTap: () => onSelected(values[index]),
                    borderRadius: BorderRadius.circular(99),
                    child: Ink(
                      height: 46,
                      decoration: BoxDecoration(
                        color: selected == values[index]
                            ? const Color(0x2EFFFFFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                values[index],
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (selected == values[index])
                            const Positioned(
                              left: 12,
                              right: 12,
                              bottom: 1,
                              child: _ShortFilterIdentityLine(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Container(
      color: const Color(0xFF050047),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: values
              .map(
                (value) => Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(value),
                    selected: selected == value,
                    showCheckmark: false,
                    onSelected: (_) => onSelected(value),
                    backgroundColor: Colors.white,
                    selectedColor: SocialV2Colors.navy,
                    labelStyle: TextStyle(
                      color: selected == value
                          ? Colors.white
                          : SocialV2Colors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide.none,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ShortFilterIdentityLine extends StatelessWidget {
  const _ShortFilterIdentityLine();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: const SizedBox(
        height: 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 45,
              child: ColoredBox(color: SocialV2Colors.saffron),
            ),
            Expanded(flex: 14, child: ColoredBox(color: Colors.white)),
            Expanded(flex: 41, child: ColoredBox(color: SocialV2Colors.green)),
          ],
        ),
      ),
    );
  }
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

class _ShortActionRow extends StatelessWidget {
  const _ShortActionRow({required this.actions, required this.dark});

  final List<(IconData, String, VoidCallback)> actions;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions.indexed
          .expand(
            (entry) => [
              if (entry.$1 > 0) const SizedBox(width: 5),
              Expanded(
                child: OutlinedButton(
                  onPressed: entry.$2.$3,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dark ? Colors.white : SocialV2Colors.navy,
                    backgroundColor: dark
                        ? const Color(0x98000028)
                        : Colors.white,
                    side: BorderSide(
                      color: dark ? Colors.white24 : SocialV2Colors.line,
                    ),
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.$2.$1, size: 18),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          entry.$2.$2,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
          .toList(growable: false),
    );
  }
}

class _ShortDetails extends StatelessWidget {
  const _ShortDetails({
    required this.text,
    required this.expanded,
    required this.compact,
    required this.canExpand,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final bool compact;
  final bool canExpand;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: expanded ? null : (compact ? 1 : 2),
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (canExpand) ...[
          const SizedBox(width: 4),
          TextButton(
            key: const Key('screen04-short-details-toggle'),
            onPressed: onToggle,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(expanded ? 'Less' : 'More'),
          ),
        ],
      ],
    );
  }
}

class _ShortCreatorLine extends StatelessWidget {
  const _ShortCreatorLine({
    required this.reel,
    required this.followed,
    required this.onFollow,
    required this.dark,
    this.youtubeSource = false,
  });

  final _ShortData reel;
  final bool followed;
  final VoidCallback onFollow;
  final bool dark;
  final bool youtubeSource;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : SocialV2Colors.navy;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: dark ? Colors.white : SocialV2Colors.navy,
          foregroundColor: dark ? SocialV2Colors.navy : Colors.white,
          child: Text(
            reel.creatorMark,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reel.creator,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                reel.subscribers ?? reel.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dark ? Colors.white70 : SocialV2Colors.muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: onFollow,
          style: OutlinedButton.styleFrom(
            foregroundColor: foreground,
            backgroundColor: dark ? const Color(0x70000040) : Colors.white,
            side: BorderSide(
              color: dark ? Colors.white54 : SocialV2Colors.line,
            ),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            youtubeSource ? 'Channel' : (followed ? 'Following' : 'Follow'),
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ShortCommerceCard extends StatelessWidget {
  const _ShortCommerceCard({
    required this.title,
    required this.detail,
    required this.showDetail,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool showDetail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB800001F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 6, 7, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (showDetail)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: SocialV2Colors.navy,
                    size: 18,
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

class _YouTubeSurfaceBar extends StatelessWidget {
  const _YouTubeSurfaceBar({
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final String label;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050047),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              _YouTubeAttribution(onTap: onTap),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: const Color(0x66FFFFFF)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                trailing,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YouTubeAttribution extends StatelessWidget {
  const _YouTubeAttribution({this.onDark = true, this.onTap});

  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : SocialV2Colors.ink;
    return Semantics(
      button: true,
      link: true,
      label: 'Open this content on YouTube',
      child: InkWell(
        key: const Key('screen04-youtube-attribution'),
        onTap:
            onTap ??
            () {
              unawaited(() async {
                try {
                  await launchUrl(
                    Uri.https('www.youtube.com', '/'),
                    mode: LaunchMode.externalApplication,
                  );
                } on Object {
                  // The surrounding screen keeps the content available.
                }
              }());
            },
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
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
                const SizedBox(width: 2),
                Icon(
                  Icons.open_in_new_rounded,
                  color: foreground.withValues(alpha: .72),
                  size: 11,
                ),
              ],
            ),
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
    this.promoted = false,
    this.youtube = false,
    this.commerceLabel,
    this.commerceMeta,
    this.commerceRoute,
    this.subscribers,
    this.views,
    this.likes,
    this.comments,
    this.published,
    this.hashtags,
    this.campaignDisclosure,
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
  final bool promoted;
  final bool youtube;
  final String? commerceLabel;
  final String? commerceMeta;
  final String? commerceRoute;
  final String? subscribers;
  final String? views;
  final String? likes;
  final String? comments;
  final String? published;
  final List<String>? hashtags;
  final String? campaignDisclosure;
  final String? details;
  final String? providerVideoId;
  final String? providerChannelId;
  final Uri? thumbnailUrl;
  final bool embeddable;
  final bool hasKnownDeviceRegionExclusion;
}

const _screen04Shorts = <_ShortData>[
  _ShortData(
    id: 'fresh-basket',
    title: 'Fresh basket packed this morning',
    summary: 'See what is fresh, useful and available around you.',
    details:
        'Packed this morning with tomatoes, leafy greens, okra and seasonal fruit from verified nearby sellers. Compare the price, pack size, delivery time and seller details before checkout.',
    creator: 'Mahadev Fresh Mart',
    creatorMark: 'MF',
    meta: 'Verified local shop · Jodhpur',
    modes: {'for-you', 'nearby'},
    promoted: true,
    commerceLabel: 'Shop this basket',
    commerceMeta: 'Price and delivery shown before checkout',
    commerceRoute: '/app/buy?intent=basket&source=shorts',
  ),
  _ShortData(
    id: 'handblock-style',
    title: 'Three ways to style handblock cotton',
    summary:
        'Save the combinations you like and discover the makers behind each piece.',
    creator: 'Nila Craft House',
    creatorMark: 'NC',
    meta: 'Creator · Rajasthan',
    modes: {'for-you', 'following'},
    commerceLabel: 'See the collection',
    commerceMeta: 'Retail and wholesale packs available',
    commerceRoute: '/app/buy?category=fashion&source=shorts',
  ),
  _ShortData(
    id: 'maker-week',
    title: 'Meet Rajasthan makers this week',
    summary:
        'Discover verified makers, wholesale packs and delivery options in one place.',
    creator: 'MoolSocial Market',
    creatorMark: 'MM',
    meta: 'Sponsored marketplace feature',
    modes: {'promoted'},
    promoted: true,
    commerceLabel: 'Explore maker collections',
    commerceMeta: 'Retail and wholesale choices available',
    commerceRoute: '/app/buy?category=craft&source=promoted-reel',
  ),
  _ShortData(
    id: 'yt-quick-breakfast-short',
    title: 'A fast breakfast for a busy morning',
    summary: 'Three ingredients, one pan and a simple start to the day.',
    creator: 'Everyday Kitchen India',
    creatorMark: 'EK',
    meta: 'Everyday Kitchen India',
    modes: {'for-you'},
    youtube: true,
    subscribers: '2.42M subscribers',
    views: '683K views',
    likes: '31K likes',
    comments: '684 comments',
    published: '3 days ago',
    hashtags: ['#Breakfast', '#QuickRecipe', '#YouTubeShorts'],
  ),
  _ShortData(
    id: 'home-repair',
    title: 'A small repair that prevents a bigger bill',
    summary:
        'See the fix, check the professional and book only when you are ready.',
    creator: 'Jodhpur Home Care',
    creatorMark: 'JH',
    meta: 'Verified service · Nearby',
    modes: {'for-you', 'nearby'},
    commerceLabel: 'Book home repair',
    commerceMeta: 'Price and availability shown first',
    commerceRoute: '/app/book?service=repair&source=shorts',
  ),
  _ShortData(
    id: 'yt-jodhpur-craft-short',
    title: 'From carved block to printed cotton',
    summary: 'Watch a hand-carved pattern come alive in under a minute.',
    creator: 'Made Across India',
    creatorMark: 'MI',
    meta: 'Made Across India',
    modes: {'for-you', 'promoted'},
    youtube: true,
    subscribers: '1.08M subscribers',
    views: '1.1M views',
    likes: '48K likes',
    comments: '926 comments',
    published: '6 days ago',
    hashtags: ['#Rajasthan', '#Handblock', '#YouTubeShorts'],
    commerceLabel: 'See the maker’s collection',
    commerceMeta: 'Brand-linked Short with tracked creator commission',
    commerceRoute: '/app/buy?category=craft&source=youtube-short',
    campaignDisclosure:
        'Brand-linked Short. The creator may earn commission from eligible delivered orders.',
  ),
];

class _FeedActions extends StatelessWidget {
  const _FeedActions({
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onShare,
  });

  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, VoidCallback)>[
      (
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        liked ? 'Liked' : 'Like',
        onLike,
      ),
      (Icons.chat_bubble_outline_rounded, 'Comment', onComment),
      (Icons.share_outlined, 'Share', onShare),
      (
        saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
        saved ? 'Saved' : 'Save',
        onSave,
      ),
    ];
    return Row(
      children: actions
          .map(
            (action) => Expanded(
              child: IconButton(
                tooltip: action.$2,
                onPressed: action.$3,
                icon: Icon(action.$1),
                color: SocialV2Colors.navy,
              ),
            ),
          )
          .toList(growable: false),
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

const _videoCatalog = <String, List<_VideoData>>{
  'All': [
    _VideoData(
      '5-minute morning mobility',
      'Move With Asha',
      '1.2M views',
      '5:04',
      published: '2 days ago',
      publishedDate: '20 Jul 2026',
      summary: 'A calm routine you can follow before the day gets busy.',
      likes: '38K likes',
      comments: '426 comments',
      subscribers: '684K subscribers',
      channelSummary:
          'Guided mobility, strength and recovery sessions for everyday movement.',
      channelVideos: '312 videos',
      channelViews: '86M channel views',
      latestVideoDate: '20 Jul 2026',
      hashtags: ['#Mobility', '#Wellness', '#MorningRoutine'],
    ),
    _VideoData(
      'How Jodhpur makers prepare block prints',
      'Made Across India',
      '486K views',
      '12:18',
      published: '5 days ago',
      publishedDate: '17 Jul 2026',
      summary:
          'Meet Jodhpur artisans as they carve, colour and print fabric by hand.',
      likes: '21K likes',
      comments: '318 comments',
      subscribers: '1.08M subscribers',
      channelSummary:
          'Stories of Indian makers, regional crafts and the people preserving them.',
      channelVideos: '428 videos',
      channelViews: '164M channel views',
      latestVideoDate: '21 Jul 2026',
      hashtags: ['#Jodhpur', '#BlockPrint', '#IndianCraft'],
    ),
  ],
  'Popular': [
    _VideoData(
      'India\'s most useful home organisation ideas',
      'Better Homes India',
      '3.8M views',
      '9:42',
      published: '1 week ago',
      publishedDate: '15 Jul 2026',
      summary:
          'Practical storage and organisation ideas designed for Indian homes.',
      likes: '94K likes',
      comments: '1.8K comments',
      subscribers: '2.4M subscribers',
      channelSummary:
          'Simple home improvements, storage ideas and everyday living solutions.',
      channelVideos: '864 videos',
      channelViews: '612M channel views',
      latestVideoDate: '22 Jul 2026',
      hashtags: ['#HomeIdeas', '#Organisation', '#IndianHomes'],
    ),
    _VideoData(
      'Seven street foods worth travelling for',
      'Tastes of India',
      '2.1M views',
      '14:06',
      published: '9 days ago',
      publishedDate: '13 Jul 2026',
      summary:
          'Seven regional street-food stops, their makers and what to order.',
      likes: '76K likes',
      comments: '2.3K comments',
      subscribers: '1.7M subscribers',
      channelSummary:
          'Regional food journeys, local kitchens and the people behind each plate.',
      channelVideos: '536 videos',
      channelViews: '408M channel views',
      latestVideoDate: '19 Jul 2026',
      hashtags: ['#StreetFood', '#FoodTravel', '#India'],
    ),
  ],
  'Local': [
    _VideoData(
      'A morning inside Jodhpur\'s old market',
      'Made Across India',
      '92K views',
      '8:16',
      published: '1 day ago',
      publishedDate: '22 Jul 2026',
      summary:
          'Walk through Jodhpur\'s old market as traders open their shops for the day.',
      likes: '8.4K likes',
      comments: '204 comments',
      subscribers: '1.08M subscribers',
      channelSummary:
          'Stories of Indian makers, regional crafts and the people preserving them.',
      channelVideos: '428 videos',
      channelViews: '164M channel views',
      latestVideoDate: '22 Jul 2026',
      hashtags: ['#Jodhpur', '#LocalMarket', '#Rajasthan'],
    ),
    _VideoData(
      'How local artisans prepare hand-block prints',
      'Rajasthan Makers',
      '184K views',
      '11:24',
      published: '4 days ago',
      publishedDate: '19 Jul 2026',
      summary:
          'Follow the hand-block printing process from carved block to finished cloth.',
      likes: '14K likes',
      comments: '287 comments',
      subscribers: '326K subscribers',
      channelSummary:
          'Craft processes, workshops and independent makers across Rajasthan.',
      channelVideos: '214 videos',
      channelViews: '48M channel views',
      latestVideoDate: '19 Jul 2026',
      hashtags: ['#HandBlockPrint', '#Artisans', '#Rajasthan'],
    ),
  ],
  'Learning': [
    _VideoData(
      'Understand wholesale pricing in 10 minutes',
      'Business Made Clear',
      '612K views',
      '10:02',
      published: '6 days ago',
      publishedDate: '17 Jul 2026',
      summary:
          'Learn how quantity, margins and payment terms shape a wholesale price.',
      likes: '31K likes',
      comments: '742 comments',
      subscribers: '912K subscribers',
      channelSummary:
          'Clear lessons for retailers, manufacturers and growing Indian businesses.',
      channelVideos: '392 videos',
      channelViews: '121M channel views',
      latestVideoDate: '21 Jul 2026',
      hashtags: ['#Wholesale', '#Pricing', '#Business'],
    ),
    _VideoData(
      'Simple product photography with a phone',
      'Create Better India',
      '830K views',
      '7:38',
      published: '3 days ago',
      publishedDate: '20 Jul 2026',
      summary:
          'Use light, framing and a phone camera to make products look their best.',
      likes: '46K likes',
      comments: '956 comments',
      subscribers: '1.2M subscribers',
      channelSummary:
          'Practical content, photography and publishing skills for Indian creators.',
      channelVideos: '478 videos',
      channelViews: '198M channel views',
      latestVideoDate: '20 Jul 2026',
      hashtags: ['#ProductPhotography', '#PhoneCamera', '#Creators'],
    ),
  ],
  'Live': [
    _VideoData(
      'Jodhpur market update · Live',
      'Local India Live',
      '13K watching',
      'LIVE',
      published: 'Live now',
      publishedDate: '23 Jul 2026',
      summary:
          'Live prices, availability and activity from Jodhpur\'s central market.',
      likes: '2.8K likes',
      comments: '1.1K comments',
      subscribers: '248K subscribers',
      channelSummary:
          'Live local updates from markets, neighbourhoods and public events.',
      channelVideos: '1.1K videos',
      channelViews: '72M channel views',
      latestVideoDate: '23 Jul 2026',
      hashtags: ['#Jodhpur', '#Live', '#MarketUpdate'],
    ),
    _VideoData(
      'Small business questions · Live',
      'Business Made Clear',
      '4.2K watching',
      'LIVE',
      published: 'Live now',
      publishedDate: '23 Jul 2026',
      summary:
          'Live answers on pricing, cash flow, customer growth and daily operations.',
      likes: '1.6K likes',
      comments: '684 comments',
      subscribers: '912K subscribers',
      channelSummary:
          'Clear lessons for retailers, manufacturers and growing Indian businesses.',
      channelVideos: '392 videos',
      channelViews: '121M channel views',
      latestVideoDate: '23 Jul 2026',
      hashtags: ['#SmallBusiness', '#Live', '#BusinessQuestions'],
    ),
  ],
  'Business': [
    _VideoData(
      'How local shops turn repeat buyers into regular customers',
      'Business Seed India',
      '274K views',
      '8:44',
      published: '8 days ago',
      publishedDate: '15 Jul 2026',
      summary:
          'See how local shops use service, reminders and trust to retain customers.',
      likes: '18K likes',
      comments: '403 comments',
      subscribers: '518K subscribers',
      channelSummary:
          'Customer growth and operating ideas for India\'s local businesses.',
      channelVideos: '286 videos',
      channelViews: '63M channel views',
      latestVideoDate: '18 Jul 2026',
      hashtags: ['#Retail', '#Customers', '#LocalBusiness'],
    ),
    _VideoData(
      'Wholesale pricing explained for growing retailers',
      'Business Made Clear',
      '612K views',
      '10:02',
      published: '6 days ago',
      publishedDate: '17 Jul 2026',
      summary:
          'Compare margins, pack sizes and payment terms before setting a retail price.',
      likes: '31K likes',
      comments: '742 comments',
      subscribers: '912K subscribers',
      channelSummary:
          'Clear lessons for retailers, manufacturers and growing Indian businesses.',
      channelVideos: '392 videos',
      channelViews: '121M channel views',
      latestVideoDate: '21 Jul 2026',
      hashtags: ['#Wholesale', '#Retail', '#Pricing'],
    ),
  ],
};

List<_VideoData> _videosForMode(String mode, {List<_VideoData>? liveVideos}) {
  if (liveVideos == null) {
    return _videoCatalog[mode] ?? _videoCatalog['All']!;
  }
  if (mode == 'Live') {
    return liveVideos
        .where((video) => video.duration == 'LIVE')
        .toList(growable: false);
  }
  if (mode == 'All' || mode == 'Popular') return liveVideos;
  final terms = switch (mode) {
    'Learning' => const ['learn', 'how to', 'guide', 'course', 'education'],
    'Local' => const ['india', 'indian', 'local', 'rajasthan', 'jodhpur'],
    'Business' => const ['business', 'market', 'shop', 'retail', 'commerce'],
    _ => const <String>[],
  };
  final filtered = liveVideos
      .where((video) {
        final searchable = <String>[
          video.title,
          video.channel,
          video.summary,
          ...video.hashtags,
        ].join(' ').toLowerCase();
        return terms.any(searchable.contains);
      })
      .toList(growable: false);
  return filtered.isEmpty ? liveVideos : filtered;
}

_VideoData _videoForId(String? id) {
  for (final videos in _videoCatalog.values) {
    for (final video in videos) {
      if (video.id == id) return video;
    }
  }
  return _videoCatalog['All']!.first;
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.data,
    required this.onTap,
    required this.onProvider,
  });
  final _VideoData data;
  final VoidCallback onTap;
  final VoidCallback onProvider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Watch ${data.title}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: Colors.white,
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
                              color: SocialV2Colors.navy,
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
                              color: SocialV2Colors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    _YouTubeAttribution(onDark: false, onTap: onProvider),
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
    required this.saved,
    required this.controller,
    required this.onPlay,
    required this.onChannel,
    required this.onOpenChannel,
    required this.onDetails,
    required this.onSave,
    required this.onDiscuss,
    required this.onShare,
    required this.onOpenProvider,
    required this.onSelectVideo,
  });

  final _VideoData data;
  final List<_VideoData> moreVideos;
  final bool saved;
  final ScrollController controller;
  final VoidCallback onPlay;
  final VoidCallback onChannel;
  final VoidCallback onOpenChannel;
  final VoidCallback onDetails;
  final VoidCallback onSave;
  final VoidCallback onDiscuss;
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
              _VideoProviderLine(
                data: data,
                onProvider: () => onOpenProvider(data),
              ),
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
                            color: SocialV2Colors.navy,
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
                            color: SocialV2Colors.muted,
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
              Row(
                children: [
                  _VideoActionButton(
                    key: const Key('screen04-video-save'),
                    icon: saved ? Icons.bookmark : Icons.bookmark_outline,
                    label: saved ? 'Saved' : 'Save',
                    onPressed: onSave,
                  ),
                  _VideoActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Discuss',
                    onPressed: onDiscuss,
                  ),
                  _VideoActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onPressed: onShare,
                  ),
                  _VideoActionButton(
                    icon: Icons.help_outline_rounded,
                    label: 'Details',
                    onPressed: onDetails,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _VideoCommentsPreview(onDiscuss: onDiscuss),
            ],
          ),
        ),
        if (moreVideos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: SocialV2SectionTitle(
              'More to watch',
              detail: '${moreVideos.length + 1} videos',
            ),
          ),
          for (final video in moreVideos)
            _VideoCard(
              data: video,
              onTap: () => onSelectVideo(video),
              onProvider: () => onOpenProvider(video),
            ),
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
      return const Image(
        image: AssetImage('assets/prototype/social-market-grocery.png'),
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      thumbnailUrl.toString(),
      key: Key('screen04-youtube-thumbnail-${data.id}'),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => const Image(
        image: AssetImage('assets/prototype/social-market-grocery.png'),
        fit: BoxFit.cover,
      ),
    );
  }
}

class _Screen04OfficialYouTubePlayer extends StatefulWidget {
  const _Screen04OfficialYouTubePlayer({
    required this.data,
    this.isVerifiedVerticalShort = false,
    super.key,
  });

  final _VideoData data;
  final bool isVerifiedVerticalShort;

  @override
  State<_Screen04OfficialYouTubePlayer> createState() =>
      _Screen04OfficialYouTubePlayerState();
}

class _Screen04OfficialYouTubePlayerState
    extends State<_Screen04OfficialYouTubePlayer>
    with WidgetsBindingObserver {
  YouTubeEmbeddedPlayerController? _controller;
  YouTubeEmbeddedPlayerStatus _status = YouTubeEmbeddedPlayerStatus.mounting;
  bool _selectionFailed = false;

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
                        _status = snapshot.status;
                        _selectionFailed =
                            snapshot.status ==
                            YouTubeEmbeddedPlayerStatus.failed;
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
              if (_status == YouTubeEmbeddedPlayerStatus.mounting ||
                  _status == YouTubeEmbeddedPlayerStatus.waitingForProvider)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              if (_selectionFailed)
                ColoredBox(
                  color: const Color(0xE6000028),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.isVerifiedVerticalShort
                            ? 'This YouTube Short cannot be played here right now.'
                            : 'This video cannot be played here right now.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
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
        setState(() => _selectionFailed = true);
      }
    } on Object {
      if (mounted) setState(() => _selectionFailed = true);
    }
  }
}

class _VideoProviderLine extends StatelessWidget {
  const _VideoProviderLine({required this.data, required this.onProvider});

  final _VideoData data;
  final VoidCallback onProvider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _YouTubeAttribution(onDark: false, onTap: onProvider),
        const Spacer(),
        Text(
          '${data.duration} · ${data.views} · ${data.published}',
          style: const TextStyle(
            color: SocialV2Colors.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
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
                      color: SocialV2Colors.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    data.subscribers,
                    style: const TextStyle(
                      color: SocialV2Colors.muted,
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
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
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

class _VideoCommentsPreview extends StatelessWidget {
  const _VideoCommentsPreview({required this.onDiscuss});

  final VoidCallback onDiscuss;

  @override
  Widget build(BuildContext context) {
    return SocialV2Card(
      padding: const EdgeInsets.all(11),
      child: InkWell(
        onTap: onDiscuss,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'MoolSocial discussion',
                    style: TextStyle(
                      color: SocialV2Colors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: SocialV2Colors.muted,
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Start a conversation about this video on MoolSocial.',
                style: TextStyle(
                  color: SocialV2Colors.muted,
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
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
          _YouTubeAttribution(onDark: false, onTap: onProvider),
        ],
      ),
    );
  }
}

class _VideoWatchScreen extends StatefulWidget {
  const _VideoWatchScreen({
    required this.data,
    required this.onCreatorWorkspace,
    required this.onPlans,
    required this.onTab,
  });
  final _VideoData data;
  final VoidCallback onCreatorWorkspace;
  final VoidCallback onPlans;
  final ValueChanged<SocialV2Tab> onTab;

  @override
  State<_VideoWatchScreen> createState() => _VideoWatchScreenState();
}

class _VideoWatchScreenState extends State<_VideoWatchScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return SocialV2Scaffold(
      title: 'Videos',
      subtitle: widget.data.channel,
      selectedTab: SocialV2Tab.videos,
      onBack: () => Navigator.of(context).pop(),
      onCreatorWorkspace: widget.onCreatorWorkspace,
      onPlans: widget.onPlans,
      onTab: (tab) {
        Navigator.of(context).pop();
        if (tab != SocialV2Tab.videos) widget.onTab(tab);
      },
      body: SocialV2PageList(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  child: Image(
                    image: AssetImage(
                      'assets/prototype/social-market-grocery.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                Center(
                  child: IconButton.filled(
                    key: const Key('social-v2-youtube-play'),
                    tooltip: 'Play in the official YouTube player',
                    onPressed: () =>
                        showSocialV2Message(context, 'Video ready'),
                    iconSize: 32,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ),
                const Positioned(
                  left: 8,
                  top: 8,
                  child: _SourcePill('YouTube video'),
                ),
              ],
            ),
          ),
          SocialV2Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.data.title,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.data.channel} · ${widget.data.views} · ${widget.data.published}',
                  style: const TextStyle(
                    color: SocialV2Colors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.data.summary,
                  style: const TextStyle(
                    color: SocialV2Colors.ink,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children:
                      [
                            widget.data.views,
                            widget.data.likes,
                            widget.data.comments,
                            widget.data.published,
                            ...widget.data.hashtags,
                          ]
                          .map(
                            (value) => Text(
                              value,
                              style: const TextStyle(
                                color: SocialV2Colors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(growable: false),
                ),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    ActionChip(
                      label: const Text('Channel'),
                      onPressed: _openChannel,
                    ),
                    ActionChip(
                      label: const Text('Details'),
                      onPressed: _openDetails,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _saved = !_saved),
                        icon: Icon(
                          _saved ? Icons.bookmark : Icons.bookmark_outline,
                        ),
                        label: Text(_saved ? 'Saved' : 'Save'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openDiscussion,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Discuss'),
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      showSocialV2Message(context, 'MoolSocial link copied'),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),
          const SocialV2SectionTitle(
            'More to watch',
            detail: 'Choose another video',
          ),
          SocialV2ListTile(
            icon: Icons.play_circle_outline,
            title: 'Easy breakfast for a busy morning',
            detail: 'Everyday Kitchen India · 7:12',
            onTap: () => showSocialV2Message(context, 'Next video selected'),
          ),
          SocialV2ListTile(
            icon: Icons.play_circle_outline,
            title: 'Local businesses using digital catalogues',
            detail: 'Made Across India · 9:48',
            onTap: () => showSocialV2Message(context, 'Next video selected'),
          ),
        ],
      ),
    );
  }

  void _openChannel() {
    showSocialV2Sheet(
      context,
      title: widget.data.channel,
      subtitle: 'YouTube channel',
      children: [
        SocialV2ListTile(
          icon: Icons.person_outline_rounded,
          title: widget.data.channel,
          detail: '${widget.data.views} on this video',
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Return to video'),
        ),
      ],
    );
  }

  void _openDetails() {
    showSocialV2Sheet(
      context,
      title: 'Video details',
      subtitle: widget.data.title,
      children: [
        SocialV2ListTile(
          icon: Icons.visibility_outlined,
          title: widget.data.views,
          detail: widget.data.published,
        ),
        SocialV2ListTile(
          icon: Icons.schedule_outlined,
          title: widget.data.duration,
          detail: 'Video duration',
        ),
        const SocialV2Notice(
          title: 'YouTube video',
          detail:
              'Playback and YouTube account actions stay with YouTube. MoolSocial Save, Discuss and Shop actions remain separate.',
          warning: true,
        ),
      ],
    );
  }

  void _openDiscussion() {
    final controller = TextEditingController();
    showSocialV2Sheet(
      context,
      title: 'MoolSocial discussion',
      subtitle: widget.data.title,
      children: [
        const SocialV2Notice(
          title: 'No MoolSocial replies yet',
          detail: 'Start a discussion about this video.',
        ),
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Add to the discussion'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) {
              showSocialV2Message(context, 'Write a comment first');
              return;
            }
            Navigator.of(context).pop();
            showSocialV2Message(context, 'Comment posted on MoolSocial');
          },
          child: const Text('Post comment'),
        ),
      ],
    );
  }
}

class _FeedData {
  const _FeedData(
    this.name,
    this.handle,
    this.title,
    this.detail,
    this.source,
    this.commerceAction,
  );
  final String name;
  final String handle;
  final String title;
  final String detail;
  final String source;
  final String commerceAction;
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.data,
    required this.promoted,
    required this.followed,
    required this.liked,
    required this.saved,
    required this.onProfile,
    required this.onMore,
    required this.onFollow,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onShare,
    required this.onCommerce,
  });

  final _FeedData data;
  final bool promoted;
  final bool followed;
  final bool liked;
  final bool saved;
  final VoidCallback onProfile;
  final VoidCallback onMore;
  final VoidCallback onFollow;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onCommerce;

  @override
  Widget build(BuildContext context) {
    return SocialV2Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 8, 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: SocialV2Colors.navy,
                  foregroundColor: Colors.white,
                  child: Text(
                    'MR',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: InkWell(
                    onTap: onProfile,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SocialV2Colors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${data.handle} · ${promoted ? 'Sponsored' : '18 min'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SocialV2Colors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 78,
                  child: OutlinedButton(
                    onPressed: onFollow,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(followed ? 'Following' : 'Follow'),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'More Post actions',
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.08,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Image(
                  image: AssetImage(
                    'assets/prototype/social-market-grocery.png',
                  ),
                  fit: BoxFit.cover,
                ),
                Positioned(left: 10, top: 10, child: _SourcePill(data.source)),
                const Positioned(
                  right: 10,
                  bottom: 10,
                  child: _SourcePill('1 / 3'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 18,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.detail,
                  style: const TextStyle(
                    color: SocialV2Colors.muted,
                    height: 1.35,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                _FeedActions(
                  liked: liked,
                  saved: saved,
                  onLike: onLike,
                  onSave: onSave,
                  onComment: onComment,
                  onShare: onShare,
                ),
                const SizedBox(height: 7),
                OutlinedButton(
                  onPressed: onCommerce,
                  child: Text(data.commerceAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
