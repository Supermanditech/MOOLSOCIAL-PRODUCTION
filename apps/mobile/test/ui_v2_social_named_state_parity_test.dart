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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Screen 08 native Create collapses legacy routes into one surface',
    (tester) async {
      const states = <String?, Key>{
        null: Key('screen04-create-post-text'),
        'post': Key('screen04-create-post-text'),
        'reel-source': Key('screen04-create-reel-camera'),
        'reel-camera': Key('screen04-create-reel-camera'),
        'reel-edit': Key('screen04-create-reel-camera'),
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
        expect(tester.takeException(), isNull, reason: '${entry.key}');
      }
    },
  );

  testWidgets('Screens 05 and 07 own filters, recovery and nested actions', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, owners.consumer());
    expect(find.text('Fresh basket packed this morning'), findsOneWidget);

    await tester.tap(find.text('Comment'));
    await tester.pumpAndSettle();
    expect(find.text('Add to the conversation'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await _pump(tester, owners.consumer(state: 'promoted'));
    expect(find.text('Meet Rajasthan makers this week'), findsOneWidget);
    await _pump(tester, owners.consumer(state: 'unavailable'));
    expect(find.text('This Short cannot be shown right now'), findsOneWidget);

    await _pump(tester, owners.consumer(sub: 'feed'));
    if (find.text('Meera Rathore').evaluate().isEmpty) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -420));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Meera Rathore'));
    await tester.pumpAndSettle();
    expect(find.text('Public MoolSocial profile'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More Post actions'));
    await tester.pumpAndSettle();
    expect(find.text('Report this Post'), findsOneWidget);

    await _pump(tester, owners.consumer(sub: 'feed', state: 'promoted'));
    await tester.drag(find.byType(ListView).last, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(find.text('Explore featured products'), findsOneWidget);
    await _pump(tester, owners.consumer(sub: 'feed', state: 'unavailable'));
    expect(find.text('This Post cannot be shown right now'), findsOneWidget);
  });

  testWidgets(
    'Screen 06 owns watch, channel, details, discussion and connect',
    (tester) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await _pump(tester, owners.consumer(sub: 'videos'));
      await _tapVisible(tester, find.text('5-minute morning mobility'));
      expect(find.byKey(const Key('social-v2-youtube-play')), findsOneWidget);
      expect(find.byKey(const Key('screen04-video-back')), findsNothing);

      await tester.tap(find.byKey(const Key('screen04-video-details-trigger')));
      await tester.pumpAndSettle();
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('38K likes'), findsOneWidget);

      await tester.tap(find.text('View channel'));
      await tester.pumpAndSettle();
      expect(find.text('Move With Asha'), findsWidgets);
      expect(find.text('86M'), findsOneWidget);
      expect(find.text('Views'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Description'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('social-v2-youtube-play')), findsOneWidget);

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Description'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discuss'));
      await tester.pumpAndSettle();
      expect(find.text('MoolSocial discussion'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Connect YouTube'));
      expect(find.text('Connect YouTube viewing actions'), findsOneWidget);

      await _pump(tester, owners.consumer(sub: 'videos', state: 'unavailable'));
      expect(find.text('This Video cannot be shown right now'), findsOneWidget);
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
    expect(
      find.text('Keep the video on YouTube. Add one useful Mool action.'),
      findsOneWidget,
    );

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
    expect(find.text('What should the viewer accomplish?'), findsOneWidget);

    session
      ..selectYouTubeAction('buy')
      ..confirmYouTubeRights(true)
      ..confirmYouTubeActionTruth(true);
    expect(session.continueToYouTubeReview(), isTrue);
    await tester.pump();
    expect(
      find.text('Video and MoolSocial action stay separate.'),
      findsOneWidget,
    );

    session.setOnline(false);
    expect(await tester.runAsync(session.publishYouTubeConnection), isFalse);
    await tester.pump();
    expect(find.textContaining('offline'), findsWidgets);
    session.setOnline(true);
    expect(await tester.runAsync(session.publishYouTubeConnection), isTrue);
    await tester.pump();
    expect(
      find.text('Your YouTube video now has a MoolSocial action.'),
      findsOneWidget,
    );
  });
}

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession()..creatorWorkspaceActive = true;
  final retailer = RetailerSession();
  final shared = SharedSession();

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
  await tester.pumpAndSettle();
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
