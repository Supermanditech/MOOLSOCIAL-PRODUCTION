import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
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
    await session.start();
    return session;
  }

  testWidgets(
    'primary app destinations reflow in landscape without locking rotation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const destinations = <(String, Key)>[
        ('/app/mool', Key('personal-mool-root-v2')),
        ('/app/buy?sub=shop', ValueKey('buy-v2-screen')),
        ('/app/buy?sub=wholesale', ValueKey('buy-v2-screen')),
        ('/app/buy?sub=orders', ValueKey('buy-v2-screen')),
        ('/app/buy?sub=medicine', ValueKey('buy-v2-screen')),
        ('/app/buy/basket', ValueKey('buy-v2-screen')),
        ('/app/buy/review', ValueKey('buy-v2-screen')),
        ('/app/social?sub=feed', Key('screen04-universal-v2')),
        ('/app/social?sub=videos', Key('screen04-universal-v2')),
        ('/app/social?sub=shorts', Key('screen04-universal-v2')),
        ('/app/social?sub=create', Key('screen04-universal-v2')),
        ('/app/eat/home', Key('eat-home-screen')),
        ('/app/eat/table', Key('eat-table-screen')),
        ('/app/ride/book?type=cab', Key('ride-booking-screen')),
        ('/app/book/doctor', Key('doctor-discovery-home')),
        ('/app/book/salon', Key('salon-discovery-home')),
        ('/app/book/bus', Key('bus-booking-home')),
        ('/app/work/earn', Key('work-earn-screen')),
        ('/app/work/my-work', Key('work-choose-screen')),
        ('/app/chat?from=%2Fapp%2Fbuy%3Fsub%3Dshop', Key('chat-inbox-screen')),
        (
          '/app/chat/thread/shop-assist?return=%2Fapp%2Fbuy%3Fsub%3Dshop',
          Key('chat-thread-screen'),
        ),
      ];
      const viewports = <(Size, double)>[
        (Size(844, 390), 1),
        (Size(640, 360), 1.4),
      ];

      for (final viewport in viewports) {
        tester.view.physicalSize = viewport.$1;
        tester.platformDispatcher.textScaleFactorTestValue = viewport.$2;
        for (final destination in destinations) {
          final journey = await readyJourney();
          await tester.pumpWidget(
            MoolSocialApp(
              key: UniqueKey(),
              session: journey,
              initialLocation: destination.$1,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(destination.$2),
            findsOneWidget,
            reason: '${destination.$1} at ${viewport.$1}',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${destination.$1} at ${viewport.$1}',
          );

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          journey.dispose();
        }
      }
    },
  );

  testWidgets('global profile remains usable in compact landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    final journey = await readyJourney();
    addTearDown(journey.dispose);

    await tester.pumpWidget(
      MoolSocialApp(session: journey, initialLocation: '/app/buy?sub=shop'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
    expect(
      find.byKey(const Key('global-profile-panel-content')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('global-profile-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape Mool menu scrolls to every main action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.reset);
    final journey = await readyJourney();
    addTearDown(journey.dispose);

    await tester.pumpWidget(
      MoolSocialApp(session: journey, initialLocation: '/app/mool'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mool-home-dashboard-scroll')), findsOneWidget);
    final work = find.byKey(const ValueKey('mool-home-family-work'));
    await tester.ensureVisible(work);
    await tester.pumpAndSettle();

    expect(tester.getRect(work).bottom, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });
}
