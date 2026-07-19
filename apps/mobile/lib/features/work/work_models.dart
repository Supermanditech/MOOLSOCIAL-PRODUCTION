import 'package:flutter/material.dart';

enum WorkFeedFilter { forYou, jobs, freelance, campaigns, nearby }

extension WorkFeedFilterLabel on WorkFeedFilter {
  String get label => switch (this) {
    WorkFeedFilter.forYou => 'For You',
    WorkFeedFilter.jobs => 'Jobs',
    WorkFeedFilter.freelance => 'Freelance',
    WorkFeedFilter.campaigns => 'Campaigns',
    WorkFeedFilter.nearby => 'Nearby',
  };
}

enum WorkReviewStage { none, drafting, gstPending, approved, setup, live }

class WorkOpportunity {
  const WorkOpportunity({
    required this.id,
    required this.publisher,
    required this.publisherType,
    required this.title,
    required this.summary,
    required this.kind,
    required this.location,
    required this.capacity,
    required this.payment,
    required this.payout,
    required this.requiredWork,
    required this.deadline,
    required this.fundingNote,
    required this.icon,
    required this.filters,
    this.available = true,
  });

  final String id;
  final String publisher;
  final String publisherType;
  final String title;
  final String summary;
  final String kind;
  final String location;
  final String capacity;
  final String payment;
  final String payout;
  final String requiredWork;
  final String deadline;
  final String fundingNote;
  final IconData icon;
  final Set<WorkFeedFilter> filters;
  final bool available;
}

class WorkTerm {
  const WorkTerm({required this.id, required this.title, required this.detail});

  final String id;
  final String title;
  final String detail;
}

class WorkProfileOption {
  const WorkProfileOption({
    required this.id,
    required this.familyId,
    required this.familyLabel,
    required this.label,
    required this.sellSide,
    required this.buySide,
    required this.tools,
    required this.icon,
  });

  final String id;
  final String familyId;
  final String familyLabel;
  final String label;
  final String sellSide;
  final String buySide;
  final String tools;
  final IconData icon;
}

class WorkProofRequirement {
  const WorkProofRequirement({
    required this.id,
    required this.label,
    required this.detail,
    required this.required,
  });

  final String id;
  final String label;
  final String detail;
  final bool required;
}

class WorkWorkspace {
  const WorkWorkspace({
    required this.id,
    required this.name,
    required this.profileLabel,
    required this.area,
    required this.verified,
    this.gstReminder = false,
  });

  final String id;
  final String name;
  final String profileLabel;
  final String area;
  final bool verified;
  final bool gstReminder;
}

