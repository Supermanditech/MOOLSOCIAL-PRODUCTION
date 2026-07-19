enum RetailerOrderSource { counter, phone, chat }

extension RetailerOrderSourceLabel on RetailerOrderSource {
  String get label => switch (this) {
    RetailerOrderSource.counter => 'Counter',
    RetailerOrderSource.phone => 'Phone',
    RetailerOrderSource.chat => 'Chat',
  };

  String get detail => switch (this) {
    RetailerOrderSource.counter => 'Walk-in',
    RetailerOrderSource.phone => 'Call active',
    RetailerOrderSource.chat => 'Message',
  };
}

enum RetailerFulfilment { counter, ownDelivery, moolDelivery }

extension RetailerFulfilmentLabel on RetailerFulfilment {
  String get label => switch (this) {
    RetailerFulfilment.counter => 'At the shop',
    RetailerFulfilment.ownDelivery => 'Own delivery',
    RetailerFulfilment.moolDelivery => 'Mool delivery',
  };

  String get detail => switch (this) {
    RetailerFulfilment.counter => 'Give to the customer now',
    RetailerFulfilment.ownDelivery => 'Use your shop rider',
    RetailerFulfilment.moolDelivery => 'Assign a verified captain',
  };
}

enum RetailerPosPayment { cash, upi, card, paymentRequest, onDelivery, due }

extension RetailerPosPaymentLabel on RetailerPosPayment {
  String get label => switch (this) {
    RetailerPosPayment.cash => 'Cash',
    RetailerPosPayment.upi => 'UPI',
    RetailerPosPayment.card => 'Card',
    RetailerPosPayment.paymentRequest => 'Pay request',
    RetailerPosPayment.onDelivery => 'On delivery',
    RetailerPosPayment.due => 'Customer due',
  };

  String get detail => switch (this) {
    RetailerPosPayment.cash => 'Record cash received',
    RetailerPosPayment.upi => 'Confirm UPI receipt',
    RetailerPosPayment.card => 'Record card payment',
    RetailerPosPayment.paymentRequest => 'Send a secure request',
    RetailerPosPayment.onDelivery => 'Cash or UPI on delivery',
    RetailerPosPayment.due => 'Use approved customer credit',
  };
}

class RetailerPosProduct {
  const RetailerPosProduct({
    required this.id,
    required this.name,
    required this.pack,
    required this.sku,
    required this.price,
    required this.stock,
  });

  final String id;
  final String name;
  final String pack;
  final String sku;
  final int price;
  final int stock;
}

class RetailerCounter {
  RetailerCounter({
    required this.id,
    required this.number,
    required this.purpose,
    required this.operatorName,
    required this.isOpen,
    required this.orderCount,
    required this.salesAmount,
    required this.activity,
  });

  final String id;
  final int number;
  String purpose;
  String operatorName;
  bool isOpen;
  int orderCount;
  int salesAmount;
  final List<String> activity;
}

enum RetailerSaleStatus { paid, due, returned }

enum RetailerSalesBookView { sales, payments, returns }

enum RetailerSaleSource { app, counter, phone, chat }

extension RetailerSaleSourceLabel on RetailerSaleSource {
  String get label => switch (this) {
    RetailerSaleSource.app => 'App',
    RetailerSaleSource.counter => 'Counter',
    RetailerSaleSource.phone => 'Phone',
    RetailerSaleSource.chat => 'Chat',
  };

  String get mark => switch (this) {
    RetailerSaleSource.app => 'APP',
    RetailerSaleSource.counter => 'C1',
    RetailerSaleSource.phone => 'CALL',
    RetailerSaleSource.chat => 'CHAT',
  };
}

class RetailerSaleRecord {
  RetailerSaleRecord({
    required this.invoiceId,
    required this.source,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.payment,
    required this.status,
    required this.customer,
    required this.orderId,
    required this.fulfilment,
    required this.stockPosting,
    required this.margin,
  });

  final String invoiceId;
  final RetailerSaleSource source;
  final String title;
  final String subtitle;
  final int amount;
  final String payment;
  final RetailerSaleStatus status;
  final String customer;
  final String orderId;
  final String fulfilment;
  final String stockPosting;
  final String margin;
}

