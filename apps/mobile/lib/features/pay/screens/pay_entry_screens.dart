import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../pay_models.dart';
import '../pay_session.dart';
import '../widgets/pay_widgets.dart';

class PayRechargeScreen extends StatefulWidget {
  const PayRechargeScreen({required this.session, super.key});

  final PaySession session;

  @override
  State<PayRechargeScreen> createState() => _PayRechargeScreenState();
}

class _PayRechargeScreenState extends State<PayRechargeScreen> {
  late final TextEditingController _account = TextEditingController(
    text: widget.session.rechargeAccount,
  );

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!widget.session.prepareRechargePayment()) return;
    final record = await widget.session.submitActivePayment();
    if (!mounted || record == null) return;
    _openPaymentResult(context, record);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final choice = widget.session.selectedRechargeChoice;
        return PayPageScaffold(
          session: widget.session,
          title: 'Recharge',
          subtitle: 'Number, operator, plan and receipt',
          activeDock: 'pay',
          body: ListView(
            key: const Key('pay-recharge-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const PayTrustRow(
                icon: Icons.phone_android_rounded,
                title: 'Confirm the connection first',
                detail:
                    'The operator and account must match before any plan can be paid.',
              ),
              const SizedBox(height: MoolSpacing.md),
              PaySegment<RechargeType>(
                values: RechargeType.values,
                selected: widget.session.rechargeType,
                label: (value) => value.label,
                keyFor: (value) => 'recharge-type-${value.name}',
                onSelected: (value) {
                  widget.session.chooseRechargeType(value);
                  _account.text = value == RechargeType.dth
                      ? 'DTH421'
                      : value == RechargeType.saved
                      ? '9428012418'
                      : '9829012321';
                },
              ),
              const SizedBox(height: MoolSpacing.md),
              PayCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const Key('recharge-account'),
                      controller: _account,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) {
                        if (widget.session.accountVerified) {
                          widget.session.chooseRechargeType(
                            widget.session.rechargeType,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        labelText:
                            widget.session.rechargeType == RechargeType.dth
                            ? 'Subscriber ID'
                            : 'Mobile number',
                        hintText: 'Enter account details',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('verify-recharge-account'),
                        onPressed: widget.session.busy
                            ? null
                            : () =>
                                  widget.session.verifyRecharge(_account.text),
                        icon: widget.session.busy
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                widget.session.accountVerified
                                    ? Icons.verified_rounded
                                    : Icons.search_rounded,
                              ),
                        label: Text(
                          widget.session.accountVerified
                              ? 'Account verified'
                              : 'Check operator and account',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const PaySectionTitle(
                'Choose a plan',
                detail: 'Plan benefits and validity stay visible.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final item in widget.session.visibleRechargeChoices) ...[
                PayChoiceTile(
                  choice: item,
                  selected: item.id == choice?.id,
                  onTap: () => widget.session.chooseChoice(item.id),
                ),
                const SizedBox(height: MoolSpacing.sm),
              ],
              const PaySectionTitle('Pay with'),
              const SizedBox(height: MoolSpacing.sm),
              PayPaymentMethods(session: widget.session),
              if (choice != null) ...[
                const SizedBox(height: MoolSpacing.md),
                PayCard(
                  color: const Color(0xFFF5F5FF),
                  child: Column(
                    children: [
                      _ReviewRow('Account', _mask(_account.text)),
                      _ReviewRow('Operator check', choice.proof),
                      _ReviewRow('Plan', choice.detail),
                      _ReviewRow('Final debit', payMoney(choice.amount)),
                      _ReviewRow('After payment', choice.follow),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomAction: PayPrimaryButton(
            keyName: 'pay-recharge-submit',
            label: choice == null
                ? 'Choose a plan'
                : 'Pay ${payMoney(choice.amount)}',
            busy: widget.session.busy,
            onPressed: _pay,
            icon: Icons.lock_rounded,
          ),
        );
      },
    );
  }
}

class PayBillsScreen extends StatefulWidget {
  const PayBillsScreen({required this.session, super.key});

  final PaySession session;

  @override
  State<PayBillsScreen> createState() => _PayBillsScreenState();
}

class _PayBillsScreenState extends State<PayBillsScreen> {
  late final TextEditingController _account = TextEditingController(
    text: widget.session.billAccount,
  );

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!widget.session.prepareBillPayment()) return;
    final record = await widget.session.submitActivePayment();
    if (!mounted || record == null) return;
    _openPaymentResult(context, record);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final choice = widget.session.selectedBillChoice;
        return PayPageScaffold(
          session: widget.session,
          title: 'Bills',
          subtitle: 'Fetch the exact bill before paying',
          activeDock: 'pay',
          body: ListView(
            key: const Key('pay-bills-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const PayTrustRow(
                icon: Icons.receipt_long_rounded,
                title: 'Biller and due amount are fetched live',
                detail:
                    'You see the consumer name, due date and exact amount before debit.',
              ),
              const SizedBox(height: MoolSpacing.md),
              PaySegment<BillType>(
                values: BillType.values,
                selected: widget.session.billType,
                label: (value) => value.label,
                keyFor: (value) => 'bill-type-${value.name}',
                onSelected: (value) {
                  widget.session.chooseBillType(value);
                  _account.text = switch (value) {
                    BillType.electricity => 'K8271',
                    BillType.water => 'W312',
                    BillType.gas => 'GAS9081',
                    BillType.internet => 'NET930',
                  };
                },
              ),
              const SizedBox(height: MoolSpacing.md),
              PayCard(
                child: Column(
                  children: [
                    TextField(
                      key: const Key('bill-account'),
                      controller: _account,
                      decoration: const InputDecoration(
                        labelText: 'Consumer or customer number',
                        hintText: 'Enter bill account',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('fetch-bill'),
                        onPressed: widget.session.busy
                            ? null
                            : () => widget.session.verifyBill(_account.text),
                        icon: widget.session.busy
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                widget.session.accountVerified
                                    ? Icons.verified_rounded
                                    : Icons.cloud_download_outlined,
                              ),
                        label: Text(
                          widget.session.accountVerified
                              ? 'Current bill fetched'
                              : 'Fetch current bill',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const PaySectionTitle(
                'Choose the bill',
                detail: 'Due date and consumer proof remain visible.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final item in widget.session.visibleBillChoices) ...[
                PayChoiceTile(
                  choice: item,
                  selected: item.id == choice?.id,
                  onTap: () => widget.session.chooseChoice(item.id),
                ),
                const SizedBox(height: MoolSpacing.sm),
              ],
              const PaySectionTitle('Pay with'),
              const SizedBox(height: MoolSpacing.sm),
              PayPaymentMethods(session: widget.session),
              if (choice != null) ...[
                const SizedBox(height: MoolSpacing.md),
                PayCard(
                  color: const Color(0xFFF5F5FF),
                  child: Column(
                    children: [
                      _ReviewRow('Biller', choice.title),
                      _ReviewRow('Consumer', choice.proof),
                      _ReviewRow('Due', choice.detail),
                      _ReviewRow('Final debit', payMoney(choice.amount)),
                      _ReviewRow('After payment', choice.follow),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomAction: PayPrimaryButton(
            keyName: 'pay-bill-submit',
            label: choice == null
                ? 'Fetch a bill'
                : 'Pay ${payMoney(choice.amount)}',
            busy: widget.session.busy,
            onPressed: _pay,
            icon: Icons.lock_rounded,
          ),
        );
      },
    );
  }
}

class PayScanScreen extends StatefulWidget {
  const PayScanScreen({required this.session, super.key});

  final PaySession session;

  @override
  State<PayScanScreen> createState() => _PayScanScreenState();
}

class _PayScanScreenState extends State<PayScanScreen> {
  late final TextEditingController _account = TextEditingController(
    text: widget.session.scanAccount,
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.session.scanAmount.toString(),
  );

  @override
  void dispose() {
    _account.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _askForCamera() async {
    final allow = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(MoolSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 38,
              color: MoolColors.navy,
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'Allow camera for this scan?',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Camera opens only for the QR you choose to scan. The payee and amount are still shown before debit.',
              style: TextStyle(
                color: MoolColors.muted,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('allow-scan-camera'),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Allow and scan QR'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('deny-scan-camera'),
                onPressed: () => Navigator.pop(sheetContext, false),
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || allow == null) return;
    if (!allow) {
      widget.session.denyCameraPermission();
      return;
    }
    _account.text = 'QR-MAHADEV-2401';
    await widget.session.verifyScan(
      _account.text,
      int.tryParse(_amount.text) ?? 0,
    );
  }

  Future<void> _pay() async {
    if (!widget.session.prepareScanPayment()) return;
    final record = await widget.session.submitActivePayment();
    if (!mounted || record == null) return;
    _openPaymentResult(context, record);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        return PayPageScaffold(
          session: widget.session,
          title: 'Scan Pay',
          subtitle: 'Verify the payee and amount',
          activeDock: 'pay',
          body: ListView(
            key: const Key('pay-scan-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const PayTrustRow(
                icon: Icons.qr_code_scanner_rounded,
                title: 'No debit from a scan alone',
                detail:
                    'Payee name, QR source, purpose and amount must be confirmed first.',
              ),
              const SizedBox(height: MoolSpacing.md),
              PaySegment<ScanPayType>(
                values: ScanPayType.values,
                selected: widget.session.scanType,
                label: (value) => value.label,
                keyFor: (value) => 'scan-type-${value.name}',
                onSelected: (value) {
                  widget.session.chooseScanType(value);
                  _account.text = value == ScanPayType.upiId
                      ? 'mahadev@upi'
                      : 'QR-MAHADEV-2401';
                  if (value == ScanPayType.orderQr) _amount.text = '645';
                  if (value == ScanPayType.providerQr) _amount.text = '600';
                },
              ),
              const SizedBox(height: MoolSpacing.md),
              PayCard(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('open-scan-camera'),
                        onPressed: _askForCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Scan with camera'),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    TextField(
                      key: const Key('scan-account'),
                      controller: _account,
                      decoration: InputDecoration(
                        labelText: widget.session.scanType == ScanPayType.upiId
                            ? 'UPI ID'
                            : 'QR or payment code',
                        hintText: 'Scan or enter payment details',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    TextField(
                      key: const Key('scan-amount'),
                      controller: _amount,
                      enabled: widget.session.scanType != ScanPayType.orderQr,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('verify-scan-payee'),
                        onPressed: widget.session.busy
                            ? null
                            : () => widget.session.verifyScan(
                                _account.text,
                                int.tryParse(_amount.text) ?? 0,
                              ),
                        icon: widget.session.accountVerified
                            ? const Icon(Icons.verified_rounded)
                            : const Icon(Icons.manage_search_rounded),
                        label: Text(
                          widget.session.accountVerified
                              ? 'Payee and amount verified'
                              : 'Check payee and amount',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.session.accountVerified) ...[
                const SizedBox(height: MoolSpacing.md),
                PayCard(
                  color: const Color(0xFFF5F5FF),
                  child: Column(
                    children: [
                      const PayTrustRow(
                        icon: Icons.verified_user_rounded,
                        title: 'Mahadev Fresh Mart',
                        detail: 'Verified payment account · Jodhpur',
                      ),
                      const Divider(height: MoolSpacing.lg),
                      _ReviewRow(
                        'Purpose',
                        widget.session.scanType == ScanPayType.orderQr
                            ? 'Order #MS2401'
                            : widget.session.scanType == ScanPayType.providerQr
                            ? 'Appointment #DC108'
                            : 'Counter payment',
                      ),
                      _ReviewRow(
                        'Final debit',
                        payMoney(int.tryParse(_amount.text) ?? 0),
                      ),
                      const _ReviewRow(
                        'After payment',
                        'Bank-backed receipt saved',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.md),
              const PaySectionTitle('Pay with'),
              const SizedBox(height: MoolSpacing.sm),
              PayPaymentMethods(session: widget.session),
            ],
          ),
          bottomAction: PayPrimaryButton(
            keyName: 'pay-scan-submit',
            label: 'Pay ${payMoney(int.tryParse(_amount.text) ?? 0)}',
            busy: widget.session.busy,
            onPressed: _pay,
            icon: Icons.lock_rounded,
          ),
        );
      },
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

void _openPaymentResult(BuildContext context, PaymentRecord record) {
  final route = switch (record.outcome) {
    PaymentOutcome.success => '/app/pay/payment/${record.id}/receipt',
    PaymentOutcome.pending => '/app/pay/payment/${record.id}/status',
    PaymentOutcome.failedNoDebit ||
    PaymentOutcome.reversal ||
    PaymentOutcome.reversed => '/app/pay/payment/${record.id}/outcome',
  };
  context.go(route);
}

String _mask(String value) {
  if (value.length <= 4) return value;
  return '${value.substring(0, 2)}••••${value.substring(value.length - 2)}';
}
