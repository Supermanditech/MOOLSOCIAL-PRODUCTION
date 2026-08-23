import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_uploader.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_creator.dart';
import 'package:moolsocial/ui_v2/social/social_v2_plans_promotion.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_connect.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_creator_upload.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

final _forbiddenSocialCopy = RegExp(
  r'\b(?:production|prototype|founder review|review build|sample|example|demo|'
  r'mock|placeholder|working note|internal plan|implementation|workflow|'
  r'state machine|endpoint|payload|backend|provider callback|next screen|'
  r'for (?:review|testing)|gated|oauth|firebase-authenticated|upload scope|'
  r'upload lifecycle|provider capability|creator capability|'
  r'authorization requirements|will not simulate|reply persistence|'
  r'processed and embeddable|eligible (?:shorts|videos)|20-item target|'
  r'no filler|app build)\b|dharmendra|@dharmendra',
  caseSensitive: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Social public catalogue and Create recovery copy stay ready', (
    tester,
  ) async {
    final journey = JourneySession();
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final shared = SharedSession();
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);

    Future<void> audit({
      required String sub,
      bool publicAccess = false,
      Future<List<Screen04YouTubePublicVideo>> Function()? videos,
      Future<List<Screen04YouTubePublicVideo>> Function()? shorts,
    }) async {
      await _mount(
        tester,
        SocialUniversalV2(
          session: journey,
          creatorSession: creator,
          retailerSession: retailer,
          sharedSession: shared,
          initialSubAction: sub,
          youtubePublicAccessOverride: publicAccess,
          youtubeVideosLoader: videos,
          youtubeShortsLoader: shorts,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      _expectCustomerCopy(tester, 'Social $sub');
    }

    await audit(sub: 'create');
    expect(find.byKey(const Key('social-creator-gateway')), findsOneWidget);
    await tester.tap(find.byKey(const Key('social-create-moolsocial-post')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsOneWidget,
    );
    _expectCustomerCopy(tester, 'Social Create workbench');

    for (final sub in const ['shorts', 'videos']) {
      await audit(
        sub: sub,
        publicAccess: true,
        videos: () async => const [],
        shorts: () async => const [],
      );
    }
    await audit(
      sub: 'shorts',
      publicAccess: true,
      videos: () async => const [],
      shorts: () async => throw StateError('offline'),
    );
    await audit(
      sub: 'videos',
      publicAccess: true,
      videos: () async => throw StateError('offline'),
      shorts: () async => const [],
    );

    final pendingVideos = Completer<List<Screen04YouTubePublicVideo>>();
    final pendingShorts = Completer<List<Screen04YouTubePublicVideo>>();
    await audit(
      sub: 'shorts',
      publicAccess: true,
      videos: () => pendingVideos.future,
      shorts: () => pendingShorts.future,
    );
    pendingVideos.complete(const []);
    pendingShorts.complete(const []);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets(
    'Social consumer and every Creator owner use customer-ready copy',
    (tester) async {
      final journey = JourneySession();
      final creator = CreatorSession()..creatorWorkspaceActive = true;
      final retailer = RetailerSession();
      final shared = SharedSession();
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);

      await _mount(
        tester,
        SocialUniversalV2(
          session: journey,
          creatorSession: creator,
          retailerSession: retailer,
          sharedSession: shared,
        ),
      );
      _expectCustomerCopy(tester, 'Social Shorts');

      for (final tab in const ['videos', 'feed', 'create']) {
        await _mount(
          tester,
          SocialUniversalV2(
            key: ValueKey('social-copy-$tab'),
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
            initialSubAction: tab,
          ),
        );
        _expectCustomerCopy(tester, 'Social $tab');
      }

      for (final state in const ['loading', 'error', 'unavailable']) {
        await _mount(
          tester,
          SocialUniversalV2(
            key: ValueKey('social-feed-copy-$state'),
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
            initialSubAction: 'feed',
            initialState: state,
          ),
        );
        _expectCustomerCopy(tester, 'Social Feed $state');
      }

      await _mount(
        tester,
        SocialUniversalV2(
          session: journey,
          creatorSession: creator,
          retailerSession: retailer,
          sharedSession: shared,
          initialSubAction: 'videos',
          initialState: 'video-watch',
        ),
      );
      _expectCustomerCopy(tester, 'YouTube video detail');
      _expectNoMisleadingYouTubeMutationCopy(tester, 'YouTube video detail');

      for (final state in const <String>[
        'post',
        'reel-source',
        'reel-camera',
        'reel-edit',
        'carousel',
        'drafts',
        'publishing',
        'failure',
        'success',
      ]) {
        await _mount(
          tester,
          SocialUniversalV2(
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
            initialSubAction: 'create',
            initialState: state,
          ),
        );
        _expectCustomerCopy(tester, 'Social Create $state');
      }

      for (final owner in CreatorSocialV2Owner.values) {
        await _mount(
          tester,
          CreatorSocialV2Screen(session: creator, owner: owner),
        );
        _expectCustomerCopy(tester, 'Creator ${owner.name}');
      }

      for (final state in const <String>[
        'destinations',
        'preview',
        'publishing',
        'partial',
        'success',
      ]) {
        await _mount(
          tester,
          CreatorSocialV2Screen(
            session: creator,
            owner: CreatorSocialV2Owner.publish,
            initialState: state,
          ),
        );
        _expectCustomerCopy(tester, 'Creator publish $state');
      }

      final inactive = CreatorSession();
      addTearDown(inactive.dispose);
      await _mount(
        tester,
        CreatorSocialV2Screen(
          session: inactive,
          owner: CreatorSocialV2Owner.home,
          initialState: 'activate',
        ),
      );
      _expectCustomerCopy(tester, 'Creator activation');
    },
  );

  testWidgets('YouTube Connect copy stays customer-ready through every step', (
    tester,
  ) async {
    final session = CreatorSession()..creatorWorkspaceActive = true;
    addTearDown(session.dispose);
    await _mount(tester, SocialYouTubeConnectV2Screen(session: session));
    _expectCustomerCopy(tester, 'YouTube source');
    _expectNoReviewerFacingYouTubeCopy(tester, 'YouTube source');

    session.setYouTubeUrl('https://youtube.com/watch?v=moolsocial');
    expect(await tester.runAsync(session.validateYouTubeSource), isTrue);
    expect(session.continueToYouTubeAction(), isTrue);
    await tester.pump();
    _expectCustomerCopy(tester, 'YouTube action');
    _expectNoReviewerFacingYouTubeCopy(tester, 'YouTube action');

    session
      ..selectYouTubeAction('buy')
      ..confirmYouTubeRights(true)
      ..confirmYouTubeActionTruth(true);
    expect(session.continueToYouTubeReview(), isTrue);
    await tester.pump();
    _expectCustomerCopy(tester, 'YouTube check');
    _expectNoReviewerFacingYouTubeCopy(tester, 'YouTube check');

    expect(await tester.runAsync(session.publishYouTubeConnection), isTrue);
    await tester.pump();
    _expectCustomerCopy(tester, 'YouTube complete');
    _expectNoReviewerFacingYouTubeCopy(tester, 'YouTube complete');
  });

  testWidgets(
    'YouTube creator connection and upload copy never exposes implementation commentary',
    (tester) async {
      final disconnected = _CopyCreatorGateway(
        connection: const YouTubeDisconnected(),
      );
      await _mount(
        tester,
        SocialYouTubeCreatorUploadScreen(gateway: disconnected),
      );
      await tester.pumpAndSettle();
      _expectCustomerCopy(tester, 'YouTube creator disconnected');
      _expectNoCreatorImplementationCopy(
        tester,
        'YouTube creator disconnected',
      );

      final connected = _CopyCreatorGateway(
        connection: YouTubeConnected(
          channelId: 'UCabcdefghijklmnopqrstuv',
          channelTitle: 'MoolSocial News',
          grantedScopes: const [
            'https://www.googleapis.com/auth/youtube.upload',
          ],
          lastVerifiedAt: DateTime.utc(2026, 8, 11),
          nextVerificationDueAt: DateTime.utc(2026, 9, 10),
        ),
      );
      await _mount(
        tester,
        SocialYouTubeCreatorUploadScreen(gateway: connected),
      );
      await tester.pumpAndSettle();
      _expectCustomerCopy(tester, 'YouTube creator connected');
      _expectNoCreatorImplementationCopy(tester, 'YouTube creator connected');
    },
  );

  testWidgets('plans and Social promotion use customer-ready copy', (
    tester,
  ) async {
    final journey = JourneySession();
    final creator = CreatorSession()..creatorWorkspaceActive = true;
    final retailer = RetailerSession();
    final shared = SharedSession();
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);

    await _mount(
      tester,
      SocialPlansV2Screen(
        sharedSession: shared,
        retailerSession: retailer,
        creatorSession: creator,
      ),
    );
    _expectCustomerCopy(tester, 'Plans');

    await _mount(tester, SocialPromotionV2Screen(session: retailer));
    _expectCustomerCopy(tester, 'Social promotion');
    for (final state in const <(int?, String?)>[
      (2, null),
      (3, null),
      (4, null),
      (5, null),
      (null, 'failure'),
      (null, 'live'),
    ]) {
      await _mount(
        tester,
        SocialPromotionV2Screen(
          session: retailer,
          initialStep: state.$1,
          initialState: state.$2,
        ),
      );
      _expectCustomerCopy(tester, 'Social promotion $state');
    }
  });
}

