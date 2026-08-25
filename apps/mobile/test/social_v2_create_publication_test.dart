import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_services.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/shared/social_create_draft_repository.dart';
import 'package:moolsocial/features/shared/social_media_picker.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_create_workbench.dart';
import 'package:moolsocial/ui_v2/social/social_v2_public_content.dart';
import 'package:share_plus/share_plus.dart';

import 'support/review_social_content_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareOrigin = Rect.fromLTWH(12, 24, 180, 44);
  final shareRequest = SocialV2ShareRequest(
    uri: Uri.https('moolsocial.com', '/app/social', {
      'sub': 'feed',
      'item': 'post-1',
    }),
    title: 'Share MoolSocial post',
    subject: 'MoolSocial post',
    sharePositionOrigin: shareOrigin,
  );

  test(
    'native share gateway forwards exact safe URI and presentation',
    () async {
      ShareParams? captured;
      final gateway = SocialV2PlatformShareGateway(
        invoker: (params) async {
          captured = params;
          return const ShareResult('target.app', ShareResultStatus.success);
        },
      );

      final outcome = await gateway.share(shareRequest);

      expect(outcome, SocialV2ShareOutcome.selected);
      expect(captured?.uri, shareRequest.uri);
      expect(captured?.title, 'Share MoolSocial post');
      expect(captured?.subject, 'MoolSocial post');
      expect(captured?.sharePositionOrigin, shareOrigin);
      expect(captured?.downloadFallbackEnabled, isFalse);
      expect(captured?.mailToFallbackEnabled, isFalse);
      expect(captured?.text, isNull);
      expect(captured?.files, isNull);
    },
  );

  test(
    'native share gateway preserves dismissed and unavailable truth',
    () async {
      final dismissed = SocialV2PlatformShareGateway(
        invoker: (_) async =>
            const ShareResult('', ShareResultStatus.dismissed),
      );
      final unavailable = SocialV2PlatformShareGateway(
        invoker: (_) async => ShareResult.unavailable,
      );
      final failed = SocialV2PlatformShareGateway(
        invoker: (_) => throw StateError('platform share failed'),
      );

      expect(
        await dismissed.share(shareRequest),
        SocialV2ShareOutcome.dismissed,
      );
      expect(
        await unavailable.share(shareRequest),
        SocialV2ShareOutcome.unavailable,
      );
      expect(
        await failed.share(shareRequest),
        SocialV2ShareOutcome.unavailable,
      );
    },
  );

  test(
    'native share gateway rejects unsafe input before platform egress',
    () async {
      var calls = 0;
      final gateway = SocialV2PlatformShareGateway(
        invoker: (_) async {
          calls += 1;
          return const ShareResult('target.app', ShareResultStatus.success);
        },
      );

      final result = await gateway.share(
        SocialV2ShareRequest(
          uri: Uri.parse('http://moolsocial.com/app/social?item=post-1'),
          title: 'Share MoolSocial post',
          sharePositionOrigin: shareOrigin,
        ),
      );

      expect(result, SocialV2ShareOutcome.unavailable);
      expect(calls, 0);
    },
  );

  test(
    'native share gateway contains duplicate taps with one operation',
    () async {
      var calls = 0;
      final result = Completer<ShareResult>();
      final gateway = SocialV2PlatformShareGateway(
        invoker: (_) {
          calls += 1;
          return result.future;
        },
      );

      final first = gateway.share(shareRequest);
      final second = gateway.share(shareRequest);
      expect(identical(first, second), isTrue);
      expect(calls, 1);

      result.complete(const ShareResult('', ShareResultStatus.dismissed));
      expect(await first, SocialV2ShareOutcome.dismissed);
      expect(await second, SocialV2ShareOutcome.dismissed);
    },
  );

  test('Feed published time uses the authoritative provider timestamp', () {
    final now = DateTime.utc(2026, 8, 13, 12);
    expect(
      socialPublishedAgeLabel(DateTime.utc(2026, 8, 13, 12, 1), now: now),
      'Just now',
    );
    expect(
      socialPublishedAgeLabel(DateTime.utc(2026, 8, 13, 11, 59, 1), now: now),
      'Just now',
    );
    expect(
      socialPublishedAgeLabel(DateTime.utc(2026, 8, 13, 11, 1), now: now),
      '59m',
    );
    expect(
      socialPublishedAgeLabel(DateTime.utc(2026, 8, 13, 10), now: now),
      '2h',
    );
    expect(
      socialPublishedAgeLabel(DateTime.utc(2026, 8, 10, 12), now: now),
      '3d',
    );
    expect(
      socialPublishedAgeLabel(DateTime.utc(2026, 8, 6, 12), now: now),
      '6 Aug 2026',
    );
  });

  test('poll closing copy uses the authoritative provider timestamp', () {
    final now = DateTime.utc(2026, 8, 13, 12);
    expect(socialPollClosingLabel(null, now: now), isEmpty);
    expect(
      socialPollClosingLabel(DateTime.utc(2026, 8, 13, 12), now: now),
      'Closed',
    );
    expect(
      socialPollClosingLabel(DateTime.utc(2026, 8, 13, 12, 0, 1), now: now),
      'Closes in 1m',
    );
    expect(
      socialPollClosingLabel(DateTime.utc(2026, 8, 13, 13), now: now),
      'Closes in 1h',
    );
    expect(
      socialPollClosingLabel(DateTime.utc(2026, 8, 20, 12), now: now),
      'Closes in 7d',
    );
  });

  testWidgets('expired quiz disables every choice and says Closed', (
    tester,
  ) async {
    final session = SharedSession(
      socialContentGateway: ReviewSocialContentGateway(),
    );
    addTearDown(session.dispose);
    final item = SocialPublishedItem(
      id: 'expired-quiz',
      authorId: 'author-1',
      type: SocialPublishedContentType.quiz,
      authorName: 'Asha Sharma',
      authorHandle: '@ashasharma',
      body: 'Choose the millet',
      audience: 'Public',
      publishedAt: DateTime.utc(2026, 8, 1),
      closesAt: DateTime.now().subtract(const Duration(seconds: 1)),
      choices: const [
        SocialPublishedChoice(label: 'Millet'),
        SocialPublishedChoice(label: 'Barley'),
        SocialPublishedChoice(label: 'Rice'),
        SocialPublishedChoice(label: 'Oats'),
      ],
      correctChoiceIndex: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialPublishedContentCardV2(
            item: item,
            session: session,
            onReply: () {},
            onShare: () {},
          ),
        ),
      ),
    );

    expect(find.text('Choose one answer · Closed'), findsOneWidget);
    for (var index = 0; index < 4; index += 1) {
      final choice = tester.widget<OutlinedButton>(
        find.byKey(Key('social-public-expired-quiz-choice-$index')),
      );
      expect(choice.onPressed, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  test(
    'SharedSession publishes and owns every approved public format',
    () async {
      final session = SharedSession(
        socialContentGateway: ReviewSocialContentGateway(),
      );
      addTearDown(session.dispose);
      const author = 'Asha Sharma';
      const handle = '@ashasharma';
      const image = 'assets/prototype/social-market-grocery.png';

      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.reel,
          authorName: author,
          authorHandle: handle,
          body: 'Morning market walk',
          mediaPaths: const [image],
          mediaAreAssets: true,
        ),
        isNull,
      );
      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.carousel,
          authorName: author,
          authorHandle: handle,
          body: 'Three ways to serve millet',
          mediaPaths: const [image, image],
          mediaAreAssets: true,
        ),
        isNotNull,
      );
      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.post,
          authorName: author,
          authorHandle: handle,
          body: 'Fresh produce is available today.',
        ),
        isNotNull,
      );
      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.imagePoll,
          authorName: author,
          authorHandle: handle,
          body: 'Which basket would you choose?',
          choices: const [
            SocialPublishedChoice(
              label: 'Family basket',
              imagePath: image,
              imageIsAsset: true,
            ),
            SocialPublishedChoice(
              label: 'Weekly basket',
              imagePath: image,
              imageIsAsset: true,
            ),
            SocialPublishedChoice(
              label: 'Fruit basket',
              imagePath: image,
              imageIsAsset: true,
            ),
            SocialPublishedChoice(
              label: 'Vegetable basket',
              imagePath: image,
              imageIsAsset: true,
            ),
          ],
        ),
        isNotNull,
      );
      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.quickPoll,
          authorName: author,
          authorHandle: handle,
          body: 'Which delivery time suits you?',
          choices: const [
            SocialPublishedChoice(label: 'Morning'),
            SocialPublishedChoice(label: 'Evening'),
          ],
        ),
        isNull,
      );
      expect(session.errorMessage, 'Add all four choices.');
      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.quickPoll,
          authorName: author,
          authorHandle: handle,
          body: 'Which delivery time suits you?',
          choices: const [
            SocialPublishedChoice(label: 'Morning'),
            SocialPublishedChoice(label: 'Evening'),
            SocialPublishedChoice(label: 'Afternoon'),
            SocialPublishedChoice(label: 'Night'),
          ],
        ),
        isNotNull,
      );
      expect(
        await session.publishSocialContent(
          type: SocialPublishedContentType.quiz,
          authorName: author,
          authorHandle: handle,
          body: 'Which grain is naturally gluten-free?',
          choices: const [
            SocialPublishedChoice(label: 'Millet'),
            SocialPublishedChoice(label: 'Barley'),
            SocialPublishedChoice(label: 'Rice'),
            SocialPublishedChoice(label: 'Oats'),
          ],
          correctChoiceIndex: 0,
        ),
        isNotNull,
      );

      expect(session.socialPublishedItems.map((item) => item.type).toSet(), {
        SocialPublishedContentType.carousel,
        SocialPublishedContentType.post,
        SocialPublishedContentType.imagePoll,
        SocialPublishedContentType.quickPoll,
        SocialPublishedContentType.quiz,
      });
      expect(session.latestPublishedReel, isNull);
      final quiz = session.socialPublishedItems.first;
      expect(quiz.type, SocialPublishedContentType.quiz);
      expect(await session.voteOnSocialContent(quiz.id, 0), isTrue);
      expect(session.socialPublishedItems.first.selectedChoiceIndex, 0);
    },
  );

  testWidgets('Create publishes entered Post copy into the public Feed', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, owners.consumer(sub: 'create'));
    expect(find.byKey(const Key('social-v2-create-workbench')), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'Jodhpur makers meet this Saturday.',
    );
    await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
    await tester.pumpAndSettle();

    expect(find.text('Jodhpur makers meet this Saturday.'), findsOneWidget);
    expect(
      find.byKey(
        Key(
          'social-public-post-${owners.shared.socialPublishedItems.single.id}',
        ),
      ),
      findsOneWidget,
    );
    expect(
      owners.shared.socialPublishedItems.single.body,
      'Jodhpur makers meet this Saturday.',
    );
    final post = find.byKey(
      Key('social-public-post-${owners.shared.socialPublishedItems.single.id}'),
    );
    final postCta = find.byKey(
      const Key('screen04-feed-post-cta-after-timeline'),
    );
    expect(postCta, findsOneWidget);
    expect(tester.getTopLeft(post).dy, lessThan(tester.getTopLeft(postCta).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('late Create success preserves a newer exact draft', (
    tester,
  ) async {
    final gateway = _DelayedPublishSocialContentGateway();
    final session = SharedSession(socialContentGateway: gateway);
    final draft = SocialCreateDraftV2();
    final picker = _FakeSocialMediaPicker();
    var publishedCount = 0;
    addTearDown(session.dispose);

    Widget workbench() => MaterialApp(
      home: Scaffold(
        body: SocialCreateWorkbenchV2(
          session: session,
          mediaPicker: picker,
          authorName: 'Asha Sharma',
          authorHandle: '@ashasharma',
          draft: draft,
          allowReel: false,
          onPublished: (_) => publishedCount += 1,
        ),
      ),
    );

    await tester.pumpWidget(workbench());
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'The exact submitted post.',
    );
    await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
    await tester.pump();
    expect(session.busy, isTrue);
    expect(gateway.lastDraft?.body, 'The exact submitted post.');

    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'A newer draft that must remain.',
    );
    gateway.completePublish();
    await tester.pumpAndSettle();

    expect(publishedCount, 1);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
          .controller!
          .text,
      'A newer draft that must remain.',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(workbench());
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
          .controller!
          .text,
      'A newer draft that must remain.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed renders real public posts before its post CTA', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    final publicPost = await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'other-public-post-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'The community market opens at six this evening.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    expect(await owners.shared.loadSocialFeed(refresh: true), isTrue);
    await _pump(tester, owners.consumer(sub: 'feed'));

    final post = find.byKey(Key('social-public-post-${publicPost.id}'));
    final postCta = find.byKey(
      const Key('screen04-feed-post-cta-after-timeline'),
    );
    expect(post, findsOneWidget);
    expect(find.text('Riya Sharma'), findsOneWidget);
    expect(postCta, findsOneWidget);
    expect(tester.getTopLeft(post).dy, lessThan(tester.getTopLeft(postCta).dy));
    expect(find.byKey(const Key('screen04-feed-create-post')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed copies the exact stable link for the selected post', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    final publicPost = await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'share-public-post-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Share this exact public post.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await owners.shared.loadSocialFeed(refresh: true);
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pump(tester, owners.consumer(sub: 'feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('social-public-share-${publicPost.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('social-share-repost')), findsOneWidget);
    expect(find.byKey(const Key('social-share-add-thoughts')), findsOneWidget);
    expect(find.byKey(const Key('social-share-send-chat')), findsOneWidget);
    expect(find.byKey(const Key('social-copy-post-link')), findsOneWidget);

    await tester.tap(find.byKey(const Key('social-copy-post-link')));
    await tester.pumpAndSettle();
    expect(
      copiedText,
      'https://moolsocial.com/app/social?sub=feed&item=${publicPost.id}',
    );
    expect(find.text('Post link copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed opens native share with the exact stable public URL', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    final publicPost = await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'native-share-public-post-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Share this public post through the phone.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await owners.shared.loadSocialFeed(refresh: true);
    final shareGateway = _RecordingShareGateway(
      outcome: SocialV2ShareOutcome.dismissed,
    );

    await _pump(
      tester,
      owners.consumer(sub: 'feed', shareGateway: shareGateway),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('social-public-share-${publicPost.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('social-share-other-apps')), findsOneWidget);
    expect(find.byKey(const Key('social-copy-post-link')), findsOneWidget);
    await tester.tap(find.byKey(const Key('social-share-other-apps')));
    await tester.pumpAndSettle();

    expect(shareGateway.calls, 1);
    expect(
      shareGateway.request?.uri,
      Uri.parse(
        'https://moolsocial.com/app/social?sub=feed&item=${publicPost.id}',
      ),
    );
    expect(shareGateway.request?.title, 'Share MoolSocial post');
    expect(shareGateway.request?.subject, 'MoolSocial post');
    expect(shareGateway.request?.sharePositionOrigin.isFinite, isTrue);
    expect(shareGateway.request?.sharePositionOrigin.width, greaterThan(0));
    expect(shareGateway.request?.sharePositionOrigin.height, greaterThan(0));
    expect(find.byKey(const Key('social-share-other-apps')), findsNothing);
    expect(find.text('Post link copied'), findsNothing);
    expect(find.text('Shared'), findsNothing);
    expect(
      find.byKey(Key('social-public-post-${publicPost.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed share failure keeps Copy link as a truthful recovery', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    final publicPost = await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'native-share-unavailable-post-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Keep the public link recoverable.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await owners.shared.loadSocialFeed(refresh: true);
    final shareGateway = _RecordingShareGateway(
      outcome: SocialV2ShareOutcome.unavailable,
    );

    await _pump(
      tester,
      owners.consumer(sub: 'feed', shareGateway: shareGateway),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('social-public-share-${publicPost.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('social-share-other-apps')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Sharing is unavailable right now. You can copy the link instead.',
      ),
      findsOneWidget,
    );
    expect(find.text('Shared'), findsNothing);
    await tester.tap(find.byKey(Key('social-public-share-${publicPost.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('social-copy-post-link')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed contains clipboard failure without a false copy claim', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    final publicPost = await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'share-failure-public-post-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Keep this share journey recoverable.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await owners.shared.loadSocialFeed(refresh: true);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'clipboard-unavailable');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pump(tester, owners.consumer(sub: 'feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('social-public-share-${publicPost.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('social-copy-post-link')));
    await tester.pump();

    expect(
      find.text('Post link could not be copied. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Post link copied'), findsNothing);
    expect(find.byKey(const Key('social-copy-post-link')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest Like Save and Vote use one authentication gate', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    final authenticationRequests = <SocialProtectedActionIntent>[];
    final item = SocialPublishedItem(
      id: 'guest-poll',
      authorId: 'author-1',
      type: SocialPublishedContentType.quickPoll,
      authorName: 'Riya Sharma',
      authorHandle: '@riyasharma',
      body: 'Choose a delivery window',
      audience: 'Public',
      publishedAt: DateTime.utc(2026, 8, 13),
      choices: const [
        SocialPublishedChoice(label: 'Morning'),
        SocialPublishedChoice(label: 'Afternoon'),
        SocialPublishedChoice(label: 'Evening'),
        SocialPublishedChoice(label: 'Night'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialPublishedContentCardV2(
            item: item,
            session: owners.shared,
            onReply: () {},
            onShare: () {},
            onAuthenticationRequired: authenticationRequests.add,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('social-public-like-guest-poll')));
    await tester.tap(find.byKey(const Key('social-public-save-guest-poll')));
    await tester.tap(
      find.byKey(const Key('social-public-guest-poll-choice-0')),
    );
    await tester.pump();

    expect(authenticationRequests.map((intent) => intent.action), const [
      SocialProtectedAction.like,
      SocialProtectedAction.save,
      SocialProtectedAction.vote,
    ]);
    expect(authenticationRequests.last.choiceIndex, 0);
    expect(item.liked, isFalse);
    expect(item.saved, isFalse);
    expect(item.selectedChoiceIndex, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed server actions explain offline outcomes without mutation', (
    tester,
  ) async {
    final shared = SharedSession(
      socialContentGateway: ReviewSocialContentGateway(),
    )..online = false;
    addTearDown(shared.dispose);
    final item = SocialPublishedItem(
      id: 'offline-actions',
      authorId: 'author-1',
      type: SocialPublishedContentType.quickPoll,
      authorName: 'Riya Sharma',
      authorHandle: '@riyasharma',
      body: 'Choose a delivery window',
      audience: 'Public',
      publishedAt: DateTime.utc(2026, 8, 13),
      choices: const [
        SocialPublishedChoice(label: 'Morning'),
        SocialPublishedChoice(label: 'Afternoon'),
        SocialPublishedChoice(label: 'Evening'),
        SocialPublishedChoice(label: 'Night'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialPublishedContentCardV2(
            item: item,
            session: shared,
            onReply: () {},
            onShare: () {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('social-public-like-offline-actions')),
    );
    await tester.pump();
    expect(find.text('You are offline. Nothing changed.'), findsOneWidget);
    expect(item.liked, isFalse);

    await tester.tap(
      find.byKey(const Key('social-public-repost-offline-actions')),
    );
    await tester.pump();
    expect(find.text('You are offline. Nothing changed.'), findsOneWidget);
    expect(item.repostCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed Repost and Undo wait for server-acknowledged truth', (
    tester,
  ) async {
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final owners = _Owners(journey: journey);
    addTearDown(owners.dispose);
    await journey.start();
    expect(journey.isAuthenticated, isTrue);
    final post = await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'repost-public-post-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Repost this public update.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await owners.shared.loadSocialFeed(refresh: true);
    await _pump(tester, owners.consumer(sub: 'feed'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('social-public-share-${post.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('social-share-repost')));
    await tester.pumpAndSettle();
    expect(owners.shared.socialPublishedItems.single.reposted, isTrue);
    expect(owners.shared.socialPublishedItems.single.repostCount, 1);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.byKey(Key('social-public-repost-${post.id}')));
    await tester.pumpAndSettle();
    expect(owners.shared.socialPublishedItems.single.reposted, isFalse);
    expect(owners.shared.socialPublishedItems.single.repostCount, 0);
    expect(find.text('Repost'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add thoughts publishes a structured quoted Feed post', (
    tester,
  ) async {
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final owners = _Owners(journey: journey);
    addTearDown(owners.dispose);
    await journey.start();
    expect(journey.isAuthenticated, isTrue);
    final original = await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'quoted-original-post-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Original public market update.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );
    await owners.shared.loadSocialFeed(refresh: true);
    await _pump(tester, owners.consumer(sub: 'feed'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('social-public-share-${original.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('social-share-add-thoughts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('social-create-quoted-post')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'My verified context for this update.',
    );
    await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
    await tester.pumpAndSettle();

    final published = owners.shared.socialPublishedItems.first;
    expect(published.body, 'My verified context for this update.');
    expect(published.quotedPost?.id, original.id);
    expect(published.quotedPost?.body, 'Original public market update.');
    expect(find.text('My verified context for this update.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty Add thoughts keeps the exact quote and explains recovery',
    (tester) async {
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Jodhpur',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final owners = _Owners(journey: journey);
      addTearDown(owners.dispose);
      await journey.start();
      final original = await owners.socialGateway.publish(
        const SocialPublishDraft(
          idempotencyKey: 'quoted-empty-original-1',
          type: SocialPublishedContentType.post,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          body: 'Original public recovery context.',
          audience: 'Public',
          mediaPaths: <String>[],
          mediaAreAssets: false,
          choices: <SocialPublishedChoice>[],
        ),
      );
      await owners.shared.loadSocialFeed(refresh: true);
      await _pump(tester, owners.consumer(sub: 'feed'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('social-public-share-${original.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('social-share-add-thoughts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
      await tester.pumpAndSettle();

      expect(
        find.text('Add your thoughts before sharing this post.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('social-create-quoted-post')),
        findsOneWidget,
      );
      expect(find.text('Original public recovery context.'), findsOneWidget);
      expect(owners.shared.socialPublishedItems, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('post-sign-in shared-post return restores the exact quote', (
    tester,
  ) async {
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final owners = _Owners(journey: journey);
    addTearDown(owners.dispose);
    await journey.start();
    final original = await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'quoted-return-original-1',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'Restore this exact original after sign-in.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );

    await _pump(
      tester,
      owners.consumer(sub: 'create', state: 'shared-post', item: original.id),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('social-create-quoted-post')), findsOneWidget);
    expect(
      find.text('Restore this exact original after sign-in.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared Feed link loads later pages and brings its post first', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    SocialPublishedItem? sharedPost;
    for (var index = 0; index < 25; index += 1) {
      final item = await owners.socialGateway.publish(
        SocialPublishDraft(
          idempotencyKey: 'deep-link-post-$index',
          type: SocialPublishedContentType.post,
          authorName: 'Author $index',
          authorHandle: '@author$index',
          body: 'Public post $index',
          audience: 'Public',
          mediaPaths: const <String>[],
          mediaAreAssets: false,
          choices: const <SocialPublishedChoice>[],
        ),
      );
      sharedPost ??= item;
    }

    await _pump(tester, owners.consumer(sub: 'feed', item: sharedPost!.id));
    await tester.pumpAndSettle();

    expect(owners.shared.socialPublishedItems, hasLength(25));
    expect(
      find.byKey(Key('social-public-post-${sharedPost.id}')),
      findsOneWidget,
    );
    final sharedCard = find.byKey(Key('social-public-post-${sharedPost.id}'));
    final latestCard = find.byKey(
      Key('social-public-post-${owners.socialGateway.latestItemId}'),
    );
    expect(
      tester.getTopLeft(sharedCard).dy,
      lessThan(tester.getTopLeft(latestCard).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing shared Feed post keeps Feed and explains recovery', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await owners.socialGateway.publish(
      const SocialPublishDraft(
        idempotencyKey: 'remaining-post',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: 'A remaining public post.',
        audience: 'Public',
        mediaPaths: <String>[],
        mediaAreAssets: false,
        choices: <SocialPublishedChoice>[],
      ),
    );

    await _pump(tester, owners.consumer(sub: 'feed', item: 'removed-post'));
    await tester.pumpAndSettle();

    expect(find.text('This shared post is not available'), findsOneWidget);
    expect(find.text('A remaining public post.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-rail-feed')));
    await tester.pumpAndSettle();

    expect(find.text('This shared post is not available'), findsNothing);
    expect(find.text('A remaining public post.'), findsOneWidget);
    expect(owners.shared.socialPublishedItems, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'normal Feed entry cancels late shared-link presentation without data loss',
    (tester) async {
      final journey = JourneySession()
        ..emailAddress = 'asha.sharma@moolsocial.in';
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final gateway = _DelayedSharedLinkGateway();
      final shared = SharedSession(
        gateway: _ImmediateSharedGateway(),
        socialContentGateway: gateway,
      );
      addTearDown(() {
        journey.dispose();
        creator.dispose();
        retailer.dispose();
        shared.dispose();
      });

      await _pump(
        tester,
        SocialUniversalV2(
          session: journey,
          creatorSession: creator,
          retailerSession: retailer,
          sharedSession: shared,
          initialSubAction: 'feed',
          initialItem: 'older-shared-post',
        ),
      );
      await tester.pump();
      expect(gateway.feedCalls, 2);

      await tester.tap(find.byKey(const Key('screen04-rail-feed')));
      gateway.completeOlderPage();
      await tester.pumpAndSettle();

      final latest = find.byKey(const Key('social-public-post-latest-post'));
      final older = find.byKey(
        const Key('social-public-post-older-shared-post'),
      );
      expect(latest, findsOneWidget);
      expect(older, findsOneWidget);
      expect(
        tester.getTopLeft(latest).dy,
        lessThan(tester.getTopLeft(older).dy),
      );
      expect(find.text('This shared post is not available'), findsNothing);
      expect(shared.socialPublishedItems, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new shared Feed route supersedes an older page resolution', (
    tester,
  ) async {
    final journey = JourneySession()
      ..emailAddress = 'asha.sharma@moolsocial.in';
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final gateway = _DelayedSharedLinkGateway();
    final shared = SharedSession(
      gateway: _ImmediateSharedGateway(),
      socialContentGateway: gateway,
    );
    addTearDown(() {
      journey.dispose();
      creator.dispose();
      retailer.dispose();
      shared.dispose();
    });

    SocialUniversalV2 consumer(String item) => SocialUniversalV2(
      session: journey,
      creatorSession: creator,
      retailerSession: retailer,
      sharedSession: shared,
      initialSubAction: 'feed',
      initialItem: item,
    );

    await _pump(tester, consumer('older-shared-post'));
    await tester.pump();
    expect(gateway.feedCalls, 2);

    await _pump(tester, consumer('newer-shared-post'));
    expect(gateway.feedCalls, 2);
    gateway.completeOlderPage();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(gateway.feedCalls, 3);
    final newer = find.byKey(const Key('social-public-post-newer-shared-post'));
    final latest = find.byKey(const Key('social-public-post-latest-post'));
    expect(newer, findsOneWidget);
    expect(tester.getTopLeft(newer).dy, lessThan(tester.getTopLeft(latest).dy));
    expect(find.text('This shared post is not available'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create keeps its draft when the native photo picker fails', (
    tester,
  ) async {
    final session = SharedSession(
      socialContentGateway: ReviewSocialContentGateway(),
    );
    addTearDown(session.dispose);
    await _pump(
      tester,
      Scaffold(
        body: SocialCreateWorkbenchV2(
          session: session,
          mediaPicker: _FailingSocialMediaPicker(),
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          onPublished: (_) {},
          allowReel: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'Keep this production draft.',
    );

    await tester.tap(find.byKey(const Key('screen04-create-tool-image')));
    await tester.pumpAndSettle();

    expect(
      find.text('Photos could not be opened. Your draft is still here.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
          .controller
          ?.text,
      'Keep this production draft.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dirty Create rejects a conflicting explicit tool route', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, owners.consumer(sub: 'create', state: 'text'));
    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'Keep this caption across the route update.',
    );

    await _pump(tester, owners.consumer(sub: 'create', state: 'quiz'));
    await tester.pump();

    expect(
      find.byKey(const Key('screen04-create-quiz-choice-0')),
      findsNothing,
    );
    expect(find.text('New text post'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
          .controller
          ?.text,
      'Keep this caption across the route update.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create ignores media returned for an older tool route', (
    tester,
  ) async {
    final gateway = _CapturingSocialContentGateway();
    final session = SharedSession(socialContentGateway: gateway);
    final picker = _DelayedImagePicker();
    final draft = SocialCreateDraftV2();
    addTearDown(session.dispose);

    Widget workbench(SocialCreateIntentV2 intent) => MaterialApp(
      home: Scaffold(
        body: SocialCreateWorkbenchV2(
          session: session,
          mediaPicker: picker,
          authorName: 'Riya Sharma',
          authorHandle: '@riyasharma',
          draft: draft,
          initialIntent: intent,
          allowReel: false,
          onPublished: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(workbench(SocialCreateIntentV2.image));
    await tester.pump();
    await tester.pump();
    expect(picker.imageCalls, 1);
    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'Which choice is correct?',
    );

    await tester.pumpWidget(workbench(SocialCreateIntentV2.quiz));
    await tester.pump();
    expect(
      find.byKey(const Key('screen04-create-quiz-choice-0')),
      findsOneWidget,
    );
    picker.completeImage();
    await tester.pumpAndSettle();

    for (var index = 0; index < 4; index++) {
      await tester.enterText(
        find.byKey(Key('screen04-create-quiz-choice-$index')),
        'Choice ${index + 1}',
      );
    }
    await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
    await tester.pumpAndSettle();

    expect(gateway.lastDraft?.type, SocialPublishedContentType.quiz);
    expect(gateway.lastDraft?.mediaPaths, isEmpty);
    expect(gateway.lastDraft?.choices, hasLength(4));
    expect(find.byType(SocialMediaPreviewV2), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create keeps every MoolSocial-owned action in one workbench', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, owners.consumer(sub: 'create'));

    final workbench = find.byKey(const Key('screen04-create-workbench'));
    expect(workbench, findsOneWidget);
    for (final key in const [
      'screen04-create-tool-image',
      'screen04-create-tool-carousel',
      'screen04-create-tool-image-poll',
      'screen04-create-tool-quick-poll',
      'screen04-create-tool-quiz',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(find.byKey(const Key('screen04-create-tool-reel')), findsNothing);
    expect(
      find.byKey(const Key('screen04-create-youtube-short')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('screen04-create-tool-image')));
    await tester.pumpAndSettle();
    expect(workbench, findsOneWidget);
    expect(find.text('market.png'), findsNothing);

    await tester.tap(find.byKey(const Key('screen04-create-tool-carousel')));
    await tester.pumpAndSettle();
    expect(workbench, findsOneWidget);
    expect(find.text('2 / 10 photos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-create-tool-post')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-post-text')), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-create-tool-image-poll')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-image-poll-choice-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-create-image-poll-choice-3')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('screen04-create-tool-quick-poll')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-quick-poll-choice-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-create-quick-poll-choice-3')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('screen04-create-tool-quiz')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-quiz-choice-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-create-quiz-choice-3')),
      findsOneWidget,
    );
    expect(find.byType(Navigator), findsOneWidget);
    expect(workbench, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Create preserves every unfinished format across a Feed round trip',
    (tester) async {
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Jodhpur',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final owners = _Owners(journey: journey);
      addTearDown(owners.dispose);
      await journey.start();
      await _pump(tester, owners.consumer(sub: 'create'));

      Future<void> leaveAndReturn() async {
        await tester.tap(find.byKey(const Key('screen04-create-close')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('social-v2-create-workbench')),
          findsNothing,
        );
        expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);
        final draft = find.byKey(const Key('screen04-create-draft-entry'));
        await tester.ensureVisible(draft);
        await tester.tap(draft);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('social-v2-create-workbench')),
          findsOneWidget,
        );
      }

      await tester.enterText(
        find.byKey(const Key('screen04-create-post-text')),
        'Keep this unfinished public draft.',
      );
      await leaveAndReturn();
      expect(find.text('Keep this unfinished public draft.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-create-tool-image')));
      await tester.pumpAndSettle();
      expect(find.text('New image post'), findsOneWidget);
      expect(find.byType(SocialMediaPreviewV2), findsOneWidget);
      await leaveAndReturn();
      expect(find.text('New image post'), findsOneWidget);
      expect(find.byType(SocialMediaPreviewV2), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-create-tool-carousel')));
      await tester.pumpAndSettle();
      expect(find.text('2 / 10 photos'), findsOneWidget);
      await leaveAndReturn();
      expect(find.text('New carousel'), findsOneWidget);
      expect(find.text('2 / 10 photos'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-create-tool-post')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('screen04-create-tool-image-poll')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('screen04-create-image-poll-choice-0')),
        'Blue basket',
      );
      await tester.tap(
        find.byKey(const Key('screen04-create-image-poll-media-0')),
      );
      await tester.pumpAndSettle();
      await leaveAndReturn();
      expect(find.text('New image poll'), findsOneWidget);
      expect(find.text('Blue basket'), findsOneWidget);
      expect(find.byType(SocialMediaPreviewV2), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('screen04-create-tool-quick-poll')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('screen04-create-quick-poll-choice-1')),
        'Tomorrow morning',
      );
      await leaveAndReturn();
      expect(find.text('New quick poll'), findsOneWidget);
      expect(find.text('Tomorrow morning'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-create-tool-quiz')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('screen04-create-quiz-choice-2')),
        'The correct answer',
      );
      await tester.tap(find.byType(Radio<int>).at(2));
      await tester.pump();
      await leaveAndReturn();
      expect(find.text('New quiz'), findsOneWidget);
      expect(find.text('The correct answer'), findsOneWidget);
      expect(
        tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>)).groupValue,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'posting-ready Create keeps YouTube Short one tap away at 140 percent',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final owners = _Owners();
      addTearDown(owners.dispose);
      var youtubeCalls = 0;
      await _pump(
        tester,
        SocialCreateWorkbenchV2(
          session: owners.shared,
          mediaPicker: owners.picker,
          authorName: 'Asha Sharma',
          authorHandle: '@ashasharma',
          allowReel: false,
          onCreateYouTubeShort: () => youtubeCalls += 1,
          onPublished: (_) {},
        ),
      );

      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(find.byKey(const Key('screen04-create-youtube-short')));
      await tester.pump();
      expect(youtubeCalls, 1);
      await tester.tap(find.byKey(const Key('screen04-create-tool-quiz')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-create-quiz-choice-3')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all five MoolSocial-hosted formats render as public content', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _seedAllFormats(owners.shared);

    for (final type in const [
      SocialPublishedContentType.carousel,
      SocialPublishedContentType.post,
      SocialPublishedContentType.imagePoll,
      SocialPublishedContentType.quickPoll,
      SocialPublishedContentType.quiz,
    ]) {
      final item = owners.shared.socialPublishedItems.firstWhere(
        (entry) => entry.type == type,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SocialPublishedContentCardV2(
                item: item,
                session: owners.shared,
                onReply: () {},
                onShare: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(Key('social-public-${type.name}-${item.id}')),
        findsOneWidget,
        reason: type.name,
      );
    }

    expect(tester.takeException(), isNull);
  });
}

Future<void> _seedAllFormats(SharedSession session) async {
  const image = 'assets/prototype/social-market-grocery.png';
  const choices = [
    SocialPublishedChoice(label: 'Morning'),
    SocialPublishedChoice(label: 'Evening'),
    SocialPublishedChoice(label: 'Afternoon'),
    SocialPublishedChoice(label: 'Night'),
  ];
  await session.publishSocialContent(
    type: SocialPublishedContentType.carousel,
    authorName: 'Asha Sharma',
    authorHandle: '@ashasharma',
    body: 'Market colours',
    mediaPaths: const [image, image],
    mediaAreAssets: true,
  );
  await session.publishSocialContent(
    type: SocialPublishedContentType.post,
    authorName: 'Asha Sharma',
    authorHandle: '@ashasharma',
    body: 'Fresh produce today',
  );
  await session.publishSocialContent(
    type: SocialPublishedContentType.imagePoll,
    authorName: 'Asha Sharma',
    authorHandle: '@ashasharma',
    body: 'Choose your basket',
    choices: const [
      SocialPublishedChoice(
        label: 'Family',
        imagePath: image,
        imageIsAsset: true,
      ),
      SocialPublishedChoice(
        label: 'Weekly',
        imagePath: image,
        imageIsAsset: true,
      ),
      SocialPublishedChoice(
        label: 'Fruit',
        imagePath: image,
        imageIsAsset: true,
      ),
      SocialPublishedChoice(
        label: 'Vegetables',
        imagePath: image,
        imageIsAsset: true,
      ),
    ],
  );
  await session.publishSocialContent(
    type: SocialPublishedContentType.quickPoll,
    authorName: 'Asha Sharma',
    authorHandle: '@ashasharma',
    body: 'Choose delivery time',
    choices: choices,
  );
  await session.publishSocialContent(
    type: SocialPublishedContentType.quiz,
    authorName: 'Asha Sharma',
    authorHandle: '@ashasharma',
    body: 'Choose the millet',
    choices: choices,
    correctChoiceIndex: 0,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: child,
    ),
  );
  await tester.pump();
}

class _Owners {
  _Owners({JourneySession? journey}) : journey = journey ?? JourneySession() {
    this.journey.emailAddress = 'asha.sharma@moolsocial.in';
    shared = SharedSession(
      gateway: _ImmediateSharedGateway(),
      socialContentGateway: socialGateway,
    );
    unawaited(draftCache.configureDurability(_PublicationDraftRepository()));
  }

  final JourneySession journey;
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final socialGateway = ReviewSocialContentGateway();
  late final SharedSession shared;
  final picker = _FakeSocialMediaPicker();
  final draftCache = SocialCreateDraftStateCache();

  SocialUniversalV2 consumer({
    String? sub,
    String? state,
    String? item,
    SocialV2ShareGateway? shareGateway,
  }) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    mediaPicker: picker,
    createDraftStateCache: draftCache,
    initialSubAction: sub,
    initialState: state,
    initialItem: item,
    shareGateway: shareGateway,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

class _RecordingShareGateway implements SocialV2ShareGateway {
  _RecordingShareGateway({required this.outcome});

  final SocialV2ShareOutcome outcome;
  int calls = 0;
  SocialV2ShareRequest? request;

  @override
  Future<SocialV2ShareOutcome> share(SocialV2ShareRequest value) async {
    calls += 1;
    request = value;
    return outcome;
  }
}

final class _PublicationDraftRepository implements SocialCreateDraftRepository {
  SocialCreateDraftSnapshot? snapshot;

  @override
  Future<SocialCreateDraftRead> read() async => SocialCreateDraftRead(
    freshness: snapshot == null
        ? SocialCreateDraftFreshness.missing
        : SocialCreateDraftFreshness.fresh,
    snapshot: snapshot,
  );

  @override
  Future<void> write(SocialCreateDraftSnapshot value) async {
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}

class _ImmediateSharedGateway extends ReviewSharedGateway {
  @override
  Future<void> execute(String actionId) async {}
}

class _DelayedSharedLinkGateway implements SocialContentGateway {
  final Completer<SocialFeedPage> _olderPage = Completer<SocialFeedPage>();
  int feedCalls = 0;

  void completeOlderPage() {
    _olderPage.complete(
      SocialFeedPage(
        items: [_item('older-shared-post', 'Older shared post')],
        nextCursor: 'newer-page',
      ),
    );
  }

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) {
    feedCalls += 1;
    return switch (feedCalls) {
      1 => Future.value(
        SocialFeedPage(
          items: [_item('latest-post', 'Latest public post')],
          nextCursor: 'older-page',
        ),
      ),
      2 => _olderPage.future,
      3 => Future.value(
        SocialFeedPage(
          items: [_item('newer-shared-post', 'Newer shared post')],
        ),
      ),
      _ => throw StateError('Unexpected Feed request $feedCalls'),
    };
  }

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      throw UnimplementedError();

  static SocialPublishedItem _item(String id, String body) =>
      SocialPublishedItem(
        id: id,
        authorId: 'author-$id',
        type: SocialPublishedContentType.post,
        authorName: 'Riya Sharma',
        authorHandle: '@riyasharma',
        body: body,
        audience: 'Public',
        publishedAt: DateTime.utc(2026, 8, 13),
        mediaPaths: const [],
        mediaAreAssets: false,
        choices: const [],
      );
}

class _CapturingSocialContentGateway implements SocialContentGateway {
  SocialPublishDraft? lastDraft;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: []);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) async {
    lastDraft = draft;
    return SocialPublishedItem(
      id: 'captured-publish',
      authorId: 'captured-author',
      type: draft.type,
      authorName: draft.authorName,
      authorHandle: draft.authorHandle,
      body: draft.body,
      audience: draft.audience,
      publishedAt: DateTime.utc(2026, 8, 13),
      mediaPaths: draft.mediaPaths,
      mediaAreAssets: draft.mediaAreAssets,
      choices: draft.choices,
      correctChoiceIndex: draft.correctChoiceIndex,
    );
  }
}

class _DelayedPublishSocialContentGateway implements SocialContentGateway {
  final Completer<SocialPublishedItem> _pending =
      Completer<SocialPublishedItem>();
  SocialPublishDraft? lastDraft;

  void completePublish() {
    final draft = lastDraft!;
    _pending.complete(
      SocialPublishedItem(
        id: 'delayed-publish',
        authorId: 'delayed-author',
        type: draft.type,
        authorName: draft.authorName,
        authorHandle: draft.authorHandle,
        body: draft.body,
        audience: draft.audience,
        publishedAt: DateTime.utc(2026, 8, 13),
        mediaPaths: draft.mediaPaths,
        mediaAreAssets: draft.mediaAreAssets,
        choices: draft.choices,
        correctChoiceIndex: draft.correctChoiceIndex,
      ),
    );
  }

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: []);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) {
    lastDraft = draft;
    return _pending.future;
  }
}

class _DelayedImagePicker implements SocialMediaPicker {
  final Completer<SocialPickedMedia?> _image = Completer<SocialPickedMedia?>();
  int imageCalls = 0;

  void completeImage() => _image.complete(_FakeSocialMediaPicker._image);

  @override
  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10}) async =>
      const [];

  @override
  Future<SocialPickedMedia?> pickImage(SocialMediaSource source) {
    imageCalls += 1;
    return _image.future;
  }

  @override
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source) async => null;

  @override
  Future<List<SocialPickedMedia>> recoverInterruptedSelection() async =>
      const [];
}

class _FakeSocialMediaPicker implements SocialMediaPicker {
  static const _image = SocialPickedMedia(
    path: 'assets/prototype/social-market-grocery.png',
    name: 'market.png',
    kind: SocialMediaKind.image,
    isAsset: true,
  );
  static const _reel = SocialPickedMedia(
    path: 'assets/prototype/social-market-grocery.png',
    name: 'market-reel.mp4',
    kind: SocialMediaKind.video,
    isAsset: true,
  );

  @override
  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10}) async =>
      const [_image, _image];

  @override
  Future<SocialPickedMedia?> pickImage(SocialMediaSource source) async =>
      _image;

  @override
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source) async => _reel;

  @override
  Future<List<SocialPickedMedia>> recoverInterruptedSelection() async =>
      const [];
}

class _FailingSocialMediaPicker implements SocialMediaPicker {
  @override
  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10}) =>
      Future.error(StateError('private native picker failure'));

  @override
  Future<SocialPickedMedia?> pickImage(SocialMediaSource source) =>
      Future.error(StateError('private native picker failure'));

  @override
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source) =>
      Future.error(StateError('private native picker failure'));

  @override
  Future<List<SocialPickedMedia>> recoverInterruptedSelection() async =>
      const [];
}
