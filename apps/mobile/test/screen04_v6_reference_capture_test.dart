import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/social_media_picker.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Screen 04 v6 identical-viewport comparison captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'current',
            areaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final creator = CreatorSession();
      final retailer = RetailerSession();
      final shared = SharedSession();
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
          home: SocialUniversalV2(
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
            mediaPicker: const _CaptureMediaPicker(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/prototype/social-market-grocery.png'),
          tester.element(find.byKey(const Key('screen04-universal-v2'))),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('screen04-rail-videos')));
      await tester.pumpAndSettle();
      await _capture(tester, 'screen04-v6-videos-discovery-390x844.png');

      await tester.tap(find.text('5-minute morning mobility'));
      await tester.pumpAndSettle();
      await _capture(tester, 'screen04-v6-videos-watch-390x844.png');

      await tester.tap(find.byKey(const Key('screen04-video-details-trigger')));
      await tester.pumpAndSettle();
      await _captureOverlay(
        tester,
        'screen04-v6-videos-description-390x844.png',
      );

      await tester.tap(
        find.byKey(const Key('screen04-video-channel-details-sheet')),
      );
      await tester.pumpAndSettle();
      await _captureOverlay(tester, 'screen04-v6-videos-channel-390x844.png');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-video-watch')), findsNothing);

      await tester.tap(find.byKey(const Key('screen04-rail-shorts')));
      await tester.pumpAndSettle();
      await _capture(tester, 'screen04-v6-shorts-390x844.png');

      await tester.tap(find.byKey(const Key('screen04-rail-feed')));
      await tester.pumpAndSettle();
      await _capture(tester, 'screen04-v6-feed-390x844.png');

      await tester.tap(find.byKey(const Key('screen04-rail-create')));
      await tester.pumpAndSettle();
      await _capture(tester, 'screen04-v6-create-390x844.png');
      expect(tester.takeException(), isNull);
    },
    // Historical capture retained as evidence; v7 is the active lock.
    skip: true,
  );
}

class _CaptureMediaPicker implements SocialMediaPicker {
  const _CaptureMediaPicker();

  @override
  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10}) async =>
      const <SocialPickedMedia>[];

  @override
  Future<SocialPickedMedia?> pickImage(SocialMediaSource source) async => null;

  @override
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source) async => null;

  @override
  Future<List<SocialPickedMedia>> recoverInterruptedSelection() async =>
      const <SocialPickedMedia>[];
}

Future<void> _capture(WidgetTester tester, String fileName) async {
  await tester.pump(const Duration(milliseconds: 900));
  await expectLater(
    find.byKey(const Key('screen04-universal-v2')),
    matchesGoldenFile('candidate_captures/$fileName'),
  );
}

Future<void> _captureOverlay(WidgetTester tester, String fileName) async {
  await tester.pump(const Duration(milliseconds: 300));
  await expectLater(
    find.byType(Overlay).first,
    matchesGoldenFile('candidate_captures/$fileName'),
  );
}
