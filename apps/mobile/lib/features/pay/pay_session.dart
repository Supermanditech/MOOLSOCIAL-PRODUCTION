import 'package:flutter/foundation.dart';

import 'pay_models.dart';
import 'pay_services.dart';

class PaySession extends ChangeNotifier {
  PaySession({PayGateway? gateway}) : _gateway = gateway ?? ReviewPayGateway();

  final PayGateway _gateway;

  RechargeType rechargeType = RechargeType.mobile;
  BillType billType = BillType.electricity;
  ScanPayType scanType = ScanPayType.shopQr;
  PayRequestCategory requestCategory = PayRequestCategory.pending;
  ConsumerPaymentMethod paymentMethod = ConsumerPaymentMethod.upi;
  ReceiptFilter receiptFilter = ReceiptFilter.all;

  String rechargeAccount = '9829012321';
  String billAccount = 'K8271';
  String scanAccount = 'mahadev@upi';
  int scanAmount = 645;
  String searchQuery = '';
  String selectedChoiceId = 'mobile-299';
  String selectedRequestId = 'MS2401';
  bool accountVerified = false;
  bool cameraPermissionDenied = false;
  bool busy = false;
  String? noticeMessage;
  String? errorMessage;
  String? declineReference;
  String? supportCaseId;
  PaymentIntent? activeIntent;
  PaymentRecord? activeRecord;

  static const rechargeChoices = <RechargeType, List<PayChoice>>{
    RechargeType.mobile: [
      PayChoice(
        id: 'mobile-299',
        title: 'Popular plan',
        amount: 299,
        detail: '1.5 GB/day · unlimited calls · 28 days',
        proof: 'Jio prepaid matched',
        follow: 'Receipt saved',
      ),
      PayChoice(
        id: 'mobile-199',
        title: 'Value plan',
        amount: 199,
        detail: '2 GB total · voice + SMS · 28 days',
        proof: 'Jio prepaid matched',
        follow: 'Receipt saved',
      ),
      PayChoice(
        id: 'mobile-2999',
        title: 'Annual plan',
        amount: 2999,
        detail: '2.5 GB/day · 365 days',
        proof: 'Jio prepaid matched',
        follow: 'Receipt saved',
      ),
    ],
    RechargeType.dth: [
      PayChoice(
        id: 'dth-310',
        title: 'Monthly pack',
        amount: 310,
        detail: 'Family TV pack · 30 days',
        proof: 'Tata Play account matched',
        follow: 'Receipt saved',
      ),
      PayChoice(
        id: 'dth-89',
        title: 'Sports add-on',
        amount: 89,
        detail: 'Sports channels · 30 days',
        proof: 'Tata Play account matched',
        follow: 'Receipt saved',
      ),
    ],
    RechargeType.data: [
      PayChoice(
        id: 'data-19',
        title: '1 GB booster',
        amount: 19,
        detail: 'Extra data · same validity',
        proof: 'Jio prepaid matched',
        follow: 'Receipt saved',
      ),
      PayChoice(
        id: 'data-61',
        title: '6 GB booster',
        amount: 61,
        detail: 'Extra data · active pack',
        proof: 'Jio prepaid matched',
        follow: 'Receipt saved',
      ),
    ],
    RechargeType.saved: [
      PayChoice(
        id: 'saved-mom',
        title: 'Mom mobile',
        amount: 299,
        detail: '94******18 · Airtel · last plan',
        proof: 'Saved account rechecked',
        follow: 'Receipt saved',
      ),
      PayChoice(
        id: 'saved-dth',
        title: 'Home DTH',
        amount: 310,
        detail: 'Subscriber ending 421 · monthly pack',
        proof: 'Tata Play account matched',
        follow: 'Receipt saved',
      ),
    ],
  };

