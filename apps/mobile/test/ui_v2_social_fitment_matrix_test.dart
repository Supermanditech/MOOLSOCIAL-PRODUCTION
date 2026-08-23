import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  const sizes = [
    Size(320, 568),
    Size(360, 640),
    Size(360, 720),
    Size(375, 667),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
  ];

  for (final size in sizes) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'all Social first-layer screens fit ${size.width.toInt()}x${size.height.toInt()} at ${(scale * 100).round()}%',
        (tester) async {
          for (final state in const <(String?, String?)>[
            (null, null),
            ('videos', null),
            ('videos', 'video-watch'),
            ('feed', null),
            ('create', null),
          ]) {
            final owners = _Owners();
            await _pumpAt(
              tester,
              size,
              scale,
              SocialUniversalV2(
                session: owners.journey,
                creatorSession: owners.creator,
                retailerSession: owners.retailer,
                sharedSession: owners.shared,
                initialSubAction: state.$1,
                initialState: state.$2,
                initialItem: state.$2 == 'video-watch'
                    ? '5-minute-morning-mobility'
                    : null,
              ),
            );
            expect(tester.takeException(), isNull, reason: '$state');
            owners.dispose();
          }
        },
      );
    }
  }

  testWidgets('all Creator owners fit compact 320x568 at 140%', (tester) async {
    for (final owner in CreatorSocialV2Owner.values) {
      final session = CreatorSession()..creatorWorkspaceActive = true;
      await _pumpAt(
        tester,
        const Size(320, 568),
        1.4,
        CreatorSocialV2Screen(session: session, owner: owner),
      );
      expect(tester.takeException(), isNull, reason: owner.name);
      session.dispose();
    }
  });

  testWidgets('all Social named states fit compact 320x568 at 140%', (
    tester,
  ) async {
    const consumerStates = <(String?, String?)>[
      (null, null),
      (null, 'promoted'),
      (null, 'unavailable'),
      ('videos', null),
      ('videos', 'video-watch'),
      ('videos', 'unavailable'),
      ('feed', null),
      ('feed', 'loading'),
      ('feed', 'error'),
      ('feed', 'unavailable'),
      ('create', null),
      ('create', 'post'),
      ('create', 'reel-source'),
      ('create', 'reel-camera'),
      ('create', 'reel-edit'),
      ('create', 'carousel'),
      ('create', 'drafts'),
      ('create', 'publishing'),
      ('create', 'failure'),
      ('create', 'success'),
    ];
    for (final state in consumerStates) {
      final owners = _Owners();
      await _pumpAt(
        tester,
        const Size(320, 568),
        1.4,
        SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: state.$1,
          initialState: state.$2,
        ),
      );
      expect(tester.takeException(), isNull, reason: '$state');
      owners.dispose();
    }

    final inactive = CreatorSession();
    await _pumpAt(
      tester,
      const Size(320, 568),
      1.4,
      CreatorSocialV2Screen(
        session: inactive,
        owner: CreatorSocialV2Owner.home,
        initialState: 'activate',
      ),
    );
    expect(tester.takeException(), isNull, reason: 'creator activation');
    inactive.dispose();

    for (final state in const <String?>[
      null,
      'destinations',
      'preview',
      'publishing',
      'partial',
      'success',
    ]) {
      final session = CreatorSession()..creatorWorkspaceActive = true;
      await _pumpAt(
        tester,
        const Size(320, 568),
        1.4,
        CreatorSocialV2Screen(
          session: session,
          owner: CreatorSocialV2Owner.publish,
          initialState: state,
        ),
      );
      expect(tester.takeException(), isNull, reason: 'publish $state');
      session.dispose();
    }

    for (final state in const <(int?, String?)>[
      (1, null),
      (2, null),
      (3, null),
      (4, null),
      (5, null),
      (null, 'failure'),
      (null, 'live'),
    ]) {
      final session = RetailerSession();
      await _pumpAt(
        tester,
        const Size(320, 568),
        1.4,
        SocialPromotionV2Screen(
          session: session,
          initialStep: state.$1,
          initialState: state.$2,
        ),
      );
      expect(tester.takeException(), isNull, reason: 'promotion $state');
      session.dispose();
    }
  });

  testWidgets('plans and promotion fit compact 320x568 at 140%', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pumpAt(
      tester,
      const Size(320, 568),
      1.4,
      SocialPlansV2Screen(
        sharedSession: owners.shared,
        retailerSession: owners.retailer,
        creatorSession: owners.creator,
      ),
    );
    expect(tester.takeException(), isNull);
    await _pumpAt(
      tester,
      const Size(320, 568),
      1.4,
      SocialPromotionV2Screen(session: owners.retailer),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('every YouTube Connect step fits compact 320x568 at 140%', (
    tester,
  ) async {
    final session = CreatorSession()..creatorWorkspaceActive = true;
    addTearDown(session.dispose);

    Future<void> verify(String step) async {
      await _pumpAt(
        tester,
        const Size(320, 568),
        1.4,
        SocialYouTubeConnectV2Screen(session: session),
      );
      expect(tester.takeException(), isNull, reason: step);
    }

    await verify('source');
    session.setYouTubeUrl('https://youtube.com/watch?v=moolsocial');
    expect(await tester.runAsync(session.validateYouTubeSource), isTrue);
    expect(session.continueToYouTubeAction(), isTrue);
    await verify('action');
    session
      ..selectYouTubeAction('buy')
      ..confirmYouTubeRights(true)
      ..confirmYouTubeActionTruth(true);
    expect(session.continueToYouTubeReview(), isTrue);
    await verify('check');
    expect(await tester.runAsync(session.publishYouTubeConnection), isTrue);
    await verify('complete');
  });
}

class _Owners {
  final journey = JourneySession();
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

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  double textScale,
  Widget child,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pump();
}
