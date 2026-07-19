import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../pay_models.dart';
import '../pay_session.dart';
import '../widgets/pay_widgets.dart';

class PayHomeScreen extends StatefulWidget {
  const PayHomeScreen({required this.session, this.initialIntent, super.key});

  final PaySession session;
  final String? initialIntent;

  @override
  State<PayHomeScreen> createState() => _PayHomeScreenState();
}

class _PayHomeScreenState extends State<PayHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = switch (widget.initialIntent) {
        'recharge' => '/app/pay/recharge',
        'bills' => '/app/pay/bills',
        'scan-pay' => '/app/pay/scan',
        'requests' => '/app/pay/requests',
        'receipts' => '/app/pay/receipts',
        _ => null,
      };
      if (route != null && mounted) context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => PayPageScaffold(
        session: widget.session,
        title: 'Pay',
        subtitle: 'Check every payment before debit',
        showBack: false,
        activeDock: 'pay',
        body: ListView(
          key: const Key('pay-home-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.sm,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            PayCard(
              color: MoolColors.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your personal payments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  const Text(
                    'Recharge, pay bills, scan a verified QR or approve a request. Business payouts stay in their business workspace.',
                    style: TextStyle(
                      color: Color(0xFFE0E1FF),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.md),
                  Wrap(
                    spacing: MoolSpacing.xs,
                    runSpacing: MoolSpacing.xs,
                    children: const [
                      _TrustPill('Payee shown'),
                      _TrustPill('Amount confirmed'),
                      _TrustPill('Receipt saved'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const PaySectionTitle(
              'Choose a payment',
              detail: 'Every action has its own safe completion path.',
            ),
            const SizedBox(height: MoolSpacing.sm),
            _PayActionCard(
              keyName: 'pay-home-recharge',
              icon: Icons.phone_android_rounded,
              color: const Color(0xFF4F46E5),
              title: 'Recharge',
              detail: 'Mobile, DTH, data and saved connections',
              proof: 'Number · operator · plan',
              onTap: () {
                widget.session.resetEntry(PayAction.recharge);
                context.go('/app/pay/recharge');
              },
            ),
            const SizedBox(height: MoolSpacing.sm),
            _PayActionCard(
              keyName: 'pay-home-bills',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF00796B),
              title: 'Bills',
              detail: 'Electricity, water, gas and internet',
              proof: 'Biller · due amount · due date',
              onTap: () {
                widget.session.resetEntry(PayAction.bills);
                context.go('/app/pay/bills');
              },
            ),
            const SizedBox(height: MoolSpacing.sm),
            _PayActionCard(
              keyName: 'pay-home-scan',
              icon: Icons.qr_code_scanner_rounded,
              color: MoolColors.orange,
              title: 'Scan Pay',
              detail: 'Shop, order, provider QR or UPI ID',
              proof: 'Payee · purpose · exact amount',
              onTap: () {
                widget.session.resetEntry(PayAction.scan);
                context.go('/app/pay/scan');
              },
            ),
            const SizedBox(height: MoolSpacing.sm),
            _PayActionCard(
              keyName: 'pay-home-requests',
              icon: Icons.mark_email_unread_rounded,
              color: const Color(0xFFB42318),
              title: 'Pay Requests',
              detail: 'Review, approve, decline or report',
              proof: 'Requester · purpose · expiry',
              badge: '2 need action',
              onTap: () {
                widget.session.resetEntry(PayAction.requests);
                context.go('/app/pay/requests');
              },
            ),
            const SizedBox(height: MoolSpacing.md),
            PayCard(
              key: const Key('pay-home-receipts'),
              onTap: () => context.go('/app/pay/receipts'),
              child: const PayTrustRow(
                icon: Icons.receipt_outlined,
                title: 'Payments & receipts',
                detail:
                    'Search successful, pending and returned payments with immutable references.',
                color: MoolColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PayActionCard extends StatelessWidget {
  const _PayActionCard({
    required this.keyName,
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.proof,
    required this.onTap,
    this.badge,
  });

  final String keyName;
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String proof;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return PayCard(
      key: Key(keyName),
      onTap: onTap,
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEA),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  proof,
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }
}
