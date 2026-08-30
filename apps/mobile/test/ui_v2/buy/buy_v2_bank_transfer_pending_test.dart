import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

final class _MemoryCustomerStateStore implements BuyV2CustomerStateStore {
  BuyV2CustomerStateSnapshot? snapshot;

  @override
  String? get ownerScope => 'bank-transfer-review-account';

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    this.snapshot = snapshot;
    return true;
  }
}

void main() {
  Widget app(BuyV2Session session) => MaterialApp(
    theme: MoolTheme.light(),
    home: BuyV2Screen(session: session),
  );

  Future<void> openBankTransferCheckout(
    WidgetTester tester,
    BuyV2Session session,
  ) async {
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart();
    expect(session.openCheckout(), isTrue);
    expect(session.choosePayment('Bank transfer'), isTrue);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Bank transfer shows exact instructions then remains pending without a duplicate order',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await openBankTransferCheckout(tester, session);

      await tester.tap(find.text('Place order'));
      await tester.pumpAndSettle();

      expect(find.text('Order placed'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-bank-transfer-instructions')),
        findsOneWidget,
      );
      expect(find.text('Transfer to place your order'), findsOneWidget);
      expect(find.text('MoolSocial Shop Payments'), findsOneWidget);
      expect(find.text('000000004821'), findsOneWidget);
      expect(find.text('MOOL0000482'), findsOneWidget);
      expect(find.text('I’ve made the transfer'), findsOneWidget);
      expect(find.text('Choose another method'), findsOneWidget);
      expect(session.cartLines, hasLength(1));

      await tester.tap(find.text('I’ve made the transfer'));
      await tester.pumpAndSettle();

      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.paymentPending,
      );
      expect(
        find.byKey(const ValueKey('buy-bank-transfer-pending-reference')),
        findsOneWidget,
      );
      expect(find.text('Check payment'), findsOneWidget);
      expect(find.textContaining('Do not pay again'), findsOneWidget);
      expect(await session.submitOrder(), isFalse);
      expect(session.cartLines, hasLength(1));

      await tester.tap(find.text('Check payment'));
      await tester.pumpAndSettle();
      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.paymentPending,
      );
      expect(find.text('Order placed'), findsNothing);
    },
  );

  testWidgets('pending Bank transfer survives customer-state restoration', (
    tester,
  ) async {
    final store = _MemoryCustomerStateStore();
    final first = BuyV2Session(core: BuySession(), customerStateStore: store);
    await openBankTransferCheckout(tester, first);
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’ve made the transfer'));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(store.snapshot?.bankTransferInstructions, isNotNull);

    final restored = BuyV2Session(
      core: BuySession(),
      customerStateStore: store,
    );
    await restored.restoreCustomerState();
    expect(restored.selectedPayment, 'Bank transfer');
    expect(
      restored.checkoutSubmissionState,
      BuyV2CheckoutSubmissionState.paymentPending,
    );
    expect(restored.bankTransferInstructions?.transferReference, isNotEmpty);
    expect(restored.cartLines, hasLength(1));
  });
}
