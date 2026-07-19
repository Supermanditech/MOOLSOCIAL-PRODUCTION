enum ManufacturerHomeView { home, orders }

enum ManufacturerCatalogueMode { stock, master }

enum ManufacturerOrderDecision { full, partial, cannotFulfil }

enum ManufacturerOrderStage {
  review,
  production,
  packed,
  dispatched,
  delivered,
  receivable,
}

enum ManufacturerPurchaseTab { matched, cart, orders }

enum ManufacturerDispatchTab { ready, transit, delivered }

enum ManufacturerGrowthTab { buyers, demand, campaigns, analytics }

enum ManufacturerControlTab { claims, team, settings, support }

enum ManufacturerServiceTab { services, active, requests }

enum ManufacturerTransport { ownFleet, moolSocial }

extension ManufacturerOrderDecisionCopy on ManufacturerOrderDecision {
  String get label => switch (this) {
    ManufacturerOrderDecision.full => 'Fulfil in full',
    ManufacturerOrderDecision.partial => 'Offer partial quantity',
    ManufacturerOrderDecision.cannotFulfil => 'Cannot fulfil',
  };
}

extension ManufacturerTransportCopy on ManufacturerTransport {
  String get label => switch (this) {
    ManufacturerTransport.ownFleet => 'Own fleet',
    ManufacturerTransport.moolSocial => 'MoolSocial Transport',
  };
}

class ManufacturerProduct {
  const ManufacturerProduct({
    required this.id,
    required this.name,
    required this.pack,
    required this.hsn,
    required this.available,
    required this.reserved,
    required this.price,
    required this.moq,
    required this.terms,
    required this.live,
  });

  final String id;
  final String name;
  final String pack;
  final String hsn;
  final int available;
  final int reserved;
  final int price;
  final int moq;
  final String terms;
  final bool live;
}

class ManufacturerInputOffer {
  const ManufacturerInputOffer({
    required this.id,
    required this.name,
    required this.grade,
    required this.pack,
    required this.price,
    required this.moq,
    required this.delivery,
    required this.payment,
  });

  final String id;
  final String name;
  final String grade;
  final String pack;
  final int price;
  final int moq;
  final String delivery;
  final String payment;
}

class ManufacturerSalesOrder {
  const ManufacturerSalesOrder({
    required this.id,
    required this.buyer,
    required this.buyerType,
    required this.product,
    required this.cases,
    required this.total,
    required this.protection,
    required this.due,
  });

  final String id;
  final String buyer;
  final String buyerType;
  final String product;
  final int cases;
  final int total;
  final String protection;
  final String due;
}

class ManufacturerBookRow {
  const ManufacturerBookRow({
    required this.id,
    required this.label,
    required this.value,
    required this.detail,
  });

  final String id;
  final String label;
  final String value;
  final String detail;
}

class ManufacturerClaim {
  const ManufacturerClaim({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.hold,
  });

  final String id;
  final String type;
  final String title;
  final String detail;
  final String hold;
}

class ManufacturerTeamMember {
  const ManufacturerTeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.access,
  });

  final String id;
  final String name;
  final String role;
  final String access;
}

class ManufacturerService {
  const ManufacturerService({
    required this.id,
    required this.mark,
    required this.name,
    required this.detail,
    required this.base,
    required this.outcomeCharge,
    required this.scope,
  });

  final String id;
  final String mark;
  final String name;
  final String detail;
  final String base;
  final String outcomeCharge;
  final String scope;
}

const reviewManufacturerProducts = <ManufacturerProduct>[
  ManufacturerProduct(
    id: 'sunflower-oil',
    name: 'Shakti Sunflower Oil',
    pack: '1 L pouch · batch SF-0719',
    hsn: '1512',
    available: 1860,
    reserved: 540,
    price: 142,
    moq: 40,
    terms: '30% advance · 7 day balance',
    live: true,
  ),
  ManufacturerProduct(
    id: 'wheat-flour',
    name: 'Shakti Whole Wheat Flour',
    pack: '10 kg bag · batch AT-0716',
    hsn: '1101',
    available: 820,
    reserved: 180,
    price: 416,
    moq: 25,
    terms: '15 day approved credit',
    live: true,
  ),
  ManufacturerProduct(
    id: 'masala-tea',
    name: 'Shakti Masala Tea',
    pack: '500 g carton · master SKU',
    hsn: '0902',
    available: 0,
    reserved: 0,
    price: 188,
    moq: 20,
    terms: 'Configure before publish',
    live: false,
  ),
];

const reviewManufacturerInputs = <ManufacturerInputOffer>[
  ManufacturerInputOffer(
    id: 'oil-bulk',
    name: 'Refined sunflower oil bulk',
    grade: 'Food grade · COA included',
    pack: '18 MT tanker',
    price: 86200,
    moq: 18,
    delivery: '4–5 days',
    payment: '20% protected advance',
  ),
  ManufacturerInputOffer(
    id: 'pet-bottle',
    name: 'Food-grade PET bottle',
    grade: '1 L · verified mould',
    pack: '5,000 units',
    price: 8,
    moq: 5000,
    delivery: '6 days',
    payment: '30% advance',
  ),
  ManufacturerInputOffer(
    id: 'carton',
    name: 'Printed corrugated carton',
    grade: '5-ply · 12 bottle',
    pack: '1,000 cartons',
    price: 39,
    moq: 1000,
    delivery: '7 days',
    payment: 'On approved proof',
  ),
];

