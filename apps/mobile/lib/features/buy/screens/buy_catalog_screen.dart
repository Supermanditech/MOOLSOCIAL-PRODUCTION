import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyCatalogScreen extends StatefulWidget {
  const BuyCatalogScreen({required this.session, super.key});

  final BuySession session;

  @override
  State<BuyCatalogScreen> createState() => _BuyCatalogScreenState();
}

class _BuyCatalogScreenState extends State<BuyCatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final products = widget.session.visibleProducts(_searchController.text);
        final categories = BuyCategory.values
            .where((category) => category != BuyCategory.medicine)
            .toList();
        return BuyPageScaffold(
          key: const Key('buy-catalog-screen'),
          session: widget.session,
          title: 'Shop essentials',
          subtitle: widget.session.fulfilment == BuyFulfilment.homeDelivery
              ? widget.session.deliveryPromise
              : 'Collect from ${widget.session.pickupStore}',
          showBack: true,
          fallbackBackRoute: '/app/buy',
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MoolSpacing.md,
                  MoolSpacing.xs,
                  MoolSpacing.md,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    _DeliveryContextCard(session: widget.session),
                    const SizedBox(height: MoolSpacing.sm),
                    TextField(
                      key: const Key('buy-search-field'),
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search products or shops',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? const Icon(Icons.mic_none_rounded)
                            : IconButton(
                                key: const Key('buy-clear-search'),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    SizedBox(
                      height: MoolMetrics.minimumTapTarget,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: MoolSpacing.xs),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return ChoiceChip(
                            key: Key('buy-category-${category.name}'),
                            label: Text(category.label),
                            selected:
                                widget.session.selectedCategory == category,
                            onSelected: (_) =>
                                widget.session.selectCategory(category),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Available for your home',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${products.length} products',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                  ],
                ),
              ),
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptySearch(
                    onClear: () {
                      _searchController.clear();
                      widget.session.selectCategory(BuyCategory.all);
                      setState(() {});
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    0,
                    MoolSpacing.md,
                    MoolSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MoolSpacing.sm),
                    itemBuilder: (context, index) => _ProductCard(
                      product: products[index],
                      session: widget.session,
                    ),
                  ),
                ),
            ],
          ),
          bottomAction: widget.session.itemCount == 0
              ? null
              : FilledButton.icon(
                  key: const Key('buy-view-basket'),
                  onPressed: () => context.go('/app/buy/basket'),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    'Review ${widget.session.itemCount} '
                    '${widget.session.itemCount == 1 ? 'item' : 'items'} · '
                    '${buyMoney(widget.session.subtotal)}',
                  ),
                ),
        );
      },
    );
  }
}

