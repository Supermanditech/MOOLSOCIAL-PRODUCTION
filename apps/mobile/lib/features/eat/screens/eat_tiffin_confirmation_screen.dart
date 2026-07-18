import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatTiffinConfirmationScreen extends StatelessWidget {
  const EatTiffinConfirmationScreen({
    required this.session,
    required this.subscriptionId,
    super.key,
  });

  final EatSession session;
  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final receipt = session.tiffinReceipt;
        if (receipt == null || receipt.id != subscriptionId) {
          return EatPageScaffold(
            key: const Key('eat-tiffin-missing-screen'),
            session: session,
            title: 'Plan not found',
            subtitle: 'Choose a meal plan',
            activeDock: 'tiffin',
            body: Center(
              child: FilledButton(
                key: const Key('eat-tiffin-missing-return'),
                onPressed: () => context.go('/app/eat/tiffin'),
                child: const Text('Choose tiffin'),
              ),
            ),
          );
        }
        final status = session.tiffinCancelled
            ? 'Ends before next cycle'
            : session.tiffinPaused
            ? 'Paused'
            : 'Active';
        return EatPageScaffold(
          key: const Key('eat-tiffin-confirmation-screen'),
          session: session,
          title: 'Tiffin plan $status',
          subtitle: receipt.id,
          activeDock: 'tiffin',
          fallbackBackRoute: '/app/eat/tiffin',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              EatSurfaceCard(
                color: session.tiffinCancelled
                    ? const Color(0xFFFFF2E8)
                    : const Color(0xFFEAF7E8),
                child: Column(
                  children: [
                    Icon(
                      session.tiffinCancelled
                          ? Icons.event_busy_outlined
                          : session.tiffinPaused
                          ? Icons.pause_circle_outline_rounded
                          : Icons.lunch_dining_rounded,
                      size: 56,
                      color: session.tiffinCancelled
                          ? const Color(0xFFB54708)
                          : MoolColors.success,
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      receipt.kitchen.name,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${receipt.plan.label} · ${receipt.meal.label} · ${receipt.slot}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: MoolColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: session.tiffinCancelled
                            ? const Color(0xFFB54708)
                            : MoolColors.success,
                        fontWeight: FontWeight.w900,
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
                    const Text(
                      'Plan details',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _PlanRow('Food', receipt.foodStyle),
                    _PlanRow('Meals', receipt.meal.count),
                    _PlanRow('Delivery', receipt.slot),
                    _PlanRow('Address', receipt.address),
                    _PlanRow('Paid', eatMoney(receipt.price)),
                    _PlanRow('Pause and skip', receipt.kitchen.pauseRule),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (!session.tiffinCancelled) ...[
                EatSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Control your next meals',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('eat-tiffin-skip-next'),
                          onPressed: session.toggleNextMealSkip,
                          icon: Icon(
                            session.nextMealSkipped
                                ? Icons.undo_rounded
                                : Icons.skip_next_rounded,
                          ),
                          label: Text(
                            session.nextMealSkipped
                                ? 'Restore next meal'
                                : 'Skip next meal',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('eat-tiffin-toggle-pause'),
                          onPressed: session.toggleTiffinPause,
                          icon: Icon(
                            session.tiffinPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          label: Text(
                            session.tiffinPaused
                                ? 'Resume meal plan'
                                : 'Pause meal plan',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('eat-tiffin-change-plan-address'),
                          onPressed: () => session.showNotice(
                            'Address change opens before the next kitchen cutoff.',
                          ),
                          icon: const Icon(Icons.location_on_outlined),
                          label: const Text('Change delivery address'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('eat-tiffin-view-bill'),
                        onPressed: () => session.showNotice(
                          'Receipt opened for ${receipt.id}.',
                        ),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('View bill'),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('eat-tiffin-chat'),
                        onPressed: () => context.go(
                          '/app/chat/thread/mahadev-business?return=/app/eat/tiffin/$subscriptionId',
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Chat'),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  key: const Key('eat-tiffin-cancel-plan'),
                  onPressed: () => _confirmCancelTiffin(context, session),
                  child: const Text('Stop before next billing cycle'),
                ),
              ] else
                FilledButton(
                  key: const Key('eat-tiffin-start-another'),
                  onPressed: () => context.go('/app/eat/tiffin'),
                  child: const Text('Choose another meal plan'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: MoolColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmCancelTiffin(
  BuildContext context,
  EatSession session,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Stop this meal plan?'),
      content: const Text(
        'Your current paid cycle remains available. Renewal stops before the next billing cycle.',
      ),
      actions: [
        TextButton(
          key: const Key('eat-tiffin-keep-plan'),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep plan'),
        ),
        FilledButton(
          key: const Key('eat-tiffin-confirm-cancel'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Stop renewal'),
        ),
      ],
    ),
  );
  if (confirmed == true) session.cancelTiffin();
}
