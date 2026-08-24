import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import 'buy_v2_design.dart';
import 'buy_v2_shop_chat_motion.dart';

enum BuyV2ShopChatFilter { all, orders, sellers, offers }

class BuyV2ShopChatView extends StatefulWidget {
  const BuyV2ShopChatView({
    super.key,
    required this.session,
    required this.originLabel,
    required this.onBack,
    required this.onOpenProductionChat,
    this.initialFilter = BuyV2ShopChatFilter.all,
  });

  final BuyV2Session session;
  final String originLabel;
  final VoidCallback onBack;
  final VoidCallback onOpenProductionChat;
  final BuyV2ShopChatFilter initialFilter;

  @override
  State<BuyV2ShopChatView> createState() => _BuyV2ShopChatViewState();
}

class _BuyV2ShopChatViewState extends State<BuyV2ShopChatView> {
  late BuyV2ShopChatFilter _filter = widget.initialFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void didUpdateWidget(covariant BuyV2ShopChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _filter = widget.initialFilter;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries();
    return Semantics(
      key: const ValueKey('buy-shop-chat'),
      container: true,
      label: 'Shop Chat. Sellers, orders and offers.',
      child: ColoredBox(
        color: const Color(0xFFF8F8FC),
        child: Column(
          children: [
            _ShopChatHeader(
              originLabel: widget.originLabel,
              onBack: widget.onBack,
              onOpenAll: widget.onOpenProductionChat,
            ),
            _ShopChatSearch(
              originLabel: widget.originLabel,
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
            ),
            _ShopChatFilters(
              selected: _filter,
              onSelected: (value) {
                HapticFeedback.selectionClick();
                setState(() => _filter = value);
              },
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, color: BuyV2Colors.line),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BuyV2ShopChatFilterMotion(
                      stateKey:
                          '${_filter.name}|${_searchController.text.trim()}',
                      child: entries.isEmpty
                          ? const _ShopChatEmptyState()
                          : ListView.builder(
                              key: ValueKey(
                                'buy-shop-chat-results-${_filter.name}',
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                88,
                              ),
                              itemCount: entries.length + 2,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return const _ShopChatTrustNote();
                                }
                                if (index == 1) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      14,
                                      4,
                                      6,
                                    ),
                                    child: Text(
                                      _filter == BuyV2ShopChatFilter.all
                                          ? 'Start with Shop'
                                          : _filter.sectionLabel,
                                      style: context.buyEyebrow.copyWith(
                                        color: BuyV2Colors.ink,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                }
                                final entry = entries[index - 2];
                                return BuyV2ShopChatEntryMotion(
                                  index: index - 2,
                                  child: _ShopChatEntryTile(
                                    entry: entry,
                                    onTap: widget.onOpenProductionChat,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Semantics(
                      label: 'Start a new Shop chat',
                      button: true,
                      child: Tooltip(
                        message: 'New Shop chat',
                        child: FloatingActionButton(
                          key: const ValueKey('buy-shop-chat-new'),
                          heroTag: 'buy-shop-chat-new',
                          elevation: 5,
                          backgroundColor: BuyV2Colors.navy,
                          foregroundColor: Colors.white,
                          onPressed: widget.onOpenProductionChat,
                          child: const Icon(Icons.add_comment_outlined),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ShopChatEntry> _visibleEntries() {
    final allEntries = _entriesFor(_filter);
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return allEntries;
    final tokens = query
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);
    return allEntries
        .where((entry) {
          final searchable = [
            entry.title,
            entry.subtitle,
            entry.detail,
            entry.kind.label,
          ].join(' ').toLowerCase();
          return tokens.every(searchable.contains);
        })
        .toList(growable: false);
  }

  List<_ShopChatEntry> _entriesFor(BuyV2ShopChatFilter filter) {
    final orderEntries = widget.session.orders
        .where(
          (order) =>
              order.destination == BuyV2Destination.shop ||
              order.destination == BuyV2Destination.wholesale,
        )
        .map(_ShopChatEntry.fromOrder)
        .toList(growable: false);
    const sellerEntries = [
      _ShopChatEntry(
        id: 'shop-seller',
        kind: BuyV2ShopChatFilter.sellers,
        title: 'Ask a Shop seller',
        subtitle: 'Products, stock and delivery',
        detail: 'Find a Mool Retail Partner in Chat',
        icon: Icons.storefront_outlined,
        accent: BuyV2Colors.orange,
      ),
      _ShopChatEntry(
        id: 'wholesale-partner',
        kind: BuyV2ShopChatFilter.sellers,
        title: 'Ask a wholesale partner',
        subtitle: 'Packs, pricing and fulfilment',
        detail: 'Find a Mool Trade Partner in Chat',
        icon: Icons.inventory_2_outlined,
        accent: BuyV2Colors.green,
      ),
    ];
    const offerEntries = [
      _ShopChatEntry(
        id: 'offer-details',
        kind: BuyV2ShopChatFilter.offers,
        title: 'Offer details',
        subtitle: 'Price, pack size and validity',
        detail: 'Continue securely in Chat',
        icon: Icons.local_offer_outlined,
        accent: BuyV2Colors.orange,
      ),
      _ShopChatEntry(
        id: 'offer-checkout',
        kind: BuyV2ShopChatFilter.offers,
        title: 'Offer and checkout help',
        subtitle: 'Eligibility, cart and payment questions',
        detail: 'Continue securely in Chat',
        icon: Icons.shopping_bag_outlined,
        accent: BuyV2Colors.navy,
      ),
    ];
    return switch (filter) {
      BuyV2ShopChatFilter.orders => orderEntries,
      BuyV2ShopChatFilter.sellers => sellerEntries,
      BuyV2ShopChatFilter.offers => offerEntries,
      BuyV2ShopChatFilter.all => [
        ...orderEntries.take(2),
        ...sellerEntries,
        offerEntries.first,
      ],
    };
  }
}

class _ShopChatHeader extends StatelessWidget {
  const _ShopChatHeader({
    required this.originLabel,
    required this.onBack,
    required this.onOpenAll,
  });

  final String originLabel;
  final VoidCallback onBack;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: BuyV2Colors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('buy-shop-chat-back'),
            tooltip: 'Back to $originLabel',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: BuyV2Colors.ink,
          ),
          const SizedBox(width: 2),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BuyV2Colors.navy, BuyV2Colors.royal],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  '$originLabel · sellers, orders and offers',
                  key: const ValueKey('buy-shop-chat-origin'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyMeta.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('buy-shop-chat-open-all'),
            tooltip: 'All MoolSocial chats',
            onPressed: onOpenAll,
            icon: const Icon(Icons.forum_outlined),
            color: BuyV2Colors.navy,
          ),
        ],
      ),
    );
  }
}

class _ShopChatSearch extends StatelessWidget {
  const _ShopChatSearch({
    required this.originLabel,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final String originLabel;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: SizedBox(
        height: 48,
        child: TextField(
          key: const ValueKey('buy-shop-chat-search'),
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: context.buyBody.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search $originLabel conversations',
            hintStyle: context.buyMeta.copyWith(fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, size: 22),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('buy-shop-chat-search-clear'),
                    tooltip: 'Clear Shop Chat search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BuyV2Colors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BuyV2Colors.navy, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopChatFilters extends StatelessWidget {
  const _ShopChatFilters({required this.selected, required this.onSelected});

  final BuyV2ShopChatFilter selected;
  final ValueChanged<BuyV2ShopChatFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        key: const ValueKey('buy-shop-chat-filters'),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: BuyV2ShopChatFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final filter = BuyV2ShopChatFilter.values[index];
          final active = filter == selected;
          return Semantics(
            selected: active,
            button: true,
            label: '${filter.label} Shop Chat filter',
            child: ChoiceChip(
              key: ValueKey('buy-shop-chat-filter-${filter.name}'),
              label: Text(filter.label),
              selected: active,
              showCheckmark: false,
              onSelected: active ? null : (_) => onSelected(filter),
              labelStyle: TextStyle(
                color: active ? Colors.white : BuyV2Colors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              selectedColor: BuyV2Colors.navy,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: active ? BuyV2Colors.navy : BuyV2Colors.line,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
            ),
          );
        },
      ),
    );
  }
}

class _ShopChatTrustNote extends StatelessWidget {
  const _ShopChatTrustNote();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Shop conversations continue securely in MoolSocial Chat.',
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: buyV2CardDecoration(
          color: BuyV2Colors.softGreen.withValues(alpha: .72),
          border: BuyV2Colors.green.withValues(alpha: .22),
          radius: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: BuyV2Colors.green,
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Shop conversations continue securely in MoolSocial Chat.',
                style: context.buyBody.copyWith(fontSize: 10.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatEntryTile extends StatelessWidget {
  const _ShopChatEntryTile({required this.entry, required this.onTap});

  final _ShopChatEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    void openChat() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return Semantics(
      key: ValueKey('buy-shop-chat-entry-${entry.id}'),
      button: true,
      label:
          '${entry.title}. ${entry.subtitle}. ${entry.detail}. Continue in Chat.',
      onTap: openChat,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: BuyV2IntentDepth(
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: BuyV2Colors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: openChat,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 76),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: entry.accent.withValues(alpha: .11),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(entry.icon, color: entry.accent, size: 23),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.buyBody.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: entry.accent.withValues(alpha: .09),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    entry.kind.label,
                                    style: TextStyle(
                                      color: entry.accent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              entry.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta.copyWith(
                                color: BuyV2Colors.ink,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta.copyWith(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: BuyV2Colors.muted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopChatEmptyState extends StatelessWidget {
  const _ShopChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: BuyV2Colors.muted,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text('No Shop chats found', style: context.buyBody),
            const SizedBox(height: 4),
            Text(
              'Try another seller, order or offer.',
              textAlign: TextAlign.center,
              style: context.buyMeta,
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _ShopChatEntry {
  const _ShopChatEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.accent,
  });

  factory _ShopChatEntry.fromOrder(BuyV2Order order) {
    final delivered = order.status == BuyV2OrderStatus.delivered;
    return _ShopChatEntry(
      id: 'order-${order.id}',
      kind: BuyV2ShopChatFilter.orders,
      title: 'Order ${order.id}',
      subtitle: '${order.partner} · ${order.status.customerLabel}',
      detail: order.promise,
      icon: delivered
          ? Icons.inventory_2_outlined
          : Icons.local_shipping_outlined,
      accent: delivered ? BuyV2Colors.green : BuyV2Colors.navy,
    );
  }

  final String id;
  final BuyV2ShopChatFilter kind;
  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final Color accent;
}

extension on BuyV2ShopChatFilter {
  String get label => switch (this) {
    BuyV2ShopChatFilter.all => 'All',
    BuyV2ShopChatFilter.orders => 'Orders',
    BuyV2ShopChatFilter.sellers => 'Sellers',
    BuyV2ShopChatFilter.offers => 'Offers',
  };

  String get sectionLabel => switch (this) {
    BuyV2ShopChatFilter.all => 'Start with Shop',
    BuyV2ShopChatFilter.orders => 'Order conversations',
    BuyV2ShopChatFilter.sellers => 'Seller conversations',
    BuyV2ShopChatFilter.offers => 'Offer conversations',
  };
}

extension on BuyV2OrderStatus {
  String get customerLabel => switch (this) {
    BuyV2OrderStatus.preparing => 'Preparing',
    BuyV2OrderStatus.confirmed => 'Confirmed',
    BuyV2OrderStatus.dispatched => 'Dispatched',
    BuyV2OrderStatus.arriving => 'Arriving',
    BuyV2OrderStatus.delivered => 'Delivered',
  };
}
