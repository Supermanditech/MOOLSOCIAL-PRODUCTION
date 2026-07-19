enum CreatorPublishFormat { reel, youtube, text, image }

enum CreatorContentTab { published, drafts, scheduled, unavailable }

enum CreatorPerformanceWindow { sevenDays, twentyEightDays, ninetyDays }

enum CreatorPerformanceView { content, campaigns }

enum CreatorCampaignTab { bestFit, awareness, conversion, saved, active }

enum CreatorEarningsTab { overview, ledger, payouts }

enum CreatorControlArea {
  identity,
  profile,
  rights,
  disclosure,
  team,
  safety,
  security,
}

enum YouTubeConnectStep { source, action, review, complete }

class CreatorContentItem {
  const CreatorContentItem({
    required this.id,
    required this.title,
    required this.format,
    required this.detail,
    required this.outcome,
    required this.status,
    this.youtube = false,
  });

  final String id;
  final String title;
  final String format;
  final String detail;
  final String outcome;
  final String status;
  final bool youtube;
}

class CreatorCampaign {
  const CreatorCampaign({
    required this.id,
    required this.title,
    required this.sponsor,
    required this.fit,
    required this.deadline,
    required this.format,
    required this.fixedPay,
    required this.outcomePay,
    required this.geography,
    required this.disclosure,
    required this.attribution,
    this.active = false,
  });

  final String id;
  final String title;
  final String sponsor;
  final int fit;
  final String deadline;
  final String format;
  final int fixedPay;
  final String outcomePay;
  final String geography;
  final String disclosure;
  final String attribution;
  final bool active;
}

class CreatorLedgerItem {
  const CreatorLedgerItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.amount,
    required this.status,
  });

  final String id;
  final String title;
  final String detail;
  final String amount;
  final String status;
}

class CreatorMembershipPlan {
  const CreatorMembershipPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.monthlyNet,
    required this.members,
    required this.promise,
  });

  final String id;
  final String name;
  final int monthlyPrice;
  final int yearlyPrice;
  final int monthlyNet;
  final int members;
  final String promise;
}

const reviewCreatorContent = <CreatorContentItem>[
  CreatorContentItem(
    id: 'CNT-126-MORNING-REEL',
    title: 'Fresh basket packed this morning',
    format: 'MoolSocial Reel · 46 sec',
    detail: '2 days remaining · expires automatically',
    outcome: '₹3,500 funded placement',
    status: 'Published',
  ),
  CreatorContentItem(
    id: 'CNT-126-LOCAL-BASKET',
    title: 'How local baskets save time',
    format: 'YouTube Short',
    detail: '48.2K views · connected to Monthly Fresh Basket',
    outcome: '126 paid orders · ₹2,840 payable',
    status: 'Published',
    youtube: true,
  ),
  CreatorContentItem(
    id: 'CNT-126-MARKET-GUIDE',
    title: 'Jodhpur market price guide',
    format: 'YouTube video · 18 min',
    detail: '12.6K views · public and available',
    outcome: '684 informed actions',
    status: 'Published',
    youtube: true,
  ),
  CreatorContentItem(
    id: 'CNT-126-ASK',
    title: 'Ask before you buy',
    format: 'Text post',
    detail: '1,206 audience actions',
    outcome: '326 useful replies',
    status: 'Published',
  ),
  CreatorContentItem(
    id: 'CNT-126-INTRO',
    title: 'Creator introduction',
    format: 'Image post',
    detail: 'Caption and rights ready',
    outcome: 'Continue editing',
    status: 'Draft',
  ),
  CreatorContentItem(
    id: 'CNT-126-FESTIVAL',
    title: 'Festival buying guide',
    format: 'YouTube video',
    detail: 'Scheduled · 24 Jul, 6 PM',
    outcome: 'Mool action ready',
    status: 'Scheduled',
    youtube: true,
  ),
  CreatorContentItem(
    id: 'CNT-126-UNAVAILABLE',
    title: 'Old channel introduction',
    format: 'YouTube video',
    detail: 'Private on YouTube',
    outcome: 'Make public on YouTube or replace it',
    status: 'Unavailable',
    youtube: true,
  ),
];

const reviewCreatorCampaigns = <CreatorCampaign>[
  CreatorCampaign(
    id: 'CR-2048',
    title: 'Explain smarter local grocery buying',
    sponsor: 'MoolSocial Funded Campaign',
    fit: 94,
    deadline: 'Closes in 18 hours',
    format: 'YouTube Short · up to 60 sec',
    fixedPay: 3500,
    outcomePay: '₹40 per paid order',
    geography: 'Jodhpur',
    disclosure: 'Paid partnership',
    attribution: '7 days',
  ),
  CreatorCampaign(
    id: 'CR-2051',
    title: 'Small retailer digital payment guide',
    sponsor: 'Verified Manufacturer Campaign',
    fit: 88,
    deadline: 'Closes in 3 days',
    format: 'YouTube video · 4–6 min',
    fixedPay: 8000,
    outcomePay: 'Education objective',
    geography: 'Rajasthan',
    disclosure: 'Paid partnership',
    attribution: '7 days',
  ),
  CreatorCampaign(
    id: 'CR-2039',
    title: 'Jodhpur restaurant discovery',
    sponsor: 'MoolSocial Local Campaign',
    fit: 91,
    deadline: 'Deliverable due today',
    format: '1 connected YouTube Short',
    fixedPay: 4500,
    outcomePay: 'Approved deliverable',
    geography: 'Jodhpur',
    disclosure: 'Paid partnership',
    attribution: '3 days',
    active: true,
  ),
];

const reviewCreatorLedger = <CreatorLedgerItem>[
  CreatorLedgerItem(
    id: 'LED-130-BASKET',
    title: 'Local basket campaign',
    detail: '126 paid orders · attribution closed',
    amount: '+₹5,040',
    status: 'Available',
  ),
  CreatorLedgerItem(
    id: 'LED-130-RESTAURANT',
    title: 'Restaurant discovery',
    detail: 'Fixed deliverable approved',
    amount: '+₹4,500',
    status: 'Available',
  ),
  CreatorLedgerItem(
    id: 'LED-130-PAYOUT',
    title: 'Prior payout',
    detail: 'Bank ••4421 · 8 Jul',
    amount: '−₹6,380',
    status: 'Paid',
  ),
  CreatorLedgerItem(
    id: 'LED-130-TDS',
    title: 'Applicable tax deduction',
    detail: 'Included in July statement',
    amount: '−₹220',
    status: 'Recorded',
  ),
];

const reviewCreatorMembershipPlans = <CreatorMembershipPlan>[
  CreatorMembershipPlan(
    id: 'local-insider',
    name: 'Local Insider',
    monthlyPrice: 99,
    yearlyPrice: 999,
    monthlyNet: 89,
    members: 214,
    promise: 'Early local guides, member polls and monthly live Q&A',
  ),
  CreatorMembershipPlan(
    id: 'business-circle',
    name: 'Business Circle',
    monthlyPrice: 249,
    yearlyPrice: 2499,
    monthlyNet: 224,
    members: 72,
    promise: 'Business explainers, templates and member questions',
  ),
];

const creatorMoolActions = <String, String>{
  'buy': 'Buy',
  'book': 'Book',
  'order': 'Order',
  'apply': 'Apply',
  'visit': 'Visit',
  'chat': 'Chat',
};

const creatorPlacementDays = <int>[1, 2, 3, 4, 5, 6, 7];
