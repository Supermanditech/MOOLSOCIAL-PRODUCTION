import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_business_services_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';

IconData _serviceIcon(RetailerBusinessServiceType type) => switch (type) {
  RetailerBusinessServiceType.delivery => Icons.local_shipping_outlined,
  RetailerBusinessServiceType.growth => Icons.trending_up_rounded,
  RetailerBusinessServiceType.books => Icons.menu_book_outlined,
  RetailerBusinessServiceType.ads => Icons.campaign_outlined,
};

Color _serviceColor(RetailerBusinessServiceType type) => switch (type) {
  RetailerBusinessServiceType.delivery => const Color(0xFF176B87),
  RetailerBusinessServiceType.growth => MoolColors.success,
  RetailerBusinessServiceType.books => const Color(0xFF5B4BB7),
  RetailerBusinessServiceType.ads => const Color(0xFFB05C00),
};

String _money(int value) {
  final raw = value.toString();
  final last = raw.length > 3 ? raw.substring(raw.length - 3) : raw;
  final head = raw.length > 3 ? raw.substring(0, raw.length - 3) : '';
  if (head.isEmpty) return '₹$last';
  final groups = <String>[];
  var remaining = head;
  while (remaining.length > 2) {
    groups.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }
  if (remaining.isNotEmpty) groups.insert(0, remaining);
  return '₹${groups.join(',')},$last';
}

