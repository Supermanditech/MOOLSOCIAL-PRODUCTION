import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('C29O keeps every Social destination direct at real 140% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);
    await owners.journey.start();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: owners.consumer('videos'),
      ),
    );
    await tester.pumpAndSettle();

    final socialContext = tester.element(
      find.byKey(const Key('screen04-universal-v2')),
    );
    expect(MediaQuery.textScalerOf(socialContext).scale(10), closeTo(14, 0.01));
    expect(tester.takeException(), isNull, reason: 'initial videos');

    for (final key in const [
      Key('mool-compact-launcher'),
      Key('social-global-chat'),
    ]) {
      final edge = find.byKey(key);
      expect(edge, findsOneWidget, reason: '$key');
      expect(tester.getSemantics(edge).rect.height, greaterThanOrEqualTo(44));
    }

    const journeys = <String, Key>{
      'shorts': Key('screen04-youtube-shorts-state-provider-access'),
      'videos': Key('screen04-youtube-videos-state-provider-access'),
      'feed': Key('screen04-moolsocial-feed-state-empty'),
      'create': Key('screen04-create-home'),
    };
    for (final journey in journeys.entries) {
      final action = find.byKey(Key('screen04-rail-${journey.key}'));
      expect(action, findsOneWidget, reason: journey.key);
      expect(
        tester.getSemantics(action).rect.height,
        greaterThanOrEqualTo(44),
        reason: journey.key,
      );
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byKey(journey.value), findsOneWidget, reason: journey.key);
      expect(tester.takeException(), isNull, reason: journey.key);
    }
  });

  test('C29O source contains no known Social false-success watch path', () {
    const prohibited = <String>[
      'Comment posted on MoolSocial',
      'screen04-video-save',
      'screen04-video-discuss',
      'class _VideoWatchScreen',
      'Finding videos for you',
      'Search YouTube videos',
      'TextScaler.linear(effectiveTextScale)',
    ];
    final source = _socialConsumerSource();
    for (final value in prohibited) {
      expect(source, isNot(contains(value)), reason: value);
    }
    expect(source, contains("hintText: 'Search YouTube'"));
    expect(source, contains('class _YouTubeSearchSurface'));
    expect(source, isNot(contains('Filter loaded videos')));
    expect(source, contains('_shareYouTubeVideo(video)'));
    expect(source, contains("title: 'Share YouTube video'"));
    expect(source, isNot(contains("'YouTube link copied'")));
  });
}

String _socialConsumerSource() =>
    File('lib/ui_v2/social/social_v2_consumer.dart').readAsStringSync();

class _Owners {
  final journey = JourneySession(otpGateway: ReviewOtpGateway(signedIn: true));
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer(String subAction) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: subAction,
    youtubePublicAccessOverride: false,
    youtubeCreatorAccessOverride: false,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}
