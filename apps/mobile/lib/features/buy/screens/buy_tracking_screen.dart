import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyTrackingScreen extends StatelessWidget {
  const BuyTrackingScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final BuySession session;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final receipt = session.receipt;
        if (receipt == null || receipt.id != orderId) {
          return _MissingOrder(session: session);
        }
        final delivered = session.orderStage == BuyOrderStage.delivered;
        return BuyPageScaffold(
          key: const Key('buy-tracking-screen'),
          session: session,
          title: delivered ? 'Delivery arrived' : 'Track your delivery',
          subtitle: '${receipt.id} · ${session.orderStage.title}',
          activeDock: 'orders',
          fallbackBackRoute: '/app/buy/review',
          trailing: IconButton.outlined(
            key: const Key('buy-delivery-help'),
            tooltip: 'Delivery help',
            onPressed: () => _showHelpSheet(context, session),
            icon: const Icon(Icons.support_agent_rounded),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              _StatusHero(session: session),
              const SizedBox(height: MoolSpacing.sm),
              _StatusTimeline(stage: session.orderStage),
              const SizedBox(height: MoolSpacing.sm),
              _RiderCard(session: session),
              const SizedBox(height: MoolSpacing.sm),
              _DeliveryAddress(session: session),
              const SizedBox(height: MoolSpacing.sm),
              _DeliveryActions(session: session),
            ],
          ),
          bottomAction: FilledButton.icon(
            key: const Key('buy-check-arrival'),
            onPressed: () {
              if (delivered) {
                context.go('/app/buy/order/$orderId/completed');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'The rider has not reached your doorstep yet. Refresh the live status.',
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              delivered
                  ? Icons.inventory_2_outlined
                  : Icons.location_searching_rounded,
            ),
            label: Text(
              delivered ? 'Check delivered basket' : 'Check doorstep arrival',
            ),
          ),
        );
      },
    );
  }
}

