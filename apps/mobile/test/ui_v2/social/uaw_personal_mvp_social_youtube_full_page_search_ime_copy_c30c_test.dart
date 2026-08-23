import 'dart:async';
import 'dart:io';

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

  test(
    'C30C source removes commentary and reuses the real provider search',
    () {
      final consumer = File(
        'lib/ui_v2/social/social_v2_consumer.dart',
      ).readAsStringSync();
      final runtime = File(
        'lib/ui_v2/social/social_v2_youtube_public_runtime.dart',
      ).readAsStringSync();

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
      expect(runtime, contains('loadScreen04YouTubePublicSearch('));
      expect(runtime, contains('client.search(query: submittedQuery)'));
      expect(runtime, contains('.where(_isEligiblePublicVideo)'));

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
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
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
