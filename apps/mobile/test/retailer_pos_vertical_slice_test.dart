import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_pos_models.dart';
import 'package:moolsocial/features/retailer/retailer_pos_services.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
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
    await session.start();
    return session;
  }

  Future<RetailerSession> mount(
    WidgetTester tester, {
    required String route,
    RetailerSession? retailerSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    final journey = await readyJourney();
    final retailer = retailerSession ?? RetailerSession();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      retailer.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        retailerSession: retailer,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    return retailer;
  }

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
    }
    expect(finder, findsOneWidget, reason: 'Missing input $key');
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

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
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return finder;
  }

  testWidgets(
    'screen 74 to 78 to 80 to 90 completes one counter sale after exact failure replays',
    (tester) async {
      final gateway = ReviewRetailerPosGateway()
        ..failCreateOrder = true
        ..failCompleteSale = true;
      final retailer = RetailerSession(posGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/home',
        retailerSession: retailer,
      );

      await tapVisible(tester, const Key('retailer-new-order'));
      expect(find.byKey(const Key('pos-create-order-screen')), findsOneWidget);
      await tapVisible(tester, const Key('pos-source-counter'));
      expect(retailer.posSource, RetailerOrderSource.counter);

      await tapVisible(tester, const Key('pos-scan-product'));
      await tapVisible(tester, const Key('pos-scan-permission-denied'));
      expect(find.textContaining('Camera access was not allowed'), findsOne);
      await tapVisible(tester, const Key('pos-scan-product'));
      await tapVisible(tester, const Key('pos-scan-success'));
      expect(retailer.posQuantity('salt'), 1);
      expect(retailer.posTotal, 428);

      await tapVisible(tester, const Key('pos-find-customer'));
      expect(find.textContaining('10-digit mobile'), findsOneWidget);
      await tapVisible(tester, const Key('pos-continue-without-customer'));
      expect(retailer.customerMessagingConsent, isFalse);

      await tapVisible(tester, const Key('pos-create-order'));
      expect(find.textContaining('order was not created'), findsOneWidget);
      expect(retailer.posOrderId, isNull);
      await tapVisible(tester, const Key('pos-create-order'));
      expect(find.byKey(const Key('pos-order-created-screen')), findsOneWidget);
      expect(retailer.posOrderId, 'RT-3028');
      expect(gateway.createOrderCalls, 2);
      expect(await retailer.createPosOrder(), isTrue);
      expect(gateway.createOrderCalls, 2);

      await tapVisible(tester, const Key('pos-open-created-order'));
      expect(find.byKey(const Key('counter-sale-screen')), findsOneWidget);
      await tapVisible(tester, const Key('sale-payment-cash'));
      await tapVisible(tester, const Key('sale-complete'));
      expect(find.textContaining('Confirm that ₹428 cash'), findsOneWidget);
      await tapVisible(tester, const Key('sale-confirm-cash'));
      await tapVisible(tester, const Key('sale-complete'));
      expect(find.textContaining('sale was not completed'), findsOneWidget);
      expect(retailer.posInvoiceId, isNull);
      await tapVisible(tester, const Key('sale-complete'));
      expect(
        find.byKey(const Key('counter-sale-complete-screen')),
        findsOneWidget,
      );
      expect(retailer.posInvoiceId, 'MSI-3028');
      expect(gateway.completeSaleCalls, 2);
      expect(
        retailer.sales.where((sale) => sale.invoiceId == 'MSI-3028'),
        hasLength(1),
      );
      expect(await retailer.completePosSale(), isTrue);
      expect(gateway.completeSaleCalls, 2);

      await tapVisible(tester, const Key('sale-share-whatsapp'));
      expect(find.textContaining('Customer consent is required'), findsOne);
      await tapVisible(tester, const Key('sale-customer-consent'));
      gateway.failShareInvoice = true;
      await tapVisible(tester, const Key('sale-share-whatsapp'));
      expect(find.textContaining('invoice was not sent'), findsOneWidget);
      await tapVisible(tester, const Key('sale-share-whatsapp'));
      expect(find.textContaining('sent by WhatsApp'), findsOneWidget);
      expect(gateway.shareInvoiceCalls, 2);
      await tapVisible(tester, const Key('sale-view-invoice'));
      expect(find.byKey(const Key('sale-invoice-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('sale-invoice-sheet-close'));

      await tapVisible(tester, const Key('sale-done'));
      expect(find.byKey(const Key('sales-book-screen')), findsOneWidget);
      expect(find.byKey(const Key('sales-row-MSI-3028')), findsOneWidget);
      expect(retailer.businessBookRecorded, isTrue);
    },
  );

  testWidgets(
    'order builder covers empty cancel search repeat voice stock limit and offline retry',
    (tester) async {
      final retailer = await mount(
        tester,
        route: '/app/retailer/orders/new?source=counter',
      );

      await tapVisible(tester, const Key('pos-clear-bill'));
      expect(find.byKey(const Key('pos-clear-bill-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('pos-cancel-clear-bill'));
      expect(retailer.posItemCount, 2);
      await tapVisible(tester, const Key('pos-clear-bill'));
      await tapVisible(tester, const Key('pos-confirm-clear-bill'));
      expect(find.byKey(const Key('pos-empty-bill')), findsOneWidget);
      await tapVisible(tester, const Key('pos-create-order'));
      expect(find.textContaining('Add at least one'), findsOneWidget);

      await enter(tester, const Key('pos-product-search'), 'not stocked');
      expect(find.byKey(const Key('pos-products-empty')), findsOneWidget);
      await tapVisible(tester, const Key('pos-products-empty-action'));
      await tapVisible(tester, const Key('pos-repeat-basket'));
      await tapVisible(tester, const Key('pos-use-last-basket'));
      expect(retailer.posItemCount, 4);
      await tapVisible(tester, const Key('pos-voice-product'));
      await tapVisible(tester, const Key('pos-voice-permission-denied'));
      expect(
        find.textContaining('Microphone access was not allowed'),
        findsOne,
      );
      await tapVisible(tester, const Key('pos-voice-product'));
      await tapVisible(tester, const Key('pos-voice-success'));
      expect(retailer.posQuantity('atta'), 3);

      for (var index = 0; index < 20; index += 1) {
        retailer.adjustPosQuantity('oil', 1);
      }
      await tester.pumpAndSettle();
      expect(retailer.posQuantity('oil'), 8);
      expect(find.textContaining('limited to 8 available'), findsOneWidget);

      retailer.setPosConnectivity(false);
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('pos-create-order'));
      expect(find.textContaining('offline'), findsWidgets);
      retailer.setPosConnectivity(true);
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('pos-create-order'));
      expect(retailer.posOrderId, 'RT-3028');
    },
  );

  testWidgets(
    'phone and Chat branches keep identity payment and open the exact created order',
    (tester) async {
      final retailer = await mount(
        tester,
        route: '/app/retailer/orders/new?source=phone',
      );
      expect(retailer.posSource, RetailerOrderSource.phone);
      await reveal(tester, const Key('pos-payment-pay-request'));
      expect(find.byKey(const Key('pos-payment-pay-request')), findsOneWidget);
      await tapVisible(tester, const Key('pos-source-chat'));
      expect(retailer.posSource, RetailerOrderSource.chat);
      expect(find.textContaining('Order-linked Chat'), findsOneWidget);
      await tapVisible(tester, const Key('pos-create-order'));
      expect(retailer.orders.first.id, 'RT-3028');
      await tapVisible(tester, const Key('pos-open-created-order'));
      expect(
        find.byKey(const Key('retailer-order-review-screen')),
        findsOneWidget,
      );
      expect(retailer.selectedOrder?.id, 'RT-3028');
    },
  );

  testWidgets(
    'counter create edit close open covers invalid duplicate cancel failure and retry',
    (tester) async {
      final gateway = ReviewRetailerPosGateway()..failSaveCounter = true;
      final retailer = RetailerSession(posGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/pos/counters',
        retailerSession: retailer,
      );

      await tapVisible(tester, const Key('counter-add'));
      await tapVisible(tester, const Key('counter-save'));
      expect(find.textContaining('Enter a clear counter purpose'), findsOne);
      await enter(tester, const Key('counter-purpose'), 'Main Billing');
      await tapVisible(tester, const Key('counter-save'));
      expect(find.textContaining('already exists'), findsOneWidget);
      await enter(tester, const Key('counter-purpose'), 'Returns Desk');
      await enter(tester, const Key('counter-operator'), 'Kavita');
      await tapVisible(tester, const Key('counter-save'));
      expect(find.textContaining('counter was not saved'), findsOneWidget);
      expect(retailer.counters, hasLength(3));
      await tapVisible(tester, const Key('counter-save'));
      expect(retailer.counters, hasLength(4));
      expect(retailer.activeCounter.purpose, 'Returns Desk');
      expect(gateway.saveCounterCalls, 2);

      await tapVisible(tester, const Key('counter-add'));
      await tapVisible(tester, const Key('counter-cancel-editor'));
      expect(retailer.counters, hasLength(4));

      await tapVisible(tester, const Key('counter-edit'));
      await enter(tester, const Key('counter-purpose'), 'Returns');
      await tapVisible(tester, const Key('counter-save'));
      expect(retailer.activeCounter.purpose, 'Returns');
      expect(retailer.activeCounter.operatorName, 'Kavita');

      gateway.failToggleCounter = true;
      await tapVisible(tester, const Key('counter-toggle'));
      expect(find.textContaining('previous state remains'), findsOneWidget);
      expect(retailer.activeCounter.isOpen, isTrue);
      await tapVisible(tester, const Key('counter-toggle'));
      expect(retailer.activeCounter.isOpen, isFalse);
      await tapVisible(tester, const Key('counter-primary-action'));
      expect(retailer.activeCounter.isOpen, isTrue);
      expect(find.byKey(const Key('pos-create-order-screen')), findsOneWidget);
      expect(gateway.toggleCounterCalls, 3);
    },
  );

  testWidgets(
    'counter selector alerts and empty activity retain selected operating context',
    (tester) async {
      final retailer = await mount(tester, route: '/app/retailer/pos/counters');
      await tapVisible(tester, const Key('counter-alerts'));
      expect(find.byKey(const Key('counter-alerts-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('counter-alert-CTR-03'));
      expect(retailer.activeCounterId, 'CTR-03');
      await reveal(tester, const Key('counter-empty-activity'));
      expect(find.text('No orders today'), findsOneWidget);
      await tapVisible(tester, const Key('counter-edit'));
      await tapVisible(tester, const Key('counter-open-now'));
      await tapVisible(tester, const Key('counter-save'));
      expect(retailer.activeCounter.isOpen, isTrue);
      await tapVisible(tester, const Key('counter-primary-action'));
      expect(retailer.activeCounterId, 'CTR-03');
      expect(retailer.posSource, RetailerOrderSource.counter);
    },
  );

  testWidgets(
    'Sales Book tests tabs filters search details invoice sharing and new-sale routes',
    (tester) async {
      final retailer = await mount(tester, route: '/app/retailer/books/sales');

      await tapVisible(tester, const Key('sales-book-period'));
      expect(find.byKey(const Key('sales-period-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('sales-period-sheet-close'));
      await tapVisible(tester, const Key('sales-book-attention'));
      expect(retailer.salesBookView, RetailerSalesBookView.payments);
      expect(find.byKey(const Key('sales-row-INV-MS-4106')), findsOneWidget);
      await tapVisible(tester, const Key('sales-tab-returns'));
      expect(find.byKey(const Key('sales-row-INV-MS-4101')), findsOneWidget);
      await tapVisible(tester, const Key('sales-filter-due'));
      expect(find.byKey(const Key('sales-book-empty')), findsOneWidget);
      await tapVisible(tester, const Key('sales-book-empty-action'));
      await tapVisible(tester, const Key('sales-tab-sales'));

      await enter(tester, const Key('sales-book-search'), 'INV-MS-4107');
      expect(find.byKey(const Key('sales-row-INV-MS-4107')), findsOneWidget);
      await tapVisible(tester, const Key('sales-row-INV-MS-4107'));
      expect(find.byKey(const Key('sales-detail-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('sales-view-invoice'));
      expect(find.byKey(const Key('sales-invoice-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('sales-invoice-sheet-close'));

      await tapVisible(tester, const Key('sales-row-INV-MS-4107'));
      await tapVisible(tester, const Key('sales-share-receipt'));
      expect(find.byKey(const Key('sales-share-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('sales-share-whatsapp'));
      expect(find.textContaining('WhatsApp delivery'), findsOneWidget);

      await tapVisible(tester, const Key('sales-book-new-sale'));
      await tapVisible(tester, const Key('sales-new-phone'));
      expect(find.byKey(const Key('pos-create-order-screen')), findsOneWidget);
      expect(retailer.posSource, RetailerOrderSource.phone);
    },
  );

  testWidgets(
    'Sales Book refresh export offline and permission outcomes preserve records',
    (tester) async {
      final gateway = ReviewRetailerPosGateway()
        ..failRefreshSales = true
        ..failExport = true;
      final retailer = RetailerSession(posGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/books/sales',
        retailerSession: retailer,
      );
      final originalCount = retailer.sales.length;

      await tapVisible(tester, const Key('sales-book-refresh'));
      expect(gateway.refreshSalesCalls, 1);
      expect(retailer.errorMessage, contains('could not refresh'));
      expect(find.textContaining('could not refresh'), findsOneWidget);
      expect(retailer.sales, hasLength(originalCount));
      await tapVisible(tester, const Key('sales-book-refresh'));
      expect(find.textContaining('Sales Book is current'), findsOneWidget);
      expect(gateway.refreshSalesCalls, 2);

      await tapVisible(tester, const Key('sales-book-export'));
      await tapVisible(tester, const Key('sales-export-gst'));
      expect(find.textContaining('export was not created'), findsOneWidget);
      expect(retailer.lastExportFormat, isNull);
      await tapVisible(tester, const Key('sales-export-gst'));
      expect(retailer.lastExportFormat, 'GST-ready export');
      expect(gateway.exportCalls, 2);

      retailer.setPosConnectivity(false);
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('sales-book-refresh'));
      expect(find.textContaining('Sales Book is offline'), findsOneWidget);
      expect(gateway.refreshSalesCalls, 2);
    },
  );

  testWidgets('Sales Book unauthorized role has one safe return action', (
    tester,
  ) async {
    final retailer = RetailerSession()..businessBookAuthorized = false;
    await mount(
      tester,
      route: '/app/retailer/books/sales',
      retailerSession: retailer,
    );
    expect(find.byKey(const Key('sales-book-unauthorized')), findsOneWidget);
    expect(find.byKey(const Key('sales-book-export')), findsOneWidget);
    await tapVisible(tester, const Key('sales-book-permission-blocked-action'));
    expect(find.byKey(const Key('retailer-home-screen')), findsOneWidget);
  });

  testWidgets(
    'loading states disable duplicate order and sale actions while requests run',
    (tester) async {
      final retailer = await mount(
        tester,
        route: '/app/retailer/orders/new?source=counter',
      );
      final createFinder = find.byKey(const Key('pos-create-order'));
      await tester.ensureVisible(createFinder);
      await tester.tap(createFinder);
      await tester.pump(const Duration(milliseconds: 2));
      expect(retailer.busy, isTrue);
      final createButton = tester.widget<FilledButton>(createFinder);
      expect(createButton.onPressed, isNull);
      await tester.pumpAndSettle();
      expect(retailer.posGateway.createOrderCalls, 1);

      await tapVisible(tester, const Key('pos-open-created-order'));
      final saleFinder = await reveal(tester, const Key('sale-complete'));
      await tester.tap(saleFinder);
      await tester.pump(const Duration(milliseconds: 2));
      expect(retailer.busy, isTrue);
      await tester.pumpAndSettle();
      expect(retailer.posGateway.completeSaleCalls, 1);
    },
  );

  testWidgets(
    'POS and Sales Book remain usable at compact width and larger text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.35;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await mount(
        tester,
        route: '/app/retailer/orders/new?source=counter',
        size: const Size(360, 800),
      );
      for (final key in const [
        Key('pos-source-counter'),
        Key('pos-source-phone'),
        Key('pos-source-chat'),
        Key('pos-product-search'),
        Key('pos-scan-product'),
        Key('pos-voice-product'),
        Key('pos-repeat-basket'),
        Key('pos-create-order'),
        Key('retailer-dock-mool'),
        Key('retailer-dock-orders'),
        Key('retailer-dock-stock'),
        Key('retailer-dock-wholesale'),
        Key('retailer-dock-chat'),
      ]) {
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
          await tester.drag(scrollables.last, const Offset(0, 900));
          await tester.pumpAndSettle();
          for (
            var attempt = 0;
            attempt < 18 && finder.evaluate().isEmpty;
            attempt += 1
          ) {
            await tester.drag(scrollables.last, const Offset(0, -300));
            await tester.pumpAndSettle();
          }
        }
        expect(finder, findsOneWidget, reason: 'Missing $key');
      }
      expect(tester.takeException(), isNull);
    },
  );
}
