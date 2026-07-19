import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_session.dart';
import '../retailer_wholesale_models.dart';
import '../widgets/retailer_widgets.dart';
import 'retailer_wholesale_catalog_screens.dart';

class RetailerWholesaleTrackingScreen extends StatelessWidget {
  const RetailerWholesaleTrackingScreen({
    required this.session,
    super.key,
  });

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final order = session.selectedPurchaseOrder;
        return RetailerPageScaffold(
          session: session,
          title: 'Track delivery',
          subtitle: 'Verified supplier and transport updates',
          activeDock: 'wholesale',
          returnRoute: '/app/retailer/wholesale/orders/confirmed',
          trailing: IconButton.outlined(
            key: const Key('wholesale-delivery-alerts'),
            tooltip: 'Open delivery alerts',
            onPressed: () => showWholesaleSheet(
              context,
              title: 'Delivery alerts',
              detail: 'Purchase-order events that need attention.',
              children: const [
                _TrackingFact(
                  title: 'Dispatch due today · 4 PM',
                  detail: 'PO-MS-8201',
                ),
                _TrackingFact(
                  title: 'Advance protected',
                  detail: 'Awaiting accepted goods receipt',
                ),
              ],
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          bottomAction: order == null
              ? null
              : order.stage == RetailerPurchaseOrderStage.delivered
              ? FilledButton(
                  key: const Key('wholesale-receive-goods'),
                  onPressed: () =>
                      context.go('/app/retailer/wholesale/goods-receipt'),
                  child: const Text('Receive goods'),
                )
              : FilledButton(
                  key: const Key('wholesale-refresh-delivery'),
                  onPressed: session.busy
                      ? null
                      : () async {
                          if (await session.refreshWholesaleDelivery()) {
                            session.advanceWholesaleDelivery();
                          }
                        },
                  child: Text(
                    order.stage == RetailerPurchaseOrderStage.confirmed
                        ? 'Check dispatch'
                        : 'Check latest update',
                  ),
                ),
          body: order == null
              ? Center(
                  child: RetailerEmptyState(
                    keyName: 'wholesale-tracking-empty',
                    title: 'No purchase order to track',
                    detail:
                        'Place a wholesale order before opening delivery tracking.',
                    actionLabel: 'Open wholesale catalogue',
                    onAction: () =>
                        context.go('/app/retailer/wholesale'),
                  ),
                )
              : ListView(
                  key: const Key('wholesale-tracking-screen'),
                  padding: const EdgeInsets.all(MoolSpacing.md),
                  children: [
                    const RetailerSectionTitle(
                      title: 'Purchase orders',
                      detail: 'Choose an order to see its delivery truth',
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final item in session.purchaseOrders)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: MoolSpacing.xxs,
                              ),
                              child: ChoiceChip(
                                key: Key('tracking-order-${item.id}'),
                                label: Text(item.id),
                                selected: item.id == order.id,
                                onSelected: (_) =>
                                    session.selectPurchaseOrder(item.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    _DeliveryTruthCard(order: order),
                    const SizedBox(height: MoolSpacing.sm),
                    RetailerCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${order.id} · ${order.productName}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${order.supplier} · ${order.deliveryMode}',
                                    ),
                                  ],
                                ),
                              ),
                              RetailerPill(
                                label: _stageLabel(order.stage),
                              ),
                            ],
                          ),
                          const SizedBox(height: MoolSpacing.sm),
                          Wrap(
                            spacing: MoolSpacing.md,
                            runSpacing: MoolSpacing.xs,
                            children: [
                              _TrackingFact(
                                title: order.deliveryWindow,
                                detail: 'Delivery window',
                              ),
                              _TrackingFact(
                                title: '${order.cases} cases',
                                detail: 'Expected quantity',
                              ),
                              _TrackingFact(
                                title: order.paymentTerm,
                                detail: 'Payment',
                              ),
                            ],
                          ),
                          const SizedBox(height: MoolSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: const Key('delivery-call'),
                                  onPressed: () => _contactSheet(
                                    context,
                                    order,
                                    call: true,
                                  ),
                                  icon: const Icon(Icons.call_outlined),
                                  label: const Text('Call'),
                                ),
                              ),
                              const SizedBox(width: MoolSpacing.xs),
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: const Key('delivery-chat'),
                                  onPressed: () => _contactSheet(
                                    context,
                                    order,
                                    call: false,
                                  ),
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                  ),
                                  label: const Text('Chat'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              key: const Key('delivery-report-delay'),
                              onPressed: () => _delaySheet(context, order),
                              icon: const Icon(Icons.report_problem_outlined),
                              label: const Text('Report delivery problem'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    RetailerCard(
                      color: const Color(0xFFFFF4E6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: MoolColors.orange,
                          ),
                          const SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: Text(
                              order.paymentTerm.contains('advance')
                                  ? 'Protected advance is not released until accepted receipt.'
                                  : 'Supplier payment begins only after accepted receipt.',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _stageLabel(RetailerPurchaseOrderStage stage) => switch (stage) {
    RetailerPurchaseOrderStage.confirmed => 'CONFIRMED',
    RetailerPurchaseOrderStage.dispatched => 'DISPATCHED',
    RetailerPurchaseOrderStage.inTransit => 'IN TRANSIT',
    RetailerPurchaseOrderStage.delivered => 'DELIVERED',
    RetailerPurchaseOrderStage.received => 'RECEIVED',
    RetailerPurchaseOrderStage.issueOpen => 'ISSUE OPEN',
  };

  Future<void> _contactSheet(
    BuildContext context,
    RetailerPurchaseOrder order, {
    required bool call,
  }) => showWholesaleSheet(
    context,
    title: call ? 'Call delivery contact' : 'Delivery chat',
    detail: '${order.id} · ${order.deliveryMode}',
    children: [
      _TrackingFact(
        title: order.stage.index >= RetailerPurchaseOrderStage.inTransit.index
            ? 'Rakesh Kumar'
            : order.supplier,
        detail: call ? 'Verified delivery contact' : 'PO-linked thread',
      ),
      _TrackingFact(
        title: order.deliveryWindow,
        detail: 'Committed delivery',
      ),
      const SizedBox(height: MoolSpacing.sm),
      FilledButton(
        key: Key(call ? 'delivery-start-call' : 'delivery-open-chat'),
        onPressed: () {
          Navigator.pop(context);
          session.showNotice(
            call
                ? 'Calling the verified contact for ${order.id}.'
                : 'PO-linked delivery chat opened for ${order.id}.',
          );
        },
        child: Text(call ? 'Call now' : 'Open chat'),
      ),
    ],
  );

  Future<void> _delaySheet(
    BuildContext context,
    RetailerPurchaseOrder order,
  ) => showWholesaleSheet(
    context,
    title: 'Report delivery problem',
    detail: '${order.id} · ${order.deliveryWindow}',
    children: [
      for (final reason in const [
        'Not dispatched',
        'ETA changed',
        'No movement',
        'Contact failed',
      ])
        ListTile(
          key: Key(
            'delivery-problem-${reason.toLowerCase().replaceAll(' ', '-')}',
          ),
          title: Text(reason),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            session.showNotice(
              '$reason reported for ${order.id}. Supplier settlement remains protected.',
            );
          },
        ),
    ],
  );
}

class _DeliveryTruthCard extends StatelessWidget {
  const _DeliveryTruthCard({required this.order});

  final RetailerPurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final live =
        order.stage == RetailerPurchaseOrderStage.inTransit ||
        order.stage == RetailerPurchaseOrderStage.delivered;
    return RetailerCard(
      color: live ? MoolColors.navy : const Color(0xFFEDEEFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            live ? Icons.local_shipping_rounded : Icons.schedule_rounded,
            color: live ? Colors.white : MoolColors.navy,
            size: 36,
          ),
          const SizedBox(height: MoolSpacing.sm),
          Text(
            live
                ? order.stage == RetailerPurchaseOrderStage.delivered
                      ? 'Delivered to your shop'
                      : 'Live delivery update'
                : 'Live tracking starts after dispatch',
            style: TextStyle(
              color: live ? Colors.white : MoolColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            live
                ? order.stage == RetailerPurchaseOrderStage.delivered
                      ? 'Delivered at 11:08 AM · receipt confirmation pending'
                      : 'Ratanada Circle · ETA 42 min · updated now'
                : '${order.supplier} is responsible for dispatch. Until verified telemetry arrives, only committed times are shown.',
            style: TextStyle(
              color: live ? const Color(0xFFD9DAFF) : MoolColors.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class RetailerGoodsReceiptScreen extends StatelessWidget {
  const RetailerGoodsReceiptScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final issue =
            session.receiptChoice == RetailerGoodsReceiptChoice.issue;
        return RetailerPageScaffold(
          session: session,
          title: 'Receive goods',
          subtitle: 'Count, condition, invoice and settlement',
          activeDock: 'wholesale',
          returnRoute: '/app/retailer/wholesale/orders/tracking',
          trailing: IconButton.outlined(
            key: const Key('goods-receipt-help'),
            tooltip: 'Goods receipt help',
            onPressed: () => showWholesaleSheet(
              context,
              title: 'Before confirming receipt',
              detail: 'Check each result against the delivered goods.',
              children: const [
                _TrackingFact(
                  title: 'Count cases',
                  detail: 'Compare with the purchase order',
                ),
                _TrackingFact(
                  title: 'Check condition',
                  detail: 'Damage, leakage, batch and expiry',
                ),
                _TrackingFact(
                  title: 'Check invoice',
                  detail: 'GSTIN, quantity and value',
                ),
                _TrackingFact(
                  title: 'Attach evidence',
                  detail: 'Required for discrepancies',
                ),
              ],
            ),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          bottomAction: FilledButton(
            key: const Key('goods-confirm-receipt'),
            onPressed:
                session.busy ||
                    session.receiptChoice ==
                        RetailerGoodsReceiptChoice.pending
                ? null
                : () => _confirm(context),
            child: Text(issue ? 'Submit issue' : 'Confirm receipt'),
          ),
          body: ListView(
            key: const Key('goods-receipt-screen'),
            padding: const EdgeInsets.all(MoolSpacing.md),
            children: [
              const RetailerSectionTitle(
                title: 'Check quantity & condition',
                detail: 'Stock and supplier payment remain on hold',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aashirvaad Whole Wheat Atta',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text('4 × 5 kg per case · INV-SM-2941'),
                            ],
                          ),
                        ),
                        RetailerPill(label: '3 CASES'),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _TrackingFact(
                            title: issue ? '2 cases' : '3 cases',
                            detail: session.receiptChoice ==
                                    RetailerGoodsReceiptChoice.pending
                                ? 'To verify'
                                : 'Accepted',
                          ),
                        ),
                        Expanded(
                          child: _TrackingFact(
                            title: issue ? '1 case short' : 'No issue',
                            detail: 'Condition',
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
                    child: _ReceiptChoiceCard(
                      keyName: 'goods-all-received',
                      title: 'All received',
                      detail: '3 cases · good condition',
                      selected:
                          session.receiptChoice ==
                          RetailerGoodsReceiptChoice.accepted,
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () => session.chooseGoodsReceipt(
                        RetailerGoodsReceiptChoice.accepted,
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _ReceiptChoiceCard(
                      keyName: 'goods-report-issue',
                      title: 'Report issue',
                      detail: 'Short, damaged or mismatch',
                      selected: issue,
                      icon: Icons.report_problem_outlined,
                      onTap: () => _chooseIssue(context),
                    ),
                  ),
                ],
              ),
              if (issue) ...[
                const SizedBox(height: MoolSpacing.sm),
                RetailerCard(
                  color: const Color(0xFFFFEBEA),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.goodsIssue?.label ?? 'Goods issue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Only accepted goods enter stock. The disputed amount remains protected.',
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('goods-evidence-denied'),
                              onPressed: () => session.attachGoodsEvidence(
                                permissionGranted: false,
                              ),
                              icon: const Icon(Icons.no_photography_outlined),
                              label: const Text('No camera'),
                            ),
                          ),
                          const SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: FilledButton.icon(
                              key: const Key('goods-attach-evidence'),
                              onPressed: () => session.attachGoodsEvidence(
                                permissionGranted: true,
                              ),
                              icon: Icon(
                                session.goodsEvidenceAttached
                                    ? Icons.check_rounded
                                    : Icons.add_a_photo_outlined,
                              ),
                              label: Text(
                                session.goodsEvidenceAttached
                                    ? 'Attached'
                                    : 'Add photo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Invoice & payment',
                detail: 'Linked to accepted quantity',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'goods-view-invoice',
                onTap: () => showWholesaleSheet(
                  context,
                  title: 'GST tax invoice',
                  detail: 'INV-SM-2941 · Supermandi Tech Pvt Ltd',
                  children: const [
                    _TrackingFact(
                      title: '₹2,856',
                      detail: 'Invoice value',
                    ),
                    _TrackingFact(
                      title: '3 cases · 12 packs',
                      detail: 'Invoice quantity',
                    ),
                    _TrackingFact(title: 'HSN 1001', detail: 'GST 5%'),
                    _TrackingFact(
                      title: '08ABCDE1234F1Z5',
                      detail: 'Buyer GSTIN',
                    ),
                  ],
                ),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('GST tax invoice INV-SM-2941'),
                  subtitle: Text('Match invoice against accepted goods'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                color: issue
                    ? const Color(0xFFFFEBEA)
                    : const Color(0xFFEDEEFF),
                child: Row(
                  children: [
                    Expanded(
                      child: _TrackingFact(
                        title: issue ? 'Held' : '₹856.80',
                        detail: 'Protected advance',
                      ),
                    ),
                    Expanded(
                      child: _TrackingFact(
                        title: issue ? 'Accepted goods only' : '₹1,999.20',
                        detail: 'Balance on delivery',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _chooseIssue(BuildContext context) => showWholesaleSheet(
    context,
    title: 'What is wrong?',
    detail: 'Choose the issue before stock or payment is posted.',
    children: [
      for (final issue in RetailerGoodsIssue.values)
        ListTile(
          key: Key('goods-issue-${issue.name}'),
          title: Text(issue.label),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            session.chooseGoodsIssue(issue);
          },
        ),
    ],
  );

  Future<void> _confirm(BuildContext context) => showWholesaleSheet(
    context,
    title: session.receiptChoice == RetailerGoodsReceiptChoice.issue
        ? 'Submit goods issue?'
        : 'Post goods receipt?',
    detail:
        'This action updates accepted stock and the linked supplier obligation once.',
    children: [
      _TrackingFact(
        title:
            session.receiptChoice == RetailerGoodsReceiptChoice.issue
            ? '8 packs'
            : '12 packs',
        detail: 'Accepted stock',
      ),
      _TrackingFact(
        title:
            session.receiptChoice == RetailerGoodsReceiptChoice.issue
            ? 'Disputed amount held'
            : 'Payment release begins',
        detail: 'Supplier settlement',
      ),
      const SizedBox(height: MoolSpacing.sm),
      FilledButton(
        key: const Key('goods-post-receipt'),
        onPressed: session.busy
            ? null
            : () async {
                Navigator.pop(context);
                if (await session.postGoodsReceipt() && context.mounted) {
                  context.go(
                    '/app/retailer/wholesale/goods-receipt/result',
                  );
                }
              },
        child: const Text('Post receipt'),
      ),
      const SizedBox(height: MoolSpacing.xs),
      OutlinedButton(
        key: const Key('goods-cancel-receipt'),
        onPressed: () => Navigator.pop(context),
        child: const Text('Check again'),
      ),
    ],
  );
}

class _ReceiptChoiceCard extends StatelessWidget {
  const _ReceiptChoiceCard({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String keyName;
  final String title;
  final String detail;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      keyName: keyName,
      color: selected ? const Color(0xFFEDEEFF) : Colors.white,
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: MoolColors.navy),
          const SizedBox(height: MoolSpacing.xs),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class RetailerGoodsReceiptResultScreen extends StatelessWidget {
  const RetailerGoodsReceiptResultScreen({
    required this.session,
    super.key,
  });

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    final issue =
        session.receiptChoice == RetailerGoodsReceiptChoice.issue;
    return RetailerPageScaffold(
      session: session,
      title: issue ? 'Receipt posted with issue' : 'Receipt posted',
      subtitle: 'Stock, purchase and payment records',
      activeDock: 'wholesale',
      returnRoute: '/app/retailer/wholesale/goods-receipt',
      trailing: IconButton.outlined(
        key: const Key('receipt-result-help'),
        tooltip: 'Receipt result help',
        onPressed: () => session.showNotice(
          'This screen shows posted business records, not estimates.',
        ),
        icon: const Icon(Icons.help_outline_rounded),
      ),
      bottomAction: FilledButton(
        key: const Key('receipt-open-purchase-book'),
        onPressed: () => context.go('/app/retailer/books/purchases'),
        child: const Text('View Purchase Book'),
      ),
      body: ListView(
        key: const Key('goods-receipt-result-screen'),
        padding: const EdgeInsets.all(MoolSpacing.md),
        children: [
          RetailerCard(
            color: issue
                ? const Color(0xFFFFF4E6)
                : const Color(0xFFEAF7E8),
            child: Row(
              children: [
                Icon(
                  issue
                      ? Icons.report_problem_outlined
                      : Icons.check_circle_rounded,
                  color: issue ? MoolColors.orange : MoolColors.success,
                  size: 40,
                ),
                const SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue
                            ? 'Accepted stock posted; case open'
                            : 'Business records updated',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        issue
                            ? 'Disputed quantity remains outside stock and payment.'
                            : 'The same receipt cannot post stock twice.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          for (final result in <(String, String, String, IconData)>[
            (
              'stock',
              issue ? '8 packs added' : '12 packs added',
              '${session.acceptedStockPacks} packs available',
              Icons.inventory_2_outlined,
            ),
            (
              'payment',
              issue ? 'Settlement held' : '₹856.80 release processing',
              issue
                  ? 'Issue resolution required'
                  : 'Balance ₹1,999.20 authorized',
              Icons.account_balance_wallet_outlined,
            ),
            (
              'ledger',
              issue ? '₹1,904 posted' : '₹2,856 posted',
              'Purchase Book · accepted value',
              Icons.auto_stories_outlined,
            ),
            (
              'grn',
              session.goodsReceiptId ?? 'GRN pending',
              issue ? 'Issue evidence linked' : 'No discrepancy',
              Icons.description_outlined,
            ),
            (
              'invoice',
              'INV-SM-2941',
              'GST invoice matched to accepted quantity',
              Icons.receipt_long_outlined,
            ),
          ]) ...[
            RetailerCard(
              keyName: 'receipt-result-${result.$1}',
              onTap: () => showWholesaleSheet(
                context,
                title: result.$2,
                detail: result.$3,
                children: [
                  _TrackingFact(
                    title: session.goodsReceiptId ?? 'GRN-85021',
                    detail: 'Goods receipt reference',
                  ),
                  const _TrackingFact(
                    title: 'PO-MS-8202',
                    detail: 'Purchase order',
                  ),
                  const _TrackingFact(
                    title: 'Audited once',
                    detail: 'Idempotent business event',
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(result.$4, color: MoolColors.navy),
                title: Text(
                  result.$2,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(result.$3),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
          ],
          OutlinedButton.icon(
            key: const Key('receipt-view-stock'),
            onPressed: () =>
                context.go('/app/retailer/home?view=stock'),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('View updated stock'),
          ),
        ],
      ),
    );
  }
}

class _TrackingFact extends StatelessWidget {
  const _TrackingFact({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(
            detail,
            style: const TextStyle(color: MoolColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
