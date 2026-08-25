import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_search_state_repository.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'C30C Home search is full-page, keyboard-safe and selects only real results',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);
      final searchCompleter = Completer<List<Screen04YouTubePublicVideo>>();
      final submittedQueries = <String>[];

      await tester.pumpWidget(
        _app(
          owners.consumer(
            searchLoader: (query) {
              submittedQueries.add(query);
              return searchCompleter.future;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('screen04-youtube-home-search')));
      await tester.pumpAndSettle();

      final surface = find.byKey(const Key('screen04-youtube-search-surface'));
      final input = find.byKey(const Key('screen04-youtube-search-input'));
      expect(surface, findsOneWidget);
      expect(input, findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
      expect(find.text('Filter loaded videos'), findsNothing);
      expect(
        find.textContaining('catalogue already on this screen'),
        findsNothing,
      );
      expect(find.textContaining('Loaded title'), findsNothing);
      expect(tester.getBottomRight(input).dy, lessThanOrEqualTo(844 - 320));
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pump();

      await tester.enterText(input, '  India news  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(submittedQueries, ['India news']);
      expect(
        find.byKey(const Key('screen04-youtube-search-loading')),
        findsOneWidget,
      );
      searchCompleter.complete([_video('searchRes01', 'India news live')]);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('screen04-youtube-search-results')),
        findsOneWidget,
      );
      expect(find.text('India news live'), findsOneWidget);
      await tester.tap(find.text('India news live'));
      await tester.pump();
      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
      expect(find.byTooltip('Back to YouTube Search results'), findsOneWidget);
      expect(find.byTooltip('Back to YouTube Home'), findsNothing);
      expect(surface, findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(surface, findsOneWidget);
      expect(find.text('India news live'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-youtube-search-back')));
      await tester.pumpAndSettle();
      expect(surface, findsNothing);
      expect(
        find.byKey(const Key('screen04-youtube-home-header')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C30C Watch search restores Watch and owns empty/error/retry', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);
    var attempts = 0;

    await tester.pumpWidget(
      _app(
        owners.consumer(
          searchLoader: (query) async {
            attempts += 1;
            if (query == 'nothing here') return const [];
            if (attempts == 2) throw StateError('provider unavailable');
            return [_video('retryRes001', 'Recovered result')];
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Provider home video'));
    await tester.pump();
    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
    expect(find.byTooltip('Back to YouTube Home'), findsOneWidget);
    expect(find.byTooltip('Back to YouTube Search results'), findsNothing);
    await tester.tap(find.byKey(const Key('screen04-youtube-watch-search')));
    await tester.pumpAndSettle();
    final input = find.byKey(const Key('screen04-youtube-search-input'));

    await tester.enterText(input, 'nothing here');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-youtube-search-empty')),
      findsOneWidget,
    );

    await tester.enterText(input, 'provider retry');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-youtube-search-error')),
      findsOneWidget,
    );
    expect(find.text('Search couldn’t load'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered result'), findsOneWidget);
    expect(attempts, 3);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
    expect(find.byTooltip('Back to YouTube Home'), findsOneWidget);
    expect(find.byTooltip('Back to YouTube Search results'), findsNothing);
    expect(find.text('Provider home video'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'RT-04B-01 process death restores Search query results and scroll',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      var now = DateTime.utc(2026, 8, 25, 6);
      final persistence = _SearchKeyValueStore();
      final firstCache = YouTubePublicSearchStateCache(now: () => now);
      await firstCache.configureDurability(
        DurableYouTubePublicSearchStateRepository(
          persistence: persistence,
          principalBinding: _binding(),
          now: () => now,
        ),
      );
      final firstOwners = _Owners();
      addTearDown(firstOwners.dispose);
      await tester.pumpWidget(
        _app(
          firstOwners.consumer(
            searchStateCache: firstCache,
            searchLoader: (query) async => List.generate(
              12,
              (index) => _video(
                'persisted${index.toString().padLeft(2, '0')}',
                'Persisted result $index',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('screen04-youtube-home-search')));
      await tester.pumpAndSettle();
      final input = find.byKey(const Key('screen04-youtube-search-input'));
      await tester.enterText(input, 'process death query');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      final results = find.byKey(const Key('screen04-youtube-search-results'));
      await tester.drag(results, const Offset(0, -700));
      await tester.pump(const Duration(milliseconds: 300));
      final firstList = tester.widget<ListView>(results);
      final storedOffset = firstList.controller!.offset;
      expect(storedOffset, greaterThan(0));
      await firstCache.settleDurableWrites();
      await tester.tap(find.textContaining('Persisted result').first);
      await tester.pump();
      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await firstCache.settleDurableWrites();
      now = now.add(const Duration(minutes: 1));
      final relaunchedCache = YouTubePublicSearchStateCache(now: () => now);
      expect(
        await relaunchedCache.configureDurability(
          DurableYouTubePublicSearchStateRepository(
            persistence: persistence,
            principalBinding: _binding(),
            now: () => now,
          ),
        ),
        YouTubePublicSearchFreshness.fresh,
      );
      var unexpectedReloads = 0;
      final relaunchedOwners = _Owners();
      addTearDown(relaunchedOwners.dispose);
      await tester.pumpWidget(
        _app(
          relaunchedOwners.consumer(
            searchStateCache: relaunchedCache,
            searchLoader: (query) async {
              unexpectedReloads += 1;
              return const [];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('screen04-youtube-search-surface')),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(input).controller?.text,
        'process death query',
      );
      expect(tester.widget<TextField>(input).autofocus, isFalse);
      expect(find.textContaining('Persisted result'), findsWidgets);
      expect(relaunchedCache.snapshot?.results, hasLength(12));
      final restoredList = tester.widget<ListView>(results);
      expect(restoredList.controller?.offset, closeTo(storedOffset, 1));
      expect(unexpectedReloads, 0);
      expect(find.byKey(const Key('screen04-video-watch')), findsNothing);

      await tester.tap(find.byKey(const Key('screen04-youtube-search-back')));
      await tester.pumpAndSettle();
      await relaunchedCache.settleDurableWrites();
      final afterClear = await DurableYouTubePublicSearchStateRepository(
        persistence: persistence,
        principalBinding: _binding(),
        now: () => now,
      ).read();
      expect(afterClear.freshness, YouTubePublicSearchFreshness.missing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RT-04B-01 late response cannot cross explicit Search close', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final response = Completer<List<Screen04YouTubePublicVideo>>();
    final cache = YouTubePublicSearchStateCache();
    final owners = _Owners();
    addTearDown(owners.dispose);
    await tester.pumpWidget(
      _app(
        owners.consumer(
          searchStateCache: cache,
          searchLoader: (_) => response.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-youtube-home-search')));
    await tester.pumpAndSettle();
    final input = find.byKey(const Key('screen04-youtube-search-input'));
    await tester.enterText(input, 'late response');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.tap(find.byKey(const Key('screen04-youtube-search-back')));
    await tester.pump();

    response.complete([_video('late0001', 'Late result')]);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('screen04-youtube-search-surface')),
      findsNothing,
    );
    expect(find.text('Late result'), findsNothing);
    expect(cache.snapshot, isNull);
    expect(tester.takeException(), isNull);
  });

  test(
    'RT-04B-01 authentication boundary clears durable Search state',
    () async {
      final repository = _SearchStateRepository();
      await youtubePublicSearchState.configureDurability(repository);
      youtubePublicSearchState.replace(
        submittedQuery: 'private local query',
        results: [
          mapScreen04VideoToYouTubePublicCatalogueItem(
            _video('boundary01', 'Boundary result'),
          ),
        ],
      );
      await youtubePublicSearchState.settleDurableWrites();
      final shared = SharedSession();
      addTearDown(shared.dispose);

      resetSocialV2RetainedStateForAuthenticationBoundary(shared);

      expect(youtubePublicSearchState.snapshot, isNull);
      await youtubePublicSearchState.settleDurableWrites();
      youtubePublicSearchState.replace(
        submittedQuery: 'second account query',
        results: const [],
      );
      await youtubePublicSearchState.settleDurableWrites();
      expect(repository.writes, 1);
      expect(repository.clears, 1);
    },
  );

  test(
    'C30C source removes commentary and reuses the real provider search',
    () {
      final consumer = File(
        'lib/ui_v2/social/social_v2_consumer.dart',
      ).readAsStringSync();
      final runtime = File(
        'lib/ui_v2/social/social_v2_youtube_public_runtime.dart',
      ).readAsStringSync();
      final mainSource = File('lib/main.dart').readAsStringSync();
      final appSource = File('lib/app/moolsocial_app.dart').readAsStringSync();

      for (final prohibited in const [
        'Filter loaded videos',
        'Filter the YouTube catalogue already on this screen',
        'Loaded title, channel or topic',
        'Apply filter',
        '_openYouTubeCatalogueSearch',
      ]) {
        expect(consumer, isNot(contains(prohibited)), reason: prohibited);
      }
      expect(consumer, contains("hintText: 'Search YouTube'"));
      expect(consumer, contains('class _YouTubeSearchSurface'));
      expect(consumer, contains('widget.youtubeSearchLoader'));
      expect(
        consumer,
        contains('youtubePublicSearchState.clear(detachRepository: true)'),
      );
      expect(consumer, contains('_discardDurableYouTubeSearch();'));
      expect(runtime, contains('loadScreen04YouTubePublicSearch('));
      expect(runtime, contains('collectScreen04YouTubeCatalogue('));
      expect(runtime, contains('query: submittedQuery'));
      expect(runtime, contains('pageToken: pageToken'));
      expect(runtime, contains('client.channelDetails('));
      expect(runtime, contains('isEligible: _isEligiblePublicVideo'));
      final searchHydration = mainSource.indexOf(
        'searchFreshness = await youtubePublicSearchState',
      );
      final appStart = mainSource.indexOf('runApp(\n    MoolSocialApp(');
      expect(searchHydration, greaterThan(-1));
      expect(appStart, greaterThan(searchHydration));
      expect(
        mainSource,
        contains('SecureStorageYouTubePublicSearchKeyValueStore()'),
      );
      expect(mainSource, contains('principalBinding: storedBinding'));
      expect(mainSource, contains('storedBinding.matches(currentBinding)'));
      final missingReceipt = mainSource.indexOf('if (storedBinding == null)');
      final currentBinding = mainSource.indexOf(
        'final currentBinding =',
        missingReceipt,
      );
      expect(missingReceipt, greaterThan(-1));
      expect(currentBinding, greaterThan(missingReceipt));
      expect(
        mainSource.substring(missingReceipt, currentBinding),
        contains("'youtube_search_state', 'degraded'"),
      );
      expect(
        mainSource,
        contains('youtubePublicSearchHydrationIsDegraded(searchFreshness)'),
      );
      expect(
        mainSource,
        isNot(contains("_showReleaseBootstrapFailure('youtube_search_state')")),
      );
      expect(
        mainSource,
        contains(
          'onAuthenticatedBoundary: '
          'bindYouTubeSearchStateToCurrentPrincipal',
        ),
      );
      expect(appSource, contains('this.onAuthenticatedBoundary'));
      expect(
        appSource,
        contains('_queueAuthenticationBoundary(onAuthenticatedBoundary)'),
      );
      expect(appSource, contains('_authenticationBoundaryTail.then<void>'));

      final homeHeaderStart = consumer.indexOf('class _YouTubeHomeHeader');
      final watchHeaderStart = consumer.indexOf('class _YouTubeWatchHeader');
      final searchSurfaceStart = consumer.indexOf(
        'class _YouTubeSearchSurface',
      );
      expect(homeHeaderStart, greaterThanOrEqualTo(0));
      expect(watchHeaderStart, greaterThan(homeHeaderStart));
      expect(searchSurfaceStart, greaterThan(watchHeaderStart));
      expect(
        consumer.substring(homeHeaderStart, watchHeaderStart),
        isNot(contains('_YouTubeAttribution')),
      );
      expect(
        consumer.substring(watchHeaderStart, searchSurfaceStart),
        isNot(contains('_YouTubeAttribution')),
      );
      expect(consumer, contains('class _YouTubeAttribution'));
      expect(consumer, contains("'Back to YouTube Search results'"));
      expect(consumer, contains("'Back to YouTube Home'"));
    },
  );
}

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
  home: child,
);

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer({
    required Screen04YouTubePublicSearchLoader searchLoader,
    YouTubePublicSearchStateCache? searchStateCache,
  }) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: 'videos',
    youtubePublicAccessOverride: true,
    youtubeCreatorAccessOverride: false,
    youtubeVideosLoader: () async => [
      _video('homeVid0001', 'Provider home video'),
    ],
    youtubeShortsLoader: () async => const [],
    youtubeSearchLoader: searchLoader,
    youtubeSearchStateCache: searchStateCache,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

final class _SearchKeyValueStore
    implements YouTubePublicCatalogueKeyValueStore {
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

final class _SearchStateRepository
    implements YouTubePublicSearchStateRepository {
  int writes = 0;
  int clears = 0;

  @override
  Future<YouTubePublicSearchRead> read() async => const YouTubePublicSearchRead(
    freshness: YouTubePublicSearchFreshness.missing,
  );

  @override
  Future<void> write(YouTubePublicSearchSnapshot snapshot) async {
    writes += 1;
  }

  @override
  Future<void> clear() async {
    clears += 1;
  }
}

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

VerifiedPrincipalBinding _binding([String hex = 'a']) =>
    VerifiedPrincipalBinding.fromStorage('v1:${hex * 64}');
