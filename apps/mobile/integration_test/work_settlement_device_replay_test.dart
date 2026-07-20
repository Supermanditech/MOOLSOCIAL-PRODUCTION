import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';

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
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical My Work settlement completes close and workspace actions',
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
      final work = WorkSession()..seedMultipleWorkspaces();
      addTearDown(journey.dispose);
      addTearDown(work.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          workSession: work,
          initialLocation: '/app/work/my-work',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      await tap(tester, const Key('my-work-settlement'));
      expect(find.byKey(const Key('my-work-settlement-sheet')), findsOneWidget);
      expect(find.text('No payout is due now'), findsOneWidget);
      await tap(tester, const Key('my-work-settlement-close'));

      await tap(tester, const Key('my-work-settlement'));
      await tap(tester, const Key('my-work-settlement-open-workspace'));
      expect(find.byKey(const Key('retailer-home-screen')), findsOneWidget);
      await binding.takeScreenshot('work-settlement-031-summary-workspace');
    },
  );
}