class _DeliveryContextCard extends StatelessWidget {
  const _DeliveryContextCard({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final home = session.fulfilment == BuyFulfilment.homeDelivery;
    return BuySurfaceCard(
      color: const Color(0xFFEDEEFF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              home ? Icons.home_outlined : Icons.store_mall_directory_outlined,
              color: MoolColors.navy,
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  home ? 'Delivering to your home' : 'Collecting at the store',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  home
                      ? session.address
                      : session.pickupStore ?? session.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                Wrap(
                  spacing: MoolSpacing.xs,
                  runSpacing: MoolSpacing.xs,
                  children: [
                    TextButton.icon(
                      key: const Key('buy-change-address'),
                      onPressed: () => _showAddressSheet(context, session),
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: const Text('Change address'),
                    ),
                    TextButton.icon(
                      key: const Key('buy-choose-store-pickup'),
                      onPressed: () => _showPickupSheet(context, session),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Collect at store'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddressSheet(BuildContext context, BuySession session) async {
  var address = session.fulfilment == BuyFulfilment.homeDelivery
      ? session.address
      : '';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Where should we deliver?',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Add a complete address so the shop and rider can complete the order.',
            ),
            const SizedBox(height: MoolSpacing.md),
            TextFormField(
              key: const Key('buy-address-field'),
              initialValue: address,
              onChanged: (value) => address = value,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Home address',
                hintText: 'House, street, area and city',
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: const Key('buy-save-address'),
              onPressed: () {
                if (session.updateAddress(address)) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Deliver to this address'),
            ),
            TextButton(
              key: const Key('buy-cancel-address'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showPickupSheet(BuildContext context, BuySession session) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a store to collect from',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Collection is for orders you plan to pick up at a selected store.',
            ),
            const SizedBox(height: MoolSpacing.md),
            _StoreChoice(
              key: const Key('buy-pickup-mahadev'),
              name: 'Mahadev Fresh Mart',
              detail: 'Sardarpura · ready in 15–20 min',
              onTap: () {
                session.chooseStorePickup('Mahadev Fresh Mart · Sardarpura');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: MoolSpacing.xs),
            _StoreChoice(
              key: const Key('buy-pickup-rasoi'),
              name: 'Rasoi Super Store',
              detail: 'Ratanada · ready in 25–30 min',
              onTap: () {
                session.chooseStorePickup('Rasoi Super Store · Ratanada');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton(
              key: const Key('buy-keep-home-delivery'),
              onPressed: () {
                session.chooseHomeDelivery();
                Navigator.of(context).pop();
              },
              child: const Text('Keep home delivery'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StoreChoice extends StatelessWidget {
  const _StoreChoice({
    required this.name,
    required this.detail,
    required this.onTap,
    super.key,
  });

  final String name;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 60,
      tileColor: const Color(0xFFF5F6FC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MoolRadii.control),
      ),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE5F3E4),
        child: Icon(Icons.storefront_outlined, color: MoolColors.success),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.session});

  final BuyProduct product;
  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final quantity = session.quantityFor(product.id);
    return BuySurfaceCard(
      child: InkWell(
        key: Key('buy-open-product-${product.id}'),
        onTap: () => context.go('/app/buy/product/${product.id}'),
        borderRadius: BorderRadius.circular(MoolRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 88,
                decoration: BoxDecoration(
                  color: _productColor(product.category),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
                child: Icon(
                  _productIcon(product.category),
                  color: MoolColors.navy,
                  size: 34,
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.unitLabel} · ${product.seller}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.deliveryPromise,
                      style: TextStyle(
                        color: product.available
                            ? MoolColors.success
                            : const Color(0xFFB42318),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            buyMoney(product.price),
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (quantity == 0)
                          FilledButton(
                            key: Key('buy-add-${product.id}'),
                            onPressed: product.available
                                ? () => session.addProduct(product.id)
                                : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(
                                78,
                                MoolMetrics.minimumTapTarget,
                              ),
                              backgroundColor: MoolColors.navy,
                            ),
                            child: Text(product.available ? 'Add' : 'Sold out'),
                          )
                        else
                          BuyQuantityControl(
                            productId: product.id,
                            quantity: quantity,
                            onDecrease: () => session.decrease(product.id),
                            onIncrease: () => session.increase(product.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: MoolColors.muted,
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'No matching products',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Clear the search or choose another category.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoolSpacing.md),
            OutlinedButton(
              key: const Key('buy-clear-empty-search'),
              onPressed: onClear,
              child: const Text('Show all products'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _productColor(BuyCategory category) => switch (category) {
  BuyCategory.fresh => const Color(0xFFE1F3DE),
  BuyCategory.staples => const Color(0xFFFFEDDA),
  BuyCategory.dairy => const Color(0xFFE3F1FF),
  BuyCategory.homeCare => const Color(0xFFEDE8FF),
  BuyCategory.personalCare => const Color(0xFFFFE8F2),
  BuyCategory.medicine => const Color(0xFFEAF7E8),
  BuyCategory.all => const Color(0xFFF0F1F8),
};

IconData _productIcon(BuyCategory category) => switch (category) {
  BuyCategory.fresh => Icons.eco_outlined,
  BuyCategory.staples => Icons.breakfast_dining_outlined,
  BuyCategory.dairy => Icons.water_drop_outlined,
  BuyCategory.homeCare => Icons.cleaning_services_outlined,
  BuyCategory.personalCare => Icons.spa_outlined,
  BuyCategory.medicine => Icons.medication_outlined,
  BuyCategory.all => Icons.shopping_basket_outlined,
};
