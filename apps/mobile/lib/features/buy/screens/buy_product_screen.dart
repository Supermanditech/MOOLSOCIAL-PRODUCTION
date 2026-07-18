import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyProductScreen extends StatelessWidget {
  const BuyProductScreen({
    required this.session,
    required this.productId,
    super.key,
  });

  final BuySession session;
  final String productId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final product = session.product(productId);
        final quantity = session.quantityFor(product.id);
        return BuyPageScaffold(
          key: const Key('buy-product-screen'),
          session: session,
          title: product.name,
          subtitle: product.seller,
          fallbackBackRoute: '/app/buy/grocery',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              Container(
                height: 210,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5F3E4), Color(0xFFFFF1DF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(MoolRadii.sheet),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.shopping_basket_outlined,
                        size: 82,
                        color: MoolColors.navy,
                      ),
                    ),
                    Positioned(
                      top: MoolSpacing.sm,
                      right: MoolSpacing.sm,
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            key: const Key('buy-save-product'),
                            tooltip: 'Save product',
                            onPressed: () => _showResult(
                              context,
                              '${product.name} saved for later.',
                            ),
                            icon: const Icon(Icons.bookmark_border_rounded),
                          ),
                          const SizedBox(width: MoolSpacing.xs),
                          IconButton.filledTonal(
                            key: const Key('buy-share-product'),
                            tooltip: 'Share product',
                            onPressed: () => _showShareSheet(context, product),
                            icon: const Icon(Icons.ios_share_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              Text(
                '${product.detail} · ${product.unitLabel}',
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    buyMoney(product.price),
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'for ${product.unitLabel}',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              _SellerCard(product: product),
              const SizedBox(height: MoolSpacing.sm),
              _FulfilmentCard(session: session),
              const SizedBox(height: MoolSpacing.sm),
              BuySurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your protection',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    _Fact(
                      icon: Icons.verified_user_outlined,
                      text: product.refundRule,
                    ),
                    const _Fact(
                      icon: Icons.receipt_long_outlined,
                      text: 'Final price and bill shown before payment',
                    ),
                    const _Fact(
                      icon: Icons.inventory_2_outlined,
                      text: 'Quantity confirmed by you before checkout',
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomAction: Row(
            children: [
              if (quantity > 0) ...[
                BuyQuantityControl(
                  productId: product.id,
                  quantity: quantity,
                  onDecrease: () => session.decrease(product.id),
                  onIncrease: () => session.increase(product.id),
                ),
                const SizedBox(width: MoolSpacing.sm),
              ],
              Expanded(
                child: FilledButton(
                  key: const Key('buy-product-primary'),
                  onPressed: product.available
                      ? () {
                          if (quantity == 0) {
                            session.addProduct(product.id);
                          } else {
                            context.go('/app/buy/basket');
                          }
                        }
                      : null,
                  child: Text(
                    !product.available
                        ? 'Not available today'
                        : quantity == 0
                        ? 'Add to basket'
                        : 'Open basket',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.product});

  final BuyProduct product;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFE5F3E4),
            child: Icon(Icons.storefront_outlined, color: MoolColors.success),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.seller,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Verified local shop · 4.8 ★ · 2.1 km',
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('buy-open-seller'),
            tooltip: 'View shop',
            onPressed: () => _showResult(
              context,
              '${product.seller} is verified and currently accepting orders.',
            ),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _FulfilmentCard extends StatelessWidget {
  const _FulfilmentCard({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final home = session.fulfilment == BuyFulfilment.homeDelivery;
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How you will receive it',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          _FulfilmentChoice(
            key: const Key('buy-product-home-delivery'),
            selected: home,
            title: 'Deliver to home',
            detail: home ? session.address : 'Choose your delivery address',
            icon: Icons.home_outlined,
            onTap: session.chooseHomeDelivery,
          ),
          const SizedBox(height: MoolSpacing.xs),
          _FulfilmentChoice(
            key: const Key('buy-product-store-pickup'),
            selected: !home,
            title: 'Collect from a selected store',
            detail: session.pickupStore ?? 'Choose the store before collection',
            icon: Icons.storefront_outlined,
            onTap: () => _showStoreChoice(context, session),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            session.deliveryPromise,
            style: const TextStyle(
              color: MoolColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FulfilmentChoice extends StatelessWidget {
  const _FulfilmentChoice({
    required this.selected,
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEDEEFF) : const Color(0xFFF5F6FC),
      borderRadius: BorderRadius.circular(MoolRadii.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MoolRadii.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MoolMetrics.minimumTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.sm),
            child: Row(
              children: [
                Icon(icon, color: MoolColors.navy),
                const SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MoolColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? MoolColors.success : MoolColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MoolColors.success, size: 19),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showResult(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _showShareSheet(BuildContext context, BuyProduct product) async {
  final pageContext = context;
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Share ${product.name}',
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          for (final option in const [
            ('chat', Icons.chat_bubble_outline_rounded, 'MoolSocial Chat'),
            ('link', Icons.link_rounded, 'Copy product link'),
            ('more', Icons.ios_share_rounded, 'More apps'),
          ])
            ListTile(
              key: Key('buy-share-${option.$1}'),
              leading: Icon(option.$2, color: MoolColors.navy),
              title: Text(option.$3),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showResult(pageContext, '${option.$3} selected.');
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _showStoreChoice(BuildContext context, BuySession session) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Collect from which store?',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Choose collection only when you plan to visit the store.',
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.tonal(
            key: const Key('buy-product-pick-mahadev'),
            onPressed: () {
              session.chooseStorePickup('Mahadev Fresh Mart · Sardarpura');
              Navigator.of(context).pop();
            },
            child: const Text('Mahadev Fresh Mart · 15–20 min'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          OutlinedButton(
            key: const Key('buy-product-cancel-pickup'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}
