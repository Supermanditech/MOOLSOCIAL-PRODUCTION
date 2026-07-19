import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';

class RetailerOrderScreen extends StatefulWidget {
  const RetailerOrderScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final RetailerSession session;
  final String orderId;

  @override
  State<RetailerOrderScreen> createState() => _RetailerOrderScreenState();
}

class _RetailerOrderScreenState extends State<RetailerOrderScreen> {
  @override
  void initState() {
    super.initState();
    widget.session.ensureOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final order = widget.session.selectedOrder;
        if (order == null) {
          return RetailerPageScaffold(
            session: widget.session,
            title: 'Order unavailable',
            subtitle: widget.orderId,
            activeDock: 'orders',
            returnRoute: '/app/retailer/orders',
            body: ListView(
              padding: const EdgeInsets.all(MoolSpacing.md),
              children: [
                RetailerEmptyState(
                  keyName: 'retailer-order-missing',
                  title: 'Order not found',
                  detail:
                      'Return to current orders and choose an available order.',
                  actionLabel: 'Open orders',
                  onAction: () => context.go('/app/retailer/orders'),
                ),
              ],
            ),
          );
        }
        return RetailerPageScaffold(
          session: widget.session,
          title: 'Order ${order.id}',
          subtitle: '${order.fulfilment} · ${order.stage.label}',
          activeDock: 'orders',
          returnRoute: '/app/retailer/orders',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                key: const Key('retailer-order-book'),
                tooltip: 'Open Business Book',
                onPressed: widget.session.openBusinessBook,
                icon: const Icon(Icons.auto_stories_outlined),
              ),
              const SizedBox(width: MoolSpacing.xxs),
              IconButton.outlined(
                key: const Key('retailer-order-alerts'),
                tooltip: 'Open order alerts',
                onPressed: () => widget.session.showNotice(
                  '${order.deliveryPromise}. Accept only if every item can be packed.',
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          bottomAction: _bottomAction(context, order),
          body: ListView(
            key: const Key('retailer-order-review-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              RetailerCard(
                color: MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final amount = Text(
                          '₹${order.amount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        );
                        final stage = RetailerPill(
                          label: order.stage.label,
                          color: order.stage == RetailerOrderStage.delivered
                              ? const Color(0xFF9EE89B)
                              : MoolColors.orange,
                        );
                        final enlargedText =
                            MediaQuery.textScalerOf(context).scale(10) > 11.5;
                        if (constraints.maxWidth < 320 || enlargedText) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              stage,
                              const SizedBox(height: MoolSpacing.xxs),
                              amount,
                            ],
                          );
                        }
                        return Row(children: [stage, const Spacer(), amount]);
                      },
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      order.customer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${order.area}\n${order.payment}',
                      style: const TextStyle(
                        color: Color(0xFFD9DAFF),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(MoolSpacing.xs),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(MoolRadii.control),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: MoolColors.orange,
                          ),
                          const SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: Text(
                              order.deliveryPromise,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              _ResponsiveTwoActions(
                first: OutlinedButton.icon(
                  key: const Key('retailer-message-customer'),
                  onPressed: () {
                    widget.session.contactCustomer('message');
                    context.go(
                      Uri(
                        path: '/app/chat/thread/mahadev-business',
                        queryParameters: {
                          'return': '/app/retailer/orders/${order.id}',
                        },
                      ).toString(),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message'),
                ),
                second: OutlinedButton.icon(
                  key: const Key('retailer-call-customer'),
                  onPressed: () => _confirmCustomerCall(context),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerSectionTitle(
                title: '${order.lines.length} checked groups',
                detail:
                    '${order.lines.fold<int>(0, (sum, line) => sum + line.quantity)} product units · tap each group while packing',
                trailing: TextButton(
                  key: const Key('retailer-toggle-order-lines'),
                  onPressed: widget.session.toggleOrderLines,
                  child: Text(
                    widget.session.orderLinesExpanded ? 'Hide' : 'Show all',
                  ),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final line
                  in (widget.session.orderLinesExpanded
                      ? order.lines
                      : order.lines.take(3))) ...[
                _OrderLineTile(
                  line: line,
                  packing: order.stage == RetailerOrderStage.packing,
                  onTap: () => widget.session.togglePackedLine(line.id),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              if (!widget.session.orderLinesExpanded && order.lines.length > 3)
                TextButton(
                  key: const Key('retailer-show-remaining-lines'),
                  onPressed: widget.session.toggleOrderLines,
                  child: Text('Show ${order.lines.length - 3} remaining group'),
                ),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                color: const Color(0xFFEAF7E8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Before you accept',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    _CheckRow(label: 'Payment status', value: order.payment),
                    _CheckRow(label: 'Fulfilment', value: order.fulfilment),
                    _CheckRow(
                      label: 'Customer promise',
                      value: order.deliveryPromise,
                    ),
                    const _CheckRow(
                      label: 'Refund rule',
                      value: 'Refund if the retailer cannot fulfil',
                    ),
                  ],
                ),
              ),
              if (order.stage == RetailerOrderStage.cannotFulfil) ...[
                const SizedBox(height: MoolSpacing.md),
                RetailerCard(
                  keyName: 'retailer-cannot-fulfil-result',
                  color: const Color(0xFFFFEBEA),
                  child: Text(
                    'Order not fulfilled: ${order.cannotFulfilReason}. Customer refund is open and stock was not reduced.',
                    style: const TextStyle(
                      color: Color(0xFF7A271A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _bottomAction(BuildContext context, RetailerOrder order) {
    return switch (order.stage) {
      RetailerOrderStage.newOrder => _ResponsiveTwoActions(
        first: OutlinedButton(
          key: const Key('retailer-cannot-fulfil'),
          onPressed: widget.session.busy
              ? null
              : () => _showCannotFulfil(context),
          child: const Text('Cannot fulfil'),
        ),
        second: RetailerPrimaryButton(
          keyName: 'retailer-accept-order',
          label: 'Accept order',
          busy: widget.session.busy,
          onPressed: widget.session.acceptSelectedOrder,
          icon: Icons.check_rounded,
        ),
      ),
      RetailerOrderStage.accepted => RetailerPrimaryButton(
        keyName: 'retailer-start-packing',
        label: 'Start packing',
        onPressed: widget.session.startPacking,
        icon: Icons.inventory_2_outlined,
      ),
      RetailerOrderStage.packing => RetailerPrimaryButton(
        keyName: 'retailer-mark-order-packed',
        label: 'Mark order packed (${order.packedCount}/${order.lines.length})',
        busy: widget.session.busy,
        onPressed: widget.session.markOrderPacked,
        icon: Icons.checklist_rounded,
      ),
      RetailerOrderStage.packed => RetailerPrimaryButton(
        keyName: 'retailer-request-delivery',
        label: 'Request delivery',
        busy: widget.session.busy,
        onPressed: () async {
          if (await widget.session.requestDelivery() && context.mounted) {
            context.go('/app/retailer/orders/${order.id}/delivery');
          }
        },
        icon: Icons.delivery_dining_rounded,
      ),
      RetailerOrderStage.deliveryRequested ||
      RetailerOrderStage.captainAssigned ||
      RetailerOrderStage.parcelReady ||
      RetailerOrderStage.captainArrived ||
      RetailerOrderStage.handoverVerified ||
      RetailerOrderStage.handedOver ||
      RetailerOrderStage.outForDelivery ||
      RetailerOrderStage.nearby => RetailerPrimaryButton(
        keyName: 'retailer-continue-delivery',
        label: 'Continue delivery',
        onPressed: () =>
            context.go('/app/retailer/orders/${order.id}/delivery'),
        icon: Icons.delivery_dining_rounded,
      ),
      RetailerOrderStage.delivered => RetailerPrimaryButton(
        keyName: 'retailer-open-delivery-result',
        label: 'Open delivery result',
        onPressed: () =>
            context.go('/app/retailer/orders/${order.id}/tracking'),
        icon: Icons.receipt_long_rounded,
      ),
      RetailerOrderStage.cannotFulfil => RetailerPrimaryButton(
        keyName: 'retailer-return-orders',
        label: 'Return to orders',
        onPressed: () => context.go('/app/retailer/orders'),
        icon: Icons.arrow_back_rounded,
      ),
    };
  }

  Future<void> _confirmCustomerCall(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Call customer?'),
        content: const Text(
          'MoolSocial uses a masked number. Your personal number is not shared.',
        ),
        actions: [
          TextButton(
            key: const Key('retailer-call-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('retailer-call-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Start masked call'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.session.contactCustomer('call');
  }

  Future<void> _showCannotFulfil(BuildContext context) {
    const reasons = [
      'Required product is unavailable',
      'Product quality check failed',
      'Customer requested cancellation',
      'Delivery promise cannot be met',
    ];
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
            ),
            child: Column(
              key: const Key('retailer-cannot-fulfil-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why can’t this order be fulfilled?',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'The customer sees the selected reason and the refund path starts only after confirmation.',
                  style: TextStyle(color: MoolColors.muted),
                ),
                const SizedBox(height: MoolSpacing.sm),
                RadioGroup<String>(
                  groupValue: widget.session.selectedCannotFulfilReason,
                  onChanged: (value) {
                    if (value != null) {
                      widget.session.chooseCannotFulfilReason(value);
                    }
                  },
                  child: Column(
                    children: [
                      for (var index = 0; index < reasons.length; index += 1)
                        RadioListTile<String>(
                          key: Key('retailer-cannot-reason-$index'),
                          value: reasons[index],
                          title: Text(reasons[index]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('retailer-cannot-cancel'),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Keep order open'),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: FilledButton(
                        key: const Key('retailer-cannot-confirm'),
                        onPressed: widget.session.busy
                            ? null
                            : () async {
                                final completed = await widget.session
                                    .submitCannotFulfil();
                                if (completed && sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderLineTile extends StatelessWidget {
  const _OrderLineTile({
    required this.line,
    required this.packing,
    required this.onTap,
  });

  final RetailerOrderLine line;
  final bool packing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      keyName: 'retailer-pack-${line.id}',
      onTap: packing ? onTap : null,
      color: line.packed ? const Color(0xFFEAF7E8) : Colors.white,
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: line.packed
                ? MoolColors.success
                : const Color(0xFFEDEEFF),
            foregroundColor: line.packed ? Colors.white : MoolColors.navy,
            child: Icon(
              line.packed ? Icons.check_rounded : Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${line.detail} · Qty ${line.quantity} · ₹${line.amount}',
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (packing)
            Icon(
              line.packed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: line.packed ? MoolColors.success : MoolColors.muted,
            ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: MoolColors.success,
            size: 18,
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w800,
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

class _ResponsiveTwoActions extends StatelessWidget {
  const _ResponsiveTwoActions({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              const SizedBox(height: MoolSpacing.xs),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
