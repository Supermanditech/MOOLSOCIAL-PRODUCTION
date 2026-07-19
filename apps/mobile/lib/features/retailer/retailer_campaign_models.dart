enum RetailerCustomerFilter { all, repeat, due, allowed, issue }

extension RetailerCustomerFilterLabel on RetailerCustomerFilter {
  String get label => switch (this) {
    RetailerCustomerFilter.all => 'All',
    RetailerCustomerFilter.repeat => 'Repeat',
    RetailerCustomerFilter.due => 'Due',
    RetailerCustomerFilter.allowed => 'Allowed',
    RetailerCustomerFilter.issue => 'Issue',
  };
}

enum RetailerMessageChannel { moolChat, whatsapp, sms }

extension RetailerMessageChannelLabel on RetailerMessageChannel {
  String get label => switch (this) {
    RetailerMessageChannel.moolChat => 'Mool Chat',
    RetailerMessageChannel.whatsapp => 'WhatsApp',
    RetailerMessageChannel.sms => 'SMS',
  };
}

class RetailerCustomer {
  const RetailerCustomer({
    required this.id,
    required this.name,
    required this.orders,
    required this.lastBuy,
    required this.fulfilment,
    required this.summary,
    required this.detail,
    required this.repeat,
    required this.allowed,
    required this.due,
    required this.issue,
  });

  final String id;
  final String name;
  final int orders;
  final String lastBuy;
  final String fulfilment;
  final String summary;
  final String detail;
  final bool repeat;
  final bool allowed;
  final bool due;
  final bool issue;

  bool matches(RetailerCustomerFilter filter) => switch (filter) {
    RetailerCustomerFilter.all => true,
    RetailerCustomerFilter.repeat => repeat,
    RetailerCustomerFilter.due => due,
    RetailerCustomerFilter.allowed => allowed,
    RetailerCustomerFilter.issue => issue,
  };
}

const reviewRetailerCustomers = <RetailerCustomer>[
  RetailerCustomer(
    id: 'sharma',
    name: 'Sharma Family',
    orders: 18,
    lastBuy: '4 days ago',
    fulfilment: 'Home delivery',
    summary: 'Basket ready · ₹645',
    detail: 'Offers allowed',
    repeat: true,
    allowed: true,
    due: false,
    issue: false,
  ),
  RetailerCustomer(
    id: 'rukmani',
    name: 'Rukmani Devi',
    orders: 11,
    lastBuy: '8 days ago',
    fulfilment: 'Counter pickup',
    summary: 'Credit due ₹1,240',
    detail: 'Invoice only · marketing off',
    repeat: false,
    allowed: false,
    due: true,
    issue: false,
  ),
  RetailerCustomer(
    id: 'arjun',
    name: 'Arjun Singh',
    orders: 7,
    lastBuy: '12 days ago',
    fulfilment: 'Counter pickup',
    summary: 'Last basket ₹392',
    detail: 'Back-in-stock allowed · Mool Chat',
    repeat: true,
    allowed: true,
    due: false,
    issue: false,
  ),
  RetailerCustomer(
    id: 'meena',
    name: 'Meena Joshi',
    orders: 6,
    lastBuy: '16 days ago',
    fulfilment: 'Home delivery',
    summary: 'Issue MS-2848',
    detail: 'Replacement awaiting response',
    repeat: false,
    allowed: false,
    due: false,
    issue: true,
  ),
];

enum RetailerCampaignFilter { all, active, draft, completed, loyalty }

extension RetailerCampaignFilterLabel on RetailerCampaignFilter {
  String get label => switch (this) {
    RetailerCampaignFilter.all => 'All',
    RetailerCampaignFilter.active => 'Active',
    RetailerCampaignFilter.draft => 'Drafts',
    RetailerCampaignFilter.completed => 'Completed',
    RetailerCampaignFilter.loyalty => 'Loyalty',
  };
}

enum RetailerCampaignState { active, paused, draft, completed }

enum RetailerCampaignObjective {
  increaseSales,
  bringCustomersBack,
  clearSlowStock,
  reachNewArea,
}