const reviewPosProducts = [
  RetailerPosProduct(
    id: 'oil',
    name: 'Fortune Sunflower Oil',
    pack: '1 L',
    sku: 'FRT-1L',
    price: 264,
    stock: 8,
  ),
  RetailerPosProduct(
    id: 'atta',
    name: 'Aashirvaad Atta',
    pack: '1 kg',
    sku: 'AAT-1K',
    price: 108,
    stock: 14,
  ),
  RetailerPosProduct(
    id: 'salt',
    name: 'Tata Salt',
    pack: '1 kg',
    sku: 'TSL-1K',
    price: 56,
    stock: 24,
  ),
];

List<RetailerCounter> buildReviewCounters() => [
  RetailerCounter(
    id: 'CTR-01',
    number: 1,
    purpose: 'Main Billing',
    operatorName: 'Meena',
    isOpen: true,
    orderCount: 18,
    salesAmount: 8420,
    activity: [
      'RT-3022 · Counter sale · ₹428',
      'RT-3019 · UPI paid · ₹316',
      'RT-3014 · Invoice sent · ₹264',
    ],
  ),
  RetailerCounter(
    id: 'CTR-02',
    number: 2,
    purpose: 'Express',
    operatorName: 'Rakesh',
    isOpen: true,
    orderCount: 11,
    salesAmount: 5160,
    activity: [
      'RT-3021 · 3 items · ₹486',
      'RT-3018 · Cash paid · ₹316',
      'RT-3012 · Invoice sent · ₹264',
    ],
  ),
  RetailerCounter(
    id: 'CTR-03',
    number: 3,
    purpose: 'Delivery Orders',
    operatorName: 'Unassigned',
    isOpen: false,
    orderCount: 0,
    salesAmount: 0,
    activity: [],
  ),
];

List<RetailerSaleRecord> buildReviewSales() => [
  RetailerSaleRecord(
    invoiceId: 'INV-MS-4108',
    source: RetailerSaleSource.counter,
    title: 'Counter 1 · Main Billing',
    subtitle: 'Walk-in · 6 items · 1:42 PM',
    amount: 845,
    payment: 'UPI paid',
    status: RetailerSaleStatus.paid,
    customer: 'Counter customer',
    orderId: 'POS-4108',
    fulfilment: 'At the shop',
    stockPosting: '6 units posted',
    margin: '₹118',
  ),
  RetailerSaleRecord(
    invoiceId: 'INV-MS-4107',
    source: RetailerSaleSource.app,
    title: 'MoolSocial App Order',
    subtitle: 'Meera Joshi · 4 items · 1:18 PM',
    amount: 645,
    payment: 'UPI paid',
    status: RetailerSaleStatus.paid,
    customer: 'Meera Joshi',
    orderId: 'MS-2848',
    fulfilment: 'Delivered',
    stockPosting: '4 units posted',
    margin: '₹96',
  ),
  RetailerSaleRecord(
    invoiceId: 'INV-MS-4106',
    source: RetailerSaleSource.phone,
    title: 'Phone Order',
    subtitle: 'Rakesh Sharma · 9 items · 12:54 PM',
    amount: 1240,
    payment: '₹1,240 due',
    status: RetailerSaleStatus.due,
    customer: 'Rakesh Sharma',
    orderId: 'PH-1182',
    fulfilment: 'Out for delivery',
    stockPosting: '9 units reserved',
    margin: '₹174',
  ),
  RetailerSaleRecord(
    invoiceId: 'INV-MS-4105',
    source: RetailerSaleSource.chat,
    title: 'Chat Order',
    subtitle: 'Nisha Khan · 3 items · 12:31 PM',
    amount: 420,
    payment: 'Cash received',
    status: RetailerSaleStatus.paid,
    customer: 'Nisha Khan',
    orderId: 'CH-0914',
    fulfilment: 'Collected at shop',
    stockPosting: '3 units posted',
    margin: '₹61',
  ),
  RetailerSaleRecord(
    invoiceId: 'INV-MS-4101',
    source: RetailerSaleSource.app,
    title: 'MoolSocial App Return',
    subtitle: 'Amit Jain · 1 item · 10:14 AM',
    amount: 180,
    payment: 'Refunded',
    status: RetailerSaleStatus.returned,
    customer: 'Amit Jain',
    orderId: 'MS-2839',
    fulfilment: 'Return inspected',
    stockPosting: '1 damaged unit',
    margin: '-₹34',
  ),
];
