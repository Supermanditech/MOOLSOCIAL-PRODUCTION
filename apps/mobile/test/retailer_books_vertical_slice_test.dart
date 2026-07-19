import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_books_models.dart';
import 'package:moolsocial/features/retailer/retailer_books_services.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  Future<T> completeFuture<T>(WidgetTester tester, Future<T> future) async {
    await tester.pump(const Duration(milliseconds: 40));
    final result = await future;
    await settle(tester);
    return result;
  }

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
        attempt < 30 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        scrollable.position.jumpTo(
          (scrollable.position.pixels + 260).clamp(
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
    'screen 92 completes position, period, attention, guidance, tax and reports with exact failure replay',
    (tester) async {
      final gateway = ReviewRetailerBooksGateway()
        ..failRefreshBook = true
        ..failExportBook = true;
      final retailer = RetailerSession(booksGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/books',
        retailerSession: retailer,
      );

      expect(find.byKey(const Key('business-book-screen')), findsOneWidget);
      expect(find.textContaining('working estimate'), findsWidgets);

      await tapVisible(tester, const Key('business-position'));
      expect(find.text('Estimated operating profit'), findsOneWidget);
      await dismissSheet(tester);

      await tapVisible(tester, const Key('business-period'));
      await tapVisible(tester, const Key('business-period-custom'));
      expect(find.byKey(const Key('custom-period-sheet')), findsOneWidget);
      await enter(tester, const Key('custom-period-start'), '01/07/2026');
      await tapVisible(tester, const Key('custom-period-apply'));
      expect(find.byKey(const Key('custom-period-error')), findsOneWidget);
      await enter(tester, const Key('custom-period-end'), '19/07/2026');
      await tapVisible(tester, const Key('custom-period-apply'));
      expect(retailer.businessPeriod, RetailerBusinessPeriod.custom);

      await tapVisible(tester, const Key('business-attention'));
      await tapVisible(tester, const Key('business-match-payment'));
      expect(retailer.matchedCustomerPaymentId, 'PH-1182');
      retailer.matchCustomerPayment();
      await settle(tester);
      expect(find.textContaining('already matched'), findsOneWidget);

      await tapVisible(tester, const Key('business-ask'));
      await tapVisible(tester, const Key('business-question-collect'));
      expect(find.textContaining('Collect ₹3,200'), findsOneWidget);

      await tapVisible(tester, const Key('business-tax-summary'));
      expect(find.text('Not filed'), findsOneWidget);
      await dismissSheet(tester);

      expect(
        await completeFuture(tester, retailer.refreshBusinessBook()),
        isFalse,
      );
      expect(find.textContaining('could not refresh'), findsOneWidget);
      expect(
        await completeFuture(tester, retailer.refreshBusinessBook()),
        isTrue,
      );
      expect(gateway.refreshBookCalls, 2);

      await tapVisible(tester, const Key('business-book-reports'));
      await tapVisible(tester, const Key('business-export-pdf'));
      expect(find.textContaining('report was not created'), findsOneWidget);
      await tapVisible(tester, const Key('business-book-reports'));
      await tapVisible(tester, const Key('business-export-pdf'));
      expect(retailer.lastBusinessExport, 'PDF');
      expect(gateway.exportBookCalls, 2);
    },
  );

  testWidgets(
    'screen 91 completes search, every filter, movement, checks and one audited adjustment after failure',
    (tester) async {
      final gateway = ReviewRetailerBooksGateway()
        ..failRefreshStock = true
        ..failAdjustStock = true
        ..failExportStock = true;
      final retailer = RetailerSession(booksGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/books/stock',
        retailerSession: retailer,
      );

      expect(find.byKey(const Key('stock-statement-screen')), findsOneWidget);
      await enter(
        tester,
        const Key('stock-statement-search'),
        'unlisted barcode',
      );
      expect(find.byKey(const Key('stock-statement-empty')), findsOneWidget);
      await tapVisible(tester, const Key('stock-statement-clear-search'));

      for (final type in RetailerStockMovementType.values) {
        await tapVisible(tester, Key('stock-filter-${type.name}'));
        expect(retailer.stockMovementFilter, type);
      }
      await tapVisible(tester, const Key('stock-filter-all'));
      expect(retailer.stockMovementFilter, isNull);

      await tapVisible(tester, const Key('stock-movement-MOV-GRN-85021'));
      expect(find.text('Available to sell'), findsOneWidget);
      expect(retailer.selectedStockMovementId, 'MOV-GRN-85021');
      await dismissSheet(tester);

      await tapVisible(tester, const Key('stock-review-checks'));
      await tapVisible(tester, const Key('stock-check-CHECK-COUNT'));
      await tapVisible(tester, const Key('stock-check-count'));
      expect(find.byKey(const Key('stock-adjustment-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('stock-adjustment-save'));
      expect(find.textContaining('greater than zero'), findsWidgets);
      await enter(tester, const Key('stock-adjustment-quantity'), '4');
      await enter(tester, const Key('stock-adjustment-reason'), 'x');
      await tapVisible(tester, const Key('stock-adjustment-save'));
      expect(find.textContaining('clear reason'), findsWidgets);
      await enter(
        tester,
        const Key('stock-adjustment-reason'),
        'Owner physical count',
      );
      await tapVisible(tester, const Key('stock-adjustment-save'));
      expect(find.textContaining('was not recorded'), findsWidgets);
      expect(retailer.stockMovements, hasLength(5));
      await tapVisible(tester, const Key('stock-adjustment-save'));
      expect(retailer.stockMovements, hasLength(6));
      expect(gateway.adjustStockCalls, 2);
      expect(
        await retailer.recordStockAdjustment(
          kind: RetailerStockAdjustmentKind.physicalCount,
          quantity: 4,
          reason: 'Owner physical count',
        ),
        isTrue,
      );
      expect(gateway.adjustStockCalls, 2);
      expect(retailer.stockMovements, hasLength(6));

      expect(
        await completeFuture(tester, retailer.refreshStockStatement()),
        isFalse,
      );
      expect(
        await completeFuture(tester, retailer.refreshStockStatement()),
        isTrue,
      );
      expect(gateway.refreshStockCalls, 2);

      await tapVisible(tester, const Key('stock-statement-export'));
      await tapVisible(tester, const Key('stock-export-csv'));
      expect(find.textContaining('export was not created'), findsOneWidget);
      await tapVisible(tester, const Key('stock-statement-export'));
      await tapVisible(tester, const Key('stock-export-csv'));
      expect(retailer.lastStockExport, 'CSV');
      expect(gateway.exportStockCalls, 2);
    },
  );

  testWidgets(
    'screen 91 routes every stock check and missing sale to its completing journey',
    (tester) async {
      final retailer = await mount(tester, route: '/app/retailer/books/stock');

      await tapVisible(tester, const Key('stock-review-checks'));
      await tapVisible(tester, const Key('stock-check-CHECK-EXPIRY'));
      await tapVisible(tester, const Key('stock-check-damage'));
      expect(find.byKey(const Key('stock-adjustment-sheet')), findsOneWidget);
      await tester.tapAt(const Offset(8, 90));
      await settle(tester);

      retailer.setStockStatementView(RetailerStockStatementView.movements);
      await tapVisible(tester, const Key('stock-record-change'));
      await tapVisible(tester, const Key('stock-adjust-missing-sale'));
      expect(find.text('Create order'), findsOneWidget);
    },
  );

  testWidgets(
    'screen 106 validates and saves one evidenced expense then resolves an exception after exact failure replay',
    (tester) async {
      final gateway = ReviewRetailerBooksGateway()
        ..failSaveExpense = true
        ..failResolveMoney = true;
      final retailer = RetailerSession(booksGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/books/money',
        retailerSession: retailer,
      );

      expect(find.byKey(const Key('money-control-screen')), findsOneWidget);
      await tapVisible(tester, const Key('money-add-expense'));
      await tapVisible(tester, const Key('expense-save'));
      expect(find.textContaining('Attach the bill'), findsWidgets);
      await tapVisible(tester, const Key('expense-evidence'));
      await tapVisible(tester, const Key('expense-save'));
      expect(find.textContaining('expense was not saved'), findsWidgets);
      expect(retailer.expenses, isEmpty);
      await tapVisible(tester, const Key('expense-save'));
      expect(retailer.expenses, hasLength(1));
      expect(gateway.saveExpenseCalls, 2);
      expect(
        await retailer.saveBusinessExpense(
          amount: 850,
          category: 'Shop expense',
          note: 'Packaging material',
          method: 'Cash',
          evidenceAttached: true,
        ),
        isTrue,
      );
      expect(gateway.saveExpenseCalls, 2);
      expect(retailer.expenses, hasLength(1));

      await tapVisible(tester, const Key('money-resolve-MONEY-CASH-1240'));
      await tapVisible(tester, const Key('money-confirm-resolution'));
      expect(find.textContaining('was not resolved'), findsOneWidget);
      expect(retailer.openMoneyExceptions, hasLength(3));
      await tapVisible(tester, const Key('money-confirm-resolution'));
      expect(retailer.openMoneyExceptions, hasLength(2));
      expect(gateway.resolveMoneyCalls, 2);
      expect(await retailer.resolveMoneyException('MONEY-CASH-1240'), isTrue);
      expect(gateway.resolveMoneyCalls, 2);
    },
  );

  testWidgets(
    'screen 92 and 106 route authoritative sales, purchases, stock and money records',
    (tester) async {
      await mount(tester, route: '/app/retailer/books');

      await tapVisible(tester, const Key('business-open-sales'));
      expect(find.text('Sales Book'), findsWidgets);

      await tapVisible(tester, const Key('retailer-back'));
      await tapVisible(tester, const Key('business-open-purchases'));
      expect(find.text('Purchase Book'), findsWidgets);

      await tapVisible(tester, const Key('retailer-back'));
      await tapVisible(tester, const Key('business-open-stock'));
      expect(find.byKey(const Key('stock-statement-screen')), findsOneWidget);

      await tapVisible(tester, const Key('retailer-back'));
      await tapVisible(tester, const Key('business-open-money'));
      expect(find.byKey(const Key('money-control-screen')), findsOneWidget);

      await tapVisible(tester, const Key('money-receipt-upi'));
      expect(find.text('Sales Book'), findsWidgets);
    },
  );

  testWidgets(
    'business records protect role, preserve offline state and fit compact accessible screens',
    (tester) async {
      final retailer = RetailerSession()
        ..businessBookAuthorized = false
        ..setBusinessBookOnline(false);
      await mount(
        tester,
        route: '/app/retailer/books',
        retailerSession: retailer,
        size: const Size(320, 700),
        textScale: 1.35,
      );
      expect(
        find.byKey(const Key('business-book-role-denied')),
        findsOneWidget,
      );

      retailer.businessBookAuthorized = true;
      retailer.notifyListeners();
      await settle(tester);
      expect(find.byKey(const Key('business-book-screen')), findsOneWidget);
      expect(await retailer.refreshBusinessBook(), isFalse);
      expect(await retailer.refreshStockStatement(), isFalse);
      expect(
        await retailer.recordStockAdjustment(
          kind: RetailerStockAdjustmentKind.damageOrExpiry,
          quantity: 1,
          reason: 'Expired pack',
        ),
        isFalse,
      );
      expect(
        await retailer.saveBusinessExpense(
          amount: 100,
          category: 'Shop expense',
          note: 'Tape',
          method: 'Cash',
          evidenceAttached: true,
        ),
        isFalse,
      );
      expect(await retailer.resolveMoneyException('MONEY-UPI-620'), isFalse);
      expect(retailer.stockMovements, hasLength(5));
      expect(retailer.expenses, isEmpty);
      expect(retailer.openMoneyExceptions, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );
}
