import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/profile/global_personal_profile_v2.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'C30J signed-out viewer starts the distinct MoolSocial auth handoff',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      late final GoRouter router;
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => owners.consumer()),
          GoRoute(
            path: '/app/creator/youtube-connect',
            builder: (_, _) => const Scaffold(
              body: Center(
                child: Text(
                  'Authoritative YouTube channel status',
                  key: Key('c30j-youtube-status-destination'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/app/account/identity',
            builder: (_, _) => GlobalPersonalProfileV2(session: owners.journey),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Public provider video'), findsOneWidget);
      expect(find.byTooltip('YouTube channel status'), findsOneWidget);
      expect(find.byTooltip('Your MoolSocial profile'), findsOneWidget);
      expect(
        find.byKey(const Key('c30j-youtube-status-destination')),
        findsNothing,
      );
      expect(owners.journey.stage, JourneyStage.ready);
      expect(owners.journey.isAuthenticated, isFalse);

      await tester.tap(find.byKey(const Key('screen04-youtube-home-account')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
      expect(find.text('Your MoolSocial profile'), findsOneWidget);
      expect(
        find.byKey(const Key('youtube-connect-auth-explanation')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('global-profile-identity')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('global-personal-profile-v2')),
        findsOneWidget,
      );
      expect(find.text('Personal profile'), findsWidgets);
      await tester.tap(find.byKey(const Key('global-personal-profile-back')));
      await tester.pumpAndSettle();
      expect(find.text('Public provider video'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('screen04-youtube-home-channel-status')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('youtube-connect-auth-explanation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('c30j-youtube-status-destination')),
        findsNothing,
      );
      expect(owners.journey.stage, JourneyStage.ready);
      expect(
        owners.journey.authenticationPurpose,
        JourneyAuthenticationPurpose.general,
      );

      await tester.tap(find.byKey(const Key('youtube-connect-auth-continue')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('youtube-connect-auth-explanation')),
        findsNothing,
      );
      expect(owners.journey.stage, JourneyStage.signIn);
      expect(
        owners.journey.authenticationPurpose,
        JourneyAuthenticationPurpose.youtubeChannelConnection,
      );
      expect(owners.journey.returnTo, '/app/creator/youtube-connect');
      expect(owners.journey.readyRoute(), '/app/social?sub=videos');
      expect(tester.takeException(), isNull);
    },
  );

  test('C30J source separates MoolSocial account from YouTube status', () {
    final source = File(
      'lib/ui_v2/social/social_v2_consumer.dart',
    ).readAsStringSync();
    final headerStart = source.indexOf('class _YouTubeHomeHeader');
    final nextOwner = source.indexOf('class _YouTubeWatchHeader');
    expect(headerStart, greaterThanOrEqualTo(0));
    expect(nextOwner, greaterThan(headerStart));
    final header = source.substring(headerStart, nextOwner);

    expect(header, contains("tooltip: 'YouTube channel status'"));
    expect(header, contains('MoolGlobalProfileShortcutV2('));
    expect(header, contains('Icons.ondemand_video_outlined'));
    expect(header, isNot(contains('CircleAvatar')));
    const statusSignature = 'Future<void> _openYouTubeChannelStatus() async {';
    final statusStart = source.indexOf(statusSignature);
    final statusEnd = source.indexOf('void _openShortFromHome', statusStart);
    expect(statusStart, greaterThanOrEqualTo(0));
    expect(statusEnd, greaterThan(statusStart));
    final statusOwner = source.substring(statusStart, statusEnd);
    expect(
      statusOwner,
      contains('JourneyAuthenticationPurpose.youtubeChannelConnection'),
    );
    expect(
      statusOwner,
      contains("returnLocation: '/app/creator/youtube-connect'"),
    );
    expect(
      statusOwner,
      contains("context.push<void>('/app/creator/youtube-connect')"),
    );
    expect(
      source.contains('onChannelStatus: _openYouTubeChannelStatus'),
      isTrue,
    );
    expect(source.contains('onAccount: _openAccount'), isTrue);
    expect(
      source.contains('onCreateYouTubeShort: _openYouTubeChannelStatus'),
      isFalse,
    );

    final routerSource = File(
      'lib/features/journey01/journey_router.dart',
    ).readAsStringSync();
    final connectRouteStart = routerSource.indexOf(
      "path: '/app/creator/youtube-connect'",
    );
    final connectRouteEnd = routerSource.indexOf(
      "path: '/app/creator/content'",
      connectRouteStart,
    );
    expect(connectRouteStart, greaterThanOrEqualTo(0));
    expect(connectRouteEnd, greaterThan(connectRouteStart));
    final connectRoute = routerSource.substring(
      connectRouteStart,
      connectRouteEnd,
    );
    expect(connectRoute, contains('SocialYouTubeCreatorUploadScreen('));
    expect(connectRoute, isNot(contains('uploadCapabilityAuthorized:')));

    final connectionSource = File(
      'lib/ui_v2/social/social_v2_youtube_creator_upload.dart',
    ).readAsStringSync();
    expect(
      connectionSource,
      contains('this.uploadCapabilityAuthorized = false'),
    );
    expect(connectionSource, contains(': YouTubeConnectPurpose.readonly'));
  });
}

class _Owners {
  final journey = JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        areaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
      ),
    ),
    allowGuestReady: true,
  );
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer() => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: 'videos',
    youtubePublicAccessOverride: true,
    youtubeCreatorAccessOverride: false,
    youtubeVideosLoader: () async => [_video()],
    youtubeShortsLoader: () async => const [],
    youtubeSearchLoader: (_) async => const [],
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

Screen04YouTubePublicVideo _video() => Screen04YouTubePublicVideo(
  videoId: 'publicVideo01',
  title: 'Public provider video',
  channelId: 'UC-public-provider',
  channelTitle: 'Public provider channel',
  description: 'Public YouTube-hosted video available without user OAuth.',
  thumbnailUrl: Uri.https('i.ytimg.com', '/vi/publicVideo01/hqdefault.jpg'),
  publishedAt: DateTime.utc(2026, 8, 12),
  duration: 'PT2M30S',
  captionAvailable: true,
  viewCount: '1200',
  likeCount: '120',
  commentCount: '12',
  embeddable: true,
  hasKnownDeviceRegionExclusion: false,
  hashtags: const ['#Public'],
);
