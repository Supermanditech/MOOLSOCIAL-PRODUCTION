import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../captain_models.dart';
import '../captain_session.dart';
import '../widgets/captain_widgets.dart';

class CaptainEarningsScreen extends StatelessWidget {
  const CaptainEarningsScreen({
    required this.session,
    this.initialTab = CaptainEarningsTab.today,
    super.key,
  });

  final CaptainSession session;
  final CaptainEarningsTab initialTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CaptainPageScaffold(
        session: session,
        title: 'Earnings',
        subtitle: 'Trips, charges, incentives and payouts',
        activeDock: 'earnings',
        returnRoute: '/app/captain',
        trailing: IconButton.outlined(
          key: const Key('captain-earnings-download'),
          tooltip: 'Download earnings statement',
          onPressed: () => _payoutSheet(context, statement: true),
          icon: const Icon(Icons.download_rounded),
        ),
        body: ListView(
          key: const Key('captain-earnings-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CaptainCard(
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
                  SizedBox(height: MoolSpacing.xxs),
                  Text(
                    '₹3,090',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7,
                    ),
                  ),
                  Text(
                    'Includes ₹250 from MS-R4821 · bank ending 4421',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CaptainEarningsTab.values
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xs),
                        child: MoolSegment(
                          key: Key('captain-earnings-tab-${tab.name}'),
                          label: switch (tab) {
                            CaptainEarningsTab.today => 'Today',
                            CaptainEarningsTab.week => 'This Week',
                            CaptainEarningsTab.payouts => 'Payouts',
                          },
                          selected: session.earningsTab == tab,
                          onPressed: () => session.setEarningsTab(tab),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            if (session.earningsTab == CaptainEarningsTab.payouts)
              _PayoutSummary(session: session)
            else
              _EarningSummary(tab: session.earningsTab),
            const SizedBox(height: MoolSpacing.sm),
            CaptainCard(
              keyName: 'captain-payout-details',
              onTap: () => _payoutSheet(context),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFEAF7E8),
                    foregroundColor: MoolColors.success,
                    child: Icon(Icons.account_balance_outlined),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automatic payout · Tomorrow',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '₹3,090 to verified bank account',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Details',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const CaptainSectionTitle(
              title: 'Recent trips',
              detail: 'Confirmed earnings',
            ),
            const SizedBox(height: MoolSpacing.sm),
            ...reviewCaptainEarnings.map(
              (earning) => Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                child: CaptainActionRow(
                  keyName: 'captain-earning-${earning.id}',
                  icon: Icons.receipt_long_outlined,
                  title: '${earning.id} · ${earning.destination}',
                  detail:
                      'Gross ₹${earning.gross} · platform ₹${earning.platformCharge}',
                  meta: 'Net ₹${earning.net} · ${earning.status.toLowerCase()}',
                  action: 'View',
                  onTap: () => _earningSheet(context, earning),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _earningSheet(BuildContext context, CaptainEarning earning) {
    session.selectEarning(earning.id);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('captain-earning-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${earning.id} · ${earning.destination}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text('Every amount is tied to the completed trip.'),
              const SizedBox(height: MoolSpacing.md),
              CaptainCard(
                color: const Color(0xFFF4F3FF),
                child: Column(
                  children: [
                    _BusinessLine(
                      label: 'Gross fare',
                      value: '₹${earning.gross}',
                    ),
                    _BusinessLine(
                      label: 'Platform charge',
                      value: '−₹${earning.platformCharge}',
                    ),
                    _BusinessLine(
                      label: 'Net earning',
                      value: '₹${earning.net}',
                    ),
                    _BusinessLine(label: 'Status', value: earning.status),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('captain-earning-close'),
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

  Future<void> _payoutSheet(
    BuildContext context, {
    bool statement = false,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('captain-payout-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statement ? 'Earnings statement' : 'Payout details',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Every amount is linked to completed and reconciled work.',
            ),
            const SizedBox(height: MoolSpacing.md),
            const CaptainCard(
              color: Color(0xFFF4F3FF),
              child: Column(
                children: [
                  _BusinessLine(label: 'Available', value: '₹3,090'),
                  _BusinessLine(label: 'Scheduled', value: 'Tomorrow'),
                  _BusinessLine(label: 'Cash adjustment', value: '−₹420'),
                  _BusinessLine(label: 'TDS / tax', value: 'As applicable'),
                  _BusinessLine(label: 'Account', value: 'Bank ••4421'),
                  _BusinessLine(label: 'Status', value: 'Ready'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('captain-open-statement'),
                onPressed: () {
                  session.showNotice(
                    'July earnings statement is ready to share or download.',
                  );
                  Navigator.pop(sheetContext);
                },
                child: Text(
                  statement ? 'Download Statement' : 'Open Statement',
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('captain-payout-close'),
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

class CaptainComplianceScreen extends StatelessWidget {
  const CaptainComplianceScreen({required this.session, super.key});

  final CaptainSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CaptainPageScaffold(
        session: session,
        title: 'Vehicle & Compliance',
        subtitle: 'Bike Captain · Rajasthan requirements',
        activeDock: 'none',
        returnRoute: '/app/captain',
        trailing: IconButton.outlined(
          key: const Key('captain-compliance-add'),
          tooltip: 'Add or update vehicle',
          onPressed: () {
            session.selectDocument('insurance');
            _verificationSheet(context, addVehicle: true);
          },
          icon: const Icon(Icons.add_rounded),
        ),
        body: ListView(
          key: const Key('captain-compliance-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CaptainCard(
              color: Color(0xFFF4F3FF),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: MoolColors.navy,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.two_wheeler_rounded),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Honda Shine · RJ19 GB 4421',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Passenger bike service · Jodhpur Central',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CaptainPill(label: 'ELIGIBLE'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CaptainCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ride readiness',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '92%',
                        style: TextStyle(
                          color: MoolColors.success,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MoolSpacing.xs),
                  LinearProgressIndicator(
                    value: .92,
                    minHeight: 7,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: MoolColors.success,
                    backgroundColor: Color(0xFFE4E5EF),
                  ),
                  SizedBox(height: MoolSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB05C00),
                      ),
                      SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Insurance expires in 18 days',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Renew before ride eligibility pauses.',
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
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const CaptainSectionTitle(
              title: 'Required documents',
              detail: 'Based on vehicle and service',
            ),
            const SizedBox(height: MoolSpacing.sm),
            ...reviewCaptainDocuments.map(
              (document) => Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                child: CaptainActionRow(
                  keyName: 'captain-document-${document.id}',
                  icon: document.needsAction
                      ? Icons.warning_amber_rounded
                      : Icons.verified_outlined,
                  title: document.name,
                  detail: document.detail,
                  meta: document.expiry,
                  action: document.needsAction ? 'Renew' : 'View',
                  color: document.needsAction
                      ? const Color(0xFFFFF6E8)
                      : Colors.white,
                  onTap: () {
                    session.selectDocument(document.id);
                    _verificationSheet(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verificationSheet(
    BuildContext context, {
    bool addVehicle = false,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('captain-verification-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addVehicle
                      ? 'Add or update vehicle'
                      : 'Verify ${session.selectedDocument.name}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  addVehicle
                      ? 'Vehicle type decides which records are needed.'
                      : '${session.selectedDocument.expiry} · ${session.selectedDocument.detail}',
                ),
                const SizedBox(height: MoolSpacing.md),
                const CaptainCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      _BusinessLine(label: 'Source', value: 'DigiLocker'),
                      _BusinessLine(
                        label: 'Alternative',
                        value: 'Upload document',
                      ),
                      _BusinessLine(
                        label: 'Identity check',
                        value: 'When required',
                      ),
                      _BusinessLine(
                        label: 'Confirmation',
                        value: 'Record + review',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const Text(
                  'Requirements can change by vehicle, use and location. An expired or suspended record can pause ride eligibility.',
                  style: TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
                CheckboxListTile(
                  key: const Key('captain-verification-consent'),
                  contentPadding: EdgeInsets.zero,
                  value: session.verificationConsent,
                  onChanged: (value) =>
                      session.acceptVerificationConsent(value ?? false),
                  title: const Text(
                    'I will provide this document or DigiLocker record',
                  ),
                ),
                if (session.errorMessage != null)
                  Text(
                    session.errorMessage!,
                    key: const Key('captain-verification-error'),
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: MoolSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('captain-verification-start'),
                    onPressed: session.busy
                        ? null
                        : session.startDocumentVerification,
                    child: Text(
                      session.verificationId == null
                          ? 'Continue Verification'
                          : 'Verification in Progress',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('captain-verification-close'),
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

class CaptainSupportWorkScreen extends StatelessWidget {
  const CaptainSupportWorkScreen({
    required this.session,
    this.initialTab = CaptainSupportTab.support,
    super.key,
  });

  final CaptainSession session;
  final CaptainSupportTab initialTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CaptainPageScaffold(
        session: session,
        title: 'Support & Opportunities',
        subtitle: 'Trip help, paid opportunities and vehicle care',
        activeDock: 'none',
        returnRoute: '/app/captain',
        trailing: IconButton.outlined(
          key: const Key('captain-support-new'),
          tooltip: 'Start support case',
          onPressed: () {
            session.selectSupport('trip');
            _supportSheet(context);
          },
          icon: const Icon(Icons.add_rounded),
        ),
        body: Column(
          key: const Key('captain-support-work-screen'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoolSpacing.md,
                MoolSpacing.xs,
                MoolSpacing.md,
                MoolSpacing.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: CaptainSupportTab.values
                      .map(
                        (tab) => Padding(
                          padding: const EdgeInsets.only(right: MoolSpacing.xs),
                          child: MoolSegment(
                            key: Key('captain-support-tab-${tab.name}'),
                            label: switch (tab) {
                              CaptainSupportTab.support => 'Support',
                              CaptainSupportTab.paidWork => 'Opportunities',
                              CaptainSupportTab.vehicle => 'Vehicle Help',
                            },
                            selected: session.supportTab == tab,
                            onPressed: () => session.setSupportTab(tab),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: switch (session.supportTab) {
                CaptainSupportTab.support => _SupportList(
                  onOpen: (id) {
                    session.selectSupport(id);
                    _supportSheet(context);
                  },
                ),
                CaptainSupportTab.paidWork => _PaidWorkList(
                  onOpen: (id) {
                    session.selectWork(id);
                    _workSheet(context);
                  },
                ),
                CaptainSupportTab.vehicle => _VehicleHelpList(
                  onOpen: (id) => _vehicleSheet(context, id),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

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
            MoolSpacing.xs,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('captain-support-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.selectedSupport.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(session.selectedSupport.detail),
                const SizedBox(height: MoolSpacing.md),
                const CaptainCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      _BusinessLine(
                        label: 'Identity',
                        value: 'Captain verified',
                      ),
                      _BusinessLine(label: 'Vehicle', value: 'RJ19 GB 4421'),
                      _BusinessLine(label: 'Trip', value: 'Attach if relevant'),
                      _BusinessLine(
                        label: 'Case updates',
                        value: 'Visible in app',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                TextFormField(
                  key: const Key('captain-support-message'),
                  initialValue: session.supportMessage,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Describe what happened',
                  ),
                  onChanged: session.setSupportMessage,
                ),
                if (session.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: MoolSpacing.xs),
                    child: Text(
                      session.errorMessage!,
                      key: const Key('captain-support-error'),
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('captain-support-create'),
                    onPressed: session.busy ? null : session.createSupportCase,
                    child: Text(
                      session.supportCaseId == null
                          ? 'Start Support Case'
                          : 'Case Open',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('captain-support-close'),
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

  Future<void> _workSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('captain-work-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.selectedWork.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${session.selectedWork.sponsor} · ${session.selectedWork.geography}',
                ),
                const SizedBox(height: MoolSpacing.md),
                CaptainCard(
                  color: const Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      _BusinessLine(
                        label: 'Payment',
                        value: '₹${session.selectedWork.payment}',
                      ),
                      _BusinessLine(
                        label: 'Paid when',
                        value: session.selectedWork.paymentRule,
                      ),
                      _BusinessLine(
                        label: 'Proof',
                        value: session.selectedWork.proof,
                      ),
                      _BusinessLine(
                        label: 'Availability',
                        value: session.selectedWork.capacity,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const Text(
                  'Delivery tasks require a separate Delivery Partner workspace. This application does not activate delivery work.',
                  style: TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
                CheckboxListTile(
                  key: const Key('captain-work-terms'),
                  contentPadding: EdgeInsets.zero,
                  value: session.workTermsAccepted,
                  onChanged: (value) => session.acceptWorkTerms(value ?? false),
                  title: const Text(
                    'I reviewed the task, location, payment and proof',
                  ),
                ),
                if (session.errorMessage != null)
                  Text(
                    session.errorMessage!,
                    key: const Key('captain-work-error'),
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: MoolSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('captain-work-apply'),
                    onPressed: session.busy ? null : session.applyForWork,
                    child: Text(
                      session.workApplicationId == null
                          ? 'Apply for Paid Work'
                          : 'Application Submitted',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('captain-work-close'),
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

  Future<void> _vehicleSheet(BuildContext context, String id) {
    final item = reviewCaptainVehicleHelp.firstWhere(
      (option) => option.id == id,
    );
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('captain-vehicle-help-sheet'),
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
              Text(item.detail),
              const SizedBox(height: MoolSpacing.sm),
              CaptainCard(
                color: const Color(0xFFF4F3FF),
                child: Text(
                  item.outcome,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('captain-vehicle-help-continue'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    if (id == 'insurance-renewal') {
                      context.go('/app/captain/compliance');
                    } else if (id == 'vehicle-bills') {
                      context.go('/app/pay');
                    } else {
                      session.showNotice(
                        'Nearby verified service options are ready to compare.',
                      );
                    }
                  },
                  child: Text(
                    id == 'insurance-renewal'
                        ? 'Open Insurance'
                        : id == 'vehicle-bills'
                        ? 'Open Pay'
                        : 'Compare Service',
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('captain-vehicle-help-close'),
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
}

class _EarningSummary extends StatelessWidget {
  const _EarningSummary({required this.tab});

  final CaptainEarningsTab tab;

  @override
  Widget build(BuildContext context) {
    final week = tab == CaptainEarningsTab.week;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CaptainMetric(
                label: 'TRIP EARNINGS',
                value: week ? '₹9,640' : '₹1,710',
                detail: week ? 'this week' : 'today',
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: CaptainMetric(
                label: 'INCENTIVES',
                value: week ? '₹680' : '₹120',
                detail: 'approved',
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: CaptainMetric(
                label: 'PLATFORM',
                value: week ? '−₹964' : '−₹170',
                detail: 'charges',
              ),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        const CaptainCard(child: _EarningsBars()),
      ],
    );
  }
}

class _PayoutSummary extends StatelessWidget {
  const _PayoutSummary({required this.session});

  final CaptainSession session;

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: CaptainMetric(
          label: 'AVAILABLE',
          value: '₹3,090',
          detail: 'ready',
        ),
      ),
      SizedBox(width: MoolSpacing.xs),
      Expanded(
        child: CaptainMetric(
          label: 'SCHEDULED',
          value: 'Tomorrow',
          detail: 'bank ••4421',
        ),
      ),
      SizedBox(width: MoolSpacing.xs),
      Expanded(
        child: CaptainMetric(
          label: 'ADJUSTMENT',
          value: '−₹420',
          detail: 'cash trips',
        ),
      ),
    ],
  );
}

class _EarningsBars extends StatelessWidget {
  const _EarningsBars();

  @override
  Widget build(BuildContext context) {
    const values = [.56, .82, .65, .91, .74, 1.0];
    const labels = ['5', '6', '7', '8', '9', '10'];
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < values.length; index += 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: values[index],
                        child: Container(
                          decoration: BoxDecoration(
                            color: index == values.length - 1
                                ? MoolColors.navy
                                : MoolColors.royal.withValues(alpha: .45),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${labels[index]} PM',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SupportList extends StatelessWidget {
  const _SupportList({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('captain-support-list'),
    padding: const EdgeInsets.fromLTRB(
      MoolSpacing.md,
      0,
      MoolSpacing.md,
      MoolSpacing.xl,
    ),
    children: reviewCaptainSupport
        .map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
            child: CaptainActionRow(
              keyName: 'captain-support-${option.id}',
              icon: option.urgent
                  ? Icons.sos_rounded
                  : Icons.support_agent_rounded,
              title: option.title,
              detail: option.detail,
              meta: option.outcome,
              action: option.urgent ? 'Get Help' : 'Start',
              color: option.urgent ? const Color(0xFFFFEDEC) : Colors.white,
              onTap: () => onOpen(option.id),
            ),
          ),
        )
        .toList(),
  );
}

class _PaidWorkList extends StatelessWidget {
  const _PaidWorkList({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('captain-paid-work-list'),
    padding: const EdgeInsets.fromLTRB(
      MoolSpacing.md,
      0,
      MoolSpacing.md,
      MoolSpacing.xl,
    ),
    children: [
      ...reviewCaptainPaidWork.map(
        (work) => Padding(
          padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
          child: CaptainCard(
            keyName: 'captain-work-${work.id}',
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
                            work.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${work.sponsor} · ${work.geography}',
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${work.payment}',
                      style: const TextStyle(
                        color: MoolColors.success,
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
                      child: _MiniFact(
                        label: 'PAID WHEN',
                        value: work.paymentRule,
                      ),
                    ),
                    Expanded(
                      child: _MiniFact(label: 'PROOF', value: work.proof),
                    ),
                    Expanded(
                      child: _MiniFact(label: 'OPEN', value: work.capacity),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: Key('captain-work-review-${work.id}'),
                    onPressed: () => onOpen(work.id),
                    child: const Text('Review & Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const CaptainCard(
        color: Color(0xFFFFF6E8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFB05C00)),
            SizedBox(width: MoolSpacing.sm),
            Expanded(
              child: Text(
                'Delivery work is separate. Activate a Delivery Partner workspace before receiving shop, food or parcel tasks.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _VehicleHelpList extends StatelessWidget {
  const _VehicleHelpList({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('captain-vehicle-help-list'),
    padding: const EdgeInsets.fromLTRB(
      MoolSpacing.md,
      0,
      MoolSpacing.md,
      MoolSpacing.xl,
    ),
    children: reviewCaptainVehicleHelp
        .map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
            child: CaptainActionRow(
              keyName: 'captain-vehicle-${option.id}',
              icon: Icons.build_outlined,
              title: option.title,
              detail: option.detail,
              meta: option.outcome,
              action: 'Review',
              onTap: () => onOpen(option.id),
            ),
          ),
        )
        .toList(),
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

class _BusinessLine extends StatelessWidget {
  const _BusinessLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: MoolColors.muted)),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}
