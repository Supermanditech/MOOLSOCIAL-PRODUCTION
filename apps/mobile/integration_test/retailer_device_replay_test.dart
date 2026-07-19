import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_models.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapVisible(WidgetTester tester, Key key) async {
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
      await tester.drag(scrollables.last, const Offset(0, 900));
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 14 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(scrollables.last, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
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
      for (
        var attempt = 0;
        attempt < 14 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(scrollables.last, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing input $key');
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical retailer order reaches verified delivery and Business Book',
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
      final retailer = RetailerSession();
      addTearDown(journey.dispose);
      addTearDown(retailer.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          retailerSession: retailer,
          initialLocation: '/app/retailer/home',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('retailer-74-home');

      await tapVisible(tester, const Key('retailer-alerts'));
      await tapVisible(tester, const Key('retailer-alert-review-order'));
      await binding.takeScreenshot('retailer-75-order-review');
      await tapVisible(tester, const Key('retailer-accept-order'));
      await tapVisible(tester, const Key('retailer-start-packing'));
      await tapVisible(tester, const Key('retailer-mark-order-packed'));
      expect(find.textContaining('Check every product'), findsOneWidget);
      await tapVisible(tester, const Key('retailer-pack-oil'));
      await tapVisible(tester, const Key('retailer-pack-atta'));
      await tapVisible(tester, const Key('retailer-pack-salt'));
      await tapVisible(tester, const Key('retailer-show-remaining-lines'));
      await tapVisible(tester, const Key('retailer-pack-remaining'));
      await tapVisible(tester, const Key('retailer-mark-order-packed'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.packed);

      await tapVisible(tester, const Key('retailer-request-delivery'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.captainAssigned);
      await binding.takeScreenshot('retailer-76-captain-assigned');
      await tapVisible(tester, const Key('retailer-parcel-ready'));
      await tapVisible(tester, const Key('retailer-captain-here'));
      await tapVisible(tester, const Key('retailer-confirm-handover'));
      await enter(tester, const Key('retailer-handover-otp'), '2841');
      await tapVisible(tester, const Key('retailer-verify-handover-otp'));
      await tapVisible(tester, const Key('retailer-hand-over-parcel'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.handedOver);

      await tapVisible(tester, const Key('retailer-track-delivery'));
      await tapVisible(tester, const Key('retailer-refresh-tracking'));
      await tapVisible(tester, const Key('retailer-refresh-tracking'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.delivered);
      await tapVisible(tester, const Key('retailer-delivery-receipt'));
      expect(retailer.businessBookRecorded, isTrue);
      await binding.takeScreenshot('retailer-77-delivered-receipt');
      await tapVisible(tester, const Key('retailer-delivery-open-book'));
      expect(find.textContaining('recorded in Business Book'), findsOneWidget);
    },
  );
}
