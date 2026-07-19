import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/manufacturer/manufacturer_services.dart';
import 'package:moolsocial/features/manufacturer/manufacturer_session.dart';

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
    'physical manufacturer completes exact failed taps through sale, supply, dispatch, growth and service',
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
      final gateway = ReviewManufacturerGateway()
        ..failSupply = true
        ..failProduct = true
        ..failOrder = true
        ..failPurchase = true
        ..failDispatch = true
        ..failCampaign = true
        ..failService = true;
      final manufacturer = ManufacturerSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(manufacturer.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          manufacturerSession: manufacturer,
          initialLocation: '/app/manufacturer',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manufacturer-home-screen')), findsOneWidget);
      await binding.takeScreenshot('manufacturer-107-home');
      await tapVisible(tester, const Key('manufacturer-supply-toggle'));
      expect(manufacturer.supplyOn, isTrue);
      await tapVisible(tester, const Key('manufacturer-supply-toggle'));
      expect(manufacturer.supplyOn, isFalse);
      expect(gateway.supplyCalls, 2);

      await openRoute(tester, '/app/manufacturer/catalogue?mode=master');
      await tapVisible(tester, const Key('manufacturer-product-masala-tea'));
      await enter(tester, const Key('manufacturer-product-quantity'), '100');
      await enter(tester, const Key('manufacturer-product-price'), '188');
      await enter(tester, const Key('manufacturer-product-moq'), '20');
      await tapVisible(tester, const Key('manufacturer-product-input-map'));
      await tapVisible(tester, const Key('manufacturer-product-publish'));
      expect(manufacturer.productPublishedId, isNull);
      await tapVisible(tester, const Key('manufacturer-product-publish'));
      expect(manufacturer.productPublishedId, 'SKU-109-0719');
      expect(gateway.productCalls, 2);
      await binding.takeScreenshot('manufacturer-109-product-published');

      await openRoute(tester, '/app/manufacturer/orders/review');
      await tapVisible(tester, const Key('manufacturer-order-confirm'));
      expect(manufacturer.orderConfirmationId, isNull);
      await tapVisible(tester, const Key('manufacturer-order-confirm'));
      expect(manufacturer.orderConfirmationId, 'CONF-110-4821');
      expect(gateway.orderCalls, 2);
      await binding.takeScreenshot('manufacturer-110-order-confirmed');

      await openRoute(tester, '/app/manufacturer/purchases');
      await tapVisible(tester, const Key('manufacturer-input-add-oil-bulk'));
      await tapVisible(tester, const Key('manufacturer-purchase-tab-cart'));
      await tapVisible(tester, const Key('manufacturer-place-po'));
      expect(manufacturer.purchaseOrderId, isNull);
      await tapVisible(tester, const Key('manufacturer-place-po'));
      expect(manufacturer.purchaseOrderId, 'PO-IN-111-0719');
      expect(gateway.purchaseCalls, 2);
      await tapVisible(tester, const Key('manufacturer-purchase-receipt'));
      expect(manufacturer.purchaseReceiptId, 'GRN-111-0719');

      await openRoute(tester, '/app/manufacturer/dispatch');
      await tapVisible(tester, const Key('manufacturer-document-lr'));
      await tapVisible(tester, const Key('manufacturer-dispatch-confirm'));
      expect(manufacturer.dispatchId, isNull);
      await tapVisible(tester, const Key('manufacturer-dispatch-confirm'));
      expect(manufacturer.dispatchId, 'DSP-112-4821');
      expect(gateway.dispatchCalls, 2);
      await tapVisible(tester, const Key('manufacturer-mark-delivered'));
      await tapVisible(tester, const Key('manufacturer-delivery-receipt'));
      expect(manufacturer.deliveryReceiptId, 'POD-112-4821');
      await binding.takeScreenshot('manufacturer-112-delivery-complete');

      await openRoute(tester, '/app/manufacturer/growth?tab=campaigns');
      await tapVisible(tester, const Key('manufacturer-growth-create'));
      await tapVisible(tester, const Key('manufacturer-campaign-publish'));
      expect(manufacturer.campaignReviewed, isTrue);
      await tapVisible(tester, const Key('manufacturer-campaign-publish'));
      expect(manufacturer.campaignId, isNull);
      await tapVisible(tester, const Key('manufacturer-campaign-publish'));
      expect(manufacturer.campaignId, 'MFG-CMP-113-0719');
      expect(gateway.campaignCalls, 2);

      await openRoute(tester, '/app/manufacturer/services');
      await tapVisible(tester, const Key('manufacturer-service-sales'));
      await tapVisible(tester, const Key('manufacturer-service-terms'));
      await tapVisible(tester, const Key('manufacturer-service-request'));
      expect(manufacturer.serviceRequestId, isNull);
      await tapVisible(tester, const Key('manufacturer-service-request'));
      expect(manufacturer.serviceRequestId, 'MFG-SVC-115-0719');
      expect(gateway.serviceCalls, 2);
      await binding.takeScreenshot('manufacturer-115-service-requested');
    },
  );
}
