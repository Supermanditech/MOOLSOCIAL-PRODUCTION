import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_models.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> verifyScreen(
    WidgetTester tester, {
    required String golden,
    void Function(BuySession session)? prepare,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
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
    final buy = BuySession();
    prepare?.call(buy);
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      buy.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        buySession: buy,
        initialLocation: '/app/buy/medicine',
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(golden));
  }

  testWidgets('Medicine search phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      golden: 'goldens/buy-medicine-search-412x915.png',
    );
  });

  testWidgets('Medicine prescription result phone visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      golden: 'goldens/buy-medicine-prescription-412x915.png',
      prepare: (session) {
        session
          ..medicinePath = BuyMedicinePath.prescription
          ..selectedMedicineId = 'metformin-500'
          ..prescriptionAttached = true
          ..medicineRequestId = 'RX-4102';
      },
    );
  });

  testWidgets('Pharmacist request result phone visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      golden: 'goldens/buy-medicine-pharmacist-412x915.png',
      prepare: (session) {
        session
          ..medicinePath = BuyMedicinePath.pharmacist
          ..pharmacistRequestId = 'PH-7302';
      },
    );
  });
}
