enum RetailerRecoveryRoute {
  customerOffer,
  retailerTransfer,
  bundle,
  supplierClaim,
}

extension RetailerRecoveryRouteLabel on RetailerRecoveryRoute {
  String get label => switch (this) {
    RetailerRecoveryRoute.customerOffer => 'Customer offer',
    RetailerRecoveryRoute.retailerTransfer => 'Retailer transfer',
    RetailerRecoveryRoute.bundle => 'Build a bundle',
    RetailerRecoveryRoute.supplierClaim => 'Supplier claim',
  };

  String get detail => switch (this) {
    RetailerRecoveryRoute.customerOffer => 'Nearby verified demand',
    RetailerRecoveryRoute.retailerTransfer =>
      'Nearby shops bid above your floor',
    RetailerRecoveryRoute.bundle => 'Pair with faster products',
    RetailerRecoveryRoute.supplierClaim =>
      'Only where invoice return terms allow',
  };
}

class RetailerSlowStockItem {
  const RetailerSlowStockItem({
    required this.id,
    required this.name,
    required this.available,
    required this.detail,
    required this.guidance,
    required this.floor,
  });

  final String id;
  final String name;
  final int available;
  final String detail;
  final String guidance;
  final int floor;
}

const reviewSlowStock = <RetailerSlowStockItem>[
  RetailerSlowStockItem(
    id: 'detergent',
    name: 'Surf Excel 1 kg',
    available: 24,
    detail: 'No sale 38 days · buy ₹112 · sell ₹128',
    guidance: 'Suggested floor ₹116 · recover ₹2,784',
    floor: 116,
  ),
  RetailerSlowStockItem(
    id: 'biscuits',
    name: 'Premium Biscuits',
    available: 36,
    detail: 'Slow 27 days · best before 92 days',
    guidance: 'Suggested bundle · protect 8% margin',
    floor: 38,
  ),
  RetailerSlowStockItem(
    id: 'juice',
    name: 'Mango Juice 1 L',
    available: 18,
    detail: 'Sell-by priority · 41 days remaining',
    guidance: 'Customer offer recommended',
    floor: 72,
  ),
];

enum RetailerStaffRole {
  counterOperator,
  stockOperator,
  procurementOperator,
  deliveryCoordinator,
  accountant,
  marketingOperator,
  manager,
}

extension RetailerStaffRoleLabel on RetailerStaffRole {
  String get label => switch (this) {
    RetailerStaffRole.counterOperator => 'Counter Operator',
    RetailerStaffRole.stockOperator => 'Stock Operator',
    RetailerStaffRole.procurementOperator => 'Procurement Operator',
    RetailerStaffRole.deliveryCoordinator => 'Delivery Coordinator',
    RetailerStaffRole.accountant => 'Accountant',
    RetailerStaffRole.marketingOperator => 'Marketing Operator',
    RetailerStaffRole.manager => 'Manager',
  };
}

class RetailerStaffMember {
  RetailerStaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.access,
    required this.activity,
    this.owner = false,
    this.paused = false,
  });

  final String id;
  final String name;
  final String role;
  final String access;
  final String activity;
  final bool owner;
  bool paused;
}

List<RetailerStaffMember> buildReviewStaff() => [
  RetailerStaffMember(
    id: 'jitendra',
    name: 'Jitendra Kumar',
    role: 'Owner',
    access: 'All controls · verified device',
    activity: 'Active now',
    owner: true,
  ),
  RetailerStaffMember(
    id: 'rakesh',
    name: 'Rakesh Kumar',
    role: 'Counter',
    access: 'Counter 1 · sales and invoices up to ₹25,000',
    activity: 'Active now',
  ),
  RetailerStaffMember(
    id: 'sunita',
    name: 'Sunita Parihar',
    role: 'Stock',
    access: 'Quantity, catalogue and goods receipt',
    activity: 'Last active 24 min ago',
  ),
  RetailerStaffMember(
    id: 'vikas',
    name: 'Vikas Mehta',
    role: 'Accountant',
    access: 'Books/export · device review required',
    activity: 'Access paused',
    paused: true,
  ),
];

