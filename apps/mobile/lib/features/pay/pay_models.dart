enum PayAction { recharge, bills, scan, requests }

enum RechargeType { mobile, dth, data, saved }

enum BillType { electricity, water, gas, internet }

enum ScanPayType { shopQr, orderQr, providerQr, upiId }

enum PayRequestCategory { pending, orders, business, people }

enum ConsumerPaymentMethod { upi, card, bank }

enum PaymentOutcome { success, pending, failedNoDebit, reversal, reversed }

enum ReceiptFilter { all, pending, refunds }

class PayChoice {
  const PayChoice({
    required this.id,
    required this.title,
    required this.amount,
    required this.detail,
    required this.proof,
    required this.follow,
  });

  final String id;
  final String title;
  final int amount;
  final String detail;
  final String proof;
  final String follow;
}

class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.source,
    required this.payee,
    required this.payeeDetail,
    required this.purpose,
    required this.amount,
    required this.linkedReference,
    required this.expires,
    required this.verified,
    this.amountLocked = true,
  });

  final String id;
  final PayAction source;
  final String payee;
  final String payeeDetail;
  final String purpose;
  final int amount;
  final String linkedReference;
  final String expires;
  final bool verified;
  final bool amountLocked;
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.intent,
    required this.method,
    required this.outcome,
    required this.createdAt,
    required this.providerReference,
    this.refundAmount = 0,
    this.supportCaseId,
  });

  final String id;
  final PaymentIntent intent;
  final ConsumerPaymentMethod method;
  final PaymentOutcome outcome;
  final DateTime createdAt;
  final String providerReference;
  final int refundAmount;
  final String? supportCaseId;

  PaymentRecord copyWith({
    PaymentOutcome? outcome,
    int? refundAmount,
    String? supportCaseId,
  }) {
    return PaymentRecord(
      id: id,
      intent: intent,
      method: method,
      outcome: outcome ?? this.outcome,
      createdAt: createdAt,
      providerReference: providerReference,
      refundAmount: refundAmount ?? this.refundAmount,
      supportCaseId: supportCaseId ?? this.supportCaseId,
    );
  }
}

extension PayActionCopy on PayAction {
  String get label => switch (this) {
    PayAction.recharge => 'Recharge',
    PayAction.bills => 'Bills',
    PayAction.scan => 'Scan Pay',
    PayAction.requests => 'Requests',
  };
}

extension RechargeTypeCopy on RechargeType {
  String get label => switch (this) {
    RechargeType.mobile => 'Mobile',
    RechargeType.dth => 'DTH',
    RechargeType.data => 'Data',
    RechargeType.saved => 'Saved',
  };
}

extension BillTypeCopy on BillType {
  String get label => switch (this) {
    BillType.electricity => 'Electricity',
    BillType.water => 'Water',
    BillType.gas => 'Gas',
    BillType.internet => 'Internet',
  };
}

extension ScanPayTypeCopy on ScanPayType {
  String get label => switch (this) {
    ScanPayType.shopQr => 'Shop QR',
    ScanPayType.orderQr => 'Order QR',
    ScanPayType.providerQr => 'Provider QR',
    ScanPayType.upiId => 'Enter UPI',
  };
}

extension PayRequestCategoryCopy on PayRequestCategory {
  String get label => switch (this) {
    PayRequestCategory.pending => 'Pending',
    PayRequestCategory.orders => 'Orders',
    PayRequestCategory.business => 'Business',
    PayRequestCategory.people => 'People',
  };
}

extension ConsumerPaymentMethodCopy on ConsumerPaymentMethod {
  String get label => switch (this) {
    ConsumerPaymentMethod.upi => 'UPI •••• 4821',
    ConsumerPaymentMethod.card => 'Card •••• 6068',
    ConsumerPaymentMethod.bank => 'Bank account',
  };
}

extension PaymentOutcomeCopy on PaymentOutcome {
  String get label => switch (this) {
    PaymentOutcome.success => 'Successful',
    PaymentOutcome.pending => 'Confirmation pending',
    PaymentOutcome.failedNoDebit => 'Not debited',
    PaymentOutcome.reversal => 'Returning',
    PaymentOutcome.reversed => 'Returned',
  };
}
