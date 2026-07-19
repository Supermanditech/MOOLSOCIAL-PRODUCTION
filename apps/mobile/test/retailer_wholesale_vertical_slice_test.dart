import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/retailer/retailer_wholesale_models.dart';
import 'package:moolsocial/features/retailer/retailer_wholesale_services.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

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
    double textScale = 1,
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
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MoolSocialApp(
          key: UniqueKey(),
          session: journey,
          retailerSession: retailer,
          initialLocation: route,
        ),
      ),
    );
    await settle(tester);
    return retailer;
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
        attempt < 24 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        scrollable.position.jumpTo(
          (scrollable.position.pixels + 280).clamp(
            scrollable.position.minScrollExtent,
            scrollable.position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await settle(tester);
    return finder;
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = await reveal(tester, key);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = await reveal(tester, key);
    await tester.enterText(finder, value);
    await settle(tester);
  }

  Future<void> dismissSheet(WidgetTester tester) async {
    if (find.byKey(const Key('wholesale-sheet')).evaluate().isNotEmpty) {
      await tester.tapAt(const Offset(8, 90));
      await settle(tester);
    }
  }

  testWidgets(
    'screens 74 and 81 to 86 complete wholesale order and receipt after exact failure replays',
    (tester) async {
      final gateway = ReviewRetailerWholesaleGateway()
        ..failPlaceOrders = true
        ..failRefreshDelivery = true
        ..failPostReceipt = true;
      final retailer = RetailerSession(wholesaleGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/home?view=wholesale',
        retailerSession: retailer,
      );

      await tapVisible(tester, const Key('retailer-wholesale-review'));
      expect(find.byKey(const Key('wholesale-catalog-screen')), findsOneWidget);

      await enter(tester, const Key('wholesale-search'), 'not available');
      expect(find.byKey(const Key('wholesale-empty')), findsOneWidget);
      await tapVisible(tester, const Key('wholesale-clear-search'));
      await tapVisible(tester, const Key('wholesale-category-credit'));
      expect(
        find.byKey(const Key('wholesale-product-tea-case')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('wholesale-category-all'));

      await tapVisible(tester, const Key('wholesale-scan'));
      await tapVisible(tester, const Key('wholesale-scan-denied'));
      expect(find.textContaining('Camera access was not allowed'), findsOne);
      await tapVisible(tester, const Key('wholesale-scan'));
      await tapVisible(tester, const Key('wholesale-scan-success'));
      expect(retailer.wholesaleSearchQuery, 'Tata Premium Tea');
      await tapVisible(tester, const Key('wholesale-clear-search'));

      await tapVisible(tester, const Key('wholesale-product-details-oil-case'));
      expect(find.textContaining('Complete buying'), findsOneWidget);
      await dismissSheet(tester);
      await tapVisible(tester, const Key('wholesale-reorder'));
      expect(retailer.wholesaleCaseCount, 5);
      await tapVisible(tester, const Key('wholesale-open-cart'));
      expect(find.byKey(const Key('wholesale-cart-screen')), findsOneWidget);

      await tapVisible(tester, const Key('wholesale-cart-terms-oil-case'));
      await dismissSheet(tester);
      await tapVisible(tester, const Key('wholesale-address'));
      await dismissSheet(tester);
      await tapVisible(tester, const Key('wholesale-gst'));
      await dismissSheet(tester);
      await tapVisible(tester, const Key('wholesale-save-cart'));
      expect(find.textContaining('cart saved'), findsOneWidget);

      await tapVisible(tester, const Key('wholesale-review-order'));
      await tapVisible(tester, const Key('wholesale-cancel-place'));
      expect(retailer.purchaseOrders, isEmpty);
      await tapVisible(tester, const Key('wholesale-review-order'));
      await tapVisible(tester, const Key('wholesale-place-orders'));
      expect(find.textContaining('were not placed'), findsOneWidget);
      expect(retailer.wholesaleCaseCount, 5);
      await tapVisible(tester, const Key('wholesale-review-order'));
      await tapVisible(tester, const Key('wholesale-place-orders'));
      expect(
        find.byKey(const Key('wholesale-order-confirmed-screen')),
        findsOneWidget,
      );
      expect(retailer.purchaseOrders, hasLength(2));
      expect(gateway.placeOrderCalls, 2);
      expect(await retailer.placeWholesaleOrders(), isTrue);
      expect(gateway.placeOrderCalls, 2);

      await tapVisible(
        tester,
        Key('purchase-order-view-${retailer.purchaseOrders.first.id}'),
      );
      expect(find.textContaining('Not added yet'), findsOneWidget);
      await dismissSheet(tester);
      await tapVisible(tester, const Key('wholesale-track-orders'));
      expect(find.byKey(const Key('wholesale-tracking-screen')), findsOne);

      await tapVisible(tester, const Key('delivery-call'));
      await tapVisible(tester, const Key('delivery-start-call'));
      expect(find.textContaining('Calling the verified'), findsOneWidget);
      await tapVisible(tester, const Key('delivery-chat'));
      await tapVisible(tester, const Key('delivery-open-chat'));
      expect(find.textContaining('chat opened'), findsOneWidget);
      await tapVisible(tester, const Key('delivery-report-delay'));
      await tapVisible(tester, const Key('delivery-problem-not-dispatched'));
      expect(find.textContaining('settlement remains protected'), findsOne);

      await tapVisible(tester, const Key('wholesale-refresh-delivery'));
      expect(find.textContaining('could not refresh'), findsOneWidget);
      for (var index = 0; index < 3; index += 1) {
        await tapVisible(tester, const Key('wholesale-refresh-delivery'));
      }
      expect(
        retailer.selectedPurchaseOrder!.stage,
        RetailerPurchaseOrderStage.delivered,
      );
      await tapVisible(tester, const Key('wholesale-receive-goods'));
      expect(find.byKey(const Key('goods-receipt-screen')), findsOneWidget);

      await tapVisible(tester, const Key('goods-report-issue'));
      await tapVisible(tester, const Key('goods-issue-shortQuantity'));
      await tapVisible(tester, const Key('goods-evidence-denied'));
      expect(find.textContaining('Camera access was not allowed'), findsOne);
      await tapVisible(tester, const Key('goods-attach-evidence'));
      expect(retailer.goodsEvidenceAttached, isTrue);
      await tapVisible(tester, const Key('goods-confirm-receipt'));
      await tapVisible(tester, const Key('goods-cancel-receipt'));
      expect(retailer.goodsReceiptId, isNull);
      await tapVisible(tester, const Key('goods-confirm-receipt'));
      await tapVisible(tester, const Key('goods-post-receipt'));
      expect(find.textContaining('was not posted'), findsOneWidget);
      await tapVisible(tester, const Key('goods-confirm-receipt'));
      await tapVisible(tester, const Key('goods-post-receipt'));
      expect(
        find.byKey(const Key('goods-receipt-result-screen')),
        findsOneWidget,
      );
      expect(retailer.goodsReceiptId, 'GRN-85021');
      expect(retailer.acceptedStockPacks, 24);
      expect(gateway.postReceiptCalls, 2);
      expect(await retailer.postGoodsReceipt(), isTrue);
      expect(gateway.postReceiptCalls, 2);
      expect(retailer.acceptedStockPacks, 24);
    },
  );

  testWidgets(
    'screen 87 covers Purchase Book views, empty, direct bill and export retry',
    (tester) async {
      final gateway = ReviewRetailerWholesaleGateway()
        ..failExportPurchases = true
        ..failRefreshPurchases = true;
      final retailer = RetailerSession(wholesaleGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/books/purchases',
        retailerSession: retailer,
      );

      expect(find.byKey(const Key('purchase-book-screen')), findsOneWidget);
      await enter(tester, const Key('purchase-search'), 'missing');
      expect(find.byKey(const Key('purchase-book-empty')), findsOneWidget);
      await tapVisible(tester, const Key('purchase-clear-search'));
      await tapVisible(tester, const Key('purchase-filter-direct'));
      expect(find.text('Jodhpur Dairy Supply'), findsOneWidget);
      await tapVisible(tester, const Key('purchase-filter-all'));

      await tapVisible(tester, const Key('purchase-actions'));
      await tapVisible(tester, const Key('purchase-attention-due'));
      expect(retailer.purchaseBookView, RetailerPurchaseBookView.payables);
      retailer.setPurchaseBookView(RetailerPurchaseBookView.purchases);
      await settle(tester);

      await tapVisible(tester, const Key('purchase-add-bill'));
      await tapVisible(tester, const Key('purchase-scan-invoice'));
      await tapVisible(tester, const Key('purchase-confirm-extracted'));
      expect(find.textContaining('Purchase added'), findsOneWidget);

      await tapVisible(tester, const Key('purchase-period'));
      await tapVisible(tester, const Key('purchase-period-jun-2026'));
      expect(find.textContaining('Jun 2026'), findsOneWidget);

      await tapVisible(tester, const Key('purchase-book-tools'));
      await tapVisible(tester, const Key('purchase-tool-export'));
      await tapVisible(tester, const Key('purchase-export-pdf'));
      expect(find.textContaining('was not created'), findsOneWidget);
      await tapVisible(tester, const Key('purchase-book-tools'));
      await tapVisible(tester, const Key('purchase-tool-export'));
      await tapVisible(tester, const Key('purchase-export-pdf'));
      expect(retailer.lastPurchaseExport, 'PDF');
      expect(gateway.exportPurchaseCalls, 2);

      var refresh = retailer.refreshPurchaseBook();
      await tester.pump(const Duration(milliseconds: 30));
      expect(await refresh, isFalse);
      expect(find.textContaining('could not refresh'), findsOneWidget);
      refresh = retailer.refreshPurchaseBook();
      await tester.pump(const Duration(milliseconds: 30));
      expect(await refresh, isTrue);
      expect(gateway.refreshPurchaseCalls, 2);
    },
  );

  testWidgets(
    'screens 87 to 89 authorize once and distinguish processing from settlement',
    (tester) async {
      final gateway = ReviewRetailerWholesaleGateway()
        ..failAuthorizePayment = true
        ..failRefreshPayment = true;
      final retailer = RetailerSession(wholesaleGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/books/purchases',
        retailerSession: retailer,
      );

      await tapVisible(tester, const Key('purchase-entry-PUR-8178'));
      await tapVisible(tester, const Key('purchase-detail-pay'));
      expect(find.byKey(const Key('supplier-bill-screen')), findsOneWidget);
      await tapVisible(tester, const Key('supplier-detail'));
      await dismissSheet(tester);
      await tapVisible(tester, const Key('supplier-view-invoice'));
      await dismissSheet(tester);
      await tapVisible(tester, const Key('supplier-match-po'));
      expect(
        find.text('PO is matched with no quantity or amount difference.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('supplier-report-issue'));
      await tapVisible(tester, const Key('supplier-issue-wrong-amount'));
      expect(find.textContaining('on hold'), findsOneWidget);
      await tapVisible(tester, const Key('supplier-bill-tools'));
      await tapVisible(tester, const Key('supplier-tool-external'));
      expect(find.textContaining('no transfer'), findsOneWidget);

      await tapVisible(tester, const Key('supplier-review-payment'));
      await tapVisible(tester, const Key('supplier-cancel-payment'));
      expect(retailer.supplierPaymentId, isNull);
      await tapVisible(tester, const Key('supplier-review-payment'));
      await tester.tap(find.text('Bank transfer').last);
      await settle(tester);
      await tapVisible(tester, const Key('supplier-authorize-payment'));
      expect(find.textContaining('not authorized'), findsOneWidget);
      await tapVisible(tester, const Key('supplier-review-payment'));
      await tapVisible(tester, const Key('supplier-authorize-payment'));
      expect(
        find.byKey(const Key('supplier-payment-status-screen')),
        findsOneWidget,
      );
      expect(
        retailer.supplierPaymentState,
        RetailerSupplierPaymentState.processing,
      );
      expect(gateway.authorizePaymentCalls, 2);
      expect(await retailer.authorizeSupplierPayment(), isTrue);
      expect(gateway.authorizePaymentCalls, 2);

      await tapVisible(tester, const Key('supplier-status-receipt'));
      expect(find.textContaining('acknowledgement'), findsOneWidget);
      await tapVisible(tester, const Key('supplier-refresh-payment'));
      expect(find.textContaining('could not refresh'), findsOneWidget);
      await tapVisible(tester, const Key('supplier-refresh-payment'));
      expect(
        retailer.supplierPaymentState,
        RetailerSupplierPaymentState.settled,
      );
      await reveal(tester, const Key('supplier-payment-state'));
      expect(find.text('Payment settled'), findsOneWidget);
      expect(gateway.refreshPaymentCalls, 2);
      await tapVisible(tester, const Key('supplier-status-receipt'));
      expect(find.textContaining('Final payment receipt'), findsOneWidget);
      await tapVisible(tester, const Key('supplier-open-purchase-book'));
      expect(find.byKey(const Key('purchase-book-screen')), findsOneWidget);
      expect(find.text('PAID'), findsWidgets);
    },
  );

  testWidgets(
    'invalid, empty, stock-limit, offline and role-denied states remain safe',
    (tester) async {
      final retailer = RetailerSession();
      await mount(
        tester,
        route: '/app/retailer/wholesale',
        retailerSession: retailer,
      );

      expect(await retailer.placeWholesaleOrders(), isFalse);
      await tester.pump();
      expect(find.textContaining('Add at least one'), findsOneWidget);
      for (var index = 0; index < 10; index += 1) {
        retailer.changeWholesaleQuantity('tea-case', 1);
      }
      await tester.pump();
      expect(retailer.wholesaleQuantity('tea-case'), 9);
      expect(find.textContaining('Only 9 cases'), findsOneWidget);

      retailer.setWholesaleOnline(false);
      expect(await retailer.placeWholesaleOrders(), isFalse);
      await tester.pump();
      expect(retailer.purchaseOrders, isEmpty);
      retailer.chooseGoodsReceipt(RetailerGoodsReceiptChoice.accepted);
      expect(await retailer.postGoodsReceipt(), isFalse);
      await tester.pump();
      expect(retailer.goodsReceiptId, isNull);
      retailer.purchaseBookAuthorized = false;
      await settle(tester);
      expect(await retailer.exportPurchaseBook('CSV'), isFalse);
      await tester.pump();
      expect(retailer.lastPurchaseExport, isNull);
    },
  );

  testWidgets('role denied Purchase Book exposes a safe return', (
    tester,
  ) async {
    final retailer = RetailerSession()..purchaseBookAuthorized = false;
    await mount(
      tester,
      route: '/app/retailer/books/purchases',
      retailerSession: retailer,
    );
    expect(find.byKey(const Key('purchase-book-role-denied')), findsOneWidget);
    await tapVisible(tester, const Key('purchase-book-role-denied-action'));
    expect(find.byKey(const Key('retailer-home-screen')), findsOneWidget);
  });

  for (final paymentState in [
    RetailerSupplierPaymentState.failed,
    RetailerSupplierPaymentState.reversed,
  ]) {
    testWidgets(
      '${paymentState.name} supplier payment restores truthful payable outcome',
      (tester) async {
        final gateway = ReviewRetailerWholesaleGateway()
          ..nextPaymentState = paymentState;
        final retailer = RetailerSession(wholesaleGateway: gateway);
        await mount(
          tester,
          route: '/app/retailer/supplier-payments/PAY-RTD-2568/status',
          retailerSession: retailer,
        );
        final authorization = retailer.authorizeSupplierPayment();
        await tester.pump(const Duration(milliseconds: 30));
        expect(await authorization, isTrue);
        await tester.pump();
        await tapVisible(tester, const Key('supplier-refresh-payment'));
        expect(retailer.supplierPaymentState, paymentState);
        expect(
          find.text(
            paymentState == RetailerSupplierPaymentState.failed
                ? 'Payment failed'
                : 'Payment reversed',
          ),
          findsOneWidget,
        );
        expect(
          retailer.purchases
              .firstWhere((purchase) => purchase.invoiceId == 'INV-RTD-665')
              .status,
          contains('Due'),
        );
      },
    );
  }

  testWidgets(
    'wholesale journey remains usable on compact width with larger text',
    (tester) async {
      final retailer = RetailerSession();
      await mount(
        tester,
        route: '/app/retailer/wholesale',
        retailerSession: retailer,
        size: const Size(360, 720),
        textScale: 1.25,
      );
      expect(tester.takeException(), isNull);
      await tapVisible(tester, const Key('wholesale-reorder'));
      await tapVisible(tester, const Key('wholesale-open-cart'));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('wholesale-cart-screen')), findsOneWidget);
    },
  );
}
