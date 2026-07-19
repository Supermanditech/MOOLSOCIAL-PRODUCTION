enum RetailerBusinessServiceType { delivery, growth, books, ads }

enum RetailerBusinessPayment { upi, card, manual }

extension RetailerBusinessPaymentLabel on RetailerBusinessPayment {
  String get label => switch (this) {
    RetailerBusinessPayment.upi => 'UPI AutoPay',
    RetailerBusinessPayment.card => 'Card mandate',
    RetailerBusinessPayment.manual => 'Manual renewal',
  };
}

class RetailerServiceFact {
  const RetailerServiceFact(this.label, this.value);

  final String label;
  final String value;
}

class RetailerServiceTerm {
  const RetailerServiceTerm(this.label, this.value);

  final String label;
  final String value;
}

class RetailerBusinessPlan {
  const RetailerBusinessPlan({
    required this.id,
    required this.name,
    required this.badge,
    required this.monthly,
    required this.included,
    required this.additional,
    required this.terms,
    required this.includedUnits,
  });

  final String id;
  final String name;
  final String badge;
  final int monthly;
  final String included;
  final String additional;
  final List<RetailerServiceTerm> terms;
  final int includedUnits;
}

class RetailerBusinessServiceOffering {
  const RetailerBusinessServiceOffering({
    required this.type,
    required this.title,
    required this.badge,
    required this.outcome,
    required this.includes,
    required this.variableCharge,
    required this.intro,
    required this.facts,
    required this.protection,
    required this.plans,
    required this.state,
    required this.detail,
    required this.workTitle,
    required this.workDetail,
    required this.workAction,
    required this.setupTitle,
    required this.quickSetup,
    required this.emptyActivity,
    required this.usageLabel,
    this.requiresDataConsent = false,
  });

  final RetailerBusinessServiceType type;
  final String title;
  final String badge;
  final String outcome;
  final String includes;
  final String variableCharge;
  final String intro;
  final List<RetailerServiceFact> facts;
  final String protection;
  final List<RetailerBusinessPlan> plans;
  final String state;
  final String detail;
  final String workTitle;
  final String workDetail;
  final String workAction;
  final String setupTitle;
  final List<(String, String, bool)> quickSetup;
  final String emptyActivity;
  final String usageLabel;
  final bool requiresDataConsent;

  RetailerBusinessPlan plan(String id) =>
      plans.firstWhere((plan) => plan.id == id, orElse: () => plans.first);
}

class RetailerActiveBusinessService {
  RetailerActiveBusinessService({
    required this.id,
    required this.offering,
    required this.plan,
    required this.monthlyLimit,
    required this.payment,
    Set<String>? readySetup,
  }) : readySetup = readySetup ?? <String>{};

  final String id;
  final RetailerBusinessServiceOffering offering;
  final RetailerBusinessPlan plan;
  final int monthlyLimit;
  final RetailerBusinessPayment payment;
  final Set<String> readySetup;
}

