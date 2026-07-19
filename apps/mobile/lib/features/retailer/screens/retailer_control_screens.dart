import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_control_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';

class RetailerSlowStockScreen extends StatelessWidget {
  const RetailerSlowStockScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Move Slow Stock',
        subtitle: 'Controlled recovery from available stock',
        activeDock: 'stock',
        returnRoute: '/app/retailer/home?view=stock',
        trailing: IconButton.outlined(
          key: const Key('recovery-stock-statement'),
          tooltip: 'Open Stock Statement',
          onPressed: () => context.go('/app/retailer/books/stock'),
          icon: const Icon(Icons.inventory_outlined),
        ),
        bottomAction: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.recoveryRoute.label.toUpperCase(),
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${session.recoveryQuantity} units · minimum ₹${session.recoveryQuantity * session.recoveryFloor}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: FilledButton(
                key: const Key('recovery-review-publish'),
                onPressed: session.busy
                    ? null
                    : () => session.reviewOrPublishRecovery(),
                child: Text(
                  session.recoveryId != null
                      ? 'Published'
                      : session.recoveryReviewed
                      ? 'Publish action'
                      : session.recoveryRoute ==
                            RetailerRecoveryRoute.supplierClaim
                      ? 'Review claim'
                      : 'Review & publish',
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          key: const Key('slow-stock-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const Row(
              children: [
                Expanded(
                  child: _ControlMetric(
                    label: 'SLOW VALUE',
                    value: '₹48,620',
                    detail: '18 products',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: _ControlMetric(
                    label: 'SAFE TO OFFER',
                    value: '₹32,400',
                    detail: '12 products',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: _ControlMetric(
                    label: 'TARGET',
                    value: '₹41,200',
                    detail: '84.7%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            const _ControlNotice(
              warning: true,
              text:
                  'Reserved, disputed, expired or unsafe quantity is excluded. Product condition remains visible.',
            ),
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Choose stock',
              detail: 'Ranked by recovery urgency',
            ),
            const SizedBox(height: MoolSpacing.sm),
            for (final product in reviewSlowStock) ...[
              _ChoiceCard(
                keyName: 'recovery-product-${product.id}',
                title: '${product.name} · ${product.available} units',
                detail: product.detail,
                footnote: product.guidance,
                selected: session.recoveryProductId == product.id,
                onTap: () => session.selectRecoveryProduct(product.id),
              ),
              const SizedBox(height: MoolSpacing.xs),
            ],
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Choose recovery route',
              detail: 'One controlled outcome',
            ),
            const SizedBox(height: MoolSpacing.sm),
            for (final route in RetailerRecoveryRoute.values) ...[
              _ChoiceCard(
                keyName: 'recovery-route-${route.name}',
                title: route.label,
                detail: route.detail,
                selected: session.recoveryRoute == route,
                onTap: () => session.setRecoveryRoute(route),
              ),
              const SizedBox(height: MoolSpacing.xs),
            ],
            const SizedBox(height: MoolSpacing.sm),
            _ControlNotice(
              text: session.recoveryRoute == RetailerRecoveryRoute.supplierClaim
                  ? 'Continue only where this batch has valid supplier return terms and invoice evidence.'
                  : 'Review quantity, protected floor price and closing time before publication.',
            ),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('recovery-quantity'),
                    initialValue: '${session.recoveryQuantity}',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) session.setRecoveryQuantity(parsed);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Quantity to release',
                    ),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: TextFormField(
                    key: const Key('recovery-floor'),
                    initialValue: '${session.recoveryFloor}',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) session.setRecoveryFloor(parsed);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Minimum price/unit',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            DropdownButtonFormField<String>(
              key: const Key('recovery-duration'),
              initialValue: session.recoveryDuration,
              decoration: const InputDecoration(labelText: 'Offer closes'),
              items: const [
                DropdownMenuItem(
                  value: 'In 48 hours',
                  child: Text('In 48 hours'),
                ),
                DropdownMenuItem(value: 'In 7 days', child: Text('In 7 days')),
                DropdownMenuItem(
                  value: 'When quantity sells',
                  child: Text('When quantity sells'),
                ),
              ],
              onChanged: (value) {
                if (value != null) session.setRecoveryDuration(value);
              },
            ),
            const SizedBox(height: MoolSpacing.sm),
            const _ControlNotice(
              text:
                  'Estimated margin stays visible. Quantity is reserved only after publication.',
            ),
            if (session.recoveryId != null)
              TextButton.icon(
                key: const Key('recovery-open-record'),
                onPressed: () => context.go('/app/retailer/books/sales'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View recovery record'),
              ),
          ],
        ),
      ),
    );
  }
}

