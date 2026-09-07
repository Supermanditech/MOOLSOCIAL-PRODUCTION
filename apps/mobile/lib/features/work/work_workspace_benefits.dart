class WorkWorkspaceBenefit {
  const WorkWorkspaceBenefit({
    required this.title,
    required this.detail,
    this.action = '',
    this.group = '',
  });
  final String title;
  final String detail;
  final String action;
  final String group;
}

class WorkWorkspaceBenefitContent {
  const WorkWorkspaceBenefitContent({
    required this.problem,
    required this.preview,
    required this.benefits,
    required this.difference,
    this.subtitle = '',
  });
  final String problem;
  final String preview;
  final List<WorkWorkspaceBenefit> benefits;
  final String difference;
  final String subtitle;
  bool get hasTopics => benefits.isNotEmpty && benefits.first.group.isNotEmpty;
}

const workWorkspaceGrowthTopics = ['Customers', 'Stock', 'Money', 'Daily work'];

WorkWorkspaceBenefitContent workWorkspaceBenefitFor(String profileId) {
  final content = workWorkspaceBenefits[profileId];
  if (content == null) {
    throw StateError('Workspace benefit content is missing for $profileId.');
  }
  if (profileId != 'retailer-speciality' && profileId != 'manufacturer') {
    return content;
  }
  return WorkWorkspaceBenefitContent(
    problem: content.problem,
    preview: content.preview,
    subtitle: content.subtitle,
    difference: content.difference,
    benefits: List.unmodifiable(
      content.benefits.map((point) {
        if (profileId == 'retailer-speciality' &&
            point.action == 'Create basket') {
          return const WorkWorkspaceBenefit(
            group: 'Customers',
            action: 'Create basket',
            title: 'The right products sell better together.',
            detail:
                'Offer a useful product bundle that customers can buy from your shop.',
          );
        }
        if (profileId == 'manufacturer' && point.action == 'Publish products') {
          return const WorkWorkspaceBenefit(
            group: 'Customers',
            action: 'Publish products',
            title: 'Finished goods are waiting for buyers.',
            detail:
                'Present your product range and clear trade terms to suitable retailers.',
          );
        }
        if (profileId == 'manufacturer' && point.action == 'Send offers') {
          return const WorkWorkspaceBenefit(
            group: 'Customers',
            action: 'Create Offer',
            title: 'Retailers don’t know your direct prices.',
            detail:
                'Create a product offer with quantity, dispatch terms and disclosed service charges.',
          );
        }
        return point;
      }),
    ),
  );
}

