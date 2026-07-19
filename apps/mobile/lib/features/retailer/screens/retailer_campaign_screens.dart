import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_campaign_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';

String _campaignMoney(int value) {
  if (value < 1000) return '₹$value';
  final raw = value.toString();
  return '₹${raw.substring(0, raw.length - 3)},${raw.substring(raw.length - 3)}';
}

class RetailerCustomersScreen extends StatelessWidget {
  const RetailerCustomersScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Customers',
        subtitle: 'Orders, baskets, dues and permissions',
        activeDock: 'none',
        returnRoute: '/app/retailer/home',
        trailing: IconButton.outlined(
          key: const Key('customers-open-campaigns'),
          tooltip: 'Open offers and campaigns',
          onPressed: () => context.go('/app/retailer/campaigns'),
          icon: const Icon(Icons.campaign_outlined),
        ),
        body: RefreshIndicator(
          key: const Key('customers-refresh'),
          onRefresh: session.refreshCustomers,
          child: ListView(
            key: const Key('customers-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              TextField(
                key: const Key('customer-search'),
                onChanged: session.setCustomerSearch,
                decoration: InputDecoration(
                  labelText: 'Search name, mobile or invoice',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    key: const Key('customer-voice-search'),
                    tooltip: 'Search by voice',
                    onPressed: () => session.setCustomerSearch('Sharma Family'),
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'CUSTOMERS',
                      value: '1,284',
                      detail: 'Consented',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _Metric(
                      label: 'REPEAT',
                      value: '218',
                      detail: '17% this month',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _Metric(
                      label: 'CREDIT DUE',
                      value: '₹18,400',
                      detail: '11 customers',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in RetailerCustomerFilter.values) ...[
                      ChoiceChip(
                        key: Key('customer-filter-${filter.name}'),
                        label: Text(filter.label),
                        selected: session.customerFilter == filter,
                        onSelected: (_) => session.setCustomerFilter(filter),
                      ),
                      const SizedBox(width: MoolSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                keyName: 'repeat-offer-hero',
                color: const Color(0xFFEAF7E8),
                onTap: () =>
                    context.go('/app/retailer/campaigns/new?audience=repeat'),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: MoolColors.success,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.repeat_rounded),
                        ),
                        SizedBox(width: MoolSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '86 customers may need staples again',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'Based on purchase timing and current permission',
                                style: TextStyle(
                                  color: MoolColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MoolSpacing.sm),
                    Divider(height: 1),
                    SizedBox(height: MoolSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Prepare a stock-backed repeat offer',
                            style: TextStyle(
                              color: MoolColors.success,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: MoolColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerSectionTitle(
                title: 'Customer records',
                detail: '${session.filteredCustomers.length} shown',
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (session.filteredCustomers.isEmpty)
                RetailerEmptyState(
                  keyName: 'customers-empty',
                  title: 'No matching customer',
                  detail:
                      'Clear the search or choose another permission-aware filter.',
                  actionLabel: 'Show all customers',
                  onAction: () {
                    session.setCustomerSearch('');
                    session.setCustomerFilter(RetailerCustomerFilter.all);
                  },
                )
              else
                for (final customer in session.filteredCustomers) ...[
                  _CustomerCard(
                    customer: customer,
                    onTap: () {
                      session.selectCustomer(customer.id);
                      context.go('/app/retailer/customers/${customer.id}');
                    },
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                ],
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('customer-repeat-baskets'),
                      onPressed: () => context.go(
                        '/app/retailer/campaigns/new?audience=repeat',
                      ),
                      icon: const Icon(Icons.shopping_basket_outlined),
                      label: const Text('Repeat baskets'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('customer-loyalty'),
                      onPressed: () =>
                          context.go('/app/retailer/campaigns?filter=loyalty'),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Loyalty'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.xs),
              OutlinedButton.icon(
                key: const Key('customer-permissions'),
                onPressed: () =>
                    session.setCustomerFilter(RetailerCustomerFilter.allowed),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Show customers who allow offers'),
              ),
              const SizedBox(height: MoolSpacing.sm),
              const RetailerCard(
                color: Color(0xFFF4F3FF),
                child: Text(
                  'Invoices are always independent of marketing permission. Credit stays explicit, open issues appear before promotion, and every reminder is audited.',
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});

  final RetailerCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = customer.issue
        ? const Color(0xFFB42318)
        : customer.due
        ? const Color(0xFFB05C00)
        : MoolColors.success;
    return RetailerCard(
      keyName: 'customer-${customer.id}',
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            foregroundColor: color,
            child: Text(
              customer.name.split(' ').take(2).map((word) => word[0]).join(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
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
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    RetailerPill(
                      label: customer.issue
                          ? 'ISSUE'
                          : customer.due
                          ? 'DUE'
                          : customer.allowed
                          ? 'ALLOWED'
                          : 'INVOICE',
                      color: color,
                    ),
                  ],
                ),
                Text(
                  '${customer.orders} orders · last buy ${customer.lastBuy} · ${customer.fulfilment}',
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
                Text(
                  '${customer.summary} · ${customer.detail}',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class RetailerCustomerDetailScreen extends StatelessWidget {
  const RetailerCustomerDetailScreen({
    required this.session,
    required this.customerId,
    super.key,
  });

  final RetailerSession session;
  final String customerId;

  @override
  Widget build(BuildContext context) {
    if (session.selectedCustomerId != customerId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        session.selectCustomer(customerId);
      });
    }
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final customer = session.selectedCustomer;
        return RetailerPageScaffold(
          session: session,
          title: customer.name,
          subtitle: 'Orders, permission and repeat basket',
          activeDock: 'none',
          returnRoute: '/app/retailer/customers',
          trailing: IconButton.outlined(
            key: const Key('customer-open-chat'),
            tooltip: 'Open customer chat',
            onPressed: () => context.go(
              '/app/chat/inbox?return=/app/retailer/customers/${customer.id}',
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          body: ListView(
            key: const Key('customer-detail-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              RetailerCard(
                color: const Color(0xFFF4F3FF),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 27,
                      backgroundColor: MoolColors.navy,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Trusted customer · Jodhpur',
                            style: TextStyle(color: MoolColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const RetailerPill(
                      label: 'VERIFIED',
                      icon: Icons.verified_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              const Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'ORDERS',
                      value: '18',
                      detail: '₹11,840',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _Metric(
                      label: 'LAST BUY',
                      value: '4 days',
                      detail: 'Ago',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _Metric(
                      label: 'CREDIT DUE',
                      value: '₹0',
                      detail: 'Clear',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Marketing permission',
                detail: 'Current customer choices control every reminder',
              ),
              const SizedBox(height: MoolSpacing.sm),
              const RetailerCard(
                child: Column(
                  children: [
                    _PermissionRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Mool Chat',
                      state: 'Allowed',
                      enabled: true,
                    ),
                    Divider(),
                    _PermissionRow(
                      icon: Icons.call_outlined,
                      label: 'WhatsApp',
                      state: 'Allowed',
                      enabled: true,
                    ),
                    Divider(),
                    _PermissionRow(
                      icon: Icons.sms_outlined,
                      label: 'SMS',
                      state: 'Off',
                      enabled: false,
                    ),
                    Divider(),
                    _PermissionRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Invoices',
                      state: 'Always available',
                      enabled: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Usual basket',
                detail: 'Current stock and price are checked before order',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'customer-repeat-basket',
                child: Column(
                  children: [
                    const _BasketLine(name: 'Aashirvaad Atta 5 kg', price: 286),
                    const _BasketLine(name: 'Fortune Oil 1 L', price: 132),
                    const _BasketLine(name: 'India Gate Rice', price: 227),
                    const Divider(),
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            '3 items · current basket',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '₹645',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('customer-edit-basket'),
                            onPressed: () => session.showNotice(
                              'Basket is ready to edit. Current stock and price will be checked before order.',
                            ),
                            child: const Text('Edit basket'),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: FilledButton(
                            key: const Key('customer-create-order'),
                            onPressed: () => context.go(
                              '/app/retailer/orders/new?source=phone&customer=${customer.id}',
                            ),
                            child: const Text('Create order'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                keyName: 'customer-order-history',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order history',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    ListTile(
                      key: const Key('customer-invoice-2840'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Invoice MS-2840'),
                      subtitle: const Text('Paid · home delivery'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.go('/app/retailer/books/sales'),
                    ),
                    ListTile(
                      key: const Key('customer-invoice-2712'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Invoice MS-2712'),
                      subtitle: const Text('Paid · counter pickup'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.go('/app/retailer/books/sales'),
                    ),
                    ListTile(
                      key: const Key('customer-resolved-issue'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Previous issue resolved'),
                      subtitle: const Text(
                        'Replacement accepted · audit record retained',
                      ),
                      trailing: const Icon(Icons.verified_outlined),
                      onTap: () => session.showNotice(
                        'Issue MS-2718 was resolved with accepted replacement proof.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Permitted reminder',
                detail: 'Sending a reminder never creates an order',
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                children: [
                  for (final channel in RetailerMessageChannel.values)
                    ChoiceChip(
                      key: Key('reminder-channel-${channel.name}'),
                      label: Text(channel.label),
                      selected: session.reminderChannel == channel,
                      onSelected: channel == RetailerMessageChannel.sms
                          ? null
                          : (_) => session.setReminderChannel(channel),
                    ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextFormField(
                key: const Key('reminder-message'),
                initialValue: session.reminderMessage,
                minLines: 3,
                maxLines: 4,
                onChanged: session.setReminderMessage,
                decoration: const InputDecoration(
                  labelText: 'Message preview',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              FilledButton.icon(
                key: const Key('send-customer-reminder'),
                onPressed: session.busy
                    ? null
                    : () => session.sendCustomerReminder(),
                icon: session.busy
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  session.reminderMessageId == null
                      ? 'Send by ${session.reminderChannel.label}'
                      : 'Reminder sent',
                ),
              ),
              if (session.reminderMessageId != null)
                TextButton.icon(
                  key: const Key('view-reminder-log'),
                  onPressed: () => context.go(
                    '/app/chat/inbox?return=/app/retailer/customers/${customer.id}',
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View message log'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class RetailerCampaignsScreen extends StatelessWidget {
  const RetailerCampaignsScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Offers & Campaigns',
        subtitle: 'Stock-backed promotions with measured results',
        activeDock: 'none',
        returnRoute: '/app/retailer/home',
        trailing: IconButton.outlined(
          key: const Key('campaign-services'),
          tooltip: 'Campaign services',
          onPressed: () => context.go('/app/retailer/services'),
          icon: const Icon(Icons.support_agent_rounded),
        ),
        body: RefreshIndicator(
          key: const Key('campaigns-refresh'),
          onRefresh: session.refreshCampaigns,
          child: ListView(
            key: const Key('campaigns-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              RetailerSectionTitle(
                title: 'Campaign performance',
                detail: 'Only paid, non-refunded attributed orders count',
                trailing: _CompactAction(
                  key: const Key('campaign-create'),
                  label: 'Create',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    session.resetCampaignBuilder();
                    context.go('/app/retailer/campaigns/new');
                  },
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'ACTIVE',
                      value: '3',
                      detail: '2 on target',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _Metric(
                      label: 'PAID SALES',
                      value: '₹42,680',
                      detail: '₹31,450 paid',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _Metric(
                      label: 'SPEND',
                      value: '₹3,240',
                      detail: 'Within ₹5,000',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in RetailerCampaignFilter.values) ...[
                      ChoiceChip(
                        key: Key('campaign-filter-${filter.name}'),
                        label: Text(filter.label),
                        selected: session.campaignFilter == filter,
                        onSelected: (_) => session.setCampaignFilter(filter),
                      ),
                      const SizedBox(width: MoolSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                keyName: 'campaign-use-again',
                color: const Color(0xFFEAF7E8),
                onTap: () {
                  session.resetCampaignBuilder(cloneId: 'monthly');
                  context.go('/app/retailer/campaigns/new?clone=monthly');
                },
                child: const Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: MoolColors.success,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.auto_graph_rounded),
                        ),
                        SizedBox(width: MoolSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly staples is converting',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '62 paid orders · 4.8× attributed sales/spend',
                                style: TextStyle(
                                  color: MoolColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MoolSpacing.sm),
                    Divider(height: 1),
                    SizedBox(height: MoolSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Use this proven setup again',
                            style: TextStyle(
                              color: MoolColors.success,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: MoolColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerSectionTitle(
                title: 'Campaigns',
                detail: '${session.filteredCampaigns.length} shown',
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (session.filteredCampaigns.isEmpty)
                RetailerEmptyState(
                  keyName: 'campaigns-empty',
                  title: 'No campaign in this view',
                  detail:
                      'Choose another filter or create a stock-backed campaign.',
                  actionLabel: 'Create campaign',
                  onAction: () {
                    session.resetCampaignBuilder();
                    context.go('/app/retailer/campaigns/new');
                  },
                )
              else
                for (final campaign in session.filteredCampaigns) ...[
                  _CampaignCard(
                    campaign: campaign,
                    onPrimary: () {
                      session.resetCampaignBuilder(
                        cloneId: campaign.id == 'monthly' ? 'monthly' : null,
                      );
                      context.go(
                        '/app/retailer/campaigns/new?edit=${campaign.id}',
                      );
                    },
                    onPause: campaign.state == RetailerCampaignState.active
                        ? () => _confirmPause(context, campaign)
                        : null,
                    onDelete: campaign.state == RetailerCampaignState.draft
                        ? () => _confirmDelete(context, campaign)
                        : null,
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                ],
              const RetailerCard(
                color: Color(0xFFF4F3FF),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, color: MoolColors.navy),
                    SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: Text(
                        'Spend never exceeds the approved cap. Views and unverified leads are not billed as sales. Completed attribution stays locked.',
                        style: TextStyle(
                          color: MoolColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPause(
    BuildContext context,
    RetailerCampaign campaign,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('pause-campaign-dialog'),
        title: const Text('Pause this campaign?'),
        content: const Text(
          'New eligible campaign spend will stop. Existing paid order attribution remains recorded.',
        ),
        actions: [
          TextButton(
            key: const Key('pause-campaign-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep active'),
          ),
          FilledButton(
            key: const Key('pause-campaign-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Pause campaign'),
          ),
        ],
      ),
    );
    if (confirmed == true) await session.pauseCampaign(campaign.id);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RetailerCampaign campaign,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('delete-campaign-dialog'),
        title: const Text('Delete this draft?'),
        content: const Text(
          'No active campaign, customer message, stock or budget will be changed.',
        ),
        actions: [
          TextButton(
            key: const Key('delete-campaign-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep draft'),
          ),
          FilledButton(
            key: const Key('delete-campaign-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete draft'),
          ),
        ],
      ),
    );
    if (confirmed == true) await session.deleteCampaignDraft(campaign.id);
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.onPrimary,
    this.onPause,
    this.onDelete,
  });

  final RetailerCampaign campaign;
  final VoidCallback onPrimary;
  final VoidCallback? onPause;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final active = campaign.state == RetailerCampaignState.active;
    final paused = campaign.state == RetailerCampaignState.paused;
    final completed = campaign.state == RetailerCampaignState.completed;
    final color = active
        ? MoolColors.success
        : paused
        ? const Color(0xFFB05C00)
        : completed
        ? MoolColors.navy
        : MoolColors.muted;
    return RetailerCard(
      keyName: 'campaign-${campaign.id}',
      color: active ? const Color(0xFFF7FFF4) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              RetailerPill(
                label: campaign.state.name.toUpperCase(),
                color: color,
              ),
            ],
          ),
          Text(
            campaign.detail,
            style: const TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          if (campaign.state != RetailerCampaignState.draft) ...[
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _CompactStat(
                    value: _campaignMoney(campaign.paidSales),
                    label: 'Paid sales',
                  ),
                ),
                Expanded(
                  child: _CompactStat(
                    value: _campaignMoney(campaign.spend),
                    label: 'Spend',
                  ),
                ),
                Expanded(
                  child: _CompactStat(value: campaign.result, label: 'Result'),
                ),
              ],
            ),
          ],
          if (onPause != null || onDelete != null || !completed) ...[
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                if (onPause != null)
                  Expanded(
                    child: OutlinedButton(
                      key: Key('campaign-pause-${campaign.id}'),
                      onPressed: onPause,
                      child: const Text('Pause'),
                    ),
                  ),
                if (onDelete != null)
                  Expanded(
                    child: OutlinedButton(
                      key: Key('campaign-delete-${campaign.id}'),
                      onPressed: onDelete,
                      child: const Text('Delete'),
                    ),
                  ),
                if (!completed) ...[
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: FilledButton(
                      key: Key('campaign-open-${campaign.id}'),
                      onPressed: onPrimary,
                      child: Text(
                        campaign.state == RetailerCampaignState.draft
                            ? 'Continue'
                            : 'View details',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class RetailerCampaignBuilderScreen extends StatelessWidget {
  const RetailerCampaignBuilderScreen({required this.session, super.key});

  final RetailerSession session;

  static const _stepNames = ['Outcome', 'Products', 'Audience', 'Review'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Create campaign',
        subtitle: 'Stock, audience, benefit and spend control',
        activeDock: 'none',
        returnRoute: '/app/retailer/campaigns',
        trailing: TextButton(
          key: const Key('campaign-save-draft'),
          onPressed: session.busy ? null : () => session.saveCampaignDraft(),
          child: Text(session.campaignDraftId == null ? 'Save draft' : 'Saved'),
        ),
        bottomAction: Row(
          children: [
            if (session.campaignBuilderStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  key: const Key('campaign-previous'),
                  onPressed: () =>
                      session.goToCampaignStep(session.campaignBuilderStep - 1),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
            ],
            Expanded(
              child: FilledButton.icon(
                key: const Key('campaign-continue'),
                onPressed: session.busy
                    ? null
                    : () async {
                        if (session.campaignBuilderStep < 3) {
                          session.continueCampaignBuilder();
                          return;
                        }
                        final completed = await session.publishCampaign();
                        if (completed && context.mounted) {
                          context.go('/app/retailer/campaigns');
                        }
                      },
                icon: session.busy
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        session.campaignBuilderStep == 3
                            ? Icons.rocket_launch_outlined
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  session.campaignBuilderStep == 3
                      ? 'Publish campaign'
                      : 'Continue',
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          key: const Key('campaign-builder-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            Row(
              children: [
                for (var index = 0; index < _stepNames.length; index += 1) ...[
                  Expanded(
                    child: InkWell(
                      key: Key('campaign-step-$index'),
                      borderRadius: BorderRadius.circular(MoolRadii.control),
                      onTap: () => session.goToCampaignStep(index),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 5,
                            decoration: BoxDecoration(
                              color: index <= session.campaignBuilderStep
                                  ? MoolColors.navy
                                  : MoolColors.line,
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _stepNames[index],
                            style: TextStyle(
                              color: index == session.campaignBuilderStep
                                  ? MoolColors.navy
                                  : MoolColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < _stepNames.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            Container(
              key: const Key('campaign-current-step'),
              padding: const EdgeInsets.symmetric(
                horizontal: MoolSpacing.sm,
                vertical: MoolSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F3FF),
                borderRadius: BorderRadius.circular(MoolRadii.control),
                border: Border.all(color: MoolColors.line),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: MoolColors.navy,
                    foregroundColor: Colors.white,
                    child: Text(
                      '${session.campaignBuilderStep + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: Text(
                      '${_stepNames[session.campaignBuilderStep]} · Step ${session.campaignBuilderStep + 1} of 4',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.checklist_rounded,
                    color: MoolColors.navy,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (session.campaignBuilderStep) {
                0 => _OutcomeStep(session: session),
                1 => _ProductsStep(session: session),
                2 => _AudienceStep(session: session),
                _ => _ReviewStep(session: session),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeStep extends StatelessWidget {
  const _OutcomeStep({required this.session});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('campaign-outcome-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RetailerSectionTitle(
          title: 'What result do you want?',
          detail: 'One clear outcome controls the campaign setup',
        ),
        const SizedBox(height: MoolSpacing.sm),
        for (final objective in RetailerCampaignObjective.values) ...[
          _SelectRow(
            keyName: 'campaign-objective-${objective.name}',
            title: objective.label,
            selected: session.campaignObjective == objective,
            onTap: () => session.setCampaignObjective(objective),
          ),
          const SizedBox(height: MoolSpacing.xs),
        ],
        const SizedBox(height: MoolSpacing.sm),
        TextFormField(
          key: const Key('campaign-name'),
          initialValue: session.campaignName,
          onChanged: session.setCampaignName,
          decoration: const InputDecoration(labelText: 'Campaign name'),
        ),
      ],
    );
  }
}

class _ProductsStep extends StatelessWidget {
  const _ProductsStep({required this.session});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('campaign-products-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RetailerSectionTitle(
          title: 'Choose sellable products',
          detail: 'Orders cannot exceed the lowest selected available stock',
        ),
        const SizedBox(height: MoolSpacing.sm),
        TextField(
          key: const Key('campaign-product-search'),
          decoration: InputDecoration(
            labelText: 'Search shop stock',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              key: const Key('campaign-scan-product'),
              tooltip: 'Scan product',
              onPressed: () =>
                  session.showNotice('Scanner ready for a shop product code.'),
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        for (final product in reviewCampaignProducts) ...[
          CheckboxListTile(
            key: Key('campaign-product-${product.id}'),
            value: session.campaignProductIds.contains(product.id),
            onChanged: (_) => session.toggleCampaignProduct(product.id),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MoolSpacing.sm,
            ),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MoolRadii.control),
              side: const BorderSide(color: MoolColors.line),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '${product.available} available · ₹${product.price} · ${product.margin}% margin',
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
        ],
        const SizedBox(height: MoolSpacing.sm),
        const Text(
          'Customer benefit',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        Wrap(
          spacing: MoolSpacing.xs,
          children: [
            for (final benefit in RetailerCampaignBenefit.values)
              ChoiceChip(
                key: Key('campaign-benefit-${benefit.name}'),
                label: Text(benefit.label),
                selected: session.campaignBenefit == benefit,
                onSelected: (_) => session.setCampaignBenefit(benefit),
              ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        TextFormField(
          key: const Key('campaign-max-orders'),
          initialValue: '${session.campaignMaximumOrders}',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final parsed = int.tryParse(value);
            if (parsed != null) session.setCampaignMaximumOrders(parsed);
          },
          decoration: const InputDecoration(
            labelText: 'Maximum customer orders',
          ),
        ),
      ],
    );
  }
}

class _AudienceStep extends StatelessWidget {
  const _AudienceStep({required this.session});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('campaign-audience-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RetailerSectionTitle(
          title: 'Choose permitted audience',
          detail: 'Channels use each customer’s current permission',
        ),
        const SizedBox(height: MoolSpacing.sm),
        Wrap(
          spacing: MoolSpacing.xs,
          runSpacing: MoolSpacing.xs,
          children: [
            for (final audience in RetailerCampaignAudience.values)
              ChoiceChip(
                key: Key('campaign-audience-${audience.name}'),
                label: Text(audience.label),
                selected: session.campaignAudience == audience,
                onSelected: (_) => session.setCampaignAudience(audience),
              ),
          ],
        ),
        const SizedBox(height: MoolSpacing.md),
        const Text('Area', style: TextStyle(fontWeight: FontWeight.w900)),
        SegmentedButton<int>(
          key: const Key('campaign-radius'),
          segments: const [
            ButtonSegment(value: 5, label: Text('Jodhpur 5 km')),
            ButtonSegment(value: 8, label: Text('Jodhpur 8 km')),
          ],
          selected: {session.campaignRadiusKm},
          onSelectionChanged: (value) => session.setCampaignRadius(value.first),
        ),
        const SizedBox(height: MoolSpacing.md),
        const Text('Duration', style: TextStyle(fontWeight: FontWeight.w900)),
        SegmentedButton<int>(
          key: const Key('campaign-duration'),
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 14, label: Text('14 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
          ],
          selected: {session.campaignDurationDays},
          onSelectionChanged: (value) =>
              session.setCampaignDuration(value.first),
        ),
        const SizedBox(height: MoolSpacing.md),
        const Text('Channel', style: TextStyle(fontWeight: FontWeight.w900)),
        for (final channel in RetailerCampaignChannel.values) ...[
          _SelectRow(
            keyName: 'campaign-channel-${channel.name}',
            title: channel == RetailerCampaignChannel.moolSocial
                ? '${channel.label} · reach eligible customers in the app'
                : '${channel.label} · only customers with current permission',
            selected: session.campaignChannel == channel,
            onTap: () => session.setCampaignChannel(channel),
          ),
          const SizedBox(height: MoolSpacing.xs),
        ],
        const RetailerCard(
          color: Color(0xFFF4F3FF),
          child: Text(
            'Invoices are independent of marketing. Opt-out, purpose, channel permission and operator remain auditable.',
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.session});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('campaign-review-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RetailerSectionTitle(
          title: 'Review before publishing',
          detail: 'No stock or budget is committed until you publish',
        ),
        const SizedBox(height: MoolSpacing.sm),
        RetailerCard(
          color: const Color(0xFFF7FFF4),
          child: Column(
            children: [
              _ReviewRow(
                label: 'Outcome',
                value: session.campaignObjective.label,
              ),
              _ReviewRow(
                label: 'Products',
                value:
                    '${session.selectedCampaignProducts.length} · ${session.campaignMaximumOrders} baskets maximum',
              ),
              _ReviewRow(
                label: 'Audience',
                value:
                    '${session.campaignAudience.label} · Jodhpur ${session.campaignRadiusKm} km',
              ),
              _ReviewRow(
                label: 'Benefit',
                value:
                    '${session.campaignBenefit.label} · ${session.campaignDurationDays} days',
              ),
              _ReviewRow(
                label: 'Channel',
                value: session.campaignChannel.label,
              ),
              const _ReviewRow(
                label: 'Attributed sale',
                value: 'Paid, non-refunded order',
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        TextFormField(
          key: const Key('campaign-spend-cap'),
          initialValue: '${session.campaignSpendCap}',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final parsed = int.tryParse(value);
            if (parsed != null) session.setCampaignSpendCap(parsed);
          },
          decoration: const InputDecoration(
            labelText: 'Maximum campaign spend',
            prefixText: '₹ ',
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        const RetailerCard(
          color: Color(0xFFFFF4E5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFFB05C00)),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  'Stock is reserved only for an accepted order. Campaign spend cannot exceed the approved cap. Views and unverified leads are not charged as sales.',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MoolSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: MoolColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: MoolColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MoolColors.navy,
      borderRadius: BorderRadius.circular(MoolRadii.capsule),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(MoolRadii.capsule),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MoolSpacing.sm,
            vertical: MoolSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(color: MoolColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.state,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final String state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: enabled ? MoolColors.success : MoolColors.muted),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        RetailerPill(
          label: state.toUpperCase(),
          color: enabled ? MoolColors.success : MoolColors.muted,
        ),
      ],
    );
  }
}

class _BasketLine extends StatelessWidget {
  const _BasketLine({required this.name, required this.price});

  final String name;
  final int price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: MoolColors.success),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text('₹$price'),
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.keyName,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String keyName;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      keyName: keyName,
      color: selected ? const Color(0xFFF4F3FF) : Colors.white,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? MoolColors.navy : MoolColors.muted,
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
