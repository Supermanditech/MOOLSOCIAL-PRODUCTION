class SharedStat {
  const SharedStat(this.label, this.value);

  final String label;
  final String value;
}

class SharedFact {
  const SharedFact(this.label, this.value);

  final String label;
  final String value;
}

class SharedStep {
  const SharedStep(this.label, this.outcome);

  final String label;
  final String outcome;
}

class SharedControl {
  const SharedControl({
    required this.id,
    required this.label,
    required this.note,
    required this.initialValue,
    this.locked = false,
    this.lockedMessage,
    this.subscriptionRequired = false,
  });

  final String id;
  final String label;
  final String note;
  final bool initialValue;
  final bool locked;
  final String? lockedMessage;
  final bool subscriptionRequired;
}

class SharedSchedule {
  const SharedSchedule(this.label, this.value);

  final String label;
  final String value;
}

class SharedItem {
  const SharedItem({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.meta,
    required this.why,
    required this.facts,
    required this.steps,
    required this.currentStep,
    required this.primary,
    required this.primaryOutcome,
    this.secondary,
    this.secondaryOutcome,
    this.primaryRoute,
    this.secondaryRoute,
    this.confirmation,
    this.secondaryConfirmation,
    this.controls = const <SharedControl>[],
    this.schedule = const <SharedSchedule>[],
    this.scheduleTitle,
    this.preview = const <String>[],
    this.tone = 'standard',
    this.unread = false,
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final String meta;
  final String why;
  final List<SharedFact> facts;
  final List<SharedStep> steps;
  final int currentStep;
  final String primary;
  final String primaryOutcome;
  final String? secondary;
  final String? secondaryOutcome;
  final String? primaryRoute;
  final String? secondaryRoute;
  final String? confirmation;
  final String? secondaryConfirmation;
  final List<SharedControl> controls;
  final List<SharedSchedule> schedule;
  final String? scheduleTitle;
  final List<String> preview;
  final String tone;
  final bool unread;
}

class SharedScreenSpec {
  const SharedScreenSpec({
    required this.screen,
    required this.title,
    required this.subtitle,
    required this.kicker,
    required this.heroTitle,
    required this.heroText,
    required this.stats,
    required this.filters,
    required this.listTitle,
    required this.items,
    this.listNote = 'tap to review',
    this.topAction,
  });

  final int screen;
  final String title;
  final String subtitle;
  final String kicker;
  final String heroTitle;
  final String heroText;
  final List<SharedStat> stats;
  final List<String> filters;
  final String listTitle;
  final String listNote;
  final String? topAction;
  final List<SharedItem> items;
}

const _identity = SharedItem(
  id: 'personal-identity',
  category: 'Identity',
  tone: 'good',
  title: 'Personal identity',
  summary: 'Mobile, face match and DigiLocker identity are verified.',
  meta: 'Last checked 03 Jul 2026',
  why:
      'Personal verification protects payments, work and regulated workspace actions.',
  facts: [
    SharedFact('MOBILE', '+91 ••••• 3210'),
    SharedFact('METHOD', 'DigiLocker'),
    SharedFact('FACE MATCH', 'Verified'),
    SharedFact('SHARED WITH', 'No provider'),
  ],
  steps: [
    SharedStep('Identity', 'Verified source'),
    SharedStep('Consent', 'Permission recorded'),
    SharedStep('Access', 'Capability level only'),
  ],
  currentStep: 3,
  primary: 'View verification',
  primaryOutcome: 'Verification source, date and permitted capability opened.',
  secondary: 'Manage consent',
  secondaryOutcome:
      'Consent history opened with purpose, recipient and expiry.',
);

const sharedScreenSpecs = <int, SharedScreenSpec>{
  157: SharedScreenSpec(
    screen: 157,
    title: 'Activity',
    subtitle: 'Important actions across MoolSocial',
    kicker: 'PRIORITY INBOX',
    heroTitle: 'What needs you now',
    heroText:
        'Required actions stay clear. Offers and updates remain under your control.',
    stats: [
      SharedStat('Required', '2'),
      SharedStat('Orders', '3'),
      SharedStat('Work', '8'),
    ],
    filters: ['All', 'Required', 'Orders', 'Work', 'Offers', 'Updates'],
    listTitle: 'Latest',
    listNote: 'reason and next action',
    items: [
      SharedItem(
        id: 'pharmacy-renewal',
        category: 'Required',
        tone: 'required',
        unread: true,
        title: 'Renew pharmacy licence record',
        summary:
            'Review the licence expiry to keep medicine-selling capabilities active.',
        meta: 'MoolSocial Compliance · expires in 28 days',
        why:
            'You own a verified pharmacy workspace with a licence record nearing expiry.',
        facts: [
          SharedFact('WORKSPACE', 'Shree Medical'),
          SharedFact('DUE', '10 Aug 2026'),
          SharedFact('AFFECTS', 'Medicine sales'),
          SharedFact('PROMOTION', 'None'),
        ],
        steps: [
          SharedStep('Review', 'Check current licence details'),
          SharedStep('Update', 'Upload renewed document'),
          SharedStep('Verify', 'Compliance review'),
          SharedStep('Restore', 'Capability remains active'),
        ],
        currentStep: 0,
        primary: 'Review document',
        primaryOutcome: 'The exact licence, purpose and renewal action opened.',
        primaryRoute: '/app/account/identity',
      ),
      SharedItem(
        id: 'captain-onboarding',
        category: 'Work',
        tone: 'good',
        unread: true,
        title: 'Paid captain onboarding is open',
        summary:
            '₹600 for each approved taxi captain. Funding and capacity are live.',
        meta: 'Matched to your Freelancer workspace · Jodhpur',
        why:
            'Your verified freelancer profile, service area and work preferences match this funded opportunity.',
        facts: [
          SharedFact('PAYOUT', '₹600 approved'),
          SharedFact('CAPACITY', '814 left'),
          SharedFact('AREA', 'Jodhpur'),
          SharedFact('PROOF', 'Verified onboarding'),
        ],
        steps: [
          SharedStep('Terms', 'Review expected outcome'),
          SharedStep('Apply', 'Reserve work capacity'),
          SharedStep('Complete', 'Submit verified outcome'),
          SharedStep('Payout', 'After approval'),
        ],
        currentStep: 0,
        primary: 'View opportunity',
        primaryOutcome:
            'Funded work terms opened without applying automatically.',
        primaryRoute: '/app/earn',
        secondary: 'Save',
        secondaryOutcome:
            'Opportunity saved. No application or capacity reservation was created.',
      ),
      SharedItem(
        id: 'pickup-order',
        category: 'Orders',
        unread: true,
        title: 'Order ready for counter pickup',
        summary: 'Mahadev Fresh Mart has packed all 6 items.',
        meta: 'Order MS-2941 · paid ₹645',
        why:
            'This is an active order placed from your personal consumer account.',
        facts: [
          SharedFact('ORDER', 'MS-2941'),
          SharedFact('ITEMS', '6 of 6'),
          SharedFact('PICKUP', 'Counter'),
          SharedFact('BILL', 'Ready'),
        ],
        steps: [
          SharedStep('Placed', 'Payment confirmed'),
          SharedStep('Packed', 'All items ready'),
          SharedStep('Collect', 'Pick up at counter'),
        ],
        currentStep: 2,
        primary: 'Open order',
        primaryOutcome: 'Pickup code, store location and bill opened.',
        primaryRoute: '/app/buy/grocery',
      ),
      SharedItem(
        id: 'basket-offer',
        category: 'Offers',
        title: 'Nearby grocery basket price is ready',
        summary:
            'See the final price, delivery time and refund rule before buying.',
        meta: 'Available in your current area · promotional',
        why:
            'You allowed local offers and your current area has confirmed supply.',
        facts: [
          SharedFact('PRICE', 'From ₹399'),
          SharedFact('DELIVERY', '45 min'),
          SharedFact('AREA', 'Jodhpur'),
          SharedFact('EXPIRES', 'Today'),
        ],
        steps: [
          SharedStep('Compare', 'Price and fulfilment'),
          SharedStep('Choose', 'Retail or basket'),
          SharedStep('Pay', 'Only after final review'),
        ],
        currentStep: 0,
        primary: 'Check price',
        primaryOutcome: 'Decision-ready basket options opened.',
        primaryRoute: '/app/buy/grocery',
        secondary: 'Not interested',
        secondaryOutcome:
            'This offer was dismissed. Required activity is unchanged.',
      ),
      SharedItem(
        id: 'stock-assistant',
        category: 'Updates',
        title: 'Retailer stock assistant is available',
        summary: 'Review suggested stock actions before anything changes.',
        meta: 'Mahadev Fresh Mart · feature update',
        why:
            'Your verified retailer workspace supports this feature and runs a compatible app version.',
        facts: [
          SharedFact('WORKSPACE', 'Mahadev Fresh Mart'),
          SharedFact('CONTROL', 'Review first'),
          SharedFact('CHANGES', 'Never automatic'),
          SharedFact('VERSION', '6.4+'),
        ],
        steps: [
          SharedStep('Preview', 'See assistant suggestions'),
          SharedStep('Choose', 'Approve individual actions'),
          SharedStep('Track', 'Audit every change'),
        ],
        currentStep: 0,
        primary: 'Open assistant',
        primaryOutcome: 'Retailer assistant opened in review-only mode.',
        primaryRoute: '/app/retailer?panel=ai',
        secondary: 'Later',
        secondaryOutcome: 'Update kept in Activity without changing stock.',
      ),
    ],
  ),
  158: SharedScreenSpec(
    screen: 158,
    title: 'Identity & documents',
    subtitle: 'One identity, permission-safe workspaces',
    kicker: 'YOUR CONTROL',
    heroTitle: 'Verified once, shared only when needed',
    heroText:
        'See what is verified, where it is used and when consent expires.',
    stats: [
      SharedStat('Identity', 'Verified'),
      SharedStat('Workspaces', '3'),
      SharedStat('Due soon', '1'),
    ],
    filters: ['All', 'Identity', 'Workspaces', 'Consent'],
    listTitle: 'Records and permissions',
    items: [
      _identity,
      SharedItem(
        id: 'retailer-documents',
        category: 'Workspaces',
        title: 'Retailer business documents',
        summary: 'GST is pending; shop and bank proofs are verified.',
        meta: 'Mahadev Fresh Mart',
        why:
            'These records unlock only retailer capabilities and are not exposed to consumers.',
        facts: [
          SharedFact('GST', 'Pending'),
          SharedFact('SHOP PROOF', 'Verified'),
          SharedFact('BANK', 'Verified'),
          SharedFact('OWNER', 'Matched'),
        ],
        steps: [
          SharedStep('Owner', 'Identity matched'),
          SharedStep('Business', 'Proof checked'),
          SharedStep('GST', 'Add when available'),
          SharedStep('Capabilities', 'Expand after review'),
        ],
        currentStep: 2,
        primary: 'Add GST certificate',
        primaryOutcome: 'Secure file choices opened for the GST certificate.',
        primaryRoute: '/app/files',
      ),
      SharedItem(
        id: 'pharmacy-consent',
        category: 'Consent',
        tone: 'required',
        title: 'Pharmacy document access expires',
        summary: 'Renew permission for licence verification.',
        meta: 'Shree Medical · 28 days left',
        why:
            'The compliance reviewer needs time-limited access to validate the regulated record.',
        facts: [
          SharedFact('DOCUMENT', 'Drug licence'),
          SharedFact('ACCESS', 'Compliance team'),
          SharedFact('EXPIRES', '10 Aug 2026'),
          SharedFact('PURPOSE', 'Licence check'),
        ],
        steps: [
          SharedStep('Review', 'Exact document and purpose'),
          SharedStep('Allow', 'Set time-limited access'),
          SharedStep('Audit', 'See every access'),
        ],
        currentStep: 0,
        primary: 'Renew permission',
        primaryOutcome:
            'Permission renewed for 30 days with a consent receipt.',
        confirmation:
            'I allow the compliance team to access this licence for 30 days only.',
        secondary: 'Contact support',
        secondaryOutcome: 'Support options opened with this document context.',
        secondaryRoute: '/app/account/security',
      ),
      SharedItem(
        id: 'alternate-mobile',
        category: 'Identity',
        title: 'Alternate mobile',
        summary:
            'Add a verified backup number for account recovery and urgent work alerts.',
        meta: 'Optional · never used for promotions without consent',
        why:
            'A verified backup number can restore access if your primary number is unavailable.',
        facts: [
          SharedFact('STATUS', 'Not added'),
          SharedFact('OTP', 'Required'),
          SharedFact('PROMOTIONS', 'Off'),
          SharedFact('RECOVERY', 'Allowed'),
        ],
        steps: [
          SharedStep('Enter', 'Alternate mobile'),
          SharedStep('Verify', 'One-time password'),
          SharedStep('Choose', 'Recovery and alert consent'),
        ],
        currentStep: 0,
        primary: 'Add number',
        primaryOutcome:
            'Backup number verification started. Promotions remain off.',
        confirmation:
            'I want this verified number used for recovery and urgent account alerts only.',
      ),
    ],
  ),
  159: SharedScreenSpec(
    screen: 159,
    title: 'Ask MoolSocial',
    subtitle: 'Search, ask, scan or speak',
    kicker: 'ONE INPUT',
    heroTitle: 'What do you want to do?',
    heroText:
        'Try “atta under ₹300”, “book a cab”, “show today’s orders” or scan a product.',
    stats: [
      SharedStat('Mode', 'Ask'),
      SharedStat('Area', 'Jodhpur'),
      SharedStat('Context', 'Personal'),
    ],
    filters: ['Recent', 'Buy', 'Book', 'Work', 'Workspace'],
    listTitle: 'Recent and suggested',
    listNote: 'opens the exact action',
    topAction: 'Scan',
    items: [
      SharedItem(
        id: 'atta',
        category: 'Buy',
        title: 'Atta under ₹300 delivered today',
        summary:
            'Compare final price, pack, delivery and refund before adding.',
        meta: 'Personal · current area',
        why:
            'Your request includes the product, maximum price, fulfilment and area.',
        facts: [
          SharedFact('INTENT', 'Buy product'),
          SharedFact('BUDGET', 'Under ₹300'),
          SharedFact('TIME', 'Today'),
          SharedFact('AREA', 'Jodhpur'),
        ],
        steps: [
          SharedStep('Understand', 'Product, budget and time'),
          SharedStep('Match', 'Confirmed nearby supply'),
          SharedStep('Decide', 'Price, proof and fulfilment'),
        ],
        currentStep: 1,
        primary: 'See matching atta',
        primaryOutcome: 'Matching product decisions opened.',
        primaryRoute: '/app/buy/grocery',
      ),
      SharedItem(
        id: 'airport-cab',
        category: 'Book',
        title: 'Book a cab to Jodhpur Airport',
        summary: 'Set pickup, compare ride options and confirm fare.',
        meta: 'Personal · location needed',
        why: 'Pickup is requested only when you continue to the ride owner.',
        facts: [
          SharedFact('SERVICE', 'Cab'),
          SharedFact('DESTINATION', 'Jodhpur Airport'),
          SharedFact('PAYMENT', 'After trip'),
          SharedFact('SAFETY', 'Live trip'),
        ],
        steps: [
          SharedStep('Pickup', 'Confirm current place'),
          SharedStep('Options', 'Fare and arrival'),
          SharedStep('Confirm', 'Request captain'),
        ],
        currentStep: 0,
        primary: 'Set pickup',
        primaryOutcome: 'Cab pickup and destination owner opened.',
        primaryRoute: '/app/ride/book?type=cab',
      ),
      SharedItem(
        id: 'retailer-orders',
        category: 'Workspace',
        title: 'Show today’s retailer orders',
        summary:
            'Open accepted, pending and delivery orders for Mahadev Fresh Mart.',
        meta: 'Retailer workspace · authorized owner',
        why: 'Your owner role permits this filtered business view.',
        facts: [
          SharedFact('WORKSPACE', 'Mahadev Fresh Mart'),
          SharedFact('OPEN', '8 orders'),
          SharedFact('URGENT', '2'),
          SharedFact('ACCESS', 'Owner'),
        ],
        steps: [
          SharedStep('Resolve', 'Correct workspace'),
          SharedStep('Authorize', 'Permission checked'),
          SharedStep('Open', 'Filtered order queue'),
        ],
        currentStep: 2,
        primary: 'Open orders',
        primaryOutcome: 'Authorized retailer order queue opened.',
        primaryRoute: '/app/retailer',
      ),
      SharedItem(
        id: 'nearby-work',
        category: 'Work',
        title: 'Paid work near me',
        summary:
            'See funded opportunities matched to your verified profiles and area.',
        meta: 'Earn · eligibility resolved live',
        why:
            'Verified profile, declared preference and area determine the match.',
        facts: [
          SharedFact('AREA', 'Jodhpur'),
          SharedFact('MATCHES', '18'),
          SharedFact('FUNDED', '12'),
          SharedFact('PROFILE', 'Freelancer'),
        ],
        steps: [
          SharedStep('Eligibility', 'Profile and area'),
          SharedStep('Terms', 'Payout and proof'),
          SharedStep('Apply', 'Reserve capacity'),
        ],
        currentStep: 0,
        primary: 'See opportunities',
        primaryOutcome: 'Funded opportunities opened without applying.',
        primaryRoute: '/app/earn',
      ),
    ],
  ),
  160: SharedScreenSpec(
    screen: 160,
    title: 'Files',
    subtitle: 'Documents, evidence and media',
    kicker: 'SECURE FILES',
    heroTitle: 'Reuse safely, upload once',
    heroText:
        'Every file shows its purpose, access, retention and linked action.',
    stats: [
      SharedStat('Files', '48'),
      SharedStat('Private', '41'),
      SharedStat('Due', '2'),
    ],
    filters: ['All', 'Documents', 'Evidence', 'Media', 'Clinical'],
    listTitle: 'Your files',
    topAction: 'Add',
    items: [
      SharedItem(
        id: 'gst',
        category: 'Documents',
        tone: 'good',
        title: 'GST certificate',
        summary:
            'Used by Mahadev Fresh Mart for business verification and invoices.',
        meta: 'PDF · 1.2 MB · verified',
        why: 'Uploaded by you during retailer workspace verification.',
        facts: [
          SharedFact('OWNER', 'You'),
          SharedFact('ACCESS', 'Retail compliance'),
          SharedFact('USED BY', '1 workspace'),
          SharedFact('RETENTION', 'While active + policy'),
        ],
        steps: [
          SharedStep('Uploaded', 'Source recorded'),
          SharedStep('Verified', 'Reviewer approved'),
          SharedStep('In use', 'Retailer capability'),
        ],
        currentStep: 3,
        primary: 'View document',
        primaryOutcome: 'Verified PDF preview opened.',
        secondary: 'Access log',
        secondaryOutcome:
            'Document access history opened with actor, purpose and time.',
      ),
      SharedItem(
        id: 'order-evidence',
        category: 'Evidence',
        title: 'Order issue photos',
        summary: 'Three photos linked to issue case MS-2941.',
        meta: 'Private · case closes in 4 days',
        why: 'You submitted these photos to support a missing-item claim.',
        facts: [
          SharedFact('CASE', 'MS-2941'),
          SharedFact('FILES', '3 photos'),
          SharedFact('ACCESS', 'Case team'),
          SharedFact('DELETE', 'After retention'),
        ],
        steps: [
          SharedStep('Submitted', 'Evidence received'),
          SharedStep('Review', 'Case team checking'),
          SharedStep('Close', 'Decision and retention'),
        ],
        currentStep: 1,
        primary: 'Open case',
        primaryOutcome: 'Issue case opened with all three evidence files.',
      ),
      SharedItem(
        id: 'basket-short',
        category: 'Media',
        title: 'Fresh basket short',
        summary:
            'Published to Social; original and edited versions are retained.',
        meta: 'Video · 26 sec · creator workspace',
        why: 'Created and published by your verified creator profile.',
        facts: [
          SharedFact('VISIBILITY', 'Public'),
          SharedFact('RIGHTS', 'Declared original'),
          SharedFact('VERSIONS', '2'),
          SharedFact('EARNINGS', 'Eligible'),
        ],
        steps: [
          SharedStep('Upload', 'Original secured'),
          SharedStep('Checks', 'Safety and rights'),
          SharedStep('Publish', 'Social audience'),
        ],
        currentStep: 3,
        primary: 'View performance',
        primaryOutcome: 'Creator performance opened with aggregated results.',
        primaryRoute: '/app/creator/performance',
        secondary: 'Manage media',
        secondaryOutcome:
            'Original, edit, rights and publication controls opened.',
      ),
      SharedItem(
        id: 'doctor-report',
        category: 'Clinical',
        tone: 'required',
        title: 'Doctor follow-up report',
        summary: 'Clinical record is separated from business and social files.',
        meta: 'PDF · access expires in 6 days',
        why:
            'You allowed Dr Mehta’s clinic to use this report for your follow-up appointment.',
        facts: [
          SharedFact('PATIENT', 'You'),
          SharedFact('ACCESS', 'Dr Mehta Clinic'),
          SharedFact('PURPOSE', 'Follow-up'),
          SharedFact('EXPIRES', '25 Jul 2026'),
        ],
        steps: [
          SharedStep('Consent', 'Time-limited access'),
          SharedStep('Consult', 'Doctor review'),
          SharedStep('Expire', 'Access ends automatically'),
        ],
        currentStep: 1,
        primary: 'Review access',
        primaryOutcome: 'Clinical access purpose, recipient and expiry opened.',
        secondary: 'Revoke',
        secondaryOutcome:
            'Future clinical access revoked. Existing medical records were not deleted.',
        secondaryConfirmation:
            'I understand revocation ends future clinic access and does not delete the medical record.',
      ),
    ],
  ),
  161: SharedScreenSpec(
    screen: 161,
    title: 'Security & support',
    subtitle: 'Protect access, money and work',
    kicker: 'ACCOUNT SAFE',
    heroTitle: 'No unknown activity detected',
    heroText:
        'Review devices, recovery, permissions and urgent support from one place.',
    stats: [
      SharedStat('Devices', '2'),
      SharedStat('Passkey', 'On'),
      SharedStat('Alerts', '0'),
    ],
    filters: ['All', 'Security', 'Access', 'Support'],
    listTitle: 'Account controls',
    items: [
      SharedItem(
        id: 'devices',
        category: 'Security',
        tone: 'good',
        title: 'Signed-in devices',
        summary:
            'OPPO phone active now; Chrome on Windows active 18 minutes ago.',
        meta: 'Two trusted sessions',
        why: 'Device visibility helps you remove access you do not recognize.',
        facts: [
          SharedFact('CURRENT', 'OPPO CPH2375'),
          SharedFact('OTHER', 'Windows Chrome'),
          SharedFact('LAST CHECK', 'Now'),
          SharedFact('UNKNOWN', 'None'),
        ],
        steps: [
          SharedStep('Review', 'Device and location'),
          SharedStep('Remove', 'End unknown sessions'),
          SharedStep('Secure', 'Reset recovery if needed'),
        ],
        currentStep: 0,
        primary: 'Manage devices',
        primaryOutcome: 'Trusted sessions and remove-access controls opened.',
      ),
      SharedItem(
        id: 'recovery',
        category: 'Security',
        title: 'Passkey and recovery',
        summary: 'Passkey is active; alternate recovery mobile is not added.',
        meta: 'Recommended action available',
        why:
            'A passkey reduces phishing risk; a verified backup helps recover access.',
        facts: [
          SharedFact('PASSKEY', 'Active'),
          SharedFact('OTP', 'Primary mobile'),
          SharedFact('BACKUP', 'Not added'),
          SharedFact('EMAIL', 'Verified'),
        ],
        steps: [
          SharedStep('Passkey', 'Active on this phone'),
          SharedStep('Backup', 'Add alternate mobile'),
          SharedStep('Codes', 'Store recovery codes'),
        ],
        currentStep: 1,
        primary: 'Complete recovery',
        primaryOutcome:
            'Recovery setup opened without exposing any recovery secret.',
        primaryRoute: '/app/account/identity',
      ),
      SharedItem(
        id: 'access-log',
        category: 'Access',
        title: 'Workspace access log',
        summary:
            'See staff, admin and integration actions across your workspaces.',
        meta: 'Last privileged action 2 hours ago',
        why:
            'Every privileged workspace action is recorded with actor, reason and result.',
        facts: [
          SharedFact('WORKSPACES', '3'),
          SharedFact('STAFF', '4'),
          SharedFact('INTEGRATIONS', '2'),
          SharedFact('ANOMALIES', '0'),
        ],
        steps: [
          SharedStep('Filter', 'Workspace or actor'),
          SharedStep('Inspect', 'Reason and before/after'),
          SharedStep('Report', 'Escalate unknown action'),
        ],
        currentStep: 0,
        primary: 'View access log',
        primaryOutcome:
            'Access history opened with actor, reason and before/after state.',
      ),
      SharedItem(
        id: 'emergency-lock',
        category: 'Support',
        tone: 'required',
        title: 'Urgent account lock',
        summary:
            'Temporarily stop payments and workspace changes if your phone is lost.',
        meta: 'Personal access can be restored after verification',
        why:
            'Use only when you believe someone else may control your account or device.',
        facts: [
          SharedFact('STOPS', 'Payments + changes'),
          SharedFact('KEEPS', 'Support access'),
          SharedFact('RESTORE', 'Identity check'),
          SharedFact('ALERTS', 'Workspace owners'),
        ],
        steps: [
          SharedStep('Confirm', 'Choose affected access'),
          SharedStep('Lock', 'Immediate server action'),
          SharedStep('Recover', 'Verified restoration'),
        ],
        currentStep: 0,
        primary: 'Start emergency lock',
        primaryOutcome:
            'Emergency lock activated. Payments and workspace changes stopped; support remains available.',
        confirmation:
            'I believe my account or device may be unsafe and want to stop payments and workspace changes now.',
        secondary: 'Contact support',
        secondaryOutcome: 'Urgent account support opened.',
      ),
    ],
  ),
  162: SharedScreenSpec(
    screen: 162,
    title: 'Workspaces',
    subtitle: 'Personal access always stays active',
    kicker: 'ONE ACCOUNT',
    heroTitle: 'Your personal life and work, one tap apart',
    heroText:
        'Open the exact workspace without changing or removing your consumer and social access.',
    stats: [
      SharedStat('Active', '3'),
      SharedStat('Actions due', '4'),
      SharedStat('Today', '₹18.4K'),
    ],
    filters: ['All', 'Personal', 'Business', 'Creator', 'Settings'],
    listTitle: 'Your spaces',
    listNote: 'tap to open',
    topAction: 'Add',
    items: [
      SharedItem(
        id: 'personal',
        category: 'Personal',
        tone: 'good',
        title: 'Personal & Social',
        summary: 'Social, Buy, Eat, Ride, Book, Pay, Work and Chat.',
        meta: 'Always active · default opens Social',
        why: 'Every MoolSocial account remains an individual consumer first.',
        facts: [
          SharedFact('SOCIAL', 'Ready'),
          SharedFact('CONSUMER', 'Always active'),
          SharedFact('AREA', 'Jodhpur'),
          SharedFact('PRIVACY', 'Personal'),
        ],
        steps: [SharedStep('Open', 'Return to focused personal experience')],
        currentStep: 0,
        primary: 'Open personal',
        primaryOutcome: 'Personal and Social opened.',
        primaryRoute: '/app/social',
      ),
      SharedItem(
        id: 'retailer',
        category: 'Business',
        unread: true,
        title: 'Mahadev Fresh Mart',
        summary: '2 orders need action; stock and wholesale buying are ready.',
        meta: 'Retailer · verified · Jodhpur',
        why: 'You created and verified this retailer workspace.',
        facts: [
          SharedFact('ORDERS', '2 urgent'),
          SharedFact('SALES TODAY', '₹18,420'),
          SharedFact('STOCK ALERTS', '6'),
          SharedFact('ROLE', 'Owner'),
        ],
        steps: [
          SharedStep('Priority', 'Resolve customer orders'),
          SharedStep('Operate', 'Stock and wholesale buy'),
          SharedStep('Grow', 'Offers and paid services'),
        ],
        currentStep: 0,
        primary: 'Open retailer workspace',
        primaryOutcome: 'Retailer operating home opened.',
        primaryRoute: '/app/retailer',
        secondary: 'Workspace settings',
        secondaryOutcome:
            'Retailer visibility, demand and communication controls opened.',
        secondaryRoute: '/app/account/workspaces/preferences?item=retailer',
      ),
      SharedItem(
        id: 'creator',
        category: 'Creator',
        title: 'Mahadev Local',
        summary:
            'One draft, two campaign matches and creator earnings available.',
        meta: 'Creator · verified · mobile and web',
        why: 'You activated a creator profile on this account.',
        facts: [
          SharedFact('DRAFTS', '1'),
          SharedFact('CAMPAIGNS', '2'),
          SharedFact('EARNINGS', '₹4,860'),
          SharedFact('WEB', 'Enabled'),
        ],
        steps: [
          SharedStep('Create', 'Publish or manage content'),
          SharedStep('Perform', 'Audience and results'),
          SharedStep('Earn', 'Campaigns and payout'),
        ],
        currentStep: 0,
        primary: 'Open creator studio',
        primaryOutcome: 'Creator Studio opened.',
        primaryRoute: '/app/creator',
        secondary: 'Channel settings',
        secondaryOutcome:
            'Creator visibility and communication controls opened.',
        secondaryRoute: '/app/account/workspaces/preferences?item=creator',
      ),
      SharedItem(
        id: 'freelancer',
        category: 'Business',
        title: 'Freelancer work',
        summary:
            'Three active assignments and ₹2,400 available after approval.',
        meta: 'Earn workspace · verified',
        why: 'Your freelancer profile is eligible for funded platform work.',
        facts: [
          SharedFact('ACTIVE', '3'),
          SharedFact('DUE TODAY', '1'),
          SharedFact('AVAILABLE', '₹2,400'),
          SharedFact('RATING', '4.8'),
        ],
        steps: [
          SharedStep('Work', 'Complete active output'),
          SharedStep('Proof', 'Submit outcome'),
          SharedStep('Earn', 'Track approval and payout'),
        ],
        currentStep: 0,
        primary: 'Open My Work',
        primaryOutcome: 'Active funded work opened.',
        primaryRoute: '/app/earn/active',
      ),
      SharedItem(
        id: 'identity',
        category: 'Settings',
        title: 'Identity and consent',
        summary: 'Verified identity, linked documents and consent history.',
        meta: 'Reusable across eligible workspaces',
        why:
            'Keep identity and consent evidence in one account-controlled place.',
        facts: [
          SharedFact('IDENTITY', 'Verified'),
          SharedFact('DOCUMENTS', 'Linked'),
          SharedFact('CONSENT', 'Audited'),
        ],
        steps: [SharedStep('Review', 'See identity and permissions')],
        currentStep: 0,
        primary: 'Open identity',
        primaryOutcome: 'Identity and consent opened.',
        primaryRoute: '/app/account/identity',
      ),
      SharedItem(
        id: 'ask',
        category: 'Settings',
        title: 'Ask, scan and voice',
        summary:
            'Use one input for questions, documents, QR and voice actions.',
        meta: 'Available across personal and work',
        why: 'Start a task without searching through multiple workspace menus.',
        facts: [
          SharedFact('ASK', 'Ready'),
          SharedFact('SCAN', 'Ready'),
          SharedFact('VOICE', 'Ready'),
        ],
        steps: [SharedStep('Start', 'Choose an input')],
        currentStep: 0,
        primary: 'Open universal input',
        primaryOutcome: 'Ask MoolSocial opened.',
        primaryRoute: '/app/ask',
      ),
      SharedItem(
        id: 'files',
        category: 'Settings',
        title: 'Files and evidence',
        summary:
            'Photos, invoices, reports and task proof in one controlled library.',
        meta: 'Private until you share it',
        why: 'Reuse files without uploading the same evidence repeatedly.',
        facts: [
          SharedFact('FILES', 'Ready'),
          SharedFact('ACCESS', 'Controlled'),
          SharedFact('AUDIT', 'On'),
        ],
        steps: [SharedStep('Open', 'Choose or capture evidence')],
        currentStep: 0,
        primary: 'Open files',
        primaryOutcome: 'Files and evidence opened.',
        primaryRoute: '/app/files',
      ),
      SharedItem(
        id: 'security',
        category: 'Settings',
        title: 'Security and support',
        summary: 'Devices, sessions, account recovery and support cases.',
        meta: 'Account protection and help',
        why: 'Protect every personal and work layer from one account.',
        facts: [
          SharedFact('DEVICES', '2'),
          SharedFact('SECURITY', 'Protected'),
          SharedFact('SUPPORT', 'Available'),
        ],
        steps: [SharedStep('Review', 'Check security or get help')],
        currentStep: 0,
        primary: 'Open security',
        primaryOutcome: 'Security and support opened.',
        primaryRoute: '/app/account/security',
      ),
      SharedItem(
        id: 'preferences',
        category: 'Settings',
        title: 'Global preferences',
        summary:
            'Language, area, notifications, accessibility and data controls.',
        meta: 'Applied across personal and eligible workspaces',
        why:
            'Account choices apply only where a workspace has no required operating rule.',
        facts: [
          SharedFact('LANGUAGE', 'English (India)'),
          SharedFact('AREA', 'Live + home'),
          SharedFact('QUIET HOURS', '10 PM–7 AM'),
          SharedFact('ACCESSIBILITY', 'Default'),
        ],
        steps: [
          SharedStep('Choose', 'Update account preference'),
          SharedStep('Preview', 'See affected workspaces'),
          SharedStep('Apply', 'Save with audit'),
        ],
        currentStep: 0,
        primary: 'Manage preferences',
        primaryOutcome: 'Personalized controls opened.',
        primaryRoute: '/app/account/workspaces/preferences',
      ),
    ],
  ),
  165: SharedScreenSpec(
    screen: 165,
    title: 'Personalized controls',
    subtitle: 'Personal, social, agent and workspace settings',
    kicker: 'YOU DECIDE',
    heroTitle: 'On when you want. Quiet when you don’t.',
    heroText:
        'Control how people find you, when workspaces accept demand, what your agent may do and which messages reach you.',
    stats: [
      SharedStat('Workspaces', '4'),
      SharedStat('Open now', '2'),
      SharedStat('Agent plan', 'Off'),
    ],
    filters: [
      'All',
      'Personal',
      'Social',
      'Communication',
      'Workspaces',
      'Agent',
      'Privacy',
    ],
    listTitle: 'Your controls',
    listNote: 'tap one area',
    items: [
      SharedItem(
        id: 'personal',
        category: 'Personal',
        title: 'Personal experience',
        summary: 'Area, quiet hours, data use and accessibility preferences.',
        meta:
            'Applied across personal access unless a workspace needs an operating rule',
        why:
            'These account defaults shape the app without changing accepted orders, bookings, rides or work.',
        facts: [
          SharedFact('LANGUAGE', 'English (India)'),
          SharedFact('HOME AREA', 'Jodhpur'),
          SharedFact('QUIET HOURS', '10 PM–7 AM'),
          SharedFact('DATA MODE', 'Standard'),
        ],
        steps: [
          SharedStep('Choose', 'Review each personal preference'),
          SharedStep('Save', 'Apply with preference receipt'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'current-area',
            label: 'Use current area while using app',
            note: 'Improves nearby products and services',
            initialValue: true,
          ),
          SharedControl(
            id: 'quiet-hours',
            label: 'Quiet hours',
            note: 'Optional alerts wait until 7 AM',
            initialValue: true,
          ),
          SharedControl(
            id: 'data-saver',
            label: 'Data saver',
            note: 'Reduce video and image data',
            initialValue: false,
          ),
          SharedControl(
            id: 'accessibility',
            label: 'Accessibility reminders',
            note: 'Remember captions and readable text choices',
            initialValue: true,
          ),
        ],
        scheduleTitle: 'Quiet hours · Asia/Kolkata',
        schedule: [
          SharedSchedule('Every day', '10:00 PM–7:00 AM'),
          SharedSchedule('Safety and active trips', 'May alert when required'),
        ],
        primary: 'Save personal settings',
        primaryOutcome:
            'Personal settings saved with preference receipt SHARED-165-PERSONAL.',
      ),
      SharedItem(
        id: 'social',
        category: 'Social',
        title: 'Social, messages and creator interactions',
        summary:
            'Feed style, comments, mentions, message requests and collaboration invites.',
        meta: 'Public post visibility is still chosen for each post',
        why:
            'Discoverability, posting visibility and communication permission remain separate controls.',
        facts: [
          SharedFact('FEED', 'Personalized'),
          SharedFact('COMMENTS', 'Followers + public posts'),
          SharedFact('MESSAGES', 'Requests allowed'),
          SharedFact('AUTOPLAY', 'Wi-Fi + mobile'),
        ],
        steps: [
          SharedStep('Choose', 'Review social permissions'),
          SharedStep('Save', 'Apply future interaction rules'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'feed',
            label: 'Personalized feed',
            note: 'Use allowed follows and interactions',
            initialValue: true,
          ),
          SharedControl(
            id: 'comments',
            label: 'Comments on public posts',
            note: 'Followers and people you reply to',
            initialValue: true,
          ),
          SharedControl(
            id: 'mentions',
            label: 'Mentions and tags',
            note: 'People you follow',
            initialValue: true,
          ),
          SharedControl(
            id: 'messages',
            label: 'Message requests',
            note: 'Unknown people stay in Requests',
            initialValue: true,
          ),
          SharedControl(
            id: 'activity-status',
            label: 'Activity status',
            note: 'Show when recently active',
            initialValue: false,
          ),
          SharedControl(
            id: 'read-receipts',
            label: 'Read receipts',
            note: 'Show when messages are read',
            initialValue: true,
          ),
          SharedControl(
            id: 'campaign-invites',
            label: 'Creator and campaign invitations',
            note: 'Only verified and eligible opportunities',
            initialValue: true,
          ),
          SharedControl(
            id: 'autoplay',
            label: 'Autoplay social video',
            note: 'Can increase mobile data use',
            initialValue: true,
          ),
        ],
        primary: 'Save social settings',
        primaryOutcome: 'Social interaction settings saved.',
        secondary: 'Blocked accounts',
        secondaryOutcome: 'Blocked-account list opened.',
      ),
      SharedItem(
        id: 'communication',
        category: 'Communication',
        title: 'Alerts, reminders and message channels',
        summary:
            'Choose purpose first, then decide which channel may contact you.',
        meta:
            'Required actions remain in Activity even when optional alerts are off',
        why:
            'Transactional and safety communication is separated from promotions, reminders and advertising.',
        facts: [
          SharedFact('IN-APP', 'Always available'),
          SharedFact('PUSH', '7 purposes on'),
          SharedFact('EMAIL', 'Receipts only'),
          SharedFact('SMS/WHATSAPP', 'Urgent only'),
        ],
        steps: [
          SharedStep('Purpose', 'Choose each message reason'),
          SharedStep('Channel', 'Apply consent and quiet hours'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'active-obligations',
            label: 'Active orders, bookings, rides and work',
            note: 'Required destination updates',
            initialValue: true,
            locked: true,
            lockedMessage:
                'Required updates stay in Activity while an obligation is active.',
          ),
          SharedControl(
            id: 'security-alerts',
            label: 'Account and security alerts',
            note: 'Important protection notices',
            initialValue: true,
            locked: true,
            lockedMessage:
                'Critical account security notices cannot be disabled.',
          ),
          SharedControl(
            id: 'chat-requests',
            label: 'People chat requests',
            note: 'Push alert for accepted contacts',
            initialValue: true,
          ),
          SharedControl(
            id: 'business-messages',
            label: 'Business and customer messages',
            note: 'Orders, bookings and enquiries',
            initialValue: true,
          ),
          SharedControl(
            id: 'repeat-reminders',
            label: 'Reorder and repeat-booking reminders',
            note: 'Based on completed activity',
            initialValue: true,
          ),
          SharedControl(
            id: 'work-matches',
            label: 'Matched work opportunities',
            note: 'Verified eligibility and funded capacity',
            initialValue: true,
          ),
          SharedControl(
            id: 'feature-updates',
            label: 'New features and upgrades',
            note: 'Only features available to your account',
            initialValue: true,
          ),
          SharedControl(
            id: 'offers',
            label: 'Offers and relevant advertisements',
            note: 'Personalized promotional communication',
            initialValue: false,
          ),
          SharedControl(
            id: 'promotional-channel',
            label: 'Promotional SMS or WhatsApp',
            note: 'Requires separate channel consent',
            initialValue: false,
          ),
        ],
        scheduleTitle: 'Optional communication · Asia/Kolkata',
        schedule: [
          SharedSchedule('Quiet hours', '10:00 PM–7:00 AM'),
          SharedSchedule('Optional frequency', 'Maximum 3 per week'),
          SharedSchedule('Required actions', 'Not combined with promotions'),
        ],
        primary: 'Save communication choices',
        primaryOutcome:
            'Communication choices applied to future eligible messages.',
        secondary: 'Channel details',
        secondaryOutcome:
            'Purpose, channel, consent and withdrawal details opened.',
      ),
      SharedItem(
        id: 'retailer',
        category: 'Workspaces',
        tone: 'good',
        title: 'Mahadev Fresh Mart',
        summary: 'Public now and accepting customer orders until 8:45 PM.',
        meta: 'Retailer · Jodhpur · automatic schedule on',
        why:
            'Customers can see truthful open, closed, order-cutoff and fulfilment states before buying.',
        preview: [
          'Open · accepting orders',
          'Orders until 8:45 PM · closes 9:00 PM',
        ],
        facts: [
          SharedFact('VISIBILITY', 'Public'),
          SharedFact('ORDERS', 'On'),
          SharedFact('NEXT CHANGE', '9:00 PM'),
          SharedFact('TIME ZONE', 'Asia/Kolkata'),
        ],
        steps: [
          SharedStep('Choose', 'Visibility and demand'),
          SharedStep('Schedule', 'Truthful customer state'),
          SharedStep('Save', 'Refresh customer cards'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'public',
            label: 'Show shop publicly',
            note: 'Customers can discover the shop and catalogue',
            initialValue: true,
          ),
          SharedControl(
            id: 'orders',
            label: 'Accept new orders',
            note: 'Existing accepted orders remain active if turned off',
            initialValue: true,
          ),
          SharedControl(
            id: 'schedule',
            label: 'Automatic opening schedule',
            note: 'Server opens and closes ordering at saved times',
            initialValue: true,
          ),
          SharedControl(
            id: 'pickup',
            label: 'Counter pickup',
            note: 'Customer can pay and collect at shop',
            initialValue: true,
          ),
          SharedControl(
            id: 'delivery',
            label: 'Home delivery',
            note: 'Use shop or MoolSocial delivery',
            initialValue: true,
          ),
          SharedControl(
            id: 'scheduled-orders',
            label: 'Scheduled orders while closed',
            note: 'Allow orders for next opening window',
            initialValue: false,
          ),
        ],
        scheduleTitle: 'Shop and order hours · Asia/Kolkata',
        schedule: [
          SharedSchedule('Mon–Sat', '8:00 AM–9:00 PM'),
          SharedSchedule('Sunday', '9:00 AM–2:00 PM'),
          SharedSchedule('Order cutoff', '15 min before close'),
        ],
        primary: 'Save shop controls',
        primaryOutcome:
            'Shop visibility, ordering and schedule updated. Customer cards refresh immediately.',
        confirmation:
            'I reviewed the customer-visible open state and understand accepted orders remain active.',
        secondary: 'Pause temporarily',
        secondaryOutcome:
            'New orders paused until the selected end time. Accepted orders remain visible.',
        secondaryConfirmation:
            'I understand only new orders pause; accepted customer orders remain active.',
      ),
      SharedItem(
        id: 'creator',
        category: 'Workspaces',
        title: 'Mahadev Local creator channel',
        summary:
            'Discoverable with comments, message requests and campaign invitations.',
        meta: 'Creator · mobile and web',
        why:
            'Creator visibility, public content, messages and paid collaboration availability can be controlled independently.',
        preview: [
          'Channel visible',
          'Campaign invitations on · messages in Requests',
        ],
        facts: [
          SharedFact('CHANNEL', 'Public'),
          SharedFact('MESSAGES', 'Requests'),
          SharedFact('CAMPAIGNS', 'On'),
          SharedFact('PUBLISHING', 'Available'),
        ],
        steps: [
          SharedStep('Choose', 'Channel and communication'),
          SharedStep('Save', 'Apply creator controls'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'channel',
            label: 'Show creator channel',
            note: 'People can discover your public profile',
            initialValue: true,
          ),
          SharedControl(
            id: 'comments',
            label: 'Allow comments',
            note: 'Per-post control remains available',
            initialValue: true,
          ),
          SharedControl(
            id: 'messages',
            label: 'Message requests',
            note: 'Unknown people do not enter the main inbox',
            initialValue: true,
          ),
          SharedControl(
            id: 'campaigns',
            label: 'Paid campaign invitations',
            note: 'Only verified, terms-ready opportunities',
            initialValue: true,
          ),
          SharedControl(
            id: 'collaboration',
            label: 'Collaboration availability',
            note: 'Show brands you are open to collaborate',
            initialValue: false,
          ),
        ],
        primary: 'Save creator controls',
        primaryOutcome: 'Creator channel settings saved.',
      ),
      SharedItem(
        id: 'freelancer',
        category: 'Workspaces',
        title: 'Freelancer work profile',
        summary: 'Available for remote and nearby paid work until 7:00 PM.',
        meta: 'Earn · verified · Jodhpur',
        why:
            'Work availability affects new matches only. Active assignments and payout tracking always remain available.',
        preview: [
          'Available for matched work',
          'Remote + Jodhpur · until 7:00 PM',
        ],
        facts: [
          SharedFact('PROFILE', 'Visible to eligible publishers'),
          SharedFact('MATCHES', 'On'),
          SharedFact('AREA', 'Jodhpur'),
          SharedFact('CAPACITY', '3 active'),
        ],
        steps: [
          SharedStep('Choose', 'Match and area'),
          SharedStep('Schedule', 'Availability window'),
          SharedStep('Save', 'Apply to new matches'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'matches',
            label: 'Accept new work matches',
            note: 'Does not auto-apply for any work',
            initialValue: true,
          ),
          SharedControl(
            id: 'remote',
            label: 'Remote work',
            note: 'Show eligible work from any area',
            initialValue: true,
          ),
          SharedControl(
            id: 'nearby',
            label: 'Nearby field work',
            note: 'Use selected service area',
            initialValue: true,
          ),
          SharedControl(
            id: 'instant-alerts',
            label: 'Instant funded-work alerts',
            note: 'Only verified funding and capacity',
            initialValue: true,
          ),
          SharedControl(
            id: 'campaign-work',
            label: 'Campaign and advertisement work',
            note: 'Creator, education and promotion assignments',
            initialValue: true,
          ),
        ],
        scheduleTitle: 'Work availability · Asia/Kolkata',
        schedule: [
          SharedSchedule('Mon–Sat', '9:00 AM–7:00 PM'),
          SharedSchedule('Sunday', 'Off'),
          SharedSchedule('Temporary override', 'None'),
        ],
        primary: 'Save work availability',
        primaryOutcome:
            'Freelancer availability updated; active work is unchanged.',
        confirmation:
            'I understand this changes new matches only and never cancels active work.',
        secondary: 'Pause new matches',
        secondaryOutcome:
            'New matches paused until the selected end time. Active work is unchanged.',
        secondaryConfirmation:
            'I understand active assignments and payout tracking remain available.',
      ),
      SharedItem(
        id: 'manufacturer',
        category: 'Workspaces',
        title: 'Rajasthan Foods factory',
        summary:
            'Catalogue visible and accepting wholesale orders during the saved order window.',
        meta: 'Manufacturer · Rajasthan · dispatch configured',
        why:
            'Wholesale catalogue visibility, new-order acceptance and transport modes are controlled separately.',
        preview: ['Accepting wholesale orders', 'Order window closes 6:00 PM'],
        facts: [
          SharedFact('CATALOGUE', 'Public to eligible buyers'),
          SharedFact('ORDERS', 'On'),
          SharedFact('CAPACITY', 'Live'),
          SharedFact('DISPATCH', 'Own + MoolSocial'),
        ],
        steps: [
          SharedStep('Choose', 'Catalogue and demand'),
          SharedStep('Schedule', 'Commercial hours'),
          SharedStep('Save', 'Apply to new wholesale orders'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'catalogue',
            label: 'Show wholesale catalogue',
            note: 'Eligible buyers see approved products and terms',
            initialValue: true,
          ),
          SharedControl(
            id: 'orders',
            label: 'Accept new wholesale orders',
            note: 'Existing purchase orders remain binding',
            initialValue: true,
          ),
          SharedControl(
            id: 'window',
            label: 'Automatic order window',
            note: 'Use saved commercial hours',
            initialValue: true,
          ),
          SharedControl(
            id: 'own-fleet',
            label: 'Own-fleet dispatch',
            note: 'Offer supplier transport where available',
            initialValue: true,
          ),
          SharedControl(
            id: 'mool-transport',
            label: 'MoolSocial transport',
            note: 'Allow platform transport selection',
            initialValue: true,
          ),
          SharedControl(
            id: 'buyer-pickup',
            label: 'Buyer pickup',
            note: 'Allow pickup under confirmed terms',
            initialValue: false,
          ),
        ],
        scheduleTitle: 'Wholesale order window · Asia/Kolkata',
        schedule: [
          SharedSchedule('Mon–Sat', '9:00 AM–6:00 PM'),
          SharedSchedule('Sunday', 'Closed'),
          SharedSchedule('Dispatch cutoff', '4:00 PM same-day'),
        ],
        primary: 'Save factory controls',
        primaryOutcome: 'Wholesale visibility and order controls updated.',
        confirmation:
            'I understand confirmed purchase orders remain binding if new orders are paused.',
        secondary: 'Pause new orders',
        secondaryOutcome:
            'New wholesale orders paused. Existing purchase orders remain binding.',
        secondaryConfirmation:
            'I understand existing purchase orders and dispatch obligations remain active.',
      ),
      SharedItem(
        id: 'agent',
        category: 'Agent',
        tone: 'required',
        title: 'Mool Agent',
        summary:
            'A scheduled work manager for personal tasks and every selected workspace.',
        meta: 'Optional monthly subscription · owner controls every boundary',
        why:
            'A subscription enables automation only inside the owner’s saved workspace, schedule, activity and limit rules.',
        facts: [
          SharedFact('PLAN', 'Not active'),
          SharedFact('NEXT BRIEF', '8:00 AM'),
          SharedFact('APPROVALS', 'Owner only'),
          SharedFact('AUDIT', 'Every action'),
        ],
        steps: [
          SharedStep('Plan', 'Choose monthly entitlement'),
          SharedStep('Scope', 'Select workspaces and limits'),
          SharedStep('Approve', 'Fresh approval for sensitive actions'),
          SharedStep('Audit', 'Review every action'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'enabled',
            label: 'Enable Mool Agent',
            note: 'Requires an active monthly plan',
            initialValue: false,
            subscriptionRequired: true,
          ),
          SharedControl(
            id: 'daily-brief',
            label: 'Prepare daily owner brief',
            note: 'Orders, stock, work, bookings, money and exceptions',
            initialValue: true,
          ),
          SharedControl(
            id: 'monitor',
            label: 'Monitor selected workspaces',
            note: 'No action outside selected verified workspaces',
            initialValue: true,
          ),
          SharedControl(
            id: 'drafts',
            label: 'Prepare replies and task drafts',
            note: 'Owner reviews before sending or publishing',
            initialValue: true,
          ),
          SharedControl(
            id: 'routine',
            label: 'Run pre-approved routine actions',
            note: 'Only exact saved suppliers, templates and limits',
            initialValue: false,
          ),
          SharedControl(
            id: 'sensitive',
            label: 'Ask before money, public or legal action',
            note: 'Fresh approval for every sensitive final step',
            initialValue: true,
            locked: true,
            lockedMessage:
                'Sensitive actions always require a fresh, scoped owner approval.',
          ),
        ],
        scheduleTitle: 'Agent working hours · Asia/Kolkata',
        schedule: [
          SharedSchedule('Daily brief', '8:00 AM'),
          SharedSchedule('Routine monitoring', '8:00 AM–9:00 PM'),
          SharedSchedule('Quiet hours', 'Only required approvals'),
          SharedSchedule('Temporary pause', 'None'),
        ],
        primary: 'Review monthly plans',
        primaryOutcome:
            'Monthly plan choices opened. No agent authority is active.',
        secondary: 'Preview daily brief',
        secondaryOutcome:
            'Today’s owner brief opened in preview. Nothing was sent or changed.',
      ),
      SharedItem(
        id: 'privacy',
        category: 'Privacy',
        title: 'Privacy and personalization',
        summary:
            'Control relevance, nearby suggestions, advertisements and activity use.',
        meta:
            'Essential security and product-health processing stays purpose-separated',
        why:
            'Optional personalization can be withdrawn without disabling personal access, transactions or verified workspaces.',
        facts: [
          SharedFact('PERSONALIZATION', 'On'),
          SharedFact('RELEVANT ADS', 'Off'),
          SharedFact('LOCATION', 'While using'),
          SharedFact('PRIVATE CHAT', 'Never used'),
        ],
        steps: [
          SharedStep('Choose', 'Optional personalization'),
          SharedStep('Review', 'Locked purpose boundaries'),
          SharedStep('Save', 'Create consent receipt'),
        ],
        currentStep: 0,
        controls: [
          SharedControl(
            id: 'products',
            label: 'Personalized products and services',
            note: 'Use allowed structured activity and preferences',
            initialValue: true,
          ),
          SharedControl(
            id: 'ads',
            label: 'Relevant advertisements',
            note: 'Promotional targeting based on allowed signals',
            initialValue: false,
          ),
          SharedControl(
            id: 'nearby',
            label: 'Nearby recommendations',
            note: 'Use current area while the app is in use',
            initialValue: true,
          ),
          SharedControl(
            id: 'work',
            label: 'Personalized work matches',
            note: 'Use verified profile, area and declared preferences',
            initialValue: true,
          ),
          SharedControl(
            id: 'health',
            label: 'Essential product-health events',
            note: 'Errors and action outcomes without private content',
            initialValue: true,
            locked: true,
            lockedMessage:
                'Essential product-health processing is purpose-limited. Open details to exercise applicable rights.',
          ),
          SharedControl(
            id: 'private-chat',
            label: 'Use private chat content',
            note: 'Private messages are never used for targeting',
            initialValue: false,
            locked: true,
            lockedMessage:
                'Private chat content is blocked from analytics and personalization.',
          ),
          SharedControl(
            id: 'location-history',
            label: 'Store continuous location history',
            note: 'Exact continuous history is not collected',
            initialValue: false,
            locked: true,
            lockedMessage:
                'Continuous location history is blocked outside active location-dependent services.',
          ),
        ],
        primary: 'Save privacy choices',
        primaryOutcome:
            'Privacy and personalization choices saved with a new consent receipt.',
        confirmation:
            'I reviewed optional personalization and understand essential security processing stays purpose-limited.',
        secondary: 'Access my data',
        secondaryOutcome:
            'Data access, correction, download and deletion options opened.',
        secondaryRoute: '/app/files',
      ),
    ],
  ),
};

SharedScreenSpec sharedScreenSpec(int screen) =>
    sharedScreenSpecs[screen] ?? sharedScreenSpecs[162]!;
