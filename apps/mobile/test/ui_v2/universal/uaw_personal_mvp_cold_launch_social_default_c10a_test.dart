import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  JourneySnapshot readySnapshot({
    String? pendingRoute,
    String? lastReadyRoute,
  }) {
    return JourneySnapshot(
      languageCode: 'en',
      areaMode: 'current',
      currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
      setupComplete: true,
      setupExperienceVersion: approvedSetupExperienceVersion,
      pendingRoute: pendingRoute,
      lastReadyRoute: lastReadyRoute,
    );
  }

  test(
    'fresh authenticated launch ignores a persisted Workspace route',
    () async {
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: readySnapshot(lastReadyRoute: '/app/work/my-work'),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.ready);
      expect(session.readyRoute(), '/app/social');
    },
  );

  test('explicit local pending route keeps precedence at boot', () async {
    const pendingRoute = '/app/buy?sub=medicine';
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: readySnapshot(
          pendingRoute: pendingRoute,
          lastReadyRoute: '/app/work/my-work',
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.ready);
    expect(session.readyRoute(), pendingRoute);
  });

  testWidgets('production boot hands a returning account to Social', (
    tester,
  ) async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: readySnapshot(lastReadyRoute: '/app/work/my-work'),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    addTearDown(session.dispose);

    await session.start();
    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/boot'),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(find.byKey(const Key('mvp-action-root-work')), findsNothing);
  });
}