class RetailerBusinessServicesScreen extends StatelessWidget {
  const RetailerBusinessServicesScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (!session.businessServicesAuthorized) {
          return RetailerPageScaffold(
            session: session,
            title: 'Business Services',
            subtitle: 'Shop owner access required',
            activeDock: 'none',
            returnRoute: '/app/retailer/books',
            body: Center(
              child: RetailerEmptyState(
                keyName: 'business-services-role-denied',
                title: 'Paid services are protected',
                detail:
                    'Ask the shop owner to grant permission to review and activate plans.',
                actionLabel: 'Return to Business Book',
                onAction: () => context.go('/app/retailer/books'),
              ),
            ),
          );
        }
        return RetailerPageScaffold(
          session: session,
          title: 'Business Services',
          subtitle: 'Choose support to run or grow your shop',
          activeDock: 'none',
          returnRoute: '/app/retailer/books',
          trailing: IconButton.outlined(
            key: const Key('business-services-help'),
            tooltip: 'Business Services help',
            onPressed: () =>
                _showService(context, retailerBusinessServiceOfferings[1]),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          body: RefreshIndicator(
            key: const Key('business-services-refresh'),
            onRefresh: session.refreshBusinessServices,
            child: ListView(
              key: const Key('business-services-screen'),
              padding: const EdgeInsets.fromLTRB(
                MoolSpacing.md,
                MoolSpacing.xs,
                MoolSpacing.md,
                MoolSpacing.xl,
              ),
              children: [
                RetailerSectionTitle(
                  title: 'Professional support',
                  detail: 'Separate plans with exact charges before activation',
                  trailing: RetailerPill(
                    label: '${session.activeBusinessServiceCount} ACTIVE',
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const RetailerCard(
                  color: Color(0xFFEAF7E8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: MoolColors.success,
                      ),
                      SizedBox(width: MoolSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Managed by MoolSocial',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Included work, maximum charges, proof, renewal and cancellation stay visible.',
                              style: TextStyle(
                                color: MoolColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                if (!session.businessServicesCatalogueAvailable)
                  RetailerEmptyState(
                    keyName: 'business-services-empty',
                    title: 'No service plans available',
                    detail:
                        'Refresh to load plans available for this shop and service area.',
                    actionLabel: 'Refresh services',
                    onAction: session.refreshBusinessServices,
                  )
                else
                  for (final service in retailerBusinessServiceOfferings) ...[
                    _ServiceOfferCard(
                      service: service,
                      active:
                          session.activeBusinessService(service.type) != null,
                      onTap: () => _showService(context, service),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showService(
    BuildContext context,
    RetailerBusinessServiceOffering service,
  ) {
    session.selectBusinessService(service);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          key: Key('business-service-detail-${service.type.name}'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            0,
            MoolSpacing.md,
            MoolSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _serviceColor(
                      service.type,
                    ).withValues(alpha: .12),
                    foregroundColor: _serviceColor(service.type),
                    child: Icon(_serviceIcon(service.type)),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          service.intro,
                          style: const TextStyle(color: MoolColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('business-service-close'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                color: const Color(0xFFEDEEFF),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MONTHLY PLAN STARTS AT',
                            style: TextStyle(
                              color: MoolColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${_money(service.plans.first.monthly)}/month',
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Text(
                        service.variableCharge,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: MoolColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final fact in service.facts)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    fact.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(fact.value),
                  leading: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: MoolColors.success,
                  ),
                ),
              const SizedBox(height: MoolSpacing.sm),
              FilledButton(
                key: const Key('business-service-view-plans'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.go('/app/retailer/services/${service.type.name}');
                },
                child: const Text('View plans'),
              ),
              const SizedBox(height: MoolSpacing.xs),
              OutlinedButton(
                key: const Key('business-service-not-now'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceOfferCard extends StatelessWidget {
  const _ServiceOfferCard({
    required this.service,
    required this.active,
    required this.onTap,
  });

  final RetailerBusinessServiceOffering service;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      keyName: 'business-service-${service.type.name}',
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _serviceColor(service.type).withValues(alpha: .1),
            foregroundColor: _serviceColor(service.type),
            child: Icon(_serviceIcon(service.type)),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: MoolSpacing.xxs,
                  runSpacing: MoolSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    RetailerPill(
                      label: active ? 'ACTIVE' : service.badge.toUpperCase(),
                      color: active
                          ? MoolColors.success
                          : _serviceColor(service.type),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  service.outcome,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  service.includes,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
                Text(
                  service.variableCharge,
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'FROM',
                style: TextStyle(
                  color: MoolColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _money(service.plans.first.monthly),
                style: const TextStyle(
                  color: MoolColors.success,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '/month',
                style: TextStyle(color: MoolColors.muted, fontSize: 10),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class RetailerBusinessServicePlanScreen extends StatefulWidget {
  const RetailerBusinessServicePlanScreen({
    required this.session,
    required this.service,
    super.key,
  });

  final RetailerSession session;
  final RetailerBusinessServiceOffering service;

  @override
  State<RetailerBusinessServicePlanScreen> createState() =>
      _RetailerBusinessServicePlanScreenState();
}

class _RetailerBusinessServicePlanScreenState
    extends State<RetailerBusinessServicePlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.session.loadBusinessServicePlans(widget.service);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final selected =
            widget.session.selectedBusinessPlan ?? widget.service.plans.first;
        return RetailerPageScaffold(
          session: widget.session,
          title: widget.service.title,
          subtitle: 'Service plan and terms',
          activeDock: 'none',
          returnRoute: '/app/retailer/services',
          trailing: IconButton.outlined(
            key: const Key('business-plan-help'),
            tooltip: 'Plan protection',
            onPressed: () => _showProtection(context),
            icon: const Icon(Icons.shield_outlined),
          ),
          bottomAction: RetailerPrimaryButton(
            keyName: 'business-plan-review',
            label: 'Review activation',
            busy: widget.session.busy,
            onPressed: () => context.go(
              Uri(
                path: '/app/retailer/services/${widget.service.type.name}',
                queryParameters: {'stage': 'review'},
              ).toString(),
            ),
          ),
          body: ListView(
            key: const Key('business-service-plan-screen'),
            padding: const EdgeInsets.all(MoolSpacing.md),
            children: [
              _ProgressStrip(current: 1),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                color: const Color(0xFFEAF7E8),
                child: Row(
                  children: [
                    Icon(
                      _serviceIcon(widget.service.type),
                      color: _serviceColor(widget.service.type),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.outcome,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(widget.service.includes),
                        ],
                      ),
                    ),
                    const RetailerPill(label: 'MANAGED'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Choose your plan',
                detail: 'Change anytime before activation',
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final plan in widget.service.plans) ...[
                _PlanCard(
                  plan: plan,
                  selected: selected.id == plan.id,
                  onTap: () => widget.session.selectBusinessServicePlan(plan),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly spending limit',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'No new paid work above this limit without approval',
                                style: TextStyle(
                                  color: MoolColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _money(widget.session.businessServiceMonthlyLimit),
                          key: const Key('business-limit-value'),
                          style: const TextStyle(
                            color: MoolColors.success,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    SegmentedButton<int>(
                      key: const Key('business-limit-options'),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 1500, label: Text('₹1,500')),
                        ButtonSegment(value: 3000, label: Text('₹3,000')),
                        ButtonSegment(value: -1, label: Text('Custom')),
                      ],
                      selected: {
                        widget.session.businessServiceCustomLimit
                            ? -1
                            : widget.session.businessServiceMonthlyLimit,
                      },
                      onSelectionChanged: (values) {
                        final value = values.first;
                        if (value == -1) {
                          _showCustomLimit(context);
                        } else {
                          widget.session.setBusinessServiceLimit(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Exact charge rules',
                detail: 'Selected plan',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'business-plan-terms',
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < selected.terms.length; index++)
                      ListTile(
                        dense: true,
                        title: Text(
                          selected.terms[index].label,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(selected.terms[index].value),
                        leading: Icon(
                          index == 3
                              ? Icons.verified_outlined
                              : Icons.receipt_long_outlined,
                          color: index == 3
                              ? MoolColors.success
                              : MoolColors.navy,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'business-plan-protection',
                color: const Color(0xFFEAF7E8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: MoolColors.success,
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(child: Text(widget.service.protection)),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              Text(
                'Due on activation: ${_money(selected.monthly)} + GST · Renews monthly · cancel before renewal',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProtection(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 42,
              color: MoolColors.success,
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'Charge protection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(widget.service.protection, textAlign: TextAlign.center),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'Every additional charge must carry service-specific completion evidence and stay within your approved monthly limit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MoolColors.muted),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showCustomLimit(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _CustomServiceLimitSheet(session: widget.session),
      );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final RetailerBusinessPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: RetailerCard(
        keyName: 'business-plan-${plan.id}',
        color: selected ? const Color(0xFFEDEEFF) : Colors.white,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? MoolColors.navy
                    : MoolColors.navy.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.radio_button_off_rounded,
                color: selected ? Colors.white : MoolColors.navy,
                size: 19,
              ),
            ),
            const SizedBox(width: MoolSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: MoolSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      RetailerPill(label: plan.badge.toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plan.included,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    plan.additional,
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Text(
              '${_money(plan.monthly)}\n/month',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: MoolColors.success,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomServiceLimitSheet extends StatefulWidget {
  const _CustomServiceLimitSheet({required this.session});

  final RetailerSession session;

  @override
  State<_CustomServiceLimitSheet> createState() =>
      _CustomServiceLimitSheetState();
}

class _CustomServiceLimitSheetState extends State<_CustomServiceLimitSheet> {
  final controller = TextEditingController();
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.md,
          0,
          MoolSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
        ),
        child: Column(
          key: const Key('business-custom-limit-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set monthly spending limit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const Text(
              'New paid work stops at this amount unless you approve a change.',
              style: TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: MoolSpacing.md),
            TextField(
              key: const Key('business-custom-limit-input'),
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Limit in rupees',
                prefixText: '₹ ',
                errorText: error,
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            FilledButton(
              key: const Key('business-custom-limit-save'),
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null) {
                  setState(() => error = 'Enter a valid amount.');
                  return;
                }
                if (!widget.session.setBusinessServiceLimit(
                  value,
                  custom: true,
                )) {
                  setState(() => error = widget.session.errorMessage);
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('Set limit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final step in const [
          (1, 'Choose plan'),
          (2, 'Review'),
          (3, 'Activate'),
        ])
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
              decoration: BoxDecoration(
                color: step.$1 <= current
                    ? MoolColors.navy
                    : const Color(0xFFE9EAF3),
                borderRadius: BorderRadius.circular(MoolRadii.control),
              ),
              child: Text(
                '${step.$1} · ${step.$2}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: step.$1 <= current ? Colors.white : MoolColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class RetailerBusinessServiceReviewScreen extends StatefulWidget {
  const RetailerBusinessServiceReviewScreen({
    required this.session,
    required this.service,
    super.key,
  });

  final RetailerSession session;
  final RetailerBusinessServiceOffering service;

  @override
  State<RetailerBusinessServiceReviewScreen> createState() =>
      _RetailerBusinessServiceReviewScreenState();
}

class _RetailerBusinessServiceReviewScreenState
    extends State<RetailerBusinessServiceReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.session.selectedBusinessService?.type != widget.service.type) {
        widget.session.selectBusinessService(widget.service);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final plan =
            widget.session.selectedBusinessPlan ?? widget.service.plans.first;
        return RetailerPageScaffold(
          session: widget.session,
          title: 'Review activation',
          subtitle: '${widget.service.title} · ${plan.name}',
          activeDock: 'none',
          returnRoute: '/app/retailer/services/${widget.service.type.name}',
          trailing: IconButton.outlined(
            key: const Key('business-activation-help'),
            tooltip: 'Activation help',
            onPressed: () => widget.session.showNotice(
              'Review the exact charge, payment method and required consent. Nothing starts until you tap Pay & activate.',
            ),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          bottomAction: RetailerPrimaryButton(
            keyName: 'business-service-activate',
            label: 'Pay & activate',
            busy: widget.session.busy,
            onPressed: widget.session.businessServiceCanActivate
                ? () => _activate(context)
                : null,
          ),
          body: ListView(
            key: const Key('business-service-review-screen'),
            padding: const EdgeInsets.all(MoolSpacing.md),
            children: [
              const _ProgressStrip(current: 2),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                color: const Color(0xFFEDEEFF),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _serviceColor(
                        widget.service.type,
                      ).withValues(alpha: .12),
                      child: Icon(
                        _serviceIcon(widget.service.type),
                        color: _serviceColor(widget.service.type),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.service.title} · ${plan.name}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(plan.included),
                        ],
                      ),
                    ),
                    Text(
                      '${_money(plan.monthly)}\n/month + GST',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: MoolColors.success,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'What you authorize',
                detail: 'Exact selected terms',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'business-activation-terms',
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ReviewRow(
                      title: 'Due now',
                      detail: 'First monthly plan charge',
                      value: '${_money(plan.monthly)} + GST',
                    ),
                    _ReviewRow(
                      title: 'Additional charge',
                      detail: plan.additional,
                      value: 'After proof',
                    ),
                    _ReviewRow(
                      title: 'Monthly spending limit',
                      detail: 'No new paid work above this without approval',
                      value: _money(widget.session.businessServiceMonthlyLimit),
                    ),
                    const _ReviewRow(
                      title: 'Next renewal',
                      detail: 'Cancel or change before renewal',
                      value: '11 Aug 2026',
                    ),
                  ],
                ),
              ),
              if (widget.session.businessServiceTermsReviewed) ...[
                const SizedBox(height: MoolSpacing.xs),
                const Text(
                  'Service terms reviewed',
                  key: Key('business-terms-reviewed'),
                  style: TextStyle(
                    color: MoolColors.success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              TextButton(
                key: const Key('business-service-terms-link'),
                onPressed: widget.session.reviewBusinessServiceTerms,
                child: const Text('Read service terms'),
              ),
              const RetailerSectionTitle(
                title: 'Payment method',
                detail: 'Secure mandate or manual renewal',
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final payment in RetailerBusinessPayment.values) ...[
                _PaymentCard(
                  payment: payment,
                  selected: widget.session.businessServicePayment == payment,
                  onTap: () =>
                      widget.session.selectBusinessServicePayment(payment),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              const SizedBox(height: MoolSpacing.sm),
              const RetailerSectionTitle(
                title: 'Your consent',
                detail: 'Required to activate',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'business-consent-card',
                child: Column(
                  children: [
                    CheckboxListTile(
                      key: const Key('business-commercial-consent'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: widget.session.businessServiceCommercialConsent,
                      onChanged: (value) => widget.session
                          .setBusinessServiceCommercialConsent(value ?? false),
                      title: const Text(
                        'I approve this monthly plan, renewal, displayed charge rules and monthly limit.',
                      ),
                    ),
                    if (widget.service.requiresDataConsent)
                      CheckboxListTile(
                        key: const Key('business-data-consent'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: widget.session.businessServiceDataConsent,
                        onChanged: (value) => widget.session
                            .setBusinessServiceDataConsent(value ?? false),
                        title: const Text(
                          'I allow purpose-limited access to selected business records. Access is logged and can be revoked subject to filing obligations.',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                color: const Color(0xFFEAF7E8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: MoolColors.success,
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(child: Text(widget.service.protection)),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              Text(
                'Pay now: ${_money(plan.monthly)} + GST · Additional charges are not collected now',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _activate(BuildContext context) async {
    final completed = await widget.session.activateBusinessService();
    if (!context.mounted || !completed) return;
    context.go(
      Uri(
        path: '/app/retailer/services/${widget.service.type.name}',
        queryParameters: {'stage': 'active'},
      ).toString(),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.title,
    required this.detail,
    required this.value,
  });

  final String title;
  final String detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(detail),
      trailing: SizedBox(
        width: 118,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.selected,
    required this.onTap,
  });

  final RetailerBusinessPayment payment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (title, detail, mark) = switch (payment) {
      RetailerBusinessPayment.upi => (
        'UPI AutoPay · ending 4321',
        'Monthly plan and verified charges within your limit',
        'UPI',
      ),
      RetailerBusinessPayment.card => (
        'Visa · ending 6068',
        'Saved card mandate',
        'CARD',
      ),
      RetailerBusinessPayment.manual => (
        'Pay manually each month',
        'Service pauses if renewal is not paid',
        '1×',
      ),
    };
    return RetailerCard(
      keyName: 'business-payment-${payment.name}',
      color: selected ? const Color(0xFFEDEEFF) : Colors.white,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: selected ? MoolColors.navy : MoolColors.canvas,
            foregroundColor: selected ? Colors.white : MoolColors.navy,
            child: Text(
              mark,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
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
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? MoolColors.navy : MoolColors.muted,
          ),
        ],
      ),
    );
  }
}

class RetailerBusinessServiceActiveScreen extends StatelessWidget {
  const RetailerBusinessServiceActiveScreen({
    required this.session,
    required this.service,
    super.key,
  });

  final RetailerSession session;
  final RetailerBusinessServiceOffering service;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final active = session.activeBusinessService(service.type);
        if (active == null) {
          return RetailerPageScaffold(
            session: session,
            title: service.title,
            subtitle: 'Activation required',
            activeDock: 'none',
            returnRoute: '/app/retailer/services',
            body: Center(
              child: RetailerEmptyState(
                keyName: 'business-service-not-active',
                title: 'This service is not active',
                detail:
                    'Choose a plan, spending limit, payment method and consent before starting.',
                actionLabel: 'Choose plan',
                onAction: () =>
                    context.go('/app/retailer/services/${service.type.name}'),
              ),
            ),
          );
        }
        return RetailerPageScaffold(
          session: session,
          title: service.title,
          subtitle: 'Active business service',
          activeDock: 'none',
          returnRoute: '/app/retailer/services',
          trailing: IconButton.outlined(
            key: const Key('business-service-menu'),
            tooltip: 'Service settings',
            onPressed: () => _showManageMenu(context, active),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          body: ListView(
            key: const Key('business-service-active-screen'),
            padding: const EdgeInsets.all(MoolSpacing.md),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Service ID ${active.id}',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const RetailerPill(label: 'ACTIVE', icon: Icons.circle),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'business-active-entitlement',
                color: MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          foregroundColor: _serviceColor(service.type),
                          child: Icon(_serviceIcon(service.type)),
                        ),
                        const SizedBox(width: MoolSpacing.sm),
                        Expanded(
                          child: Text(
                            service.state,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MoolSpacing.xs,
                            vertical: MoolSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(
                              MoolRadii.capsule,
                            ),
                          ),
                          child: Text(
                            active.plan.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      service.detail,
                      style: const TextStyle(
                        color: Color(0xFFD9DAFF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Wrap(
                      spacing: MoolSpacing.sm,
                      runSpacing: MoolSpacing.xxs,
                      children: [
                        Text(
                          '✓ ${active.payment.label} confirmed',
                          style: const TextStyle(
                            color: MoolColors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Renews 11 Aug',
                          style: TextStyle(
                            color: Color(0xFFD9DAFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'This month',
                detail: 'Live plan usage and spend',
              ),
              const SizedBox(height: MoolSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MetricCard(
                        keyName: 'business-usage',
                        label: service.usageLabel,
                        value: '0 / ${active.plan.includedUnits}',
                        detail: '${active.plan.includedUnits} remaining',
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: _MetricCard(
                        keyName: 'business-spend',
                        label: 'SPEND / LIMIT',
                        value:
                            '${_money(active.plan.monthly)} / ${_money(active.monthlyLimit)}',
                        detail: 'Plan paid',
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    const Expanded(
                      child: _MetricCard(
                        keyName: 'business-additional',
                        label: 'ADDITIONAL',
                        value: '₹0',
                        detail: 'No extra charge',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerCard(
                keyName: 'business-primary-work',
                color: const Color(0xFFFFF4E6),
                onTap: () => _openPrimaryWork(context, active),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.workTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            service.workDetail,
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 122,
                      child: FilledButton.tonal(
                        onPressed: () => _openPrimaryWork(context, active),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(service.workAction),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerSectionTitle(
                title: service.setupTitle,
                detail: 'Tap each item to complete service readiness',
              ),
              const SizedBox(height: MoolSpacing.sm),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: .9,
                mainAxisSpacing: MoolSpacing.xs,
                crossAxisSpacing: MoolSpacing.xs,
                children: [
                  for (final setup in service.quickSetup)
                    RetailerCard(
                      keyName: 'business-setup-${setup.$1.toLowerCase()}',
                      color: active.readySetup.contains(setup.$1)
                          ? const Color(0xFFEAF7E8)
                          : Colors.white,
                      padding: const EdgeInsets.all(MoolSpacing.xs),
                      onTap: () => session.completeBusinessServiceSetup(
                        service.type,
                        setup.$1,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            active.readySetup.contains(setup.$1)
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: active.readySetup.contains(setup.$1)
                                ? MoolColors.success
                                : MoolColors.navy,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            setup.$1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            active.readySetup.contains(setup.$1)
                                ? 'Ready'
                                : setup.$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              const RetailerSectionTitle(
                title: 'Recent activity',
                detail: 'Auditable records',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'business-service-activity',
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle_rounded,
                        color: MoolColors.success,
                      ),
                      title: const Text(
                        'Service activated',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${active.plan.name} · ${active.payment.label} · ${_money(active.monthlyLimit)} limit',
                      ),
                      trailing: const Text('Today'),
                    ),
                    ListTile(
                      leading: const CircleAvatar(child: Text('0')),
                      title: Text(
                        service.emptyActivity,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text(
                        'New activity appears here with proof and charges',
                      ),
                      trailing: const Text('Live'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('business-manage-plan'),
                      onPressed: () => context.go(
                        '/app/retailer/services/${service.type.name}',
                      ),
                      child: const Text('Plan & billing'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: FilledButton(
                      key: const Key('business-service-support'),
                      onPressed: session.busy
                          ? null
                          : () => _openSupport(context, active),
                      child: const Text('Service support'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPrimaryWork(
    BuildContext context,
    RetailerActiveBusinessService active,
  ) async {
    switch (service.type) {
      case RetailerBusinessServiceType.delivery:
        context.go('/app/retailer/orders');
      case RetailerBusinessServiceType.books:
        context.go('/app/retailer/books');
      case RetailerBusinessServiceType.growth:
      case RetailerBusinessServiceType.ads:
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(MoolSpacing.md),
              child: Column(
                key: const Key('business-primary-work-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    _serviceIcon(service.type),
                    size: 42,
                    color: _serviceColor(service.type),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  Text(
                    service.workTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    service.workDetail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: MoolColors.muted),
                  ),
                  const SizedBox(height: MoolSpacing.md),
                  FilledButton(
                    key: const Key('business-primary-work-complete'),
                    onPressed: () async {
                      final pending = service.quickSetup.firstWhere(
                        (item) => !active.readySetup.contains(item.$1),
                        orElse: () => service.quickSetup.first,
                      );
                      final completed = await session
                          .completeBusinessServiceSetup(
                            service.type,
                            pending.$1,
                          );
                      if (!sheetContext.mounted || !completed) return;
                      Navigator.pop(sheetContext);
                    },
                    child: Text('${service.workAction} setup'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  Future<void> _openSupport(
    BuildContext context,
    RetailerActiveBusinessService active,
  ) async {
    final completed = await session.openBusinessServiceSupport(
      active.offering.type,
    );
    if (!context.mounted || !completed) return;
    context.go(
      Uri(
        path: '/app/chat/thread/order-support',
        queryParameters: {
          'return': '/app/retailer/services/${service.type.name}?stage=active',
        },
      ).toString(),
    );
  }

  Future<void> _showManageMenu(
    BuildContext context,
    RetailerActiveBusinessService active,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          0,
          MoolSpacing.md,
          MoolSpacing.md,
        ),
        child: Column(
          key: const Key('business-service-manage-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${service.title} settings',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MoolSpacing.sm),
            ListTile(
              key: const Key('business-menu-plan'),
              leading: const Icon(Icons.credit_card_outlined),
              title: const Text('Plan, limit and billing'),
              subtitle: Text(
                '${active.plan.name} · ${_money(active.monthlyLimit)} limit',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(sheetContext);
                context.go('/app/retailer/services/${service.type.name}');
              },
            ),
            ListTile(
              key: const Key('business-menu-cancel'),
              leading: const Icon(
                Icons.cancel_outlined,
                color: Color(0xFFB42318),
              ),
              title: const Text('Stop renewal'),
              subtitle: const Text(
                'Current paid access remains until the renewal date',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmCancel(context, active);
              },
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmCancel(
    BuildContext context,
    RetailerActiveBusinessService active,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('business-service-cancel-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Stop monthly renewal?',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(
              '${active.offering.title} stays available until 11 Aug 2026. No new monthly plan charge follows after confirmed cancellation.',
            ),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: const Key('business-cancel-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              onPressed: () async {
                final completed = await session.cancelBusinessService(
                  service.type,
                );
                if (!sheetContext.mounted || !completed) return;
                Navigator.pop(sheetContext);
                if (context.mounted) {
                  context.go('/app/retailer/services');
                }
              },
              child: const Text('Stop renewal'),
            ),
            TextButton(
              key: const Key('business-cancel-keep'),
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Keep service'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.keyName,
    required this.label,
    required this.value,
    required this.detail,
  });

  final String keyName;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      keyName: keyName,
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            detail,
            style: const TextStyle(color: MoolColors.success, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
