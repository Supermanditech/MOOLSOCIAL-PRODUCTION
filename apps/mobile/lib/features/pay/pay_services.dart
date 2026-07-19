import 'pay_models.dart';

class PayServiceException implements Exception {
  const PayServiceException(this.userMessage);

  final String userMessage;
}

abstract interface class PayGateway {
  Future<void> verifyAccount({
    required PayAction source,
    required String account,
  });

  Future<PaymentRecord> submitPayment({
    required PaymentIntent intent,
    required ConsumerPaymentMethod method,
  });

  Future<PaymentOutcome> refreshStatus({required PaymentRecord record});

  Future<String> declineRequest({required PaymentIntent intent});

  Future<String> openSupport({
    required PaymentRecord record,
    required String reason,
  });
}

class ReviewPayGateway implements PayGateway {
  ReviewPayGateway({
    this.failNextVerification = false,
    this.failNextPayment = false,
    this.failNextRefresh = false,
    this.failNextDecline = false,
    this.failNextSupport = false,
    this.nextOutcome = PaymentOutcome.success,
    this.refreshedOutcome = PaymentOutcome.success,
    this.latency = const Duration(milliseconds: 120),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool failNextVerification;
  bool failNextPayment;
  bool failNextRefresh;
  bool failNextDecline;
  bool failNextSupport;
  PaymentOutcome nextOutcome;
  PaymentOutcome refreshedOutcome;
  final Duration latency;
  final DateTime Function() _now;
  int verificationCalls = 0;
  int paymentCalls = 0;
  int refreshCalls = 0;
  int declineCalls = 0;
  int supportCalls = 0;
  int _sequence = 812;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  @override
  Future<void> verifyAccount({
    required PayAction source,
    required String account,
  }) async {
    verificationCalls += 1;
    await _wait();
    if (failNextVerification) {
      failNextVerification = false;
      throw const PayServiceException(
        'The provider could not confirm these details. Nothing was charged. Check the entry and try again.',
      );
    }
  }

  @override
  Future<PaymentRecord> submitPayment({
    required PaymentIntent intent,
    required ConsumerPaymentMethod method,
  }) async {
    paymentCalls += 1;
    await _wait();
    if (failNextPayment) {
      failNextPayment = false;
      throw const PayServiceException(
        'The bank did not complete this payment. No debit is confirmed. Check the result before trying again.',
      );
    }
    _sequence += 1;
    final outcome = nextOutcome;
    nextOutcome = PaymentOutcome.success;
    return PaymentRecord(
      id: 'MSP2407$_sequence',
      intent: intent,
      method: method,
      outcome: outcome,
      createdAt: _now(),
      providerReference: 'UPI784$_sequence',
    );
  }

  @override
  Future<PaymentOutcome> refreshStatus({required PaymentRecord record}) async {
    refreshCalls += 1;
    await _wait();
    if (failNextRefresh) {
      failNextRefresh = false;
      throw const PayServiceException(
        'The bank status is temporarily unavailable. Do not pay again. Try this status check later.',
      );
    }
    final outcome = refreshedOutcome;
    refreshedOutcome = PaymentOutcome.success;
    return outcome;
  }

  @override
  Future<String> declineRequest({required PaymentIntent intent}) async {
    declineCalls += 1;
    await _wait();
    if (failNextDecline) {
      failNextDecline = false;
      throw const PayServiceException(
        'The request could not be declined yet. No debit was made. Try again.',
      );
    }
    _sequence += 1;
    return 'REQ-DECLINED-$_sequence';
  }

  @override
  Future<String> openSupport({
    required PaymentRecord record,
    required String reason,
  }) async {
    supportCalls += 1;
    await _wait();
    if (failNextSupport) {
      failNextSupport = false;
      throw const PayServiceException(
        'Support could not attach the payment record yet. Your payment status remains protected. Try again.',
      );
    }
    _sequence += 1;
    return 'PAY-HELP-$_sequence';
  }
}
