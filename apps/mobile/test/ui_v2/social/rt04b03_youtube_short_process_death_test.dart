import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_short_state_repository.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RT-04B-03 restores exact Short identity after reorder', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    var now = DateTime.utc(2026, 8, 25, 6);
    final persistence = _KeyValueStore();
    final firstCache = YouTubePublicShortStateCache(now: () => now);
    await firstCache.configureDurability(
      DurableYouTubePublicShortStateRepository(
        persistence: persistence,
        principalBinding: _binding(),
        now: () => now,
      ),
    );
    final firstShorts = [
      _short('short-1'),
      _short('short-2'),
      _short('short-3'),
    ];
    final firstStore = Screen04YouTubeCatalogueSnapshotStore()
      ..replaceVideos(const [])
      ..replaceShorts(firstShorts);
    final firstOwners = _Owners();
    addTearDown(firstOwners.dispose);
    await tester.pumpWidget(
      _app(
        firstOwners.consumer(
          shortCache: firstCache,
          catalogueStore: firstStore,
          shorts: firstShorts,
          initialSubAction: 'shorts',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final page = find.byKey(const Key('screen04-shorts-page-view'));
    await tester.fling(page, const Offset(0, -700), 1200);
    await tester.pumpAndSettle();
    await tester.fling(page, const Offset(0, -700), 1200);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('screen04-youtube-short-short-3')),
      findsOneWidget,
    );
    expect(firstCache.snapshot?.selectedVideoId, 'short-3');
    expect(firstCache.snapshot?.activeIndex, 2);
    await firstCache.settleDurableWrites();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    now = now.add(const Duration(minutes: 1));
    final relaunched = YouTubePublicShortStateCache(now: () => now);
    expect(
      await relaunched.configureDurability(
        DurableYouTubePublicShortStateRepository(
          persistence: persistence,
          principalBinding: _binding(),
          now: () => now,
        ),
      ),
      YouTubePublicShortFreshness.fresh,
    );
    final reordered = [_short('short-3'), _short('short-1'), _short('short-2')];
    final relaunchedStore = Screen04YouTubeCatalogueSnapshotStore()
      ..replaceVideos(const [])
      ..replaceShorts(reordered);
    final relaunchedOwners = _Owners();
    addTearDown(relaunchedOwners.dispose);
    await tester.pumpWidget(
      _app(
        relaunchedOwners.consumer(
          shortCache: relaunched,
          catalogueStore: relaunchedStore,
          shorts: reordered,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('screen04-youtube-short-short-3')),
      findsOneWidget,
    );
    expect(relaunched.snapshot?.selectedVideoId, 'short-3');
    expect(relaunched.snapshot?.activeIndex, 0);
    await tester.tap(find.byKey(const Key('screen04-rail-videos')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const Key('screen04-youtube-home-header')),
      findsOneWidget,
    );
    expect(relaunched.snapshot, isNull);
    await relaunched.settleDurableWrites();
    expect(
      (await DurableYouTubePublicShortStateRepository(
        persistence: persistence,
        principalBinding: _binding(),
        now: () => now,
      ).read()).freshness,
      YouTubePublicShortFreshness.missing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RT-04B-03 removed Short clears and falls back to page zero', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final cache = YouTubePublicShortStateCache()
      ..replace(
        selectedVideoId: 'removed-short',
        activeIndex: 1,
        catalogueVideoIds: const ['short-1', 'removed-short'],
      );
    final shorts = [_short('short-1'), _short('short-2')];
    final store = Screen04YouTubeCatalogueSnapshotStore()
      ..replaceVideos(const [])
      ..replaceShorts(shorts);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        owners.consumer(
          shortCache: cache,
          catalogueStore: store,
          shorts: shorts,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('screen04-shorts-page-view')), findsNothing);
    expect(cache.snapshot, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RT-04B-03 eligible projection ignores leading ineligible item', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final cache = YouTubePublicShortStateCache()
      ..replace(
        selectedVideoId: 'short-2',
        activeIndex: 1,
        catalogueVideoIds: const ['blocked-short', 'short-2'],
      );
    final shorts = [
      _short('blocked-short', embeddable: false),
      _short('short-2'),
    ];
    final store = Screen04YouTubeCatalogueSnapshotStore()
      ..replaceVideos(const [])
      ..replaceShorts(shorts);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        owners.consumer(
          shortCache: cache,
          catalogueStore: store,
          shorts: shorts,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('screen04-youtube-short-short-2')),
      findsOneWidget,
    );
    expect(cache.snapshot?.selectedVideoId, 'short-2');
    expect(cache.snapshot?.activeIndex, 0);
    expect(cache.snapshot?.catalogueVideoIds, ['short-2']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'RT-04B-03 selected Short becoming ineligible falls to page zero',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final cache = YouTubePublicShortStateCache()
        ..replace(
          selectedVideoId: 'short-2',
          activeIndex: 1,
          catalogueVideoIds: const ['short-1', 'short-2'],
        );
      final cached = [_short('short-1'), _short('short-2')];
      final refreshed = [
        _short('short-1'),
        _short('short-2', embeddable: false),
      ];
      final store = Screen04YouTubeCatalogueSnapshotStore()
        ..replaceVideos(const [])
        ..replaceShorts(cached);
      final owners = _Owners();
      addTearDown(owners.dispose);

      await tester.pumpWidget(
        _app(
          owners.consumer(
            shortCache: cache,
            catalogueStore: store,
            shorts: cached,
            loadedShorts: refreshed,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const ValueKey('screen04-youtube-short-short-1')),
        findsOneWidget,
      );
      expect(cache.snapshot, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RT-04B-03 explicit Videos route cannot be hijacked by Short', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final cache = YouTubePublicShortStateCache()
      ..replace(
        selectedVideoId: 'short-2',
        activeIndex: 1,
        catalogueVideoIds: const ['short-1', 'short-2'],
      );
    final shorts = [_short('short-1'), _short('short-2')];
    final store = Screen04YouTubeCatalogueSnapshotStore()
      ..replaceVideos([_video('video-1')])
      ..replaceShorts(shorts);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        owners.consumer(
          shortCache: cache,
          catalogueStore: store,
          shorts: shorts,
          initialSubAction: 'videos',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const Key('screen04-youtube-home-header')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('screen04-shorts-page-view')), findsNothing);
    expect(cache.snapshot, isNull);
    expect(tester.takeException(), isNull);
  });

  test('RT-04B-03 binder and payload exclude playback state', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final shortSource = File(
      'lib/features/shared/youtube_public_short_state_repository.dart',
    ).readAsStringSync();
    final consumer = File(
      'lib/ui_v2/social/social_v2_consumer.dart',
    ).readAsStringSync();

    expect(
      mainSource,
      contains('SecureStorageYouTubePublicShortKeyValueStore()'),
    );
    expect(mainSource, contains('bindingAttempt: shortBindingAttempt'));
    expect(mainSource, contains("'youtube_short_state', 'degraded'"));
    expect(
      consumer,
      contains('youtubePublicShortState.clear(detachRepository: true)'),
    );
    for (final prohibited in [
      'playbackPosition',
      'autoplay',
      'playerController',
      'mediaBytes',
    ]) {
      expect(shortSource, isNot(contains(prohibited)), reason: prohibited);
    }
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
    required YouTubePublicShortStateCache shortCache,
    required Screen04YouTubeCatalogueSnapshotStore catalogueStore,
    required List<Screen04YouTubePublicVideo> shorts,
    List<Screen04YouTubePublicVideo>? loadedShorts,
    String? initialSubAction,
  }) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: initialSubAction,
    youtubePublicAccessOverride: true,
    youtubeCreatorAccessOverride: false,
    youtubeVideosLoader: () async => catalogueStore.readVideos() ?? const [],
    youtubeShortsLoader: () async => loadedShorts ?? shorts,
    youtubeSearchLoader: (_) async => const [],
    youtubeCatalogueSnapshotStore: catalogueStore,
    youtubeShortStateCache: shortCache,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
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

Screen04YouTubePublicVideo _short(
  String id, {
  bool embeddable = true,
  String duration = 'PT30S',
}) => Screen04YouTubePublicVideo(
  videoId: id,
  title: 'Short $id',
  channelId: 'UC-$id',
  channelTitle: 'Provider channel',
  description: 'Creator-declared #Shorts item.',
  thumbnailUrl: Uri.https('i.ytimg.com', '/vi/$id/hqdefault.jpg'),
  publishedAt: DateTime.utc(2026, 8, 11),
  duration: duration,
  captionAvailable: true,
  viewCount: '1200',
  likeCount: '120',
  commentCount: '12',
  embeddable: embeddable,
  hasKnownDeviceRegionExclusion: false,
  hashtags: const ['#Shorts'],
);

Screen04YouTubePublicVideo _video(String id) => Screen04YouTubePublicVideo(
  videoId: id,
  title: 'Video $id',
  channelId: 'UC-$id',
  channelTitle: 'Provider channel',
  description: 'Public video.',
  thumbnailUrl: Uri.https('i.ytimg.com', '/vi/$id/hqdefault.jpg'),
  publishedAt: DateTime.utc(2026, 8, 11),
  duration: 'PT4M',
  captionAvailable: true,
  viewCount: '1200',
  likeCount: '120',
  commentCount: '12',
  embeddable: true,
  hasKnownDeviceRegionExclusion: false,
  hashtags: const ['#News'],
);
