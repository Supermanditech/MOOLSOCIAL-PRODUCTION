import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/social_create_draft_repository.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  late SocialCreateDraftStateCache draftState;
  JourneySession signedInSession() => JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );

  Future<void> pumpApp(
    WidgetTester tester,
    JourneySession journey,
    String location,
  ) async {
    draftState = SocialCreateDraftStateCache();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        createDraftStateCache: draftState,
        session: journey,
        initialLocation: location,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollToClearBottomAndTap(
    WidgetTester tester,
    Finder finder,
  ) async {
    final verticalScrollable = find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: verticalScrollable.last,
    );
    await tester.pumpAndSettle();
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final rect = tester.getRect(finder);
    final clearBottom = viewportHeight - 132;
    if (rect.bottom > clearBottom) {
      await tester.drag(
        verticalScrollable.last,
        Offset(0, -(rect.bottom - clearBottom + 16)),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('C03 removes every Social-hosted Mool main-action mode', () {
    final contract =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/'
                  'mvp-personal-global-mool-bottom-rail-navigation-fix1.json',
                ),
              ).readAsStringSync(),
            )
            as Map;
    final rules = contract['rules'] as Map;
    expect(rules['moolIsStableHub'], isTrue);
    expect(rules['moolMayAliasSocial'], isFalse);
    expect(rules['moolMayToggleMainActionRibbon'], isFalse);

    final socialSource = File.fromUri(
      Directory.current.uri.resolve('lib/ui_v2/social/social_v2_consumer.dart'),
    ).readAsStringSync();
    final railSource = File.fromUri(
      Directory.current.uri.resolve(
        'lib/ui_v2/social/screen04_universal_components.dart',
      ),
    ).readAsStringSync();
    for (final forbidden in const [
      'initialMoolOpen',
      '_moolOpen',
      'moolOpen',
      'onWorld',
      'screen04-world-ribbon',
    ]) {
      expect('$socialSource\n$railSource', isNot(contains(forbidden)));
    }
  });

  for (final subAction in const ['shorts', 'videos', 'feed', 'create']) {
    testWidgets('Social $subAction menu Back preserves its current owner', (
      tester,
    ) async {
      final journey = signedInSession();
      addTearDown(journey.dispose);
      await journey.start();
      await pumpApp(tester, journey, '/app/social?sub=$subAction');
      if (subAction == 'create') await _bindNavigationDraft(draftState);

      if (subAction == 'create') {
        expect(
          find.byKey(const ValueKey('social-creator-gateway')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('social-creator-gateway')),
          findsNothing,
        );
      }
      final retainedSubAction = subAction == 'create' ? 'feed' : subAction;
      final selected = find.byKey(Key('screen04-rail-$retainedSubAction'));
      expect(
        tester.getSemantics(selected).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      for (final mainAction in const [
        'social',
        'buy',
        'eat',
        'ride',
        'book',
        'work',
      ]) {
        expect(find.byKey(Key('screen04-rail-$mainAction')), findsNothing);
      }

      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsNothing,
      );
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        tester.getSemantics(selected).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      if (subAction == 'create') {
        await tester.tap(find.byKey(const Key('screen04-rail-create')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('social-creator-gateway')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in [
    ('state', 'home'),
    ('mode', 'home'),
    ('state', ''),
    ('state', 'unrecognized'),
  ]) {
    final legacyParameter = entry.$1;
    final legacyState = entry.$2;
    testWidgets(
      'Create legacy $legacyParameter $legacyState preserves failed draft and returns Feed after retry',
      (tester) async {
        final journey = signedInSession();
        addTearDown(journey.dispose);
        await journey.start();
        await pumpApp(
          tester,
          journey,
          '/app/social?sub=create&$legacyParameter=$legacyState',
        );
        final drafts = await _bindNavigationDraft(draftState);
        final composer = find.byKey(const ValueKey('social-creator-gateway'));
        final field = find.byKey(const Key('screen04-create-post-text'));
        await tester.enterText(field, 'Keep my $legacyParameter draft');
        drafts.failWrites = true;
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(composer, findsOneWidget);
        expect(
          tester.widget<TextField>(field).controller!.text,
          'Keep my $legacyParameter draft',
        );
        expect(find.byKey(const Key('buy-v2-screen')), findsNothing);
        drafts.failWrites = false;
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(composer, findsNothing);
        expect(drafts.snapshot?.body, 'Keep my $legacyParameter draft');
        expect(
          tester
              .getSemantics(find.byKey(const Key('screen04-rail-feed')))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('active Social video closes before connected-menu Back', (
    tester,
  ) async {
    final journey = signedInSession();
    final creator = CreatorSession();
    final retailer = RetailerSession();
    final shared = SharedSession();
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await journey.start();
    draftState = SocialCreateDraftStateCache();
    final publicVideo = Screen04YouTubePublicVideo(
      videoId: 'video123456',
      title: 'Navigation lifecycle fixture',
      channelId: 'UCNEWS1',
      channelTitle: 'Public News',
      description: 'Controlled navigation fixture.',
      thumbnailUrl: Uri.parse(
        'https://i.ytimg.com/vi/video123456/hqdefault.jpg',
      ),
      publishedAt: DateTime.utc(2026, 8, 11),
      duration: 'PT5M',
      captionAvailable: true,
      viewCount: '1000',
      likeCount: '100',
      commentCount: '10',
      embeddable: true,
      hasKnownDeviceRegionExclusion: false,
      hashtags: const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SocialUniversalV2(
          createDraftStateCache: draftState,
          session: journey,
          creatorSession: creator,
          retailerSession: retailer,
          sharedSession: shared,
          initialSubAction: 'videos',
          youtubePublicAccessOverride: true,
          youtubeVideosLoader: () async => [publicVideo],
          youtubeShortsLoader: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final navigator = Navigator.of(
      tester.element(find.byKey(const Key('screen04-universal-v2'))),
    );

    final video = find.text('Navigation lifecycle fixture');
    await scrollToClearBottomAndTap(tester, video);
    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(navigator.canPop(), isFalse);
    expect(
      tester
          .widget<PopScope<Object?>>(
            find.ancestor(
              of: find.byKey(const Key('screen04-universal-v2')),
              matching: find.byType(PopScope<Object?>),
            ),
          )
          .canPop,
      isTrue,
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('screen04-rail-videos')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(navigator.canPop(), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final ownerAfterSystemBack = <String, Object>{
      'socialOwners': find
          .byKey(const Key('screen04-universal-v2'))
          .evaluate()
          .length,
      'moolOwners': find
          .byKey(const Key('personal-mool-root-v2'))
          .evaluate()
          .length,
      'canPop': navigator.canPop(),
    };
    expect(ownerAfterSystemBack, <String, Object>{
      'socialOwners': 1,
      'moolOwners': 0,
      'canPop': false,
    });
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(
      tester
          .getSemantics(find.byKey(const Key('screen04-rail-videos')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('Legacy Home Social menu Back Back returns to Buy', (
    tester,
  ) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    await journey.start();
    await pumpApp(tester, journey, '/app/mool');

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mool-navigator-family-social')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
  });
}

Future<_NavigationDraftRepository> _bindNavigationDraft(
  SocialCreateDraftStateCache cache,
) async {
  final repository = _NavigationDraftRepository();
  final binding = cache.beginPrincipalBindingAttempt();
  await cache.configureDurability(repository, bindingAttempt: binding);
  addTearDown(() {
    cache.beginPrincipalBindingAttempt();
  });
  return repository;
}

final class _NavigationDraftRepository implements SocialCreateDraftRepository {
  SocialCreateDraftSnapshot? snapshot;
  bool failWrites = false;
  @override
  Future<SocialCreateDraftRead> read() async => SocialCreateDraftRead(
    freshness: snapshot == null
        ? SocialCreateDraftFreshness.missing
        : SocialCreateDraftFreshness.fresh,
    snapshot: snapshot,
  );
  @override
  Future<void> write(SocialCreateDraftSnapshot value) async {
    if (failWrites) throw StateError('Controlled draft write failure');
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}
