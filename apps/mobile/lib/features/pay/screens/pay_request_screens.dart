import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../pay_models.dart';
import '../pay_session.dart';
import '../widgets/pay_widgets.dart';

class PayRequestsScreen extends StatelessWidget {
  const PayRequestsScreen({required this.session, super.key});

  final PaySession session;

  Future<void> _confirmDecline(BuildContext context, String requestId) async {
    if (!session.selectRequest(requestId)) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(MoolSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.block_rounded, size: 38, color: Color(0xFFB42318)),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'Decline this payment request?',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(
              '${session.activeIntent!.payee} will see that you declined. No money will be debited.',
              style: const TextStyle(
                color: MoolColors.muted,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('confirm-decline-request'),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Decline request'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('cancel-decline-request'),
                onPressed: () => Navigator.pop(sheetContext, false),
                child: const Text('Keep request'),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await session.declineSelectedRequest();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => PayPageScaffold(
        session: session,
        title: 'Pay Requests',
        subtitle: 'Nothing is paid without your approval',
        activeDock: 'requests',
        body: ListView(
          key: const Key('pay-requests-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.sm,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const PayCard(
              color: Color(0xFFF5F5FF),
              child: PayTrustRow(
                icon: Icons.verified_user_outlined,
                title: '2 requests need action',
                detail:
                    'Requester, linked purpose, amount and expiry stay visible before debit.',
                color: MoolColors.navy,
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            PaySegment<PayRequestCategory>(
              values: PayRequestCategory.values,
              selected: session.requestCategory,
              label: (value) => value.label,
              keyFor: (value) => 'request-category-${value.name}',
              onSelected: session.chooseRequestCategory,
            ),
            const SizedBox(height: MoolSpacing.md),
            if (session.visibleRequests.isEmpty)
              const PayCard(
                child: PayTrustRow(
                  icon: Icons.inbox_outlined,
                  title: 'No requests here',
                  detail: 'New requests will appear with their full purpose.',
                  color: MoolColors.muted,
                ),
              )
            else
              for (final request in session.visibleRequests) ...[
                _RequestCard(
                  request: request,
                  declined:
                      session.declineReference != null &&
                      session.activeIntent?.id == request.id,
                  busy: session.busy,
                  onReview: () {
                    if (!session.selectRequest(request.id)) return;
                    context.go('/app/pay/request/${request.id}/confirm');
                  },
                  onDecline: () => _confirmDecline(context, request.id),
                  onReport: () => session.showNotice(
                    'Request reported and blocked. No debit was made.',
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.declined,
    required this.busy,
    required this.onReview,
    required this.onDecline,
    required this.onReport,
  });

  final PaymentIntent request;
  final bool declined;
  final bool busy;
  final VoidCallback onReview;
  final VoidCallback onDecline;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final blocked = !request.verified;
    return PayCard(
      key: Key('pay-request-${request.id}'),
      color: blocked ? const Color(0xFFFFF4F2) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: blocked
                      ? const Color(0xFFFFE4E1)
                      : const Color(0xFFEAF7E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  blocked
                      ? Icons.gpp_bad_outlined
                      : Icons.verified_user_rounded,
                  color: blocked ? const Color(0xFFB42318) : MoolColors.success,
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.payee,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      request.payeeDetail,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                payMoney(request.amount),
                style: TextStyle(
                  color: blocked ? const Color(0xFFB42318) : MoolColors.success,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Text(
            request.purpose,
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${request.linkedReference} · expires ${request.expires}',
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          if (declined)
            const PayTrustRow(
              icon: Icons.block_rounded,
              title: 'Declined · no debit',
              detail: 'The decline reference is saved.',
            )
          else if (blocked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('report-request-${request.id}'),
                onPressed: onReport,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report blocked request'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('decline-request-${request.id}'),
                    onPressed: busy ? null : onDecline,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: Key('review-request-${request.id}'),
                    onPressed: busy ? null : onReview,
                    child: const Text('Review to pay'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class PayRequestConfirmationScreen extends StatefulWidget {
  const PayRequestConfirmationScreen({
    required this.session,
    required this.requestId,
    super.key,
  });

  final PaySession session;
  final String requestId;

  @override
  State<PayRequestConfirmationScreen> createState() =>
      _PayRequestConfirmationScreenState();
}

class _PayRequestConfirmationScreenState
    extends State<PayRequestConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.session.activeIntent?.id != widget.requestId) {
      widget.session.selectRequest(widget.requestId);
    }
  }

  Future<void> _addMethod() async {
    final controller = TextEditingController();
    String? error;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            MoolSpacing.md,
            MoolSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add UPI method',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              const Text(
                'Saved only after the UPI ID is validated.',
                style: TextStyle(
                  color: MoolColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              TextField(
                key: const Key('new-upi-id'),
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  errorText: error,
                  hintText: 'name@bank',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('save-new-upi'),
                  onPressed: () {
                    if (!controller.text.trim().contains('@')) {
                      setSheetState(() => error = 'Enter a complete UPI ID.');
                      return;
                    }
                    Navigator.pop(sheetContext, true);
                  },
                  child: const Text('Validate and use UPI'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (saved == true) {
      widget.session.choosePaymentMethod(ConsumerPaymentMethod.upi);
      widget.session.showNotice('UPI method validated for this payment.');
    }
  }

  Future<void> _pay() async {
    final record = await widget.session.submitActivePayment();
    if (!mounted || record == null) return;
    final route = switch (record.outcome) {
      PaymentOutcome.success => '/app/pay/payment/${record.id}/receipt',
      PaymentOutcome.pending => '/app/pay/payment/${record.id}/status',
      PaymentOutcome.failedNoDebit ||
      PaymentOutcome.reversal ||
      PaymentOutcome.reversed => '/app/pay/payment/${record.id}/outcome',
    };
    context.go(route);
  }

  Future<void> _decline() async {
    final done = await widget.session.declineSelectedRequest();
    if (done && mounted) context.go('/app/pay/requests');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final intent = widget.session.activeIntent;
        if (intent == null) {
          return PayPageScaffold(
            session: widget.session,
            title: 'Confirm payment',
            subtitle: 'Request unavailable',
            fallbackBackRoute: '/app/pay/requests',
            body: Center(
              child: PayCard(
                child: PayTrustRow(
                  icon: Icons.error_outline,
                  title: 'This request cannot be paid',
                  detail: widget.session.errorMessage ?? 'Return to requests.',
                  color: const Color(0xFFB42318),
                ),
              ),
            ),
          );
        }
        final isRequest = intent.source == PayAction.requests;
        final returnRoute = isRequest ? '/app/pay/requests' : '/app/pay/home';
        return PayPageScaffold(
          session: widget.session,
          title: 'Confirm payment',
          subtitle: 'Final approval before debit',
          fallbackBackRoute: returnRoute,
          activeDock: isRequest ? 'requests' : 'pay',
          body: ListView(
            key: const Key('pay-request-confirmation-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              PayCard(
                color: const Color(0xFFF5F5FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PayTrustRow(
                      icon: Icons.verified_rounded,
                      title: intent.payee,
                      detail: intent.payeeDetail,
                    ),
                    const Divider(height: MoolSpacing.lg),
                    _ConfirmationRow('Purpose', intent.purpose),
                    _ConfirmationRow('Linked', intent.linkedReference),
                    _ConfirmationRow('Expires', intent.expires),
                    _ConfirmationRow('Exact debit', payMoney(intent.amount)),
                    const _ConfirmationRow('Payment fee', '₹0'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const PaySectionTitle(
                'Pay with',
                detail: 'Changing method does not change payee or amount.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              PayPaymentMethods(session: widget.session),
              const SizedBox(height: MoolSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('add-payment-method'),
                  onPressed: _addMethod,
                  icon: const Icon(Icons.add_card_rounded),
                  label: const Text('Add another UPI method'),
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const PayCard(
                child: PayTrustRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'No debit on page open',
                  detail:
                      'Any change to payee, purpose or amount cancels this confirmation. Success requires bank confirmation.',
                  color: MoolColors.navy,
                ),
              ),
            ],
          ),
          bottomAction: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('confirmation-decline'),
                  onPressed: widget.session.busy
                      ? null
                      : isRequest
                      ? _decline
                      : () => context.go(returnRoute),
                  child: Text(isRequest ? 'Decline' : 'Cancel'),
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                flex: 2,
                child: PayPrimaryButton(
                  keyName: 'confirmation-pay',
                  label: 'Pay ${payMoney(intent.amount)}',
                  busy: widget.session.busy,
                  onPressed: _pay,
                  icon: Icons.lock_rounded,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow(this.label, this.value);

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
            width: 74,
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
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