enum RetailerIssueFilter { all, action, replacement, refund, closed }

extension RetailerIssueFilterLabel on RetailerIssueFilter {
  String get label => switch (this) {
    RetailerIssueFilter.all => 'All',
    RetailerIssueFilter.action => 'Need action',
    RetailerIssueFilter.replacement => 'Replacement',
    RetailerIssueFilter.refund => 'Refund',
    RetailerIssueFilter.closed => 'Closed',
  };
}

enum RetailerIssueResolution { replace, refund, requestEvidence }

extension RetailerIssueResolutionLabel on RetailerIssueResolution {
  String label(int amount) => switch (this) {
    RetailerIssueResolution.replace => 'Replace item',
    RetailerIssueResolution.refund => 'Refund ₹$amount',
    RetailerIssueResolution.requestEvidence => 'Request evidence',
  };
}

class RetailerCustomerIssue {
  RetailerCustomerIssue({
    required this.id,
    required this.title,
    required this.customer,
    required this.detail,
    required this.status,
    required this.amount,
    required this.states,
    required this.timeline,
    required this.message,
    required this.evidenceAction,
    this.resolved = false,
  });

  final String id;
  final String title;
  final String customer;
  final String detail;
  final String status;
  final int amount;
  final Set<RetailerIssueFilter> states;
  final List<String> timeline;
  final String message;
  final String evidenceAction;
  bool resolved;
}

List<RetailerCustomerIssue> buildReviewCustomerIssues() => [
  RetailerCustomerIssue(
    id: 'MS-2848',
    title: 'Damaged item',
    customer: 'Meena Joshi',
    detail: 'Fortune Oil 1 L · photo received',
    status: 'Respond in 42 min',
    amount: 132,
    states: {RetailerIssueFilter.action, RetailerIssueFilter.replacement},
    timeline: [
      '11:08 AM · Customer uploaded the damaged-item photo',
      '11:09 AM · ₹132 protected; shop notified',
      'Now · Review photo, packing proof and choose a resolution',
    ],
    message: 'We reviewed your photo and can replace this item today.',
    evidenceAction: 'Review photo and order evidence',
  ),
  RetailerCustomerIssue(
    id: 'MS-2843',
    title: 'Missing item',
    customer: 'Rukmani Devi',
    detail: 'Bill and packing proof differ',
    status: 'Shop response needed',
    amount: 86,
    states: {RetailerIssueFilter.action, RetailerIssueFilter.refund},
    timeline: [
      '10:34 AM · Customer reported one missing basket item',
      '10:36 AM · Bill and packing proof mismatch found',
      'Now · Review the ₹86 line and confirm refund or evidence request',
    ],
    message:
        'We found a mismatch between your bill and packing proof. We are reviewing the missing item now.',
    evidenceAction: 'Review bill and packing proof',
  ),
  RetailerCustomerIssue(
    id: 'MS-2831',
    title: 'Replacement accepted',
    customer: 'Customer confirmation awaited',
    detail: 'Fresh item reserved',
    status: 'Delivery tomorrow',
    amount: 0,
    states: {RetailerIssueFilter.replacement},
    timeline: [
      '8 Jul · Replacement accepted by the customer',
      'Today · Fresh item reserved',
      'Next · Delivery is scheduled for tomorrow',
    ],
    message: 'Your replacement is reserved for delivery tomorrow.',
    evidenceAction: 'Track replacement',
  ),
  RetailerCustomerIssue(
    id: 'MS-2790',
    title: 'Refund completed',
    customer: 'Refund proof',
    detail: '₹42 returned to UPI · credit note posted',
    status: 'Closed 9 Jul',
    amount: 42,
    states: {RetailerIssueFilter.closed, RetailerIssueFilter.refund},
    timeline: [
      '9 Jul · ₹42 refund approved',
      '9 Jul · UPI reversal completed',
      '9 Jul · Credit note CN-2790 posted',
    ],
    message: 'Your ₹42 refund and credit note are available.',
    evidenceAction: 'View refund proof and credit note',
    resolved: true,
  ),
];
