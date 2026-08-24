import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/screen04_universal_components.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

final _forbiddenScreen04Copy = RegExp(
  r'\b(?:example|sample|demo|mock|placeholder|prototype|founder review|'
  r'review build|implementation note|developer note|working note|internal '
  r'plan|state machine|payload|endpoint|next screen|for testing)\b',
  caseSensitive: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shared owners cannot expose the prototype Creator Studio', () {
    final sharedSource = File(
      'lib/features/shared/shared_models.dart',
    ).readAsStringSync();
    final routerSource = File(
      'lib/features/journey01/journey_router.dart',
    ).readAsStringSync();

    expect(
      sharedSource,
      isNot(contains(RegExp(r"primaryRoute:\s*'/app/creator(?:/[^']*)?'"))),
    );
    expect(sharedSource, contains("primaryRoute: '/app/social?sub=feed'"));
    expect(sharedSource, contains("primaryRoute: '/app/social?sub=create'"));
    expect(routerSource, contains("path: '/app/creator/youtube-connect'"));
  });

  testWidgets('Screen 04 opens with direct choices and one launcher', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, const Size(390, 844), 1, owners.consumer());

    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(find.byKey(const Key('screen04-context-tabs')), findsOneWidget);
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-youtube-videos-state-provider-access')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('screen04-search')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mool Buy opens the native Buy V2 route directly', (
    tester,
  ) async {
    final owners = _AuthenticatedOwners();
    addTearDown(owners.dispose);
    await owners.journey.start();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MoolSocialApp(
        session: owners.journey,
        creatorSession: owners.creator,
        retailerSession: owners.retailer,
        sharedSession: owners.shared,
        initialLocation: '/app/social',
      ),
    );
    await tester.pumpAndSettle();

    await _openConnectedAction(tester, family: 'buy', action: 'wholesale');
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(find.text('Retail and wholesale, in one place'), findsNothing);
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Social actions stay directly discoverable in the local rail', (
    tester,
  ) async {
    final owners = _Owners();
    await _pump(
      tester,
      const Size(320, 568),
      1.4,
      owners.consumer(world: 'social', sub: 'shorts'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-context-tabs')), findsOneWidget);
    for (final choice in screen04World('social').choices) {
      final action = find.byKey(Key('screen04-rail-${choice.id}'));
      expect(action, findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    }
    expect(find.byKey(const Key('screen04-rail-create')), findsOneWidget);
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(tester.takeException(), isNull);
    owners.dispose();
  });

  testWidgets(
    'every Social subaction survives connected-chooser open and system Back',
    (tester) async {
      const directRouteOwnerKeys = <String, Key>{
        'shorts': Key('screen04-youtube-shorts-state-provider-access'),
        'videos': Key('screen04-youtube-videos-state-provider-access'),
        'feed': Key('screen04-moolsocial-feed-state-empty'),
        'create': Key('screen04-create-workbench'),
      };
      for (final choice in screen04World('social').choices) {
        final owners = _AuthenticatedOwners();
        await owners.journey.start();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(
          MoolSocialApp(
            key: ValueKey('social-${choice.id}'),
            session: owners.journey,
            creatorSession: owners.creator,
            retailerSession: owners.retailer,
            sharedSession: owners.shared,
            initialLocation: '/app/social?sub=${choice.id}',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(directRouteOwnerKeys[choice.id]!),
          choice.id == 'videos' ? findsWidgets : findsOneWidget,
        );
        if (choice.id == 'create') {
          expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
          expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
          await tester.tap(find.byKey(const Key('screen04-create-close')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
            findsOneWidget,
          );
        } else {
          expect(
            find.byKey(const Key('screen04-context-tabs')),
            findsOneWidget,
          );
        }
        await tester.tap(find.byKey(const Key('mool-compact-launcher')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('mool-navigator-family-social')),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('mool-navigator-social-${choice.id}')),
          findsNothing,
        );

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
        if (choice.id == 'create') {
          expect(
            find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
            findsOneWidget,
          );
        } else {
          expect(
            find.byKey(directRouteOwnerKeys[choice.id]!),
            choice.id == 'videos' ? findsWidgets : findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull, reason: choice.id);
        owners.dispose();
      }
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    },
  );

  testWidgets('Create hides the dock until the composer closes', (
    tester,
  ) async {
    final owners = _AuthenticatedOwners();
    addTearDown(owners.dispose);
    await owners.journey.start();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MoolSocialApp(
        session: owners.journey,
        creatorSession: owners.creator,
        retailerSession: owners.retailer,
        sharedSession: owners.shared,
        initialLocation: '/app/social?sub=create',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen04-create-workbench')), findsOneWidget);
    expect(find.byKey(const Key('screen04-create-post-text')), findsOneWidget);
    expect(find.text('Reel'), findsNothing);
    expect(find.byKey(const Key('screen04-create-tool-reel')), findsNothing);
    expect(find.text('Carousel'), findsOneWidget);
    expect(find.text('Post'), findsWidgets);
    for (final key in const [
      Key('screen04-create-tool-post'),
      Key('screen04-create-tool-image'),
      Key('screen04-create-tool-carousel'),
      Key('screen04-create-tool-image-poll'),
      Key('screen04-create-tool-quick-poll'),
      Key('screen04-create-tool-quiz'),
    ]) {
      expect(find.byKey(key), findsOneWidget, reason: '$key');
    }
    expect(
      find.byKey(const Key('screen04-create-youtube-short')),
      findsNothing,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
    expect(find.byKey(const Key('social-global-chat')), findsNothing);
    expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);

    await tester.tap(find.byKey(const Key('screen04-create-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-workbench')), findsNothing);
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(find.byKey(const Key('social-global-chat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Chat and deeper destinations return to the exact Universal context',
    (tester) async {
      final owners = _AuthenticatedOwners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MoolSocialApp(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialLocation: '/app/social?sub=feed&world=work',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
      expect(find.text('Build trust for better work'), findsNothing);

      await _openConnectedChat(tester);
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

      expect(find.byKey(const Key('chat-back')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );

      await _openConnectedAction(tester, family: 'buy', action: 'wholesale');
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      await _openConnectedAction(tester, family: 'social', action: 'feed');
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Videos provider gate keeps its context through global Chat return',
    (tester) async {
      final owners = _AuthenticatedOwners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MoolSocialApp(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialLocation: '/app/social?sub=videos',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('screen04-youtube-videos-state-provider-access')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
      expect(find.byKey(const Key('screen04-context-tabs')), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(find.byKey(const Key('social-v2-tab-videos')), findsNothing);

      expect(find.byKey(const Key('social-global-chat')), findsOneWidget);
      await _openConnectedChat(tester);
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(find.byKey(const Key('chat-back')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
      expect(
        find.byKey(const Key('screen04-youtube-videos-state-provider-access')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen04-context-tabs')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Videos uses native Back and restores provider discovery', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final owners = _Owners();
    addTearDown(owners.dispose);
    final providerVideos = <Screen04YouTubePublicVideo>[
      Screen04YouTubePublicVideo(
        videoId: 'abc123XYZ09',
        title: 'Provider morning mobility',
        channelId: 'UC111',
        channelTitle: 'Provider wellness',
        description: 'A current provider-returned mobility session.',
        thumbnailUrl: Uri.https('i.ytimg.com', '/vi/abc123XYZ09/hqdefault.jpg'),
        publishedAt: DateTime.utc(2026, 8, 8),
        duration: 'PT5M4S',
        captionAvailable: true,
        viewCount: '1200000',
        likeCount: '38000',
        commentCount: '426',
        embeddable: true,
        hasKnownDeviceRegionExclusion: false,
        hashtags: const ['#Mobility'],
        channelDescription: 'Current public wellness videos.',
        subscriberCount: '684000',
        channelVideoCount: '312',
        channelViewCount: '86000000',
      ),
      Screen04YouTubePublicVideo(
        videoId: 'def456UVW10',
        title: 'Provider craft story',
        channelId: 'UC222',
        channelTitle: 'Provider makers',
        description: 'A current provider-returned story about makers.',
        thumbnailUrl: Uri.https('i.ytimg.com', '/vi/def456UVW10/hqdefault.jpg'),
        publishedAt: DateTime.utc(2026, 8, 7),
        duration: 'PT12M18S',
        captionAvailable: true,
        viewCount: '486000',
        likeCount: '21000',
        commentCount: '318',
        embeddable: true,
        hasKnownDeviceRegionExclusion: false,
        hashtags: const ['#Makers'],
        channelDescription: 'Current public maker stories.',
        subscriberCount: '1080000',
        channelVideoCount: '428',
        channelViewCount: '164000000',
      ),
    ];
    await _pump(
      tester,
      const Size(320, 568),
      1.4,
      owners.consumer(
        sub: 'videos',
        youtubePublicAccessOverride: true,
        youtubeVideosLoader: () async => providerVideos,
        youtubeShortsLoader: () async => const [],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final socialContext = tester.element(
      find.byKey(const Key('screen04-universal-v2')),
    );
    expect(MediaQuery.textScalerOf(socialContext).scale(10), closeTo(14, 0.01));

    final discoveryList = find.byType(ListView).last;
    await tester.drag(discoveryList, const Offset(0, -120));
    await tester.pump();
    final secondTitle = find.text('Provider craft story');
    await tester.ensureVisible(secondTitle);
    await tester.pump();
    final discoveryTop = tester.getTopLeft(secondTitle).dy;

    await tester.tap(secondTitle);
    await tester.pump();
    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
    expect(find.byKey(const Key('screen04-video-back')), findsNothing);
    for (final key in const [
      Key('screen04-video-share'),
      Key('screen04-video-details'),
      Key('screen04-video-details-trigger'),
      Key('screen04-video-channel-details'),
    ]) {
      final action = find.byKey(key);
      expect(action, findsOneWidget, reason: '$key');
      expect(
        tester.getSize(action).height,
        greaterThanOrEqualTo(44),
        reason: '$key',
      );
    }
    expect(find.byKey(const Key('screen04-video-save')), findsNothing);
    expect(find.byKey(const Key('screen04-video-discuss')), findsNothing);
    expect(find.text('MoolSocial discussion'), findsNothing);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Discuss'), findsNothing);
    expect(find.text('Like'), findsNothing);
    expect(find.text('Comment'), findsNothing);
    expect(find.text('Subscribe'), findsNothing);
    expect(find.text('Upload'), findsNothing);

    await tester.tap(find.byKey(const Key('screen04-video-details-trigger')));
    await tester.pumpAndSettle();
    expect(
      find.text('A current provider-returned story about makers.'),
      findsOneWidget,
    );
    expect(
      find.text('A current provider-returned mobility session.'),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('screen04-video-channel-details-sheet')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Current public maker stories.'), findsOneWidget);
    expect(find.text('Current public wellness videos.'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Description'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);

    final share = find.byKey(const Key('screen04-video-share'));
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.pump();
    expect(copiedText, 'https://www.youtube.com/watch?v=def456UVW10');
    expect(find.text('YouTube link copied'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(tester.getTopLeft(secondTitle).dy, closeTo(discoveryTop, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'YouTube video contains clipboard failure without false success',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'clipboard-unavailable');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final owners = _Owners();
      addTearDown(owners.dispose);
      final providerVideo = Screen04YouTubePublicVideo(
        videoId: 'ghi789RST11',
        title: 'Provider clipboard recovery',
        channelId: 'UC333',
        channelTitle: 'Provider recovery',
        description: 'A provider video used to verify link recovery.',
        thumbnailUrl: Uri.https('i.ytimg.com', '/vi/ghi789RST11/hqdefault.jpg'),
        publishedAt: DateTime.utc(2026, 8, 9),
        duration: 'PT3M12S',
        captionAvailable: true,
        viewCount: '4200',
        likeCount: '310',
        commentCount: '18',
        embeddable: true,
        hasKnownDeviceRegionExclusion: false,
        hashtags: const ['#Recovery'],
        channelDescription: 'Current public recovery videos.',
        subscriberCount: '27000',
        channelVideoCount: '81',
        channelViewCount: '1900000',
      );
      await _pump(
        tester,
        const Size(360, 720),
        1,
        owners.consumer(
          sub: 'videos',
          youtubePublicAccessOverride: true,
          youtubeVideosLoader: () async => [providerVideo],
          youtubeShortsLoader: () async => const [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Provider clipboard recovery'));
      await tester.pump();
      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('screen04-video-share')));
      await tester.tap(find.byKey(const Key('screen04-video-share')));
      await tester.pump();

      expect(
        find.text('YouTube link could not be copied. Try again.'),
        findsOneWidget,
      );
      expect(find.text('YouTube link copied'), findsNothing);
      expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('YouTube Shorts show finished recovery copy when unavailable', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(
      tester,
      const Size(360, 720),
      1,
      owners.consumer(sub: 'shorts'),
    );

    final providerAccess = find.byKey(
      const Key('screen04-youtube-shorts-state-provider-access'),
    );
    expect(providerAccess, findsOneWidget);
    expect(
      find.text('YouTube Shorts are unavailable right now'),
      findsOneWidget,
    );
    expect(find.text('Please try again later.'), findsOneWidget);
    expect(
      find.textContaining('will not replace it with unverified videos'),
      findsNothing,
    );
    expect(find.byKey(const Key('screen04-shorts-page-view')), findsNothing);
    expect(
      find.byKey(const Key('screen04-short-media-moolsocial')),
      findsNothing,
    );
    expect(find.text('For You'), findsNothing);
    expect(find.text('Promoted'), findsNothing);
    expect(find.text('Like'), findsNothing);
    expect(find.text('Comment'), findsNothing);
    expect(find.text('Remix'), findsNothing);
    expect(find.text('Upload'), findsNothing);
    expect(tester.getSize(providerAccess).height, greaterThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'provider-returned Short owns the full available viewport without local overlays',
    (tester) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      final providerShort = Screen04YouTubePublicVideo(
        videoId: 'abc123XYZ09',
        title: 'A public creator-labelled Short',
        channelId: 'UC123',
        channelTitle: 'Public creator',
        description: 'Provider-returned public Short description.',
        thumbnailUrl: Uri.https('i.ytimg.com', '/vi/abc123XYZ09/hqdefault.jpg'),
        publishedAt: DateTime.utc(2026, 8, 10),
        duration: 'PT42S',
        captionAvailable: true,
        viewCount: '12000',
        likeCount: '900',
        commentCount: '45',
        embeddable: true,
        hasKnownDeviceRegionExclusion: false,
        hashtags: const ['#Shorts'],
        subscriberCount: '3400',
      );
      await _pump(
        tester,
        const Size(320, 568),
        1.4,
        owners.consumer(
          sub: 'shorts',
          youtubePublicAccessOverride: true,
          youtubeVideosLoader: () async => const [],
          youtubeShortsLoader: () async => [providerShort],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const Key('screen04-shorts-page-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-youtube-shorts-provider-owned')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-short-media-youtube-live')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-youtube-shorts-stage-header')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('screen04-youtube-shorts-stage')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-youtube-shorts-stage-metadata')),
        findsNothing,
      );
      final pageRect = tester.getRect(
        find.byKey(const Key('screen04-shorts-page-view')),
      );
      final providerRect = tester.getRect(
        find.byKey(const Key('screen04-youtube-shorts-provider-owned')),
      );
      final stageRect = tester.getRect(
        find.byKey(const Key('screen04-youtube-shorts-stage')),
      );
      final playerRect = tester.getRect(
        find.byKey(const Key('screen04-short-media-youtube-live')),
      );
      expect(providerRect, pageRect);
      expect(stageRect, pageRect);
      expect(playerRect, pageRect);
      expect(playerRect.width, greaterThanOrEqualTo(200));
      expect(playerRect.height, greaterThanOrEqualTo(200));
      expect(find.text('A public creator-labelled Short'), findsNothing);
      expect(find.text('Public creator'), findsNothing);
      expect(
        find.textContaining('YouTube hosts and plays this Short'),
        findsNothing,
      );

      for (final key in const [
        Key('screen04-youtube-short-save'),
        Key('screen04-youtube-short-discuss'),
        Key('screen04-youtube-short-share'),
        Key('screen04-youtube-short-channel'),
        Key('screen04-youtube-short-open'),
      ]) {
        expect(find.byKey(key), findsNothing, reason: '$key');
      }
      expect(find.text('Like'), findsNothing);
      expect(find.text('Comment'), findsNothing);
      expect(find.text('Subscribe'), findsNothing);
      expect(find.text('Remix'), findsNothing);
      expect(find.text('Upload'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('guest Feed stays truthful and hands Create to real sign-in', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, const Size(390, 844), 1, owners.consumer(sub: 'feed'));
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-brand')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('screen04-quick-post-feed')), findsNothing);
    expect(find.text('Meera Rathore'), findsNothing);
    expect(find.text('Explore featured products'), findsNothing);

    final create = find.byKey(const Key('screen04-feed-create-post'));
    expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-workbench')), findsNothing);
    expect(owners.journey.stage, JourneyStage.signIn);
    expect(owners.journey.returnTo, '/app/social?sub=create');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every Mool main action and Social subaction stays visible and exact',
    (tester) async {
      final owners = _AuthenticatedOwners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MoolSocialApp(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialLocation: '/app/social',
        ),
      );
      await tester.pumpAndSettle();

      const destinationKeys = <String, Key>{
        'social': Key('screen04-universal-v2'),
        'buy': Key('buy-v2-screen'),
        'eat': Key('eat-home-screen'),
        'ride': Key('ride-booking-screen'),
        'book': Key('book-doctor'),
        'work': Key('work-earn-screen'),
      };
      for (final family in moolActionFamilies) {
        await _openConnectedAction(
          tester,
          family: family.id,
          action: family.actions.first.id,
        );
        expect(
          find.byKey(destinationKeys[family.id]!),
          findsOneWidget,
          reason: family.id,
        );
        expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      }

      final social = screen04World('social');
      const localDockOwnerKeys = <String, Key>{
        'shorts': Key('screen04-youtube-shorts-state-provider-access'),
        'videos': Key('screen04-youtube-videos-state-provider-access'),
        'feed': Key('screen04-moolsocial-feed-state-empty'),
        'create': ValueKey('screen04-create-workbench'),
      };
      for (final choice in social.choices) {
        await _openConnectedAction(tester, family: 'social', action: choice.id);
        expect(
          find.byKey(localDockOwnerKeys[choice.id]!),
          choice.id == 'videos' ? findsWidgets : findsOneWidget,
        );
        if (choice.id == 'create') {
          expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
          expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
          await tester.tap(find.byKey(const Key('screen04-create-close')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
            findsOneWidget,
          );
        } else {
          expect(
            find.byKey(const Key('screen04-context-tabs')),
            findsOneWidget,
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  const sizes = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 720),
    Size(375, 667),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
  ];

  for (final size in sizes) {
    for (final scale in const [1.0, 1.4]) {
      testWidgets('all Screen 04 worlds and choices fit '
          '${size.width.toInt()}x${size.height.toInt()} at '
          '${(scale * 100).round()}%', (tester) async {
        for (final world in screen04Worlds) {
          for (final choice in world.choices) {
            final owners = _Owners();
            await _pump(
              tester,
              size,
              scale,
              owners.consumer(world: world.id, sub: choice.id),
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${world.id}/${choice.id}',
            );
            _expectCustomerCopy(tester, '${world.id}/${choice.id}');
            owners.dispose();
          }
        }
      });
    }
  }

  testWidgets('Screen 04 header actions expose customer destinations', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, const Size(390, 844), 1, owners.consumer(world: 'buy'));

    await tester.tap(find.byKey(const Key('screen04-area')));
    await tester.pumpAndSettle();
    expect(find.text('Serviceable area'), findsWidgets);
    expect(find.byKey(const Key('screen04-area-input')), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-notifications')));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Your MoolSocial account'), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-account-youtube-connection')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('screen04-account-sign-out')), findsOneWidget);
    expect(find.text('Creator workspace'), findsNothing);
    expect(find.textContaining('Minimum read-only access'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('social-v2-search-input')), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-scan')));
    await tester.pumpAndSettle();
    expect(find.text('Scan a code'), findsWidgets);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-voice')));
    await tester.pumpAndSettle();
    expect(find.text('Voice search'), findsOneWidget);
    expect(tester.takeException(), isNull);
    _expectCustomerCopy(tester, 'header actions');
  });

  testWidgets('authenticated account shows identity and switching action', (
    tester,
  ) async {
    final owners = _AuthenticatedOwners();
    addTearDown(owners.dispose);
    await owners.journey.start();
    await _pump(
      tester,
      const Size(390, 844),
      1,
      SocialUniversalV2(
        session: owners.journey,
        creatorSession: owners.creator,
        retailerSession: owners.retailer,
        sharedSession: owners.shared,
        initialWorld: 'buy',
      ),
    );

    await tester.tap(find.byKey(const Key('screen04-profile')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('screen04-account-authenticated-identity')),
      findsOneWidget,
    );
    expect(find.text('Test Member'), findsOneWidget);
    expect(find.text('member@example.com · Google'), findsOneWidget);
    expect(find.text('Sign out or switch account'), findsOneWidget);
  });
}

Future<void> _openConnectedAction(
  WidgetTester tester, {
  required String family,
  required String action,
}) async {
  await tester.tap(find.byKey(const Key('mool-compact-launcher')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('mool-navigator-family-$family')));
  await tester.pumpAndSettle();
  if (moolDefaultActionForFamily(family).id != action) {
    final localKey = switch (family) {
      'social' => 'screen04-rail-$action',
      'buy' => 'buy-local-tab-$action',
      'eat' => 'eat-local-$action',
      'ride' => 'ride-local-$action',
      'book' => 'care-local-$action',
      'work' => 'work-local-$action',
      _ => throw StateError('Unknown family: $family'),
    };
    await tester.tap(find.byKey(Key(localKey)));
    await tester.pumpAndSettle();
  }
}

Future<void> _openConnectedChat(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('social-global-chat')));
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double textScale,
  Widget child,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: child,
    ),
  );
  await tester.pump();
}

void _expectCustomerCopy(WidgetTester tester, String state) {
  final copy = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    copy.add(text.data ?? text.textSpan?.toPlainText() ?? '');
  }
  for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
    copy.addAll([
      field.decoration?.labelText ?? '',
      field.decoration?.hintText ?? '',
      field.decoration?.helperText ?? '',
    ]);
  }
  for (final semantics in tester.widgetList<Semantics>(
    find.byType(Semantics),
  )) {
    copy.add(semantics.properties.label ?? '');
    copy.add(semantics.properties.tooltip ?? '');
  }
  final visible = copy.where((value) => value.trim().isNotEmpty).join('\n');
  expect(
    _forbiddenScreen04Copy.hasMatch(visible),
    isFalse,
    reason: '$state exposed non-customer copy:\n$visible',
  );
}

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer({
    String world = 'social',
    String? sub,
    bool? youtubePublicAccessOverride,
    Screen04YouTubePublicVideoLoader? youtubeVideosLoader,
    Screen04YouTubePublicVideoLoader? youtubeShortsLoader,
  }) {
    return SocialUniversalV2(
      session: journey,
      creatorSession: creator,
      retailerSession: retailer,
      sharedSession: shared,
      initialWorld: world,
      initialSubAction: sub,
      youtubePublicAccessOverride: youtubePublicAccessOverride,
      youtubeVideosLoader: youtubeVideosLoader,
      youtubeShortsLoader: youtubeShortsLoader,
    );
  }

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

class _AuthenticatedOwners {
  final journey = JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        areaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
    accountIdentityGateway: ReviewAuthenticatedAccountIdentityGateway(
      identity: const AuthenticatedAccountIdentity(
        displayName: 'Test Member',
        emailAddress: 'member@example.com',
        signInMethods: ['Google'],
      ),
    ),
  );
  final creator = CreatorSession()..creatorWorkspaceActive = true;
  final retailer = RetailerSession();
  final shared = SharedSession();

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}
