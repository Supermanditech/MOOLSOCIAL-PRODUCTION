import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Checkout help opens shared Chat without entering the retired Assist view',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      var chatOpens = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session, onOpenChat: () => chatOpens += 1),
        ),
      );
      await tester.pumpAndSettle();

      session.addProduct('s-tomato');
      session.openCart(scope: BuyV2CartScope.shop);
      session.openCheckout();
      session.checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
      session.notifyListeners();
      await tester.pumpAndSettle();

      expect(session.view, BuyV2View.checkout);
      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-submission-help')),
      );
      await tester.pumpAndSettle();

      expect(chatOpens, 1);
      expect(session.view, BuyV2View.checkout);
      expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    },
  );

  testWidgets(
    'Standalone order help stays on the exact order when Chat is unavailable',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();
      final order = session.orders.firstWhere(
        (candidate) => candidate.status != BuyV2OrderStatus.delivered,
      );
      expect(session.openTracking(order.id), isTrue);
      await tester.pumpAndSettle();

      final help = find.byKey(const ValueKey('buy-tracking-help'));
      await tester.scrollUntilVisible(
        help,
        240,
        scrollable: find.descendant(
          of: find.byKey(PageStorageKey('buy-tracking-${order.id}')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(help);
      await tester.pumpAndSettle();

      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, order.id);
      expect(
        session.notice,
        'Shop Chat is unavailable right now. Your order is unchanged.',
      );
      expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    },
  );
}