void _expectNoMisleadingYouTubeMutationCopy(WidgetTester tester, String state) {
  final forbidden = RegExp(
    r'\bSubscribe\b|like,\s*comment\s*or\s*subscribe|'
    r'Connect YouTube viewing actions',
    caseSensitive: false,
  );
  final visibleCopy = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
      .where((text) => text.trim().isNotEmpty)
      .toList(growable: false);
  expect(
    visibleCopy.where(forbidden.hasMatch),
    isEmpty,
    reason: '$state implied unavailable YouTube mutations: $visibleCopy',
  );
}

void _expectNoReviewerFacingYouTubeCopy(WidgetTester tester, String state) {
  final forbidden = RegExp(
    r'\b(?:embedding|attribution|API|quota|endpoint|validated|validation|'
    r'outside (?:the )?player|Mool action|connected post)\b',
    caseSensitive: false,
  );
  final visibleCopy = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
      .where((text) => text.trim().isNotEmpty)
      .toList(growable: false);
  expect(
    visibleCopy.where(forbidden.hasMatch),
    isEmpty,
    reason: '$state exposed reviewer-facing language: $visibleCopy',
  );
}

void _expectNoCreatorImplementationCopy(WidgetTester tester, String state) {
  final forbidden = RegExp(
    r'\b(?:GATED|OAuth|Firebase|API|scope|endpoint|provider capability|'
    r'authorization requirements|upload lifecycle|simulate|private Dev|'
    r'proof harness)\b',
    caseSensitive: false,
  );
  final visibleCopy = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
      .where((text) => text.trim().isNotEmpty)
      .toList(growable: false);
  expect(
    visibleCopy.where(forbidden.hasMatch),
    isEmpty,
    reason: '$state exposed implementation commentary: $visibleCopy',
  );
}

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
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