const _retailerGrowth = <WorkWorkspaceBenefit>[
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Send offers',
    title: 'Customers buy once, then disappear.',
    detail:
        'Use your shop’s customer records to send relevant offers to customers who want your updates.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Create basket',
    title: 'Their monthly shopping goes elsewhere.',
    detail:
        'Put regular essentials into a basket families can easily buy from you again.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Collect at store',
    title: 'Queues build up at the counter.',
    detail:
        'Customers order and pay before arriving. Pack ahead for checked collection.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Publish products',
    title: 'People don’t know what you stock.',
    detail:
        'Show your products, prices and availability before they decide where to buy.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Promote store',
    title: 'How will new customers find you?',
    detail: 'Put your products and offers in front of relevant nearby buyers.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Send store link',
    title: 'Phone orders mean repeating everything.',
    detail:
        'Send your shop link. Let customers choose items and pay in the app.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Clear stock',
    title: 'Money is stuck in unsold products.',
    detail:
        'Create an offer for slow-selling stock and make room for what customers need.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Send bill',
    title: 'The sale ends. The customer disappears.',
    detail: 'Send the purchase bill with a link to shop with you again.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Restock',
    title: 'Who watches the shop while you restock?',
    detail:
        'Compare and reorder from your counter. Check delivered prices and arrival dates before paying.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Buy Direct',
    title: 'Could the same goods cost less?',
    detail: 'Compare manufacturer offers with delivery and charges included.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Group Bulk Buying',
    title: 'You need the bulk rate, not a truckload.',
    detail:
        'Join other shops, choose your share and review the full delivered cost.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Track stock',
    title: 'It has left the supplier. When will it arrive?',
    detail:
        'Follow each purchase’s dispatch and latest expected-arrival update.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Receive goods',
    title: 'What if a carton is short or damaged?',
    detail:
        'Check what arrived, report differences and record the goods actually received.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Request stock',
    title: 'Can’t find the pack your customers need?',
    detail:
        'Send the exact product, quantity and required date as a stock request.',
  ),
  WorkWorkspaceBenefit(
    group: 'Money',
    action: 'Collect dues',
    title: 'Unpaid bills. Fresh stock still needs paying for.',
    detail:
        'See who owes what. Send a bill-linked reminder and check which payments have arrived.',
  ),
  WorkWorkspaceBenefit(
    group: 'Money',
    action: 'View statement',
    title: 'Bills and payment messages don’t add up.',
    detail:
        'Trace each sale, purchase and payment without searching separate records.',
  ),
  WorkWorkspaceBenefit(
    group: 'Money',
    action: 'Settle',
    title: 'How much can reach your bank?',
    detail:
        'See the amount available and request transfer to your registered account.',
  ),
  WorkWorkspaceBenefit(
    group: 'Money',
    action: 'Check earnings',
    title: 'A busy counter—but what did you keep?',
    detail:
        'See sales, known costs and charges separately, with a margin estimate when costs are available.',
  ),
  WorkWorkspaceBenefit(
    group: 'Money',
    action: 'Check eligibility',
    title: 'Customers want it. Restocking money is short.',
    detail:
        'Check stock-credit eligibility and review available charges and repayment terms.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Arrange delivery',
    title: 'They want delivery. You have nobody to send.',
    detail:
        'Arrange available delivery support without keeping your own dedicated rider.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Add products',
    title: 'No time to type thousands of products.',
    detail:
        'Choose existing products, then add your price and stock. Don’t enter the same details again.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Pack orders',
    title: 'A rush makes it easy to miss an item.',
    detail:
        'Keep the exact items, packs, quantities and collection or delivery action together.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Get tax help',
    title: 'Filing work takes time away from the shop.',
    detail:
        'Request bookkeeping, GST/ITR filing or audit support, with the scope and charges clear.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Post requirement',
    title: 'You need a job done, not a full-time hire.',
    detail:
        'Ask for a clear result in sourcing, content, promotion or another business task.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Review returns',
    title: 'The return changes both money and stock.',
    detail:
        'Keep returned goods, refunds and stock corrections linked to the original bill.',
  ),
];

const _tradeGrowth = <WorkWorkspaceBenefit>[
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Publish products',
    title: 'Buyers don’t know your full range.',
    detail:
        'Show available packs, quantities and trade terms to suitable retail buyers.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Send offers',
    title: 'The same calling list limits your orders.',
    detail: 'Make relevant trade offers available to more shops.',
  ),
  WorkWorkspaceBenefit(
    group: 'Customers',
    action: 'Send store link',
    title: 'Orders are scattered across messages.',
    detail: 'Give buyers a clear place to review products and place an order.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Restock',
    title: 'Your fast-moving lines are running short.',
    detail: 'Compare supply terms before replenishing the goods buyers need.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Track stock',
    title: 'Where is the supply you are waiting for?',
    detail: 'Follow the latest dispatch and expected-arrival information.',
  ),
  WorkWorkspaceBenefit(
    group: 'Stock',
    action: 'Receive goods',
    title: 'Shortages need a clear record.',
    detail:
        'Check quantities and condition against the purchase before acknowledging receipt.',
  ),
  WorkWorkspaceBenefit(
    group: 'Money',
    action: 'Collect dues',
    title: 'Retailer payments are overdue.',
    detail:
        'Follow each buyer’s outstanding bills and send the correct reminder.',
  ),
  WorkWorkspaceBenefit(
    group: 'Money',
    action: 'View statement',
    title: 'Trade invoices are hard to reconcile.',
    detail: 'Keep purchase, sale and payment records easy to trace.',
  ),
  WorkWorkspaceBenefit(
    group: 'Money',
    action: 'Settle',
    title: 'What is ready to reach the bank?',
    detail:
        'Review the available settlement amount before requesting transfer.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Pack orders',
    title: 'Wrong case quantities lead to disputes.',
    detail:
        'Keep the exact buyer order, packs and dispatch quantities together.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Get tax help',
    title: 'The books need attention too.',
    detail:
        'Request the bookkeeping, filing or audit support your business needs.',
  ),
  WorkWorkspaceBenefit(
    group: 'Daily work',
    action: 'Post requirement',
    title: 'You need a specific business result.',
    detail:
        'Request sourcing, content or trade-promotion assistance with clear terms.',
  ),
];

