import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../pay_models.dart';
import '../pay_session.dart';
import '../widgets/pay_widgets.dart';

class PayReceiptScreen extends StatefulWidget {
  const PayReceiptScreen({
    required this.session,
    required this.paymentId,
    super.key,
  });

  final PaySession session;
  final String paymentId;

  @override
  State<PayReceiptScreen> createState() => _PayReceiptScreenState();
}

class _PayReceiptScreenState extends State<PayReceiptScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.session.activeRecord?.id != widget.paymentId) {
      widget.session.openRecord(widget.paymentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final record = widget.session.activeRecord;
        if (record == null) {
          return _MissingPayment(session: widget.session);
        }
        return PayPageScaffold(
          session: widget.session,
          title: 'Payment successful',
          subtitle: 'Receipt saved · linked purpose updated',
          fallbackBackRoute: '/app/pay/receipts',
          activeDock: 'receipts',
          body: ListView(
            key: const Key('pay-receipt-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              PayCard(
                color: const Color(0xFFEAF7E8),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: MoolColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const Text(
                      'Payment complete',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      payMoney(record.intent.amount),
                      style: const TextStyle(
                        color: MoolColors.success,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${record.intent.payee} · ${record.method.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              PayCard(
                child: Column(
                  children: [
                    _RecordRow('Payee', record.intent.payee),
                    _RecordRow('Purpose', record.intent.purpose),
                    _RecordRow('Linked', record.intent.linkedReference),
                    _RecordRow('MoolSocial ref', record.id),
                    _RecordRow('Bank ref', record.providerReference),
                    const _RecordRow('Status', 'Success'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const PayCard(
                child: PayTrustRow(
                  icon: Icons.verified_outlined,
                  title: 'Bank-confirmed receipt',
                  detail:
                      'Refreshing the app cannot create another debit or receipt.',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('download-pay-receipt'),
                      onPressed: () => widget.session.showNotice(
                        'Receipt downloaded to this device.',
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('share-pay-receipt'),
                      onPressed: () => widget.session.showNotice(
                        'Secure receipt share sheet opened.',
                      ),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('view-linked-payment-purpose'),
                  onPressed: () => widget.session.showNotice(
                    '${record.intent.linkedReference} is confirmed and ready to track.',
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('View linked order or booking'),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const Key('receipt-payment-help'),
                  onPressed: () => widget.session.openSupport(
                    'Payment or linked-purpose help',
                  ),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: Text(
                    widget.session.supportCaseId == null
                        ? 'Get payment help'
                        : 'Support case ${widget.session.supportCaseId}',
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

class PayReceiptsScreen extends StatefulWidget {
  const PayReceiptsScreen({required this.session, super.key});

  final PaySession session;

  @override
  State<PayReceiptsScreen> createState() => _PayReceiptsScreenState();
}

class _PayReceiptsScreenState extends State<PayReceiptsScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.session.searchQuery,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openRecord(BuildContext context, PaymentRecord record) {
    widget.session.openRecord(record.id);
    final route = switch (record.outcome) {
      PaymentOutcome.success => '/app/pay/payment/${record.id}/receipt',
      PaymentOutcome.pending => '/app/pay/payment/${record.id}/status',
      PaymentOutcome.failedNoDebit ||
      PaymentOutcome.reversal => '/app/pay/payment/${record.id}/outcome',
      PaymentOutcome.reversed => '/app/pay/payment/${record.id}/status',
    };
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final records = widget.session.visibleRecords;
        return PayPageScaffold(
          session: widget.session,
          title: 'Payments & receipts',
          subtitle: 'Search every consumer payment',
          fallbackBackRoute: '/app/pay/home',
          activeDock: 'receipts',
          body: ListView(
            key: const Key('pay-receipts-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              PayCard(
                color: MoolColors.navy,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'July 2026',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Consumer payments only',
                            style: TextStyle(
                              color: Color(0xFFD9DAFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      payMoney(
                        widget.session.visibleRecords.fold(
                          0,
                          (sum, item) => sum + item.intent.amount,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              TextField(
                key: const Key('receipt-search'),
                controller: _search,
                onChanged: widget.session.searchReceipts,
                decoration: InputDecoration(
                  hintText: 'Search payee, amount or reference',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('clear-receipt-search'),
                          onPressed: () {
                            _search.clear();
                            widget.session.searchReceipts('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              PaySegment<ReceiptFilter>(
                values: ReceiptFilter.values,
                selected: widget.session.receiptFilter,
                label: (value) => switch (value) {
                  ReceiptFilter.all => 'All',
                  ReceiptFilter.pending => 'Pending',
                  ReceiptFilter.refunds => 'Refunds',
                },
                keyFor: (value) => 'receipt-filter-${value.name}',
                onSelected: widget.session.setReceiptFilter,
              ),
              const SizedBox(height: MoolSpacing.md),
              if (records.isEmpty)
                PayCard(
                  key: const Key('receipts-empty'),
                  child: Column(
                    children: [
                      const PayTrustRow(
                        icon: Icons.search_off_rounded,
                        title: 'No matching payment',
                        detail:
                            'Try another payee, amount or payment reference.',
                        color: MoolColors.muted,
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      OutlinedButton(
                        onPressed: () {
                          _search.clear();
                          widget.session.searchReceipts('');
                          widget.session.setReceiptFilter(ReceiptFilter.all);
                        },
                        child: const Text('Show all payments'),
                      ),
                    ],
                  ),
                )
              else
                for (final record in records) ...[
                  _PaymentRecordCard(
                    record: record,
                    onOpen: () => _openRecord(context, record),
                    onShare: () => widget.session.showNotice(
                      'Secure share sheet opened for ${record.id}.',
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                ],
            ],
          ),
        );
      },
    );
  }
}

class PayStatusScreen extends StatefulWidget {
  const PayStatusScreen({
    required this.session,
    required this.paymentId,
    super.key,
  });

  final PaySession session;
  final String paymentId;

  @override
  State<PayStatusScreen> createState() => _PayStatusScreenState();
}

class _PayStatusScreenState extends State<PayStatusScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.session.activeRecord?.id != widget.paymentId) {
      widget.session.openRecord(widget.paymentId);
    }
  }

  Future<void> _refresh() async {
    final changed = await widget.session.refreshActiveStatus();
    if (!mounted || !changed) return;
    final record = widget.session.activeRecord!;
    if (record.outcome == PaymentOutcome.success) {
      context.go('/app/pay/payment/${record.id}/receipt');
    } else if (record.outcome == PaymentOutcome.failedNoDebit ||
        record.outcome == PaymentOutcome.reversal) {
      context.go('/app/pay/payment/${record.id}/outcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final record = widget.session.activeRecord;
        if (record == null) return _MissingPayment(session: widget.session);
        final refunded =
            record.outcome == PaymentOutcome.reversed ||
            record.refundAmount > 0;
        return PayPageScaffold(
          session: widget.session,
          title: refunded ? 'Refund status' : 'Payment status',
          subtitle: refunded
              ? 'Returned to the original method'
              : 'Automatic bank confirmation',
          fallbackBackRoute: '/app/pay/receipts',
          activeDock: 'receipts',
          bottomAction: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!refunded)
                SizedBox(
                  width: double.infinity,
                  child: PayPrimaryButton(
                    keyName: 'refresh-payment-status',
                    label: 'Check bank status',
                    busy: widget.session.busy,
                    onPressed: _refresh,
                    icon: Icons.refresh_rounded,
                  ),
                ),
              if (!refunded) const SizedBox(height: MoolSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('status-payment-help'),
                  onPressed: widget.session.busy
                      ? null
                      : () => widget.session.openSupport(
                          refunded
                              ? 'Refund record help'
                              : 'Pending payment help',
                        ),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: Text(
                    widget.session.supportCaseId == null
                        ? 'Get help with this record'
                        : 'Support case ${widget.session.supportCaseId}',
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            key: const Key('pay-status-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              PayCard(
                color: refunded
                    ? const Color(0xFFEAF7E8)
                    : const Color(0xFFFFF4E5),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: refunded
                            ? MoolColors.success
                            : MoolColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        refunded
                            ? Icons.keyboard_return_rounded
                            : Icons.more_horiz_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      refunded
                          ? 'Refund completed'
                          : 'Confirmation in progress',
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      payMoney(
                        refunded && record.refundAmount > 0
                            ? record.refundAmount
                            : record.intent.amount,
                      ),
                      style: TextStyle(
                        color: refunded
                            ? MoolColors.success
                            : MoolColors.orange,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      refunded
                          ? 'Returned to ${record.method.label}'
                          : 'Do not pay again while checking',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              PayCard(
                child: Column(
                  children: [
                    _RecordRow('Payee', record.intent.payee),
                    _RecordRow('Purpose', record.intent.purpose),
                    _RecordRow('Linked', record.intent.linkedReference),
                    _RecordRow('Reference', record.id),
                    _RecordRow('Method', record.method.label),
                    _RecordRow(
                      refunded ? 'Returned' : 'Expected',
                      refunded ? 'Completed' : 'Automatic update',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              PayCard(
                color: refunded
                    ? const Color(0xFFEAF7E8)
                    : const Color(0xFFFFF4E5),
                child: PayTrustRow(
                  icon: refunded
                      ? Icons.check_circle_outline_rounded
                      : Icons.hourglass_top_rounded,
                  title: refunded
                      ? 'Original payment remains linked'
                      : 'Repeat payment is locked',
                  detail: refunded
                      ? 'The returned amount, destination and original purpose are saved together.'
                      : 'Status refresh checks the existing payment. It cannot create a new debit.',
                  color: refunded ? MoolColors.success : MoolColors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PayOutcomeScreen extends StatefulWidget {
  const PayOutcomeScreen({
    required this.session,
    required this.paymentId,
    super.key,
  });

  final PaySession session;
  final String paymentId;

  @override
  State<PayOutcomeScreen> createState() => _PayOutcomeScreenState();
}

class _PayOutcomeScreenState extends State<PayOutcomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.session.activeRecord?.id != widget.paymentId) {
      widget.session.openRecord(widget.paymentId);
    }
  }

  Future<void> _refresh() async {
    final changed = await widget.session.refreshActiveStatus();
    if (!mounted || !changed) return;
    final record = widget.session.activeRecord!;
    if (record.outcome == PaymentOutcome.success) {
      context.go('/app/pay/payment/${record.id}/receipt');
    } else if (record.outcome == PaymentOutcome.pending ||
        record.outcome == PaymentOutcome.reversed) {
      context.go('/app/pay/payment/${record.id}/status');
    }
  }

  void _safeRetry() {
    widget.session.prepareSafeRetry();
    if (widget.session.activeRecord == null) {
      context.go('/app/pay/request/${widget.session.activeIntent!.id}/confirm');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final record = widget.session.activeRecord;
        if (record == null) return _MissingPayment(session: widget.session);
        final failed = record.outcome == PaymentOutcome.failedNoDebit;
        final returned = record.outcome == PaymentOutcome.reversed;
        final color = failed
            ? const Color(0xFFB42318)
            : returned
            ? MoolColors.success
            : MoolColors.orange;
        final title = failed
            ? 'Payment failed'
            : returned
            ? 'Reversal completed'
            : 'Reversal in progress';
        return PayPageScaffold(
          session: widget.session,
          title: 'Payment result',
          subtitle: 'Bank-confirmed outcome',
          fallbackBackRoute: '/app/pay/receipts',
          activeDock: 'receipts',
          body: ListView(
            key: const Key('pay-outcome-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              PayCard(
                color: color.withValues(alpha: .10),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        failed
                            ? Icons.close_rounded
                            : returned
                            ? Icons.check_rounded
                            : Icons.replay_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      title,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      payMoney(record.intent.amount),
                      style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      failed
                          ? 'Bank confirmed no debit'
                          : returned
                          ? 'Returned to ${record.method.label}'
                          : 'Returning to ${record.method.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              PayCard(
                child: Column(
                  children: [
                    _RecordRow('Payee', record.intent.payee),
                    _RecordRow('Purpose', record.intent.purpose),
                    _RecordRow('Linked', record.intent.linkedReference),
                    _RecordRow('Attempt ref', record.id),
                    _RecordRow('Method', record.method.label),
                    _RecordRow(
                      failed ? 'Debit check' : 'Return status',
                      failed
                          ? '₹0 confirmed'
                          : returned
                          ? 'Returned'
                          : 'Automatic',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              PayCard(
                color: color.withValues(alpha: .10),
                child: PayTrustRow(
                  icon: failed
                      ? Icons.verified_outlined
                      : Icons.warning_amber_rounded,
                  title: failed
                      ? 'Safe retry is available'
                      : returned
                      ? 'Original amount returned'
                      : 'Do not retry yet',
                  detail: failed
                      ? 'One retry keeps the same payee, purpose and amount and uses a new method.'
                      : returned
                      ? 'Retry only if the linked purpose still needs payment.'
                      : 'A debit was detected. Retry remains locked until it is returned or reconciled.',
                  color: color,
                ),
              ),
            ],
          ),
          bottomAction: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: failed
                    ? PayPrimaryButton(
                        keyName: 'safe-payment-retry',
                        label: 'Try another method',
                        busy: widget.session.busy,
                        onPressed: _safeRetry,
                        icon: Icons.refresh_rounded,
                      )
                    : !returned
                    ? PayPrimaryButton(
                        keyName: 'check-payment-reversal',
                        label: 'Check reversal',
                        busy: widget.session.busy,
                        onPressed: _refresh,
                        icon: Icons.refresh_rounded,
                      )
                    : FilledButton.icon(
                        key: const Key('view-returned-receipt'),
                        onPressed: () => context.go('/app/pay/receipts'),
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('View receipt history'),
                      ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('outcome-payment-help'),
                  onPressed: widget.session.busy
                      ? null
                      : () => widget.session.openSupport(
                          failed
                              ? 'Bank shows debit after failed result'
                              : 'Return is delayed',
                        ),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: Text(
                    widget.session.supportCaseId == null
                        ? 'Get help with this result'
                        : 'Support case ${widget.session.supportCaseId}',
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

class _PaymentRecordCard extends StatelessWidget {
  const _PaymentRecordCard({
    required this.record,
    required this.onOpen,
    required this.onShare,
  });

  final PaymentRecord record;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final warning =
        record.outcome == PaymentOutcome.pending ||
        record.outcome == PaymentOutcome.reversal;
    return PayCard(
      key: Key('payment-record-${record.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: warning
                      ? const Color(0xFFFFF4E5)
                      : const Color(0xFFEAF7E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  warning
                      ? Icons.hourglass_top_rounded
                      : Icons.receipt_long_rounded,
                  color: warning ? MoolColors.orange : MoolColors.success,
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.intent.payee,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      record.intent.linkedReference,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    payMoney(
                      record.refundAmount > 0
                          ? record.refundAmount
                          : record.intent.amount,
                    ),
                    style: TextStyle(
                      color: warning ? MoolColors.orange : MoolColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    record.outcome.label,
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Text(
            '${record.id} · ${record.method.label}',
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: Key('share-payment-${record.id}'),
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded, size: 17),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: FilledButton(
                  key: Key('open-payment-${record.id}'),
                  onPressed: onOpen,
                  child: Text(
                    record.outcome == PaymentOutcome.pending
                        ? 'Check status'
                        : record.refundAmount > 0
                        ? 'View refund'
                        : 'View receipt',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingPayment extends StatelessWidget {
  const _MissingPayment({required this.session});

  final PaySession session;

  @override
  Widget build(BuildContext context) {
    return PayPageScaffold(
      session: session,
      title: 'Payment record',
      subtitle: 'Record unavailable',
      fallbackBackRoute: '/app/pay/receipts',
      activeDock: 'receipts',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: PayCard(
            child: Column(
              children: [
                const PayTrustRow(
                  icon: Icons.search_off_rounded,
                  title: 'Payment record not found',
                  detail: 'Return to receipts and search by reference.',
                  color: MoolColors.muted,
                ),
                const SizedBox(height: MoolSpacing.md),
                FilledButton(
                  onPressed: () => context.go('/app/pay/receipts'),
                  child: const Text('Open receipts'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