const retailerBusinessServiceOfferings = <RetailerBusinessServiceOffering>[
  RetailerBusinessServiceOffering(
    type: RetailerBusinessServiceType.delivery,
    title: 'Delivery Support',
    badge: 'Nearby',
    outcome: 'Customer orders delivered from your shop',
    includes: 'Partner assignment · live tracking · proof',
    variableCharge: 'Charge only for completed delivery',
    intro: 'Reliable fulfilment support for customer orders from your shop.',
    facts: [
      RetailerServiceFact(
        'You receive',
        'Delivery capacity, live status, proof and support',
      ),
      RetailerServiceFact('Extra charge', 'Only for a completed delivery'),
      RetailerServiceFact('Proof', 'Pickup and accepted delivery record'),
      RetailerServiceFact(
        'Not charged',
        'Unassigned or failed delivery under plan rules',
      ),
    ],
    protection:
        'Unassigned, failed or cancelled delivery is not charged under the displayed plan rules.',
    plans: [
      RetailerBusinessPlan(
        id: 'starter',
        name: 'Starter',
        badge: 'Start',
        monthly: 299,
        included: '10 deliveries included',
        additional: '₹35 per completed delivery after 10',
        includedUnits: 10,
        terms: [
          RetailerServiceTerm('Monthly plan', '₹299 + GST'),
          RetailerServiceTerm('Included', '10 completed deliveries'),
          RetailerServiceTerm(
            'Additional',
            '₹35 per completed delivery after 10',
          ),
          RetailerServiceTerm(
            'Charged when',
            'Accepted delivery proof is recorded',
          ),
          RetailerServiceTerm(
            'Not charged',
            'Unassigned, failed or cancelled delivery',
          ),
          RetailerServiceTerm(
            'Service area',
            'Eligible Jodhpur zones shown before activation',
          ),
        ],
      ),
      RetailerBusinessPlan(
        id: 'growth',
        name: 'Growth',
        badge: 'Popular',
        monthly: 699,
        included: '30 deliveries included',
        additional: '₹29 per completed delivery after 30',
        includedUnits: 30,
        terms: [
          RetailerServiceTerm('Monthly plan', '₹699 + GST'),
          RetailerServiceTerm('Included', '30 completed deliveries'),
          RetailerServiceTerm(
            'Additional',
            '₹29 per completed delivery after 30',
          ),
          RetailerServiceTerm(
            'Charged when',
            'Accepted delivery proof is recorded',
          ),
          RetailerServiceTerm(
            'Not charged',
            'Unassigned, failed or cancelled delivery',
          ),
          RetailerServiceTerm(
            'Service area',
            'Eligible Jodhpur zones shown before activation',
          ),
        ],
      ),
    ],
    state: 'Ready for customer deliveries',
    detail: 'Use MoolSocial delivery from any packed order',
    workTitle: 'Deliver a customer order',
    workDetail: 'Open a packed order and request a delivery partner',
    workAction: 'Open Orders',
    setupTitle: 'Delivery setup',
    quickSetup: [
      ('Hours', 'Pickup hours', true),
      ('Zones', 'Delivery zones', true),
      ('Rules', 'Delivery rules', false),
    ],
    emptyActivity: 'No delivery requested yet',
    usageLabel: 'DELIVERIES USED',
  ),
  RetailerBusinessServiceOffering(
    type: RetailerBusinessServiceType.growth,
    title: 'Grow Sales',
    badge: 'Verified',
    outcome: 'Expand sales beyond your immediate area',
    includes: 'Sales team · field partners · creator campaigns',
    variableCharge: 'Fee only on verified attributed sales',
    intro:
        'Verified field teams, freelancers or creators help expand your shop customer reach.',
    facts: [
      RetailerServiceFact(
        'You receive',
        'Planned customer acquisition in an agreed area',
      ),
      RetailerServiceFact(
        'Extra charge',
        'Only on paid, non-refunded attributed sales',
      ),
      RetailerServiceFact('Proof', 'Order and attribution record'),
      RetailerServiceFact('Not charged', 'Views, visits or unverified leads'),
    ],
    protection:
        'Views, visits, unverified leads, cancelled orders and refunded orders are not attributed sales.',
    plans: [
      RetailerBusinessPlan(
        id: 'starter',
        name: 'Starter',
        badge: 'Start',
        monthly: 499,
        included: 'One local sales campaign',
        additional: '3% of verified attributed sales',
        includedUnits: 1,
        terms: [
          RetailerServiceTerm('Monthly plan', '₹499 + GST'),
          RetailerServiceTerm(
            'Included',
            'One local campaign and weekly report',
          ),
          RetailerServiceTerm(
            'Additional',
            '3% of paid, non-refunded attributed sales',
          ),
          RetailerServiceTerm(
            'Attribution',
            'Campaign link or verified assisted order',
          ),
          RetailerServiceTerm(
            'Not charged',
            'Views, leads, cancellations or refunds',
          ),
          RetailerServiceTerm('Service area', 'Selected Jodhpur radius'),
        ],
      ),
      RetailerBusinessPlan(
        id: 'growth',
        name: 'Growth',
        badge: 'Popular',
        monthly: 999,
        included: 'Three active campaigns',
        additional: '2% of verified attributed sales',
        includedUnits: 3,
        terms: [
          RetailerServiceTerm('Monthly plan', '₹999 + GST'),
          RetailerServiceTerm(
            'Included',
            'Three campaigns and weekly optimization',
          ),
          RetailerServiceTerm(
            'Additional',
            '2% of paid, non-refunded attributed sales',
          ),
          RetailerServiceTerm(
            'Attribution',
            'Campaign link or verified assisted order',
          ),
          RetailerServiceTerm(
            'Not charged',
            'Views, leads, cancellations or refunds',
          ),
          RetailerServiceTerm('Service area', 'Selected city zones'),
        ],
      ),
    ],
    state: 'Ready to create your first campaign',
    detail: 'Expand verified sales beyond your immediate area',
    workTitle: 'Start a sales campaign',
    workDetail: 'Choose area, outcome, budget and attribution rule',
    workAction: 'Create campaign',
    setupTitle: 'Growth setup',
    quickSetup: [
      ('Area', 'Sales radius', true),
      ('Offer', 'Shop offer', false),
      ('Team', 'Field team', false),
    ],
    emptyActivity: 'No sales campaign started yet',
    usageLabel: 'CAMPAIGNS USED',
  ),
  RetailerBusinessServiceOffering(
    type: RetailerBusinessServiceType.books,
    title: 'Tax & Books',
    badge: 'Professional',
    outcome: 'GST, ITR, accounts and bookkeeping',
    includes: 'Qualified professionals · records · reminders',
    variableCharge: 'Agreed filing or completion fee',
    intro:
        'Structured GST, ITR, accounts and bookkeeping support for your shop.',
    facts: [
      RetailerServiceFact(
        'You receive',
        'Selected bookkeeping or filing support',
      ),
      RetailerServiceFact(
        'Extra charge',
        'Per accepted filing or agreed completed milestone',
      ),
      RetailerServiceFact('Proof', 'Acknowledgement or accepted work record'),
      RetailerServiceFact(
        'Protection',
        'Verified professional, consent and access log',
      ),
    ],
    protection:
        'No filing or statutory submission occurs without the retailer explicit final approval.',
    plans: [
      RetailerBusinessPlan(
        id: 'starter',
        name: 'Records',
        badge: 'Start',
        monthly: 499,
        included: 'Monthly books review',
        additional: 'Filing fee shown before each filing',
        includedUnits: 1,
        terms: [
          RetailerServiceTerm('Monthly plan', '₹499 + GST'),
          RetailerServiceTerm(
            'Included',
            'Monthly records review and reconciliation',
          ),
          RetailerServiceTerm(
            'Additional',
            'Exact filing fee approved before submission',
          ),
          RetailerServiceTerm(
            'Completed when',
            'Acknowledgement or accepted work record',
          ),
          RetailerServiceTerm(
            'Not included',
            'Government fee, audit or legal representation',
          ),
          RetailerServiceTerm(
            'Access',
            'Purpose consent and access log required',
          ),
        ],
      ),
      RetailerBusinessPlan(
        id: 'growth',
        name: 'Compliance',
        badge: 'Popular',
        monthly: 999,
        included: 'Books plus GST readiness',
        additional: 'Agreed ITR or special filing fee',
        includedUnits: 1,
        terms: [
          RetailerServiceTerm('Monthly plan', '₹999 + GST'),
          RetailerServiceTerm(
            'Included',
            'Books review, GST readiness and reminders',
          ),
          RetailerServiceTerm('Additional', 'Exact ITR or special filing fee'),
          RetailerServiceTerm(
            'Completed when',
            'Acknowledgement or accepted work record',
          ),
          RetailerServiceTerm(
            'Not included',
            'Government fee, audit or legal representation',
          ),
          RetailerServiceTerm(
            'Access',
            'Purpose consent and access log required',
          ),
        ],
      ),
    ],
    state: 'Ready to connect your business records',
    detail: 'Purpose-limited access remains logged and controlled',
    workTitle: 'Start monthly books review',
    workDetail: 'Connect Sales Book, Purchase Book and required documents',
    workAction: 'Connect records',
    setupTitle: 'Records setup',
    quickSetup: [
      ('Books', 'Connect books', true),
      ('Docs', 'Add documents', false),
      ('Access', 'Permissions', true),
    ],
    emptyActivity: 'No review or filing started yet',
    usageLabel: 'REVIEWS USED',
    requiresDataConsent: true,
  ),
  RetailerBusinessServiceOffering(
    type: RetailerBusinessServiceType.ads,
    title: 'Offers & Ads',
    badge: 'Campaigns',
    outcome: 'Create promotions and run campaigns',
    includes: 'Offers · creatives · advertising · reports',
    variableCharge: 'Approved ad spend and agreed result fee',
    intro:
        'Create and operate shop promotions, creator campaigns and advertising.',
    facts: [
      RetailerServiceFact(
        'You receive',
        'Offer setup, campaign operation and reporting',
      ),
      RetailerServiceFact(
        'Extra charge',
        'Ad spend plus agreed attributed-sales fee',
      ),
      RetailerServiceFact('Proof', 'Spend report and attributed order record'),
      RetailerServiceFact(
        'Control',
        'Budget cap and approval before campaign starts',
      ),
    ],
    protection:
        'No campaign spend starts or exceeds the approved budget without the retailer approval.',
    plans: [
      RetailerBusinessPlan(
        id: 'starter',
        name: 'Offers',
        badge: 'Start',
        monthly: 299,
        included: 'Two shop offers monthly',
        additional: 'Approved ad spend is separate',
        includedUnits: 2,
        terms: [
          RetailerServiceTerm('Monthly plan', '₹299 + GST'),
          RetailerServiceTerm(
            'Included',
            'Two offers and basic creative support',
          ),
          RetailerServiceTerm(
            'Additional',
            'Only retailer-approved advertising spend',
          ),
          RetailerServiceTerm('Result fee', 'None unless separately agreed'),
          RetailerServiceTerm(
            'Control',
            'Campaign and budget approval required',
          ),
          RetailerServiceTerm('Report', 'Spend and attributed orders shown'),
        ],
      ),
      RetailerBusinessPlan(
        id: 'growth',
        name: 'Campaigns',
        badge: 'Popular',
        monthly: 799,
        included: 'Four managed campaigns',
        additional: 'Ad spend + 2% attributed sales',
        includedUnits: 4,
        terms: [
          RetailerServiceTerm('Monthly plan', '₹799 + GST'),
          RetailerServiceTerm(
            'Included',
            'Four campaigns, creatives and reports',
          ),
          RetailerServiceTerm(
            'Additional',
            'Approved ad spend plus 2% attributed sales',
          ),
          RetailerServiceTerm(
            'Attribution',
            'Paid, non-refunded campaign order',
          ),
          RetailerServiceTerm(
            'Control',
            'Campaign and budget approval required',
          ),
          RetailerServiceTerm('Report', 'Spend and attributed orders shown'),
        ],
      ),
    ],
    state: 'Ready to create your first promotion',
    detail: 'No advertising spend begins without your approval',
    workTitle: 'Create a shop offer',
    workDetail: 'Choose products, customers, dates and approved budget',
    workAction: 'Create offer',
    setupTitle: 'Campaign setup',
    quickSetup: [
      ('Offer', 'Offer rules', false),
      ('Budget', 'Spend limit', true),
      ('Report', 'Attribution', true),
    ],
    emptyActivity: 'No offer or campaign started yet',
    usageLabel: 'CAMPAIGNS USED',
  ),
];

RetailerBusinessServiceOffering retailerBusinessServiceByName(String value) {
  return retailerBusinessServiceOfferings.firstWhere(
    (service) => service.type.name == value,
    orElse: () => retailerBusinessServiceOfferings.first,
  );
}
