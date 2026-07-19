import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_pos_models.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

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
      final scrollable = tester.state<ScrollableState>(scrollables.last);
      scrollable.position.jumpTo(scrollable.position.minScrollExtent);
      await tester.pump();
      for (
        var attempt = 0;
        attempt < 18 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        scrollable.position.jumpTo(
          (scrollable.position.pixels + 300).clamp(
            scrollable.position.minScrollExtent,
            scrollable.position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
      for (
        var attempt = 0;
        attempt < 8 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(scrollables.last, const Offset(0, -560));
        await tester.pumpAndSettle();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return finder;
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = await reveal(tester, key);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical retailer counter order posts one paid invoice to Sales Book',
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

      await tapVisible(tester, const Key('retailer-new-order'));
      await tapVisible(tester, const Key('pos-source-counter'));
      await tapVisible(tester, const Key('pos-scan-product'));
      await tapVisible(tester, const Key('pos-scan-success'));
      expect(retailer.posTotal, 428);
      await binding.takeScreenshot('retailer-78-counter-order');

      await tapVisible(tester, const Key('pos-create-order'));
      expect(retailer.posOrderId, 'RT-3028');
      await binding.takeScreenshot('retailer-78-order-created');
      await tapVisible(tester, const Key('pos-open-created-order'));
      expect(find.byKey(const Key('counter-sale-screen')), findsOneWidget);
      expect(retailer.posPayment, RetailerPosPayment.upi);
      await binding.takeScreenshot('retailer-80-receive-payment');

      await tapVisible(tester, const Key('sale-complete'));
      expect(retailer.posInvoiceId, 'MSI-3028');
      expect(
        retailer.sales.where((sale) => sale.invoiceId == 'MSI-3028'),
        hasLength(1),
      );
      await binding.takeScreenshot('retailer-80-sale-complete');
      await tapVisible(tester, const Key('sale-share-qr'));
      expect(find.textContaining('Invoice QR is ready'), findsOneWidget);
      await tapVisible(tester, const Key('sale-done'));

      expect(find.byKey(const Key('sales-book-screen')), findsOneWidget);
      await reveal(tester, const Key('sales-row-MSI-3028'));
      await binding.takeScreenshot('retailer-90-sales-book');
      await tapVisible(tester, const Key('sales-row-MSI-3028'));
      expect(find.byKey(const Key('sales-detail-sheet')), findsOneWidget);
      expect(retailer.businessBookRecorded, isTrue);
    },
  );
}