const workOpportunities = <WorkOpportunity>[
  WorkOpportunity(
    id: 'mool-explainer',
    publisher: 'MoolSocial',
    publisherType: 'Official sponsored campaign',
    title: 'Make one MoolSocial explainer video',
    summary:
        'Create one original 45–60 second Hindi or regional-language vertical video.',
    kind: 'Create',
    location: 'Remote India',
    capacity: '12 slots',
    payment: '₹1,500 per approved video',
    payout: 'Within 3 days',
    requiredWork: 'Creator Work',
    deadline: 'Closes 22 Jul · 8:00 PM',
    fundingNote: 'Funded · disclosure required',
    icon: Icons.movie_creation_outlined,
    filters: {WorkFeedFilter.forYou, WorkFeedFilter.campaigns},
  ),
  WorkOpportunity(
    id: 'shakti-shorts',
    publisher: 'Shakti Foods',
    publisherType: 'Verified manufacturer',
    title: 'Create two product showcase Shorts',
    summary:
        'Show the supplied product pack, preparation and final serving in two original shorts.',
    kind: 'Create',
    location: 'Remote India',
    capacity: '18 slots',
    payment: '₹1,200 per approved pair',
    payout: 'Within 5 days',
    requiredWork: 'Creator Work',
    deadline: 'Closes 23 Jul · 6:00 PM',
    fundingNote: 'Funded · product supplied',
    icon: Icons.play_circle_outline_rounded,
    filters: {WorkFeedFilter.forYou, WorkFeedFilter.campaigns},
  ),
  WorkOpportunity(
    id: 'mahadev-orders',
    publisher: 'Mahadev Fresh Mart',
    publisherType: 'Verified retailer',
    title: 'Bring completed grocery orders',
    summary:
        'Earn only for trackable paid orders that are delivered and remain outside the refund window.',
    kind: 'Promote',
    location: 'Jodhpur · 4 km',
    capacity: '20 orders',
    payment: '₹20 per delivered order',
    payout: 'T+2 days',
    requiredWork: 'Freelancer Work',
    deadline: 'Ends 21 Jul · 9:00 PM',
    fundingNote: 'Funded · maximum payout ₹400',
    icon: Icons.storefront_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'riya-edit',
    publisher: 'Riya Sharma',
    publisherType: 'Verified creator',
    title: 'Edit three vertical short videos',
    summary:
        'Edit supplied clips with approved captions, pacing and brand styling.',
    kind: 'Edit',
    location: 'Remote India',
    capacity: '6 packs',
    payment: '₹900 per approved pack',
    payout: 'Within 3 days',
    requiredWork: 'Creator Work',
    deadline: 'Deliver by 24 Jul',
    fundingNote: 'Funded · files supplied',
    icon: Icons.video_file_outlined,
    filters: {WorkFeedFilter.forYou, WorkFeedFilter.freelance},
  ),
  WorkOpportunity(
    id: 'evening-delivery',
    publisher: 'MoolSocial Delivery',
    publisherType: 'Verified prepaid route',
    title: 'Complete an evening grocery route',
    summary:
        'Collect prepaid orders and complete eight OTP-verified drops from 6–9 PM.',
    kind: 'Deliver',
    location: 'Jodhpur central',
    capacity: '10 routes',
    payment: '₹520 for 8 drops',
    payout: 'Next payout',
    requiredWork: 'Delivery Work',
    deadline: 'Today · 5:30 PM',
    fundingNote: 'Funded · route support included',
    icon: Icons.delivery_dining_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'business-activation',
    publisher: 'MoolSocial',
    publisherType: 'Verified activation work',
    title: 'Activate local businesses',
    summary:
        'Complete owner-approved setup and the first verified business activation action.',
    kind: 'Onboard',
    location: 'Jodhpur district',
    capacity: '40 nearby',
    payment: '₹350 per activation',
    payout: 'T+1 review',
    requiredWork: 'Freelancer Work',
    deadline: 'Apply by 25 Jul',
    fundingNote: 'Funded · verified activation',
    icon: Icons.add_business_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'city-coordinator',
    publisher: 'MoolSocial',
    publisherType: 'Verified permanent role',
    title: 'City operations coordinator',
    summary:
        'Own city partner quality, support resolution and revenue execution.',
    kind: 'Job',
    location: 'Jodhpur · on-site',
    capacity: '2 roles',
    payment: '₹25k–35k monthly',
    payout: 'Monthly salary',
    requiredWork: 'Job Seeker Work',
    deadline: 'Apply by 27 Jul',
    fundingNote: 'No application fee',
    icon: Icons.badge_outlined,
    filters: {WorkFeedFilter.forYou, WorkFeedFilter.jobs},
  ),
];

const workTerms = <WorkTerm>[
  WorkTerm(
    id: 'payment',
    title: 'Payment and payout',
    detail:
        '₹1,500 is reserved for one approved video. Payout releases within three working days after final approval.',
  ),
  WorkTerm(
    id: 'publisher',
    title: 'What the publisher provides',
    detail:
        'Campaign brief, approved facts, brand assets and submission instructions are provided after selection.',
  ),
  WorkTerm(
    id: 'review',
    title: 'Review, correction and rejection',
    detail:
        'One correction is allowed. Copied media, hidden sponsorship, false claims or off-brief output may be rejected with a stated reason.',
  ),
  WorkTerm(
    id: 'rights',
    title: 'Content use and rights',
    detail:
        'The approved campaign licence and usage period are stated before final acceptance. Ownership is not transferred beyond those terms.',
  ),
];

