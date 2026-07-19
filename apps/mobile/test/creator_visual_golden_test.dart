import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/creator/creator_models.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> verifyScreen(
    WidgetTester tester, {
    required String route,
    required String golden,
    void Function(CreatorSession session)? prepare,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
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
    final creator = CreatorSession();
    prepare?.call(creator);
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
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(golden));
  }

  testWidgets('Creator Studio 124 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator',
      golden: 'goldens/creator-124-studio-412x915.png',
    );
  });

  testWidgets('Creator funded Reel 125 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/publish?campaign=CR-2048',
      golden: 'goldens/creator-125-funded-reel-412x915.png',
      prepare: (session) {
        session
          ..postTitle = 'Fresh basket packed this morning'
          ..postCaption =
              'See how a verified local shop prepares the morning basket.'
          ..mediaSelected = true
          ..reelDurationDays = 3;
      },
    );
  });

  testWidgets('Creator text post 125 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/publish',
      golden: 'goldens/creator-125-text-post-412x915.png',
      prepare: (session) {
        session
          ..publishFormat = CreatorPublishFormat.text
          ..postTitle = 'Ask before you buy'
          ..postCaption =
              'Share the product details you want verified before purchase.';
      },
    );
  });

  testWidgets('YouTube Connect source 166 phone visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/creator/youtube-connect',
      golden: 'goldens/creator-166-youtube-source-412x915.png',
    );
  });

  testWidgets('YouTube Connect action 166 phone visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/creator/youtube-connect',
      golden: 'goldens/creator-166-youtube-action-412x915.png',
      prepare: (session) {
        session
          ..youtubeUrl = 'https://youtube.com/watch?v=LOCAL123'
          ..youtubeValidated = true
          ..youtubeValidationId = 'YT-VALID-166-0719'
          ..youtubeStep = YouTubeConnectStep.action;
      },
    );
  });

  testWidgets('YouTube Connect review 166 phone visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/creator/youtube-connect',
      golden: 'goldens/creator-166-youtube-review-412x915.png',
      prepare: (session) {
        session
          ..youtubeUrl = 'https://youtube.com/watch?v=LOCAL123'
          ..youtubeValidated = true
          ..youtubeValidationId = 'YT-VALID-166-0719'
          ..youtubeAction = 'buy'
          ..youtubeCampaign = 'CR-2048'
          ..youtubePlacementDays = 3
          ..youtubeRightsConfirmed = true
          ..youtubeActionTruthConfirmed = true
          ..youtubeSponsored = true
          ..youtubeStep = YouTubeConnectStep.review;
      },
    );
  });

  testWidgets('Creator library 126 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/content',
      golden: 'goldens/creator-126-library-412x915.png',
    );
  });

  testWidgets('Creator performance 127 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/performance',
      golden: 'goldens/creator-127-performance-412x915.png',
    );
  });

  testWidgets('Creator audience 128 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/audience',
      golden: 'goldens/creator-128-audience-412x915.png',
    );
  });

  testWidgets('Creator campaigns 129 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/campaigns',
      golden: 'goldens/creator-129-campaigns-412x915.png',
    );
  });

  testWidgets('Creator earnings 130 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/earnings',
      golden: 'goldens/creator-130-earnings-412x915.png',
    );
  });

  testWidgets('Creator control 131 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/control',
      golden: 'goldens/creator-131-control-412x915.png',
    );
  });

  testWidgets('Creator memberships 132 phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/creator/audience?tab=memberships',
      golden: 'goldens/creator-132-memberships-412x915.png',
    );
  });
}
