import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatTableConfirmationScreen extends StatelessWidget {
  const EatTableConfirmationScreen({
    required this.session,
    required this.bookingId,
    super.key,
  });

  final EatSession session;
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final receipt = session.tableReceipt;
        if (receipt == null || receipt.id != bookingId) {
          return EatPageScaffold(
            key: const Key('eat-table-missing-screen'),
            session: session,
            title: 'Booking not found',
            subtitle: 'Choose another table',
            activeDock: 'table',
            body: Center(
              child: FilledButton(
                key: const Key('eat-table-missing-return'),
                onPressed: () => context.go('/app/eat/table'),
                child: const Text('Find a table'),
              ),
            ),
          );
        }
        final cancelled = session.tableBookingCancelled;
        return EatPageScaffold(
          key: const Key('eat-table-confirmation-screen'),
          session: session,
          title: cancelled ? 'Booking cancelled' : 'Table confirmed',
          subtitle: receipt.id,
          activeDock: 'table',
          fallbackBackRoute: '/app/eat/table',
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
                    : const Color(0xFFEAF7E8),
                child: Column(
                  children: [
                    Icon(
                      cancelled
                          ? Icons.event_busy_outlined
                          : Icons.event_available_rounded,
                      size: 56,
                      color: cancelled
                          ? const Color(0xFFB54708)
                          : MoolColors.success,
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      cancelled
                          ? 'Your table is released'
                          : receipt.restaurant.name,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      cancelled
                          ? 'No cancellation fee was charged.'
                          : '${receipt.people} people · ${receipt.time} · ${receipt.tableChoice}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: MoolColors.muted),
                    ),
                    if (!cancelled) ...[
                      const SizedBox(height: MoolSpacing.sm),
                      Container(
                        key: const Key('eat-table-qr'),
                        width: 108,
                        height: 108,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            MoolRadii.control,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 82,
                          color: MoolColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Show this code when you arrive',
                        style: TextStyle(
                          color: MoolColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              EatSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking details',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _DetailRow('People', receipt.people),
                    _DetailRow('Time', receipt.time),
                    _DetailRow('Table', receipt.tableChoice),
                    _DetailRow(
                      'Cost',
                      receipt.price == 0
                          ? 'Free booking'
                          : eatMoney(receipt.price),
                    ),
                    _DetailRow(
                      'Cancellation',
                      receipt.restaurant.cancellationRule,
                    ),
                    _DetailRow('Late arrival', 'Table held for 10 minutes'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (!cancelled) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('eat-table-directions'),
                        onPressed: () => session.showNotice(
                          'Directions opened to ${receipt.restaurant.name}.',
                        ),
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text('Directions'),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('eat-table-confirm-call'),
                        onPressed: () => session.showNotice(
                          'Calling ${receipt.restaurant.name} through a masked number.',
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('eat-table-preorder'),
                        onPressed: () {
                          session.chooseFulfilment(EatFulfilment.tableQr);
                          context.go('/app/eat/order');
                        },
                        child: const Text('Preorder food'),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('eat-table-confirm-chat'),
                        onPressed: () => context.go(
                          '/app/chat/thread/mahadev-business?return=/app/eat/table/$bookingId',
                        ),
                        child: const Text('Chat'),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  key: const Key('eat-table-cancel-booking'),
                  onPressed: () => _confirmCancelTable(context, session),
                  child: const Text('Cancel table booking'),
                ),
              ] else
                FilledButton(
                  key: const Key('eat-table-book-again'),
                  onPressed: () => context.go('/app/eat/table'),
                  child: const Text('Book another table'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

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

Future<void> _confirmCancelTable(
  BuildContext context,
  EatSession session,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel table booking?'),
      content: Text(
        '${session.tableRestaurant.cancellationRule}. The table will be released immediately.',
      ),
      actions: [
        TextButton(
          key: const Key('eat-table-keep-booking'),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep booking'),
        ),
        FilledButton(
          key: const Key('eat-table-confirm-cancel'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cancel booking'),
        ),
      ],
    ),
  );
  if (confirmed == true) session.cancelTableBooking();
}
