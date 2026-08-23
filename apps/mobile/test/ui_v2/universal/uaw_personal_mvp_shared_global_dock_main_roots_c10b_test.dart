import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  JourneySession signedInSession() => JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
        setupExperienceVersion: approvedSetupExperienceVersion,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );

  testWidgets(
    'Social and Work share one connected launcher while Back restores Feed',
    (tester) async {
      final journey = signedInSession();
      addTearDown(journey.dispose);
      await journey.start();
      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          initialLocation: '/app/social?sub=feed',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('screen04-moolsocial-feed-brand')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(
        find.byKey(const Key('moolsocial-global-navigation')),
        findsNothing,
      );
      expect(find.byKey(const Key('screen04-context-tabs')), findsOneWidget);
      expect(find.byKey(const Key('mvp-action-work-back')), findsNothing);

      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mool-navigator-family-work')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
      expect(find.byKey(const Key('mvp-action-work-back')), findsNothing);
      expect(
        find.byKey(const Key('moolsocial-global-navigation')),
        findsNothing,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-brand')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
    },
  );
}