const workProfiles = <WorkProfileOption>[
  WorkProfileOption(
    id: 'retailer-grocery',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Grocery / Kirana Shop',
    sellSide: 'Sell products to local customers',
    buySide: 'Buy verified wholesale packs',
    tools: 'Orders, stock, delivery and business book',
    icon: Icons.storefront_rounded,
  ),
  WorkProfileOption(
    id: 'retailer-speciality',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Speciality Retail Shop',
    sellSide: 'Sell category products',
    buySide: 'Procure from eligible suppliers',
    tools: 'Catalogue, stock, orders and invoices',
    icon: Icons.shopping_bag_outlined,
  ),
  WorkProfileOption(
    id: 'wholesaler',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Wholesaler / Distributor',
    sellSide: 'List case packs and trade terms',
    buySide: 'Source from manufacturers',
    tools: 'Business orders, credit and dispatch',
    icon: Icons.warehouse_outlined,
  ),
  WorkProfileOption(
    id: 'manufacturer',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Manufacturer / Supplier',
    sellSide: 'Reach eligible trade buyers',
    buySide: 'Source materials and services',
    tools: 'Sales targets, distribution and fulfilment',
    icon: Icons.factory_outlined,
  ),
  WorkProfileOption(
    id: 'restaurant',
    familyId: 'food-business',
    familyLabel: 'Food Business',
    label: 'Restaurant / Café',
    sellSide: 'Serve delivery, pickup and tables',
    buySide: 'Procure food and supplies',
    tools: 'Menu, kitchen, orders and tables',
    icon: Icons.restaurant_rounded,
  ),
  WorkProfileOption(
    id: 'cloud-kitchen',
    familyId: 'food-business',
    familyLabel: 'Food Business',
    label: 'Cloud Kitchen / Tiffin',
    sellSide: 'Sell meals and subscriptions',
    buySide: 'Procure ingredients and packaging',
    tools: 'Menu, plans, delivery and kitchen',
    icon: Icons.soup_kitchen_outlined,
  ),
  WorkProfileOption(
    id: 'clinic',
    familyId: 'health',
    familyLabel: 'Health & Medicine',
    label: 'Clinic / Doctor',
    sellSide: 'Offer verified appointments',
    buySide: 'Manage approved supplies',
    tools: 'Appointments, consent and follow-up',
    icon: Icons.medical_services_outlined,
  ),
  WorkProfileOption(
    id: 'pharmacy',
    familyId: 'health',
    familyLabel: 'Health & Medicine',
    label: 'Pharmacy',
    sellSide: 'Fulfil eligible medicine orders',
    buySide: 'Procure from licensed suppliers',
    tools: 'Prescription checks, stock and orders',
    icon: Icons.local_pharmacy_outlined,
  ),
  WorkProfileOption(
    id: 'salon',
    familyId: 'services',
    familyLabel: 'Services & Salon',
    label: 'Salon / Wellness',
    sellSide: 'Offer appointments and packages',
    buySide: 'Procure professional products',
    tools: 'Slots, staff, bills and repeat visits',
    icon: Icons.content_cut_rounded,
  ),
  WorkProfileOption(
    id: 'service-provider',
    familyId: 'services',
    familyLabel: 'Services & Salon',
    label: 'Local Service Provider',
    sellSide: 'Accept defined service tasks',
    buySide: 'Source tools and supplies',
    tools: 'Availability, proof, payout and support',
    icon: Icons.handyman_outlined,
  ),
  WorkProfileOption(
    id: 'captain',
    familyId: 'ride',
    familyLabel: 'Ride & Transport',
    label: 'Ride / Delivery Captain',
    sellSide: 'Accept eligible trips and routes',
    buySide: 'Access vehicle services',
    tools: 'Trips, safety, earnings and documents',
    icon: Icons.two_wheeler_rounded,
  ),
  WorkProfileOption(
    id: 'fleet',
    familyId: 'ride',
    familyLabel: 'Ride & Transport',
    label: 'Fleet / Transport Business',
    sellSide: 'Offer verified capacity',
    buySide: 'Source routes and services',
    tools: 'Vehicles, drivers, routes and settlement',
    icon: Icons.local_shipping_outlined,
  ),
  WorkProfileOption(
    id: 'creator',
    familyId: 'create-work',
    familyLabel: 'Create & Work',
    label: 'Creator',
    sellSide: 'Complete funded creator campaigns',
    buySide: 'Hire creator support services',
    tools: 'YouTube Connect, campaigns and earnings',
    icon: Icons.video_camera_front_outlined,
  ),
  WorkProfileOption(
    id: 'freelancer',
    familyId: 'create-work',
    familyLabel: 'Create & Work',
    label: 'Freelancer / Job Seeker',
    sellSide: 'Apply for funded work and roles',
    buySide: 'Access professional services',
    tools: 'Applications, proof, payout and profile',
    icon: Icons.work_outline_rounded,
  ),
];

const workProofs = <WorkProofRequirement>[
  WorkProofRequirement(
    id: 'personal-kyc',
    label: 'Personal identity',
    detail: 'Verified account owner · already received',
    required: true,
  ),
  WorkProofRequirement(
    id: 'shop-front',
    label: 'Shop or work-place proof',
    detail: 'Clear current photo with the work name or operating location',
    required: true,
  ),
  WorkProofRequirement(
    id: 'owner-authority',
    label: 'Owner or operator authority',
    detail: 'Registration, licence, bill or authorization showing your link',
    required: true,
  ),
  WorkProofRequirement(
    id: 'gst',
    label: 'GST certificate',
    detail: 'Add now when applicable, or continue with a visible reminder',
    required: false,
  ),
];
