import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/screen04_universal_components.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'C29G Social plus separates YouTube and MoolSocial creator hosting',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();

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
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final shared = SharedSession();
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);

      await journey.start();
      expect(journey.isAuthenticated, isTrue);

      var openedMool = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 41),
              viewPadding: EdgeInsets.only(top: 41, bottom: 44),
            ),
            child: SocialUniversalV2(
              session: journey,
              creatorSession: creator,
              retailerSession: retailer,
              sharedSession: shared,
              youtubePublicAccessOverride: true,
              youtubeCreatorAccessOverride: true,
              youtubeVideosLoader: () async => [_video],
              youtubeShortsLoader: () async => [_short],
              onOpenMool: () => openedMool = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('screen04-youtube-home-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-youtube-home-shorts-shelf')),
        findsOneWidget,
      );
      expect(find.text('YouTube videos'), findsOneWidget);
      expect(find.text('YouTube Shorts'), findsOneWidget);
      expect(find.byType(Screen04Header), findsNothing);
      expect(find.text('India current affairs'), findsOneWidget);
      for (final id in const ['videos', 'shorts', 'create', 'feed']) {
        expect(find.byKey(Key('screen04-rail-$id')), findsOneWidget);
      }
      expect(find.byKey(const Key('social-global-chat')), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(
        tester
            .getSize(
              find.byKey(
                const Key('social-android-exported-semantics-clearance'),
              ),
            )
            .height,
        MoolLocalNavigationTokens.destinationRailHeight +
            moolAndroidExportedSemanticsClearance(
              viewPadding: const EdgeInsets.only(top: 41, bottom: 44),
              platform: TargetPlatform.android,
            ),
      );
      for (final key in const [
        Key('screen04-rail-videos'),
        Key('screen04-rail-shorts'),
        Key('screen04-rail-create'),
        Key('screen04-rail-feed'),
        Key('social-global-chat'),
      ]) {
        expect(
          tester.getSemantics(find.byKey(key)).rect.height,
          greaterThanOrEqualTo(44),
          reason: key.toString(),
        );
      }
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Open MoolSocial main menu'))
            .rect
            .height,
        greaterThanOrEqualTo(44),
      );
      semantics.dispose();

      await tester.tap(find.byKey(const Key('screen04-rail-shorts')));
      await tester.pump();
      expect(
        find.byKey(const Key('screen04-shorts-page-view')),
        findsOneWidget,
      );
      final shortsViewport = tester.getSize(
        find.byKey(const Key('screen04-shorts-page-view')),
      );
      final providerStage = tester.getSize(
        find.byKey(const Key('screen04-youtube-shorts-stage')),
      );
      expect(providerStage, shortsViewport);
      expect(
        tester
            .getTopLeft(find.byKey(const Key('screen04-youtube-shorts-stage')))
            .dy,
        41,
      );
      expect(
        find.byKey(const Key('screen04-youtube-shorts-stage-header')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('screen04-youtube-shorts-stage-metadata')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('screen04-youtube-short-save')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('screen04-youtube-short-discuss')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('screen04-youtube-home-header')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('screen04-rail-create')));
      await tester.pumpAndSettle();
      expect(find.byType(Screen04Header), findsNothing);
      expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);
      expect(find.byKey(const Key('screen04-context-tabs')), findsOneWidget);
      await tester.tap(find.byKey(const Key('screen04-create-post-entry')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-create-ownership-gateway')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('social-v2-create-workbench')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-create-youtube-short')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('screen04-create-tool-post')),
        findsOneWidget,
      );
      for (final id in const [
        'image',
        'carousel',
        'image-poll',
        'quick-poll',
        'quiz',
      ]) {
        expect(find.byKey(Key('screen04-create-tool-$id')), findsOneWidget);
      }
      expect(
        find.byKey(const Key('screen04-youtube-home-header')),
        findsNothing,
      );
      for (final commentary in const [
        'GATED',
        'OAuth',
        'Firebase-authenticated',
        'upload scope',
        'provider capability',
        'authorization requirements',
        'upload lifecycle',
        'will not simulate',
      ]) {
        expect(find.textContaining(commentary), findsNothing);
      }
      expect(find.byKey(const Key('screen04-create-tool-reel')), findsNothing);
      expect(
        find.byKey(const Key('screen04-create-tool-carousel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-create-tool-post')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
      expect(find.byKey(const Key('screen04-create-close')), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-create-close')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('screen04-rail-videos')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-youtube-home-header')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      expect(openedMool, isFalse);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'C30T OPPO Shorts provider stage begins below the exact system top inset',
    (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(720, 1612);
      tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 96);
      addTearDown(tester.view.reset);

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
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final shared = SharedSession();
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      await journey.start();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: SocialUniversalV2(
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
            initialSubAction: 'shorts',
            youtubePublicAccessOverride: true,
            youtubeCreatorAccessOverride: false,
            youtubeVideosLoader: () async => [_video],
            youtubeShortsLoader: () async => [_short],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pageRect = tester.getRect(
        find.byKey(const Key('screen04-shorts-page-view')),
      );
      final providerRect = tester.getRect(
        find.byKey(const Key('screen04-youtube-shorts-provider-owned')),
      );
      final stageRect = tester.getRect(
        find.byKey(const Key('screen04-youtube-shorts-stage')),
      );
      final dockRect = tester.getRect(
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );
      final systemUi = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byKey(const Key('screen04-system-ui-style')),
      );

      expect(tester.view.physicalSize, const Size(720, 1612));
      expect(tester.view.devicePixelRatio, 2);
      expect(
        MediaQuery.viewPaddingOf(tester.element(find.byType(Scaffold))),
        const EdgeInsets.only(top: 24, bottom: 48),
      );
      expect(pageRect.top, 24);
      expect(providerRect, pageRect);
      expect(stageRect, pageRect);
      expect(pageRect.bottom, lessThanOrEqualTo(dockRect.top));
      expect(systemUi.value.statusBarColor, Colors.transparent);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

final _video = Screen04YouTubePublicVideo(
  videoId: 'video123456',
  title: 'India current affairs',
  channelId: 'UCNEWS1',
  channelTitle: 'Public News',
  description: 'Current public news video.',
  thumbnailUrl: Uri.parse('https://i.ytimg.com/vi/video123456/hqdefault.jpg'),
  publishedAt: DateTime.utc(2026, 8, 11),
  duration: 'PT5M',
  captionAvailable: true,
  viewCount: '1000',
  likeCount: '100',
  commentCount: '10',
  embeddable: true,
  hasKnownDeviceRegionExclusion: false,
  hashtags: ['#India'],
);

final _short = Screen04YouTubePublicVideo(
  videoId: 'short123456',
  title: 'India news #Shorts',
  channelId: 'UCSHORT1',
  channelTitle: 'Public Shorts',
  description: 'Creator-declared public Short.',
  thumbnailUrl: Uri.parse('https://i.ytimg.com/vi/short123456/hqdefault.jpg'),
  publishedAt: DateTime.utc(2026, 8, 11),
  duration: 'PT45S',
  captionAvailable: true,
  viewCount: '2000',
  likeCount: '200',
  commentCount: '20',
  embeddable: true,
  hasKnownDeviceRegionExclusion: false,
  hashtags: ['#Shorts', '#India'],
);