class RetailerAiAssistantScreen extends StatelessWidget {
  const RetailerAiAssistantScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Ask Mool AI',
        subtitle: 'Explain, forecast and prepare actions',
        activeDock: 'none',
        returnRoute: '/app/retailer/home',
        trailing: IconButton.outlined(
          key: const Key('ai-history'),
          tooltip: 'Assistant history',
          onPressed: () => _showAiHistory(context),
          icon: const Icon(Icons.history_rounded),
        ),
        body: ListView(
          key: const Key('retailer-ai-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            RetailerCard(
              color: const Color(0xFFF4F3FF),
              child: Column(
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: MoolColors.navy,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.auto_awesome_rounded),
                      ),
                      SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grounded in your workspace',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Answers cite authorized shop records.',
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
                  const SizedBox(height: MoolSpacing.sm),
                  const Divider(height: 1),
                  const SizedBox(height: MoolSpacing.xs),
                  const Row(
                    children: [
                      RetailerPill(label: 'DRAFT ONLY'),
                      SizedBox(width: MoolSpacing.xs),
                      Expanded(
                        child: Text(
                          'Every business change requires your approval',
                          style: TextStyle(
                            color: MoolColors.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.verified_user_outlined,
                        color: MoolColors.navy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextFormField(
              key: const Key('ai-prompt'),
              initialValue: session.aiPrompt,
              onChanged: session.setAiPrompt,
              decoration: InputDecoration(
                labelText: 'Ask about your shop',
                suffixIcon: IconButton.filled(
                  key: const Key('ai-ask'),
                  tooltip: 'Ask Mool AI',
                  onPressed: session.busy ? null : session.askRetailerAi,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children:
                  {
                        'restock': 'What should I restock this week?',
                        'slow': 'Which stock is moving slowly?',
                        'dues': 'Show customer payments due',
                        'offer': 'Draft an offer for repeat customers',
                        'profit': "Explain today's profit estimate",
                      }.entries
                      .map(
                        (entry) => ActionChip(
                          key: Key('ai-prompt-${entry.key}'),
                          label: Text(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                          ),
                          onPressed: () => session.setAiPrompt(entry.value),
                        ),
                      )
                      .toList(),
            ),
            if (session.aiAnswer != null) ...[
              const SizedBox(height: MoolSpacing.sm),
              _ControlNotice(text: session.aiAnswer!),
            ],
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Prepared actions',
              detail: 'Approval required',
            ),
            const SizedBox(height: MoolSpacing.sm),
            if (!session.dismissedAiActions.contains('purchase'))
              _AiProposal(
                keyName: 'ai-proposal-purchase',
                title: 'Reorder Aashirvaad Atta 5 kg',
                badge: 'DRAFT PO',
                facts: const [
                  ('12 units', '7-day demand'),
                  ('4 units', 'Available'),
                  ('₹238', 'Best landed'),
                ],
                detail:
                    'Suggested: 3 cases from Jodhpur Authorised Distributor · delivery tomorrow.',
                onDismiss: () => session.dismissAiAction('purchase'),
                onReview: () => context.go('/app/retailer/wholesale/cart'),
              ),
            if (!session.dismissedAiActions.contains('offer')) ...[
              const SizedBox(height: MoolSpacing.sm),
              _AiProposal(
                keyName: 'ai-proposal-offer',
                title: 'Prepare slow-stock customer offer',
                badge: 'DRAFT ONLY',
                facts: const [
                  ('20 units', 'Safe quantity'),
                  ('₹116', 'Floor/unit'),
                  ('48 hours', 'Suggested'),
                ],
                detail:
                    'No price or offer changed. Review quantity, floor and audience first.',
                onDismiss: () => session.dismissAiAction('offer'),
                onReview: () =>
                    context.go('/app/retailer/home?view=stock&panel=recovery'),
              ),
            ],
            if (session.dismissedAiActions.length == 2)
              RetailerEmptyState(
                keyName: 'ai-proposals-empty',
                title: 'No prepared action',
                detail: 'Ask another question to prepare a reviewable draft.',
                actionLabel: 'Ask about slow stock',
                onAction: () =>
                    session.setAiPrompt('Which stock is moving slowly?'),
              ),
            const SizedBox(height: MoolSpacing.md),
            const _ControlNotice(
              warning: true,
              text:
                  'AI cannot spend, publish, refund, message, file returns or change access without authorized approval.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAiHistory(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('ai-history-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Recent explanations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const ListTile(
              title: Text('Why is profit lower this week?'),
              subtitle: Text(
                'Oil margin fell 1.8%; delivery cost rose ₹1,240 · locked books',
              ),
            ),
            const ListTile(
              title: Text('Which customers may reorder?'),
              subtitle: Text(
                '86 eligible from permitted history · no message sent',
              ),
            ),
            FilledButton(
              key: const Key('ai-history-close'),
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );
}

class RetailerStaffScreen extends StatelessWidget {
  const RetailerStaffScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Staff & Access',
        subtitle: 'Branch roles, limits, devices and history',
        activeDock: 'none',
        returnRoute: '/app/retailer/settings',
        trailing: IconButton.filled(
          key: const Key('staff-add'),
          tooltip: 'Invite staff',
          onPressed: () => session.setInvitePanel(true),
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
        body: ListView(
          key: const Key('staff-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const Row(
              children: [
                Expanded(
                  child: _ControlMetric(
                    label: 'ACTIVE STAFF',
                    value: '8',
                    detail: '5 working now',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: _ControlMetric(
                    label: 'COUNTERS',
                    value: '3',
                    detail: '2 open',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: _ControlMetric(
                    label: 'DEVICES',
                    value: '6',
                    detail: '1 review',
                  ),
                ),
              ],
            ),
            if (session.invitePanelOpen) ...[
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'staff-invite-panel',
                color: const Color(0xFFF4F3FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Invite staff member',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          key: const Key('staff-invite-close'),
                          onPressed: () => session.setInvitePanel(false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    TextFormField(
                      key: const Key('staff-invite-name'),
                      initialValue: session.inviteName,
                      onChanged: session.setInviteName,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    TextFormField(
                      key: const Key('staff-invite-mobile'),
                      initialValue: session.inviteMobile,
                      keyboardType: TextInputType.phone,
                      onChanged: session.setInviteMobile,
                      decoration: const InputDecoration(labelText: 'Mobile'),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    DropdownButtonFormField<RetailerStaffRole>(
                      key: const Key('staff-invite-role'),
                      isExpanded: true,
                      initialValue: session.inviteRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: RetailerStaffRole.values
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) session.setInviteRole(value);
                      },
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    FilledButton(
                      key: const Key('staff-send-invite'),
                      onPressed: session.busy ? null : session.sendStaffInvite,
                      child: Text(
                        session.staffInviteId == null
                            ? 'Send secure invite'
                            : 'Invite sent',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Team',
              detail: 'Mahadev Fresh Mart · main branch',
            ),
            const SizedBox(height: MoolSpacing.sm),
            for (final member in session.staff) ...[
              RetailerCard(
                keyName: 'staff-${member.id}',
                onTap: member.owner
                    ? null
                    : () => _showStaff(context, member.id),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: member.paused
                          ? const Color(0xFFFFEBEA)
                          : const Color(0xFFEAF7E8),
                      foregroundColor: member.paused
                          ? const Color(0xFFB42318)
                          : MoolColors.success,
                      child: Text(
                        member.name
                            .split(' ')
                            .take(2)
                            .map((word) => word[0])
                            .join(),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${member.name} · ${member.role}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            member.access,
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            member.activity,
                            style: const TextStyle(
                              color: MoolColors.navy,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    member.owner
                        ? const RetailerPill(label: 'PROTECTED')
                        : const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
            ],
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Permission view',
              detail: 'Least privilege by role',
            ),
            const SizedBox(height: MoolSpacing.sm),
            const _PermissionMatrix(),
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Security',
              detail: 'Workspace audit',
            ),
            const SizedBox(height: MoolSpacing.sm),
            _ControlRow(
              keyName: 'staff-devices',
              icon: Icons.devices_outlined,
              title: 'Active devices',
              detail: '6 devices · last sign-in and branch',
              action: 'Review',
              onTap: () => _showSecurity(context, true),
            ),
            const SizedBox(height: MoolSpacing.xs),
            _ControlRow(
              keyName: 'staff-history',
              icon: Icons.history_rounded,
              title: 'Permission history',
              detail: 'Every grant, revoke and limit change',
              action: 'View',
              onTap: () => _showSecurity(context, false),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const _ControlNotice(
              warning: true,
              text:
                  'Bank mandates, high-value refunds, staff administration and filing approval require owner authority.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStaff(BuildContext context, String id) {
    final member = session.staff.firstWhere((item) => item.id == id);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('staff-manage-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text('${member.role} · ${member.access}'),
              const SizedBox(height: MoolSpacing.md),
              FilledButton(
                key: const Key('staff-toggle-access'),
                onPressed: session.busy
                    ? null
                    : () async {
                        final changed = await session.toggleStaffAccess(id);
                        if (changed && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                child: Text(member.paused ? 'Resume access' : 'Pause access'),
              ),
              TextButton(
                key: const Key('staff-manage-cancel'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Keep current access'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSecurity(
    BuildContext context,
    bool devices,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: Key(devices ? 'staff-devices-sheet' : 'staff-history-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              devices ? 'Active devices' : 'Permission history',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            ListTile(
              title: Text(
                devices ? 'OPPO CPH2375 · main branch' : 'Vikas access paused',
              ),
              subtitle: Text(
                devices
                    ? 'Verified · active now'
                    : 'Owner · 18 July · reason retained',
              ),
            ),
            FilledButton(
              key: const Key('staff-security-close'),
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );
}

class RetailerStoreSettingsScreen extends StatelessWidget {
  const RetailerStoreSettingsScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: 'Store Settings',
        subtitle: 'Customer-visible readiness and fulfilment',
        activeDock: 'none',
        returnRoute: '/app/retailer/home',
        trailing: IconButton.filled(
          key: const Key('settings-save'),
          tooltip: 'Save settings',
          onPressed: session.busy ? null : session.saveStoreSettings,
          icon: const Icon(Icons.save_outlined),
        ),
        body: ListView(
          key: const Key('store-settings-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            RetailerCard(
              keyName: 'settings-readiness',
              color: const Color(0xFFEAF7E8),
              onTap: session.reviewLicenceReminder,
              child: const Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: MoolColors.success,
                        foregroundColor: Colors.white,
                        child: Text(
                          '92%',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shop readiness is strong',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Price, stock, fulfilment and support are live.',
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
                      Icon(
                        Icons.notification_important_outlined,
                        color: Color(0xFFB05C00),
                        size: 18,
                      ),
                      SizedBox(width: MoolSpacing.xs),
                      Expanded(
                        child: Text(
                          '1 licence reminder needs attention',
                          style: TextStyle(
                            color: Color(0xFF8A4700),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Shop profile',
              detail: 'Public and operating identity',
            ),
            const SizedBox(height: MoolSpacing.sm),
            _ControlRow(
              keyName: 'settings-profile',
              icon: Icons.storefront_outlined,
              title: 'Mahadev Fresh Mart · Main Branch',
              detail:
                  'Sardarpura, Jodhpur · Grocery / Kirana · verified WK-256619',
              action: 'Edit',
              onTap: () => _showSetting(
                context,
                'Shop profile',
                'Verified branch identity and public category',
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            _ControlRow(
              keyName: 'settings-hours',
              icon: Icons.schedule_rounded,
              title: 'Open 7:00 AM – 10:00 PM',
              detail: 'All days · order cutoff 9:30 PM',
              action: 'Edit',
              onTap: () => _showSetting(
                context,
                'Shop hours',
                'Open 7:00 AM – 10:00 PM · cutoff 9:30 PM',
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Orders and fulfilment',
              detail: 'Live customer controls',
            ),
            const SizedBox(height: MoolSpacing.sm),
            _SettingSwitch(
              keyName: 'settings-orders',
              title: 'Accept app orders',
              detail: 'Customers may order from live stock',
              value: session.acceptAppOrders,
              onChanged: (_) => session.toggleStoreSetting('orders'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            _SettingSwitch(
              keyName: 'settings-collection',
              title: 'At-shop collection',
              detail: 'For customers visiting the shop · ready in 15–25 min',
              value: session.atShopCollection,
              onChanged: (_) => session.toggleStoreSetting('collection'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            _SettingSwitch(
              keyName: 'settings-delivery',
              title: 'Home delivery',
              detail: 'Own delivery + MoolSocial · up to 8 km',
              value: session.homeDelivery,
              onChanged: (_) => session.toggleStoreSetting('delivery'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            _ControlRow(
              keyName: 'settings-payment',
              icon: Icons.payments_outlined,
              title: 'Payment methods',
              detail: 'UPI, cash, card · customer credit by permission',
              action: 'Edit',
              onTap: () => _showSetting(
                context,
                'Payment methods',
                'UPI, cash and card are enabled. Credit requires permission.',
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Customer rules',
              detail: 'Rights preserved before publication',
            ),
            const SizedBox(height: MoolSpacing.sm),
            _ControlRow(
              keyName: 'settings-invoice',
              icon: Icons.receipt_long_outlined,
              title: 'Invoice and GST',
              detail: 'GSTIN verified · HSN catalogue · sequence active',
              action: 'View',
              onTap: () => context.go('/app/retailer/books/sales'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            _ControlRow(
              keyName: 'settings-returns',
              icon: Icons.assignment_return_outlined,
              title: 'Return and refund rule',
              detail: 'Category-aware · customer rights preserved',
              action: 'Edit',
              onTap: () => context.go('/app/retailer/orders/issues'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            _ControlRow(
              keyName: 'settings-team',
              icon: Icons.people_alt_outlined,
              title: 'Staff and access',
              detail: 'Branch roles, limits, devices and permission history',
              action: 'Manage',
              onTap: () => context.go('/app/retailer/settings/team'),
            ),
            const SizedBox(height: MoolSpacing.md),
            const RetailerSectionTitle(
              title: 'Compliance',
              detail: 'Rajasthan · India',
            ),
            const SizedBox(height: MoolSpacing.sm),
            const _ControlRow(
              keyName: 'settings-gst',
              icon: Icons.verified_outlined,
              title: 'GST certificate',
              detail: 'Verified · last checked 10 Jul 2026',
              action: 'Ready',
            ),
            const SizedBox(height: MoolSpacing.xs),
            RetailerCard(
              keyName: 'settings-licence',
              color: session.licenceAttention
                  ? const Color(0xFFFFF4E5)
                  : Colors.white,
              onTap: session.reviewLicenceReminder,
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: Color(0xFFB05C00)),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shop licence renewal',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          session.licenceAttention
                              ? 'Action needed · upload before the due date'
                              : 'Due in 28 days · upload renewed copy when available',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const RetailerPill(
                    label: 'REMINDER',
                    color: Color(0xFFB05C00),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            _ControlRow(
              keyName: 'settings-services',
              icon: Icons.auto_awesome_outlined,
              title: 'MoolSocial Business Services',
              detail: 'Delivery, growth, tax, books, offers and ads',
              action: 'View',
              onTap: () => context.go('/app/retailer/services'),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const _ControlNotice(
              text:
                  'Products stay visible only while price, stock, fulfilment, payment, support and applicable compliance remain ready.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetting(
    BuildContext context,
    String title,
    String detail,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('settings-edit-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(detail),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: const Key('settings-edit-done'),
              onPressed: () {
                session.showNotice(
                  '$title remains ready for owner review before saving.',
                );
                Navigator.pop(sheetContext);
              },
              child: const Text('Keep and review'),
            ),
          ],
        ),
      ),
    ),
  );
}

class RetailerCustomerIssuesScreen extends StatelessWidget {
  const RetailerCustomerIssuesScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final issue = session.selectedIssue;
        return RetailerPageScaffold(
          session: session,
          title: 'Customer Issues',
          subtitle: 'Order, evidence, payment and resolution',
          activeDock: 'orders',
          returnRoute: '/app/retailer/orders',
          trailing: IconButton.outlined(
            key: const Key('issues-support-chat'),
            tooltip: 'Issue support chat',
            onPressed: () => context.go(
              '/app/chat/thread/order-support?return=/app/retailer/orders/issues',
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          bottomAction: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SELECTED RESOLUTION',
                      style: TextStyle(
                        color: MoolColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      session.issueResolution.label(issue.amount),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: FilledButton(
                  key: const Key('issue-confirm'),
                  onPressed: session.busy ? null : session.resolveCustomerIssue,
                  child: Text(
                    session.issueResolutionId == null
                        ? 'Confirm outcome'
                        : 'Completed',
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            key: const Key('customer-issues-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const Row(
                children: [
                  Expanded(
                    child: _ControlMetric(
                      label: 'OPEN',
                      value: '5',
                      detail: '3 response',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _ControlMetric(
                      label: 'REFUND HELD',
                      value: '₹1,486',
                      detail: 'Until decision',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _ControlMetric(
                      label: 'RESOLVED 30D',
                      value: '94%',
                      detail: 'Within SLA',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in RetailerIssueFilter.values) ...[
                      ChoiceChip(
                        key: Key('issue-filter-${filter.name}'),
                        label: Text(filter.label),
                        selected: session.issueFilter == filter,
                        onSelected: (_) => session.setIssueFilter(filter),
                      ),
                      const SizedBox(width: MoolSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'issue-urgent',
                color: const Color(0xFFFFEBEA),
                onTap: () => session.selectIssue('MS-2848'),
                child: const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Color(0xFFB42318)),
                    SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MS-2848 needs response in 42 minutes',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Damaged oil pouch · photo received · ₹132 held',
                            style: TextStyle(
                              color: MoolColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerSectionTitle(
                title: 'Cases',
                detail: '${session.filteredIssues.length} shown',
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (session.filteredIssues.isEmpty)
                RetailerEmptyState(
                  keyName: 'issues-empty',
                  title: 'No issue in this view',
                  detail: 'Choose another issue filter.',
                  actionLabel: 'Show all cases',
                  onAction: () =>
                      session.setIssueFilter(RetailerIssueFilter.all),
                )
              else
                for (final item in session.filteredIssues) ...[
                  _ChoiceCard(
                    keyName: 'issue-${item.id}',
                    title: '${item.id} · ${item.title}',
                    detail: '${item.customer} · ${item.detail}',
                    footnote: item.status,
                    selected: session.selectedIssueId == item.id,
                    onTap: () => session.selectIssue(item.id),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                ],
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                keyName: 'issue-detail',
                color: const Color(0xFFFFF8F7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${issue.id} · ${issue.title}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        RetailerPill(
                          label: issue.resolved ? 'RESOLVED' : 'ACTION DUE',
                          color: issue.resolved
                              ? MoolColors.success
                              : const Color(0xFFB42318),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    for (final event in issue.timeline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                        child: Text(
                          event,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    const Divider(),
                    Wrap(
                      spacing: MoolSpacing.xs,
                      runSpacing: MoolSpacing.xs,
                      children: [
                        for (final resolution in RetailerIssueResolution.values)
                          ChoiceChip(
                            key: Key('issue-resolution-${resolution.name}'),
                            label: Text(resolution.label(issue.amount)),
                            selected: session.issueResolution == resolution,
                            onSelected: (_) =>
                                session.setIssueResolution(resolution),
                          ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _ControlNotice(
                      text: switch (session.issueResolution) {
                        RetailerIssueResolution.replace =>
                          'Fresh stock will be reserved once after confirmation and the customer receives the new time.',
                        RetailerIssueResolution.refund =>
                          'Confirmation creates a linked credit note and payment reversal.',
                        RetailerIssueResolution.requestEvidence =>
                          'A secure evidence link is sent and the protected amount remains held.',
                      },
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    TextFormField(
                      key: const Key('issue-message'),
                      initialValue: session.issueMessage,
                      minLines: 2,
                      maxLines: 4,
                      onChanged: session.setIssueMessage,
                      decoration: const InputDecoration(
                        labelText: 'Message to customer',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    OutlinedButton.icon(
                      key: const Key('issue-review-evidence'),
                      onPressed: () => context.go(
                        '/app/chat/thread/order-support?return=/app/retailer/orders/issues',
                      ),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(issue.evidenceAction),
                    ),
                    if (session.issueResolutionId != null)
                      TextButton.icon(
                        key: const Key('issue-open-receipt'),
                        onPressed: () =>
                            context.go('/app/retailer/books/sales'),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Open issue receipt'),
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
}

class _AiProposal extends StatelessWidget {
  const _AiProposal({
    required this.keyName,
    required this.title,
    required this.badge,
    required this.facts,
    required this.detail,
    required this.onDismiss,
    required this.onReview,
  });

  final String keyName;
  final String title;
  final String badge;
  final List<(String, String)> facts;
  final String detail;
  final VoidCallback onDismiss;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      keyName: keyName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              RetailerPill(label: badge),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              for (final fact in facts) ...[
                Expanded(
                  child: _ControlMetric(
                    label: fact.$2.toUpperCase(),
                    value: fact.$1,
                    detail: '',
                  ),
                ),
                if (fact != facts.last) const SizedBox(width: MoolSpacing.xs),
              ],
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Text(
            detail,
            style: const TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: Key('$keyName-dismiss'),
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: FilledButton(
                  key: Key('$keyName-review'),
                  onPressed: onReview,
                  child: const Text('Review'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionMatrix extends StatelessWidget {
  const _PermissionMatrix();

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.8),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
        },
        children: [
          _permissionRow('Action', 'Counter', 'Stock', 'Accountant', true),
          _permissionRow('Create sale', 'Yes', 'No', 'No'),
          _permissionRow('Edit stock', 'No', 'Yes', 'No'),
          _permissionRow('Export books', 'No', 'No', 'Yes'),
          _permissionRow('Refund/bank/staff', 'Owner', 'Owner', 'Owner'),
        ],
      ),
    );
  }

  TableRow _permissionRow(
    String a,
    String b,
    String c,
    String d, [
    bool header = false,
  ]) => TableRow(
    children: [a, b, c, d]
        .map(
          (text) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              text,
              textAlign: text == a ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: header ? FontWeight.w900 : FontWeight.w700,
                color: header ? MoolColors.navy : MoolColors.ink,
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String keyName;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      child: SwitchListTile(
        key: Key(keyName),
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(detail),
      ),
    );
  }
}

class _ControlMetric extends StatelessWidget {
  const _ControlMetric({
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
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.footnote,
  });

  final String keyName;
  final String title;
  final String detail;
  final String? footnote;
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
                ? Icons.check_circle_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? MoolColors.navy : MoolColors.muted,
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
                if (footnote != null)
                  Text(
                    footnote!,
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlNotice extends StatelessWidget {
  const _ControlNotice({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MoolSpacing.sm),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF4E5) : const Color(0xFFEAF7E8),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(
          color: warning ? const Color(0xFFB05C00) : MoolColors.success,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning
                ? Icons.warning_amber_rounded
                : Icons.verified_user_outlined,
            color: warning ? const Color(0xFFB05C00) : MoolColors.success,
            size: 19,
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      keyName: keyName,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: MoolColors.navy),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: MoolColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
