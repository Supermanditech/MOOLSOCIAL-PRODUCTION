import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/eat/eat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) => widget is Scrollable,
      );
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

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical Eat Find and Offers complete their owned nested actions',
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
      final eat = EatSession();
      addTearDown(journey.dispose);
      addTearDown(eat.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          eatSession: eat,
          initialLocation: '/app/eat/home',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      await tapVisible(tester, const Key('eat-context-find'));
      final search = tester.widget<TextField>(
        find.byKey(const Key('eat-home-search')),
      );
      expect(search.focusNode?.hasFocus, isTrue);
      await tester.enterText(find.byKey(const Key('eat-home-search')), 'Spice');
      await tester.pumpAndSettle();
      expect(find.text('Spice Darbar'), findsWidgets);

      await tapVisible(tester, const Key('eat-context-offers'));
      expect(find.byKey(const Key('eat-offer-sheet')), findsOneWidget);
      expect(find.text(eat.selectedRestaurant.offer), findsWidgets);
      await tapVisible(tester, const Key('eat-offer-close'));

      await tapVisible(tester, const Key('eat-context-offers'));
      await tapVisible(tester, const Key('eat-offer-order'));
      expect(find.byKey(const Key('eat-order-screen')), findsOneWidget);
      await binding.takeScreenshot('eat-home-028-find-offer-order');
    },
  );
}
