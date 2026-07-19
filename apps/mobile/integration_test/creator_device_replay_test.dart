import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/creator/creator_services.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
      expect(scrollables, findsWidgets, reason: 'No scrollable for $key');
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
    await tester.pumpAndSettle();
    return finder;
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await tester.pumpAndSettle();
  }

  Future<void> openRoute(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  Future<void> chooseDropdown(
    WidgetTester tester, {
    required Key key,
    required String label,
  }) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical Creator completes business-funded Reel, YouTube, campaign, earnings, rights and membership failed-tap replays',
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
      final gateway = ReviewCreatorGateway()
        ..failDraft = true
        ..failPostPublish = true
        ..failYouTubeValidation = true
        ..failYouTubePublish = true
        ..failCampaignAccept = true
        ..failStatement = true
        ..failAppeal = true
        ..failMembership = true;
      final creator = CreatorSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          creatorSession: creator,
          initialLocation: '/app/creator',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('creator-studio-home-screen')),
        findsOneWidget,
      );
      await binding.takeScreenshot('creator-124-studio');
      await tapVisible(tester, const Key('creator-home-publish'));
      expect(find.byKey(const Key('creator-publish-screen')), findsOneWidget);

      await tapVisible(tester, const Key('creator-media-camera'));
      await enter(tester, const Key('creator-post-title'), 'Fresh basket Reel');
      await enter(
        tester,
        const Key('creator-post-caption'),
        'See how a verified shop packs the morning basket.',
      );
      await tapVisible(tester, const Key('creator-reel-days-7'));
      expect(creator.reelDurationDays, 7);
      await tapVisible(tester, const Key('creator-reel-funding-terms'));
      await tapVisible(tester, const Key('creator-rights-confirm'));
      await binding.takeScreenshot('creator-125-business-funded-reel');

      await tapVisible(tester, const Key('creator-save-draft'));
      expect(creator.draftId, isNull);
      await tapVisible(tester, const Key('creator-save-draft'));
      expect(creator.draftId, 'CR-DRAFT-125-0719');
      expect(gateway.draftCalls, 2);

      await tapVisible(tester, const Key('creator-review-publish'));
      await tapVisible(tester, const Key('creator-publish-confirm'));
      expect(creator.publishedPostId, isNull);
      await tapVisible(tester, const Key('creator-publish-confirm'));
      expect(creator.publishedPostId, 'REEL-125-0719');
      expect(gateway.postPublishCalls, 2);
      await binding.takeScreenshot('creator-125-reel-published');
      await tapVisible(tester, const Key('creator-publish-view-library'));

      await openRoute(tester, '/app/creator/youtube-connect');
      await tapVisible(tester, const Key('youtube-connect-channel'));
      await tapVisible(tester, const Key('youtube-channel-confirm'));
      await enter(
        tester,
        const Key('youtube-url'),
        'https://youtube.com/watch?v=LOCAL123',
      );
      await tapVisible(tester, const Key('youtube-validate'));
      expect(creator.youtubeValidationId, isNull);
      await tapVisible(tester, const Key('youtube-validate'));
      expect(creator.youtubeValidationId, 'YT-VALID-166-0719');
      expect(gateway.youtubeValidationCalls, 2);
      await tapVisible(tester, const Key('youtube-source-continue'));
      await tapVisible(tester, const Key('youtube-action-buy'));
      await chooseDropdown(
        tester,
        key: const Key('youtube-campaign'),
        label: 'Funded Campaign Reel · CR-2048',
      );
      await tapVisible(tester, const Key('youtube-days-7'));
      await tapVisible(tester, const Key('youtube-rights'));
      await tapVisible(tester, const Key('youtube-action-truth'));
      await tapVisible(tester, const Key('youtube-action-preview'));
      await binding.takeScreenshot('creator-166-youtube-review');
      await tapVisible(tester, const Key('youtube-publish'));
      expect(creator.youtubeConnectedPostId, isNull);
      await tapVisible(tester, const Key('youtube-publish'));
      expect(creator.youtubeConnectedPostId, 'YT-POST-166-0719');
      expect(gateway.youtubePublishCalls, 2);

      await openRoute(tester, '/app/creator/campaigns');
      await tapVisible(tester, const Key('creator-campaign-review-CR-2048'));
      await tapVisible(tester, const Key('creator-campaign-terms'));
      await tapVisible(tester, const Key('creator-campaign-primary'));
      expect(creator.campaignAcceptanceId, isNull);
      await tapVisible(tester, const Key('creator-campaign-primary'));
      expect(creator.campaignAcceptanceId, 'CR-ACCEPT-129-2048');
      expect(gateway.campaignAcceptCalls, 2);
      await tapVisible(tester, const Key('creator-campaign-create'));

      await openRoute(tester, '/app/creator/earnings');
      await tapVisible(tester, const Key('creator-earnings-download'));
      await tapVisible(tester, const Key('creator-statement-prepare'));
      expect(creator.statementId, isNull);
      await tapVisible(tester, const Key('creator-statement-prepare'));
      expect(creator.statementId, 'CR-STATEMENT-130-0726');
      expect(gateway.statementCalls, 2);
      await tapVisible(tester, const Key('creator-statement-close'));

      await openRoute(tester, '/app/creator/control');
      await tapVisible(tester, const Key('creator-rights-alert'));
      await tapVisible(tester, const Key('creator-appeal-evidence'));
      await tapVisible(tester, const Key('creator-appeal-submit'));
      expect(creator.appealId, isNull);
      await tapVisible(tester, const Key('creator-appeal-submit'));
      expect(creator.appealId, 'CR-APPEAL-131-2041');
      expect(gateway.appealCalls, 2);
      await tapVisible(tester, const Key('creator-appeal-close'));

      await openRoute(tester, '/app/creator/audience?tab=memberships');
      await tapVisible(
        tester,
        const Key('creator-membership-manage-local-insider'),
      );
      await tapVisible(tester, const Key('creator-membership-benefits'));
      await tapVisible(tester, const Key('creator-membership-billing'));
      await tapVisible(tester, const Key('creator-membership-save'));
      expect(creator.membershipPlanId, isNull);
      await tapVisible(tester, const Key('creator-membership-save'));
      expect(creator.membershipPlanId, 'CR-MEMBER-132-local-insider');
      expect(gateway.membershipCalls, 2);
      await binding.takeScreenshot('creator-132-membership-saved');

      expect([
        gateway.draftCalls,
        gateway.postPublishCalls,
        gateway.youtubeValidationCalls,
        gateway.youtubePublishCalls,
        gateway.campaignAcceptCalls,
        gateway.statementCalls,
        gateway.appealCalls,
        gateway.membershipCalls,
      ], everyElement(2));
    },
  );
}
