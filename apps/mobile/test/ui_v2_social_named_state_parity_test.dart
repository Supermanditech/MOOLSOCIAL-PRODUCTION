import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_models.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_creator.dart';
import 'package:moolsocial/ui_v2/social/social_v2_plans_promotion.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_connect.dart';

import 'support/review_social_content_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Screen 08 native Create collapses legacy routes into one surface',
    (tester) async {
      const states = <String?, Key>{
        null: Key('screen04-create-post-text'),
        'post': Key('screen04-create-post-text'),
        'reel-source': Key('screen04-create-post-text'),
        'reel-camera': Key('screen04-create-post-text'),
        'reel-edit': Key('screen04-create-post-text'),
        'carousel': Key('screen04-create-carousel-add'),
        'drafts': Key('screen04-create-post-text'),
        'publishing': Key('screen04-create-post-text'),
        'failure': Key('screen04-create-post-text'),
        'success': Key('screen04-create-post-text'),
      };
      for (final entry in states.entries) {
        final owners = _Owners();
        addTearDown(owners.dispose);
        await _pump(tester, owners.consumer(sub: 'create', state: entry.key));
        expect(
          find.byKey(const Key('screen04-create-workbench')),
          findsOneWidget,
          reason: '${entry.key}',
        );
        expect(find.byKey(entry.value), findsOneWidget, reason: '${entry.key}');
        expect(
          find.byKey(const Key('screen04-create-tool-reel')),
          findsNothing,
          reason: '${entry.key}',
        );
        expect(tester.takeException(), isNull, reason: '${entry.key}');
      }
    },
  );

  testWidgets('Shorts and Feed fail closed with truthful recovery states', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, owners.consumer(sub: 'shorts'));
    expect(
      find.byKey(const Key('screen04-youtube-shorts-state-provider-access')),
      findsOneWidget,
    );
    expect(
      find.text('YouTube Shorts are unavailable right now'),
      findsOneWidget,
    );
    expect(find.textContaining('continue in MoolSocial Feed'), findsOneWidget);
    expect(find.text('Open Feed'), findsOneWidget);
    expect(find.text('Fresh basket packed this morning'), findsNothing);
    expect(find.text('Comment'), findsNothing);

    await _pump(tester, owners.consumer(sub: 'shorts', state: 'promoted'));
    expect(
      find.byKey(const Key('screen04-youtube-shorts-state-provider-access')),
      findsOneWidget,
    );
    expect(find.text('Meet Rajasthan makers this week'), findsNothing);
    await _pump(tester, owners.consumer(sub: 'shorts', state: 'unavailable'));
    expect(
      find.byKey(const Key('screen04-youtube-shorts-state-unavailable')),
      findsOneWidget,
    );
    expect(find.text('YouTube Shorts are unavailable'), findsOneWidget);

    await _pump(tester, owners.consumer(sub: 'feed'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
      findsOneWidget,
    );
    expect(find.text('Meera Rathore'), findsNothing);
    expect(find.text('Explore featured products'), findsNothing);
    expect(find.byKey(const Key('screen04-quick-post-feed')), findsNothing);

    await _pump(tester, owners.consumer(sub: 'feed', state: 'loading'));
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-loading')),
      findsOneWidget,
    );

    await _pump(tester, owners.consumer(sub: 'feed', state: 'error'));
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-error')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('screen04-feed-retry')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
      findsOneWidget,
    );

    await _pump(tester, owners.consumer(sub: 'feed', state: 'unavailable'));
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-unavailable')),
      findsOneWidget,
    );
    expect(find.text('Feed isn’t available right now'), findsOneWidget);
  });

  testWidgets(
    'Screen 06 shows finished recovery copy without an eligible video',
    (tester) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await _pump(tester, owners.consumer(sub: 'videos'));
      expect(
        find.byKey(const Key('screen04-youtube-videos-state-provider-access')),
        findsOneWidget,
      );
      expect(
        find.text('YouTube Videos are unavailable right now'),
        findsOneWidget,
      );
      expect(find.textContaining('continue in MoolSocial Feed'), findsOneWidget);
      expect(find.text('Open Feed'), findsOneWidget);
      expect(find.text('5-minute morning mobility'), findsNothing);
      expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
      expect(find.text('Subscribe'), findsNothing);
      expect(find.text('Upload'), findsNothing);

      await _pump(tester, owners.consumer(sub: 'videos', state: 'unavailable'));
      expect(
        find.byKey(const Key('screen04-youtube-videos-state-unavailable')),
        findsOneWidget,
      );
      expect(find.text('YouTube Videos are unavailable'), findsOneWidget);
    },
  );

  testWidgets('Screens 124 to 132 own activation and every Creator state', (
    tester,
  ) async {
    final inactive = CreatorSession();
    addTearDown(inactive.dispose);
    await _pump(
      tester,
      CreatorSocialV2Screen(
        session: inactive,
        owner: CreatorSocialV2Owner.home,
        initialState: 'activate',
      ),
    );
    expect(
      find.text('Add Creator tools to your existing profile'),
      findsOneWidget,
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('social-v2-activate-creator-workspace')),
    );
    expect(inactive.creatorWorkspaceActive, isTrue);
    expect(find.text('Creator workspace active'), findsOneWidget);

    final session = CreatorSession()..creatorWorkspaceActive = true;
    addTearDown(session.dispose);
    const owners = <CreatorSocialV2Owner, String>{
      CreatorSocialV2Owner.home: 'Creator workspace active',
      CreatorSocialV2Owner.publish: 'Choose publishing destinations',
      CreatorSocialV2Owner.library: 'Published',
      CreatorSocialV2Owner.performance: 'View attribution',
      CreatorSocialV2Owner.audience: 'Active audience times',
      CreatorSocialV2Owner.campaigns: 'Explain smarter local grocery buying',
      CreatorSocialV2Owner.earnings: 'Recent earnings',
      CreatorSocialV2Owner.safety: 'Moderation and appeals',
      CreatorSocialV2Owner.memberships: 'Follower-paid Creator Memberships',
    };
    for (final entry in owners.entries) {
      await _pump(
        tester,
        CreatorSocialV2Screen(session: session, owner: entry.key),
      );
      expect(find.text(entry.value), findsWidgets, reason: entry.key.name);
      expect(tester.takeException(), isNull, reason: entry.key.name);
    }

    session.setContentTab(CreatorContentTab.unavailable);
    await _pump(
      tester,
      CreatorSocialV2Screen(
        session: session,
        owner: CreatorSocialV2Owner.library,
        initialState: 'processing',
      ),
    );
    expect(find.text('Old channel introduction'), findsOneWidget);

    await _pump(
      tester,
      CreatorSocialV2Screen(
        session: session,
        owner: CreatorSocialV2Owner.campaigns,
      ),
    );
    await tester.tap(find.text('Explain smarter local grocery buying'));
    await tester.pumpAndSettle();
    expect(
      find.text('Read every requirement before accepting'),
      findsOneWidget,
    );
  });

  testWidgets('Screen 125 owns all six destination-result states', (
    tester,
  ) async {
    const states = <String?, String>{
      null: 'Choose publishing destinations',
      'destinations': 'Where should this content go?',
      'preview': 'Check before publishing',
      'publishing': 'Publishing',
      'partial': 'Your content is still saved',
      'success': 'Your content is ready for its audience',
    };
    for (final entry in states.entries) {
      final session = CreatorSession()..creatorWorkspaceActive = true;
      addTearDown(session.dispose);
      await _pump(
        tester,
        CreatorSocialV2Screen(
          session: session,
          owner: CreatorSocialV2Owner.publish,
          initialState: entry.key,
        ),
      );
      expect(find.text(entry.value), findsWidgets, reason: '${entry.key}');
      expect(tester.takeException(), isNull, reason: '${entry.key}');
    }
  });

  testWidgets(
    'Screens 167 to 169 own plan detail, activation, invoice and end',
    (tester) async {
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
      expect(find.text('Plans & Access'), findsOneWidget);
      await _tapVisible(tester, find.text('Check Creator Pro'));
      expect(find.text('Included capabilities'), findsOneWidget);
      await _tapVisible(
        tester,
        find.byKey(const Key('social-v2-open-plan-activation')),
      );
      expect(find.text('Activate launch access'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await _tapVisible(
        tester,
        find.byKey(const Key('social-v2-activate-plan')),
      );
      expect(owners.shared.subscriptionActive, isTrue);
      Navigator.of(tester.element(find.text('Plan Details'))).pop();
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Manage current access'));
      expect(find.text('Access and billing history'), findsOneWidget);
      await tester.tap(find.text('Access and billing history'));
      await tester.pumpAndSettle();
      expect(find.text('No paid invoice yet'), findsOneWidget);
      await tester.tap(find.text('Return to current access'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End launch access'));
      await tester.pumpAndSettle();
      expect(
        find.text('Keep your content and end professional access'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Screen 170 owns all five steps plus failure and live outcomes', (
    tester,
  ) async {
    const states = <(int?, String?), String>{
      (1, null): 'What outcome matters most?',
      (2, null): 'Choose what people will see',
      (3, null): 'Choose the audience',
      (4, null): 'Set your total spend',
      (5, null): 'Check before payment',
      (null, 'failure'): 'Your campaign is saved',
      (null, 'live'): 'Your campaign is ready',
    };
    for (final entry in states.entries) {
      final session = RetailerSession();
      addTearDown(session.dispose);
      await _pump(
        tester,
        SocialPromotionV2Screen(
          session: session,
          initialStep: entry.key.$1,
          initialState: entry.key.$2,
        ),
      );
      expect(find.text(entry.value), findsWidgets, reason: '${entry.key}');
      expect(tester.takeException(), isNull, reason: '${entry.key}');
    }
  });

  testWidgets('YouTube Connect owns six source, action and recovery states', (
    tester,
  ) async {
    final session = CreatorSession()..creatorWorkspaceActive = true;
    addTearDown(session.dispose);
    await _pump(tester, SocialYouTubeConnectV2Screen(session: session));
    expect(find.text('Share a YouTube video on MoolSocial'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const Key('social-v2-youtube-validate')),
    );
    expect(
      find.text('Paste a public YouTube link or connect your channel first.'),
      findsOneWidget,
    );

    session
      ..setYouTubeUrl('https://youtube.com/watch?v=moolsocial')
      ..setYouTubeChannelConnected(true);
    expect(await tester.runAsync(session.validateYouTubeSource), isTrue);
    expect(session.continueToYouTubeAction(), isTrue);
    await tester.pump();
    expect(find.text('Add post details'), findsOneWidget);

    session
      ..selectYouTubeAction('buy')
      ..confirmYouTubeRights(true)
      ..confirmYouTubeActionTruth(true);
    expect(session.continueToYouTubeReview(), isTrue);
    await tester.pump();
    expect(find.text('Review your YouTube post'), findsOneWidget);

    session.setOnline(false);
    expect(await tester.runAsync(session.publishYouTubeConnection), isFalse);
    await tester.pump();
    expect(find.textContaining('offline'), findsWidgets);
    session.setOnline(true);
    expect(await tester.runAsync(session.publishYouTubeConnection), isTrue);
    await tester.pump();
    expect(find.text('Your YouTube post is live'), findsOneWidget);
  });
}

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession()..creatorWorkspaceActive = true;
  final retailer = RetailerSession();
  final shared = SharedSession(
    socialContentGateway: ReviewSocialContentGateway(),
  );

  SocialUniversalV2 consumer({String? sub, String? state}) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: sub,
    initialState: state,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: child,
    ),
  );
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  final scrollables = find.byType(Scrollable);
  if (finder.evaluate().isEmpty && scrollables.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(finder, 220, scrollable: scrollables.last);
  } else if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
