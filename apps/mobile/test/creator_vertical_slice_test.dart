import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/creator/creator_models.dart';
import 'package:moolsocial/features/creator/creator_services.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  Future<CreatorSession> mount(
    WidgetTester tester, {
    required String route,
    CreatorSession? creatorSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
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
    final creator = creatorSession ?? CreatorSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      creator.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        creatorSession: creator,
        initialLocation: route,
      ),
    );
    await settle(tester);
    return creator;
  }

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      for (final state
          in scrollables
              .evaluate()
              .whereType<StatefulElement>()
              .map((element) => element.state)
              .whereType<ScrollableState>()) {
        if (state.position.maxScrollExtent <= state.position.minScrollExtent) {
          continue;
        }
        state.position.jumpTo(state.position.minScrollExtent);
        await tester.pump();
        for (
          var attempt = 0;
          attempt < 50 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 260).clamp(
              state.position.minScrollExtent,
              state.position.maxScrollExtent,
            ),
          );
          await tester.pump();
        }
        if (finder.evaluate().isNotEmpty) break;
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await settle(tester);
    return finder;
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await settle(tester);
  }

  Future<void> go(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await settle(tester);
  }

  String location(WidgetTester tester) => GoRouterState.of(
    tester.element(find.byType(Scaffold).first),
  ).uri.toString();

  Future<void> chooseDropdown(
    WidgetTester tester, {
    required Key key,
    required String label,
  }) async {
    await tester.tap(await reveal(tester, key));
    await settle(tester);
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  testWidgets('screen 124 opens every Creator Studio owner route', (
    tester,
  ) async {
    await mount(tester, route: '/app/creator');
    expect(find.byKey(const Key('creator-studio-home-screen')), findsOneWidget);
    await tap(tester, const Key('creator-studio-controls'));
    expect(
      find.byKey(const Key('creator-studio-controls-sheet')),
      findsOneWidget,
    );
    await tap(tester, const Key('creator-controls-close'));
    await tap(tester, const Key('creator-studio-controls'));
    await tap(tester, const Key('creator-controls-open'));
    expect(location(tester), '/app/creator/control');

    final routeOwners = <Key, String>{
      const Key('creator-home-publish'): '/app/creator/publish',
      const Key('creator-home-library'): '/app/creator/content',
      const Key('creator-home-campaigns'): '/app/creator/campaigns',
      const Key('creator-home-audience'): '/app/creator/audience',
      const Key('creator-priority-campaign'):
          '/app/creator/publish?campaign=CR-2048',
      const Key('creator-priority-ready'): '/app/creator/content?tab=drafts',
      const Key('creator-priority-earnings'): '/app/creator/earnings',
      const Key('creator-home-performance'): '/app/creator/performance',
      const Key('creator-dock-create'): '/app/creator/publish',
      const Key('creator-dock-studio'): '/app/creator',
      const Key('creator-dock-earnings'): '/app/creator/earnings',
    };
    for (final entry in routeOwners.entries) {
      await go(tester, '/app/creator');
      await tap(tester, entry.key);
      expect(location(tester), entry.value);
    }
  });

  testWidgets(
    'screen 125 business-funded Reel validates duration and exactly retries draft and publish',
    (tester) async {
      final gateway = ReviewCreatorGateway()
        ..failDraft = true
        ..failPostPublish = true;
      final session = CreatorSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/creator/publish?campaign=CR-2048',
        creatorSession: session,
      );
      expect(find.byKey(const Key('creator-publish-screen')), findsOneWidget);
      expect(session.publishFormat, CreatorPublishFormat.reel);
      await tap(tester, const Key('creator-media-camera'));
      await enter(tester, const Key('creator-post-title'), 'Fresh basket Reel');
      await enter(
        tester,
        const Key('creator-post-caption'),
        'See how a verified shop packs the morning basket.',
      );
      await tap(tester, const Key('creator-reel-days-7'));
      expect(session.reelDurationDays, 7);

      await tap(tester, const Key('creator-save-draft'));
      expect(session.draftId, isNull);
      await tap(tester, const Key('creator-save-draft'));
      expect(session.draftId, 'CR-DRAFT-125-0719');
      expect(gateway.draftCalls, 2);
      await tap(tester, const Key('creator-save-draft'));
      expect(gateway.draftCalls, 2);

      await tap(tester, const Key('creator-review-publish'));
      await tap(tester, const Key('creator-publish-confirm'));
      expect(gateway.postPublishCalls, 0);
      await tap(tester, const Key('creator-publish-close'));
      await tap(tester, const Key('creator-reel-funding-terms'));
      await tap(tester, const Key('creator-rights-confirm'));
      await tap(tester, const Key('creator-review-publish'));
      await tap(tester, const Key('creator-publish-confirm'));
      expect(session.publishedPostId, isNull);
      await tap(tester, const Key('creator-publish-confirm'));
      expect(session.publishedPostId, 'REEL-125-0719');
      expect(gateway.postPublishCalls, 2);
      await tap(tester, const Key('creator-publish-confirm'));
      expect(gateway.postPublishCalls, 2);
      await tap(tester, const Key('creator-publish-view-library'));
      expect(location(tester), '/app/creator/content');
    },
  );

  testWidgets(
    'screen 125 keeps YouTube, text and image creation paths explicit',
    (tester) async {
      final session = await mount(tester, route: '/app/creator/publish');
      await tap(tester, const Key('creator-format-youtube'));
      expect(session.publishFormat, CreatorPublishFormat.youtube);
      await tap(tester, const Key('creator-youtube-start'));
      expect(location(tester), '/app/creator/youtube-connect');
      await go(tester, '/app/creator/publish');
      await tap(tester, const Key('creator-format-text'));
      expect(session.publishFormat, CreatorPublishFormat.text);
      expect(find.byKey(const Key('creator-media-picker')), findsNothing);
      await tap(tester, const Key('creator-format-image'));
      expect(session.publishFormat, CreatorPublishFormat.image);
      expect(find.byKey(const Key('creator-media-picker')), findsOneWidget);
      await tap(tester, const Key('creator-media-gallery'));
      await tap(tester, const Key('creator-media-remove'));
      expect(session.mediaSelected, isFalse);
      await tap(tester, const Key('creator-open-drafts'));
      expect(location(tester), '/app/creator/content?tab=drafts');
    },
  );

  testWidgets(
    'screen 166 validates YouTube source and exactly retries one connected post',
    (tester) async {
      final gateway = ReviewCreatorGateway()
        ..failYouTubeValidation = true
        ..failYouTubePublish = true;
      final session = CreatorSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/creator/youtube-connect',
        creatorSession: session,
      );
      expect(find.byKey(const Key('youtube-source-step')), findsOneWidget);
      await tap(tester, const Key('youtube-connect-help'));
      await tap(tester, const Key('youtube-help-close'));
      await tap(tester, const Key('youtube-connect-channel'));
      await tap(tester, const Key('youtube-channel-cancel'));
      expect(session.youtubeChannelConnected, isFalse);
      await tap(tester, const Key('youtube-connect-channel'));
      await tap(tester, const Key('youtube-channel-confirm'));
      expect(session.youtubeChannelConnected, isTrue);
      await enter(
        tester,
        const Key('youtube-url'),
        'https://youtube.com/watch?v=LOCAL123',
      );
      await tap(tester, const Key('youtube-validate'));
      expect(session.youtubeValidationId, isNull);
      await tap(tester, const Key('youtube-validate'));
      expect(session.youtubeValidationId, 'YT-VALID-166-0719');
      expect(gateway.youtubeValidationCalls, 2);
      await tap(tester, const Key('youtube-source-continue'));
      expect(find.byKey(const Key('youtube-action-step')), findsOneWidget);
      await tap(tester, const Key('youtube-action-preview'));
      expect(session.youtubeStep, YouTubeConnectStep.action);
      await tap(tester, const Key('youtube-action-buy'));
      await chooseDropdown(
        tester,
        key: const Key('youtube-campaign'),
        label: 'Funded Campaign Reel · CR-2048',
      );
      await tap(tester, const Key('youtube-days-7'));
      await tap(tester, const Key('youtube-rights'));
      await tap(tester, const Key('youtube-action-truth'));
      await tap(tester, const Key('youtube-action-preview'));
      expect(find.byKey(const Key('youtube-review-step')), findsOneWidget);
      await tap(tester, const Key('youtube-publish'));
      expect(session.youtubeConnectedPostId, isNull);
      await tap(tester, const Key('youtube-publish'));
      expect(session.youtubeConnectedPostId, 'YT-POST-166-0719');
      expect(gateway.youtubePublishCalls, 2);
      await tap(tester, const Key('youtube-view-connected'));
      expect(location(tester), '/app/creator/content');
    },
  );

  testWidgets(
    'screen 126 covers every content state, empty recovery and owned next action',
    (tester) async {
      final session = await mount(tester, route: '/app/creator/content');
      expect(
        find.byKey(const Key('creator-content-library-screen')),
        findsOneWidget,
      );
      await tap(tester, const Key('creator-content-filter'));
      await tap(tester, const Key('creator-content-filter-drafts'));
      expect(session.contentTab, CreatorContentTab.drafts);
      for (final item in reviewCreatorContent) {
        final tab = switch (item.status) {
          'Draft' => CreatorContentTab.drafts,
          'Scheduled' => CreatorContentTab.scheduled,
          'Unavailable' => CreatorContentTab.unavailable,
          _ => CreatorContentTab.published,
        };
        await tap(tester, Key('creator-content-tab-${tab.name}'));
        await tap(tester, Key('creator-content-${item.id}'));
        expect(session.selectedContentId, item.id);
        await tap(tester, const Key('creator-content-detail-close'));
      }
      await enter(
        tester,
        const Key('creator-content-search'),
        'no matching creator content',
      );
      expect(find.byKey(const Key('creator-content-empty')), findsOneWidget);
      await tap(tester, const Key('creator-content-clear'));
      expect(session.contentQuery, isEmpty);

      await tap(tester, const Key('creator-content-tab-published'));
      await tap(tester, const Key('creator-content-CNT-126-LOCAL-BASKET'));
      await tap(tester, const Key('creator-content-primary-action'));
      expect(location(tester), '/app/creator/performance');
      await go(tester, '/app/creator/content?tab=unavailable');
      await tap(tester, const Key('creator-content-CNT-126-UNAVAILABLE'));
      await tap(tester, const Key('creator-content-primary-action'));
      expect(location(tester), '/app/creator/youtube-connect');
    },
  );

  testWidgets(
    'screens 127 and 128 cover performance, export, audience, sharing and community routes',
    (tester) async {
      final session = await mount(tester, route: '/app/creator/performance');
      for (final window in CreatorPerformanceWindow.values) {
        await tap(tester, Key('creator-performance-window-${window.name}'));
        expect(session.performanceWindow, window);
      }
      await tester.tap(find.text('Campaign'));
      await settle(tester);
      expect(session.performanceView, CreatorPerformanceView.campaigns);
      await tap(tester, const Key('creator-performance-top-content'));
      await tap(tester, const Key('creator-performance-detail-close'));
      await tap(tester, const Key('creator-performance-export'));
      await tap(tester, const Key('creator-export-csv'));
      expect(session.exportId, 'CR-EXPORT-127-CSV');
      await tap(tester, const Key('creator-export-pdf'));
      expect(session.exportId, 'CR-EXPORT-127-PDF');
      await tap(tester, const Key('creator-export-close'));

      await go(tester, '/app/creator/audience');
      expect(find.byKey(const Key('creator-audience-screen')), findsOneWidget);
      await tap(tester, const Key('creator-audience-invite'));
      await tap(tester, const Key('creator-audience-share-close'));
      await tap(tester, const Key('creator-audience-share'));
      await tap(tester, const Key('creator-audience-share-confirm'));
      expect(session.noticeMessage, contains('No contacts'));
      await tap(tester, const Key('creator-audience-memberships'));
      expect(location(tester), '/app/creator/audience?tab=memberships');
      await go(tester, '/app/creator/audience');
      await tap(tester, const Key('creator-audience-ask'));
      expect(location(tester), '/app/social?sub=create');
      await go(tester, '/app/creator/audience');
      await tap(tester, const Key('creator-audience-comments'));
      expect(location(tester), contains('/app/chat/inbox'));
    },
  );

  testWidgets(
    'screen 129 covers every campaign tab and exact funded acceptance retry',
    (tester) async {
      final gateway = ReviewCreatorGateway()..failCampaignAccept = true;
      final session = CreatorSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/creator/campaigns',
        creatorSession: session,
      );
      for (final tab in CreatorCampaignTab.values) {
        await tap(tester, Key('creator-campaign-tab-${tab.name}'));
        expect(session.campaignTab, tab);
      }
      await tap(tester, const Key('creator-campaign-filter'));
      await tap(tester, const Key('creator-campaign-filter-close'));
      await tap(tester, const Key('creator-campaign-tab-bestFit'));
      for (final campaign in reviewCreatorCampaigns) {
        await tap(tester, Key('creator-campaign-review-${campaign.id}'));
        expect(session.selectedCampaignId, campaign.id);
        await tap(tester, const Key('creator-campaign-close'));
      }
      await tap(tester, const Key('creator-campaign-review-CR-2048'));
      await tap(tester, const Key('creator-campaign-primary'));
      expect(gateway.campaignAcceptCalls, 0);
      await tap(tester, const Key('creator-campaign-terms'));
      await tap(tester, const Key('creator-campaign-primary'));
      expect(session.campaignAcceptanceId, isNull);
      await tap(tester, const Key('creator-campaign-primary'));
      expect(session.campaignAcceptanceId, 'CR-ACCEPT-129-2048');
      expect(gateway.campaignAcceptCalls, 2);
      await tap(tester, const Key('creator-campaign-primary'));
      expect(gateway.campaignAcceptCalls, 2);
      await tap(tester, const Key('creator-campaign-create'));
      expect(location(tester), '/app/creator/publish?campaign=CR-2048');
    },
  );

  testWidgets(
    'screen 130 opens every ledger record and exactly retries statement',
    (tester) async {
      final gateway = ReviewCreatorGateway()..failStatement = true;
      final session = CreatorSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/creator/earnings',
        creatorSession: session,
      );
      for (final tab in CreatorEarningsTab.values) {
        await tap(tester, Key('creator-earnings-tab-${tab.name}'));
        expect(session.earningsTab, tab);
      }
      for (final item in reviewCreatorLedger) {
        await tap(tester, Key('creator-ledger-${item.id}'));
        expect(session.selectedLedgerId, item.id);
        await tap(tester, const Key('creator-ledger-close'));
      }
      await tap(tester, const Key('creator-earnings-download'));
      await tap(tester, const Key('creator-statement-prepare'));
      expect(session.statementId, isNull);
      await tap(tester, const Key('creator-statement-prepare'));
      expect(session.statementId, 'CR-STATEMENT-130-0726');
      expect(gateway.statementCalls, 2);
      await tap(tester, const Key('creator-statement-prepare'));
      expect(gateway.statementCalls, 2);
      await tap(tester, const Key('creator-statement-close'));
    },
  );

  testWidgets(
    'screen 131 opens every control and exactly retries one rights appeal',
    (tester) async {
      final gateway = ReviewCreatorGateway()..failAppeal = true;
      final session = CreatorSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/creator/control',
        creatorSession: session,
      );
      for (final area in CreatorControlArea.values.where(
        (area) => area != CreatorControlArea.rights,
      )) {
        await tap(tester, Key('creator-control-${area.name}'));
        expect(session.selectedControlArea, area);
        await tap(tester, const Key('creator-control-sheet-close'));
      }
      await tap(tester, const Key('creator-rights-alert'));
      await tap(tester, const Key('creator-appeal-submit'));
      expect(gateway.appealCalls, 0);
      await tap(tester, const Key('creator-appeal-evidence'));
      await tap(tester, const Key('creator-appeal-submit'));
      expect(session.appealId, isNull);
      await tap(tester, const Key('creator-appeal-submit'));
      expect(session.appealId, 'CR-APPEAL-131-2041');
      expect(gateway.appealCalls, 2);
      await tap(tester, const Key('creator-appeal-submit'));
      expect(gateway.appealCalls, 2);
      await tap(tester, const Key('creator-appeal-close'));
    },
  );

  testWidgets(
    'screen 132 covers eligibility, every plan and exact membership retry',
    (tester) async {
      final gateway = ReviewCreatorGateway()..failMembership = true;
      final session = CreatorSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/creator/audience?tab=memberships',
        creatorSession: session,
      );
      expect(
        find.byKey(const Key('creator-memberships-screen')),
        findsOneWidget,
      );
      await tap(tester, const Key('creator-membership-settings'));
      await tap(tester, const Key('creator-membership-eligibility-close'));
      for (final plan in reviewCreatorMembershipPlans) {
        await tap(tester, Key('creator-membership-manage-${plan.id}'));
        expect(session.selectedMembershipId, plan.id);
        await tap(tester, const Key('creator-membership-close'));
      }
      await tap(tester, const Key('creator-membership-manage-local-insider'));
      await tap(tester, const Key('creator-membership-save'));
      expect(gateway.membershipCalls, 0);
      await tap(tester, const Key('creator-membership-benefits'));
      await tap(tester, const Key('creator-membership-billing'));
      await tap(tester, const Key('creator-membership-save'));
      expect(session.membershipPlanId, isNull);
      await tap(tester, const Key('creator-membership-save'));
      expect(session.membershipPlanId, 'CR-MEMBER-132-local-insider');
      expect(gateway.membershipCalls, 2);
      await tap(tester, const Key('creator-membership-save'));
      expect(gateway.membershipCalls, 2);
    },
  );

  testWidgets(
    'offline and unauthorized Creator commands preserve every outcome',
    (tester) async {
      final gateway = ReviewCreatorGateway();
      final session = CreatorSession(gateway: gateway)
        ..postTitle = 'Funded Reel'
        ..postCaption = 'A complete caption for this funded Reel.'
        ..mediaSelected = true
        ..reelFundingReviewed = true
        ..rightsConfirmed = true
        ..campaignTermsAccepted = true
        ..appealEvidenceConfirmed = true
        ..membershipBenefitsConfirmed = true
        ..membershipBillingConfirmed = true
        ..youtubeValidated = true
        ..youtubeValidationId = 'YT-VALID-166-0719'
        ..youtubeAction = 'buy'
        ..youtubeRightsConfirmed = true
        ..youtubeActionTruthConfirmed = true
        ..youtubeStep = YouTubeConnectStep.review;
      await mount(tester, route: '/app/creator', creatorSession: session);
      session.setOnline(false);
      expect(await tester.runAsync(session.saveDraft), isFalse);
      expect(await tester.runAsync(session.publishNativePost), isFalse);
      expect(await tester.runAsync(session.acceptCampaign), isFalse);
      expect(await tester.runAsync(session.prepareStatement), isFalse);
      expect(await tester.runAsync(session.submitAppeal), isFalse);
      expect(await tester.runAsync(session.saveMembershipPlan), isFalse);
      expect(await tester.runAsync(session.publishYouTubeConnection), isFalse);
      session.setOnline(true);
      session.authorized = false;
      expect(await tester.runAsync(session.publishNativePost), isFalse);
      expect(await tester.runAsync(session.acceptCampaign), isFalse);
      expect([
        gateway.draftCalls,
        gateway.postPublishCalls,
        gateway.campaignAcceptCalls,
        gateway.statementCalls,
        gateway.appealCalls,
        gateway.membershipCalls,
        gateway.youtubePublishCalls,
      ], everyElement(0));
    },
  );
}
