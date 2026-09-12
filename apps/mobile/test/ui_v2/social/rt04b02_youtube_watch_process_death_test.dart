import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_search_state_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_watch_state_repository.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RT-04B-02 Search Watch restores before Search with exact Back target',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      var now = DateTime.utc(2026, 8, 25, 6);
      final searchPersistence = _KeyValueStore();
      final watchPersistence = _KeyValueStore();
      final firstSearch = YouTubePublicSearchStateCache(now: () => now);
      final firstWatch = YouTubePublicWatchStateCache(now: () => now);
      await firstSearch.configureDurability(
        DurableYouTubePublicSearchStateRepository(
          persistence: searchPersistence,
          principalBinding: _binding(),
          now: () => now,
        ),
      );
      await firstWatch.configureDurability(
        DurableYouTubePublicWatchStateRepository(
          persistence: watchPersistence,
          principalBinding: _binding(),
          now: () => now,
        ),
      );
      final firstOwners = _Owners();
      addTearDown(firstOwners.dispose);
      await tester.pumpWidget(
        _app(
          firstOwners.consumer(
            searchStateCache: firstSearch,
            watchStateCache: firstWatch,
            searchLoader: (_) async => [
              _video('watchPersist01', 'Persisted Watch result'),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('screen04-youtube-home-search')));
      await tester.pump();
      final input = find.byKey(const Key('screen04-youtube-search-input'));
      await tester.enterText(input, 'watch process death');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Persisted Watch result'));
      await tester.pump();
      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
      final watchList = find
          .descendant(
            of: find.byKey(const Key('screen04-video-watch')),
            matching: find.byType(ListView),
          )
          .first;
      await tester.drag(watchList, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
      final storedWatchOffset = tester
          .widget<ListView>(watchList)
          .controller!
          .offset;
      expect(storedWatchOffset, greaterThan(0));
      await firstSearch.settleDurableWrites();
      await firstWatch.settleDurableWrites();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await firstWatch.settleDurableWrites();
      now = now.add(const Duration(minutes: 1));
      final relaunchedSearch = YouTubePublicSearchStateCache(now: () => now);
      final relaunchedWatch = YouTubePublicWatchStateCache(now: () => now);
      expect(
        await relaunchedSearch.configureDurability(
          DurableYouTubePublicSearchStateRepository(
            persistence: searchPersistence,
            principalBinding: _binding(),
            now: () => now,
          ),
        ),
        YouTubePublicSearchFreshness.fresh,
      );
      expect(
        await relaunchedWatch.configureDurability(
          DurableYouTubePublicWatchStateRepository(
            persistence: watchPersistence,
            principalBinding: _binding(),
            now: () => now,
          ),
        ),
        YouTubePublicWatchFreshness.fresh,
      );
      var unexpectedSearchLoads = 0;
      final relaunchedOwners = _Owners();
      addTearDown(relaunchedOwners.dispose);
      await tester.pumpWidget(
        _app(
          relaunchedOwners.consumer(
            searchStateCache: relaunchedSearch,
            watchStateCache: relaunchedWatch,
            searchLoader: (_) async {
              unexpectedSearchLoads += 1;
              return const [];
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
      expect(find.text('Persisted Watch result'), findsWidgets);
      expect(find.byTooltip('Back to YouTube Search results'), findsOneWidget);
      final restoredWatchList = find
          .descendant(
            of: find.byKey(const Key('screen04-video-watch')),
            matching: find.byType(ListView),
          )
          .first;
      expect(
        tester.widget<ListView>(restoredWatchList).controller?.offset,
        closeTo(storedWatchOffset, 1),
      );
      expect(unexpectedSearchLoads, 0);

      await tester.tap(find.byKey(const Key('screen04-youtube-watch-search')));
      await tester.pump();
      expect(
        find.byKey(const Key('screen04-youtube-search-surface')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('screen04-youtube-search-back')));
      await tester.pump();
      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
      expect(find.byTooltip('Back to YouTube Search results'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const Key('screen04-youtube-search-surface')),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(input).controller?.text,
        'watch process death',
      );
      expect(find.text('Persisted Watch result'), findsOneWidget);
      expect(relaunchedWatch.snapshot, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RT-04B-02 Home Watch restores Watch and Home offsets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final selected = _video('homeWatch01', 'Persisted Home Watch');
    final watchCache = YouTubePublicWatchStateCache();
    final watchRepository = _WatchStateRepository(
      YouTubePublicWatchRead(
        freshness: YouTubePublicWatchFreshness.fresh,
        snapshot: YouTubePublicWatchSnapshot(
          selectedVideo: mapScreen04VideoToYouTubePublicCatalogueItem(selected),
          origin: YouTubePublicWatchOrigin.home,
          watchScrollOffset: 150,
          homeScrollOffset: 220,
          capturedAtUtc: DateTime.now().toUtc(),
        ),
      ),
    );
    await watchCache.configureDurability(watchRepository);
    final owners = _Owners();
    addTearDown(owners.dispose);
    final videos = <Screen04YouTubePublicVideo>[
      selected,
      ...List.generate(
        11,
        (index) => _video('homeMore$index', 'Home more $index'),
      ),
    ];

    await tester.pumpWidget(
      _app(
        owners.consumer(
          searchStateCache: YouTubePublicSearchStateCache(),
          watchStateCache: watchCache,
          searchLoader: (_) async => const [],
          videos: videos,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
    expect(find.text('Persisted Home Watch'), findsWidgets);
    expect(find.byTooltip('Back to YouTube Home'), findsOneWidget);
    final watchList = find
        .descendant(
          of: find.byKey(const Key('screen04-video-watch')),
          matching: find.byType(ListView),
        )
        .first;
    expect(
      tester.widget<ListView>(watchList).controller?.offset,
      closeTo(150, 1),
    );
    await tester.tap(find.text('Home more 0').last);
    await tester.pump();
    expect(watchCache.snapshot?.selectedVideo.videoId, 'homeMore0');
    expect(watchCache.snapshot?.origin, YouTubePublicWatchOrigin.home);
    expect(watchCache.snapshot?.watchScrollOffset, 0);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('screen04-youtube-home-list')), findsOneWidget);
    final homeList = tester.widget<ListView>(
      find.byKey(const Key('screen04-youtube-home-list')),
    );
    expect(homeList.controller?.offset, closeTo(220, 1));
    expect(watchCache.snapshot, isNull);
    expect(watchRepository.clears, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RT-04B-02 Search-origin recommendation keeps Search Back', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final searchResult = _video('searchOrigin01', 'Original Search result');
    final recommendation = _video('recommend01', 'Watch recommendation');
    final searchCache = YouTubePublicSearchStateCache()
      ..replace(
        submittedQuery: 'original query',
        results: [mapScreen04VideoToYouTubePublicCatalogueItem(searchResult)],
      );
    final watchCache = YouTubePublicWatchStateCache()
      ..replace(
        selectedVideo: mapScreen04VideoToYouTubePublicCatalogueItem(
          recommendation,
        ),
        origin: YouTubePublicWatchOrigin.search,
      );
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        owners.consumer(
          searchStateCache: searchCache,
          watchStateCache: watchCache,
          searchLoader: (_) async => const [],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Watch recommendation'), findsWidgets);
    expect(find.byTooltip('Back to YouTube Search results'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(
      find.byKey(const Key('screen04-youtube-search-surface')),
      findsOneWidget,
    );
    expect(find.text('Original Search result'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('screen04-youtube-search-input')),
          )
          .controller
          ?.text,
      'original query',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RT-04B-02 Search-origin Watch fails closed without Search', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final watchCache = YouTubePublicWatchStateCache()
      ..replace(
        selectedVideo: mapScreen04VideoToYouTubePublicCatalogueItem(
          _video('orphanWatch01', 'Orphan Watch'),
        ),
        origin: YouTubePublicWatchOrigin.search,
      );
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        owners.consumer(
          searchStateCache: YouTubePublicSearchStateCache(),
          watchStateCache: watchCache,
          searchLoader: (_) async => const [],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(
      find.byKey(const Key('screen04-youtube-home-header')),
      findsOneWidget,
    );
    expect(watchCache.snapshot, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RT-04B-02 matching Chat return route consumes durable Watch', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final selected = _video('chatReturn01', 'Search-only Chat return Watch');
    final watchCache = YouTubePublicWatchStateCache()
      ..replace(
        selectedVideo: mapScreen04VideoToYouTubePublicCatalogueItem(selected),
        origin: YouTubePublicWatchOrigin.home,
      );
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        owners.consumer(
          searchStateCache: YouTubePublicSearchStateCache(),
          watchStateCache: watchCache,
          searchLoader: (_) async => const [],
          initialState: 'video-watch',
          initialItem: 'chatReturn01',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
    expect(find.text('Search-only Chat return Watch'), findsWidgets);
    expect(watchCache.snapshot?.selectedVideo.videoId, 'chatReturn01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('RT-04B-02 mismatched Chat return clears durable Watch', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final watchCache = YouTubePublicWatchStateCache()
      ..replace(
        selectedVideo: mapScreen04VideoToYouTubePublicCatalogueItem(
          _video('priorWatch01', 'Prior Watch'),
        ),
        origin: YouTubePublicWatchOrigin.home,
      );
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        owners.consumer(
          searchStateCache: YouTubePublicSearchStateCache(),
          watchStateCache: watchCache,
          searchLoader: (_) async => const [],
          initialState: 'video-watch',
          initialItem: 'different-video',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Prior Watch'), findsNothing);
    expect(watchCache.snapshot, isNull);
    expect(tester.takeException(), isNull);
  });

  test('RT-04B-02 secure binder and explicit clear composition is exact', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final consumer = File(
      'lib/ui_v2/social/social_v2_consumer.dart',
    ).readAsStringSync();

    expect(
      mainSource,
      contains('SecureStorageYouTubePublicWatchKeyValueStore()'),
    );
    expect(mainSource, contains('DurableYouTubePublicWatchStateRepository('));
    expect(mainSource, contains('principalBinding: storedBinding'));
    expect(mainSource, contains('bindingAttempt: watchBindingAttempt'));
    expect(mainSource, contains("'youtube_watch_state', 'degraded'"));
    expect(
      mainSource,
      contains(
        'onAuthenticatedBoundary: '
        'bindYouTubeSearchStateToCurrentPrincipal',
      ),
    );
    expect(
      consumer,
      contains('youtubePublicWatchState.clear(detachRepository: true)'),
    );
    expect(consumer, contains('_discardDurableYouTubeWatch();'));
    expect(consumer, isNot(contains('playbackPosition')));
  });
}

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true),
  home: child,
);

final class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer({
    required Screen04YouTubePublicSearchLoader searchLoader,
    required YouTubePublicSearchStateCache searchStateCache,
    required YouTubePublicWatchStateCache watchStateCache,
    List<Screen04YouTubePublicVideo>? videos,
    String? initialState,
    String? initialItem,
  }) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: 'videos',
    initialState: initialState,
    initialItem: initialItem,
    youtubePublicAccessOverride: true,
    youtubeCreatorAccessOverride: false,
    youtubeVideosLoader: () async =>
        videos ?? [_video('homeVid0001', 'Provider home video')],
    youtubeShortsLoader: () async => const [],
    youtubeSearchLoader: searchLoader,
    youtubeSearchStateCache: searchStateCache,
    youtubeWatchStateCache: watchStateCache,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

final class _WatchStateRepository implements YouTubePublicWatchStateRepository {
  _WatchStateRepository(this.value);

  final YouTubePublicWatchRead value;
  int clears = 0;

  @override
  Future<YouTubePublicWatchRead> read() async => value;

  @override
  Future<void> write(YouTubePublicWatchSnapshot snapshot) async {}

  @override
  Future<void> clear() async {
    clears += 1;
  }
}

final class _KeyValueStore implements YouTubePublicCatalogueKeyValueStore {
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

VerifiedPrincipalBinding _binding() =>
    VerifiedPrincipalBinding.fromStorage('v1:${'a' * 64}');

Screen04YouTubePublicVideo _video(String id, String title) =>
    Screen04YouTubePublicVideo(
      videoId: id,
      title: title,
      channelId: 'UC-$id',
      channelTitle: 'Provider channel',
      description: 'Provider-returned public result.',
      thumbnailUrl: Uri.https('i.ytimg.com', '/vi/$id/hqdefault.jpg'),
      publishedAt: DateTime.utc(2026, 8, 11),
      duration: 'PT4M12S',
      captionAvailable: true,
      viewCount: '1200',
      likeCount: '120',
      commentCount: '12',
      embeddable: true,
      hasKnownDeviceRegionExclusion: false,
      hashtags: const ['#News'],
    );
