import 'package:flutter/material.dart';

import '../../features/buy/buy_v2_session.dart';
import '../buy/buy_v2_shop_chat.dart';

abstract interface class MoolContextualChatProvisioningSource {
  List<BuyV2ShopChatThread> threadsFor(String familyId);
}

class MoolDefaultContextualChatProvisioningSource
    implements MoolContextualChatProvisioningSource {
  const MoolDefaultContextualChatProvisioningSource();

  @override
  List<BuyV2ShopChatThread> threadsFor(String familyId) => switch (familyId) {
    'eat' => _foodThreads,
    'ride' => _travelThreads,
    'book' => _careThreads,
    'work' => _workThreads,
    _ => const [],
  };
}

class MoolContextualChatSourceAdapter
    implements BuyV2ShopChatProvisioningSource {
  const MoolContextualChatSourceAdapter({
    required this.familyId,
    required this.source,
  });

  final String familyId;
  final MoolContextualChatProvisioningSource source;

  @override
  List<BuyV2ShopChatThread> threads(BuyV2Session? _) =>
      source.threadsFor(familyId);
}

abstract final class MoolContextualChatCatalog {
  static bool supports(String familyId) =>
      const {'eat', 'ride', 'book', 'work'}.contains(familyId);

  static BuyV2ShopChatPresentation presentationFor(String familyId) =>
      switch (familyId) {
        'eat' => food,
        'ride' => travel,
        'book' => care,
        'work' => work,
        _ => BuyV2ShopChatPresentation.shop,
      };

  static String initialFilterFor(String familyId, String subActionId) {
    final presentation = presentationFor(familyId);
    return presentation.filters.any((filter) => filter.id == subActionId)
        ? subActionId
        : 'all';
  }

  static const food = BuyV2ShopChatPresentation(
    familyId: 'eat',
    familyLabel: 'Food',
    title: 'Food Chat',
    subtitle: 'orders and reservations',
    icon: Icons.restaurant_outlined,
    accent: Color(0xFFF27A1A),
    securityMessage:
        'Food conversations stay with your order or reservation in MoolSocial Chat.',
    newConversationPrompt:
        'Choose who can help with your order or reservation.',
    filters: [
      BuyV2ShopChatFilterSpec(
        id: 'all',
        label: 'All',
        sectionLabel: 'Start with Food',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'order-food',
        label: 'Order Food',
        sectionLabel: 'Food order conversations',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'book-table',
        label: 'Book Table',
        sectionLabel: 'Table reservation conversations',
      ),
    ],
  );

  static const travel = BuyV2ShopChatPresentation(
    familyId: 'ride',
    familyLabel: 'Travel',
    title: 'Travel Chat',
    subtitle: 'rides and bookings',
    icon: Icons.route_outlined,
    accent: Color(0xFF34345E),
    securityMessage:
        'Travel conversations stay with your trip in MoolSocial Chat.',
    newConversationPrompt: 'Choose the trip you need help with.',
    filters: [
      BuyV2ShopChatFilterSpec(
        id: 'all',
        label: 'All',
        sectionLabel: 'Start with Travel',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'bike',
        label: 'Bike',
        sectionLabel: 'Bike conversations',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'auto',
        label: 'Auto',
        sectionLabel: 'Auto conversations',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'cab',
        label: 'Cab',
        sectionLabel: 'Cab conversations',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'bus',
        label: 'Bus',
        sectionLabel: 'Bus booking conversations',
      ),
    ],
  );

  static const care = BuyV2ShopChatPresentation(
    familyId: 'book',
    familyLabel: 'Care',
    title: 'Care Chat',
    subtitle: 'appointments and services',
    icon: Icons.health_and_safety_outlined,
    accent: Color(0xFF00757B),
    securityMessage:
        'Care Chat supports booking and coordination, not emergency or medical advice.',
    newConversationPrompt: 'Choose the Care service you need help with.',
    filters: [
      BuyV2ShopChatFilterSpec(
        id: 'all',
        label: 'All',
        sectionLabel: 'Start with Care',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'doctor',
        label: 'Doctor',
        sectionLabel: 'Doctor booking conversations',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'medicine',
        label: 'Medicine',
        sectionLabel: 'Medicine order conversations',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'salon',
        label: 'Salon',
        sectionLabel: 'Salon booking conversations',
      ),
    ],
  );

