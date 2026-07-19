import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/retailer/retailer_wholesale_models.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {AxisDirection.down, AxisDirection.up}.contains(
              widget.axisDirection,
            ),
      );
      expect(scrollables, findsWidgets, reason: 'No scrollable for $key');
      final scrollable = tester.state<ScrollableState>(scrollables.last);
      scrollable.position.jumpTo(scrollable.position.minScrollExtent);
      await tester.pump();
      for (
        var attempt = 0;
        attempt < 22 && finder.evaluate().isEmpty;
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
    'physical retailer wholesale order posts one GRN and Purchase Book record',
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
          initialLocation: '/app/retailer/home?view=wholesale',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      await tapVisible(tester, const Key('retailer-wholesale-review'));
      await tapVisible(tester, const Key('wholesale-reorder'));
      expect(retailer.wholesaleCaseCount, 5);
      await binding.takeScreenshot('retailer-81-wholesale-catalogue');

      await tapVisible(tester, const Key('wholesale-open-cart'));
      expect(find.byKey(const Key('wholesale-cart-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-82-wholesale-cart');
      await tapVisible(tester, const Key('wholesale-review-order'));
      await tapVisible(tester, const Key('wholesale-place-orders'));
      expect(retailer.purchaseOrders, hasLength(2));
      expect(
        find.byKey(const Key('wholesale-order-confirmed-screen')),
        findsOneWidget,
      );
      await binding.takeScreenshot('retailer-83-orders-confirmed');

      await tapVisible(tester, const Key('wholesale-track-orders'));
      for (var index = 0; index < 3; index += 1) {
        await tapVisible(
          tester,
          const Key('wholesale-refresh-delivery'),
        );
      }
      expect(
        retailer.selectedPurchaseOrder!.stage,
        RetailerPurchaseOrderStage.delivered,
      );
      await binding.takeScreenshot('retailer-84-delivery-arrived');

      await tapVisible(tester, const Key('wholesale-receive-goods'));
      await tapVisible(tester, const Key('goods-all-received'));
      await binding.takeScreenshot('retailer-85-goods-receipt');
      await tapVisible(tester, const Key('goods-confirm-receipt'));
      await tapVisible(tester, const Key('goods-post-receipt'));
      expect(retailer.goodsReceiptId, 'GRN-85021');
      expect(retailer.acceptedStockPacks, 28);
      expect(
        find.byKey(const Key('goods-receipt-result-screen')),
        findsOneWidget,
      );
      await binding.takeScreenshot('retailer-86-receipt-result');

      await tapVisible(
        tester,
        const Key('receipt-open-purchase-book'),
      );
      expect(find.byKey(const Key('purchase-book-screen')), findsOneWidget);
      await reveal(tester, const Key('purchase-entry-PUR-85021'));
      await binding.takeScreenshot('retailer-87-purchase-book');
      expect(
        retailer.purchases
            .where((purchase) => purchase.grnId == 'GRN-85021'),
        hasLength(1),
      );
    },
  );
}
