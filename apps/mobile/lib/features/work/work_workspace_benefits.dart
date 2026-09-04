class WorkWorkspaceBenefit {
  const WorkWorkspaceBenefit({required this.title, required this.detail});

  final String title;
  final String detail;
}

class WorkWorkspaceBenefitContent {
  const WorkWorkspaceBenefitContent({
    required this.problem,
    required this.preview,
    required this.benefits,
    required this.difference,
  });

  final String problem;
  final String preview;
  final List<WorkWorkspaceBenefit> benefits;
  final String difference;
}

WorkWorkspaceBenefitContent workWorkspaceBenefitFor(String profileId) {
  final content = workWorkspaceBenefits[profileId];
  if (content == null) {
    throw StateError('Workspace benefit content is missing for $profileId.');
  }
  return content;
}

const workWorkspaceBenefits = <String, WorkWorkspaceBenefitContent>{
  'retailer-grocery': WorkWorkspaceBenefitContent(
    problem:
        'A customer who forgets your shop becomes someone else’s customer.',
    preview:
        'Bring families back for regular baskets, deliver without maintaining a full-time rider and restock with better visibility.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Bring customers back',
        detail:
            'Share permitted offers, festival savings and back-in-stock news with customers who already know your shop.',
      ),
      WorkWorkspaceBenefit(
        title: 'Deliver without a salary burden',
        detail:
            'Request delivery support after packing an order and follow the displayed completed-delivery terms.',
      ),
      WorkWorkspaceBenefit(
        title: 'Buy stock with your eyes open',
        detail:
            'Compare case price, minimum order, delivery date and payment terms before restocking.',
      ),
      WorkWorkspaceBenefit(
        title: 'Know where your money is',
        detail:
            'Keep counter sales, online orders, payments and customer dues—udhaar—visible together.',
      ),
    ],
    difference:
        'Not only an online shop listing—MoolSocial helps you sell, deliver, restock and bring customers back.',
  ),
  'retailer-speciality': WorkWorkspaceBenefitContent(
    problem:
        'Good products remain unsold when nearby customers do not know you keep them.',
    preview:
        'Be found for your exact product category, explain what makes it valuable and manage stock, pickup and delivery together.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Be found for the right product',
        detail:
            'Reach nearby customers searching for the exact category and specialist products you sell.',
      ),
      WorkWorkspaceBenefit(
        title: 'Show why your product is different',
        detail:
            'Present clear product details, price and availability before the customer visits or orders.',
      ),
      WorkWorkspaceBenefit(
        title: 'Promote selected stock',
        detail:
            'Use permitted offers and suitable creator campaigns to highlight products that need attention.',
      ),
      WorkWorkspaceBenefit(
        title: 'Serve beyond the counter',
        detail:
            'Offer collection or delivery while keeping the product and order record connected.',
      ),
    ],
    difference:
        'Your specialist knowledge and products are presented clearly instead of being buried inside a generic marketplace.',
  ),
  'wholesaler': WorkWorkspaceBenefitContent(
    problem:
        'Phone orders and loose messages create quantity, price and payment disputes.',
    preview:
        'Reach verified retailers, show case price and minimum order first, then keep dispatch, receipt and payment connected.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'Reach more retailer counters',
        detail:
            'Present available stock to suitable retailers beyond your existing calling list.',
      ),
      WorkWorkspaceBenefit(
        title: 'Reduce order confusion',
        detail:
            'Keep quantity, case size, buyer price, delivery and payment terms visible before confirmation.',
      ),
      WorkWorkspaceBenefit(
        title: 'Keep dispatch clear',
        detail:
            'Connect the buyer order with dispatch, accepted goods and shortage or damage records.',
      ),
      WorkWorkspaceBenefit(
        title: 'Strengthen your own supply',
        detail:
            'Find manufacturers and compare product, delivery and payment terms for your godown.',
      ),
    ],
    difference:
        'Move from scattered calls and notebooks to clear trade orders that both buyer and seller can follow.',
  ),
  'manufacturer': WorkWorkspaceBenefitContent(
    problem:
        'Production without confirmed demand locks money inside unsold stock.',
    preview:
        'See buyer demand, reach beyond your dealer network and connect sales orders, dispatch and payment release.',
    benefits: [
      WorkWorkspaceBenefit(
        title: 'See demand before producing',
        detail:
            'Review product demand by buyer group and location before committing more stock.',
      ),
      WorkWorkspaceBenefit(
        title: 'Reach buyers beyond your network',
        detail:
            'Show stock, minimum quantity and buyer price to suitable retailers, distributors and institutions.',
      ),
      WorkWorkspaceBenefit(
        title: 'Dispatch against clear terms',
        detail:
            'Keep quantity, invoice, transport, buyer receipt and payment release tied to the sales order.',
      ),
      WorkWorkspaceBenefit(
        title: 'Source production inputs',
        detail:
            'Compare raw material and packaging offers before placing a protected purchase order.',
      ),
    ],
    difference:
        'MoolSocial connects demand, production, selling, transport and payment—not only another product listing.',
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
