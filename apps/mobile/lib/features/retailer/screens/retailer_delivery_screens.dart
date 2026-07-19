import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';

class RetailerDeliveryAssignmentScreen extends StatefulWidget {
  const RetailerDeliveryAssignmentScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final RetailerSession session;
  final String orderId;

  @override
  State<RetailerDeliveryAssignmentScreen> createState() =>
      _RetailerDeliveryAssignmentScreenState();
}

class _RetailerDeliveryAssignmentScreenState
    extends State<RetailerDeliveryAssignmentScreen> {
  final _otp = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.session.selectedOrderId != widget.orderId) {
      widget.session.ensureOrder(widget.orderId);
    }
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final order = widget.session.selectedOrder;
        if (order == null) {
          return _MissingDeliveryOrder(
            session: widget.session,
            orderId: widget.orderId,
          );
        }
        return RetailerPageScaffold(
          session: widget.session,
          title: 'Delivery handover',
          subtitle: '${order.id} · ${order.stage.label}',
          activeDock: 'orders',
          returnRoute: '/app/retailer/orders/${order.id}',
          trailing: IconButton.outlined(
            key: const Key('retailer-delivery-alerts'),
            tooltip: 'Open delivery alerts',
            onPressed: () => widget.session.showNotice(
              'Keep the sealed parcel until the assigned captain and handover OTP both match.',
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          bottomAction: _bottomAction(context, order),
          body: ListView(
            key: const Key('retailer-delivery-assignment-screen'),
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
                    RetailerPill(
                      label: order.stage.label,
                      color: MoolColors.orange,
                      icon: Icons.delivery_dining_rounded,
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const Text(
                      '₹0 before completed delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'The shop is charged only after the customer delivery proof is accepted.',
                      style: TextStyle(color: Color(0xFFD9DAFF), height: 1.4),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _DarkInfoRow(
                      label: 'Delivery reference',
                      value: order.deliveryReference ?? 'Assignment pending',
                    ),
                    _DarkInfoRow(
                      label: 'Customer promise',
                      value: order.deliveryPromise,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Assigned captain',
                detail: 'Match both identity and vehicle before OTP',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFFEDEEFF),
                          foregroundColor: MoolColors.navy,
                          child: Text(
                            'RK',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.captainName ?? 'Finding captain',
                                style: const TextStyle(
                                  color: MoolColors.ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                order.captainVehicle ??
                                    'Vehicle appears after assignment',
                                style: const TextStyle(color: MoolColors.muted),
                              ),
                              const Text(
                                'Verified delivery partner · 4.9 ★',
                                style: TextStyle(
                                  color: MoolColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const RetailerPill(label: 'Matched'),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('retailer-message-captain'),
                            onPressed: () => context.go(
                              Uri(
                                path: '/app/chat/thread/ride-support',
                                queryParameters: {
                                  'return':
                                      '/app/retailer/orders/${order.id}/delivery',
                                },
                              ).toString(),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Message', maxLines: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('retailer-call-captain'),
                            onPressed: () => _confirmCaptainCall(context),
                            icon: const Icon(Icons.call_outlined),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Call', maxLines: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Safe handover',
                detail: 'Each step must be completed in order',
              ),
              const SizedBox(height: MoolSpacing.sm),
              _HandoverStep(
                label: 'Parcel sealed and ready',
                done: order.stage.index >= RetailerOrderStage.parcelReady.index,
              ),
              _HandoverStep(
                label: 'Assigned captain at shop',
                done:
                    order.stage.index >=
                    RetailerOrderStage.captainArrived.index,
              ),
              _HandoverStep(
                label: 'Captain OTP verified',
                done:
                    order.stage.index >=
                    RetailerOrderStage.handoverVerified.index,
              ),
              _HandoverStep(
                label: 'Parcel handover recorded',
                done: order.stage.index >= RetailerOrderStage.handedOver.index,
              ),
              if (widget.session.handoverOtpVisible) ...[
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  keyName: 'retailer-handover-otp-card',
                  color: const Color(0xFFFFF4E5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter captain handover OTP',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'For this reviewed journey use 2841.',
                        style: TextStyle(color: MoolColors.muted, fontSize: 11),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      TextField(
                        key: const Key('retailer-handover-otp'),
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: '4-digit OTP',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      FilledButton(
                        key: const Key('retailer-verify-handover-otp'),
                        onPressed: () =>
                            widget.session.verifyHandoverOtp(_otp.text),
                        child: const Text('Verify captain'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.md),
              OutlinedButton.icon(
                key: const Key('retailer-delivery-issue'),
                onPressed: () =>
                    showRetailerDeliveryIssue(context, session: widget.session),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Report delivery issue'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomAction(BuildContext context, RetailerOrder order) {
    return switch (order.stage) {
      RetailerOrderStage.captainAssigned => RetailerPrimaryButton(
        keyName: 'retailer-parcel-ready',
        label: 'Parcel ready',
        onPressed: widget.session.markParcelReady,
        icon: Icons.inventory_2_outlined,
      ),
      RetailerOrderStage.parcelReady => RetailerPrimaryButton(
        keyName: 'retailer-captain-here',
        label: 'Captain is here',
        onPressed: widget.session.markCaptainArrived,
        icon: Icons.person_pin_circle_outlined,
      ),
      RetailerOrderStage.captainArrived => RetailerPrimaryButton(
        keyName: 'retailer-confirm-handover',
        label: 'Confirm handover',
        onPressed: widget.session.beginHandoverVerification,
        icon: Icons.password_rounded,
      ),
      RetailerOrderStage.handoverVerified => RetailerPrimaryButton(
        keyName: 'retailer-hand-over-parcel',
        label: 'Hand over parcel',
        busy: widget.session.busy,
        onPressed: widget.session.handOverParcel,
        icon: Icons.handshake_outlined,
      ),
      RetailerOrderStage.handedOver => RetailerPrimaryButton(
        keyName: 'retailer-track-delivery',
        label: 'Track delivery',
        onPressed: () {
          widget.session.openTracking();
          context.go('/app/retailer/orders/${order.id}/tracking');
        },
        icon: Icons.location_searching_rounded,
      ),
      RetailerOrderStage.outForDelivery ||
      RetailerOrderStage.nearby ||
      RetailerOrderStage.delivered => RetailerPrimaryButton(
        keyName: 'retailer-open-live-tracking',
        label: order.stage == RetailerOrderStage.delivered
            ? 'Open delivery result'
            : 'Open live tracking',
        onPressed: () =>
            context.go('/app/retailer/orders/${order.id}/tracking'),
        icon: Icons.location_searching_rounded,
      ),
      _ => RetailerPrimaryButton(
        keyName: 'retailer-return-order',
        label: 'Return to order',
        onPressed: () => context.go('/app/retailer/orders/${order.id}'),
        icon: Icons.arrow_back_rounded,
      ),
    };
  }

  Future<void> _confirmCaptainCall(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Call captain?'),
        content: const Text(
          'A masked call keeps the shop and captain numbers private.',
        ),
        actions: [
          TextButton(
            key: const Key('retailer-captain-call-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('retailer-captain-call-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Start masked call'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.session.showNotice(
        'Masked captain call is ready. The order remains on this screen.',
      );
    }
  }
}

class RetailerDeliveryTrackingScreen extends StatefulWidget {
  const RetailerDeliveryTrackingScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final RetailerSession session;
  final String orderId;

  @override
  State<RetailerDeliveryTrackingScreen> createState() =>
      _RetailerDeliveryTrackingScreenState();
}

class _RetailerDeliveryTrackingScreenState
    extends State<RetailerDeliveryTrackingScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.session.selectedOrderId != widget.orderId) {
      widget.session.ensureOrder(widget.orderId);
    }
    widget.session.ensureTrackingOpen();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final order = widget.session.selectedOrder;
        if (order == null) {
          return _MissingDeliveryOrder(
            session: widget.session,
            orderId: widget.orderId,
          );
        }
        final delivered = order.stage == RetailerOrderStage.delivered;
        return RetailerPageScaffold(
          session: widget.session,
          title: delivered ? 'Delivery complete' : 'Live delivery',
          subtitle: '${order.id} · ${order.stage.label}',
          activeDock: 'orders',
          returnRoute: '/app/retailer/orders/${order.id}/delivery',
          trailing: IconButton.outlined(
            key: const Key('retailer-tracking-book'),
            tooltip: 'Open Business Book',
            onPressed: widget.session.openBusinessBook,
            icon: const Icon(Icons.auto_stories_outlined),
          ),
          bottomAction: delivered
              ? RetailerPrimaryButton(
                  keyName: 'retailer-delivery-open-book',
                  label: 'Open Business Book entry',
                  onPressed: widget.session.openBusinessBook,
                  icon: Icons.auto_stories_outlined,
                )
              : RetailerPrimaryButton(
                  keyName: 'retailer-refresh-tracking',
                  label: order.stage == RetailerOrderStage.nearby
                      ? 'Confirm delivery update'
                      : 'Refresh live tracking',
                  busy: widget.session.busy,
                  onPressed: widget.session.refreshTracking,
                  icon: Icons.refresh_rounded,
                ),
          body: ListView(
            key: const Key('retailer-delivery-tracking-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              _TrackingMap(order: order),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                color: delivered ? const Color(0xFFEAF7E8) : MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RetailerPill(
                      label: order.stage.label,
                      color: delivered ? MoolColors.success : MoolColors.orange,
                      icon: delivered
                          ? Icons.check_circle_outline_rounded
                          : Icons.delivery_dining_rounded,
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      delivered
                          ? 'Customer received the order'
                          : order.stage == RetailerOrderStage.nearby
                          ? 'Captain is near the customer'
                          : 'Captain is carrying the sealed parcel',
                      style: TextStyle(
                        color: delivered ? MoolColors.ink : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      delivered
                          ? '${order.deliveryProof}\n₹${order.amount} sale posted to Business Book.'
                          : '${order.captainName} · ${order.captainVehicle}\n${order.deliveryPromise}',
                      style: TextStyle(
                        color: delivered
                            ? MoolColors.muted
                            : const Color(0xFFD9DAFF),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('retailer-tracking-message-captain'),
                      onPressed: delivered
                          ? null
                          : () => context.go(
                              Uri(
                                path: '/app/chat/thread/ride-support',
                                queryParameters: {
                                  'return':
                                      '/app/retailer/orders/${order.id}/tracking',
                                },
                              ).toString(),
                            ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Message', maxLines: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('retailer-tracking-call-captain'),
                      onPressed: delivered
                          ? null
                          : () => widget.session.showNotice(
                              'Masked captain call is ready. Live tracking remains active.',
                            ),
                      icon: const Icon(Icons.call_outlined),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Call', maxLines: 1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Delivery progress',
                detail: 'Each state comes from the existing delivery reference',
              ),
              const SizedBox(height: MoolSpacing.sm),
              _TrackingStep(
                title: 'Parcel handed over',
                detail: order.handoverReference ?? 'Handover reference pending',
                done: true,
              ),
              _TrackingStep(
                title: 'Out for delivery',
                detail: 'Captain left Mahadev Fresh Mart',
                done:
                    order.stage.index >=
                    RetailerOrderStage.outForDelivery.index,
              ),
              _TrackingStep(
                title: 'Near customer',
                detail: 'Customer notification sent',
                done: order.stage.index >= RetailerOrderStage.nearby.index,
              ),
              _TrackingStep(
                title: 'Customer received',
                detail: order.deliveryProof ?? 'Customer proof required',
                done: delivered,
              ),
              if (delivered) ...[
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  keyName: 'retailer-delivery-receipt',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completed order record',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _ReceiptRow(label: 'Order', value: order.id),
                      _ReceiptRow(label: 'Customer', value: order.customer),
                      _ReceiptRow(label: 'Sale', value: '₹${order.amount}'),
                      _ReceiptRow(label: 'Payment', value: order.payment),
                      _ReceiptRow(
                        label: 'Delivery proof',
                        value: order.deliveryProof ?? 'Recorded',
                      ),
                      const Divider(),
                      const Text(
                        'This result can be reconciled in Business Book. A duplicate refresh cannot create another sale.',
                        style: TextStyle(color: MoolColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.md),
              OutlinedButton.icon(
                key: const Key('retailer-tracking-delivery-issue'),
                onPressed: () =>
                    showRetailerDeliveryIssue(context, session: widget.session),
                icon: const Icon(Icons.report_problem_outlined),
                label: Text(
                  delivered
                      ? 'Report completed-delivery issue'
                      : 'Report delivery issue',
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              TextButton(
                key: const Key('retailer-tracking-return-orders'),
                onPressed: () => context.go('/app/retailer/orders'),
                child: const Text('Return to all orders'),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showRetailerDeliveryIssue(
  BuildContext context, {
  required RetailerSession session,
}) {
  const reasons = [
    'Captain has not arrived',
    'Captain or vehicle does not match',
    'Parcel was damaged during delivery',
    'Customer could not be reached',
    'Delivery proof or charge is incorrect',
  ];
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: Column(
            key: const Key('retailer-delivery-issue-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report delivery issue',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'The order, captain, handover and current delivery state are attached automatically.',
                style: TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: MoolSpacing.sm),
              RadioGroup<String>(
                groupValue: session.selectedIssueReason,
                onChanged: (value) {
                  if (value != null) session.chooseIssueReason(value);
                },
                child: Column(
                  children: [
                    for (var index = 0; index < reasons.length; index += 1)
                      RadioListTile<String>(
                        key: Key('retailer-delivery-issue-$index'),
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
                      key: const Key('retailer-delivery-issue-cancel'),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: FilledButton(
                      key: const Key('retailer-delivery-issue-submit'),
                      onPressed: session.busy
                          ? null
                          : () async {
                              final completed = await session
                                  .submitDeliveryIssue();
                              if (completed && sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      child: const Text('Send issue'),
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

class _MissingDeliveryOrder extends StatelessWidget {
  const _MissingDeliveryOrder({required this.session, required this.orderId});

  final RetailerSession session;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return RetailerPageScaffold(
      session: session,
      title: 'Delivery unavailable',
      subtitle: orderId,
      activeDock: 'orders',
      returnRoute: '/app/retailer/orders',
      body: ListView(
        padding: const EdgeInsets.all(MoolSpacing.md),
        children: [
          RetailerEmptyState(
            keyName: 'retailer-delivery-missing',
            title: 'Order not found',
            detail: 'Choose a current delivery from retailer orders.',
            actionLabel: 'Open orders',
            onAction: () => context.go('/app/retailer/orders'),
          ),
        ],
      ),
    );
  }
}

class _DarkInfoRow extends StatelessWidget {
  const _DarkInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: MoolSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFBFC2F7), fontSize: 11),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandoverStep extends StatelessWidget {
  const _HandoverStep({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? MoolColors.success : MoolColors.muted,
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: MoolColors.ink,
                fontWeight: done ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.order});

  final RetailerOrder order;

  @override
  Widget build(BuildContext context) {
    final delivered = order.stage == RetailerOrderStage.delivered;
    return Container(
      key: const Key('retailer-live-map'),
      height: 176,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        borderRadius: BorderRadius.circular(MoolRadii.card),
        border: Border.all(color: MoolColors.line),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _RoutePainter(delivered: delivered)),
          ),
          const Positioned(
            left: 22,
            bottom: 26,
            child: _MapPoint(
              icon: Icons.storefront_outlined,
              label: 'Shop',
              color: MoolColors.navy,
            ),
          ),
          Positioned(
            left: delivered ? null : 152,
            right: delivered ? 28 : null,
            top: delivered ? 24 : 66,
            child: _MapPoint(
              icon: delivered
                  ? Icons.home_rounded
                  : Icons.delivery_dining_rounded,
              label: delivered ? 'Delivered' : 'Captain',
              color: delivered ? MoolColors.success : MoolColors.orange,
            ),
          ),
          const Positioned(
            right: 24,
            top: 22,
            child: _MapPoint(
              icon: Icons.home_outlined,
              label: 'Customer',
              color: MoolColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.delivered});

  final bool delivered;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = delivered ? MoolColors.success : MoolColors.navy
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(54, size.height - 44)
      ..quadraticBezierTo(
        size.width * .52,
        size.height * .64,
        size.width - 56,
        48,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.delivered != delivered;
}

class _MapPoint extends StatelessWidget {
  const _MapPoint({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MoolRadii.capsule),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({
    required this.title,
    required this.detail,
    required this.done,
  });

  final String title;
  final String detail;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? MoolColors.success : MoolColors.muted,
          ),
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
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: MoolColors.muted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: MoolColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
