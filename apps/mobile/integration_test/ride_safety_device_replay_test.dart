import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/ride/ride_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      for (final state
          in find
              .byWidgetPredicate((widget) => widget is Scrollable)
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
          attempt < 30 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 240).clamp(
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

  Future<void> tap(WidgetTester tester, Key key) async {
    final finder = await reveal(tester, key);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('physical Ride safety completes empty and active-trip actions', (
    tester,
  ) async {
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
    final ride = RideSession();
    addTearDown(journey.dispose);
    addTearDown(ride.dispose);
    await journey.start();

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        rideSession: ride,
        initialLocation: '/app/ride/book',
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await tap(tester, const Key('ride-safety-shortcut'));
    expect(find.textContaining('There is no active trip'), findsOneWidget);
    await tap(tester, const Key('ride-safety-report'));
    expect(
      find.byKey(const Key('chat-open-thread-order-support')),
      findsOneWidget,
    );

    await ride.bookRide();
    final tripId = ride.trip!.id;
    tester.element(find.byType(Scaffold).first).go('/app/ride/trip/$tripId');
    await tester.pumpAndSettle();
    await tap(tester, const Key('ride-open-safety'));
    await tap(tester, const Key('ride-safety-share'));
    expect(ride.noticeMessage, 'Live trip safety link copied.');
    await binding.takeScreenshot('ride-safety-030-empty-active');
  });
}
