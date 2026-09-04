import 'package:flutter/material.dart';

enum ChatEntryContextId {
  mool,
  social,
  shop,
  food,
  travel,
  care,
  work,
  workspace,
  pay,
}

@immutable
class ChatEntryContext {
  const ChatEntryContext({
    required this.id,
    required this.originLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.showThreadFilters = true,
    this.allowedThreadIds,
    this.allowedThreadPrefixes,
  });

  final ChatEntryContextId id;
  final String originLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool showThreadFilters;
  final Set<String>? allowedThreadIds;
  final Set<String>? allowedThreadPrefixes;

  bool allowsThread(String threadId) {
    if (threadId == 'shop-assist') return true;
    final ids = allowedThreadIds;
    final prefixes = allowedThreadPrefixes;
    if (ids == null && prefixes == null) return true;
    return (ids?.contains(threadId) ?? false) ||
        (prefixes?.any(threadId.startsWith) ?? false);
  }

  static ChatEntryContext resolve(String returnRoute) {
    final uri = Uri.tryParse(returnRoute);
    final path = uri?.path.toLowerCase() ?? '';
    if (path.startsWith('/app/social')) return social;
    if (path.startsWith('/app/buy')) {
      final sub = uri?.queryParameters['sub']?.toLowerCase();
      if (path == '/app/buy/medicine' || sub == 'medicine' || sub == 'rx') {
        return care;
      }
      return shop;
    }
    if (path.startsWith('/app/eat')) return food;
    if (path.startsWith('/app/ride')) return travel;
    if (path.startsWith('/app/book')) return care;
    if (path.startsWith('/app/retailer')) return _retailerWorkspace;
    if (path.startsWith('/app/manufacturer')) return _manufacturerWorkspace;
    if (path.startsWith('/app/captain')) return _captainWorkspace;
    if (path.startsWith('/app/operations')) return _operationsWorkspace;
    if (path.startsWith('/app/creator')) return _creatorWorkspace;
    if (_workspaceWorkPrefixes.any(path.startsWith) ||
        (path == '/app/work' &&
            uri?.queryParameters['sub']?.toLowerCase() == 'workspace')) {
      return workspace;
    }
    if (path.startsWith('/app/work')) return work;
    if (_workspacePrefixes.any(path.startsWith)) return workspace;
    if (path.startsWith('/app/pay')) return pay;
    return mool;
  }

  static const mool = ChatEntryContext(
    id: ChatEntryContextId.mool,
    originLabel: 'MoolSocial',
    title: 'Chat',
    subtitle: 'All your conversations',
    icon: Icons.chat_bubble_outline_rounded,
    accent: Color(0xFF000080),
  );

  static const social = ChatEntryContext(
    id: ChatEntryContextId.social,
    originLabel: 'Social',
    title: 'Social Chat',
    subtitle: 'People and creators',
    icon: Icons.people_alt_outlined,
    accent: Color(0xFF2F5BEA),
  );

  static const shop = ChatEntryContext(
    id: ChatEntryContextId.shop,
    originLabel: 'Shop',
    title: 'Shop Chat',
    subtitle: 'Orders and products',
    icon: Icons.shopping_bag_outlined,
    accent: Color(0xFF7A4D10),
    allowedThreadIds: {
      'shop-assist',
      'shop-order',
      'shop-partner',
      'shop-offers',
    },
  );

  static const food = ChatEntryContext(
    id: ChatEntryContextId.food,
    originLabel: 'Food',
    title: 'Food Chat',
    subtitle: 'Orders and tables',
    icon: Icons.restaurant_outlined,
    accent: Color(0xFFF27A1A),
    allowedThreadIds: {'rasoi', 'order-support'},
    allowedThreadPrefixes: {'food-restaurant-'},
  );

  static const travel = ChatEntryContext(
    id: ChatEntryContextId.travel,
    originLabel: 'Travel',
    title: 'Travel Chat',
    subtitle: 'Trips and bookings',
    icon: Icons.route_outlined,
    accent: Color(0xFF4C4C8A),
    allowedThreadIds: {'ride-support', 'ride-captain'},
    allowedThreadPrefixes: {'ride-'},
  );

