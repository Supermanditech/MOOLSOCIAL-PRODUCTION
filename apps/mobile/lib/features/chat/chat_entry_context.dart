import 'package:flutter/material.dart';

import 'chat_models.dart';

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
    this.defaultFilter,
    this.showThreadFilters = true,
    this.allowedThreadIds,
  });

  final ChatEntryContextId id;
  final String originLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final ChatThreadType? defaultFilter;
  final bool showThreadFilters;
  final Set<String>? allowedThreadIds;

  static ChatEntryContext resolve(String returnRoute) {
    final path = Uri.tryParse(returnRoute)?.path.toLowerCase() ?? '';
    if (path.startsWith('/app/social')) return social;
    if (path.startsWith('/app/buy')) return shop;
    if (path.startsWith('/app/eat')) return food;
    if (path.startsWith('/app/ride')) return travel;
    if (path.startsWith('/app/book')) return care;
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
    defaultFilter: ChatThreadType.people,
    showThreadFilters: false,
  );

  static const shop = ChatEntryContext(
    id: ChatEntryContextId.shop,
    originLabel: 'Shop',
    title: 'Shop Chat',
    subtitle: 'Orders and products',
    icon: Icons.shopping_bag_outlined,
    accent: Color(0xFF7A4D10),
    defaultFilter: ChatThreadType.order,
  );

  static const food = ChatEntryContext(
    id: ChatEntryContextId.food,
    originLabel: 'Food',
    title: 'Food Chat',
    subtitle: 'Orders and tables',
    icon: Icons.restaurant_outlined,
    accent: Color(0xFFF27A1A),
    defaultFilter: ChatThreadType.order,
  );

  static const travel = ChatEntryContext(
    id: ChatEntryContextId.travel,
    originLabel: 'Travel',
    title: 'Travel Chat',
    subtitle: 'Trips and bookings',
    icon: Icons.route_outlined,
    accent: Color(0xFF4C4C8A),
    defaultFilter: ChatThreadType.support,
    allowedThreadIds: {'ride-support'},
  );

  static const care = ChatEntryContext(
    id: ChatEntryContextId.care,
    originLabel: 'Care',
    title: 'Care Chat',
    subtitle: 'Appointments and care',
    icon: Icons.health_and_safety_outlined,
    accent: Color(0xFF00757B),
    defaultFilter: ChatThreadType.support,
  );

  static const work = ChatEntryContext(
    id: ChatEntryContextId.work,
    originLabel: 'Work',
    title: 'Work Chat',
    subtitle: 'Opportunities',
    icon: Icons.work_outline_rounded,
    accent: Color(0xFF2F7A28),
    defaultFilter: ChatThreadType.business,
  );

  static const workspace = ChatEntryContext(
    id: ChatEntryContextId.workspace,
    originLabel: 'Workspace',
    title: 'Workspace Chat',
    subtitle: 'Customers and operations',
    icon: Icons.storefront_outlined,
    accent: Color(0xFF5B3F8C),
    defaultFilter: ChatThreadType.business,
  );

  static const pay = ChatEntryContext(
    id: ChatEntryContextId.pay,
    originLabel: 'Pay',
    title: 'Pay Chat',
    subtitle: 'Payments and support',
    icon: Icons.account_balance_wallet_outlined,
    accent: Color(0xFF0B6B55),
    defaultFilter: ChatThreadType.support,
  );

  static const _workspacePrefixes = <String>[
    '/app/retailer',
    '/app/manufacturer',
    '/app/creator',
    '/app/captain',
    '/app/operations',
  ];
}
