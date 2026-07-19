import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/pay/pay_models.dart';
import 'package:moolsocial/features/pay/pay_services.dart';
import 'package:moolsocial/features/pay/pay_session.dart';

void main() {
  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    return session;
  }

  Future<void> mount(
    WidgetTester tester, {
    required PaySession pay,
    required String location,
  }) async {
    final journey = await readyJourney();
    addTearDown(journey.dispose);
    addTearDown(pay.dispose);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        paySession: pay,
        initialLocation: location,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'recharge verifies account, shows plan and completes one bank-backed receipt',
    (tester) async {
      final gateway = ReviewPayGateway(latency: Duration.zero);
      final pay = PaySession(gateway: gateway);
      await mount(tester, pay: pay, location: '/app/pay/home');

      await tapVisible(tester, const Key('pay-home-recharge'));
      expect(find.byKey(const Key('pay-recharge-screen')), findsOneWidget);
      await tapVisible(tester, const Key('verify-recharge-account'));
      expect(pay.accountVerified, isTrue);
      await tapVisible(tester, const Key('pay-choice-mobile-199'));
      await tapVisible(tester, const Key('pay-method-card'));
      await tapVisible(tester, const Key('pay-recharge-submit'));

      expect(find.byKey(const Key('pay-receipt-screen')), findsOneWidget);
      expect(find.text('₹199'), findsWidgets);
      expect(find.text('Bank-confirmed receipt'), findsOneWidget);
      expect(gateway.paymentCalls, 1);

      await tapVisible(tester, const Key('download-pay-receipt'));
      expect(find.text('Receipt downloaded to this device.'), findsOneWidget);
      await tapVisible(tester, const Key('share-pay-receipt'));
      expect(find.text('Secure receipt share sheet opened.'), findsOneWidget);
    },
  );

  testWidgets(
    'recharge empty, provider failure and payment failure replay without duplicate debit',
    (tester) async {
      final gateway = ReviewPayGateway(
        latency: Duration.zero,
        failNextVerification: true,
        failNextPayment: true,
      );
      final pay = PaySession(gateway: gateway);
      await mount(tester, pay: pay, location: '/app/pay/recharge');

      await tester.enterText(find.byKey(const Key('recharge-account')), '');
      await tapVisible(tester, const Key('verify-recharge-account'));
      expect(
        find.text('Enter a valid mobile number or subscriber ID.'),
        findsOneWidget,
      );
      expect(gateway.verificationCalls, 0);

      await tester.enterText(
        find.byKey(const Key('recharge-account')),
        '9829012321',
      );
      await tapVisible(tester, const Key('verify-recharge-account'));
      expect(find.textContaining('provider could not confirm'), findsOneWidget);
      expect(gateway.verificationCalls, 1);

      await tapVisible(tester, const Key('verify-recharge-account'));
      expect(pay.accountVerified, isTrue);
      await tapVisible(tester, const Key('pay-recharge-submit'));
      expect(find.textContaining('bank did not complete'), findsOneWidget);
      expect(find.byKey(const Key('pay-recharge-screen')), findsOneWidget);
      expect(gateway.paymentCalls, 1);

      await tapVisible(tester, const Key('pay-recharge-submit'));
      expect(find.byKey(const Key('pay-receipt-screen')), findsOneWidget);
      expect(gateway.paymentCalls, 2);
      expect(
        pay.visibleRecords
            .where((item) => item.intent.id.startsWith('RECH-'))
            .length,
        1,
      );
    },
  );

  testWidgets('bill fetch validates and completes the selected due bill', (
    tester,
  ) async {
    final gateway = ReviewPayGateway(latency: Duration.zero);
    final pay = PaySession(gateway: gateway);
    await mount(tester, pay: pay, location: '/app/pay/bills');

    await tapVisible(tester, const Key('bill-type-internet'));
    await tester.enterText(find.byKey(const Key('bill-account')), 'NET930');
    await tapVisible(tester, const Key('fetch-bill'));
    expect(find.text('Current bill fetched'), findsOneWidget);
    await tapVisible(tester, const Key('pay-choice-internet-mobile'));
    await tapVisible(tester, const Key('pay-bill-submit'));

    expect(find.byKey(const Key('pay-receipt-screen')), findsOneWidget);
    expect(find.text('₹649'), findsWidgets);
    expect(find.textContaining('Postpaid mobile'), findsWidgets);
  });

  testWidgets(
    'scan permission denied, invalid UPI and valid payee paths complete visibly',
    (tester) async {
      final gateway = ReviewPayGateway(latency: Duration.zero);
      final pay = PaySession(gateway: gateway);
      await mount(tester, pay: pay, location: '/app/pay/scan');

      await tapVisible(tester, const Key('open-scan-camera'));
      await tapVisible(tester, const Key('deny-scan-camera'));
      expect(
        find.textContaining('Camera access was not allowed'),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('scan-type-upiId'));
      await tester.enterText(find.byKey(const Key('scan-account')), 'invalid');
      await tester.enterText(find.byKey(const Key('scan-amount')), '0');
      await tapVisible(tester, const Key('verify-scan-payee'));
      expect(
        find.text('Enter an amount from ₹1 to ₹1,00,000.'),
        findsOneWidget,
      );
      expect(gateway.verificationCalls, 0);

      await tester.enterText(
        find.byKey(const Key('scan-account')),
        'mahadev@upi',
      );
      await tester.enterText(find.byKey(const Key('scan-amount')), '645');
      await tapVisible(tester, const Key('verify-scan-payee'));
      expect(find.text('Payee and amount verified'), findsOneWidget);
      expect(find.text('Mahadev Fresh Mart'), findsWidgets);
      await tapVisible(tester, const Key('pay-scan-submit'));
      expect(find.byKey(const Key('pay-receipt-screen')), findsOneWidget);
    },
  );

  testWidgets(
    'request decline cancel, failure and exact retry save one no-debit reference',
    (tester) async {
      final gateway = ReviewPayGateway(
        latency: Duration.zero,
        failNextDecline: true,
      );
      final pay = PaySession(gateway: gateway);
      await mount(tester, pay: pay, location: '/app/pay/requests');

      await tapVisible(tester, const Key('decline-request-MS2401'));
      await tapVisible(tester, const Key('cancel-decline-request'));
      expect(gateway.declineCalls, 0);

      await tapVisible(tester, const Key('decline-request-MS2401'));
      await tapVisible(tester, const Key('confirm-decline-request'));
      expect(find.textContaining('could not be declined'), findsOneWidget);
      expect(gateway.declineCalls, 1);

      await tapVisible(tester, const Key('decline-request-MS2401'));
      await tapVisible(tester, const Key('confirm-decline-request'));
      expect(find.textContaining('No debit was made'), findsOneWidget);
      expect(find.text('Declined · no debit'), findsOneWidget);
      expect(gateway.declineCalls, 2);
      expect(pay.declineReference, isNotNull);
    },
  );

  testWidgets(
    'verified request confirms exact debit while unknown request stays blocked',
    (tester) async {
      final gateway = ReviewPayGateway(latency: Duration.zero);
      final pay = PaySession(gateway: gateway);
      await mount(tester, pay: pay, location: '/app/pay/requests');

      await tapVisible(tester, const Key('review-request-MS2401'));
      expect(
        find.byKey(const Key('pay-request-confirmation-screen')),
        findsOneWidget,
      );
      expect(find.text('₹645'), findsWidgets);
      expect(find.text('No debit on page open'), findsOneWidget);
      await tapVisible(tester, const Key('confirmation-pay'));
      expect(find.byKey(const Key('pay-receipt-screen')), findsOneWidget);
      expect(gateway.paymentCalls, 1);

      await tapVisible(tester, const Key('pay-dock-requests'));
      await tapVisible(tester, const Key('request-category-people'));
      expect(find.byKey(const Key('report-request-BLOCKED')), findsOneWidget);
      expect(find.byKey(const Key('review-request-BLOCKED')), findsNothing);
      await tapVisible(tester, const Key('report-request-BLOCKED'));
      expect(find.textContaining('reported and blocked'), findsOneWidget);
      expect(gateway.paymentCalls, 1);
    },
  );

  testWidgets(
    'pending payment blocks repeat and status failure then exact refresh becomes one receipt',
    (tester) async {
      final gateway = ReviewPayGateway(
        latency: Duration.zero,
        nextOutcome: PaymentOutcome.pending,
        failNextRefresh: true,
        refreshedOutcome: PaymentOutcome.success,
      );
      final pay = PaySession(gateway: gateway);
      await mount(tester, pay: pay, location: '/app/pay/requests');

      await tapVisible(tester, const Key('review-request-MS2401'));
      await tapVisible(tester, const Key('confirmation-pay'));
      expect(find.byKey(const Key('pay-status-screen')), findsOneWidget);
      expect(find.text('Repeat payment is locked'), findsOneWidget);
      expect(find.byKey(const Key('confirmation-pay')), findsNothing);
      expect(gateway.paymentCalls, 1);

      await tapVisible(tester, const Key('refresh-payment-status'));
      expect(find.textContaining('Do not pay again'), findsWidgets);
      expect(gateway.refreshCalls, 1);
      await tapVisible(tester, const Key('refresh-payment-status'));
      expect(find.byKey(const Key('pay-receipt-screen')), findsOneWidget);
      expect(gateway.refreshCalls, 2);
      expect(gateway.paymentCalls, 1);
    },
  );

  testWidgets(
    'failed no-debit outcome permits one safe retry with unchanged purpose',
    (tester) async {
      final gateway = ReviewPayGateway(
        latency: Duration.zero,
        nextOutcome: PaymentOutcome.failedNoDebit,
      );
      final pay = PaySession(gateway: gateway);
      await mount(tester, pay: pay, location: '/app/pay/requests');

      await tapVisible(tester, const Key('review-request-DC108'));
      await tapVisible(tester, const Key('confirmation-pay'));
      expect(find.byKey(const Key('pay-outcome-screen')), findsOneWidget);
      expect(find.text('Bank confirmed no debit'), findsOneWidget);
      expect(find.text('Safe retry is available'), findsOneWidget);
      expect(gateway.paymentCalls, 1);

      await tapVisible(tester, const Key('safe-payment-retry'));
      expect(
        find.byKey(const Key('pay-request-confirmation-screen')),
        findsOneWidget,
      );
      expect(find.text('Appointment #DC108'), findsWidgets);
      await tapVisible(tester, const Key('confirmation-pay'));
      expect(find.byKey(const Key('pay-receipt-screen')), findsOneWidget);
      expect(gateway.paymentCalls, 2);
      expect(pay.activeRecord?.outcome, PaymentOutcome.success);
      expect(pay.activeRecord?.intent.id, 'DC108');
    },
  );

  testWidgets(
    'reversal locks retry, status refresh returns original amount and support retries once',
    (tester) async {
      final gateway = ReviewPayGateway(
        latency: Duration.zero,
        nextOutcome: PaymentOutcome.reversal,
        refreshedOutcome: PaymentOutcome.reversed,
        failNextSupport: true,
      );
      final pay = PaySession(gateway: gateway);
      await mount(tester, pay: pay, location: '/app/pay/requests');

      await tapVisible(tester, const Key('review-request-DC108'));
      await tapVisible(tester, const Key('confirmation-pay'));
      expect(find.text('Do not retry yet'), findsOneWidget);
      expect(find.byKey(const Key('safe-payment-retry')), findsNothing);

      await tapVisible(tester, const Key('outcome-payment-help'));
      expect(find.textContaining('could not attach'), findsOneWidget);
      await tapVisible(tester, const Key('outcome-payment-help'));
      expect(find.textContaining('Support case PAY-HELP-'), findsWidgets);
      expect(gateway.supportCalls, 2);

      await tapVisible(tester, const Key('check-payment-reversal'));
      expect(find.byKey(const Key('pay-status-screen')), findsOneWidget);
      expect(find.text('Refund completed'), findsOneWidget);
      expect(find.textContaining('Returned to'), findsWidgets);
      expect(gateway.paymentCalls, 1);
    },
  );

  testWidgets(
    'receipt search, pending and refund filters include empty recovery and direct records',
    (tester) async {
      final pay = PaySession(gateway: ReviewPayGateway(latency: Duration.zero));
      await mount(tester, pay: pay, location: '/app/pay/receipts');

      await tester.enterText(
        find.byKey(const Key('receipt-search')),
        'not-a-record',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('receipts-empty')), findsOneWidget);
      await tapVisible(tester, const Key('clear-receipt-search'));

      await tapVisible(tester, const Key('receipt-filter-pending'));
      expect(
        find.byKey(const Key('payment-record-MSP240710740')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('open-payment-MSP240710740'));
      expect(find.text('Confirmation in progress'), findsOneWidget);

      await tapVisible(tester, const Key('pay-dock-receipts'));
      await tapVisible(tester, const Key('receipt-filter-refunds'));
      expect(
        find.byKey(const Key('payment-record-RF240709615')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('open-payment-RF240709615'));
      expect(find.text('Refund completed'), findsOneWidget);
    },
  );

  testWidgets('Pay remains usable on compact width with larger text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final pay = PaySession(gateway: ReviewPayGateway(latency: Duration.zero));
    final journey = await readyJourney();
    addTearDown(journey.dispose);
    addTearDown(pay.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        paySession: pay,
        initialLocation: '/app/pay/home',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pay-home-screen')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('pay-home-recharge')),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('pay-home-screen')),
        matching: find.byType(Scrollable),
      ),
    );
    await tapVisible(tester, const Key('pay-home-recharge'));
    expect(find.byKey(const Key('pay-recharge-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
