import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_services.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      expect(scrollables, findsWidgets, reason: 'No scrollable for $key');
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
          attempt < 50 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 260).clamp(
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

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await tester.pumpAndSettle();
  }

  Future<void> openRoute(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical Medicine completes empty recovery, basket, prescription and pharmacist failed-tap replays',
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
      final gateway = ReviewBuyMedicineGateway(
        failPrescription: true,
        failPharmacist: true,
        latency: Duration.zero,
      );
      final buy = BuySession(medicineGateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(buy.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          buySession: buy,
          initialLocation: '/app/buy/medicine',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('buy-medicine-screen')), findsOneWidget);
      await binding.takeScreenshot('buy-medicine-search');

      await enter(tester, const Key('medicine-search'), 'not listed');
      expect(find.byKey(const Key('medicine-empty')), findsOneWidget);
      await tapVisible(tester, const Key('medicine-empty-clear'));
      await tapVisible(tester, const Key('medicine-primary-ors'));
      expect(buy.quantityFor('ors'), 1);
      await tapVisible(tester, const Key('medicine-view-basket'));
      expect(find.byKey(const Key('buy-basket-screen')), findsOneWidget);
      expect(find.text('ORS electrolyte sachets'), findsOneWidget);

      await openRoute(tester, '/app/buy/medicine');
      await tapVisible(tester, const Key('medicine-primary-metformin-500'));
      await tapVisible(tester, const Key('medicine-prescription-submit'));
      expect(
        find.text('Add the prescription before sending this request.'),
        findsOneWidget,
      );
      expect(gateway.prescriptionCalls, 0);

      await tapVisible(tester, const Key('medicine-prescription-attach'));
      await tapVisible(tester, const Key('medicine-prescription-submit'));
      expect(find.textContaining('prescription was not sent'), findsOneWidget);
      expect(gateway.prescriptionCalls, 1);
      expect(buy.medicineRequestId, isNull);

      await tapVisible(tester, const Key('medicine-prescription-submit'));
      expect(buy.medicineRequestId, 'RX-4102');
      expect(gateway.prescriptionCalls, 2);
      expect(
        find.byKey(const Key('medicine-prescription-result')),
        findsOneWidget,
      );
      expect(await buy.submitPrescription(), isTrue);
      expect(gateway.prescriptionCalls, 2);
      await binding.takeScreenshot('buy-medicine-prescription-complete');

      await tapVisible(tester, const Key('medicine-path-pharmacist'));
      await tapVisible(tester, const Key('medicine-pharmacist-submit'));
      expect(find.text('Describe what you need help with.'), findsOneWidget);
      expect(gateway.pharmacistCalls, 0);

      const question = 'Is a prescription required for this medicine?';
      await enter(tester, const Key('medicine-pharmacist-question'), question);
      await tapVisible(tester, const Key('medicine-pharmacist-submit'));
      expect(find.textContaining('question was not sent'), findsOneWidget);
      expect(gateway.pharmacistCalls, 1);
      expect(find.text(question), findsOneWidget);

      await tapVisible(tester, const Key('medicine-pharmacist-submit'));
      expect(buy.pharmacistRequestId, 'PH-7302');
      expect(gateway.pharmacistCalls, 2);
      expect(
        find.byKey(const Key('medicine-pharmacist-result')),
        findsOneWidget,
      );
      expect(await buy.requestPharmacist(question), isTrue);
      expect(gateway.pharmacistCalls, 2);
      await binding.takeScreenshot('buy-medicine-pharmacist-complete');
    },
  );
}
