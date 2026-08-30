import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_public_content.dart';

import 'support/review_social_content_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'C30T guest remains ready for public reads and can begin real sign-in',
    () async {
      final social = ReviewSocialAuthGateway(
        defaultResult: const SocialAuthResult.authenticated('user-1'),
      );
      final session = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        socialAuthGateway: social,
        allowGuestReady: true,
      );
      addTearDown(session.dispose);

      await session.start();
      expect(session.stage, JourneyStage.ready);
      expect(session.isAuthenticated, isFalse);

      session.beginSignIn(returnLocation: '/app/social?sub=create');
      expect(session.stage, JourneyStage.signIn);
      expect(session.returnTo, '/app/social?sub=create');

      expect(await session.signInWithSocial(SocialAuthProvider.google), isTrue);
      expect(session.stage, JourneyStage.ready);
      expect(session.isAuthenticated, isTrue);
    },
  );

  testWidgets(
    'UI review Feed uses the real contract and keeps messaging on profiles',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        allowGuestReady: true,
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final shared = SharedSession(
        socialContentGateway: UiReviewSocialContentGateway(
          now: () => DateTime(2026, 8, 31, 12),
        ),
      );
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
            enableCreateReviewPreview: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(shared.socialPublishedItems, hasLength(3));
      expect(
        find.byKey(const Key('screen04-feed-review-preview-label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-feed-mode-forYou')),
        findsOneWidget,
      );
      expect(find.text('Asha Verma'), findsOneWidget);
      expect(find.text('Rohan Mehta'), findsOneWidget);
      expect(
        find.byKey(const Key('social-message-author-UI-REVIEW-FEED-001')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('social-author-relationship-UI-REVIEW-FEED-001')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-feed-network-discover')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen04-feed-saved-posts')),
        findsOneWidget,
      );
      expect(find.text('Like'), findsWidgets);
      expect(find.text('Comment'), findsWidgets);

      await tester.tap(find.byKey(const Key('screen04-feed-mode-following')));
      await tester.pumpAndSettle();
      expect(find.text('Your Following feed is ready to grow'), findsOneWidget);
      expect(find.text('Asha Verma'), findsNothing);

      await tester.tap(find.byKey(const Key('screen04-feed-mode-forYou')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('social-open-post-UI-REVIEW-FEED-001')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('social-post-detail-UI-REVIEW-FEED-001')),
        findsOneWidget,
      );
      expect(find.text('Conversation'), findsOneWidget);
      expect(
        find.byKey(const Key('social-comments-panel-UI-REVIEW-FEED-001')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('social-author-profile-UI-REVIEW-FEED-001')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in to message'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('UI review Feed adapter rejects every write', () async {
    final gateway = UiReviewSocialContentGateway(
      now: () => DateTime(2026, 8, 31, 12),
    );
    final page = await gateway.feed();
    expect(page.items, hasLength(3));
    expect(
      () => gateway.interact(postId: page.items.first.id, interaction: 'like'),
      throwsA(
        isA<SocialContentGatewayException>().having(
          (error) => error.code,
          'code',
          'ui_review_read_only',
        ),
      ),
    );
  });

  testWidgets('C30T Feed Create uses the authenticated creation gateway', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(snapshot: readySnapshot),
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
    await tester.pump();

    await tester.tap(find.text('Create a post'));
    await tester.pump();
    expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);
    expect(find.byKey(const Key('screen04-create-hub-header')), findsOneWidget);
    for (final key in const [
      Key('screen04-create-photo-entry'),
      Key('screen04-create-carousel-entry'),
      Key('screen04-create-poll-entry'),
      Key('screen04-create-quiz-entry'),
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(journey.stage, JourneyStage.ready);
    expect(journey.isAuthenticated, isTrue);
  });

  testWidgets('C30T guest Create rail starts sign-in with exact return', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(snapshot: readySnapshot),
      allowGuestReady: true,
    );
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final shared = SharedSession(
      socialContentGateway: ReviewSocialContentGateway(),
    );
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

    await tester.tap(find.byKey(const Key('screen04-rail-create')));
    await tester.pump();

    expect(journey.stage, JourneyStage.signIn);
    expect(journey.returnTo, '/app/social?sub=create');
    expect(
      journey.authenticationPurpose,
      JourneyAuthenticationPurpose.socialCreate,
    );
    expect(find.byKey(const Key('social-v2-create-workbench')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'C30T guest Like enters sign-in and preserves exact Feed return',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        allowGuestReady: true,
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final socialGateway = ReviewSocialContentGateway();
      final shared = SharedSession(socialContentGateway: socialGateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      final item = await socialGateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'guest-like-return',
          type: SocialPublishedContentType.post,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          body: 'A public post for a guest reader.',
          audience: 'Public',
          mediaPaths: <String>[],
          mediaAreAssets: false,
          choices: <SocialPublishedChoice>[],
        ),
      );
      await journey.start();
      await shared.loadSocialFeed(refresh: true);

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
      await tester.tap(find.byKey(Key('social-public-like-${item.id}')));
      await tester.pump();

      expect(journey.stage, JourneyStage.signIn);
      expect(
        journey.returnTo,
        '/app/social?sub=feed&item=${item.id}&action=like',
      );
      expect(journey.readyRoute(), '/app/social?sub=feed&item=${item.id}');
      expect(shared.socialPublishedItems.single.liked, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'C30T guest reads replies publicly and retains draft through exact sign-in return',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        allowGuestReady: true,
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final socialGateway = ReviewSocialContentGateway();
      final shared = SharedSession(socialContentGateway: socialGateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      final item = await socialGateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'guest-reply-return',
          type: SocialPublishedContentType.post,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          body: 'A public post with public replies.',
          audience: 'Public',
          mediaPaths: <String>[],
          mediaAreAssets: false,
          choices: <SocialPublishedChoice>[],
        ),
      );
      await journey.start();
      await shared.loadSocialFeed(refresh: true);

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

      await tester.tap(find.byKey(Key('social-public-reply-${item.id}')));
      await tester.pumpAndSettle();
      expect(journey.stage, JourneyStage.ready);
      expect(
        find.byKey(Key('social-comments-panel-${item.id}')),
        findsOneWidget,
      );
      expect(find.text('No replies yet'), findsOneWidget);
      final field = find.byKey(Key('social-reply-field-${item.id}'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Keep this reply through sign-in');
      final submit = find.byKey(Key('social-reply-submit-${item.id}'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(submit).dy,
        lessThanOrEqualTo(544),
        reason: 'The reply action must stay above a 300dp keyboard.',
      );
      await tester.tap(submit);
      await tester.pump();

      expect(journey.stage, JourneyStage.signIn);
      expect(
        journey.returnTo,
        '/app/social?sub=feed&item=${item.id}&action=reply',
      );
      expect(
        shared.socialReplyDraft(item.id),
        'Keep this reply through sign-in',
      );
      expect(shared.socialComments(item.id), isEmpty);

      journey.cancelSignIn();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('social-public-reply-${item.id}')));
      await tester.pumpAndSettle();
      final reopened = tester.widget<TextField>(
        find.byKey(Key('social-reply-field-${item.id}')),
      );
      expect(reopened.controller?.text, 'Keep this reply through sign-in');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'C30T authenticated reply renders only after durable acknowledgement',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final socialGateway = ReviewSocialContentGateway();
      final shared = SharedSession(socialContentGateway: socialGateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      final item = await socialGateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'authenticated-reply',
          type: SocialPublishedContentType.post,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          body: 'Reply to this public post.',
          audience: 'Public',
          mediaPaths: <String>[],
          mediaAreAssets: false,
          choices: <SocialPublishedChoice>[],
        ),
      );
      await journey.start();
      await shared.loadSocialFeed(refresh: true);
      expect(journey.isAuthenticated, isTrue);

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
      await tester.tap(find.byKey(Key('social-public-reply-${item.id}')));
      await tester.pumpAndSettle();
      final field = find.byKey(Key('social-reply-field-${item.id}'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'A durable widget reply');
      final submit = find.byKey(Key('social-reply-submit-${item.id}'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('social-comment-TEST-COMMENT-0001')),
        findsOneWidget,
      );
      expect(find.text('A durable widget reply'), findsOneWidget);
      expect(shared.socialPublishedItems.single.replyCount, 1);
      expect(shared.socialReplyDraft(item.id), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'C30T guest opens public author and Follow preserves exact author return',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        allowGuestReady: true,
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final socialGateway = ReviewSocialContentGateway();
      final shared = SharedSession(socialContentGateway: socialGateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      final item = await socialGateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'guest-author-return',
          type: SocialPublishedContentType.post,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          body: 'A public author post.',
          audience: 'Public',
          mediaPaths: <String>[],
          mediaAreAssets: false,
          choices: <SocialPublishedChoice>[],
        ),
      );
      await journey.start();
      await shared.loadSocialFeed(refresh: true);

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

      await tester.tap(
        find.byKey(Key('social-author-relationship-${item.id}')),
      );
      await tester.pump();
      expect(journey.stage, JourneyStage.signIn);
      expect(
        journey.returnTo,
        '/app/social?sub=feed&item=${item.id}&action=follow',
      );
      expect(shared.socialAuthorProfile(item.authorId!), isNull);
      journey.cancelSignIn();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('social-author-profile-${item.id}')));
      await tester.pumpAndSettle();
      expect(journey.stage, JourneyStage.ready);
      expect(
        find.byKey(Key('social-author-panel-${item.authorId}')),
        findsOneWidget,
      );
      expect(find.text('Riya Sharma'), findsWidgets);
      expect(find.text('@riyasharma'), findsWidgets);
      expect(find.text('A public author post.'), findsWidgets);
      expect(find.textContaining('followers'), findsOneWidget);
      expect(
        find.byKey(Key('social-author-paid-follow-${item.authorId}')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Paid following is not offered'),
        findsOneWidget,
      );
      expect(find.textContaining('email'), findsNothing);
      final follow = find.byKey(Key('social-author-follow-${item.authorId}'));
      await tester.ensureVisible(follow);
      await tester.tap(follow);
      await tester.pump();

      expect(journey.stage, JourneyStage.signIn);
      expect(
        journey.returnTo,
        '/app/social?sub=feed&state=author&item=${item.id}',
      );
      expect(shared.socialAuthorProfile(item.authorId!)?.followed, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'C30T authenticated Follow and Unfollow wait for server acknowledgement',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final socialGateway = ReviewSocialContentGateway();
      final shared = SharedSession(socialContentGateway: socialGateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      final item = await socialGateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'authenticated-author-follow',
          type: SocialPublishedContentType.post,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          body: 'Follow this public author.',
          audience: 'Public',
          mediaPaths: <String>[],
          mediaAreAssets: false,
          choices: <SocialPublishedChoice>[],
        ),
      );
      await journey.start();
      await shared.loadSocialFeed(refresh: true);

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
      final relationship = find.byKey(
        Key('social-author-relationship-${item.id}'),
      );
      await tester.tap(relationship);
      await tester.pumpAndSettle();

      expect(shared.socialAuthorProfile(item.authorId!)?.followed, isTrue);
      expect(
        find.descendant(of: relationship, matching: find.text('Following')),
        findsOneWidget,
      );
      await tester.tap(relationship);
      await tester.pumpAndSettle();
      expect(shared.socialAuthorProfile(item.authorId!)?.followed, isFalse);
      expect(find.text('Follow'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'C30T restored Follow intent never unfollows an existing relationship',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final socialGateway = ReviewSocialContentGateway();
      final shared = SharedSession(socialContentGateway: socialGateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      final item = await socialGateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'restored-follow-already-complete',
          type: SocialPublishedContentType.post,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          body: 'Keep this existing follow relationship.',
          audience: 'Public',
          mediaPaths: <String>[],
          mediaAreAssets: false,
          choices: <SocialPublishedChoice>[],
        ),
      );
      await socialGateway.follow(authorId: item.authorId!, followed: true);
      await journey.start();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialUniversalV2(
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
            initialSubAction: 'feed',
            initialItem: item.id,
            initialAction: 'follow',
            youtubePublicAccessOverride: false,
            youtubeCreatorAccessOverride: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(shared.socialAuthorProfile(item.authorId!)?.followed, isTrue);
      expect(
        find.descendant(
          of: find.byKey(Key('social-author-relationship-${item.id}')),
          matching: find.text('Following'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C30T guest Report preserves the exact post action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(snapshot: readySnapshot),
      allowGuestReady: true,
    );
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final socialGateway = ReviewSocialContentGateway();
    final shared = SharedSession(socialContentGateway: socialGateway);
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);
    final item = await socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'guest-report-return',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'A public post with report controls.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await journey.start();
    await shared.loadSocialFeed(refresh: true);

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
    await tester.tap(find.byKey(Key('social-post-more-${item.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('social-report-post-${item.id}')));
    await tester.pump();

    expect(journey.stage, JourneyStage.signIn);
    expect(
      journey.returnTo,
      '/app/social?sub=feed&item=${item.id}&action=report',
    );
    expect(socialGateway.reports, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C30T authenticated Report waits for durable confirmation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(snapshot: readySnapshot),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final socialGateway = ReviewSocialContentGateway();
    final shared = SharedSession(socialContentGateway: socialGateway);
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);
    final item = await socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'authenticated-report',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Report this post only after confirmation.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await journey.start();
    await shared.loadSocialFeed(refresh: true);

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
    await tester.tap(find.byKey(Key('social-post-more-${item.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('social-report-post-${item.id}')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('social-report-reason-dialog-${item.id}')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('social-report-reason-spam')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('social-report-confirm-${item.id}')), findsOneWidget);
    await tester.tap(find.byKey(const Key('social-report-send')));
    await tester.pumpAndSettle();

    expect(socialGateway.reports, hasLength(1));
    expect(socialGateway.reports.single.$1, item.id);
    expect(socialGateway.reports.single.$2, SocialReportReason.spam);
    expect(shared.socialPostReported(item.id), isTrue);
    expect(find.textContaining('Report sent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C30T guest Saved posts preserves the exact return', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(snapshot: readySnapshot),
      allowGuestReady: true,
    );
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final shared = SharedSession(
      socialContentGateway: UiReviewSocialContentGateway(),
    );
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
          enableCreateReviewPreview: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-feed-saved-posts')));
    await tester.pump();

    expect(journey.stage, JourneyStage.signIn);
    expect(journey.returnTo, '/app/social?sub=feed&state=saved');
    expect(journey.readyRoute(), '/app/social?sub=feed');
    expect(tester.takeException(), isNull);
  });

  testWidgets('C30T Saved posts opens the selected public post', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(snapshot: readySnapshot),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final socialGateway = ReviewSocialContentGateway();
    final shared = SharedSession(socialContentGateway: socialGateway);
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);
    final item = await socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'saved-post-library',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'A useful post saved for later.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await journey.start();
    await shared.loadSocialFeed(refresh: true);
    expect(await shared.toggleSocialSave(item.id), isTrue);

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
    await tester.tap(find.byKey(const Key('screen04-feed-saved-posts')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('social-saved-posts-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(Key('social-saved-post-${item.id}')),
        matching: find.text('A useful post saved for later.'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(Key('social-saved-open-${item.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('social-post-detail-${item.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'C30T post-sign-in author return reopens the exact public author',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final socialGateway = ReviewSocialContentGateway();
      final shared = SharedSession(socialContentGateway: socialGateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      final item = await socialGateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'author-post-sign-in-return',
          type: SocialPublishedContentType.post,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          body: 'Restore this exact public author.',
          audience: 'Public',
          mediaPaths: <String>[],
          mediaAreAssets: false,
          choices: <SocialPublishedChoice>[],
        ),
      );
      await journey.start();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialUniversalV2(
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
            initialSubAction: 'feed',
            initialState: 'author',
            initialItem: item.id,
            youtubePublicAccessOverride: false,
            youtubeCreatorAccessOverride: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('social-author-panel-${item.authorId}')),
        findsOneWidget,
      );
      expect(find.text('Restore this exact public author.'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C30T author sheet fits compact 140 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(snapshot: readySnapshot),
      allowGuestReady: true,
    );
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final socialGateway = ReviewSocialContentGateway();
    final shared = SharedSession(socialContentGateway: socialGateway);
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);
    final item = await socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'compact-author-profile',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Compact public author post.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await journey.start();
    await shared.loadSocialFeed(refresh: true);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
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
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(Key('social-author-profile-${item.id}')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(Key('social-author-panel-${item.authorId}')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('social-author-follow-${item.authorId}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'C30T public media and Share stay guest-readable while account actions gate',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(snapshot: readySnapshot),
        allowGuestReady: true,
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final item = SocialPublishedItem(
        id: 'public-action-truth',
        authorId: 'public-author-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Choose the best market time.',
        audience: 'Public',
        publishedAt: DateTime.utc(2026, 8, 13),
        mediaPaths: const ['assets/prototype/social-market-grocery.png'],
        mediaAreAssets: true,
      );
      final socialGateway = _RecordingFeedGateway(item);
      final shared = SharedSession(socialContentGateway: socialGateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);
      await journey.start();
      await shared.loadSocialFeed(refresh: true);

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

      final media = find.byType(SocialMediaPreviewV2);
      expect(media, findsOneWidget);
      await tester.tapAt(tester.getCenter(media));
      await tester.pumpAndSettle();
      expect(journey.stage, JourneyStage.ready);
      expect(
        find.byKey(const Key('social-public-media-view-public-action-truth')),
        findsOneWidget,
      );
      expect(socialGateway.interactions, isEmpty);
      Navigator.of(
        tester.element(
          find.byKey(const Key('social-public-media-view-public-action-truth')),
        ),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('social-public-share-public-action-truth')),
      );
      await tester.pumpAndSettle();
      expect(journey.stage, JourneyStage.ready);
      expect(find.byKey(const Key('social-copy-post-link')), findsOneWidget);
      expect(find.byKey(const Key('social-share-repost')), findsOneWidget);
      expect(
        find.byKey(const Key('social-share-add-thoughts')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('social-share-send-chat')), findsOneWidget);
      expect(find.byKey(const Key('social-share-other-apps')), findsOneWidget);
      expect(find.byKey(const Key('social-copy-post-link')), findsOneWidget);
      expect(socialGateway.interactions, isEmpty);
      await tester.tap(find.byKey(const Key('social-share-add-thoughts')));
      await tester.pump();
      expect(journey.stage, JourneyStage.signIn);
      expect(
        journey.returnTo,
        '/app/social?sub=create&state=shared-post&item=public-action-truth',
      );
      expect(socialGateway.interactions, isEmpty);
      journey.cancelSignIn();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('social-public-share-public-action-truth')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('social-share-send-chat')));
      await tester.pump();
      expect(journey.stage, JourneyStage.signIn);
      expect(
        journey.returnTo,
        '/app/chat?draft=https%3A%2F%2Fmoolsocial.com%2Fapp%2Fsocial%3Fsub%3Dfeed%26item%3Dpublic-action-truth&return=%2Fapp%2Fsocial%3Fsub%3Dfeed%26item%3Dpublic-action-truth',
      );
      expect(socialGateway.interactions, isEmpty);
      journey.cancelSignIn();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('social-public-share-public-action-truth')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('social-share-repost')));
      await tester.pump();
      expect(journey.stage, JourneyStage.signIn);
      expect(
        journey.returnTo,
        '/app/social?sub=feed&item=public-action-truth&action=repost',
      );
      expect(socialGateway.interactions, isEmpty);
      journey.cancelSignIn();
      await tester.pumpAndSettle();

      for (final entry in const {
        'social-public-like-public-action-truth': 'like',
        'social-public-repost-public-action-truth': 'repost',
        'social-public-save-public-action-truth': 'save',
      }.entries) {
        final actionKey = entry.key;
        await tester.tap(find.byKey(Key(actionKey)));
        await tester.pump();
        expect(journey.stage, JourneyStage.signIn, reason: actionKey);
        expect(
          journey.returnTo,
          '/app/social?sub=feed&item=public-action-truth&action=${entry.value}',
          reason: actionKey,
        );
        expect(socialGateway.interactions, isEmpty, reason: actionKey);
        journey.cancelSignIn();
        await tester.pump();
      }

      expect(
        find.byKey(const Key('social-message-author-public-action-truth')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const Key('social-author-profile-public-action-truth')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('social-author-panel-public-author-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('social-author-message-request-public-author-1')),
        findsNothing,
      );
      expect(journey.stage, JourneyStage.ready);
      expect(socialGateway.interactions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C30T public media viewer fits compact large-text geometry', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final shared = SharedSession();
    addTearDown(shared.dispose);
    final item = SocialPublishedItem(
      id: 'compact-public-photo',
      type: SocialPublishedContentType.post,
      authorName: 'Riya Sharma',
      authorHandle: '@riyasharma',
      body: 'A public market photo.',
      audience: 'Public',
      publishedAt: DateTime.utc(2026, 8, 13),
      mediaPaths: const ['assets/prototype/social-market-grocery.png'],
      mediaAreAssets: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SocialPublishedContentCardV2(
              item: item,
              session: shared,
              onReply: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final media = find.byKey(
      const Key('social-public-media-compact-public-photo'),
    );
    await tester.ensureVisible(media);
    await tester.tap(media);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('social-public-media-view-compact-public-photo')),
      findsOneWidget,
    );
    expect(find.text('Public photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('C30T failed Feed refresh preserves the load-more cursor', () async {
    final gateway = _RefreshFailurePaginationGateway();
    final shared = SharedSession(socialContentGateway: gateway);
    addTearDown(shared.dispose);

    expect(await shared.loadSocialFeed(refresh: true), isTrue);
    expect(shared.socialPublishedItems.map((item) => item.id), ['page-1']);
    expect(shared.socialFeedHasMore, isTrue);

    expect(await shared.loadSocialFeed(refresh: true), isFalse);
    expect(shared.socialPublishedItems.map((item) => item.id), ['page-1']);
    expect(shared.socialFeedHasMore, isTrue);
    expect(shared.socialFeedError, 'Refresh unavailable.');

    expect(await shared.loadSocialFeed(), isTrue);
    expect(gateway.feedCursors, [null, null, 'next-page']);
    expect(shared.socialPublishedItems.map((item) => item.id), [
      'page-1',
      'page-2',
    ]);
    expect(shared.socialFeedHasMore, isFalse);
  });

  test('C30T Feed retry repeats the failed load-more cursor', () async {
    final gateway = _LoadMoreRetryGateway();
    final shared = SharedSession(socialContentGateway: gateway);
    addTearDown(shared.dispose);

    expect(await shared.loadSocialFeed(refresh: true), isTrue);
    expect(await shared.loadSocialFeed(), isFalse);
    expect(shared.socialFeedError, 'Next page unavailable.');
    expect(shared.socialPublishedItems.map((item) => item.id), ['page-1']);

    expect(await shared.retrySocialFeed(), isTrue);
    expect(gateway.feedCursors, [null, 'next-page', 'next-page']);
    expect(shared.socialPublishedItems.map((item) => item.id), [
      'page-1',
      'page-2',
    ]);
    expect(shared.socialFeedHasMore, isFalse);
  });

  test('C30T unexpected Social failures retain state and fail closed', () async {
    final gateway = _UnexpectedFailureGateway();
    final shared = SharedSession(socialContentGateway: gateway);
    addTearDown(shared.dispose);

    expect(await shared.loadSocialFeed(refresh: true), isTrue);
    final original = shared.socialPublishedItems.single;
    gateway.fail = true;

    expect(await shared.loadSocialFeed(refresh: true), isFalse);
    expect(shared.socialPublishedItems.single, same(original));
    expect(
      shared.socialFeedError,
      'Feed is unavailable right now. Your last loaded posts remain visible.',
    );

    expect(
      await shared.publishSocialContent(
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Keep this unfinished post.',
      ),
      isNull,
    );
    expect(
      shared.errorMessage,
      'Your content could not be posted. It is still here. Please try again.',
    );

    expect(await shared.toggleSocialLike(original.id), isFalse);
    expect(shared.socialPublishedItems.single.liked, isFalse);
    expect(
      shared.socialInteractionError(original.id),
      'That Feed action could not be completed. Nothing changed. Please try again.',
    );
  });
}

const readySnapshot = JourneySnapshot(
  languageCode: 'en',
  areaMode: 'current',
  areaLabel: 'Jodhpur',
  setupComplete: true,
  setupExperienceVersion: approvedSetupExperienceVersion,
);

class _RefreshFailurePaginationGateway implements SocialContentGateway {
  final List<String?> feedCursors = <String?>[];

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async {
    feedCursors.add(cursor);
    return switch (feedCursors.length) {
      1 => SocialFeedPage(items: [_post('page-1')], nextCursor: 'next-page'),
      2 => throw const SocialContentGatewayException(
        code: 'unavailable',
        message: 'Refresh unavailable.',
        retryable: true,
      ),
      3 => SocialFeedPage(items: [_post('page-2')]),
      _ => throw StateError('Unexpected Feed request.'),
    };
  }

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => Future<SocialPublishedItem>.error(
    StateError('Interaction is outside this pagination test.'),
  );

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      Future<SocialPublishedItem>.error(
        StateError('Publish is outside this pagination test.'),
      );
}

class _LoadMoreRetryGateway implements SocialContentGateway {
  final List<String?> feedCursors = <String?>[];

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async {
    feedCursors.add(cursor);
    return switch (feedCursors.length) {
      1 => SocialFeedPage(items: [_post('page-1')], nextCursor: 'next-page'),
      2 => throw const SocialContentGatewayException(
        code: 'unavailable',
        message: 'Next page unavailable.',
        retryable: true,
      ),
      3 => SocialFeedPage(items: [_post('page-2')]),
      _ => throw StateError('Unexpected Feed request.'),
    };
  }

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => Future<SocialPublishedItem>.error(
    StateError('Interaction is outside this pagination test.'),
  );

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      Future<SocialPublishedItem>.error(
        StateError('Publish is outside this pagination test.'),
      );
}

class _UnexpectedFailureGateway implements SocialContentGateway {
  bool fail = false;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async {
    if (fail) throw StateError('private unexpected Feed failure');
    return SocialFeedPage(items: [_post('retained-post')]);
  }

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => Future.error(StateError('private unexpected interaction failure'));

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      Future.error(StateError('private unexpected publish failure'));
}

class _RecordingFeedGateway implements SocialContentGateway {
  _RecordingFeedGateway(this.item);

  final SocialPublishedItem item;
  final List<String> interactions = <String>[];

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      SocialFeedPage(items: [item]);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) async {
    interactions.add(interaction);
    return item;
  }

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      Future<SocialPublishedItem>.error(
        StateError('Publish is outside this action-truth test.'),
      );
}

SocialPublishedItem _post(String id) => SocialPublishedItem(
  id: id,
  authorId: 'author-$id',
  type: SocialPublishedContentType.post,
  authorName: 'Feed author',
  authorHandle: '@feedauthor',
  body: 'Feed page $id',
  audience: 'Public',
  publishedAt: DateTime.utc(2026, 8, 13),
);