  static const care = ChatEntryContext(
    id: ChatEntryContextId.care,
    originLabel: 'Care',
    title: 'Care Chat',
    subtitle: 'Appointments and care',
    icon: Icons.health_and_safety_outlined,
    accent: Color(0xFF00757B),
    allowedThreadIds: {'clinic-care', 'task-helper', 'order-support'},
  );

  static const work = ChatEntryContext(
    id: ChatEntryContextId.work,
    originLabel: 'Work',
    title: 'Work Chat',
    subtitle: 'Opportunities',
    icon: Icons.work_outline_rounded,
    accent: Color(0xFF2F7A28),
    allowedThreadIds: {'work-opportunity', 'work-support'},
  );

  static const workspace = ChatEntryContext(
    id: ChatEntryContextId.workspace,
    originLabel: 'Workspace',
    title: 'Workspace Chat',
    subtitle: 'Setup and review support',
    icon: Icons.storefront_outlined,
    accent: Color(0xFF5B3F8C),
    allowedThreadIds: {'workspace-support'},
  );

  static const _retailerWorkspace = ChatEntryContext(
    id: ChatEntryContextId.workspace,
    originLabel: 'Workspace',
    title: 'Workspace Chat',
    subtitle: 'Setup and review support',
    icon: Icons.storefront_outlined,
    accent: Color(0xFF5B3F8C),
    allowedThreadIds: {
      'workspace-support',
      'order-support',
      'ride-support',
      'mahadev',
      'retailer-order-ms-2841',
      'retailer-order-ms-2840',
    },
  );

  static const _manufacturerWorkspace = ChatEntryContext(
    id: ChatEntryContextId.workspace,
    originLabel: 'Workspace',
    title: 'Workspace Chat',
    subtitle: 'Setup and review support',
    icon: Icons.storefront_outlined,
    accent: Color(0xFF5B3F8C),
    allowedThreadIds: {'workspace-support', 'order-support'},
  );

  static const _captainWorkspace = ChatEntryContext(
    id: ChatEntryContextId.workspace,
    originLabel: 'Workspace',
    title: 'Workspace Chat',
    subtitle: 'Setup and review support',
    icon: Icons.storefront_outlined,
    accent: Color(0xFF5B3F8C),
    allowedThreadIds: {'workspace-support', 'order-support', 'ride-support'},
    allowedThreadPrefixes: {'ride-'},
  );

  static const _operationsWorkspace = ChatEntryContext(
    id: ChatEntryContextId.workspace,
    originLabel: 'Workspace',
    title: 'Workspace Chat',
    subtitle: 'Setup and review support',
    icon: Icons.storefront_outlined,
    accent: Color(0xFF5B3F8C),
    allowedThreadIds: {'workspace-support', 'order-support'},
  );

  static const _creatorWorkspace = ChatEntryContext(
    id: ChatEntryContextId.workspace,
    originLabel: 'Workspace',
    title: 'Workspace Chat',
    subtitle: 'Setup and review support',
    icon: Icons.storefront_outlined,
    accent: Color(0xFF5B3F8C),
    allowedThreadIds: {'workspace-support'},
  );

  static const pay = ChatEntryContext(
    id: ChatEntryContextId.pay,
    originLabel: 'Pay',
    title: 'Pay Chat',
    subtitle: 'Payments and support',
    icon: Icons.account_balance_wallet_outlined,
    accent: Color(0xFF0B6B55),
    allowedThreadIds: {'pay-support'},
  );

  static const _workspacePrefixes = <String>[
    '/app/retailer',
    '/app/manufacturer',
    '/app/creator',
    '/app/captain',
    '/app/operations',
  ];

  static const _workspaceWorkPrefixes = <String>[
    '/app/work/my-work',
    '/app/work/workspace',
    '/app/work/status',
  ];
}
