enum RetailerStockMovementType {
  received,
  sold,
  reserved,
  returned,
  damage,
  adjusted,
}

extension RetailerStockMovementTypeLabel on RetailerStockMovementType {
  String get label => switch (this) {
    RetailerStockMovementType.received => 'Received',
    RetailerStockMovementType.sold => 'Sold',
    RetailerStockMovementType.reserved => 'Reserved',
    RetailerStockMovementType.returned => 'Returns',
    RetailerStockMovementType.damage => 'Damage',
    RetailerStockMovementType.adjusted => 'Count',
  };
}

class RetailerStockMovement {
  const RetailerStockMovement({
    required this.id,
    required this.product,
    required this.sku,
    required this.source,
    required this.reference,
    required this.change,
    required this.balance,
    required this.type,
  });

  final String id;
  final String product;
  final String sku;
  final String source;
  final String reference;
  final int change;
  final int balance;
  final RetailerStockMovementType type;
}

class RetailerStockCheck {
  const RetailerStockCheck({
    required this.id,
    required this.product,
    required this.reason,
    required this.action,
  });

  final String id;
  final String product;
  final String reason;
  final String action;
}

enum RetailerStockStatementView { movements, checks }

enum RetailerStockAdjustmentKind {
  physicalCount,
  damageOrExpiry,
  supplierReturn,
}

extension RetailerStockAdjustmentKindLabel on RetailerStockAdjustmentKind {
  String get label => switch (this) {
    RetailerStockAdjustmentKind.physicalCount => 'Physical stock count',
    RetailerStockAdjustmentKind.damageOrExpiry => 'Damage or expiry',
    RetailerStockAdjustmentKind.supplierReturn => 'Supplier return',
  };
}

enum RetailerBusinessPeriod { today, week, month, custom }

extension RetailerBusinessPeriodLabel on RetailerBusinessPeriod {
  String get label => switch (this) {
    RetailerBusinessPeriod.today => 'Today',
    RetailerBusinessPeriod.week => 'This week',
    RetailerBusinessPeriod.month => 'July 2026',
    RetailerBusinessPeriod.custom => 'Custom',
  };
}

class RetailerExpense {
  const RetailerExpense({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.method,
    required this.evidenceAttached,
  });

  final String id;
  final int amount;
  final String category;
  final String note;
  final String method;
  final bool evidenceAttached;
}

class RetailerMoneyException {
  RetailerMoneyException({
    required this.id,
    required this.title,
    required this.detail,
    required this.action,
    this.resolved = false,
  });

  final String id;
  final String title;
  final String detail;
  final String action;
  bool resolved;
}

const reviewStockMovements = [
  RetailerStockMovement(
    id: 'MOV-GRN-85021',
    product: 'Aashirvaad Atta 5 kg',
    sku: 'AASH-ATTA-5KG',
    source: 'Accepted goods receipt',
    reference: 'GRN-85021 · PO-MS-8202',
    change: 12,
    balance: 28,
    type: RetailerStockMovementType.received,
  ),
  RetailerStockMovement(
    id: 'MOV-MSI-3028',
    product: 'Fortune Sunflower Oil 1 L',
    sku: 'FRT-1L',
    source: 'Completed counter sale',
    reference: 'MSI-3028 · Counter 1',
    change: -1,
    balance: 7,
    type: RetailerStockMovementType.sold,
  ),
  RetailerStockMovement(
    id: 'MOV-ORDER-2841',
    product: 'Tata Salt 1 kg',
    sku: 'TATA-SALT-1KG',
    source: 'Accepted customer order',
    reference: 'MS-2841 · reserved',
    change: -2,
    balance: 18,
    type: RetailerStockMovementType.reserved,
  ),
  RetailerStockMovement(
    id: 'MOV-RETURN-118',
    product: 'Surf Excel Bar 250 g',
    sku: 'SURF-BAR-250',
    source: 'Inspected customer return',
    reference: 'RET-118 · sellable',
    change: 1,
    balance: 31,
    type: RetailerStockMovementType.returned,
  ),
  RetailerStockMovement(
    id: 'MOV-DAMAGE-44',
    product: 'Fresh Milk 1 L',
    sku: 'MILK-1L',
    source: 'Expiry recorded by owner',
    reference: 'ADJ-44 · evidence attached',
    change: -3,
    balance: 9,
    type: RetailerStockMovementType.damage,
  ),
];

const reviewStockChecks = [
  RetailerStockCheck(
    id: 'CHECK-COUNT',
    product: 'Fortune Sunflower Oil 1 L',
    reason: 'System 7 · last physical count 9',
    action: 'Count',
  ),
  RetailerStockCheck(
    id: 'CHECK-EXPIRY',
    product: 'Fresh Milk 1 L',
    reason: '3 packs expire tomorrow',
    action: 'Review',
  ),
  RetailerStockCheck(
    id: 'CHECK-FAST',
    product: 'Tata Salt 1 kg',
    reason: 'Fast selling · 2 reserved',
    action: 'Reorder',
  ),
];

List<RetailerMoneyException> buildReviewMoneyExceptions() => [
  RetailerMoneyException(
    id: 'MONEY-UPI-620',
    title: 'UPI settlement short by ₹620',
    detail: 'Provider batch UPI-1107 · expected tomorrow',
    action: 'Review',
  ),
  RetailerMoneyException(
    id: 'MONEY-CASH-1240',
    title: 'Cash count difference ₹1,240',
    detail: 'Counter 2 · operator explanation needed',
    action: 'Resolve',
  ),
  RetailerMoneyException(
    id: 'MONEY-BILL-850',
    title: 'Expense bill not attached',
    detail: 'Packaging ₹850 · evidence pending',
    action: 'Add bill',
  ),
];
