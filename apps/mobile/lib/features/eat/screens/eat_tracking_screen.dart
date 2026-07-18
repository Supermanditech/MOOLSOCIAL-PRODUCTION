import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatTrackingScreen extends StatelessWidget {
  const EatTrackingScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final EatSession session;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final receipt = session.orderReceipt;
        if (receipt == null || receipt.id != orderId) {
          return EatPageScaffold(
            key: const Key('eat-order-missing-screen'),
            session: session,
            title: 'Order not found',
            subtitle: 'Start a new food order',
            activeDock: 'order',
            body: Center(
              child: FilledButton(
                key: const Key('eat-order-missing-return'),
                onPressed: () => context.go('/app/eat/order'),
                child: const Text('Choose food'),
              ),
            ),
          );
        }
        final cancelled = session.foodOrderCancelled;
        final delivered = session.orderStage == EatOrderStage.delivered;
        return EatPageScaffold(
          key: const Key('eat-tracking-screen'),
          session: session,
          title: cancelled ? 'Order cancelled' : session.orderStage.title,
          subtitle: '${receipt.id} · ${receipt.restaurant.name}',
          activeDock: 'order',
          fallbackBackRoute: '/app/eat/home',
          trailing: IconButton.outlined(
            key: const Key('eat-refresh-order'),
            tooltip: 'Refresh order status',
            onPressed: session.refreshFoodOrder,
            icon: const Icon(Icons.refresh_rounded),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              EatSurfaceCard(
                color: cancelled
                    ? const Color(0xFFFFF2E8)
                    : const Color(0xFFEDEEFF),
                child: Column(
                  children: [
                    Icon(
                      cancelled
                          ? Icons.cancel_outlined
                          : delivered
                          ? Icons.check_circle_rounded
                          : Icons.delivery_dining_rounded,
                      size: 54,
                      color: cancelled
                          ? const Color(0xFFB54708)
                          : MoolColors.navy,
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      cancelled
                          ? 'Refund is being processed'
                          : session.orderStage.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cancelled
                          ? 'No further preparation or delivery will happen.'
                          : session.orderStage.detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: MoolColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              _OrderProgress(active: session.orderStage, cancelled: cancelled),
              const SizedBox(height: MoolSpacing.sm),
              EatSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.fulfilment.label,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      receipt.promise,
                      style: const TextStyle(
                        color: MoolColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      receipt.deliveryAddress,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Paid total',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          eatMoney(receipt.total),
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('eat-order-support'),
                      onPressed: () => context.go(
                        '/app/chat/thread/order-support?return=/app/eat/order/$orderId',
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Support'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('eat-order-call-rider'),
                      onPressed: () => session.showNotice(
                        'Calling your rider through a masked number.',
                      ),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Call rider'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.xs),
              if (!cancelled && session.orderStage == EatOrderStage.confirmed)
                TextButton(
                  key: const Key('eat-cancel-order'),
                  onPressed: () => _confirmCancel(context, session),
                  child: const Text('Cancel order before preparation'),
                ),
              if (delivered && !cancelled)
                FilledButton(
                  key: const Key('eat-complete-order'),
                  onPressed: () =>
                      context.go('/app/eat/order/$orderId/completed'),
                  child: const Text('Confirm delivery and rate meal'),
                ),
              if (cancelled)
                FilledButton(
                  key: const Key('eat-order-again-after-cancel'),
                  onPressed: () {
                    session.startNewFoodOrder();
                    context.go('/app/eat/order');
                  },
                  child: const Text('Start a new order'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.active, required this.cancelled});

  final EatOrderStage active;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        children: EatOrderStage.values.map((stage) {
          final reached = !cancelled && stage.index <= active.index;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(
                  reached
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: reached ? MoolColors.success : MoolColors.muted,
                  size: 21,
                ),
                const SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: Text(
                    stage.title,
                    style: TextStyle(
                      color: reached ? MoolColors.ink : MoolColors.muted,
                      fontWeight: reached ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

Future<void> _confirmCancel(BuildContext context, EatSession session) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel this order?'),
      content: const Text(
        'The restaurant has not started preparation. Your paid amount will be refunded.',
      ),
      actions: [
        TextButton(
          key: const Key('eat-cancel-order-keep'),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep order'),
        ),
        FilledButton(
          key: const Key('eat-cancel-order-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cancel order'),
        ),
      ],
    ),
  );
  if (confirmed == true) session.cancelFoodOrder();
}
