import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatReviewScreen extends StatelessWidget {
  const EatReviewScreen({required this.session, super.key});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final empty = session.cartLines.isEmpty;
        return EatPageScaffold(
          key: const Key('eat-review-screen'),
          session: session,
          title: 'Review and pay',
          subtitle: empty
              ? 'Add food before payment'
              : 'Final total ${eatMoney(session.orderTotal)}',
          activeDock: 'order',
          fallbackBackRoute: '/app/eat/basket',
          body: empty
              ? Center(
                  child: FilledButton(
                    key: const Key('eat-review-return'),
                    onPressed: () => context.go('/app/eat/order'),
                    child: const Text('Choose food'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    MoolSpacing.xs,
                    MoolSpacing.md,
                    MoolSpacing.xxl,
                  ),
                  children: [
                    EatSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  session.selectedRestaurant.name,
                                  style: const TextStyle(
                                    color: MoolColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const Key('eat-review-edit-items'),
                                onPressed: () => context.go('/app/eat/basket'),
                                child: const Text('Edit'),
                              ),
                            ],
                          ),
                          for (final line in session.cartLines)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${line.quantity} × ${line.item.name}',
                                      style: const TextStyle(
                                        color: MoolColors.muted,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    eatMoney(line.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    EatSurfaceCard(
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
                          Text(
                            session.fulfilmentPromise,
                            style: const TextStyle(
                              color: MoolColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (session.fulfilment == EatFulfilment.delivery ||
                              session.fulfilment == EatFulfilment.scheduled)
                            Text(
                              session.deliveryAddress,
                              style: const TextStyle(
                                color: MoolColors.muted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _PaymentMethods(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    EatPriceSummary(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    const EatSurfaceCard(
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
                              'A failed payment creates no order and deducts no money. Retrying sends one new request only.',
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
                  key: const Key('eat-place-order'),
                  onPressed: session.busy
                      ? null
                      : () async {
                          final placed = await session.placeFoodOrder();
                          if (placed && context.mounted) {
                            context.go(
                              '/app/eat/order/${session.orderReceipt!.id}',
                            );
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
                      : Text('Pay ${eatMoney(session.orderTotal)}'),
                ),
        );
      },
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({required this.session});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
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
          for (final method in EatPaymentMethod.values)
            Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
              child: Material(
                color: session.paymentMethod == method
                    ? const Color(0xFFEDEEFF)
                    : const Color(0xFFF5F6FC),
                borderRadius: BorderRadius.circular(MoolRadii.control),
                child: InkWell(
                  key: Key('eat-payment-${method.name}'),
                  onTap: () => session.choosePaymentMethod(method),
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
                            session.paymentMethod == method
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: session.paymentMethod == method
                                ? MoolColors.success
                                : MoolColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

IconData _paymentIcon(EatPaymentMethod method) => switch (method) {
  EatPaymentMethod.upi => Icons.qr_code_rounded,
  EatPaymentMethod.wallet => Icons.account_balance_wallet_outlined,
  EatPaymentMethod.card => Icons.credit_card_rounded,
  EatPaymentMethod.payAtHandoff => Icons.payments_outlined,
};