void _expectCustomerCopy(WidgetTester tester, String owner) {
  final copy = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    copy.add(text.data ?? text.textSpan?.toPlainText() ?? '');
  }
  for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
    final decoration = field.decoration;
    copy.addAll([
      decoration?.labelText ?? '',
      decoration?.hintText ?? '',
      decoration?.helperText ?? '',
      decoration?.prefixText ?? '',
      decoration?.suffixText ?? '',
    ]);
  }
  for (final semantics in tester.widgetList<Semantics>(
    find.byType(Semantics),
  )) {
    copy.add(semantics.properties.label ?? '');
    copy.add(semantics.properties.hint ?? '');
  }
  final visible = copy.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final match = _forbiddenSocialCopy.firstMatch(visible);
  expect(
    match,
    isNull,
    reason:
        'Forbidden customer-facing wording "${match?.group(0)}" found in $owner. Visible copy: $visible',
  );
  expect(tester.takeException(), isNull, reason: owner);
}

class _CopyCreatorGateway implements SocialYouTubeCreatorGateway {
  _CopyCreatorGateway({required this.connection});

  final YouTubeConnectionStatus connection;

  @override
  Future<YouTubePrivateDevCapabilities> capabilities() async {
    return const YouTubePrivateDevCapabilities(
      environment: 'Dev',
      publicData: true,
      ownerConnect: true,
      privateUpload: true,
      ownerAnalytics: false,
      publicOrUnlistedUpload: false,
    );
  }

  @override
  Future<YouTubeConnectionStatus> connectionStatus() async => connection;

  @override
  Future<void> beginChannelConnection({
    required YouTubeConnectPurpose purpose,
  }) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<YouTubeVideoSummary> uploadPrivateShort({
    required String idempotencyKey,
    required String path,
    required String contentType,
    required YouTubePrivateUploadMetadata metadata,
    required YouTubeUploadProgress onProgress,
    required YouTubeUploadCancellation cancellation,
  }) {
    throw UnimplementedError();
  }

  @override
  void dispose() {}
}