const workWorkspaceBenefits = <String, WorkWorkspaceBenefitContent>{
  'retailer-grocery': WorkWorkspaceBenefitContent(
    problem: 'Bring customers back. Keep shelves stocked. Collect what is due.',
    subtitle: 'Regular customers · Everyday essentials',
    preview:
        'Bring families back. Restock from your counter. Keep customer dues in sight.',
    benefits: _retailerGrowth,
    difference: 'Sell, restock and collect payments from the same Workspace.',
  ),
  'retailer-speciality': WorkWorkspaceBenefitContent(
    problem: 'Bring buyers back for the products you know best.',
    subtitle: 'Your products · More relevant buyers',
    preview:
        'Be found for what you stock. Turn enquiries into orders. Bring buyers back.',
    benefits: _retailerGrowth,
    difference: 'Keep specialist products, repeat buyers and stock together.',
  ),
  'wholesaler': WorkWorkspaceBenefitContent(
    problem: 'Reach more shops. Keep every trade order clear.',
    subtitle: 'Retail buyers · Trade orders · Dispatch',
    preview:
        'Reach more shops. Keep quantities, dispatch and buyer dues clear.',
    benefits: _tradeGrowth,
    difference: 'Keep buyer orders, dispatch and payment connected.',
  ),
  'manufacturer': WorkWorkspaceBenefitContent(
    problem: 'Connect your production with the retailers who need it.',
    subtitle: 'Direct offers · Retail buyers · Supply',
    preview:
        'Put your range in front of retailers. Follow orders, dispatch and payments.',
    benefits: _tradeGrowth,
    difference:
        'Connect your product range with retail demand and clear trade terms.',
  ),
  'restaurant': WorkWorkspaceBenefitContent(
    problem: 'Empty tables and an idle kitchen both cost money.',
    preview:
        'Fill tables, serve delivery and pickup orders, and keep menus, preparation and customer updates connected.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Use every part of your business',
        detail:
            'Serve table bookings, pickup, delivery and scheduled food orders from one restaurant presence.',
      ),
      WorkWorkspaceBenefit(
        title: 'Show the meal before the order',
        detail:
            'Keep menu, price, availability, preparation time and current offers clear.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep delivery connected',
        detail:
            'Link preparation, rider collection, customer updates and the completed order.',
      ),
      WorkWorkspaceBenefit(
        title: 'Bring diners back',
        detail:
            'Make repeat ordering, table booking, bills and support easier for satisfied customers.',
      ),
    ],
    difference:
        'Use one Workspace to fill tables, use kitchen capacity and serve customers outside the restaurant.',
  ),
  'cloud-kitchen': WorkWorkspaceBenefitContent(
    problem: 'One-time meal orders make tomorrow’s income uncertain.',
    preview:
        'Turn trial meals into weekly or monthly plans and manage cooking, delivery and regular customers together.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Build regular meal income',
        detail:
            'Offer trial, weekly and monthly plans instead of finding every customer again each day.',
      ),
      WorkWorkspaceBenefit(
        title: 'Serve the right meal plan',
        detail:
            'Offer lunch, dinner or combined plans with clear timing and price.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep changes manageable',
        detail:
            'Handle delivery address, meal timing and permitted plan pauses without loose messages.',
      ),
      WorkWorkspaceBenefit(
        title: 'Buy kitchen supplies smarter',
        detail:
            'Use business buying for ingredients, packaging and other regular operating needs.',
      ),
    ],
    difference:
        'Build regular meal income instead of starting from zero every morning.',
  ),
  'clinic': WorkWorkspaceBenefitContent(
    problem:
        'A patient relationship should not end when the patient leaves the clinic.',
    preview:
        'Help patients find the right care, keep appointments and reports connected, and make follow-up easier.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Help the right patient find you',
        detail:
            'Show specialty, availability, consultation fee and verified registration before booking.',
      ),
      WorkWorkspaceBenefit(
        title: 'Reduce uncertain waiting-room traffic',
        detail:
            'Receive clear appointments with the selected consultation type and patient details.',
      ),
      WorkWorkspaceBenefit(
        title: 'Receive reports with consent',
        detail:
            'Patients choose which reports are shared with the clinic for the appointment or follow-up.',
      ),
      WorkWorkspaceBenefit(
        title: 'Continue care after the visit',
        detail:
            'Offer secure follow-up invitations, reminders and rebooking with the same clinic.',
      ),
    ],
    difference:
        'MoolSocial connects discovery, appointment and follow-up—not only a one-time doctor listing.',
  ),
  'pharmacy': WorkWorkspaceBenefitContent(
    problem:
        'Medicine orders over calls can create prescription, stock and payment confusion.',
    preview:
        'Receive clearer medicine requests, review prescriptions before acceptance, and offer delivery or collection.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Be found as a licensed pharmacy',
        detail:
            'Appear to nearby customers searching for medicines and pharmacy help.',
      ),
      WorkWorkspaceBenefit(
        title: 'Review before accepting',
        detail:
            'Receive the medicine request and prescription before any payment is taken.',
      ),
      WorkWorkspaceBenefit(
        title: 'Answer pharmacist requests',
        detail:
            'Let customers ask for pharmacist assistance when the medicine choice needs review.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep the order traceable',
        detail:
            'Connect acceptance, delivery or collection, invoice and customer support.',
      ),
    ],
    difference:
        'Prescription review comes before payment, reducing confusion for both pharmacy and customer.',
  ),
  'salon': WorkWorkspaceBenefitContent(
    problem: 'An empty chair today cannot be sold again tomorrow.',
    preview:
        'Fill open appointments, show price and time before booking, and bring satisfied customers back.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Fill today’s open time',
        detail:
            'Show nearby customers your services, price, shop details and available appointments.',
      ),
      WorkWorkspaceBenefit(
        title: 'Reduce uncertain walk-ins',
        detail:
            'Use confirmed appointments with clear time, duration and cancellation terms.',
      ),
      WorkWorkspaceBenefit(
        title: 'Make every visit easier',
        detail:
            'Connect directions, rescheduling, arrival, payment and the completed visit.',
      ),
      WorkWorkspaceBenefit(
        title: 'Bring good customers back',
        detail:
            'Support ratings, repeat booking and suitable service packages after a successful visit.',
      ),
    ],
    difference:
        'MoolSocial helps fill today’s empty time and build tomorrow’s repeat customers.',
  ),
  'travel-bike-provider': WorkWorkspaceBenefitContent(
    problem: 'Waiting for random rides means losing earning hours.',
    preview:
        'See nearby trip demand, know the route and expected earning first, and keep safety and payouts connected.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'See demand near you',
        detail:
            'Review active demand areas and control when you are available for requests.',
      ),
      WorkWorkspaceBenefit(
        title: 'Know the trip before accepting',
        detail:
            'See pickup, destination, distance, fare and expected earning first.',
      ),
      WorkWorkspaceBenefit(
        title: 'Complete trips with proof',
        detail:
            'Use OTP-backed pickup, live route status and the final fare record.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep earnings visible',
        detail:
            'See trip charges, net earning, payout status and support against the exact trip.',
      ),
    ],
    difference:
        'You see the route and earning first—then decide whether the trip is right for you.',
  ),
  'travel-auto-provider': WorkWorkspaceBenefitContent(
    problem:
        'Long waiting at a stand reduces the number of trips you can complete.',
    preview:
        'See nearby passenger demand, review pickup and earnings before accepting, and track every completed trip.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Spend less time waiting',
        detail:
            'See nearby travel demand across the area where you choose to operate.',
      ),
      WorkWorkspaceBenefit(
        title: 'Review the route first',
        detail:
            'Know pickup distance, destination, trip time and expected earning before accepting.',
      ),
      WorkWorkspaceBenefit(
        title: 'Stay in control',
        detail:
            'Choose availability, use masked customer contact and open safety support when needed.',
      ),
      WorkWorkspaceBenefit(
        title: 'Follow your money',
        detail:
            'Track fare, platform charge, trip earning and payout status together.',
      ),
    ],
    difference:
        'Spend less time waiting for uncertain street demand and more time reviewing clear trip requests.',
  ),
  'travel-cab-provider': WorkWorkspaceBenefitContent(
    problem: 'Every idle cab hour is earning capacity that cannot return.',
    preview:
        'Reach immediate and scheduled passengers, know the route and fare first, and keep trip records and payouts together.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Use more of your working day',
        detail:
            'Receive suitable immediate and scheduled travel requests in your operating area.',
      ),
      WorkWorkspaceBenefit(
        title: 'See the complete trip first',
        detail:
            'Review pickup, destination, expected time, fare and earning before accepting.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep the cab ready',
        detail:
            'Maintain vehicle documents, service eligibility and operating alerts in one place.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep every earning traceable',
        detail:
            'Connect the completed trip with its charges, receipt, payout and support record.',
      ),
    ],
    difference:
        'Immediate and scheduled travel demand can reach the same verified cab Workspace.',
  ),
  'travel-bus-provider': WorkWorkspaceBenefitContent(
    problem: 'Every vacant seat leaves with the bus and cannot be sold again.',
    preview:
        'Make routes and available capacity easier to discover and turn scattered counter calls into organised traveller interest.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Make routes easier to find',
        detail:
            'Present route, timing and displayed passenger capacity to interested travellers.',
      ),
      WorkWorkspaceBenefit(
        title: 'Show clear booking information',
        detail:
            'Let travellers review displayed seats and fares before final live checkout.',
      ),
      WorkWorkspaceBenefit(
        title: 'Build operator trust',
        detail:
            'Keep fleet, permit, insurance and authorised-contact details ready for review.',
      ),
      WorkWorkspaceBenefit(
        title: 'Organise traveller interest',
        detail:
            'Reduce dependence on scattered counter and phone enquiries for route discovery.',
      ),
    ],
    difference:
        'Turn scattered counter and phone enquiries into an organised route presence for travellers.',
  ),
  'quick-delivery-biker': WorkWorkspaceBenefitContent(
    problem: 'Waiting without a delivery means waiting without earnings.',
    preview:
        'Find eligible shop, food and parcel work nearby, see route and payment first, and keep completed-work proof together.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Find more nearby work',
        detail:
            'Receive suitable delivery opportunities from participating local businesses.',
      ),
      WorkWorkspaceBenefit(
        title: 'Know the work first',
        detail:
            'Review the area, delivery requirement, payment rule and required proof before accepting.',
      ),
      WorkWorkspaceBenefit(
        title: 'Prove completed delivery',
        detail:
            'Use the required GPS, photo or handover record for the exact assignment.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep earnings and support connected',
        detail:
            'Track completed work, payment status and any support case in one record.',
      ),
    ],
    difference:
        'Receive delivery opportunities from participating businesses instead of depending on only one shop.',
  ),
  'wholesale-fleet-delivery': WorkWorkspaceBenefitContent(
    problem: 'Unused fleet capacity is lost business every day.',
    preview:
        'Show available vehicles to wholesale businesses and connect route, load, driver, receipt and payment proof.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Put available vehicles to work',
        detail:
            'Present suitable fleet capacity to participating retailers and wholesale businesses.',
      ),
      WorkWorkspaceBenefit(
        title: 'Review the movement first',
        detail:
            'See route, load, delivery window and payment terms before committing a vehicle.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep drivers and documents ready',
        detail:
            'Maintain vehicle, driver and operating-authority records for the fleet Workspace.',
      ),
      WorkWorkspaceBenefit(
        title: 'Link delivery with payment',
        detail:
            'Keep dispatch, transit, accepted receipt and shortage or damage records together.',
      ),
    ],
    difference:
        'Available fleet capacity becomes visible to suitable business demand instead of depending only on repeated calls.',
  ),
  'bulk-delivery-fleet': WorkWorkspaceBenefitContent(
    problem:
        'One unclear load, missing document or disputed receipt can delay the entire payment.',
    preview:
        'Review load, route and payment terms first, then connect factory pickup, transport documents and buyer receipt.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Know the load before dispatch',
        detail:
            'Review movement size, pickup, route, delivery timing and payment terms before commitment.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep every document with the movement',
        detail:
            'Connect order, invoice, transport documents, tracking and delivery receipt.',
      ),
      WorkWorkspaceBenefit(
        title: 'Show current movement status',
        detail:
            'Keep factory pickup, transit and buyer delivery visible against the exact movement.',
      ),
      WorkWorkspaceBenefit(
        title: 'Protect the final payment record',
        detail:
            'Tie accepted receipt, shortage, damage and claim evidence to payment review.',
      ),
    ],
    difference:
        'Every bulk movement carries its order, documents, tracking and receipt together.',
  ),
  'creator': WorkWorkspaceBenefitContent(
    problem: 'Views alone do not pay your bills.',
    preview:
        'Find campaigns with clear work and payment, connect content to one customer action, and track approved earnings.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Know the campaign before creating',
        detail:
            'See the business, content format, deadline, fixed pay and result-linked pay first.',
      ),
      WorkWorkspaceBenefit(
        title: 'Give content a useful next step',
        detail:
            'Connect a post to Buy, Book, Order, Apply, Visit or Chat—not only likes and views.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep rights and disclosure clear',
        detail:
            'Manage paid-partnership wording, content rights and the agreed live period.',
      ),
      WorkWorkspaceBenefit(
        title: 'See what became payable',
        detail:
            'Track approved content, completed customer actions, earnings and payout records.',
      ),
    ],
    difference:
        'Content is connected to a real customer action and visible earning record—not only likes and views.',
  ),
  'freelancer': WorkWorkspaceBenefitContent(
    problem: 'Vague work and hidden payment waste your time.',
    preview:
        'See the skill, work, location and payment before applying, then build trusted history through completed assignments.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'See the complete work first',
        detail:
            'Know the required skill, work, location, deadline and payment before applying.',
      ),
      WorkWorkspaceBenefit(
        title: 'Never pay to apply',
        detail:
            'MoolSocial does not charge you to apply for or begin a funded opportunity.',
      ),
      WorkWorkspaceBenefit(
        title: 'Find work near you',
        detail: 'Search suitable assignments by city, area and PIN code.',
      ),
      WorkWorkspaceBenefit(
        title: 'Build trusted work history',
        detail:
            'Keep applications, completion proof, earnings and support connected to the exact assignment.',
      ),
    ],
    difference:
        'The work, payment and proof are shown before you commit—not after the work is finished.',
  ),
};
