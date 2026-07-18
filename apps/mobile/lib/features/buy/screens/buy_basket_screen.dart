import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyBasketScreen extends StatelessWidget {
  const BuyBasketScreen({required this.session, super.key});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final empty = session.cartLines.isEmpty;
        return BuyPageScaffold(
          key: const Key('buy-basket-screen'),
          session: session,
          title: 'Your basket',
          subtitle: empty
              ? 'Add products to continue'
              : '${session.itemCount} '
                    '${session.itemCount == 1 ? 'item' : 'items'} · '
                    '${buyMoney(session.total)}',
          activeDock: 'basket',
          fallbackBackRoute: '/app/buy/grocery',
          trailing: IconButton.outlined(
            key: const Key('buy-apply-coupon'),
            tooltip: 'Apply coupon',
            onPressed: empty ? null : () => _showCouponSheet(context, session),
            icon: const Icon(Icons.local_offer_outlined),
          ),
          body: empty
              ? _EmptyBasket(onBrowse: () => context.go('/app/buy/grocery'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    MoolSpacing.xs,
                    MoolSpacing.md,
                    MoolSpacing.xxl,
                  ),
                  children: [
                    for (final line in session.cartLines) ...[
                      _BasketLine(line: line, session: session),
                      const SizedBox(height: MoolSpacing.sm),
                    ],
                    _DeliveryChoice(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    _DeliveryTime(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    _UnavailableItems(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    if (session.couponCode != null) ...[
                      _CouponApplied(session: session),
                      const SizedBox(height: MoolSpacing.sm),
                    ],
                    BuyPriceSummary(session: session),
                  ],
                ),
          bottomAction: empty
              ? null
              : FilledButton(
                  key: const Key('buy-review-order'),
                  onPressed: () => context.go('/app/buy/review'),
                  child: Text('Review order · ${buyMoney(session.total)}'),
                ),
        );
      },
    );
  }
}

class _EmptyBasket extends StatelessWidget {
  const _EmptyBasket({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFEDEEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: MoolColors.navy,
                size: 38,
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const Text(
              'Your basket is empty',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Choose a product and it will appear here with its final price and delivery promise.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoolSpacing.lg),
            FilledButton(
              key: const Key('buy-empty-browse'),
              onPressed: onBrowse,
              child: const Text('Choose products'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketLine extends StatelessWidget {
  const _BasketLine({required this.line, required this.session});

  final BuyCartLine line;
  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Row(
        children: [
          Container(
            width: 62,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F3E4),
              borderRadius: BorderRadius.circular(MoolRadii.control),
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: MoolColors.navy,
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${line.product.unitLabel} · ${line.product.seller}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
                const SizedBox(height: MoolSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        buyMoney(line.total),
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    BuyQuantityControl(
                      productId: line.product.id,
                      quantity: line.quantity,
                      onDecrease: () => session.decrease(line.product.id),
                      onIncrease: () => session.increase(line.product.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('buy-remove-${line.product.id}'),
            tooltip: 'Remove ${line.product.name}',
            onPressed: () => session.remove(line.product.id),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _DeliveryChoice extends StatelessWidget {
  const _DeliveryChoice({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final home = session.fulfilment == BuyFulfilment.homeDelivery;
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                home ? Icons.home_outlined : Icons.storefront_outlined,
                color: MoolColors.navy,
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  home ? 'Deliver to home' : 'Collect from store',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                key: const Key('buy-basket-change-fulfilment'),
                onPressed: () => _showFulfilmentSheet(context, session),
                child: const Text('Change'),
              ),
            ],
          ),
          Text(
            home ? session.address : session.pickupStore ?? session.address,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTime extends StatelessWidget {
  const _DeliveryTime({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final options = session.fulfilment == BuyFulfilment.homeDelivery
        ? const [
            'Deliver in 22–35 min',
            'Deliver in 60–90 min',
            'Deliver this evening',
          ]
        : const [
            'Ready to collect in 15–20 min',
            'Ready to collect in 45–60 min',
          ];
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose delivery time',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          RadioGroup<String>(
            groupValue: session.deliveryPromise,
            onChanged: (value) {
              if (value != null) session.chooseDeliveryPromise(value);
            },
            child: Column(
              children: [
                for (var index = 0; index < options.length; index++)
                  RadioListTile<String>(
                    key: Key('buy-delivery-time-$index'),
                    value: options[index],
                    title: Text(
                      options[index],
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableItems extends StatelessWidget {
  const _UnavailableItems({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    const labels = {
      UnavailableItemRule.askBeforeReplacing: 'Ask before replacing it',
      UnavailableItemRule.allowSimilarItem: 'Allow a similar item',
      UnavailableItemRule.remove: 'Remove it and refund me',
    };
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'If an item becomes unavailable',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          RadioGroup<UnavailableItemRule>(
            groupValue: session.unavailableItemRule,
            onChanged: (value) {
              if (value != null) session.chooseUnavailableRule(value);
            },
            child: Column(
              children: [
                for (final rule in UnavailableItemRule.values)
                  RadioListTile<UnavailableItemRule>(
                    key: Key('buy-unavailable-${rule.name}'),
                    value: rule,
                    title: Text(
                      labels[rule]!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponApplied extends StatelessWidget {
  const _CouponApplied({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      color: const Color(0xFFEAF7E8),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: MoolColors.success),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Text(
              '${session.couponCode} applied · ${buyMoney(session.discount)} saved',
              style: const TextStyle(
                color: Color(0xFF155B17),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            key: const Key('buy-remove-coupon'),
            onPressed: session.removeCoupon,
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCouponSheet(BuildContext context, BuySession session) async {
  var coupon = '';
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Apply a coupon',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text('Enter the code exactly as you received it.'),
          const SizedBox(height: MoolSpacing.md),
          TextFormField(
            key: const Key('buy-coupon-field'),
            onChanged: (value) => coupon = value,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Coupon code',
              hintText: 'For example MOOL50',
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton(
            key: const Key('buy-submit-coupon'),
            onPressed: () {
              if (session.applyCoupon(coupon)) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Apply coupon'),
          ),
          TextButton(
            key: const Key('buy-cancel-coupon'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showFulfilmentSheet(
  BuildContext context,
  BuySession session,
) async {
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
            'How should you receive this order?',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.tonalIcon(
            key: const Key('buy-basket-home-delivery'),
            onPressed: () {
              session.chooseHomeDelivery();
              Navigator.of(context).pop();
              _editAddress(context, session);
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Deliver to home'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          OutlinedButton.icon(
            key: const Key('buy-basket-store-pickup'),
            onPressed: () {
              session.chooseStorePickup('Mahadev Fresh Mart · Sardarpura');
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Collect at Mahadev Fresh Mart'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          TextButton(
            key: const Key('buy-basket-cancel-fulfilment'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _editAddress(BuildContext context, BuySession session) async {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Confirm your delivery address',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          TextFormField(
            key: const Key('buy-basket-address-field'),
            initialValue: address,
            onChanged: (value) => address = value,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Complete address'),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton(
            key: const Key('buy-basket-save-address'),
            onPressed: () {
              if (session.updateAddress(address)) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Use this address'),
          ),
        ],
      ),
    ),
  );
}