  static const billChoices = <BillType, List<PayChoice>>{
    BillType.electricity: [
      PayChoice(
        id: 'electricity-home',
        title: 'Home electricity',
        amount: 1240,
        detail: 'Jodhpur Discom · due 18 Jul · no late fee today',
        proof: 'K No. ending 8271 · consumer name shown',
        follow: 'Receipt saved',
      ),
      PayChoice(
        id: 'electricity-shop',
        title: 'Shop electricity',
        amount: 3860,
        detail: 'Commercial meter · due 21 Jul',
        proof: 'K No. ending 4450 · shop name shown',
        follow: 'GST bill available',
      ),
    ],
    BillType.water: [
      PayChoice(
        id: 'water-home',
        title: 'Jodhpur water',
        amount: 410,
        detail: 'Municipal bill · due 20 Jul',
        proof: 'Account ending 312 · address shown',
        follow: 'Receipt saved',
      ),
    ],
    BillType.gas: [
      PayChoice(
        id: 'gas-lpg',
        title: 'LPG booking',
        amount: 905,
        detail: 'Indane · next available slot',
        proof: 'Consumer name shown',
        follow: 'Booking receipt saved',
      ),
      PayChoice(
        id: 'gas-png',
        title: 'Piped gas',
        amount: 1180,
        detail: 'Meter bill · due 19 Jul',
        proof: 'Address shown',
        follow: 'Receipt saved',
      ),
    ],
    BillType.internet: [
      PayChoice(
        id: 'internet-home',
        title: 'Home broadband',
        amount: 799,
        detail: 'Fiber plan · due 16 Jul',
        proof: 'Customer ID ending 930',
        follow: 'Receipt saved',
      ),
      PayChoice(
        id: 'internet-mobile',
        title: 'Postpaid mobile',
        amount: 649,
        detail: 'Mobile bill · due 22 Jul',
        proof: 'Operator and number shown',
        follow: 'Receipt saved',
      ),
    ],
  };

  static const requests = <PaymentIntent>[
    PaymentIntent(
      id: 'MS2401',
      source: PayAction.requests,
      payee: 'Mahadev Fresh Mart',
      payeeDetail: 'Verified shop · Jodhpur',
      purpose: 'Grocery bill · 12 items reserved',
      amount: 645,
      linkedReference: 'Order #MS2401',
      expires: '28 minutes',
      verified: true,
    ),
    PaymentIntent(
      id: 'DC108',
      source: PayAction.requests,
      payee: 'Dr Mehta Clinic',
      payeeDetail: 'Verified clinic · Jodhpur',
      purpose: 'Consultation fee',
      amount: 600,
      linkedReference: 'Appointment #DC108',
      expires: 'Today',
      verified: true,
    ),
    PaymentIntent(
      id: 'SAL52',
      source: PayAction.requests,
      payee: 'Blue City Salon',
      payeeDetail: 'Verified salon',
      purpose: 'Service completed',
      amount: 799,
      linkedReference: 'Booking #SAL52',
      expires: '2 hours',
      verified: true,
    ),
    PaymentIntent(
      id: 'PPL72',
      source: PayAction.requests,
      payee: 'Karan Sharma',
      payeeDetail: 'Saved contact',
      purpose: 'Dinner split · note included',
      amount: 850,
      linkedReference: 'Personal request #PPL72',
      expires: 'Tonight',
      verified: true,
    ),
    PaymentIntent(
      id: 'BLOCKED',
      source: PayAction.requests,
      payee: 'Unknown request',
      payeeDetail: 'Unverified sender',
      purpose: 'No linked purpose',
      amount: 3500,
      linkedReference: 'No trusted reference',
      expires: 'Blocked',
      verified: false,
    ),
  ];

  final List<PaymentRecord> _records = [
    PaymentRecord(
      id: 'MSP240710812',
      intent: requests.first,
      method: ConsumerPaymentMethod.upi,
      outcome: PaymentOutcome.success,
      createdAt: DateTime(2026, 7, 10, 8, 12),
      providerReference: 'UPI784521',
    ),
    PaymentRecord(
      id: 'MSP240710740',
      intent: requests[1],
      method: ConsumerPaymentMethod.card,
      outcome: PaymentOutcome.pending,
      createdAt: DateTime(2026, 7, 10, 7, 40),
      providerReference: 'CARD6068-740',
    ),
    PaymentRecord(
      id: 'RF240709615',
      intent: PaymentIntent(
        id: 'GID882',
        source: PayAction.requests,
        payee: 'Get It Done',
        payeeDetail: 'Protected task payment',
        purpose: 'Unused task amount returned',
        amount: 80,
        linkedReference: 'Task #GID882',
        expires: 'Completed',
        verified: true,
      ),
      method: ConsumerPaymentMethod.upi,
      outcome: PaymentOutcome.reversed,
      createdAt: DateTime(2026, 7, 9, 18, 15),
      providerReference: 'UPI-REFUND-615',
      refundAmount: 80,
    ),
  ];

  List<PayChoice> get visibleRechargeChoices =>
      rechargeChoices[rechargeType] ?? const [];

  List<PayChoice> get visibleBillChoices => billChoices[billType] ?? const [];

  PayChoice? get selectedRechargeChoice {
    for (final item in visibleRechargeChoices) {
      if (item.id == selectedChoiceId) return item;
    }
    return visibleRechargeChoices.isEmpty ? null : visibleRechargeChoices.first;
  }

