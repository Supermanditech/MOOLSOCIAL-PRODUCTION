import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'C29T reopens Videos and Shorts from snapshots while refresh is pending',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);
      final store = Screen04YouTubeCatalogueSnapshotStore();
      final videos = [_publicVideo('video-1', duration: 'PT4M')];
      final shorts = [_publicVideo('short-1', duration: 'PT30S')];

      await _mount(
        tester,
        owners.consumer(
          subAction: 'videos',
          store: store,
          videosLoader: () async => videos,
          shortsLoader: () async => shorts,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Provider title video-1'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final pendingVideos = Completer<List<Screen04YouTubePublicVideo>>();
      final pendingShorts = Completer<List<Screen04YouTubePublicVideo>>();
      await _mount(
        tester,
        owners.consumer(
          subAction: 'videos',
          store: store,
          videosLoader: () => pendingVideos.future,
          shortsLoader: () => pendingShorts.future,
        ),
      );
      await tester.pump();

      expect(find.text('Provider title video-1'), findsOneWidget);
      expect(
        find.byKey(const Key('screen04-youtube-videos-state-loading')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('screen04-rail-shorts')));
      await tester.pump();
      expect(
        find.byKey(const Key('screen04-shorts-page-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-youtube-shorts-state-loading')),
        findsNothing,
      );

      pendingVideos.completeError(StateError('offline'));
      pendingShorts.completeError(StateError('offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const Key('screen04-youtube-shorts-refresh-error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-shorts-page-view')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('screen04-rail-videos')));
      await tester.pump();
      expect(find.text('Provider title video-1'), findsOneWidget);
      expect(
        find.byKey(const Key('screen04-youtube-videos-refresh-error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-youtube-videos-state-error')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C29T expired snapshot uses only the in-surface cold start', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);
    var now = DateTime.utc(2026, 8, 11, 12);
    final store = Screen04YouTubeCatalogueSnapshotStore(
      timeToLive: const Duration(minutes: 5),
      now: () => now,
    );
    store.replaceVideos([_publicVideo('expired', duration: 'PT4M')]);
    store.replaceShorts([_publicVideo('expired-short', duration: 'PT30S')]);
    now = now.add(const Duration(minutes: 6));
    final pendingVideos = Completer<List<Screen04YouTubePublicVideo>>();
    final pendingShorts = Completer<List<Screen04YouTubePublicVideo>>();

    await _mount(
      tester,
      owners.consumer(
        subAction: 'videos',
        store: store,
        videosLoader: () => pendingVideos.future,
        shortsLoader: () => pendingShorts.future,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('screen04-youtube-videos-state-loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-youtube-home-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-youtube-home-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-youtube-home-account')),
      findsOneWidget,
    );
    expect(find.text('Provider title expired'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.byKey(const Key('screen04-youtube-home-search')));
    await tester.pump();
    expect(
      find.byKey(const Key('screen04-youtube-search-surface')),
      findsOneWidget,
    );

    pendingVideos.complete(const []);
    pendingShorts.complete(const []);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('C30T older catalogue retry cannot overwrite a newer result', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);
    final store = Screen04YouTubeCatalogueSnapshotStore()
      ..replaceVideos(const [])
      ..replaceShorts(const []);
    final videoRequests = [
      Completer<List<Screen04YouTubePublicVideo>>(),
      Completer<List<Screen04YouTubePublicVideo>>(),
    ];
    final shortRequests = [
      Completer<List<Screen04YouTubePublicVideo>>(),
      Completer<List<Screen04YouTubePublicVideo>>(),
    ];
    var videoCall = 0;
    var shortCall = 0;

    await _mount(
      tester,
      owners.consumer(
        subAction: 'videos',
        store: store,
        videosLoader: () => videoRequests[videoCall++].future,
        shortsLoader: () => shortRequests[shortCall++].future,
      ),
    );
    await tester.pump();

    expect(videoCall, 1);
    expect(shortCall, 1);
    await tester.tap(find.byKey(const Key('screen04-youtube-videos-retry')));
    await tester.pump();
    expect(videoCall, 2);
    expect(shortCall, 2);

    videoRequests[1].complete([_publicVideo('newer', duration: 'PT4M')]);
    shortRequests[1].complete(const []);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Provider title newer'), findsOneWidget);

    videoRequests[0].complete([_publicVideo('older', duration: 'PT4M')]);
    shortRequests[0].complete(const []);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Provider title newer'), findsOneWidget);
    expect(find.text('Provider title older'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'C30T cached video-watch deep link survives a failed network refresh',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);
      final store = Screen04YouTubeCatalogueSnapshotStore()
        ..replaceVideos([_publicVideo('cached-watch', duration: 'PT4M')])
        ..replaceShorts(const []);
      final videos = Completer<List<Screen04YouTubePublicVideo>>();
      final shorts = Completer<List<Screen04YouTubePublicVideo>>();

      await _mount(
        tester,
        owners.consumer(
          subAction: 'videos',
          initialState: 'video-watch',
          initialItem: 'cached-watch',
          store: store,
          videosLoader: () => videos.future,
          shortsLoader: () => shorts.future,
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
      expect(find.text('Provider title cached-watch'), findsOneWidget);

      videos.completeError(StateError('offline'));
      shorts.completeError(StateError('offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
      expect(find.text('Provider title cached-watch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C30T Shorts refresh clamps a removed active page', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);
    final store = Screen04YouTubeCatalogueSnapshotStore()
      ..replaceVideos(const [])
      ..replaceShorts([
        _publicVideo('short-1', duration: 'PT30S'),
        _publicVideo('short-2', duration: 'PT30S'),
        _publicVideo('short-3', duration: 'PT30S'),
      ]);
    var call = 0;

    await _mount(
      tester,
      owners.consumer(
        subAction: 'shorts',
        store: store,
        videosLoader: () async => const [],
        shortsLoader: () async {
          call += 1;
          if (call == 1) throw StateError('offline');
          return [_publicVideo('short-1', duration: 'PT30S')];
        },
      ),
    );
    await tester.pump();
    await tester.fling(
      find.byKey(const Key('screen04-shorts-page-view')),
      const Offset(0, -700),
      1200,
    );
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const Key('screen04-shorts-page-view')),
      const Offset(0, -700),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('screen04-youtube-short-short-3')),
      findsOneWidget,
    );

    final refreshNotice = find.byKey(
      const Key('screen04-youtube-shorts-refresh-error'),
    );
    expect(refreshNotice, findsOneWidget);
    await tester.tap(
      find.descendant(of: refreshNotice, matching: find.text('Retry')),
    );
    await tester.pumpAndSettle();

    expect(call, 2);
    expect(
      find.byKey(const ValueKey('screen04-youtube-short-short-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: child,
  ),
);

Screen04YouTubePublicVideo _publicVideo(
  String id, {
  required String duration,
}) => Screen04YouTubePublicVideo(
  videoId: id,
  title: 'Provider title $id',
  channelId: 'channel-$id',
  channelTitle: 'Provider channel',
  description: 'Provider description',
  thumbnailUrl: Uri.parse('https://i.ytimg.com/vi/$id/hqdefault.jpg'),
  publishedAt: DateTime.utc(2026, 8, 11),
  duration: duration,
  captionAvailable: true,
  viewCount: '100',
  likeCount: '10',
  commentCount: '1',
  embeddable: true,
  hasKnownDeviceRegionExclusion: false,
  hashtags: const ['#Shorts'],
);

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer({
    required String subAction,
    String? initialState,
    String? initialItem,
    required Screen04YouTubeCatalogueSnapshotStore store,
    required Screen04YouTubePublicVideoLoader videosLoader,
    required Screen04YouTubePublicVideoLoader shortsLoader,
  }) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: subAction,
    initialState: initialState,
    initialItem: initialItem,
    youtubePublicAccessOverride: true,
    youtubeCreatorAccessOverride: false,
    youtubeVideosLoader: videosLoader,
    youtubeShortsLoader: shortsLoader,
    youtubeCatalogueSnapshotStore: store,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}
