import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Social UI V2 consumer journeys', () {
    testWidgets('Shorts engagement and filters change visible state', (
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

      expect(find.text('Fresh basket packed this morning'), findsOneWidget);
      await tester.tap(find.text('Promoted'));
      await tester.pumpAndSettle();
      expect(find.text('Meet Rajasthan makers this week'), findsOneWidget);

      await tester.tap(find.text('Like'));
      await tester.pump();
      expect(find.text('Liked'), findsOneWidget);
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

      await tester.tap(find.byKey(const Key('screen04-rail-videos')));
      await tester.pumpAndSettle();
      expect(find.text('Videos'), findsWidgets);
      expect(find.text('India'), findsOneWidget);
      expect(find.text('Live'), findsNothing);
      expect(find.text('Learning'), findsNothing);
      expect(find.text('Local'), findsNothing);
      expect(find.text('Business'), findsNothing);
      expect(find.text('5-minute morning mobility'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-rail-feed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nearby'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-quick-post-feed')), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(find.text('Fresh arrivals near Khema-Ka-Kuwa'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-rail-create')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-create-workbench')),
        findsOneWidget,
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
    });

    testWidgets(
      'approved capability rail remains actionable from video detail',
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

        await _scrollToAndTap(tester, find.text('5-minute morning mobility'));
        expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
        expect(find.byKey(const Key('screen04-mool')), findsOneWidget);
        expect(find.byKey(const Key('screen04-rail-videos')), findsOneWidget);
        expect(find.byKey(const Key('screen04-chat')), findsOneWidget);
        expect(find.byKey(const Key('social-v2-tab-feed')), findsNothing);

        await tester.tap(find.byKey(const Key('screen04-rail-feed')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('screen04-quick-post-feed')),
          findsOneWidget,
        );
      },
    );

    testWidgets('account exposes Creator workspace and Plans', (tester) async {
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
      await tester.tap(find.byKey(const Key('screen04-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Creator workspace'), findsOneWidget);
      expect(find.text('Plans & access'), findsOneWidget);
    });

    testWidgets('Feed lays out with the production app theme', (tester) async {
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
      expect(find.byKey(const Key('screen04-quick-post-feed')), findsOneWidget);
      expect(
        find.byKey(const Key('screen04-quick-post-input-feed')),
        findsOneWidget,
      );
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
            initialLocation: '/app/social?sub=create',
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('screen04-profile')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Creator workspace'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
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
        expect(find.text('5-minute morning mobility'), findsOneWidget);
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
      expect(find.byKey(const Key('screen04-quick-post-feed')), findsOneWidget);
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
        expect(find.byKey(const Key('pay-home-screen')), findsOneWidget);
        expect(
          find.text('Campaign spend is separate from your MoolSocial plan'),
          findsNothing,
        );
        expect(owners.retailer.campaignSpendCap, 1500);
      },
    );
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