const reviewManufacturerOrders = <ManufacturerSalesOrder>[
  ManufacturerSalesOrder(
    id: 'SO-4821',
    buyer: 'Verified Rajasthan Retailer Pool',
    buyerType: 'Retailer pool',
    product: 'Shakti Sunflower Oil 1 L',
    cases: 240,
    total: 341000,
    protection: '30% protected advance',
    due: 'Confirm in 02:14',
  ),
  ManufacturerSalesOrder(
    id: 'SO-4818',
    buyer: 'Jodhpur Hotel Group',
    buyerType: 'Hotel group',
    product: 'Monthly staples supply',
    cases: 120,
    total: 192000,
    protection: 'Verified monthly account',
    due: 'Production date required',
  ),
  ManufacturerSalesOrder(
    id: 'SO-4807',
    buyer: 'Marwar Restaurant Distributor',
    buyerType: 'Distributor',
    product: 'Oil and flour mixed load',
    cases: 260,
    total: 286000,
    protection: 'Invoice and LR ready',
    due: 'Dispatch before 4 PM',
  ),
];

const reviewManufacturerBookRows = <ManufacturerBookRow>[
  ManufacturerBookRow(
    id: 'sales',
    label: 'Sales Book',
    value: '₹8.60L',
    detail: 'Orders and GST invoices',
  ),
  ManufacturerBookRow(
    id: 'purchases',
    label: 'Purchase Book',
    value: '₹3.20L',
    detail: 'Input POs and supplier bills',
  ),
  ManufacturerBookRow(
    id: 'receivables',
    label: 'Receivables',
    value: '₹4.26L',
    detail: 'Buyer ledger and protected release',
  ),
  ManufacturerBookRow(
    id: 'payables',
    label: 'Payables',
    value: '₹1.84L',
    detail: 'Supplier payment schedule',
  ),
];

const reviewManufacturerClaims = <ManufacturerClaim>[
  ManufacturerClaim(
    id: 'CLM-BUY-4771',
    type: 'Buyer',
    title: 'Buyer quantity mismatch',
    detail: 'SO-4771 · 6 cases disputed',
    hold: '₹8,352 held · response due',
  ),
  ManufacturerClaim(
    id: 'CLM-IN-2028',
    type: 'Input',
    title: 'Input quality claim',
    detail: 'PO-IN-2028 · oil grade evidence',
    hold: 'Supplier response received',
  ),
  ManufacturerClaim(
    id: 'CLM-TR-4768',
    type: 'Transport',
    title: 'Transport damage',
    detail: 'SO-4768 · carton damage',
    hold: 'Carrier evidence under review',
  ),
];

const reviewManufacturerTeam = <ManufacturerTeamMember>[
  ManufacturerTeamMember(
    id: 'owner',
    name: 'Karan Sharma',
    role: 'Owner',
    access: 'All workspace approvals · MFA on',
  ),
  ManufacturerTeamMember(
    id: 'sales',
    name: 'Priya Jain',
    role: 'Sales Manager',
    access: 'Orders, buyers and campaigns · no bank access',
  ),
  ManufacturerTeamMember(
    id: 'dispatch',
    name: 'Rakesh Kumar',
    role: 'Dispatch',
    access: 'Packing, documents and tracking',
  ),
  ManufacturerTeamMember(
    id: 'accounts',
    name: 'Meera Joshi',
    role: 'Accountant',
    access: 'Books, GST and reconciliation',
  ),
];

const reviewManufacturerServices = <ManufacturerService>[
  ManufacturerService(
    id: 'sales',
    mark: 'SALE',
    name: 'Exclusive Product Sales Contract',
    detail: 'Dedicated execution for selected products and territory',
    base: 'From ₹2,999/mo',
    outcomeCharge: 'Approved-sales success fee',
    scope: 'Area to national',
  ),
  ManufacturerService(
    id: 'logistics',
    mark: 'MOVE',
    name: 'Product Pickup & Delivery',
    detail: 'Factory pickup, line-haul, hubs and buyer delivery',
    base: 'From ₹999/mo',
    outcomeCharge: 'Per completed movement',
    scope: 'Route based',
  ),
  ManufacturerService(
    id: 'ads',
    mark: 'ADV',
    name: 'Advertising & Sales Campaign',
    detail: 'Regional, state or national outcome campaign',
    base: 'From ₹1,499/mo',
    outcomeCharge: 'Outcome-linked option',
    scope: 'Geo targeted',
  ),
  ManufacturerService(
    id: 'tax',
    mark: 'GST',
    name: 'GST, Tax, Accounts & Audit',
    detail: 'Books, returns, ITR and qualified audit coordination',
    base: 'From ₹1,999/mo',
    outcomeCharge: 'Professional scope priced',
    scope: 'India compliance',
  ),
  ManufacturerService(
    id: 'source',
    mark: 'SRC',
    name: 'Exclusive Input Sourcing',
    detail: 'Confirmed raw material and packaging categories',
    base: 'From ₹2,499/mo',
    outcomeCharge: 'Savings or supply outcome',
    scope: 'Category + territory',
  ),
];
