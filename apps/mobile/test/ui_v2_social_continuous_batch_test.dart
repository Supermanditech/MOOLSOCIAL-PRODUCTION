import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/creator/creator_models.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_creator.dart';
import 'package:moolsocial/ui_v2/social/social_v2_plans_promotion.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_connect.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Social UI V2 consumer journeys', () {
    testWidgets('Shorts fail closed when provider access is unavailable', (
      tester,
    ) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await _pump(
        tester,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: 'shorts',
        ),
      );

      expect(
        find.byKey(const Key('screen04-youtube-shorts-state-provider-access')),
        findsOneWidget,
      );
      expect(
        find.text('YouTube Shorts are unavailable right now'),
        findsOneWidget,
      );
      expect(find.text('Please try again later.'), findsOneWidget);
      expect(find.text('Fresh basket packed this morning'), findsNothing);
      expect(find.text('Meet Rajasthan makers this week'), findsNothing);
      expect(find.text('Promoted'), findsNothing);
      expect(find.text('Like'), findsNothing);
      expect(find.text('Remix'), findsNothing);
      expect(find.text('Upload'), findsNothing);
    });

    testWidgets('Video, Feed and Create are one-tap destinations', (
      tester,
    ) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await _pump(
        tester,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
        ),
      );

      await _pump(
        tester,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: 'videos',
        ),
      );
      expect(
        find.byKey(const Key('screen04-youtube-videos-state-provider-access')),
        findsOneWidget,
      );
      expect(
        find.text('YouTube Videos are unavailable right now'),
        findsOneWidget,
      );
      expect(find.text('Please try again later.'), findsOneWidget);
      expect(find.text('Live'), findsNothing);
      expect(find.text('Learning'), findsNothing);
      expect(find.text('Local'), findsNothing);
      expect(find.text('Business'), findsNothing);
      expect(find.text('5-minute morning mobility'), findsNothing);

      await _pump(
        tester,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: 'feed',
        ),
      );
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-feed-create-post')),
        findsOneWidget,
      );
      expect(find.text('Nearby'), findsNothing);
      expect(find.text('Fresh arrivals near Khema-Ka-Kuwa'), findsNothing);

      await _pump(
        tester,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: 'create',
          initialState: 'text',
        ),
      );
      expect(
        find.byKey(const Key('screen04-create-workbench')),
        findsOneWidget,
      );
      for (final key in const [
        'screen04-create-tool-post',
        'screen04-create-tool-image',
        'screen04-create-tool-carousel',
        'screen04-create-tool-image-poll',
        'screen04-create-tool-quick-poll',
        'screen04-create-tool-quiz',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      expect(
        find.byKey(const Key('screen04-create-youtube-short')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('screen04-create-post-text')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-create-tool-image')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-create-tool-image-poll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-create-tool-quick-poll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-create-tool-quiz')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
    });

    testWidgets(
      'Videos provider gate keeps compact MoolSocial and direct Social rail',
      (tester) async {
        final owners = _Owners();
        addTearDown(owners.dispose);
        await _pump(
          tester,
          SocialUniversalV2(
            session: owners.journey,
            creatorSession: owners.creator,
            retailerSession: owners.retailer,
            sharedSession: owners.shared,
            initialSubAction: 'videos',
          ),
        );

        expect(
          find.byKey(
            const Key('screen04-youtube-videos-state-provider-access'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        expect(find.byKey(const Key('social-global-chat')), findsOneWidget);
        expect(find.byKey(const Key('screen04-rail-videos')), findsOneWidget);
        expect(find.byKey(const Key('mool-root-chat')), findsNothing);
        expect(find.byKey(const Key('social-v2-tab-feed')), findsNothing);
      },
    );

    testWidgets('YouTube account action opens the channel-status owner', (
      tester,
    ) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      expect(owners.journey.isAuthenticated, isTrue);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => MediaQuery(
              data: const MediaQueryData(size: Size(390, 844)),
              child: SocialUniversalV2(
                session: owners.journey,
                creatorSession: owners.creator,
                retailerSession: owners.retailer,
                sharedSession: owners.shared,
                initialSubAction: 'videos',
                youtubePublicAccessOverride: true,
                youtubeVideosLoader: () async => [_accountVideo],
                youtubeShortsLoader: () async => const [],
              ),
            ),
          ),
          GoRoute(
            path: '/app/creator/youtube-connect',
            builder: (_, _) => const Scaffold(
              body: Text(
                'Authoritative YouTube channel status',
                key: Key('continuous-youtube-status-owner'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account access video'), findsOneWidget);
      expect(find.byTooltip('YouTube channel status'), findsOneWidget);
      expect(find.byTooltip('MoolSocial account'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('screen04-youtube-home-channel-status')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('continuous-youtube-status-owner')),
        findsOneWidget,
      );
    });

    testWidgets('guest YouTube action explains the two account steps first', (
      tester,
    ) async {
      final owners = _GuestOwners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      await _pump(
        tester,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: 'videos',
          youtubePublicAccessOverride: true,
          youtubeVideosLoader: () async => [_accountVideo],
          youtubeShortsLoader: () async => const [],
        ),
      );

      await tester.tap(
        find.byKey(const Key('screen04-youtube-home-channel-status')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('youtube-connect-auth-explanation')),
        findsOneWidget,
      );
      expect(find.text('Connect your YouTube channel'), findsOneWidget);
      expect(
        find.textContaining('sign in to your MoolSocial account'),
        findsOneWidget,
      );
      expect(
        find.textContaining('This is separate from YouTube'),
        findsOneWidget,
      );
      expect(find.textContaining('existing Google account'), findsOneWidget);
      expect(find.textContaining('read-only access'), findsOneWidget);
      expect(owners.journey.stage, JourneyStage.ready);
    });

    testWidgets('guest can cancel YouTube explanation without entering auth', (
      tester,
    ) async {
      final owners = _GuestOwners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      await _pump(
        tester,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: 'videos',
          youtubePublicAccessOverride: true,
          youtubeVideosLoader: () async => [_accountVideo],
          youtubeShortsLoader: () async => const [],
        ),
      );

      await tester.tap(
        find.byKey(const Key('screen04-youtube-home-channel-status')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('youtube-connect-auth-cancel')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('youtube-connect-auth-explanation')),
        findsNothing,
      );
      expect(owners.journey.stage, JourneyStage.ready);
      expect(
        owners.journey.authenticationPurpose,
        JourneyAuthenticationPurpose.general,
      );
    });

    testWidgets('guest can dismiss YouTube explanation through the barrier', (
      tester,
    ) async {
      final owners = _GuestOwners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      await _pump(
        tester,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: 'videos',
          youtubePublicAccessOverride: true,
          youtubeVideosLoader: () async => [_accountVideo],
          youtubeShortsLoader: () async => const [],
        ),
      );

      await tester.tap(
        find.byKey(const Key('screen04-youtube-home-channel-status')),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('youtube-connect-auth-explanation')),
        findsNothing,
      );
      expect(owners.journey.stage, JourneyStage.ready);
      expect(owners.journey.isAuthenticated, isFalse);
    });

    testWidgets(
      'guest YouTube continuation enters exact MoolSocial auth state',
      (tester) async {
        final owners = _GuestOwners();
        addTearDown(owners.dispose);
        await owners.journey.start();
        await _pump(
          tester,
          SocialUniversalV2(
            session: owners.journey,
            creatorSession: owners.creator,
            retailerSession: owners.retailer,
            sharedSession: owners.shared,
            initialSubAction: 'videos',
            youtubePublicAccessOverride: true,
            youtubeVideosLoader: () async => [_accountVideo],
            youtubeShortsLoader: () async => const [],
          ),
        );

        await tester.tap(
          find.byKey(const Key('screen04-youtube-home-channel-status')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('youtube-connect-auth-continue')),
        );
        await tester.pumpAndSettle();

        expect(owners.journey.stage, JourneyStage.signIn);
        expect(owners.journey.returnTo, '/app/creator/youtube-connect');
        expect(owners.journey.readyRoute(), '/app/social?sub=videos');
        expect(
          owners.journey.authenticationPurpose,
          JourneyAuthenticationPurpose.youtubeChannelConnection,
        );
      },
    );

    testWidgets('Feed owns a truthful MoolSocial empty state and post action', (
      tester,
    ) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      await tester.pumpWidget(
        MoolSocialApp(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialLocation: '/app/social?sub=feed',
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-brand')),
        findsOneWidget,
      );
      expect(find.text('PUBLIC FEED'), findsOneWidget);
      expect(
        find.byKey(const Key('screen04-feed-create-post')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-feed-discover-people')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-feed-start-conversation')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen04-quick-post-feed')), findsNothing);

      await tester.tap(find.byKey(const Key('screen04-feed-discover-people')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-section-body-discover')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('screen04-feed-start-conversation')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-section-body-chats')),
        findsOneWidget,
      );
      expect(find.text('All'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Creator, plans and promotion owners', () {
    testWidgets('Creator Studio reuses CreatorSession publishing state', (
      tester,
    ) async {
      final session = CreatorSession()..creatorWorkspaceActive = true;
      addTearDown(session.dispose);
      await _pump(
        tester,
        CreatorSocialV2Screen(
          session: session,
          owner: CreatorSocialV2Owner.publish,
        ),
      );

      await tester.tap(find.text('Gallery'));
      await tester.pump();
      expect(session.mediaSelected, isTrue);
      final rights = find.byType(CheckboxListTile).first;
      await tester.ensureVisible(rights);
      await tester.pumpAndSettle();
      await tester.tap(rights);
      await tester.pump();
      expect(session.rightsConfirmed, isTrue);
    });

    testWidgets('failed publishing can return to editable content', (
      tester,
    ) async {
      final session = CreatorSession()..creatorWorkspaceActive = true;
      addTearDown(session.dispose);
      await _pump(
        tester,
        CreatorSocialV2Screen(
          session: session,
          owner: CreatorSocialV2Owner.publish,
          initialState: 'partial',
        ),
      );

      final review = find.byKey(const Key('social-v2-review-publish-content'));
      expect(review, findsOneWidget);
      await tester.tap(review);
      await tester.pumpAndSettle();

      expect(find.text('Choose publishing destinations'), findsOneWidget);
      expect(find.text('Review content'), findsNothing);
    });

    testWidgets('Creator Content Library filters through CreatorSession', (
      tester,
    ) async {
      final session = CreatorSession()..creatorWorkspaceActive = true;
      addTearDown(session.dispose);
      await _pump(
        tester,
        CreatorSocialV2Screen(
          session: session,
          owner: CreatorSocialV2Owner.library,
        ),
      );
      expect(find.text('How local baskets save time'), findsOneWidget);
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      expect(session.contentTab.name, 'drafts');
      expect(find.text('Creator introduction'), findsOneWidget);
    });

    testWidgets(
      'YouTube Connect validates and publishes through CreatorSession',
      (tester) async {
        final session = CreatorSession();
        addTearDown(session.dispose);
        await _pump(tester, SocialYouTubeConnectV2Screen(session: session));

        await tester.enterText(
          find.byKey(const Key('social-v2-youtube-url')),
          'https://youtube.com/watch?v=moolsocial',
        );
        await _scrollToAndTap(
          tester,
          find.byKey(const Key('social-v2-youtube-validate')),
        );
        expect(session.youtubeValidated, isTrue);
        expect(session.youtubeStep, YouTubeConnectStep.action);
        expect(find.text('Add post details'), findsOneWidget);

        await _scrollToAndTap(tester, find.text('Buy'));
        await _scrollToAndTap(
          tester,
          find.widgetWithText(
            CheckboxListTile,
            'I have permission to share this video',
          ),
        );
        await _scrollToAndTap(
          tester,
          find.widgetWithText(
            CheckboxListTile,
            'The post information is accurate',
          ),
        );
        await _scrollToAndTap(
          tester,
          find.byKey(const Key('social-v2-youtube-action-next')),
        );
        await _scrollToAndTap(
          tester,
          find.byKey(const Key('social-v2-youtube-publish')),
        );
        expect(session.youtubeConnectedPostId, isNotNull);
        expect(find.text('Your YouTube post is live'), findsOneWidget);
      },
    );

    testWidgets(
      'global Social rail leaves an imperatively opened YouTube workflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final owners = _Owners();
        addTearDown(owners.dispose);
        await owners.journey.start();
        await tester.pumpWidget(
          MoolSocialApp(
            session: owners.journey,
            creatorSession: owners.creator,
            retailerSession: owners.retailer,
            sharedSession: owners.shared,
            initialLocation: '/app/creator/publish',
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Video'));
        await tester.pumpAndSettle();
        final connect = find.text('Connect a YouTube video');
        await tester.ensureVisible(connect);
        await tester.pumpAndSettle();
        await tester.tap(connect);
        await tester.pumpAndSettle();
        expect(find.text('Share from YouTube'), findsOneWidget);

        await tester.tap(find.byKey(const Key('social-v2-tab-videos')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const Key('screen04-youtube-videos-state-provider-access'),
          ),
          findsOneWidget,
        );
        expect(find.text('5-minute morning mobility'), findsNothing);
      },
    );

    testWidgets('plan-detail Social rail reaches the selected destination', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      await tester.pumpWidget(
        MoolSocialApp(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialLocation: '/app/account/plans',
        ),
      );
      await tester.pumpAndSettle();
      final creatorPro = find.text('Check Creator Pro');
      await tester.ensureVisible(creatorPro);
      await tester.pumpAndSettle();
      await tester.tap(creatorPro);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('social-v2-tab-feed')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
    });

    testWidgets('plan activation requires explicit launch-access consent', (
      tester,
    ) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await _pump(
        tester,
        SocialPlansV2Screen(
          sharedSession: owners.shared,
          retailerSession: owners.retailer,
          creatorSession: owners.creator,
        ),
      );
      await _scrollToAndTap(tester, find.text('Check Creator Pro'));
      await _scrollToAndTap(
        tester,
        find.byKey(const Key('social-v2-open-plan-activation')),
      );
      final activate = find.byKey(const Key('social-v2-activate-plan'));
      await _scrollToAndTap(tester, activate);
      expect(owners.shared.subscriptionActive, isFalse);

      await _scrollToAndTap(tester, find.byType(CheckboxListTile));
      await _scrollToAndTap(tester, activate);
      expect(owners.shared.subscriptionActive, isTrue);
    });

    testWidgets(
      'promotion keeps campaign budget separate and reaches Pay handoff',
      (tester) async {
        final owners = _Owners();
        addTearDown(owners.dispose);
        await owners.journey.start();
        await tester.pumpWidget(
          MoolSocialApp(
            session: owners.journey,
            creatorSession: owners.creator,
            retailerSession: owners.retailer,
            sharedSession: owners.shared,
            initialLocation: '/app/social/promote',
          ),
        );
        await tester.pumpAndSettle();
        await _scrollToAndTap(tester, find.text('Sales'));
        await _scrollToAndTap(tester, find.text('Morning market Reel'));
        await _scrollToAndTap(tester, find.text('Continue to budget'));
        await _scrollToAndTap(tester, find.text('Check campaign'));
        await _scrollToAndTap(
          tester,
          find.byKey(const Key('social-v2-campaign-pay')),
        );
        expect(
          find.byKey(const Key('legacy-route-containment-standalone-pay')),
          findsOneWidget,
        );
        expect(
          find.text('Campaign spend is separate from your MoolSocial plan'),
          findsNothing,
        );
        expect(owners.retailer.campaignSpendCap, 1500);
      },
    );
  });
}

final _accountVideo = Screen04YouTubePublicVideo(
  videoId: 'account12345',
  title: 'Account access video',
  channelId: 'UCACCOUNT',
  channelTitle: 'MoolSocial Review',
  description: 'Public review video.',
  thumbnailUrl: Uri.parse('https://i.ytimg.com/vi/account12345/hqdefault.jpg'),
  publishedAt: DateTime.utc(2026, 8, 11),
  duration: 'PT2M',
  captionAvailable: true,
  viewCount: '10',
  likeCount: '1',
  commentCount: '0',
  embeddable: true,
  hasKnownDeviceRegionExclusion: false,
  hashtags: const ['#Review'],
);

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
    otpGateway: ReviewOtpGateway(signedIn: true),
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

class _GuestOwners {
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

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  final verticalScrollable = _verticalScrollable();
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: verticalScrollable.last,
  );
  await tester.pumpAndSettle();
  final viewportHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final rect = tester.getRect(finder);
  final clearBottom = viewportHeight - 132;
  if (rect.bottom > clearBottom) {
    await tester.drag(
      verticalScrollable.last,
      Offset(0, -(rect.bottom - clearBottom + 16)),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _verticalScrollable() {
  return find.descendant(
    of: find.byType(ListView),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
}
