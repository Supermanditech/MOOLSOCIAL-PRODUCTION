import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_services.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/social_media_picker.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_public_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'SharedSession publishes and owns every approved public format',
    () async {
      final session = SharedSession();
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
        isNotNull,
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
          ],
          correctChoiceIndex: 0,
        ),
        isNotNull,
      );

      expect(
        session.socialPublishedItems.map((item) => item.type).toSet(),
        SocialPublishedContentType.values.toSet(),
      );
      expect(session.latestPublishedReel?.body, 'Morning market walk');
      final quiz = session.socialPublishedItems.first;
      expect(quiz.type, SocialPublishedContentType.quiz);
      expect(session.voteOnSocialContent(quiz.id, 0), isTrue);
      expect(session.socialPublishedItems.first.selectedChoiceIndex, 0);
    },
  );

  testWidgets('Create publishes entered Post copy into the public Feed', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, owners.consumer(sub: 'create'));

    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'Jodhpur makers meet this Saturday.',
    );
    await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
    await tester.pumpAndSettle();

    expect(find.text('Jodhpur makers meet this Saturday.'), findsOneWidget);
    expect(
      find.byKey(const Key('social-public-post-MS-SOCIAL-0001')),
      findsOneWidget,
    );
    expect(
      owners.shared.socialPublishedItems.single.body,
      'Jodhpur makers meet this Saturday.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create keeps every approved action in one direct workbench', (
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
      'screen04-create-tool-reel',
      'screen04-create-tool-quiz',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('screen04-create-tool-image')));
    await tester.pumpAndSettle();
    expect(workbench, findsOneWidget);
    expect(find.text('market.png'), findsNothing);

    await tester.tap(find.byKey(const Key('screen04-create-tool-carousel')));
    await tester.pumpAndSettle();
    expect(workbench, findsOneWidget);
    expect(find.text('2 / 10 photos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-create-tool-reel')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-reel-camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-create-reel-gallery')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('screen04-create-reel-camera')));
    await tester.pumpAndSettle();
    expect(find.text('market-reel.mp4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-create-tool-post')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-post-text')), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-create-tool-image-poll')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-image-poll-choice-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('screen04-create-tool-quick-poll')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-quick-poll-choice-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('screen04-create-tool-quiz')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-quiz-choice-0')),
      findsOneWidget,
    );
    expect(find.byType(Navigator), findsOneWidget);
    expect(workbench, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all six session-owned formats render as public content', (
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

    final reel = owners.shared.latestPublishedReel!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialPublishedReelV2(
            item: reel,
            session: owners.shared,
            onComment: () {},
            onShare: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(Key('social-public-reel-${reel.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _seedAllFormats(SharedSession session) async {
  const image = 'assets/prototype/social-market-grocery.png';
  const choices = [
    SocialPublishedChoice(label: 'Morning'),
    SocialPublishedChoice(label: 'Evening'),
  ];
  await session.publishSocialContent(
    type: SocialPublishedContentType.reel,
    authorName: 'Asha Sharma',
    authorHandle: '@ashasharma',
    body: 'Morning market walk',
    mediaPaths: const [image],
    mediaAreAssets: true,
  );
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
  _Owners() {
    journey.emailAddress = 'asha.sharma@moolsocial.in';
  }

  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession(gateway: _ImmediateSharedGateway());
  final picker = _FakeSocialMediaPicker();

  SocialUniversalV2 consumer({String? sub}) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    mediaPicker: picker,
    initialSubAction: sub,
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
