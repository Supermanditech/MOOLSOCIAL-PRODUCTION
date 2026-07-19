enum RetailerWholesaleCategory { all, deals, fastDelivery, credit, brands }

extension RetailerWholesaleCategoryLabel on RetailerWholesaleCategory {
  String get label => switch (this) {
    RetailerWholesaleCategory.all => 'All',
    RetailerWholesaleCategory.deals => 'Deals',
    RetailerWholesaleCategory.fastDelivery => 'Fast delivery',
    RetailerWholesaleCategory.credit => 'Credit',
    RetailerWholesaleCategory.brands => 'Brands',
  };
}

class RetailerWholesaleProduct {
  const RetailerWholesaleProduct({
    required this.id,
    required this.brand,
    required this.name,
    required this.pack,
    required this.casePrice,
    required this.moq,
    required this.delivery,
    required this.payment,
    required this.offer,
    required this.availableCases,
  });

  final String id;
  final String brand;
  final String name;
  final String pack;
  final int casePrice;
  final int moq;
  final String delivery;
  final String payment;
  final String offer;
  final int availableCases;
}

enum RetailerPurchaseOrderStage {
  confirmed,
  dispatched,
  inTransit,
  delivered,
  received,
  issueOpen,
}

class RetailerPurchaseOrder {
  RetailerPurchaseOrder({
    required this.id,
    required this.supplier,
    required this.productId,
    required this.productName,
    required this.cases,
    required this.value,
    required this.deliveryMode,
    required this.deliveryWindow,
    required this.paymentTerm,
    this.stage = RetailerPurchaseOrderStage.confirmed,
  });

  final String id;
  final String supplier;
  final String productId;
  final String productName;
  final int cases;
  final int value;
  final String deliveryMode;
  final String deliveryWindow;
  final String paymentTerm;
  RetailerPurchaseOrderStage stage;
}

enum RetailerGoodsReceiptChoice { pending, accepted, issue }

enum RetailerGoodsIssue {
  shortQuantity,
  damaged,
  wrongProduct,
  invoiceMismatch,
}

extension RetailerGoodsIssueLabel on RetailerGoodsIssue {
  String get label => switch (this) {
    RetailerGoodsIssue.shortQuantity => 'Short quantity',
    RetailerGoodsIssue.damaged => 'Damaged goods',
    RetailerGoodsIssue.wrongProduct => 'Wrong product',
    RetailerGoodsIssue.invoiceMismatch => 'Invoice mismatch',
  };
}

class RetailerPurchaseRecord {
  RetailerPurchaseRecord({
    required this.id,
    required this.supplier,
    required this.summary,
    required this.amount,
    required this.source,
    required this.status,
    required this.invoiceId,
    required this.poId,
    required this.grnId,
  });

  final String id;
  final String supplier;
  final String summary;
  final int amount;
  final String source;
  String status;
  final String invoiceId;
  final String poId;
  final String grnId;
}

enum RetailerPurchaseBookView { purchases, payables, returns }

enum RetailerSupplierPaymentMethod { upi, bankTransfer }

extension RetailerSupplierPaymentMethodLabel on RetailerSupplierPaymentMethod {
  String get label => switch (this) {
    RetailerSupplierPaymentMethod.upi => 'UPI',
    RetailerSupplierPaymentMethod.bankTransfer => 'Bank transfer',
  };
}

enum RetailerSupplierPaymentState {
  notStarted,
  processing,
  settled,
  failed,
  reversed,
}

extension RetailerSupplierPaymentStateLabel on RetailerSupplierPaymentState {
  String get label => switch (this) {
    RetailerSupplierPaymentState.notStarted => 'Ready',
    RetailerSupplierPaymentState.processing => 'Processing',
    RetailerSupplierPaymentState.settled => 'Paid',
    RetailerSupplierPaymentState.failed => 'Failed',
    RetailerSupplierPaymentState.reversed => 'Reversed',
  };
}

const reviewWholesaleProducts = [
  RetailerWholesaleProduct(
    id: 'oil-case',
    brand: 'Fortune',
    name: 'Sunflower Oil',
    pack: '10 × 1 L per case',
    casePrice: 1320,
    moq: 2,
    delivery: 'Tomorrow',
    payment: 'Protected advance',
    offer: 'Save ₹160',
    availableCases: 18,
  ),
  RetailerWholesaleProduct(
    id: 'atta-case',
    brand: 'Aashirvaad',
    name: 'Whole Wheat Atta',
    pack: '4 × 5 kg per case',
    casePrice: 952,
    moq: 3,
    delivery: '2 days',
    payment: 'Pay on delivery',
    offer: 'Best landed cost',
    availableCases: 24,
  ),
  RetailerWholesaleProduct(
    id: 'tea-case',
    brand: 'Tata',
    name: 'Premium Tea',
    pack: '12 × 500 g per case',
    casePrice: 2568,
    moq: 1,
    delivery: 'Today',
    payment: '15-day credit',
    offer: 'Credit eligible',
    availableCases: 9,
  ),
  RetailerWholesaleProduct(
    id: 'soap-case',
    brand: 'Surf Excel',
    name: 'Detergent Bar',
    pack: '24 × 250 g per case',
    casePrice: 864,
    moq: 2,
    delivery: 'Tomorrow',
    payment: 'Pay on delivery',
    offer: '2% case discount',
    availableCases: 40,
  ),
];

List<RetailerPurchaseRecord> buildReviewPurchaseRecords() => [
  RetailerPurchaseRecord(
    id: 'PUR-85021',
    supplier: 'Jodhpur Authorised Distributor',
    summary: 'Aashirvaad Atta · 3 cases · 12 packs',
    amount: 2856,
    source: 'MoolSocial PO',
    status: 'Processing',
    invoiceId: 'INV-SM-2941',
    poId: 'PO-MS-8202',
    grnId: 'GRN-85021',
  ),
  RetailerPurchaseRecord(
    id: 'PUR-8178',
    supplier: 'Rajasthan Tea Distribution',
    summary: 'Tata Premium Tea · 1 case · 12 packs',
    amount: 2568,
    source: 'MoolSocial PO',
    status: 'Due 25 Jul',
    invoiceId: 'INV-RTD-665',
    poId: 'PO-MS-8178',
    grnId: 'GRN-8178',
  ),
  RetailerPurchaseRecord(
    id: 'PUR-440',
    supplier: 'Jodhpur Dairy Supply',
    summary: 'Milk, curd and paneer · 6 lines',
    amount: 6480,
    source: 'Direct bill',
    status: 'Paid',
    invoiceId: 'INV-JDS-440',
    poId: 'Direct',
    grnId: 'Stock posted',
  ),
];