  static const work = BuyV2ShopChatPresentation(
    familyId: 'work',
    familyLabel: 'Work',
    title: 'Work Chat',
    subtitle: 'jobs and workspace',
    icon: Icons.work_outline_rounded,
    accent: Color(0xFF2F7A28),
    securityMessage:
        'Work conversations stay with your opportunity or workspace in MoolSocial Chat.',
    newConversationPrompt: 'Choose the Work conversation you need.',
    filters: [
      BuyV2ShopChatFilterSpec(
        id: 'all',
        label: 'All',
        sectionLabel: 'Start with Work',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'earn-today',
        label: 'Earn Today',
        sectionLabel: 'Opportunity conversations',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'workspace',
        label: 'Workspace',
        sectionLabel: 'Workspace conversations',
      ),
    ],
  );
}

const _foodThreads = <BuyV2ShopChatThread>[
  BuyV2ShopChatThread(
    id: 'food-order-support',
    filter: BuyV2ShopChatFilter.orders,
    filterId: 'order-food',
    participantKind: BuyV2ShopChatParticipantKind.restaurant,
    title: 'Food order support',
    subtitle: 'Restaurants, menus and delivery questions',
    detail: 'Start an Order Food conversation',
    icon: Icons.restaurant_outlined,
    accent: Color(0xFFF27A1A),
    contextTitle: 'Order Food',
    contextDetail: 'Restaurant, item, price and delivery context',
    quickReplies: ['Ask about this item', 'Check delivery time'],
  ),
  BuyV2ShopChatThread(
    id: 'food-table-desk',
    filter: BuyV2ShopChatFilter.sellers,
    filterId: 'book-table',
    participantKind: BuyV2ShopChatParticipantKind.tableDesk,
    title: 'Table reservation desk',
    subtitle: 'Restaurant, time and party-size questions',
    detail: 'Start a Book Table conversation',
    icon: Icons.table_restaurant_outlined,
    accent: Color(0xFF7A3E12),
    contextTitle: 'Book Table',
    contextDetail: 'Restaurant, date, time and party-size context',
    quickReplies: ['Check this time', 'Ask about seating'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  ),
];

const _travelThreads = <BuyV2ShopChatThread>[
  BuyV2ShopChatThread(
    id: 'travel-bike-support',
    filter: BuyV2ShopChatFilter.orders,
    filterId: 'bike',
    participantKind: BuyV2ShopChatParticipantKind.travelPartner,
    title: 'Bike trip support',
    subtitle: 'Pickup, destination and fare questions',
    detail: 'Start a Bike conversation',
    icon: Icons.two_wheeler_outlined,
    accent: Color(0xFF007C78),
    contextTitle: 'Bike trip',
    contextDetail: 'Pickup, destination, estimate and trip context',
    quickReplies: ['Ask about pickup', 'Check the fare'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  ),
  BuyV2ShopChatThread(
    id: 'travel-auto-support',
    filter: BuyV2ShopChatFilter.sellers,
    filterId: 'auto',
    participantKind: BuyV2ShopChatParticipantKind.travelPartner,
    title: 'Auto trip support',
    subtitle: 'Pickup, destination and fare questions',
    detail: 'Start an Auto conversation',
    icon: Icons.electric_rickshaw_outlined,
    accent: Color(0xFF4E7200),
    contextTitle: 'Auto trip',
    contextDetail: 'Pickup, destination, estimate and trip context',
    quickReplies: ['Ask about arrival', 'Check the fare'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  ),
  BuyV2ShopChatThread(
    id: 'travel-cab-support',
    filter: BuyV2ShopChatFilter.sellers,
    filterId: 'cab',
    participantKind: BuyV2ShopChatParticipantKind.travelPartner,
    title: 'Cab trip support',
    subtitle: 'Vehicle, pickup and fare questions',
    detail: 'Start a Cab conversation',
    icon: Icons.local_taxi_outlined,
    accent: Color(0xFF34345E),
    contextTitle: 'Cab trip',
    contextDetail: 'Vehicle, pickup, destination and trip context',
    quickReplies: ['Ask about the vehicle', 'Check arrival time'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  ),
  BuyV2ShopChatThread(
    id: 'travel-bus-desk',
    filter: BuyV2ShopChatFilter.offers,
    filterId: 'bus',
    participantKind: BuyV2ShopChatParticipantKind.travelPartner,
    title: 'Bus booking desk',
    subtitle: 'Route, date, seat and fare questions',
    detail: 'Start a Bus conversation',
    icon: Icons.directions_bus_outlined,
    accent: Color(0xFF234B7A),
    contextTitle: 'Bus booking',
    contextDetail: 'Route, travel date, seat and fare context',
    quickReplies: ['Ask about this route', 'Check seat options'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  ),
];

const _careThreads = <BuyV2ShopChatThread>[
  BuyV2ShopChatThread(
    id: 'care-doctor-desk',
    filter: BuyV2ShopChatFilter.orders,
    filterId: 'doctor',
    participantKind: BuyV2ShopChatParticipantKind.doctorDesk,
    title: 'Doctor booking',
    subtitle: 'Availability, fees and appointment support',
    detail: 'Booking support only · not medical advice',
    icon: Icons.medical_services_outlined,
    accent: Color(0xFF00757B),
    contextTitle: 'Doctor appointment',
    contextDetail: 'Provider, consultation type, fee and time context',
    quickReplies: ['Check availability', 'Ask about consultation type'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  ),
  BuyV2ShopChatThread(
    id: 'care-medicine-desk',
    filter: BuyV2ShopChatFilter.sellers,
    filterId: 'medicine',
    participantKind: BuyV2ShopChatParticipantKind.medicineDesk,
    title: 'Medicine order support',
    subtitle: 'Catalogue, order and delivery questions',
    detail: 'Order support only · not medical advice',
    icon: Icons.local_pharmacy_outlined,
    accent: Color(0xFF006A4E),
    contextTitle: 'Medicine order',
    contextDetail: 'Listed product, order and delivery context',
    quickReplies: ['Ask about this order', 'Check delivery time'],
  ),
  BuyV2ShopChatThread(
    id: 'care-salon-desk',
    filter: BuyV2ShopChatFilter.offers,
    filterId: 'salon',
    participantKind: BuyV2ShopChatParticipantKind.salonDesk,
    title: 'Salon booking desk',
    subtitle: 'Service, professional, price and time questions',
    detail: 'Start a Salon conversation',
    icon: Icons.content_cut_rounded,
    accent: Color(0xFF8A3B70),
    contextTitle: 'Salon appointment',
    contextDetail: 'Service, professional, price and time context',
    quickReplies: ['Check this service', 'Ask about the time'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  ),
];

const _workThreads = <BuyV2ShopChatThread>[
  BuyV2ShopChatThread(
    id: 'work-opportunity-support',
    filter: BuyV2ShopChatFilter.orders,
    filterId: 'earn-today',
    participantKind: BuyV2ShopChatParticipantKind.workOpportunity,
    title: 'Work opportunity',
    subtitle: 'Requirements, timing and earnings questions',
    detail: 'Start an Earn Today conversation',
    icon: Icons.payments_outlined,
    accent: Color(0xFF2F7A28),
    contextTitle: 'Earn Today',
    contextDetail: 'Opportunity, requirements, timing and earnings context',
    quickReplies: ['Ask about requirements', 'Check the timing'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  ),
  BuyV2ShopChatThread(
    id: 'work-workspace-support',
    filter: BuyV2ShopChatFilter.sellers,
    filterId: 'workspace',
    participantKind: BuyV2ShopChatParticipantKind.workspaceSupport,
    title: 'Workspace support',
    subtitle: 'Active work, documents and account questions',
    detail: 'Start a Workspace conversation',
    icon: Icons.work_outline_rounded,
    accent: Color(0xFF3F3F82),
    contextTitle: 'Workspace',
    contextDetail: 'Active work, next steps and document context',
    quickReplies: ['Ask about next steps', 'Help with documents'],
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
      locationSharing: false,
    ),
  ),
];