extension RetailerCampaignObjectiveLabel on RetailerCampaignObjective {
  String get label => switch (this) {
    RetailerCampaignObjective.increaseSales => 'Increase sales',
    RetailerCampaignObjective.bringCustomersBack => 'Bring customers back',
    RetailerCampaignObjective.clearSlowStock => 'Clear slow stock',
    RetailerCampaignObjective.reachNewArea => 'Reach new area',
  };
}

enum RetailerCampaignAudience {
  repeatCustomers,
  nearbyCustomers,
  loyaltyEligible,
  newArea,
}

extension RetailerCampaignAudienceLabel on RetailerCampaignAudience {
  String get label => switch (this) {
    RetailerCampaignAudience.repeatCustomers => 'Repeat customers',
    RetailerCampaignAudience.nearbyCustomers => 'Nearby customers',
    RetailerCampaignAudience.loyaltyEligible => 'Loyalty eligible',
    RetailerCampaignAudience.newArea => 'New area',
  };
}

enum RetailerCampaignBenefit { basketSaving, percentOff, freeDelivery }

extension RetailerCampaignBenefitLabel on RetailerCampaignBenefit {
  String get label => switch (this) {
    RetailerCampaignBenefit.basketSaving => '₹40 basket saving',
    RetailerCampaignBenefit.percentOff => '5% off',
    RetailerCampaignBenefit.freeDelivery => 'Free delivery',
  };
}

enum RetailerCampaignChannel { moolSocial, permittedWhatsApp }

extension RetailerCampaignChannelLabel on RetailerCampaignChannel {
  String get label => switch (this) {
    RetailerCampaignChannel.moolSocial => 'MoolSocial',
    RetailerCampaignChannel.permittedWhatsApp => 'Permitted WhatsApp',
  };
}

class RetailerCampaignProduct {
  const RetailerCampaignProduct({
    required this.id,
    required this.name,
    required this.available,
    required this.price,
    required this.margin,
  });

  final String id;
  final String name;
  final int available;
  final int price;
  final int margin;
}

const reviewCampaignProducts = <RetailerCampaignProduct>[
  RetailerCampaignProduct(
    id: 'atta',
    name: 'Aashirvaad Atta 5 kg',
    available: 32,
    price: 286,
    margin: 12,
  ),
  RetailerCampaignProduct(
    id: 'oil',
    name: 'Fortune Oil 1 L',
    available: 48,
    price: 132,
    margin: 10,
  ),
  RetailerCampaignProduct(
    id: 'rice',
    name: 'India Gate Rice 5 kg',
    available: 18,
    price: 499,
    margin: 9,
  ),
];

class RetailerCampaign {
  RetailerCampaign({
    required this.id,
    required this.title,
    required this.detail,
    required this.state,
    required this.paidSales,
    required this.spend,
    required this.result,
    this.loyalty = false,
  });

  final String id;
  final String title;
  final String detail;
  RetailerCampaignState state;
  final int paidSales;
  final int spend;
  final String result;
  final bool loyalty;
}

List<RetailerCampaign> buildReviewRetailerCampaigns() => [
  RetailerCampaign(
    id: 'monthly',
    title: 'Monthly staples · Jodhpur 5 km',
    detail: 'Repeat customers · MoolSocial + permitted WhatsApp',
    state: RetailerCampaignState.active,
    paidSales: 31450,
    spend: 2130,
    result: '4.8× return',
  ),
  RetailerCampaign(
    id: 'festival',
    title: 'Festival loyalty basket',
    detail: 'Eligible customers · 180 redemptions maximum',
    state: RetailerCampaignState.active,
    paidSales: 11230,
    spend: 1110,
    result: '54 customers',
    loyalty: true,
  ),
  RetailerCampaign(
    id: 'oil',
    title: 'Back-in-stock: Fortune Oil',
    detail: '142 customers allowed · stock 48 units',
    state: RetailerCampaignState.draft,
    paidSales: 0,
    spend: 0,
    result: 'Ready to continue',
  ),
  RetailerCampaign(
    id: 'monsoon',
    title: 'Monsoon home-care bundle',
    detail: 'Completed · final attribution locked',
    state: RetailerCampaignState.completed,
    paidSales: 18820,
    spend: 1420,
    result: '3.2× return',
  ),
];
