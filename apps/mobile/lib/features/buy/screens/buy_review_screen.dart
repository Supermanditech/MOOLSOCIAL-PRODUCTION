import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyReviewScreen extends StatelessWidget {
  const BuyReviewScreen({required this.session, super.key});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final empty = session.cartLines.isEmpty;
        return BuyPageScaffold(
          key: const Key('buy-review-screen'),
          session: session,
          title: 'Review and pay',
          subtitle: empty
              ? 'Your basket needs a product'
              : 'Final total ${buyMoney(session.total)}',
          activeDock: 'basket',
          fallbackBackRoute: '/app/buy/basket',
          body: empty
              ? _EmptyReview(onReturn: () => context.go('/app/buy/basket'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    MoolSpacing.xs,
                    MoolSpacing.md,
                    MoolSpacing.xxl,
                  ),
                  children: [
                    _OrderItems(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    _DeliverySummary(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    _PaymentMethods(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    BuyPriceSummary(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    const BuySurfaceCard(
                      color: Color(0xFFEAF7E8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: MoolColors.success,
                          ),
                          SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: Text(
                              'You see the final total before payment. Failed payments do not create an order, and no duplicate charge is sent on retry.',
                              style: TextStyle(
                                color: Color(0xFF155B17),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          bottomAction: empty
              ? null
              : FilledButton(
                  key: const Key('buy-place-order'),
                  onPressed: session.busy
                      ? null
                      : () async {
                          final placed = await session.placeOrder();
                          if (placed && context.mounted) {
                            final receipt = session.receipt!;
                            final route =
                                receipt.fulfilment == BuyFulfilment.storePickup
                                ? '/app/buy/order/${receipt.id}/collection'
                                : '/app/buy/order/${receipt.id}';
                            context.go(route);
                          }
                        },
                  child: session.busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '${_paymentVerb(session.paymentMethod)} '
                          '${buyMoney(session.total)}',
                        ),
                ),
        );
      },
    );
  }
}

String _paymentVerb(BuyPaymentMethod method) {
  return method == BuyPaymentMethod.cashOnDelivery ? 'Place order ·' : 'Pay';
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.remove_shopping_cart_outlined,
              size: 52,
              color: MoolColors.muted,
            ),
            const SizedBox(height: MoolSpacing.md),
            const Text(
              'Nothing to review yet',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Add at least one product before reviewing payment.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoolSpacing.lg),
            FilledButton(
              key: const Key('buy-review-return-basket'),
              onPressed: onReturn,
              child: const Text('Return to basket'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItems extends StatelessWidget {
  const _OrderItems({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Order items',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                key: const Key('buy-review-edit-basket'),
                onPressed: () => context.go('/app/buy/basket'),
                child: const Text('Edit'),
              ),
            ],
          ),
          for (final line in session.cartLines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEEFF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${line.quantity}',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          line.product.unitLabel,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    buyMoney(line.total),
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliverySummary extends StatelessWidget {
  const _DeliverySummary({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final home = session.fulfilment == BuyFulfilment.homeDelivery;
    return BuySurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            home ? Icons.home_outlined : Icons.storefront_outlined,
            color: MoolColors.navy,
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.fulfilment.label,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.address,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
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
          ),
          TextButton(
            key: const Key('buy-review-edit-delivery'),
            onPressed: () => context.go('/app/buy/basket'),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment method',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          for (final method in BuyPaymentMethod.values)
            _PaymentChoice(
              key: Key('buy-payment-${method.name}'),
              method: method,
              selected: session.paymentMethod == method,
              onTap: () => session.choosePaymentMethod(method),
            ),
        ],
      ),
    );
  }
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.method,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final BuyPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
      child: Material(
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
                  Icon(_paymentIcon(method), color: MoolColors.navy),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Text(
                      method.label,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
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
      ),
    );
  }
}

IconData _paymentIcon(BuyPaymentMethod method) => switch (method) {
  BuyPaymentMethod.upi => Icons.qr_code_rounded,
  BuyPaymentMethod.wallet => Icons.account_balance_wallet_outlined,
  BuyPaymentMethod.card => Icons.credit_card_rounded,
  BuyPaymentMethod.cashOnDelivery => Icons.payments_outlined,
};
