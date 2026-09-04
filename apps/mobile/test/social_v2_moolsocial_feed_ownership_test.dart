import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_services.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';

import 'support/review_social_content_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Feed source reuses real publications without representative fallback',
    () {
      final source = File(
        'lib/ui_v2/social/social_v2_consumer.dart',
      ).readAsStringSync();
      final buildFeed = source.substring(
        source.indexOf('Widget _buildFeed()'),
        source.indexOf('Widget _buildCreate()'),
      );

      expect(buildFeed, contains('_MoolSocialFeedStatusView('));
      expect(buildFeed, contains('onCreate: _openCreationGateway'));
      expect(buildFeed, contains('socialPublishedItems'));
      expect(buildFeed, contains('SocialPublishedContentCardV2('));
      expect(
        buildFeed,
        contains('item.type != SocialPublishedContentType.reel'),
      );
      expect(buildFeed, isNot(contains('publishSocialContent')));
      expect(buildFeed, isNot(contains('source=feed')));
      expect(source, isNot(contains('class _FeedData')));
      expect(source, isNot(contains('class _FeedPostCard')));
      expect(source, isNot(contains('class _QuickPublicComposer')));
      expect(source, isNot(contains('Meera Rathore')));
      expect(source, isNot(contains('Rajasthan Makers')));
      expect(source, isNot(contains('Mahadev Fresh Mart')));
      expect(source, contains('screen04-moolsocial-feed-state-'));
      expect(source, contains('screen04-feed-create-post'));
    },
  );

  testWidgets(
    'Feed projects a real stored MoolSocial publication without filler',
    (tester) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await owners.shared.publishSocialContent(
        type: SocialPublishedContentType.post,
        authorName: 'MoolSocial author',
        authorHandle: '@moolsocialauthor',
        body: 'This real stored MoolSocial post belongs in Feed.',
      );

      await _pumpFeed(tester, owners, state: null);

      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-brand')),
        findsOneWidget,
      );
      final post = find.text(
        'This real stored MoolSocial post belongs in Feed.',
      );
      final createPost = find.byKey(const Key('screen04-feed-create-post'));
      expect(post, findsOneWidget);
      expect(find.byKey(const Key('screen04-quick-post-feed')), findsNothing);
      expect(createPost, findsNothing);
      expect(find.byKey(const Key('screen04-rail-create')), findsOneWidget);
      expect(find.text('Meera Rathore'), findsNothing);
      expect(find.text('Explore featured products'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Feed retains cached posts and retry after a refresh failure', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await owners.shared.publishSocialContent(
      type: SocialPublishedContentType.post,
      authorName: 'MoolSocial author',
      authorHandle: '@moolsocialauthor',
      body: 'Keep this cached post visible during recovery.',
    );
    expect(await owners.shared.loadSocialFeed(refresh: true), isTrue);
    owners.shared.setOnline(false);
    expect(await owners.shared.loadSocialFeed(refresh: true), isFalse);

    await _pumpFeed(tester, owners, state: null);

    expect(
      find.text('Keep this cached post visible during recovery.'),
      findsOneWidget,
    );
    expect(find.text('Feed refresh did not complete'), findsOneWidget);
    expect(find.byKey(const Key('screen04-feed-cached-retry')), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed exposes distinct loading, error and unavailable states', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);

    for (final state in const ['loading', 'error', 'unavailable']) {
      await _pumpFeed(tester, owners, state: state);
      expect(
        find.byKey(Key('screen04-moolsocial-feed-state-$state')),
        findsOneWidget,
      );
      expect(find.text('Meera Rathore'), findsNothing);
      expect(find.text('Explore featured products'), findsNothing);
      expect(tester.takeException(), isNull, reason: state);
    }

    final retry = find.byKey(const Key('screen04-feed-retry'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
      findsOneWidget,
    );
  });
}

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession(
    gateway: _ImmediateSharedGateway(),
    socialContentGateway: ReviewSocialContentGateway(),
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

class _ImmediateSharedGateway extends ReviewSharedGateway {
  @override
  Future<void> execute(String actionId) async {}
}

Future<void> _pumpFeed(
  WidgetTester tester,
  _Owners owners, {
  required String? state,
}) async {
  const size = Size(320, 568);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(1.4),
        ),
        child: SocialUniversalV2(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialSubAction: 'feed',
          initialState: state,
        ),
      ),
    ),
  );
  await tester.pump();
}
