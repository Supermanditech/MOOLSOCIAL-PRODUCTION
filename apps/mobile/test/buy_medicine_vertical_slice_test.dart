import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_services.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    required BuySession buy,
    Size size = const Size(412, 915),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    addTearDown(buy.dispose);
    await journey.start();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MoolSocialApp(
          session: journey,
          buySession: buy,
          initialLocation: '/app/buy/medicine',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return finder;
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  testWidgets('search handles empty recovery and adds an eligible item', (
    tester,
  ) async {
    final buy = BuySession();
    await mount(tester, buy: buy);

    expect(find.byKey(const Key('buy-medicine-screen')), findsOneWidget);
    for (final path in const ['search', 'prescription', 'pharmacist']) {
      expect(
        find.byKey(Key('medicine-path-$path')).hitTestable(),
        findsOneWidget,
      );
    }

    await tester.enterText(
      find.byKey(const Key('medicine-search')),
      'not listed',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('medicine-empty')), findsOneWidget);
    await tap(tester, const Key('medicine-empty-clear'));

    await tap(tester, const Key('medicine-primary-ors'));
    expect(buy.quantityFor('ors'), 1);
    expect(find.textContaining('added to your basket'), findsOneWidget);
    await tap(tester, const Key('medicine-view-basket'));
    expect(find.byKey(const Key('buy-basket-screen')), findsOneWidget);
    expect(find.text('ORS electrolyte sachets'), findsOneWidget);
  });

  testWidgets(
    'prescription validates, preserves failure and succeeds once on retry',
    (tester) async {
      final gateway = ReviewBuyMedicineGateway(
        failPrescription: true,
        latency: Duration.zero,
      );
      final buy = BuySession(medicineGateway: gateway);
      await mount(tester, buy: buy);

      await tap(tester, const Key('medicine-primary-metformin-500'));
      expect(
        find.byKey(const Key('medicine-prescription-request')),
        findsOneWidget,
      );

      await tap(tester, const Key('medicine-prescription-submit'));
      expect(
        find.text('Add the prescription before sending this request.'),
        findsOneWidget,
      );
      expect(gateway.prescriptionCalls, 0);

      await tap(tester, const Key('medicine-prescription-attach'));
      await tap(tester, const Key('medicine-prescription-submit'));
      expect(find.textContaining('prescription was not sent'), findsOneWidget);
      expect(gateway.prescriptionCalls, 1);
      expect(buy.medicineRequestId, isNull);

      await tap(tester, const Key('medicine-prescription-submit'));
      expect(buy.medicineRequestId, 'RX-4102');
      expect(gateway.prescriptionCalls, 2);
      expect(
        find.byKey(const Key('medicine-prescription-result')),
        findsOneWidget,
      );

      expect(await buy.submitPrescription(), isTrue);
      expect(gateway.prescriptionCalls, 2);
    },
  );

  testWidgets(
    'pharmacist question validates, retries without losing text and opens once',
    (tester) async {
      final gateway = ReviewBuyMedicineGateway(
        failPharmacist: true,
        latency: Duration.zero,
      );
      final buy = BuySession(medicineGateway: gateway);
      await mount(tester, buy: buy);

      await tap(tester, const Key('medicine-path-pharmacist'));
      await tap(tester, const Key('medicine-pharmacist-submit'));
      expect(find.text('Describe what you need help with.'), findsOneWidget);
      expect(gateway.pharmacistCalls, 0);

      await tester.enterText(
        find.byKey(const Key('medicine-pharmacist-question')),
        'Is a prescription required for this medicine?',
      );
      await tap(tester, const Key('medicine-pharmacist-submit'));
      expect(find.textContaining('question was not sent'), findsOneWidget);
      expect(gateway.pharmacistCalls, 1);
      expect(
        find.text('Is a prescription required for this medicine?'),
        findsOneWidget,
      );

      await tap(tester, const Key('medicine-pharmacist-submit'));
      expect(buy.pharmacistRequestId, 'PH-7302');
      expect(gateway.pharmacistCalls, 2);
      expect(
        find.byKey(const Key('medicine-pharmacist-result')),
        findsOneWidget,
      );

      expect(
        await buy.requestPharmacist(
          'Is a prescription required for this medicine?',
        ),
        isTrue,
      );
      expect(gateway.pharmacistCalls, 2);
    },
  );

  testWidgets(
    'compact larger-text screen keeps every medicine path reachable',
    (tester) async {
      final buy = BuySession();
      await mount(tester, buy: buy, size: const Size(360, 800), textScale: 1.4);

      for (final path in const ['search', 'prescription', 'pharmacist']) {
        expect(
          find.byKey(Key('medicine-path-$path')).hitTestable(),
          findsOneWidget,
        );
      }
      await reveal(tester, const Key('medicine-primary-ors'));
      expect(
        find.byKey(const Key('medicine-primary-ors')).hitTestable(),
        findsOneWidget,
      );
    },
  );
}
