import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_public_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FIX4 parses only complete protected Social action intents', () {
    expect(
      SocialProtectedActionIntent.tryParse('like', null)?.action,
      SocialProtectedAction.like,
    );
    expect(SocialProtectedActionIntent.tryParse('vote', '2')?.choiceIndex, 2);
    expect(SocialProtectedActionIntent.tryParse('vote', null), isNull);
    expect(SocialProtectedActionIntent.tryParse('vote', '-1'), isNull);
    expect(SocialProtectedActionIntent.tryParse('like', '2'), isNull);
    expect(SocialProtectedActionIntent.tryParse('delete', null), isNull);
  });

  testWidgets('FIX4 carries the exact signed-out Poll choice through sign-in', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final gateway = _Fix4SocialGateway(_poll());
    final journey = JourneySession(
      store: MemoryJourneyStore(snapshot: _readySnapshot),
      allowGuestReady: true,
    );
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final shared = SharedSession(socialContentGateway: gateway);
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);
    await journey.start();

    await tester.pumpWidget(
      MaterialApp(
        home: SocialUniversalV2(
          session: journey,
          creatorSession: creator,
          retailerSession: retailer,
          sharedSession: shared,
          initialSubAction: 'feed',
          youtubePublicAccessOverride: false,
          youtubeCreatorAccessOverride: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final choice = find.byKey(const Key('social-public-fix4-poll-choice-2'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump();

    expect(journey.stage, JourneyStage.signIn);
    expect(
      journey.returnTo,
      '/app/social?sub=feed&item=fix4-poll&action=vote&choice=2',
    );
    expect(journey.readyRoute(), '/app/social?sub=feed&item=fix4-poll');
    expect(gateway.interactions, isEmpty);
  });

  testWidgets(
    'FIX4 consumes Like return once and removes resumable route intent',
    (tester) async {
      final gateway = _Fix4SocialGateway(_post());
      final harness = await _pumpAuthenticatedReturn(
        tester,
        gateway: gateway,
        location: '/app/social?sub=feed&item=fix4-post&action=like',
      );

      expect(gateway.interactions, const ['like']);
      expect(harness.shared.socialPublishedItems.single.liked, isTrue);
      expect(
        harness.router.routeInformationProvider.value.uri.toString(),
        '/app/social?sub=feed&item=fix4-post',
      );

      await tester.pumpAndSettle();
      expect(gateway.interactions, const ['like']);
    },
  );

  testWidgets('FIX4 never toggles an already completed desired state off', (
    tester,
  ) async {
    final gateway = _Fix4SocialGateway(_post(liked: true));
    final harness = await _pumpAuthenticatedReturn(
      tester,
      gateway: gateway,
      location: '/app/social?sub=feed&item=fix4-post&action=like',
    );

    expect(gateway.interactions, isEmpty);
    expect(harness.shared.socialPublishedItems.single.liked, isTrue);
    expect(
      harness.router.routeInformationProvider.value.uri.queryParameters,
      const {'sub': 'feed', 'item': 'fix4-post'},
    );
  });

  testWidgets('FIX4 preserves and applies the selected Poll choice once', (
    tester,
  ) async {
    final gateway = _Fix4SocialGateway(_poll());
    final harness = await _pumpAuthenticatedReturn(
      tester,
      gateway: gateway,
      location: '/app/social?sub=feed&item=fix4-poll&action=vote&choice=2',
    );

    expect(gateway.interactions, const ['vote:2']);
    expect(harness.shared.socialPublishedItems.single.selectedChoiceIndex, 2);
    expect(
      harness.router.routeInformationProvider.value.uri.queryParameters,
      const {'sub': 'feed', 'item': 'fix4-poll'},
    );
  });

  testWidgets('FIX4 reopens Replies with the existing signed-out draft', (
    tester,
  ) async {
    final gateway = _Fix4SocialGateway(_post());
    final harness = await _pumpAuthenticatedReturn(
      tester,
      gateway: gateway,
      location: '/app/social?sub=feed&item=fix4-post&action=reply',
      beforePump: (shared) {
        shared.saveSocialReplyDraft('fix4-post', 'Keep this exact reply');
      },
    );

    expect(gateway.interactions, isEmpty);
    expect(find.byKey(const Key('social-comments-panel-fix4-post')), findsOne);
    final field = tester.widget<TextField>(
      find.byKey(const Key('social-reply-field-fix4-post')),
    );
    expect(field.controller?.text, 'Keep this exact reply');
    expect(
      harness.router.routeInformationProvider.value.uri.queryParameters,
      const {'sub': 'feed', 'item': 'fix4-post'},
    );
  });

  testWidgets('FIX4 rejects an out-of-range Poll choice without dispatch', (
    tester,
  ) async {
    final gateway = _Fix4SocialGateway(_poll());
    final harness = await _pumpAuthenticatedReturn(
      tester,
      gateway: gateway,
      location: '/app/social?sub=feed&item=fix4-poll&action=vote&choice=99',
    );

    expect(gateway.interactions, isEmpty);
    expect(
      harness.shared.socialPublishedItems.single.selectedChoiceIndex,
      isNull,
    );
    expect(
      find.text('That Feed action could not be restored. Nothing changed.'),
      findsOne,
    );
    expect(
      harness.router.routeInformationProvider.value.uri.queryParameters,
      const {'sub': 'feed', 'item': 'fix4-poll'},
    );
  });

  testWidgets('FIX4 rejects an unknown action without gateway dispatch', (
    tester,
  ) async {
    final gateway = _Fix4SocialGateway(_post());
    final harness = await _pumpAuthenticatedReturn(
      tester,
      gateway: gateway,
      location: '/app/social?sub=feed&item=fix4-post&action=delete',
    );

    expect(gateway.interactions, isEmpty);
    expect(
      harness.router.routeInformationProvider.value.uri.queryParameters,
      const {'sub': 'feed', 'item': 'fix4-post'},
    );
  });
}

Future<_Fix4Harness> _pumpAuthenticatedReturn(
  WidgetTester tester, {
  required _Fix4SocialGateway gateway,
  required String location,
  void Function(SharedSession shared)? beforePump,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  final journey = JourneySession(
    store: MemoryJourneyStore(snapshot: _readySnapshot),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession(socialContentGateway: gateway);
  addTearDown(journey.dispose);
  addTearDown(creator.dispose);
  addTearDown(retailer.dispose);
  addTearDown(shared.dispose);
  await journey.start();
  expect(journey.isAuthenticated, isTrue);
  beforePump?.call(shared);

  late final GoRouter router;
  router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/app/social',
        builder: (context, state) => SocialUniversalV2(
          session: journey,
          creatorSession: creator,
          retailerSession: retailer,
          sharedSession: shared,
          initialSubAction: state.uri.queryParameters['sub'],
          initialItem: state.uri.queryParameters['item'],
          initialAction: state.uri.queryParameters['action'],
          initialChoice: state.uri.queryParameters['choice'],
          youtubePublicAccessOverride: false,
          youtubeCreatorAccessOverride: false,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return _Fix4Harness(router: router, shared: shared);
}

const _readySnapshot = JourneySnapshot(
  languageCode: 'en',
  areaMode: 'current',
  areaLabel: 'Jodhpur',
  setupComplete: true,
  setupExperienceVersion: approvedSetupExperienceVersion,
);

class _Fix4Harness {
  const _Fix4Harness({required this.router, required this.shared});

  final GoRouter router;
  final SharedSession shared;
}

class _Fix4SocialGateway implements SocialContentGateway, SocialCommentGateway {
  _Fix4SocialGateway(this.item);

  SocialPublishedItem item;
  final List<String> interactions = [];

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      SocialFeedPage(items: [item]);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) async {
    interactions.add(
      choiceIndex == null ? interaction : '$interaction:$choiceIndex',
    );
    item = switch (interaction) {
      'like' => item.copyWith(liked: !item.liked),
      'save' => item.copyWith(saved: !item.saved),
      'repost' => item.copyWith(reposted: !item.reposted),
      'vote' => item.copyWith(selectedChoiceIndex: choiceIndex),
      _ => item,
    };
    return item;
  }

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      throw UnimplementedError();

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 30,
  }) async => const SocialCommentPage(items: []);

  @override
  Future<SocialReplyResult> reply(SocialReplyDraft draft) =>
      throw UnimplementedError();
}

SocialPublishedItem _post({bool liked = false}) => SocialPublishedItem(
  id: 'fix4-post',
  type: SocialPublishedContentType.post,
  authorName: 'Veto News',
  authorHandle: '@VetoNewslive',
  body: 'Protected action return continuity.',
  audience: 'Public',
  publishedAt: DateTime.utc(2026, 8, 15),
  liked: liked,
);

SocialPublishedItem _poll() => SocialPublishedItem(
  id: 'fix4-poll',
  type: SocialPublishedContentType.quickPoll,
  authorName: 'Veto News',
  authorHandle: '@VetoNewslive',
  body: 'Which update should come first?',
  audience: 'Public',
  publishedAt: DateTime.utc(2026, 8, 15),
  choices: const [
    SocialPublishedChoice(label: 'Local'),
    SocialPublishedChoice(label: 'India'),
    SocialPublishedChoice(label: 'World'),
    SocialPublishedChoice(label: 'Business'),
  ],
  closesAt: DateTime.utc(2100, 1, 1),
);
