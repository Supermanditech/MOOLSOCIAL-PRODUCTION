import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
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
        attempt < 24 && finder.evaluate().isEmpty;
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

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = await reveal(tester, key);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical Business Book records one stock count and one evidenced expense',
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
          initialLocation: '/app/retailer/books',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('business-book-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-92-business-book');

      await tapVisible(tester, const Key('business-open-stock'));
      expect(find.byKey(const Key('stock-statement-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-91-stock-statement');
      await tapVisible(tester, const Key('stock-record-change'));
      await tapVisible(tester, const Key('stock-adjust-physicalCount'));
      await enter(tester, const Key('stock-adjustment-quantity'), '4');
      await enter(
        tester,
        const Key('stock-adjustment-reason'),
        'Owner physical count',
      );
      await tapVisible(tester, const Key('stock-adjustment-save'));
      expect(retailer.stockMovements, hasLength(6));
      expect(retailer.stockAdjustmentId, 'ADJ-9101');
      await binding.takeScreenshot('retailer-91-stock-count-recorded');

      await tapVisible(tester, const Key('retailer-back'));
      await tapVisible(tester, const Key('business-open-money'));
      expect(find.byKey(const Key('money-control-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-106-money-control');
      await tapVisible(tester, const Key('money-add-expense'));
      await tapVisible(tester, const Key('expense-evidence'));
      await tapVisible(tester, const Key('expense-save'));
      expect(retailer.expenses, hasLength(1));
      expect(retailer.expenseId, 'EXP-10601');

      await tapVisible(tester, const Key('money-resolve-MONEY-CASH-1240'));
      await tapVisible(tester, const Key('money-confirm-resolution'));
      expect(retailer.openMoneyExceptions, hasLength(2));
      await binding.takeScreenshot('retailer-106-expense-reconciled');
    },
  );
}