class _MissingOrder extends StatelessWidget {
  const _MissingOrder({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuyPageScaffold(
      key: const Key('buy-missing-order-screen'),
      session: session,
      title: 'Order not available',
      subtitle: 'Open your latest order or start a new basket',
      activeDock: 'orders',
      fallbackBackRoute: '/app/buy/grocery',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: MoolColors.muted,
              ),
              const SizedBox(height: MoolSpacing.md),
              const Text(
                'We could not find this order',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              const Text(
                'It may belong to another account or the link may be incomplete.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MoolSpacing.lg),
              FilledButton(
                key: const Key('buy-missing-order-shop'),
                onPressed: () => context.go('/app/buy/grocery'),
                child: const Text('Shop products'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MoolSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoolColors.navy, Color(0xFF2525CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MoolRadii.sheet),
        boxShadow: MoolShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              session.orderStage == BuyOrderStage.delivered
                  ? Icons.check_rounded
                  : Icons.delivery_dining_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          Text(
            session.orderStage.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            session.orderStage.detail,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.tonalIcon(
            key: const Key('buy-refresh-status'),
            onPressed: session.refreshOrderStatus,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh live status'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: MoolColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.stage});

  final BuyOrderStage stage;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        children: [
          for (var index = 0; index < BuyOrderStage.values.length; index++)
            _StatusStep(
              stage: BuyOrderStage.values[index],
              completed: index <= stage.index,
              active: index == stage.index,
              showLine: index < BuyOrderStage.values.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.stage,
    required this.completed,
    required this.active,
    required this.showLine,
  });

  final BuyOrderStage stage;
  final bool completed;
  final bool active;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: completed ? MoolColors.success : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed ? MoolColors.success : MoolColors.line,
                    width: 2,
                  ),
                ),
                child: completed
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
              if (showLine)
                Container(
                  width: 2,
                  height: 27,
                  color: completed ? MoolColors.success : MoolColors.line,
                ),
            ],
          ),
        ),
        const SizedBox(width: MoolSpacing.xs),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              stage.title,
              style: TextStyle(
                color: active || completed ? MoolColors.ink : MoolColors.muted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final assigned =
        session.orderStage.index >= BuyOrderStage.riderAssigned.index;
    return BuySurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFFFEDDA),
            child: Icon(
              assigned ? Icons.person_rounded : Icons.schedule_rounded,
              color: MoolColors.navy,
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assigned ? 'Rakesh · delivery partner' : 'Rider assignment',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  assigned
                      ? 'Verified · 4.9 ★ · RJ19 ES 4210'
                      : 'A verified rider will be shown here.',
                  style: const TextStyle(color: MoolColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            key: const Key('buy-call-rider'),
            tooltip: 'Call rider',
            onPressed: assigned
                ? () => _showCallSheet(context)
                : () => _showSnack(
                    context,
                    'Call becomes available when a rider is assigned.',
                  ),
            icon: const Icon(Icons.call_outlined),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAddress extends StatelessWidget {
  const _DeliveryAddress({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: MoolColors.navy),
              const SizedBox(width: MoolSpacing.xs),
              const Expanded(
                child: Text(
                  'Doorstep address',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                key: const Key('buy-edit-instructions'),
                onPressed: () => _showInstructionSheet(context, session),
                child: const Text('Edit note'),
              ),
            ],
          ),
          Text(
            session.address,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Leave with security only after calling',
            style: TextStyle(
              color: MoolColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryActions extends StatelessWidget {
  const _DeliveryActions({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Help the rider reach you',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: [
              _ActionChip(
                key: const Key('buy-change-landmark'),
                icon: Icons.edit_location_alt_outlined,
                label: 'Change landmark',
                onTap: () => _showLandmarkSheet(context),
              ),
              _ActionChip(
                key: const Key('buy-cannot-find-me'),
                icon: Icons.person_pin_circle_outlined,
                label: 'Cannot find me',
                onTap: () => _showCannotFindSheet(context),
              ),
              _ActionChip(
                key: const Key('buy-share-location'),
                icon: Icons.my_location_rounded,
                label: 'Share live location',
                onTap: () => _showShareLocationSheet(context),
              ),
              _ActionChip(
                key: const Key('buy-report-delay'),
                icon: Icons.timer_outlined,
                label: 'Report delay',
                onTap: () => _showDelaySheet(context, session),
              ),
              _ActionChip(
                key: const Key('buy-rider-change'),
                icon: Icons.swap_horiz_rounded,
                label: 'Rider changed',
                onTap: () => _showSnack(
                  context,
                  'You will be notified here if the delivery partner changes.',
                ),
              ),
              _ActionChip(
                key: const Key('buy-order-support'),
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat order support',
                onTap: () {
                  final current = GoRouterState.of(context).uri.toString();
                  context.go(
                    Uri(
                      path: '/app/chat/thread/order-support',
                      queryParameters: {'return': current},
                    ).toString(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: MoolColors.navy),
      label: Text(label),
    );
  }
}

Future<void> _showCallSheet(BuildContext context) {
  final pageContext = context;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _SimpleActionSheet(
      title: 'Call Rakesh?',
      detail: 'Use a masked number to protect both phone numbers.',
      primaryKey: const Key('buy-confirm-call-rider'),
      primaryLabel: 'Call now',
      primaryIcon: Icons.call_outlined,
      onPrimary: () {
        Navigator.of(sheetContext).pop();
        _showSnack(
          pageContext,
          'Calling the rider through a protected number.',
        );
      },
    ),
  );
}

Future<void> _showInstructionSheet(BuildContext context, BuySession session) {
  return _showTextActionSheet(
    context,
    title: 'Delivery note',
    label: 'Instructions for the rider',
    initial: 'Leave with security only after calling',
    fieldKey: const Key('buy-instruction-field'),
    saveKey: const Key('buy-save-instruction'),
    success: 'Delivery note updated.',
    onSaved: () => session.showNotice('Delivery note updated.'),
  );
}

Future<void> _showLandmarkSheet(BuildContext context) {
  return _showTextActionSheet(
    context,
    title: 'Change landmark',
    label: 'Nearby landmark',
    initial: '',
    fieldKey: const Key('buy-landmark-field'),
    saveKey: const Key('buy-save-landmark'),
    success: 'Landmark shared with the rider.',
  );
}

Future<void> _showTextActionSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String initial,
  required Key fieldKey,
  required Key saveKey,
  required String success,
  VoidCallback? onSaved,
}) async {
  final pageContext = context;
  var input = initial;
  String? error;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          MoolSpacing.sm,
          MoolSpacing.lg,
          MediaQuery.viewInsetsOf(sheetContext).bottom + MoolSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            TextFormField(
              key: fieldKey,
              initialValue: input,
              onChanged: (value) => input = value,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(labelText: label, errorText: error),
            ),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: saveKey,
              onPressed: () {
                if (input.trim().length < 3) {
                  setSheetState(() => error = 'Enter at least 3 characters.');
                  return;
                }
                Navigator.of(sheetContext).pop();
                if (onSaved != null) {
                  onSaved();
                } else {
                  _showSnack(pageContext, success);
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showCannotFindSheet(BuildContext context) {
  final pageContext = context;
  return showModalBottomSheet<void>(
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
          const Text(
            'Help the rider find you',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.icon(
            key: const Key('buy-cannot-find-call'),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _showSnack(
                pageContext,
                'Calling the rider through a protected number.',
              );
            },
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call rider'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          OutlinedButton.icon(
            key: const Key('buy-cannot-find-location'),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _showShareLocationSheet(pageContext);
            },
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Share live location'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showShareLocationSheet(BuildContext context) {
  final pageContext = context;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _SimpleActionSheet(
      title: 'Share live location?',
      detail:
          'Your live location is shared with this rider only until the order is delivered.',
      primaryKey: const Key('buy-confirm-share-location'),
      primaryLabel: 'Share until delivery',
      primaryIcon: Icons.my_location_rounded,
      onPrimary: () {
        Navigator.of(sheetContext).pop();
        _showSnack(
          pageContext,
          'Live location sharing is on for this delivery.',
        );
      },
    ),
  );
}

Future<void> _showDelaySheet(BuildContext context, BuySession session) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _SimpleActionSheet(
      title: 'Report a delivery delay',
      detail:
          'Support will check the live order and update you in this order screen.',
      primaryKey: const Key('buy-confirm-report-delay'),
      primaryLabel: 'Ask support to check',
      primaryIcon: Icons.support_agent_rounded,
      onPrimary: () {
        Navigator.of(sheetContext).pop();
        session.showNotice('Support is checking the delivery delay.');
      },
    ),
  );
}

Future<void> _showHelpSheet(BuildContext context, BuySession session) {
  final pageContext = context;
  return showModalBottomSheet<void>(
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
          const Text(
            'Delivery help',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          ListTile(
            key: const Key('buy-help-refresh'),
            leading: const Icon(Icons.refresh_rounded, color: MoolColors.navy),
            title: const Text('Refresh the live status'),
            onTap: () {
              session.refreshOrderStatus();
              Navigator.of(sheetContext).pop();
            },
          ),
          ListTile(
            key: const Key('buy-help-chat'),
            leading: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: MoolColors.navy,
            ),
            title: const Text('Chat with order support'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              final current = GoRouterState.of(pageContext).uri.toString();
              pageContext.go(
                Uri(
                  path: '/app/chat/thread/order-support',
                  queryParameters: {'return': current},
                ).toString(),
              );
            },
          ),
          ListTile(
            key: const Key('buy-help-cancel'),
            leading: const Icon(
              Icons.cancel_outlined,
              color: Color(0xFFB42318),
            ),
            title: const Text('Check cancellation options'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _showSnack(
                pageContext,
                'Cancellation availability depends on the current packing stage.',
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _SimpleActionSheet extends StatelessWidget {
  const _SimpleActionSheet({
    required this.title,
    required this.detail,
    required this.primaryKey,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
  });

  final String title;
  final String detail;
  final Key primaryKey;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            title,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(detail),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.icon(
            key: primaryKey,
            onPressed: onPrimary,
            icon: Icon(primaryIcon),
            label: Text(primaryLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
