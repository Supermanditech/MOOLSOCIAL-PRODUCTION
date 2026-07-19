import 'package:flutter/material.dart';

class IntentOption {
  const IntentOption(this.label, this.detail);

  final String label;
  final String detail;
}

class UniversalIntentSpec {
  const UniversalIntentSpec({
    required this.section,
    required this.id,
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.facts,
    required this.primaryAction,
    required this.choicePrompt,
    required this.options,
    required this.confirmAction,
    required this.resultTitle,
    required this.resultDescription,
  });

  final String section;
  final String id;
  final String label;
  final String title;
  final String description;
  final IconData icon;
  final List<String> facts;
  final String primaryAction;
  final String choicePrompt;
  final List<IntentOption> options;
  final String confirmAction;
  final String resultTitle;
  final String resultDescription;
}

abstract final class UniversalIntentCatalog {
  static const bySection = <String, List<UniversalIntentSpec>>{
    'buy': [
      UniversalIntentSpec(
        section: 'buy',
        id: 'grocery',
        label: 'Grocery',
        title: 'Groceries delivered to your home',
        description:
            'Choose everyday products with a clear price, quantity, seller and '
            'delivery promise.',
        icon: Icons.local_grocery_store_outlined,
        facts: ['Retail quantities', 'Home delivery', 'Refund terms shown'],
        primaryAction: 'Choose groceries',
        choicePrompt: 'What do you need today?',
        options: [
          IntentOption('Fresh produce', 'Vegetables and fruit available today'),
          IntentOption(
            'Daily staples',
            'Flour, rice, oil and household basics',
          ),
          IntentOption('Milk and dairy', 'Chilled products with delivery time'),
        ],
        confirmAction: 'Add to basket',
        resultTitle: 'Added to your basket',
        resultDescription:
            'The selected item is ready in Basket with its quantity, seller '
            'and delivery promise.',
      ),
      UniversalIntentSpec(
        section: 'buy',
        id: 'categories',
        label: 'Categories',
        title: 'Find products by category',
        description:
            'Move from a useful category to a product without mixing consumer '
            'buying with wholesale campaigns.',
        icon: Icons.grid_view_rounded,
        facts: ['Consumer products', 'Final price shown', 'Delivery available'],
        primaryAction: 'Browse categories',
        choicePrompt: 'Choose a category',
        options: [
          IntentOption('Home care', 'Cleaning and household supplies'),
          IntentOption('Personal care', 'Daily hygiene and wellness products'),
          IntentOption('Electronics', 'Verified local products and support'),
        ],
        confirmAction: 'See products',
        resultTitle: 'Products are ready to choose',
        resultDescription:
            'The selected category now shows retail products available for '
            'home delivery.',
      ),
      UniversalIntentSpec(
        section: 'buy',
        id: 'medicine',
        label: 'Medicine',
        title: 'Find medicine safely',
        description:
            'Search available medicine and provide a prescription only when it '
            'is legally required.',
        icon: Icons.medication_outlined,
        facts: ['Licensed pharmacy', 'Prescription check', 'Delivery terms'],
        primaryAction: 'Find medicine',
        choicePrompt: 'How would you like to continue?',
        options: [
          IntentOption('Search by name', 'Find an eligible medicine'),
          IntentOption('Upload prescription', 'Ask a pharmacy to review it'),
          IntentOption('Ask a pharmacist', 'Get help before choosing'),
        ],
        confirmAction: 'Continue safely',
        resultTitle: 'Your pharmacy request is ready',
        resultDescription:
            'The next pharmacy step will show availability, price and any '
            'required prescription review before an order.',
      ),
      UniversalIntentSpec(
        section: 'buy',
        id: 'basket',
        label: 'Basket',
        title: 'Review your household basket',
        description:
            'Check quantity, final price, delivery address and refund terms '
            'before you pay.',
        icon: Icons.shopping_basket_outlined,
        facts: ['Final total', 'Delivery address', 'Refund terms'],
        primaryAction: 'Review basket',
        choicePrompt: 'Choose delivery',
        options: [
          IntentOption('Deliver to home', 'Use your saved home address'),
          IntentOption('Choose another address', 'Add or select an address'),
          IntentOption('Pick up from a store', 'Choose a store before pickup'),
        ],
        confirmAction: 'Continue to payment',
        resultTitle: 'Basket is ready for payment',
        resultDescription:
            'Your items, delivery choice and final total are ready for secure '
            'payment confirmation.',
      ),
    ],
    'eat': [
      UniversalIntentSpec(
        section: 'eat',
        id: 'order-food',
        label: 'Order Food',
        title: 'Order food for delivery',
        description:
            'Choose a restaurant or dish with price, preparation time and '
            'cancellation terms shown first.',
        icon: Icons.restaurant_outlined,
        facts: ['Menu price', 'Delivery time', 'Cancellation terms'],
        primaryAction: 'Choose food',
        choicePrompt: 'What would you like?',
        options: [
          IntentOption('Meals near you', 'Restaurants delivering now'),
          IntentOption('Quick bites', 'Faster preparation options'),
          IntentOption('Family meals', 'Shareable meal combinations'),
        ],
        confirmAction: 'Add to food basket',
        resultTitle: 'Added to your food basket',
        resultDescription:
            'The selected meal is ready with its price and delivery estimate.',
      ),
      UniversalIntentSpec(
        section: 'eat',
        id: 'book-table',
        label: 'Book Table',
        title: 'Reserve a table',
        description:
            'Choose a restaurant, time and guest count with cancellation terms '
            'visible before confirmation.',
        icon: Icons.table_restaurant_outlined,
        facts: ['Available time', 'Guest count', 'Cancellation terms'],
        primaryAction: 'Find a table',
        choicePrompt: 'Choose a dining time',
        options: [
          IntentOption('Lunch', '12:00 pm to 3:00 pm'),
          IntentOption('Early dinner', '6:00 pm to 8:00 pm'),
          IntentOption('Dinner', '8:00 pm to 11:00 pm'),
        ],
        confirmAction: 'Review reservation',
        resultTitle: 'Reservation details are ready',
        resultDescription:
            'Choose a restaurant and guest count to confirm this dining time.',
      ),
      UniversalIntentSpec(
        section: 'eat',
        id: 'tiffin',
        label: 'Tiffin',
        title: 'Choose a regular meal plan',
        description:
            'Compare meal days, menu, delivery time and pause rules before '
            'starting a plan.',
        icon: Icons.lunch_dining_outlined,
        facts: ['Meal schedule', 'Home delivery', 'Pause anytime'],
        primaryAction: 'Choose a meal plan',
        choicePrompt: 'Choose a plan',
        options: [
          IntentOption('Weekday lunch', 'Lunch from Monday to Friday'),
          IntentOption('Daily dinner', 'Dinner delivered every day'),
          IntentOption('Lunch and dinner', 'Two meals on selected days'),
        ],
        confirmAction: 'Review meal plan',
        resultTitle: 'Meal plan is ready to review',
        resultDescription:
            'Your selected schedule is ready with menu, address and final '
            'price before payment.',
      ),
    ],
    'ride': [
      UniversalIntentSpec(
        section: 'ride',
        id: 'bike',
        label: 'Bike',
        title: 'Book a bike ride',
        description:
            'Set pickup and destination, then review arrival time, fare and '
            'cancellation terms.',
        icon: Icons.two_wheeler_rounded,
        facts: ['Pickup shown', 'Fare estimate', 'Cancellation terms'],
        primaryAction: 'Set bike ride',
        choicePrompt: 'Choose pickup',
        options: [
          IntentOption('Use current location', 'Pickup where you are now'),
          IntentOption('Choose on map', 'Move the pickup pin'),
          IntentOption('Enter pickup', 'Search an address or landmark'),
        ],
        confirmAction: 'Add destination',
        resultTitle: 'Pickup is ready',
        resultDescription:
            'Add your destination to see the live bike fare and arrival time.',
      ),
      UniversalIntentSpec(
        section: 'ride',
        id: 'auto',
        label: 'Auto',
        title: 'Book an auto ride',
        description:
            'Review pickup, destination, fare estimate and cancellation terms '
            'before requesting a driver.',
        icon: Icons.electric_rickshaw_outlined,
        facts: ['Nearby autos', 'Fare estimate', 'Driver details'],
        primaryAction: 'Set auto ride',
        choicePrompt: 'Choose pickup',
        options: [
          IntentOption('Use current location', 'Pickup where you are now'),
          IntentOption('Choose on map', 'Move the pickup pin'),
          IntentOption('Enter pickup', 'Search an address or landmark'),
        ],
        confirmAction: 'Add destination',
        resultTitle: 'Pickup is ready',
        resultDescription:
            'Add your destination to see available autos and the live fare.',
      ),
      UniversalIntentSpec(
        section: 'ride',
        id: 'cab',
        label: 'Cab',
        title: 'Book a cab',
        description:
            'Choose a cab type after reviewing pickup, arrival time, fare and '
            'cancellation terms.',
        icon: Icons.local_taxi_outlined,
        facts: ['Cab choices', 'Fare estimate', 'Safety details'],
        primaryAction: 'Set cab ride',
        choicePrompt: 'Choose pickup',
        options: [
          IntentOption('Use current location', 'Pickup where you are now'),
          IntentOption('Choose on map', 'Move the pickup pin'),
          IntentOption('Enter pickup', 'Search an address or landmark'),
        ],
        confirmAction: 'Add destination',
        resultTitle: 'Pickup is ready',
        resultDescription:
            'Add your destination to compare available cabs and live fares.',
      ),
    ],
    'book': [
      UniversalIntentSpec(
        section: 'book',
        id: 'get-done',
        label: 'Get It Done',
        title: 'Book a task with clear terms',
        description:
            'Choose a task with scope, price, timing, completion check and '
            'support shown before booking.',
        icon: Icons.task_alt_rounded,
        facts: ['Defined scope', 'Price and time', 'Completion check'],
        primaryAction: 'Choose a task',
        choicePrompt: 'What should be completed?',
        options: [
          IntentOption('Pickup and delivery', 'Move an item locally'),
          IntentOption('Print or scan documents', 'Prepare and deliver papers'),
          IntentOption('Appointment help', 'Book or collect a service token'),
        ],
        confirmAction: 'Review task',
        resultTitle: 'Task details are ready',
        resultDescription:
            'Add address and preferred time to see the final price before '
            'booking.',
      ),
      UniversalIntentSpec(
        section: 'book',
        id: 'doctor',
        label: 'Doctor',
        title: 'Book a doctor appointment',
        description:
            'Choose a verified doctor and available time with fee and '
            'cancellation terms shown first.',
        icon: Icons.medical_services_outlined,
        facts: ['Verified clinic', 'Available time', 'Fee shown'],
        primaryAction: 'Find a doctor',
        choicePrompt: 'How would you like to search?',
        options: [
          IntentOption('By specialty', 'Choose the care you need'),
          IntentOption('Nearby doctors', 'See clinics near your area'),
          IntentOption('Available today', 'Find the earliest appointment'),
        ],
        confirmAction: 'See appointments',
        resultTitle: 'Appointments are ready to choose',
        resultDescription:
            'Select a doctor and time to review the fee before confirmation.',
      ),
      UniversalIntentSpec(
        section: 'book',
        id: 'salon',
        label: 'Salon',
        title: 'Book a salon service',
        description:
            'Choose a service, professional and time with the final price and '
            'cancellation terms shown.',
        icon: Icons.content_cut_rounded,
        facts: ['Service menu', 'Final price', 'Available time'],
        primaryAction: 'Choose a service',
        choicePrompt: 'What would you like to book?',
        options: [
          IntentOption('Hair service', 'Cut, styling and treatment'),
          IntentOption('Beauty service', 'Salon and care services'),
          IntentOption('Home service', 'Available professionals who travel'),
        ],
        confirmAction: 'See available times',
        resultTitle: 'Available times are ready',
        resultDescription:
            'Choose a professional and time to review the final price.',
      ),
    ],
    'pay': [
      UniversalIntentSpec(
        section: 'pay',
        id: 'recharge',
        label: 'Recharge',
        title: 'Recharge a supported service',
        description:
            'Choose a supported operator and plan, confirm the number, then '
            'pay securely.',
        icon: Icons.phone_android_rounded,
        facts: ['Operator checked', 'Plan details', 'Receipt saved'],
        primaryAction: 'Start recharge',
        choicePrompt: 'Choose a recharge type',
        options: [
          IntentOption('Mobile', 'Prepaid mobile recharge'),
          IntentOption('DTH', 'Supported television accounts'),
          IntentOption('FASTag', 'Supported vehicle accounts'),
        ],
        confirmAction: 'Enter account details',
        resultTitle: 'Recharge details are ready',
        resultDescription:
            'Enter the number and choose a plan before secure payment.',
      ),
      UniversalIntentSpec(
        section: 'pay',
        id: 'bills',
        label: 'Bills',
        title: 'Fetch and pay a bill',
        description:
            'Choose a supported biller, fetch the exact amount and keep the '
            'receipt after payment.',
        icon: Icons.receipt_long_outlined,
        facts: ['Bill fetched', 'Amount confirmed', 'Receipt saved'],
        primaryAction: 'Choose a biller',
        choicePrompt: 'Choose a bill type',
        options: [
          IntentOption('Electricity', 'Supported electricity providers'),
          IntentOption('Water', 'Supported water providers'),
          IntentOption('Gas', 'Supported gas providers'),
        ],
        confirmAction: 'Enter bill details',
        resultTitle: 'Bill details are ready',
        resultDescription:
            'Enter the consumer number to fetch the current bill before '
            'payment.',
      ),
      UniversalIntentSpec(
        section: 'pay',
        id: 'scan-pay',
        label: 'Scan & Pay',
        title: 'Pay a verified recipient',
        description:
            'Scan or enter a supported payment code, confirm the recipient and '
            'amount, then authenticate.',
        icon: Icons.qr_code_scanner_rounded,
        facts: ['Recipient confirmed', 'Amount reviewed', 'Receipt saved'],
        primaryAction: 'Open payment scanner',
        choicePrompt: 'How would you like to continue?',
        options: [
          IntentOption(
            'Scan with camera',
            'Point the camera at a payment code',
          ),
          IntentOption('Choose an image', 'Use a saved payment code'),
          IntentOption('Enter payment ID', 'Type a supported payment address'),
        ],
        confirmAction: 'Continue',
        resultTitle: 'Ready to confirm the recipient',
        resultDescription:
            'Verify the recipient and amount before authenticating payment.',
      ),
      UniversalIntentSpec(
        section: 'pay',
        id: 'receipts',
        label: 'Receipts',
        title: 'Find payment and order receipts',
        description:
            'Open a receipt, view its status and get payment support without '
            'leaving MoolSocial.',
        icon: Icons.receipt_outlined,
        facts: ['Payment status', 'Order reference', 'Get help'],
        primaryAction: 'Find a receipt',
        choicePrompt: 'Choose a receipt type',
        options: [
          IntentOption('Payments', 'QR and account payments'),
          IntentOption('Orders', 'Product and food orders'),
          IntentOption('Bookings', 'Rides, services and appointments'),
        ],
        confirmAction: 'See receipts',
        resultTitle: 'Receipts are ready',
        resultDescription:
            'Choose a receipt to view, share, download or get help.',
      ),
    ],
    'work': [
      UniversalIntentSpec(
        section: 'work',
        id: 'earn-today',
        label: 'Earn Today',
        title: 'Choose funded work',
        description:
            'See the task, location, completion evidence, payout and review '
            'time before applying.',
        icon: Icons.currency_rupee_rounded,
        facts: ['Funded', 'Payout shown', 'Review time'],
        primaryAction: 'Find work',
        choicePrompt: 'Choose work near you',
        options: [
          IntentOption('Local tasks', 'Work available in your area'),
          IntentOption('Remote tasks', 'Complete eligible work online'),
          IntentOption('Short assignments', 'Tasks designed for today'),
        ],
        confirmAction: 'Check eligibility',
        resultTitle: 'Eligibility check is ready',
        resultDescription:
            'Review the requirements and payout before you apply.',
      ),
      UniversalIntentSpec(
        section: 'work',
        id: 'delivery',
        label: 'Delivery',
        title: 'Choose a funded delivery route',
        description:
            'Review stops, distance, completion evidence, payout and '
            'settlement timing before accepting.',
        icon: Icons.delivery_dining_outlined,
        facts: ['Route shown', 'Payout shown', 'Settlement time'],
        primaryAction: 'Find delivery work',
        choicePrompt: 'Choose a route type',
        options: [
          IntentOption('Food delivery', 'Restaurant delivery routes'),
          IntentOption('Local products', 'Shop and household routes'),
          IntentOption('Documents', 'Defined pickup and delivery tasks'),
        ],
        confirmAction: 'Review route',
        resultTitle: 'Route details are ready',
        resultDescription:
            'Review every stop, required evidence and payout before accepting.',
      ),
      UniversalIntentSpec(
        section: 'work',
        id: 'onboard',
        label: 'Onboard',
        title: 'Help verified businesses join',
        description:
            'Choose a funded onboarding assignment with target, required '
            'evidence and payout shown.',
        icon: Icons.storefront_outlined,
        facts: ['Business verified', 'Target shown', 'Payout shown'],
        primaryAction: 'Find onboarding work',
        choicePrompt: 'Choose a business type',
        options: [
          IntentOption('Retail shops', 'Help an eligible shop get started'),
          IntentOption('Restaurants', 'Help a food business get started'),
          IntentOption('Service providers', 'Help an eligible provider join'),
        ],
        confirmAction: 'Check assignment',
        resultTitle: 'Assignment details are ready',
        resultDescription:
            'Review the business, required evidence and payout before applying.',
      ),
      UniversalIntentSpec(
        section: 'work',
        id: 'verify',
        label: 'Verify',
        title: 'Complete funded verification work',
        description:
            'Choose only funded checks with location, evidence requirement, '
            'payout and review time shown.',
        icon: Icons.fact_check_outlined,
        facts: ['Funded check', 'Evidence shown', 'Payout shown'],
        primaryAction: 'Find verification work',
        choicePrompt: 'Choose a verification type',
        options: [
          IntentOption('Price check', 'Confirm a visible local price'),
          IntentOption('Shop check', 'Confirm an eligible shop status'),
          IntentOption('Service check', 'Confirm readiness where requested'),
        ],
        confirmAction: 'Review requirements',
        resultTitle: 'Requirements are ready',
        resultDescription:
            'Review the exact evidence and payout before applying.',
      ),
      UniversalIntentSpec(
        section: 'work',
        id: 'workspace',
        label: 'Workspace',
        title: 'Add your professional workspace',
        description:
            'Create a workspace for eligible business, creator, captain or '
            'professional activity and submit it for verification.',
        icon: Icons.workspaces_outline,
        facts: ['Keep consumer access', 'Add business tools', 'Verify once'],
        primaryAction: 'Choose workspace',
        choicePrompt: 'What do you want to add?',
        options: [
          IntentOption('Business', 'Retailer, restaurant, salon or supplier'),
          IntentOption('Professional', 'Doctor, service provider or captain'),
          IntentOption('Creator', 'Creator identity and connected content'),
        ],
        confirmAction: 'Enter workspace details',
        resultTitle: 'Workspace form is ready',
        resultDescription:
            'Enter verified details and submit when every required field is '
            'complete.',
      ),
    ],
    'chat': [
      UniversalIntentSpec(
        section: 'chat',
        id: 'people',
        label: 'People',
        title: 'Message people you know',
        description:
            'Open a conversation, send a message or attachment and keep the '
            'delivery state visible.',
        icon: Icons.people_outline_rounded,
        facts: ['Delivered state', 'Attachments', 'Retry failed send'],
        primaryAction: 'Choose a conversation',
        choicePrompt: 'Who would you like to message?',
        options: [
          IntentOption('Recent conversations', 'Continue a recent chat'),
          IntentOption('Search people', 'Find someone by name'),
          IntentOption('Create a group', 'Start a group conversation'),
        ],
        confirmAction: 'Open conversation',
        resultTitle: 'Conversation is ready',
        resultDescription:
            'Write a message, attach a file or record a voice message.',
      ),
      UniversalIntentSpec(
        section: 'chat',
        id: 'business-chat',
        label: 'Business',
        title: 'Message a business',
        description:
            'Keep product, booking and service questions connected to the '
            'business that can resolve them.',
        icon: Icons.store_mall_directory_outlined,
        facts: ['Verified business', 'Linked action', 'Support available'],
        primaryAction: 'Choose a business',
        choicePrompt: 'Choose a conversation',
        options: [
          IntentOption('Shops', 'Product and delivery questions'),
          IntentOption('Services', 'Appointment and service questions'),
          IntentOption('Food', 'Restaurant and meal questions'),
        ],
        confirmAction: 'Open business chat',
        resultTitle: 'Business chat is ready',
        resultDescription:
            'Send a message or open the linked order, booking or service.',
      ),
      UniversalIntentSpec(
        section: 'chat',
        id: 'orders',
        label: 'Orders',
        title: 'Message about an order',
        description:
            'Choose the order first so the business and support team have the '
            'right payment and delivery context.',
        icon: Icons.shopping_bag_outlined,
        facts: ['Order linked', 'Status visible', 'Support available'],
        primaryAction: 'Choose an order',
        choicePrompt: 'Which order needs attention?',
        options: [
          IntentOption('Product orders', 'Buying and delivery conversations'),
          IntentOption('Food orders', 'Restaurant and delivery conversations'),
          IntentOption('Bookings', 'Ride, appointment and service chats'),
        ],
        confirmAction: 'Open order chat',
        resultTitle: 'Order chat is ready',
        resultDescription:
            'Ask a question, share required information or open support.',
      ),
      UniversalIntentSpec(
        section: 'chat',
        id: 'support',
        label: 'Support',
        title: 'Get help with a completed action',
        description:
            'Choose the affected payment, order, booking or account issue and '
            'keep its case status visible.',
        icon: Icons.support_agent_rounded,
        facts: ['Case reference', 'Status updates', 'Conversation history'],
        primaryAction: 'Choose an issue',
        choicePrompt: 'What do you need help with?',
        options: [
          IntentOption('Payment', 'Payment, refund or receipt issue'),
          IntentOption('Order or booking', 'Product, food or service issue'),
          IntentOption('Account', 'Sign-in, profile or workspace issue'),
        ],
        confirmAction: 'Start support request',
        resultTitle: 'Support request is ready',
        resultDescription:
            'Choose the affected transaction and describe what happened.',
      ),
    ],
  };

  static List<UniversalIntentSpec> forSection(String section) {
    return bySection[section] ?? const [];
  }

  static UniversalIntentSpec selected(String section, String? id) {
    final values = forSection(section);
    assert(values.isNotEmpty, 'Unknown Universal section: $section');
    return values.firstWhere(
      (value) => value.id == id,
      orElse: () => values.first,
    );
  }

  static Map<String, String> initialSelection() {
    return {
      for (final entry in bySection.entries) entry.key: entry.value.first.id,
    };
  }
}
