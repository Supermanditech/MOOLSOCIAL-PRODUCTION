import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RT-07 Android Back from focused Feed returns to Mool and retains Feed',
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
      addTearDown(journey.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          initialLocation: '/app/social?sub=feed',
        ),
      );
      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope<Object?>>(
        find.ancestor(
          of: find.byKey(const Key('screen04-universal-v2')),
          matching: find.byType(PopScope<Object?>),
        ),
      );
      expect(popScope.canPop, isFalse);
      expect(find.byKey(const Key('screen04-feed-create-post')), findsWidgets);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
      expect(find.byKey(const Key('screen04-universal-v2')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.byKey(const Key('screen04-feed-create-post')), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
