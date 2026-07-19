import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/mool_design_system.dart';
import '../../../../core/design/mool_theme.dart';
import '../operations_session.dart';
import '../widgets/operations_widgets.dart';

class EarnOpportunitiesScreen extends StatelessWidget {
  const EarnOpportunitiesScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Earn',
      subtitle: 'Matched paid work · Jodhpur',
      activeDock: 'opportunities',
      returnRoute: '/app/earn',
      provider: false,
      showBack: false,
      trailing: IconButton.outlined(
        key: const Key('earn-opportunity-filters'),
        tooltip: 'Filter opportunities',
        onPressed: () => _filterSheet(context),
        icon: const Icon(Icons.tune_rounded),
      ),
      body: ListView(
        key: const Key('earn-opportunities-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FUNDED MONTHLY POTENTIAL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '₹28,000–₹74,000',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Based on open eligible outputs · not guaranteed income',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(label: '426 OPEN', color: MoolColors.orange),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: OpsMetric(
                  label: 'BEST MATCH',
                  value: '32',
                  detail: 'eligible',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'NEARBY',
                  value: '18',
                  detail: 'Jodhpur',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'REMOTE',
                  value: '14',
                  detail: 'from home',
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          _EarnSegments(session: session),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Matched opportunities',
            detail: 'Compare before applying',
          ),
          const SizedBox(height: MoolSpacing.sm),
          ...reviewEarnOpportunities.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.sm),
              child: _EarnOpportunityCard(
                item: item,
                onOpen: () {
                  session.selectOpportunity(item.id);
                  _opportunitySheet(context);
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _filterSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('earn-filter-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose work to compare',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const Text('Match, place, proof and funded capacity.'),
            const SizedBox(height: MoolSpacing.md),
            _EarnSegments(session: session, keyPrefix: 'earn-filter-sheet'),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('earn-filter-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Show Opportunities'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _opportunitySheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final item = session.selectedOpportunity;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                key: const Key('earn-opportunity-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(item.source),
                  const SizedBox(height: MoolSpacing.md),
                  OpsCard(
                    color: const Color(0xFFF4F3FF),
                    child: Column(
                      children: [
                        OpsFact(label: 'Output', value: item.title),
                        OpsFact(label: 'Payout', value: item.payout),
                        OpsFact(label: 'Place / time', value: item.place),
                        OpsFact(label: 'Proof', value: item.proof),
                        const OpsFact(
                          label: 'Review target',
                          value: 'Within 24 hours',
                        ),
                        const OpsFact(
                          label: 'Correction',
                          value: 'One attempt',
                        ),
                        const OpsFact(
                          label: 'Funding',
                          value: 'Reserved for approved output',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  const Text(
                    'The business or MoolSocial funds approved work. You never pay to apply or start. Potential depends on eligibility and approved output; it is not salary or guaranteed income.',
                    style: TextStyle(
                      color: MoolColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('earn-opportunity-terms'),
                    contentPadding: EdgeInsets.zero,
                    value: session.opportunityTermsAccepted,
                    onChanged: (value) =>
                        session.confirmOpportunityTerms(value ?? false),
                    title: const Text(
                      'I reviewed the work, proof, payout and correction terms',
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('earn-opportunity-apply'),
                      onPressed: session.busy ? null : session.applyOpportunity,
                      child: Text(
                        session.applicationId == null
                            ? 'Apply for Funded Work'
                            : 'Application Sent',
                      ),
                    ),
                  ),
                  if (session.applicationId != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('earn-opportunity-open-work'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          context.go('/app/earn/applications');
                        },
                        child: const Text('Open My Work'),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('earn-opportunity-close'),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class EarnApplicationsScreen extends StatelessWidget {
  const EarnApplicationsScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'My Work',
      subtitle: 'Applications, saved work and eligibility',
      activeDock: 'work',
      returnRoute: '/app/earn',
      provider: false,
      trailing: IconButton.outlined(
        key: const Key('earn-eligibility-open'),
        tooltip: 'Open eligibility',
        onPressed: () =>
            session.setApplicationTab(EarnApplicationTab.eligibility),
        icon: const Icon(Icons.verified_user_outlined),
      ),
      body: ListView(
        key: const Key('earn-applications-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          _EnumSegments<EarnApplicationTab>(
            values: EarnApplicationTab.values,
            selected: session.applicationTab,
            keyPrefix: 'earn-app-tab',
            label: (value) => switch (value) {
              EarnApplicationTab.applied => 'Applied',
              EarnApplicationTab.saved => 'Saved',
              EarnApplicationTab.eligibility => 'Eligibility',
            },
            onSelect: session.setApplicationTab,
          ),
          const SizedBox(height: MoolSpacing.md),
          if (session.applicationTab == EarnApplicationTab.applied) ...[
            OpsActionRow(
              keyName: 'earn-application-approved',
              icon: Icons.check_circle_outline_rounded,
              title: 'Onboard verified grocery retailer',
              detail: 'Jodhpur · ₹450 per approved output',
              meta: 'Approved · seat reserved for 4 hours',
              action: 'Open',
              color: const Color(0xFFEAF7E8),
              onTap: () {
                session.selectApplication('approved');
                _applicationSheet(context, approved: true);
              },
            ),
            const SizedBox(height: MoolSpacing.sm),
            OpsActionRow(
              keyName: 'earn-application-review',
              icon: Icons.hourglass_top_rounded,
              title: 'Verify shop display and QR',
              detail: 'Sardarpura · ₹220 per approved shop',
              meta: 'Eligibility and capacity under review',
              action: 'Status',
              onTap: () {
                session.selectApplication('review');
                _applicationSheet(context, approved: false);
              },
            ),
          ] else if (session.applicationTab == EarnApplicationTab.saved)
            OpsActionRow(
              keyName: 'earn-saved-catalog',
              icon: Icons.inventory_2_outlined,
              title: 'Validate FMCG catalogue',
              detail: 'Remote · ₹18 per approved SKU',
              meta: '240 funded units open',
              action: 'Review',
              onTap: () => context.go('/app/earn'),
            )
          else
            const OpsCard(
              color: Color(0xFFF4F3FF),
              child: Column(
                children: [
                  _EligibilityRow(title: 'Identity and payout', value: 'Ready'),
                  _EligibilityRow(
                    title: 'Retailer onboarding training',
                    value: 'Complete',
                  ),
                  _EligibilityRow(title: 'GPS and photo proof', value: 'Ready'),
                  _EligibilityRow(title: 'Jodhpur work area', value: 'Active'),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _applicationSheet(
    BuildContext context, {
    required bool approved,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('earn-application-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                approved ? 'Assignment approved' : 'Application under review',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                approved
                    ? 'Funding and eligibility are reserved for 4 hours.'
                    : 'You do not need to apply again.',
              ),
              const SizedBox(height: MoolSpacing.md),
              OpsCard(
                color: const Color(0xFFF4F3FF),
                child: Column(
                  children: [
                    OpsFact(
                      label: 'Status',
                      value: approved ? 'Approved' : 'Under review',
                    ),
                    OpsFact(
                      label: 'Reserved seat',
                      value: approved ? '4 hours' : 'Not yet reserved',
                    ),
                    const OpsFact(label: 'Training', value: 'Complete'),
                    const OpsFact(label: 'Conflict check', value: 'Passed'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              if (approved)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('earn-work-start'),
                    onPressed: session.busy
                        ? null
                        : () async {
                            if (await session.startApprovedWork() &&
                                context.mounted) {
                              Navigator.pop(sheetContext);
                              context.go('/app/earn/active');
                            }
                          },
                    child: Text(
                      session.workStartId == null
                          ? 'Start Work'
                          : 'Work Started',
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('earn-application-close'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EarnActiveWorkScreen extends StatelessWidget {
  const EarnActiveWorkScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Active Work',
      subtitle: 'WRK-4821 · one bounded output',
      activeDock: 'work',
      returnRoute: '/app/earn/applications',
      provider: false,
      trailing: IconButton.outlined(
        key: const Key('earn-work-support'),
        tooltip: 'Get work support',
        onPressed: () => _supportSheet(context),
        icon: const Icon(Icons.help_outline_rounded),
      ),
      bottomAction: FilledButton(
        key: const Key('earn-work-continue-proof'),
        onPressed: () => context.go('/app/earn/proof'),
        child: const Text('Continue to Proof'),
      ),
      body: ListView(
        key: const Key('earn-active-work-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSIGNED OUTPUT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Onboard Mahadev Fresh Mart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Jodhpur · ₹450 after approved activation',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(label: '3H 42M', color: MoolColors.orange),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: OpsMetric(
                  label: 'PAYOUT',
                  value: '₹450',
                  detail: 'approved',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'PROOF',
                  value: '4 items',
                  detail: 'required',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'REVIEW',
                  value: '≤24 h',
                  detail: 'target',
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Complete the assigned output',
            detail: 'Only the required steps',
          ),
          const SizedBox(height: MoolSpacing.sm),
          const _WorkStep(
            index: '✓',
            title: 'Meet authorized owner',
            detail: 'Owner OTP and identity match',
            status: 'Done',
            complete: true,
          ),
          const _WorkStep(
            index: '✓',
            title: 'Capture business details',
            detail: 'Shop, category and GST when available',
            status: 'Done',
            complete: true,
          ),
          const _WorkStep(
            index: '3',
            title: 'Place and verify QR',
            detail: 'Location, shop photo and successful QR scan',
            status: 'Next',
          ),
          const _WorkStep(
            index: '4',
            title: 'Complete first activation',
            detail: 'Owner confirms app access',
            status: 'Pending',
          ),
          const SizedBox(height: MoolSpacing.sm),
          const OpsCard(
            color: Color(0xFFFFF6E8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFFB05C00)),
                SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: Text(
                    'Do only this assigned output. Never collect cash, passwords or unrelated documents. Business consent remains required.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _supportSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.md,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('earn-work-support-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Work support',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('Support stays linked to WRK-4821 and its terms.'),
                const SizedBox(height: MoolSpacing.md),
                DropdownButtonFormField<String>(
                  key: const Key('earn-support-category'),
                  initialValue: session.supportCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Issue'),
                  items:
                      const [
                            'Business unavailable',
                            'Reschedule',
                            'Wrong location',
                            'Safety issue',
                            'Terms question',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => session.selectSupportCategory(value!),
                ),
                const SizedBox(height: MoolSpacing.sm),
                TextField(
                  key: const Key('earn-support-details'),
                  minLines: 3,
                  maxLines: 4,
                  onChanged: session.updateSupportDetails,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    hintText: 'Describe what needs help',
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('earn-support-submit'),
                    onPressed: session.busy ? null : session.openEarnSupport,
                    child: Text(
                      session.earnSupportId == null
                          ? 'Open support case'
                          : 'Case opened',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('earn-support-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class EarnProofScreen extends StatelessWidget {
  const EarnProofScreen({required this.session, super.key});

  final OperationsSession session;

  static const proofItems = <(String, String, String)>[
    ('owner-otp', 'Owner OTP', 'Matched 10:06'),
    ('shop-photo', 'Shop photo', 'Location + time saved'),
    ('qr-test', 'QR scan confirmation', 'Activation confirmed'),
    ('owner-confirmed', 'Owner confirmed', 'App access active'),
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Submit work proof',
      subtitle: 'WRK-4821 · retailer activation',
      activeDock: 'work',
      returnRoute: '/app/earn/active',
      provider: false,
      trailing: IconButton.outlined(
        key: const Key('earn-proof-help'),
        tooltip: 'How verification works',
        onPressed: () => _verificationHelp(context),
        icon: const Icon(Icons.help_outline_rounded),
      ),
      bottomAction: FilledButton(
        key: const Key('earn-proof-submit'),
        onPressed: session.busy ? null : () => _submit(context),
        child: Text(
          session.outcomeId == null
              ? 'Submit for verification'
              : 'Proof submitted',
        ),
      ),
      body: ListView(
        key: const Key('earn-proof-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          OpsCard(
            color: const Color(0xFFF4F3FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Required proof · ${session.capturedProof.length} of 4 captured',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: MoolSpacing.xs),
                LinearProgressIndicator(
                  value: session.capturedProof.length / 4,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: MoolSpacing.xs,
            mainAxisSpacing: MoolSpacing.xs,
            childAspectRatio: 1.15,
            children: [
              for (final item in proofItems)
                OpsCard(
                  keyName: 'earn-proof-${item.$1}',
                  onTap: () => session.toggleProof(item.$1),
                  color: session.capturedProof.contains(item.$1)
                      ? const Color(0xFFEAF7E8)
                      : Colors.white,
                  padding: const EdgeInsets.all(MoolSpacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        session.capturedProof.contains(item.$1)
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: session.capturedProof.contains(item.$1)
                            ? MoolColors.success
                            : MoolColors.navy,
                      ),
                      const SizedBox(height: MoolSpacing.xxs),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        item.$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
          const OpsCard(
            color: Color(0xFFFFF6E8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹450 held for this output',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Automated checks run first. Any rejection must include a reason, correction option and appeal path.',
                  style: TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            key: const Key('earn-proof-truth'),
            contentPadding: EdgeInsets.zero,
            value: session.outcomeTruthConfirmed,
            onChanged: (value) => session.confirmOutcomeTruth(value ?? false),
            title: const Text(
              'I confirm this proof shows the assigned output completed',
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit(BuildContext context) async {
    if (await session.submitOutcome() && context.mounted) {
      await _submittedSheet(context);
    }
  }

  Future<void> _verificationHelp(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('earn-proof-help-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How verification works',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'Location, time, activation and owner confirmation are checked against this assignment. Reviewers see only the evidence needed for the decision.',
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('earn-proof-help-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Got It'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submittedSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              key: const Key('earn-outcome-submitted-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outcome submitted',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('Verification target: within 24 hours.'),
                const SizedBox(height: MoolSpacing.md),
                const OpsCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      OpsFact(label: 'Work', value: 'WRK-4821'),
                      OpsFact(label: 'Evidence', value: '4 items'),
                      OpsFact(label: 'Payout held', value: '₹450'),
                      OpsFact(label: 'Status', value: 'Verifying'),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('earn-outcome-open-earnings'),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go('/app/earn/earnings');
                    },
                    child: const Text('Track Earnings'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('earn-outcome-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class EarnEarningsScreen extends StatelessWidget {
  const EarnEarningsScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Earnings',
      subtitle: 'Approved outputs, holds and payouts',
      activeDock: 'earnings',
      returnRoute: '/app/earn',
      provider: false,
      trailing: IconButton.outlined(
        key: const Key('earn-statement-open'),
        tooltip: 'Prepare earnings statement',
        onPressed: () => _statementSheet(context),
        icon: const Icon(Icons.download_rounded),
      ),
      body: ListView(
        key: const Key('earn-earnings-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVAILABLE FOR PAYOUT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '₹4,860',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Verified bank ••4421 · automatic payout tomorrow',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: OpsMetric(
                  label: 'THIS MONTH',
                  value: '₹18,240',
                  detail: 'earned',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'UNDER REVIEW',
                  value: '₹1,120',
                  detail: 'held',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'PAID',
                  value: '₹13,380',
                  detail: 'settled',
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          const OpsCard(
            color: Color(0xFFFFF6E8),
            child: Text(
              'Only approved funded output becomes payable. Applying, travelling or spending time does not create automatic payout.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Recent earnings',
            detail: 'Linked to each task',
          ),
          const SizedBox(height: MoolSpacing.sm),
          ...const [
            (
              'retailer-4818',
              'Retailer onboarding · WRK-4818',
              'Approved activation · 12 July',
              '+₹450',
            ),
            (
              'qr-4807',
              'QR verification · WRK-4807',
              '8 approved shops',
              '+₹1,760',
            ),
            (
              'retailer-4821',
              'Retailer onboarding · WRK-4821',
              'Outcome verification in progress',
              '₹450 held',
            ),
            (
              'payout-0710',
              'Bank payout',
              'UTR available · 10 July',
              '−₹6,240',
            ),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
              child: OpsActionRow(
                keyName: 'earn-ledger-${item.$1}',
                icon: Icons.receipt_long_outlined,
                title: item.$2,
                detail: item.$3,
                meta: item.$4,
                action: 'Details',
                onTap: () => _ledgerSheet(context, item),
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('earn-open-history'),
            onPressed: () => context.go('/app/earn/history'),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Issues, ratings and work history'),
          ),
        ],
      ),
    ),
  );

  Future<void> _statementSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('earn-statement-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earnings statement',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('Approved output, adjustments and payouts.'),
                const SizedBox(height: MoolSpacing.md),
                const OpsCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      OpsFact(label: 'Earned', value: '₹18,240'),
                      OpsFact(label: 'Paid', value: '₹13,380'),
                      OpsFact(label: 'Available', value: '₹4,860'),
                      OpsFact(label: 'Under review', value: '₹1,120'),
                      OpsFact(label: 'Account', value: '••4421'),
                      OpsFact(label: 'Formats', value: 'PDF and CSV'),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('earn-statement-prepare'),
                    onPressed: session.busy ? null : session.prepareStatement,
                    child: Text(
                      session.statementId == null
                          ? 'Prepare Statement'
                          : 'Statement Ready',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('earn-statement-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _ledgerSheet(
    BuildContext context,
    (String, String, String, String) item,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('earn-ledger-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.$2,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(item.$3),
            const SizedBox(height: MoolSpacing.md),
            OpsCard(
              color: const Color(0xFFF4F3FF),
              child: Column(
                children: [
                  OpsFact(label: 'Amount', value: item.$4),
                  const OpsFact(
                    label: 'Why this amount',
                    value: 'Approved funded output',
                  ),
                  const OpsFact(
                    label: 'Returns',
                    value: 'Accounted before payout',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('earn-ledger-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EarnHistoryScreen extends StatelessWidget {
  const EarnHistoryScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'History & Support',
      subtitle: 'Ratings, issues, decisions and growth',
      activeDock: 'work',
      returnRoute: '/app/earn/earnings',
      provider: false,
      trailing: IconButton.outlined(
        key: const Key('earn-history-support'),
        tooltip: 'Open support',
        onPressed: () => _supportSheet(context),
        icon: const Icon(Icons.support_agent_rounded),
      ),
      body: ListView(
        key: const Key('earn-history-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RELIABILITY',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Trusted Field Partner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '96% approved · 4.8 rating · Level 3',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(label: 'LEVEL 3', color: MoolColors.orange),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: OpsMetric(
                  label: 'COMPLETED',
                  value: '148',
                  detail: 'outputs',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'APPROVED',
                  value: '142',
                  detail: 'paid',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'CORRECTED',
                  value: '6',
                  detail: 'resolved',
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          _EnumSegments<EarnHistoryTab>(
            values: EarnHistoryTab.values,
            selected: session.historyTab,
            keyPrefix: 'earn-history-tab',
            label: (value) => switch (value) {
              EarnHistoryTab.history => 'History',
              EarnHistoryTab.issues => 'Issues',
              EarnHistoryTab.growth => 'Growth',
            },
            onSelect: session.setHistoryTab,
          ),
          const SizedBox(height: MoolSpacing.md),
          ..._historyRows(context),
        ],
      ),
    ),
  );

  List<Widget> _historyRows(BuildContext context) {
    final rows = switch (session.historyTab) {
      EarnHistoryTab.history => const [
        ('4818', 'Retailer onboarding · WRK-4818', 'Approved · ₹450 paid'),
        ('4807', 'QR verification · WRK-4807', 'Approved · ₹1,760 paid'),
      ],
      EarnHistoryTab.issues => const [
        (
          'issue-02',
          'Shop photo needed correction',
          'Resolved after one update',
        ),
      ],
      EarnHistoryTab.growth => const [
        (
          'level',
          '12 more approvals to Level 4',
          'Unlock higher-capacity work',
        ),
      ],
    };
    return rows
        .map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
            child: OpsActionRow(
              keyName: 'earn-history-${row.$1}',
              icon: session.historyTab == EarnHistoryTab.issues
                  ? Icons.info_outline_rounded
                  : Icons.history_rounded,
              title: row.$2,
              detail: row.$3,
              action: 'Open',
              onTap: () {
                session.selectWorkRecord(row.$1);
                _recordSheet(context, row);
              },
            ),
          ),
        )
        .toList();
  }

  Future<void> _recordSheet(
    BuildContext context,
    (String, String, String) row,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('earn-work-record-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.$2,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(row.$3),
            const SizedBox(height: MoolSpacing.md),
            const OpsCard(
              color: Color(0xFFF4F3FF),
              child: Column(
                children: [
                  OpsFact(label: 'Decision', value: 'Approved'),
                  OpsFact(label: 'Rating', value: '5.0'),
                  OpsFact(label: 'Payout', value: '₹450 paid'),
                  OpsFact(label: 'Evidence', value: 'Available for review'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('earn-record-open-support'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _supportSheet(context);
                },
                child: const Text('Open support case'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('earn-record-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _supportSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.md,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('earn-history-support-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Work support',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('Choose the work record and describe the issue.'),
                const SizedBox(height: MoolSpacing.md),
                TextField(
                  key: const Key('earn-history-support-details'),
                  minLines: 3,
                  maxLines: 4,
                  onChanged: session.updateSupportDetails,
                  decoration: const InputDecoration(
                    labelText: 'What should be reviewed?',
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('earn-history-support-submit'),
                    onPressed: session.busy ? null : session.openEarnSupport,
                    child: Text(
                      session.earnSupportId == null
                          ? 'Open support case'
                          : 'Case opened',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('earn-history-support-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EarnSegments extends StatelessWidget {
  const _EarnSegments({required this.session, this.keyPrefix = 'earn-filter'});

  final OperationsSession session;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: EarnOpportunityFilter.values
          .map(
            (value) => Padding(
              padding: const EdgeInsets.only(right: MoolSpacing.xs),
              child: MoolSegment(
                key: Key('$keyPrefix-${value.name}'),
                label: switch (value) {
                  EarnOpportunityFilter.bestMatch => 'Best Match',
                  EarnOpportunityFilter.onboarding => 'Onboarding',
                  EarnOpportunityFilter.campaign => 'Campaign',
                  EarnOpportunityFilter.verification => 'Verification',
                  EarnOpportunityFilter.delivery => 'Delivery',
                },
                selected: session.opportunityFilter == value,
                onPressed: () => session.setOpportunityFilter(value),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _EarnOpportunityCard extends StatelessWidget {
  const _EarnOpportunityCard({required this.item, required this.onOpen});

  final EarnOpportunity item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => OpsCard(
    keyName: 'earn-opportunity-${item.id}',
    onTap: onOpen,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.source,
                    style: const TextStyle(
                      color: MoolColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            OpsPill(label: item.capacity, color: const Color(0xFFB05C00)),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MiniFact(label: 'PAYOUT', value: item.payout),
            ),
            Expanded(
              child: _MiniFact(label: 'PLACE / TIME', value: item.place),
            ),
            Expanded(
              child: _MiniFact(label: 'PROOF', value: item.proof),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: Key('earn-opportunity-review-${item.id}'),
            onPressed: onOpen,
            child: const Text('Review & Apply'),
          ),
        ),
      ],
    ),
  );
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: MoolSpacing.xs),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: MoolColors.orange, width: 2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _EnumSegments<T> extends StatelessWidget {
  const _EnumSegments({
    required this.values,
    required this.selected,
    required this.keyPrefix,
    required this.label,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String keyPrefix;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: values
          .map(
            (value) => Padding(
              padding: const EdgeInsets.only(right: MoolSpacing.xs),
              child: MoolSegment(
                key: Key('$keyPrefix-${(value as Enum).name}'),
                label: label(value),
                selected: value == selected,
                onPressed: () => onSelect(value),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _EligibilityRow extends StatelessWidget {
  const _EligibilityRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 13,
          backgroundColor: MoolColors.success,
          foregroundColor: Colors.white,
          child: Icon(Icons.check_rounded, size: 16),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        OpsPill(label: value),
      ],
    ),
  );
}

class _WorkStep extends StatelessWidget {
  const _WorkStep({
    required this.index,
    required this.title,
    required this.detail,
    required this.status,
    this.complete = false,
  });

  final String index;
  final String title;
  final String detail;
  final String status;
  final bool complete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
    child: OpsCard(
      color: complete ? const Color(0xFFEAF7E8) : Colors.white,
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: complete
                ? MoolColors.success
                : MoolColors.navy.withValues(alpha: .08),
            foregroundColor: complete ? Colors.white : MoolColors.navy,
            child: Text(
              index,
              style: const TextStyle(fontWeight: FontWeight.w900),
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
          OpsPill(
            label: status.toUpperCase(),
            color: complete ? MoolColors.success : const Color(0xFFB05C00),
          ),
        ],
      ),
    ),
  );
}
