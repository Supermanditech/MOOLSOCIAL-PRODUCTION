import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
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

  Future<void> openCheckout(WidgetTester tester, BuyV2Session session) async {
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart();
    expect(session.openCheckout(), isTrue);
    expect(session.continueCheckoutFromAddress(), isTrue);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'retired Bank transfer cannot start a new payment or expose account instructions',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await openCheckout(tester, session);
      expect(session.choosePayment('Bank transfer'), isFalse);
      expect(session.selectedPayment, 'PhonePe');
      expect(session.availablePaymentMethods, isNot(contains('Bank transfer')));
      expect(
        find.byKey(const ValueKey('buy-payment-Bank transfer')),
        findsNothing,
      );
      expect(find.text('Order placed'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-bank-transfer-instructions')),
        findsNothing,
      );
      expect(find.text('000000004821'), findsNothing);
      expect(find.text('MOOL0000482'), findsNothing);
      expect(session.markBankTransferSent(), isFalse);
      expect(session.cartLines, hasLength(1));
      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.idle,
      );
      expect(session.confirmedOrders, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending Bank transfer survives customer-state restoration', (
    tester,
  ) async {
    // A persisted pre-retirement payment must retain its original identity.
    final seed = BuyV2Session(core: BuySession());
    addTearDown(seed.dispose);
    final store = _MemoryCustomerStateStore()
      ..snapshot = BuyV2CustomerStateSnapshot(
        cartQuantities: const {'s-tomato': 1},
        addresses: seed.addresses,
        selectedAddressId: seed.selectedAddressId,
        selectedPayment: 'Bank transfer',
        checkoutIdempotencyKey: 'legacy-bank-checkout-1',
        paymentReference: 'legacy-bank-transfer-1',
        checkoutSubmissionState: 'paymentPending',
        bankTransferInstructions: const BuyV2BankTransferInstructions(
          beneficiaryName: 'Fixture beneficiary',
          bankName: 'Fixture bank',
          accountNumber: '000000004821',
          ifsc: 'MOOL0000482',
          transferReference: 'legacy-bank-transfer-1',
        ),
      );

    final restored = BuyV2Session(
      core: BuySession(),
      customerStateStore: store,
    );
    addTearDown(restored.dispose);
    await restored.restoreCustomerState();
    expect(restored.selectedPayment, 'Bank transfer');
    expect(
      restored.checkoutSubmissionState,
      BuyV2CheckoutSubmissionState.paymentPending,
    );
    expect(
      restored.bankTransferInstructions?.transferReference,
      'legacy-bank-transfer-1',
    );
    expect(restored.availablePaymentMethods, isNot(contains('Bank transfer')));
    expect(restored.choosePayment('PhonePe'), isFalse);
    expect(restored.confirmOrder(), isFalse);
    expect(await restored.submitOrder(), isFalse);
    expect(restored.confirmedOrders, isEmpty);
    expect(restored.cartLines, hasLength(1));
    expect(restored.checkoutRequiresResolution, isTrue);
  });

  test(
    'retired method restoration distinguishes unresolved attempts from old preferences',
    () async {
      for (final method in ['Bank transfer', 'UPI']) {
        for (final state in BuyV2CheckoutSubmissionState.values) {
          final store = _MemoryCustomerStateStore()
            ..snapshot = BuyV2CustomerStateSnapshot(
              selectedPayment: method,
              checkoutSubmissionState: state.name,
              checkoutIdempotencyKey: 'original-attempt',
              paymentReference: 'original-reference',
            );
          final session = BuyV2Session(
            core: BuySession(),
            customerStateStore: store,
          );
          await session.restoreCustomerState();
          final unresolved = {
            BuyV2CheckoutSubmissionState.submitting,
            BuyV2CheckoutSubmissionState.paymentActionRequired,
            BuyV2CheckoutSubmissionState.paymentPending,
            BuyV2CheckoutSubmissionState.paymentUnknown,
          }.contains(state);
          expect(
            session.selectedPayment,
            unresolved ? method : 'PhonePe',
            reason: '$method/${state.name}',
          );
          expect(session.availablePaymentMethods, isNot(contains(method)));
          expect(session.choosePayment(method), isFalse);
          if (unresolved) {
            expect(session.confirmOrder(), isFalse);
            expect(session.checkoutRequiresResolution, isTrue);
            expect(session.confirmedOrders, isEmpty);
          }
          session.dispose();
        }
      }
    },
  );
}
