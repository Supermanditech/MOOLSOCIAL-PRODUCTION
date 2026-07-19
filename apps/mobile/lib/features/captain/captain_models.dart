enum CaptainTripState {
  available,
  assigned,
  pickup,
  live,
  arrived,
  paymentPending,
  completed,
}

enum CaptainEarningsTab { today, week, payouts }

enum CaptainSupportTab { support, paidWork, vehicle }

enum CaptainRequestDecision { none, accepted, declined }

class CaptainRideRequest {
  const CaptainRideRequest({
    required this.id,
    required this.service,
    required this.pickup,
    required this.pickupDetail,
    required this.drop,
    required this.dropDetail,
    required this.pickupDistance,
    required this.tripDistance,
    required this.duration,
    required this.riderFare,
    required this.platformCharge,
    required this.estimatedFuel,
    required this.netEarning,
    required this.paymentMethod,
    required this.rider,
    required this.rating,
  });

  final String id;
  final String service;
  final String pickup;
  final String pickupDetail;
  final String drop;
  final String dropDetail;
  final String pickupDistance;
  final String tripDistance;
  final String duration;
  final int riderFare;
  final int platformCharge;
  final int estimatedFuel;
  final int netEarning;
  final String paymentMethod;
  final String rider;
  final double rating;
}

class CaptainEarning {
  const CaptainEarning({
    required this.id,
    required this.destination,
    required this.gross,
    required this.platformCharge,
    required this.net,
    required this.status,
  });

  final String id;
  final String destination;
  final int gross;
  final int platformCharge;
  final int net;
  final String status;
}

class CaptainDocument {
  const CaptainDocument({
    required this.id,
    required this.shortLabel,
    required this.name,
    required this.detail,
    required this.status,
    required this.expiry,
    this.needsAction = false,
  });

  final String id;
  final String shortLabel;
  final String name;
  final String detail;
  final String status;
  final String expiry;
  final bool needsAction;
}

class CaptainSupportOption {
  const CaptainSupportOption({
    required this.id,
    required this.title,
    required this.detail,
    required this.outcome,
    required this.iconLabel,
    this.urgent = false,
  });

  final String id;
  final String title;
  final String detail;
  final String outcome;
  final String iconLabel;
  final bool urgent;
}

class CaptainPaidWork {
  const CaptainPaidWork({
    required this.id,
    required this.title,
    required this.sponsor,
    required this.geography,
    required this.payment,
    required this.paymentRule,
    required this.proof,
    required this.capacity,
  });

  final String id;
  final String title;
  final String sponsor;
  final String geography;
  final int payment;
  final String paymentRule;
  final String proof;
  final String capacity;
}

const reviewCaptainRide = CaptainRideRequest(
  id: 'MS-R4821',
  service: 'Bike ride',
  pickup: 'Sardarpura C Road',
  pickupDetail: 'Opposite Central Bank · blue gate',
  drop: 'Jodhpur Airport, Terminal Gate',
  dropDetail: '11.8 km · about 28 min',
  pickupDistance: '2.1 km · about 5 min',
  tripDistance: '11.8 km',
  duration: '28 min',
  riderFare: 278,
  platformCharge: 28,
  estimatedFuel: 12,
  netEarning: 238,
  paymentMethod: 'UPI',
  rider: 'Asha K.',
  rating: 4.8,
);

const reviewCaptainEarnings = <CaptainEarning>[
  CaptainEarning(
    id: 'MS-R4821',
    destination: 'Airport',
    gross: 278,
    platformCharge: 28,
    net: 250,
    status: 'Paid',
  ),
  CaptainEarning(
    id: 'MS-R4817',
    destination: 'Railway Station',
    gross: 196,
    platformCharge: 20,
    net: 176,
    status: 'Paid',
  ),
];

const reviewCaptainDocuments = <CaptainDocument>[
  CaptainDocument(
    id: 'dl',
    shortLabel: 'DL',
    name: 'Driving Licence',
    detail: 'Face and identity matched',
    status: 'Valid',
    expiry: '12 Mar 2029',
  ),
  CaptainDocument(
    id: 'rc',
    shortLabel: 'RC',
    name: 'Vehicle Registration',
    detail: 'RJ19 GB 4421 · owner authorization matched',
    status: 'Valid',
    expiry: 'Verified',
  ),
  CaptainDocument(
    id: 'insurance',
    shortLabel: 'INS',
    name: 'Vehicle Insurance',
    detail: 'Comprehensive policy · renewal needed',
    status: '18 days',
    expiry: '30 Jul 2026',
    needsAction: true,
  ),
  CaptainDocument(
    id: 'puc',
    shortLabel: 'PUC',
    name: 'PUC Certificate',
    detail: 'Document and vehicle number matched',
    status: 'Valid',
    expiry: '18 Dec 2026',
  ),
  CaptainDocument(
    id: 'permit',
    shortLabel: 'PER',
    name: 'Permit / Service Authorization',
    detail: 'Approved for this vehicle and ride service',
    status: 'Ready',
    expiry: 'Review complete',
  ),
];

const reviewCaptainSupport = <CaptainSupportOption>[
  CaptainSupportOption(
    id: 'emergency',
    title: 'Emergency & Safety',
    detail: 'Active or recent trip incident',
    outcome: 'Immediate support',
    iconLabel: 'SOS',
    urgent: true,
  ),
  CaptainSupportOption(
    id: 'trip',
    title: 'Trip or Rider Issue',
    detail: 'Pickup, route, cancellation or conduct',
    outcome: 'Trip attached automatically',
    iconLabel: 'TRIP',
  ),
  CaptainSupportOption(
    id: 'fare',
    title: 'Fare & Payout',
    detail: 'Payment, cash adjustment or payout',
    outcome: 'Trip earnings included',
    iconLabel: '₹',
  ),
  CaptainSupportOption(
    id: 'lost-item',
    title: 'Report an Item Found',
    detail: 'Keep it safe and start a traceable return',
    outcome: 'Return stays inside the app',
    iconLabel: 'ITEM',
  ),
];

const reviewCaptainPaidWork = <CaptainPaidWork>[
  CaptainPaidWork(
    id: 'captain-onboarding',
    title: 'Onboard verified autos in Jodhpur',
    sponsor: 'MoolSocial funded campaign',
    geography: 'Jodhpur citywide',
    payment: 300,
    paymentRule: 'Per approved captain',
    proof: 'Verified activation',
    capacity: '120 open',
  ),
  CaptainPaidWork(
    id: 'pickup-map',
    title: 'Map pickup points near railway station',
    sponsor: 'Mobility operations',
    geography: '2 km station zone',
    payment: 450,
    paymentRule: 'Per approved map',
    proof: 'Photos + GPS',
    capacity: 'Ends 24 Jul',
  ),
];

const reviewCaptainVehicleHelp = <CaptainSupportOption>[
  CaptainSupportOption(
    id: 'insurance-renewal',
    title: 'Insurance renewal support',
    detail: 'Compare eligible policies before expiry',
    outcome: '18 days remaining',
    iconLabel: 'INS',
  ),
  CaptainSupportOption(
    id: 'vehicle-service',
    title: 'Verified service nearby',
    detail: 'Maintenance slot with a clear estimate',
    outcome: 'Compare before booking',
    iconLabel: 'SRV',
  ),
  CaptainSupportOption(
    id: 'vehicle-bills',
    title: 'FASTag, insurance and vehicle bills',
    detail: 'Open the matching Pay action',
    outcome: 'One-tap payment routes',
    iconLabel: 'BILL',
  ),
];
