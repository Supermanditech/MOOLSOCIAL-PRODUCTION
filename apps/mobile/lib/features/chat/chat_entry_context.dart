import 'dart:convert';

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

@immutable
class ChatCommerceContext {
  ChatCommerceContext._({required Map<String, String> values})
    : values = Map.unmodifiable(values),
      productSnapshot = Map.unmodifiable(
        _decodeObject(values['productSnapshot']),
      );

  factory ChatCommerceContext.fromUri(Uri uri) {
    final values = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      final value = entry.value.trim();
      if (value.isNotEmpty) values[entry.key] = value;
    }
    return ChatCommerceContext._(values: values);
  }

  final Map<String, String> values;
  final Map<String, Object?> productSnapshot;

  static ChatCommerceContext? maybeFromUri(Uri uri) {
    final value = ChatCommerceContext.fromUri(uri);
    return value.isCommerceConversation ? value : null;
  }

  bool get isCommerceConversation =>
      contextName != null ||
      supplier != null ||
      productTitle != null ||
      orderId != null ||
      conversationKey != null;

  String? get contextName => _value('context');
  String? get conversationKey => _value('conversationKey');
  String? get supplier => _value('supplier') ?? _snapshotString('supplier');
  String? get supplierType =>
      _value('supplierType') ?? _snapshotString('supplierType');
  String? get supplierRole =>
      _value('supplierRole') ?? _snapshotString('supplierRole');
  String? get productId => _value('productId') ?? _snapshotString('productId');
  String? get skuId => _value('skuId') ?? _snapshotString('skuId');
  String? get productTitle =>
      _value('productTitle') ?? _snapshotString('title');
  String? get brand => _value('brand') ?? _snapshotString('brand');
  String? get variant => _value('variant') ?? _snapshotString('variant');
  String? get pack => _value('pack') ?? _snapshotString('pack');
  String? get price => _value('price') ?? _snapshotString('price');
  String? get unitPrice => _value('unitPrice') ?? _snapshotString('unitPrice');
  String? get mrp => _value('mrp') ?? _snapshotString('mrp');
  String? get quantity => _value('quantity');
  String? get minimumOrder =>
      _value('minimumOrder') ?? _snapshotString('minimumOrder');
  String? get delivery => _value('delivery') ?? _snapshotString('delivery');
  String? get paymentMethod => _value('paymentMethod');
  String? get paymentTerms => _value('paymentTerms');
  String? get policy => _value('policy') ?? _snapshotString('returnPolicy');
  String? get productLink => _value('productLink');
  String? get orderId => _value('orderId');
  String? get purchaseId => _value('purchaseId');
  String? get orderTotal => _value('orderTotal');
  String? get deliveryDestination => _value('deliveryDestination');

  bool get isOrderConversation =>
      orderId != null || (contextName?.contains('order') ?? false);

  String get title =>
      supplier ?? productTitle ?? orderId ?? 'MoolSocial conversation';

  String get subtitle {
    final type = supplierType;
    final product = productTitle;
    final order = orderId;
    final values = <String>[
      ?type,
      ?product,
      if (product == null && order != null) 'Order $order',
    ];
    return values.isEmpty
        ? 'MoolSocial business conversation'
        : values.take(2).join(' · ');
  }

  String get contextLabel {
    if (isOrderConversation) return 'Order conversation';
    if (productTitle != null) return 'Product conversation';
    return 'Store conversation';
  }

  String get emptyMessage {
    if (productTitle case final value?) {
      return 'Ask $title about $value or share the details you need.';
    }
    if (orderId case final value?) {
      return 'Message $title about order $value.';
    }
    return 'Send your first message to $title.';
  }

  List<String> get suggestedPrompts => [
    if (productTitle != null) 'Is this product available?',
    if (price != null || orderTotal != null) 'Please confirm the price.',
    if (delivery != null) 'When can this be delivered?',
  ];

  List<ChatCommerceFact> get decisionFacts {
    final facts = <ChatCommerceFact>[];
    void add(String label, String? value) {
      final clean = value?.trim();
      if (clean == null || clean.isEmpty) return;
      if (facts.any((fact) => fact.label == label && fact.value == clean)) {
        return;
      }
      facts.add(ChatCommerceFact(label: label, value: clean));
    }

    add('Product', productTitle);
    add('Product ID', productId);
    add('SKU', skuId);
    add('Brand', brand);
    add('Variant', variant);
    add('Pack', pack);
    add('Quantity', quantity);
    add('Minimum order', minimumOrder);
    add('Price', _money(price));
    add('Unit price', unitPrice);
    add('MRP', _money(mrp));
    add('Delivery', delivery);
    add('Order', orderId);
    add('Purchase', purchaseId);
    add('Order total', _money(orderTotal));
    add('Deliver to', deliveryDestination);
    add('Payment', paymentMethod);
    add('Payment terms', paymentTerms);
    add('After delivery', policy);

    final compliance = productSnapshot['compliance'];
    if (compliance is Map) {
      String? complianceValue(String key) {
        final value = compliance[key];
        final clean = value?.toString().trim();
        return clean == null || clean.isEmpty || clean == 'null' ? null : clean;
      }

      add('Generic name', complianceValue('genericName'));
      add('Net quantity', complianceValue('netQuantity'));
      add('Manufacturer', complianceValue('manufacturer'));
      add('Country of origin', complianceValue('countryOfOrigin'));
      add('Best before / use by', complianceValue('bestBeforeOrUseBy'));
    }
    return List.unmodifiable(facts);
  }

  String? get productAppRoute {
    final uri = Uri.tryParse(productLink ?? '');
    if (uri == null ||
        uri.host.toLowerCase() != 'moolsocial.app' ||
        uri.path != '/app/buy') {
      return null;
    }
    return Uri(path: uri.path, queryParameters: uri.queryParameters).toString();
  }

  String? _value(String key) {
    final value = values[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? _snapshotString(String key) {
    final value = productSnapshot[key];
    final clean = value?.toString().trim();
    return clean == null || clean.isEmpty || clean == 'null' ? null : clean;
  }

  static Map<String, Object?> _decodeObject(String? source) {
    if (source == null || source.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(source);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  static String? _money(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean.contains('₹') ? clean : '₹$clean';
  }
}

@immutable
class ChatCommerceFact {
  const ChatCommerceFact({required this.label, required this.value});

  final String label;
  final String value;
}
