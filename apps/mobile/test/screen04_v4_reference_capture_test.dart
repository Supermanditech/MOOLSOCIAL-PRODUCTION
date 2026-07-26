import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Screen 04 v4 identical-viewport comparison captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
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
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: app!,
          ),
          home: SocialUniversalV2(
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _capture(tester, 'screen04-v4-shorts-320x568-text140.png');
      await tester.tap(find.byKey(const Key('screen04-rail-videos')));
      await tester.pumpAndSettle();
      await _capture(tester, 'screen04-v4-videos-320x568-text140.png');
      await tester.tap(find.byKey(const Key('screen04-rail-feed')));
      await tester.pumpAndSettle();
      await _capture(tester, 'screen04-v4-feed-320x568-text140.png');
      await tester.tap(find.byKey(const Key('screen04-rail-create')));
      await tester.pumpAndSettle();
      await _capture(tester, 'screen04-v4-create-320x568-text140.png');

      expect(tester.takeException(), isNull);
    },
    // Historical capture retained as evidence; v7 is the active lock.
    skip: true,
  );
}

Future<void> _capture(WidgetTester tester, String fileName) async {
  await tester.pump(const Duration(milliseconds: 500));
  await expectLater(
    find.byKey(const Key('screen04-universal-v2')),
    matchesGoldenFile('candidate_captures/$fileName'),
  );
}