  PayChoice? get selectedBillChoice {
    for (final item in visibleBillChoices) {
      if (item.id == selectedChoiceId) return item;
    }
    return visibleBillChoices.isEmpty ? null : visibleBillChoices.first;
  }

  List<PaymentIntent> get visibleRequests {
    return switch (requestCategory) {
      PayRequestCategory.pending => requests.take(2).toList(),
      PayRequestCategory.orders =>
        requests
            .where(
              (item) =>
                  item.linkedReference.contains('Order') ||
                  item.linkedReference.contains('Appointment'),
            )
            .toList(),
      PayRequestCategory.business =>
        requests
            .where(
              (item) =>
                  item.payeeDetail.toLowerCase().contains('verified') &&
                  item.id != 'MS2401',
            )
            .toList(),
      PayRequestCategory.people =>
        requests
            .where((item) => item.id == 'PPL72' || item.id == 'BLOCKED')
            .toList(),
    };
  }

  List<PaymentRecord> get visibleRecords {
    Iterable<PaymentRecord> result = _records;
    result = switch (receiptFilter) {
      ReceiptFilter.all => result,
      ReceiptFilter.pending => result.where(
        (item) => item.outcome == PaymentOutcome.pending,
      ),
      ReceiptFilter.refunds => result.where(
        (item) =>
            item.outcome == PaymentOutcome.reversal ||
            item.outcome == PaymentOutcome.reversed ||
            item.refundAmount > 0,
      ),
    };
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where(
        (item) =>
            item.intent.payee.toLowerCase().contains(query) ||
            item.intent.linkedReference.toLowerCase().contains(query) ||
            item.id.toLowerCase().contains(query) ||
            item.intent.amount.toString().contains(query),
      );
    }
    return result.toList();
  }

  PaymentRecord? recordById(String id) {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
  }

  void chooseRechargeType(RechargeType value) {
    rechargeType = value;
    selectedChoiceId = rechargeChoices[value]!.first.id;
    accountVerified = false;
    _clearFeedback();
    notifyListeners();
  }

  void chooseBillType(BillType value) {
    billType = value;
    selectedChoiceId = billChoices[value]!.first.id;
    accountVerified = false;
    _clearFeedback();
    notifyListeners();
  }

  void chooseScanType(ScanPayType value) {
    scanType = value;
    accountVerified = false;
    cameraPermissionDenied = false;
    _clearFeedback();
    notifyListeners();
  }

  void chooseRequestCategory(PayRequestCategory value) {
    requestCategory = value;
    declineReference = null;
    _clearFeedback();
    notifyListeners();
  }

  void chooseChoice(String id) {
    selectedChoiceId = id;
    errorMessage = null;
    noticeMessage = 'Choice selected. Check the details before paying.';
    notifyListeners();
  }

  void choosePaymentMethod(ConsumerPaymentMethod value) {
    paymentMethod = value;
    errorMessage = null;
    noticeMessage = '${value.label} selected.';
    notifyListeners();
  }

  void denyCameraPermission() {
    cameraPermissionDenied = true;
    accountVerified = false;
    errorMessage =
        'Camera access was not allowed. Enter the UPI ID or use a saved QR image.';
    noticeMessage = null;
    notifyListeners();
  }

  Future<bool> verifyRecharge(String account) =>
      _verify(PayAction.recharge, account);

  Future<bool> verifyBill(String account) => _verify(PayAction.bills, account);

  Future<bool> verifyScan(String account, int amount) async {
    if (amount < 1 || amount > 100000) {
      errorMessage = 'Enter an amount from ₹1 to ₹1,00,000.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    scanAmount = amount;
    return _verify(PayAction.scan, account);
  }

  Future<bool> _verify(PayAction source, String account) async {
    if (busy) return false;
    final value = account.trim();
    final minimum = source == PayAction.recharge ? 6 : 4;
    if (value.length < minimum) {
      errorMessage = source == PayAction.recharge
          ? 'Enter a valid mobile number or subscriber ID.'
          : source == PayAction.bills
          ? 'Enter a valid consumer or customer number.'
          : 'Scan a QR or enter a valid UPI ID.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (source == PayAction.scan &&
        scanType == ScanPayType.upiId &&
        !value.contains('@')) {
      errorMessage = 'Enter a complete UPI ID, such as name@bank.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    try {
      await _gateway.verifyAccount(source: source, account: value);
      if (source == PayAction.recharge) rechargeAccount = value;
      if (source == PayAction.bills) billAccount = value;
      if (source == PayAction.scan) scanAccount = value;
      accountVerified = true;
      noticeMessage = switch (source) {
        PayAction.recharge =>
          'Operator and account matched. Choose the plan to continue.',
        PayAction.bills =>
          'Biller, consumer name, due amount and due date confirmed.',
        PayAction.scan =>
          'Payee name and payment account matched. Check the purpose and amount.',
        PayAction.requests => 'Request checked.',
      };
      return true;
    } on PayServiceException catch (error) {
      accountVerified = false;
      errorMessage = error.userMessage;
      return false;
    } on Object {
      accountVerified = false;
      errorMessage =
          'These details could not be checked. Check your connection and try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  bool prepareRechargePayment() {
    final choice = selectedRechargeChoice;
    if (!accountVerified || choice == null) {
      errorMessage = 'Verify the account and choose a plan before paying.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    activeIntent = PaymentIntent(
      id: 'RECH-${choice.id}',
      source: PayAction.recharge,
      payee: rechargeType == RechargeType.dth ? 'Tata Play' : 'Jio Prepaid',
      payeeDetail: 'Operator account matched',
      purpose: '${choice.title} · ${choice.detail}',
      amount: choice.amount,
      linkedReference: 'Account ${_mask(rechargeAccount)}',
      expires: 'Current session',
      verified: true,
    );
    _clearFeedback();
    notifyListeners();
    return true;
  }

  bool prepareBillPayment() {
    final choice = selectedBillChoice;
    if (!accountVerified || choice == null) {
      errorMessage = 'Fetch the current bill and choose it before paying.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    activeIntent = PaymentIntent(
      id: 'BILL-${choice.id}',
      source: PayAction.bills,
      payee: choice.title,
      payeeDetail: 'Biller and consumer name matched',
      purpose: choice.detail,
      amount: choice.amount,
      linkedReference: choice.proof,
      expires: 'Before the shown due date',
      verified: true,
    );
    _clearFeedback();
    notifyListeners();
    return true;
  }

  bool prepareScanPayment() {
    if (!accountVerified) {
      errorMessage = 'Verify the QR or UPI ID before paying.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    activeIntent = PaymentIntent(
      id: 'SCAN-${scanType.name}',
      source: PayAction.scan,
      payee: switch (scanType) {
        ScanPayType.shopQr => 'Mahadev Fresh Mart',
        ScanPayType.orderQr => 'Mahadev Fresh Mart',
        ScanPayType.providerQr => 'Dr Mehta Clinic',
        ScanPayType.upiId => 'Mahadev Fresh Mart',
      },
      payeeDetail: 'Verified payment account · Jodhpur',
      purpose: switch (scanType) {
        ScanPayType.shopQr => 'Counter payment',
        ScanPayType.orderQr => 'Order #MS2401',
        ScanPayType.providerQr => 'Appointment #DC108',
        ScanPayType.upiId => 'UPI payment',
      },
      amount: scanAmount,
      linkedReference: scanType == ScanPayType.orderQr
          ? 'Order #MS2401'
          : 'Payee ${_mask(scanAccount)}',
      expires: 'Current session',
      verified: true,
      amountLocked: scanType == ScanPayType.orderQr,
    );
    _clearFeedback();
    notifyListeners();
    return true;
  }

  bool selectRequest(String id) {
    final intent = requests.firstWhere((item) => item.id == id);
    selectedRequestId = id;
    if (!intent.verified) {
      activeIntent = null;
      errorMessage =
          'This sender and purpose are not verified. Payment is blocked. You can report the request.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    activeIntent = intent;
    _clearFeedback();
    notifyListeners();
    return true;
  }

  Future<bool> declineSelectedRequest() async {
    final intent = activeIntent;
    if (busy || intent == null) return false;
    busy = true;
    _clearFeedback();
    notifyListeners();
    try {
      declineReference = await _gateway.declineRequest(intent: intent);
      noticeMessage =
          'Request declined. No debit was made. Reference $declineReference saved.';
      return true;
    } on PayServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<PaymentRecord?> submitActivePayment() async {
    final intent = activeIntent;
    if (busy || intent == null) return null;
    if (!intent.verified) {
      errorMessage = 'This payee is not verified. Payment remains blocked.';
      noticeMessage = null;
      notifyListeners();
      return null;
    }
    busy = true;
    _clearFeedback();
    notifyListeners();
    try {
      final record = await _gateway.submitPayment(
        intent: intent,
        method: paymentMethod,
      );
      _upsertRecord(record);
      activeRecord = record;
      noticeMessage = switch (record.outcome) {
        PaymentOutcome.success => 'Payment confirmed and receipt saved.',
        PaymentOutcome.pending =>
          'Bank confirmation is pending. Do not pay again.',
        PaymentOutcome.failedNoDebit =>
          'The bank confirmed no debit. Safe retry is available.',
        PaymentOutcome.reversal =>
          'A debit was detected and is returning automatically.',
        PaymentOutcome.reversed =>
          'The original amount has returned to the payment method.',
      };
      return record;
    } on PayServiceException catch (error) {
      errorMessage = error.userMessage;
      return null;
    } on Object {
      errorMessage =
          'The result is not yet available. Do not pay again. Check payment status.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> refreshActiveStatus() async {
    final record = activeRecord;
    if (busy || record == null) return false;
    busy = true;
    _clearFeedback();
    notifyListeners();
    try {
      final outcome = await _gateway.refreshStatus(record: record);
      final updated = record.copyWith(
        outcome: outcome,
        refundAmount: outcome == PaymentOutcome.reversed
            ? record.intent.amount
            : record.refundAmount,
      );
      _upsertRecord(updated);
      activeRecord = updated;
      noticeMessage = switch (outcome) {
        PaymentOutcome.success => 'Bank confirmed payment. Receipt saved.',
        PaymentOutcome.pending => 'Still checking. No new payment was created.',
        PaymentOutcome.failedNoDebit =>
          'Bank confirmed no debit. You may retry safely.',
        PaymentOutcome.reversal =>
          'Return is still processing. Do not retry this payment.',
        PaymentOutcome.reversed =>
          'The original amount has returned. Record updated.',
      };
      return true;
    } on PayServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> openSupport(String reason) async {
    final record = activeRecord;
    if (busy || record == null) return false;
    busy = true;
    _clearFeedback();
    notifyListeners();
    try {
      supportCaseId = await _gateway.openSupport(
        record: record,
        reason: reason,
      );
      final updated = record.copyWith(supportCaseId: supportCaseId);
      _upsertRecord(updated);
      activeRecord = updated;
      noticeMessage =
          'Support case $supportCaseId opened with payment references attached.';
      return true;
    } on PayServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void prepareSafeRetry() {
    final record = activeRecord;
    if (record == null || record.outcome != PaymentOutcome.failedNoDebit) {
      errorMessage =
          'Retry is locked until the bank confirms that no debit occurred.';
      noticeMessage = null;
      notifyListeners();
      return;
    }
    activeIntent = record.intent;
    activeRecord = null;
    paymentMethod = record.method == ConsumerPaymentMethod.card
        ? ConsumerPaymentMethod.upi
        : ConsumerPaymentMethod.card;
    errorMessage = null;
    noticeMessage =
        'Safe retry prepared with another method. The payee and purpose are unchanged.';
    notifyListeners();
  }

  void openRecord(String id) {
    final record = recordById(id);
    if (record == null) {
      errorMessage = 'This payment record could not be found.';
      noticeMessage = null;
    } else {
      activeRecord = record;
      activeIntent = record.intent;
      _clearFeedback();
    }
    notifyListeners();
  }

  void setReceiptFilter(ReceiptFilter value) {
    receiptFilter = value;
    _clearFeedback();
    notifyListeners();
  }

  void searchReceipts(String value) {
    searchQuery = value;
    _clearFeedback();
    notifyListeners();
  }

  void showNotice(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  void clearMessages() {
    _clearFeedback();
    notifyListeners();
  }

  void resetEntry(PayAction source) {
    accountVerified = false;
    activeIntent = null;
    activeRecord = null;
    declineReference = null;
    cameraPermissionDenied = false;
    _clearFeedback();
    switch (source) {
      case PayAction.recharge:
        rechargeType = RechargeType.mobile;
        selectedChoiceId = rechargeChoices[rechargeType]!.first.id;
      case PayAction.bills:
        billType = BillType.electricity;
        selectedChoiceId = billChoices[billType]!.first.id;
      case PayAction.scan:
        scanType = ScanPayType.shopQr;
      case PayAction.requests:
        requestCategory = PayRequestCategory.pending;
    }
    notifyListeners();
  }

  void _upsertRecord(PaymentRecord record) {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      _records.insert(0, record);
    } else {
      _records[index] = record;
    }
  }

  void _clearFeedback() {
    errorMessage = null;
    noticeMessage = null;
  }

  String _mask(String value) {
    if (value.length <= 4) return value;
    return '${value.substring(0, 2)}••••${value.substring(value.length - 2)}';
  }
}
