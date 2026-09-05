import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../widgets/work_widgets.dart';
import '../widgets/work_workspace_benefit_card.dart';
import '../work_models.dart';
import '../work_services.dart';
import '../work_session.dart';
import '../work_workspace_benefits.dart';

double _workViewBottomInset(BuildContext context) {
  final view = View.of(context);
  return view.viewPadding.bottom / view.devicePixelRatio;
}

class WorkChooseActivityScreen extends StatefulWidget {
  const WorkChooseActivityScreen({required this.session, super.key});

  final WorkSession session;

  @override
  State<WorkChooseActivityScreen> createState() =>
      _WorkChooseActivityScreenState();
}

class _WorkChooseActivityScreenState extends State<WorkChooseActivityScreen> {
  String? _expandedProfileId;
  String _workspaceQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.session.loadInitialWorkspaceState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final family = widget.session.selectedFamilyId;
        final profile = widget.session.selectedProfile;

        void collapseBenefits() {
          setState(() => _expandedProfileId = null);
        }

        void toggleBenefits(String profileId) {
          setState(() {
            _expandedProfileId = _expandedProfileId == profileId
                ? null
                : profileId;
          });
        }

        void chooseWorkspace(WorkProfileOption option) {
          widget.session.selectProfile(option.id);
          context.push('/app/work/workspace/requirements');
        }

        return WorkPageScaffold(
          session: widget.session,
          title: 'Grow with MoolSocial',
          subtitle: family == null
              ? 'Choose the Workspace that matches what you do'
              : widget.session.familyLabel(family),
          fallbackBackRoute: '/app/work/earn',
          showBack:
              _expandedProfileId != null ||
              family != null ||
              Navigator.of(context).canPop(),
          onBack: _expandedProfileId != null
              ? collapseBenefits
              : family == null
              ? null
              : widget.session.changeFamily,
          activeLocalAction: 'workspace',
          showHeaderChat: false,
          showTrailingAction: false,
          body: ListView(
            key: const Key('work-choose-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const _WorkspaceEntryHero(),
              if (widget.session.selectedOpportunity
                  case final opportunity?) ...[
                const SizedBox(height: MoolSpacing.sm),
                _WorkspaceOpportunityContext(opportunity: opportunity),
              ],
              if (widget.session.activeWorkspace case final workspace?) ...[
                const SizedBox(height: MoolSpacing.sm),
                _ExistingWorkspaceSummary(
                  session: widget.session,
                  workspace: workspace,
                ),
              ] else if (widget.session.reviewCaseId != null) ...[
                const SizedBox(height: MoolSpacing.sm),
                _WorkspaceApplicationSummary(session: widget.session),
              ],
              const SizedBox(height: MoolSpacing.lg),
              if (family == null) ...[
                TextField(
                  key: const Key('work-workspace-search'),
                  decoration: const InputDecoration(
                    hintText: 'Find your business or profession',
                    prefixIcon: Icon(Icons.search),
                    border: UnderlineInputBorder(),
                  ),
                  onChanged: (value) => setState(
                    () => _workspaceQuery = value.trim().toLowerCase(),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const WorkSectionTitle(
                  title: 'Choose how you want to grow',
                  detail:
                      'Select the Workspace that best represents your business, profession or service.',
                ),
                const SizedBox(height: MoolSpacing.md),
                for (final familyId in widget.session.familyIds)
                  if (widget.session
                      .profilesForFamily(familyId)
                      .any(
                        (option) => option.label.toLowerCase().contains(
                          _workspaceQuery,
                        ),
                      )) ...[
                    WorkSectionTitle(
                      title: widget.session.familyLabel(familyId),
                      detail: _workspaceGroupPresentation(familyId).examples,
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    for (final option
                        in widget.session
                            .profilesForFamily(familyId)
                            .where(
                              (option) => option.label.toLowerCase().contains(
                                _workspaceQuery,
                              ),
                            )) ...[
                      WorkWorkspaceBenefitCard(
                        option: option,
                        content: workWorkspaceBenefitFor(option.id),
                        expanded: _expandedProfileId == option.id,
                        onToggle: () => toggleBenefits(option.id),
                        onChoose: () => chooseWorkspace(option),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                    ],
                    const SizedBox(height: MoolSpacing.xs),
                  ],
                OutlinedButton.icon(
                  key: const Key('work-profile-not-shown'),
                  onPressed: () => _showUnsupportedRequest(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text(
                    'Can’t find your Workspace? Tell us what you do',
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: WorkSectionTitle(
                        title:
                            'Choose a ${widget.session.familyLabel(family)} Workspace',
                        detail: profile == null
                            ? 'Select the Workspace that best matches what you do.'
                            : 'See how this Workspace can help you grow.',
                      ),
                    ),
                    TextButton(
                      key: const Key('work-change-family'),
                      onPressed: widget.session.changeFamily,
                      child: const Text('Browse Workspaces'),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                for (final option in widget.session.profilesForFamily(
                  family,
                )) ...[
                  WorkWorkspaceBenefitCard(
                    option: option,
                    content: workWorkspaceBenefitFor(option.id),
                    expanded: _expandedProfileId == option.id,
                    onToggle: () => toggleBenefits(option.id),
                    onChoose: () => chooseWorkspace(option),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUnsupportedRequest(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _WorkspaceRequestSheet(session: widget.session),
    );
  }
}

class _WorkspaceRequestSheet extends StatefulWidget {
  const _WorkspaceRequestSheet({required this.session});

  final WorkSession session;

  @override
  State<_WorkspaceRequestSheet> createState() => _WorkspaceRequestSheetState();
}

class _WorkspaceRequestSheetState extends State<_WorkspaceRequestSheet> {
  static const _categories = <String>[
    'Products & Trade',
    'Food Business',
    'Health & Medicine',
    'Services & Salon',
    'Travel Partners',
    'Delivery & Logistics',
    'Create & Work',
    'Other',
  ];

  final TextEditingController _workspace = TextEditingController();
  final TextEditingController _area = TextEditingController();
  final TextEditingController _otherActivity = TextEditingController();
  final FocusNode _workspaceFocus = FocusNode();
  final FocusNode _areaFocus = FocusNode();
  final FocusNode _otherActivityFocus = FocusNode();
  String _category = '';
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _workspace.text = widget.session.unsupportedWorkspace;
    _area.text = widget.session.unsupportedArea;
    _otherActivity.text = widget.session.unsupportedOtherActivity;
    _category = widget.session.unsupportedFamily;
  }

  @override
  void dispose() {
    if (!widget.session.unsupportedRequestSent) {
      widget.session.unsupportedWorkspace = _workspace.text;
      widget.session.unsupportedArea = _area.text;
      widget.session.unsupportedOtherActivity = _otherActivity.text;
      widget.session.unsupportedFamily = _category;
    }
    _workspace.dispose();
    _area.dispose();
    _otherActivity.dispose();
    _workspaceFocus.dispose();
    _areaFocus.dispose();
    _otherActivityFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final validationError = _workspace.text.trim().length < 3
        ? 'Enter your business, profession or service.'
        : _category.isEmpty
        ? 'Choose the closest category.'
        : _category == 'Other' && _otherActivity.text.trim().length < 3
        ? 'Enter the activity you want to offer.'
        : _area.text.trim().length < 3
        ? 'Enter your city or service area.'
        : null;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final sent = await widget.session.sendUnsupportedRequest(
      workspace: _workspace.text,
      family: _category,
      area: _area.text,
      otherActivity: _otherActivity.text,
    );
    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _error = widget.session.errorMessage;
    });
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final reportedBottomInset = _workViewBottomInset(context);
    final gestureSafeBottom = reportedBottomInset < 24
        ? 24.0
        : reportedBottomInset;
    return SafeArea(
      top: true,
      minimum: EdgeInsets.only(bottom: gestureSafeBottom + MoolSpacing.xs),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  (MediaQuery.sizeOf(context).height -
                          keyboardInset -
                          MediaQuery.paddingOf(context).top -
                          24)
                      .clamp(0, 500),
            ),
            child: Material(
              key: const Key('work-profile-request-sheet'),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(MoolRadii.sheet),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MoolSpacing.md,
                      MoolSpacing.xs,
                      MoolSpacing.xs,
                      MoolSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8DAE8),
                            borderRadius: BorderRadius.circular(
                              MoolRadii.capsule,
                            ),
                          ),
                        ),
                        const SizedBox(height: MoolSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tell us what you do',
                                    style: TextStyle(
                                      color: MoolColors.ink,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'Share your business, profession or service. MoolSocial will guide you to the right Workspace.',
                                    style: TextStyle(
                                      color: MoolColors.muted,
                                      fontSize: 11,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: const Key('work-profile-request-close'),
                              tooltip: 'Close',
                              onPressed: _close,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_error case final error?)
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        key: const Key('work-profile-request-error'),
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(
                          MoolSpacing.md,
                          0,
                          MoolSpacing.md,
                          MoolSpacing.xs,
                        ),
                        padding: const EdgeInsets.all(MoolSpacing.xs),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9E7),
                          borderRadius: BorderRadius.circular(
                            MoolRadii.control,
                          ),
                        ),
                        child: Text(
                          error,
                          style: const TextStyle(
                            color: Color(0xFF9D1C15),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: ListView(
                      key: const Key('work-profile-request-scroll'),
                      shrinkWrap: true,
                      primary: false,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        MoolSpacing.md,
                        MoolSpacing.xs,
                        MoolSpacing.md,
                        MoolSpacing.md,
                      ),
                      children: [
                        TextField(
                          key: const Key('work-request-profile-name'),
                          controller: _workspace,
                          focusNode: _workspaceFocus,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          scrollPadding: const EdgeInsets.only(bottom: 120),
                          onSubmitted: (_) => _areaFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Business, profession or service',
                            hintText: 'For example, furniture repair',
                          ),
                        ),
                        const SizedBox(height: MoolSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: const Key('work-request-family'),
                          initialValue: _category.isEmpty ? null : _category,
                          decoration: const InputDecoration(
                            labelText: 'Closest category',
                          ),
                          items: _categories
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(growable: false),
                          onTap: () =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          onChanged: _submitting
                              ? null
                              : (value) =>
                                    setState(() => _category = value ?? ''),
                        ),
                        if (_category == 'Other') ...[
                          const SizedBox(height: MoolSpacing.sm),
                          TextField(
                            key: const Key('work-request-other-activity'),
                            controller: _otherActivity,
                            focusNode: _otherActivityFocus,
                            enabled: !_submitting,
                            textInputAction: TextInputAction.next,
                            scrollPadding: const EdgeInsets.only(bottom: 120),
                            onSubmitted: (_) => _areaFocus.requestFocus(),
                            decoration: const InputDecoration(
                              labelText: 'Describe your activity',
                              hintText: 'For example, handloom repair',
                            ),
                          ),
                        ],
                        const SizedBox(height: MoolSpacing.sm),
                        TextField(
                          key: const Key('work-request-area'),
                          controller: _area,
                          focusNode: _areaFocus,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.done,
                          scrollPadding: const EdgeInsets.only(bottom: 120),
                          decoration: const InputDecoration(
                            labelText: 'City or service area',
                            hintText: 'For example, Jodhpur',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    key: const Key('work-profile-request-actions'),
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0x22000050),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MoolSpacing.md,
                        MoolSpacing.sm,
                        MoolSpacing.md,
                        MoolSpacing.xs + 24,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('work-profile-request-back'),
                              onPressed: _submitting ? null : _close,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: FilledButton(
                              key: const Key('work-send-profile-request'),
                              onPressed: _submitting ? null : _submit,
                              child: Text(
                                _submitting ? 'Sending…' : 'Send request',
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

class WorkDocumentRequirementsScreen extends StatelessWidget {
  const WorkDocumentRequirementsScreen({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final profile = session.selectedProfile;

    void returnToRoles() {
      session.clearMessages();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/app/work/my-work');
      }
    }

    if (profile == null) {
      return WorkPageScaffold(
        session: session,
        title: 'Choose a Workspace first',
        subtitle: 'Return to Workspace choices to continue',
        fallbackBackRoute: '/app/work/my-work',
        activeLocalAction: 'workspace',
        showHeaderChat: false,
        showTrailingAction: false,
        onBack: returnToRoles,
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            WorkEmptyState(
              title: 'No Workspace selected',
              detail: 'Choose the Workspace that best matches what you do.',
              actionLabel: 'Browse Workspaces',
              onAction: returnToRoles,
            ),
          ],
        ),
      );
    }

    return WorkPageScaffold(
      session: session,
      title: 'Documents to keep ready',
      subtitle: profile.label,
      fallbackBackRoute: '/app/work/my-work',
      activeLocalAction: 'workspace',
      showHeaderChat: false,
      showTrailingAction: false,
      onBack: returnToRoles,
      bottomAction: _DocumentsReadyAction(
        onPressed: () => context.push('/app/work/workspace/contact'),
      ),
      body: ListView(
        key: const Key('work-requirements-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.sm,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const Padding(
            key: Key('work-requirements-role-summary'),
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Keep clear copies ready. You can submit your application before adding documents; MoolSocial will confirm what is needed.',
              style: TextStyle(
                color: MoolColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          for (
            var index = 0;
            index < profile.verificationDocuments.length;
            index += 1
          ) ...[
            _DocumentRequirementCard(
              index: index,
              item: profile.verificationDocuments[index],
            ),
            const SizedBox(height: MoolSpacing.sm),
          ],
          _GstComplianceNotice(profile: profile),
        ],
      ),
    );
  }
}

class _DocumentRequirementCard extends StatelessWidget {
  const _DocumentRequirementCard({required this.index, required this.item});
  final int index;
  final WorkDocumentChecklistItem item;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('work-requirement-$index'),
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE4E7F0))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, color: MoolColors.navy, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.detail,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              if (item.importance == WorkDocumentImportance.ifApplicable)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'When applicable',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GstComplianceNotice extends StatelessWidget {
  const _GstComplianceNotice({required this.profile});

  final WorkProfileOption profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-gst-compliance-guidance'),
      padding: const EdgeInsets.all(MoolSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FD),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: const Color(0xFFE4E7F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_rounded, color: MoolColors.navy),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GST registration requirement',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _gstComplianceText(profile.gstMatchCategory),
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Aggregate turnover is calculated across India for the same PAN. Keep your GST certificate ready if registered. If you are unsure whether registration applies, confirm the current Central and State/UT rules with a GST professional.',
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10,
                    height: 1.32,
                    fontWeight: FontWeight.w600,
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

String _gstComplianceText(WorkGstMatchCategory category) => switch (category) {
  WorkGstMatchCategory.retailGoodsSupplier ||
  WorkGstMatchCategory.wholesaleDistributor ||
  WorkGstMatchCategory.manufacturerSupplier ||
  WorkGstMatchCategory.pharmacySupplier =>
    'For businesses supplying goods, GST registration depends on annual PAN-wide aggregate turnover, the State or Union Territory of supply, the nature of the supplies and any compulsory-registration rule.',
  WorkGstMatchCategory.healthcareProvider =>
    'Qualifying health-care services may be GST-exempt. Taxable or mixed supplies can change the requirement under the current Central and State/UT GST rules.',
  WorkGstMatchCategory.bikeTravelProvider ||
  WorkGstMatchCategory.autoTravelProvider ||
  WorkGstMatchCategory.cabTravelProvider ||
  WorkGstMatchCategory.busTravelProvider ||
  WorkGstMatchCategory.quickDeliveryBiker ||
  WorkGstMatchCategory.wholesaleFleetDelivery ||
  WorkGstMatchCategory.bulkDeliveryFleet =>
    'Transport and delivery GST treatment depends on the exact service, payment arrangement, place of supply, reverse-charge treatment and any compulsory-registration rule.',
  _ =>
    'For service businesses, GST registration depends on annual PAN-wide aggregate turnover, the State or Union Territory of supply, the nature of the service and any compulsory-registration rule.',
};

class _DocumentsReadyAction extends StatelessWidget {
  const _DocumentsReadyAction({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton(
      key: const Key('work-requirements-ready'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: MoolColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Continue setup'),
    ),
  );
}

class WorkWorkspaceContactScreen extends StatefulWidget {
  const WorkWorkspaceContactScreen({required this.session, super.key});

  final WorkSession session;

  @override
  State<WorkWorkspaceContactScreen> createState() =>
      _WorkWorkspaceContactScreenState();
}

class _WorkWorkspaceContactScreenState
    extends State<WorkWorkspaceContactScreen> {
  late final TextEditingController _alternate = TextEditingController(
    text: widget.session.alternateMobile,
  );
  final TextEditingController _otp = TextEditingController();

  @override
  void dispose() {
    _alternate.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final profile = widget.session.selectedProfile;
        return WorkPageScaffold(
          session: widget.session,
          title: 'Set up your Workspace',
          subtitle: profile?.label ?? 'Choose a Workspace first',
          fallbackBackRoute: '/app/work/workspace/requirements',
          activeLocalAction: 'workspace',
          showHeaderChat: false,
          showTrailingAction: false,
          bottomAction: profile == null
              ? null
              : WorkPrimaryButton(
                  keyName: 'work-contact-continue',
                  label: 'Continue to Workspace details',
                  onPressed: () {
                    if (widget.session.continueToProof()) {
                      context.push('/app/work/workspace/proof');
                    }
                  },
                ),
          body: ListView(
            key: const Key('work-contact-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: profile == null
                ? [
                    WorkEmptyState(
                      title: 'No Workspace selected',
                      detail:
                          'Choose the Workspace that best matches what you do.',
                      actionLabel: 'Browse Workspaces',
                      onAction: () {
                        widget.session.changeFamily();
                        context.go('/app/work/my-work');
                      },
                    ),
                  ]
                : [
                    _SelectedProfileCard(option: profile),
                    const SizedBox(height: MoolSpacing.md),
                    const WorkSectionTitle(
                      title: 'Contact for this Workspace',
                      detail:
                          'We’ll use your signed-in number unless you add another work number.',
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const WorkCard(
                      child: _ContactRow(
                        label: 'Signed-in number',
                        value: '+91 98••• ••321',
                        state: 'Account',
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    TextField(
                      key: const Key('work-alternate-mobile'),
                      controller: _alternate,
                      enabled: !widget.session.alternateVerified,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Alternate work number · optional',
                        prefixText: '+91 ',
                        suffixIcon: widget.session.alternateVerified
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: MoolColors.success,
                              )
                            : null,
                      ),
                    ),
                    if (!widget.session.alternateOtpSent)
                      TextButton(
                        key: const Key('work-send-alternate-otp'),
                        onPressed: widget.session.busy
                            ? null
                            : () => widget.session.sendAlternateOtp(
                                _alternate.text,
                              ),
                        child: const Text('Send OTP'),
                      )
                    else if (!widget.session.alternateVerified) ...[
                      const SizedBox(height: MoolSpacing.xs),
                      TextField(
                        key: const Key('work-alternate-otp'),
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit OTP',
                          counterText: '',
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('work-change-alternate'),
                              onPressed: () {
                                widget.session.removeAlternateMobile();
                                _alternate.clear();
                                _otp.clear();
                              },
                              child: const Text('Change number'),
                            ),
                          ),
                          const SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: FilledButton(
                              key: const Key('work-verify-alternate'),
                              onPressed: () =>
                                  widget.session.verifyAlternateOtp(_otp.text),
                              child: const Text('Confirm OTP'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
          ),
        );
      },
    );
  }
}

class _WorkspaceEntryHero extends StatelessWidget {
  const _WorkspaceEntryHero();
  @override
  Widget build(BuildContext context) {
    const steps = [
      'Choose Workspace',
      'Upload documents',
      'MoolSocial review',
      'Add your products',
      'Go live',
    ];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MoolMotion.accessible(context, MoolMotion.standard),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Container(
        key: const Key('workspace-chooser-hero'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MoolColors.navy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your business. More customers.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Reach more customers. Grow repeat sales.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < steps.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}  ${steps[i]}',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceOpportunityContext extends StatelessWidget {
  const _WorkspaceOpportunityContext({required this.opportunity});

  final WorkOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('workspace-opportunity-context'),
      padding: const EdgeInsets.all(MoolSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: const Color(0xFFFFC37A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: MoolColors.orange),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workspace required for your application',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  opportunity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
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

class _ExistingWorkspaceSummary extends StatelessWidget {
  const _ExistingWorkspaceSummary({
    required this.session,
    required this.workspace,
  });

  final WorkSession session;
  final WorkWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final route = session.hasVerifiedWorkspace
        ? '/app/work/workspace/dashboard'
        : '/app/work/workspace/proof';
    return WorkCard(
      keyName: 'workspace-existing-summary',
      color: const Color(0xFFEAF7E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkPill(
            label: 'Active Workspace',
            color: MoolColors.success,
            icon: Icons.verified_rounded,
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            workspace.name,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${workspace.profileLabel} · ${workspace.area}',
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (session.otherWorkspaces.isNotEmpty)
            Column(
              key: const Key('workspace-other-list'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: MoolSpacing.lg),
                const Text(
                  'Other Workspaces',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                for (final other in session.otherWorkspaces)
                  Padding(
                    key: Key('workspace-other-${other.id}'),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.dashboard_outlined,
                          color: MoolColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: Text(
                            '${other.name} · ${other.area}',
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: MoolSpacing.sm),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: [
              OutlinedButton.icon(
                key: const Key('workspace-open-active'),
                onPressed: () => context.push(route),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Workspace'),
              ),
              TextButton.icon(
                key: const Key('workspace-settlement'),
                onPressed: () =>
                    _showSettlementSummary(context, workspace.name),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Settlements'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceApplicationSummary extends StatelessWidget {
  const _WorkspaceApplicationSummary({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final status = session.remoteReviewStatus;
    final rejected = status == WorkRemoteReviewStatus.rejected;
    final suspended = status == WorkRemoteReviewStatus.suspended;
    final clarification =
        status == WorkRemoteReviewStatus.pending &&
        session.reviewReason?.trim().isNotEmpty == true;
    final accent = rejected || suspended
        ? const Color(0xFFB42318)
        : MoolColors.orange;
    final title = rejected
        ? 'Workspace changes required'
        : suspended
        ? 'Workspace unavailable'
        : clarification
        ? 'Clarification requested'
        : 'Workspace review in progress';
    final detail = session.reviewReason?.trim().isNotEmpty == true
        ? session.reviewReason!.trim()
        : session.reviewCaseId ?? 'Submitted for review';
    return WorkCard(
      keyName: 'workspace-application-summary',
      color: accent.withValues(alpha: .09),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: accent,
            child: Icon(
              rejected
                  ? Icons.edit_note_rounded
                  : suspended
                  ? Icons.pause_circle_outline_rounded
                  : clarification
                  ? Icons.mark_unread_chat_alt_outlined
                  : Icons.schedule_rounded,
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('workspace-check-review'),
            onPressed: () => context.push('/app/work/workspace/proof'),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showSettlementSummary(
  BuildContext context,
  String workspaceName,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        0,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        key: const Key('my-work-settlement-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Settlement overview',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          WorkCard(
            color: const Color(0xFFF0FAF3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspaceName,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                const Text(
                  'No payout is due now',
                  style: TextStyle(
                    color: MoolColors.success,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                const Text(
                  'Completed orders, refunds and service fees will appear after their payment records are verified.',
                  style: TextStyle(
                    color: MoolColors.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton(
            key: const Key('my-work-settlement-open-workspace'),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              context.push('/app/retailer/home');
            },
            child: const Text('Open Workspace'),
          ),
          TextButton(
            key: const Key('my-work-settlement-close'),
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}

class _WorkspaceGroupPresentation {
  const _WorkspaceGroupPresentation({
    required this.accent,
    required this.tint,
    required this.examples,
  });

  final Color accent;
  final Color tint;
  final String examples;
}

_WorkspaceGroupPresentation _workspaceGroupPresentation(String familyId) =>
    switch (familyId) {
      'products-trade' => const _WorkspaceGroupPresentation(
        accent: Color(0xFF0047AB),
        tint: Color(0xFFEAF2FF),
        examples: 'Retailer · Wholesaler · Manufacturer',
      ),
      'food-business' => const _WorkspaceGroupPresentation(
        accent: Color(0xFFA65A00),
        tint: Color(0xFFFFF4E5),
        examples: 'Restaurant · Café · Cloud kitchen',
      ),
      'health' => const _WorkspaceGroupPresentation(
        accent: Color(0xFF007A4D),
        tint: Color(0xFFE8F7F0),
        examples: 'Doctor · Clinic · Pharmacy',
      ),
      'services' => const _WorkspaceGroupPresentation(
        accent: Color(0xFF9C1C6B),
        tint: Color(0xFFFFEDF7),
        examples: 'Salon · Beauty · Wellness',
      ),
      'travel' => const _WorkspaceGroupPresentation(
        accent: Color(0xFF006D77),
        tint: Color(0xFFE8F7F8),
        examples: 'Bike · Auto · Cab · Bus',
      ),
      'delivery' => const _WorkspaceGroupPresentation(
        accent: Color(0xFFB54708),
        tint: Color(0xFFFFF1E7),
        examples: 'Quick delivery · Wholesale fleet · Bulk fleet',
      ),
      _ => const _WorkspaceGroupPresentation(
        accent: Color(0xFF5B21B6),
        tint: Color(0xFFF2EDFF),
        examples: 'Creator · Freelancer · Job seeker',
      ),
    };

class _SelectedProfileCard extends StatelessWidget {
  const _SelectedProfileCard({required this.option});

  final WorkProfileOption option;

  @override
  Widget build(BuildContext context) {
    final presentation = _workspaceGroupPresentation(option.familyId);
    return WorkCard(
      keyName: 'work-profile-${option.id}',
      color: presentation.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: presentation.accent,
                foregroundColor: Colors.white,
                child: Icon(option.icon),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Text(
                  option.label,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: MoolColors.success),
            ],
          ),
          const Divider(height: MoolSpacing.lg),
          _PreviewRow(label: 'Reach customers', value: option.sellSide),
          _PreviewRow(label: 'Source smarter', value: option.buySide),
          _PreviewRow(label: 'Run your Workspace', value: option.tools),
          const SizedBox(height: MoolSpacing.xs),
          _BusinessIdentityNotice(profile: option),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Next, add the documents for this Workspace. Verification begins after you submit them.',
            style: TextStyle(
              color: MoolColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessIdentityNotice extends StatelessWidget {
  const _BusinessIdentityNotice({required this.profile});

  final WorkProfileOption profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('workspace-business-identity-notice'),
      padding: const EdgeInsets.all(MoolSpacing.xs),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7E8),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: const Color(0xFFB9DDB5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: MoolColors.success,
            size: 19,
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GST registration check',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Add a GST certificate when registration applies to your ${profile.label} Workspace. Applicability follows the current Central and State/UT GST rules.',
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10,
                    height: 1.32,
                    fontWeight: FontWeight.w600,
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

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
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
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.label,
    required this.value,
    required this.state,
  });

  final String label;
  final String value;
  final String state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        WorkPill(label: state),
      ],
    );
  }
}

class WorkProfileProofScreen extends StatefulWidget {
  const WorkProfileProofScreen({required this.session, super.key});

  final WorkSession session;

  @override
  State<WorkProfileProofScreen> createState() => _WorkProfileProofScreenState();
}

class _WorkProfileProofScreenState extends State<WorkProfileProofScreen>
    with WidgetsBindingObserver {
  final ScrollController _scroll = ScrollController();
  Timer? _reviewTimer;
  bool _redirectQueued = false;
  bool _appActive = true;
  int _reviewPolls = 0;
  int _step = 0;
  bool _correctionMode = false;
  bool _reviewEditMode = false;
  String? _correctionInstruction;
  late final TextEditingController _name = TextEditingController(
    text: widget.session.workName,
  );
  late final TextEditingController _area = TextEditingController(
    text: widget.session.workArea,
  );
  late final TextEditingController _activity = TextEditingController(
    text: widget.session.primaryActivity,
  );

  @override
  void initState() {
    super.initState();
    if (widget.session.reviewCaseId != null) _step = 3;
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_onReviewChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshReview();
    });
    _reviewTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshReview(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reviewTimer?.cancel();
    widget.session.removeListener(_onReviewChanged);
    _scroll.dispose();
    _name.dispose();
    _area.dispose();
    _activity.dispose();
    super.dispose();
  }

  void _saveFields() {
    widget.session.saveDetails(
      name: _name.text,
      area: _area.text,
      activity: _activity.text,
    );
  }

  void _goBack() {
    if (_step == 0) _saveFields();
    FocusManager.instance.primaryFocus?.unfocus();
    _resetScroll();
    if (_step >= 3) {
      context.go(
        widget.session.hasVerifiedWorkspace
            ? '/app/work/workspace/dashboard'
            : '/app/work/workspace/choose',
      );
      return;
    }
    if (_reviewEditMode && (_step == 0 || _step == 1)) {
      setState(() {
        _step = 2;
        _reviewEditMode = false;
      });
      return;
    }
    if (_correctionMode && (_step == 0 || _step == 1)) {
      if (widget.session.reviewCaseId != null) {
        setState(() {
          _step = 3;
          _correctionMode = false;
        });
      } else {
        context.go('/app/work/workspace/choose');
      }
      return;
    }
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/work/workspace/contact');
    }
  }

  void _beginCorrection(int step) {
    final instruction = widget.session.reviewReason?.trim();
    if (!widget.session.beginReviewCorrection()) return;
    setState(() {
      _step = step;
      _correctionMode = true;
      _correctionInstruction = instruction?.isEmpty == true
          ? null
          : instruction;
    });
  }

  void _resetScroll() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _refreshReview() {
    if (!mounted ||
        !_appActive ||
        _step != 3 ||
        widget.session.busy ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    if (_reviewPolls >= 20) {
      _reviewTimer?.cancel();
      return;
    }
    _onReviewChanged();
    final status = widget.session.remoteReviewStatus;
    if (!_redirectQueued &&
        widget.session.reviewCaseId != null &&
        status != WorkRemoteReviewStatus.rejected &&
        status != WorkRemoteReviewStatus.suspended) {
      _reviewPolls += 1;
      unawaited(widget.session.checkReview());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      _reviewPolls = 0;
      if (_reviewTimer?.isActive != true) {
        _reviewTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _refreshReview(),
        );
      }
      _refreshReview();
    }
  }

  void _onReviewChanged() {
    if (!mounted ||
        _step != 3 ||
        _redirectQueued ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final session = widget.session;
    if ((session.remoteReviewStatus == WorkRemoteReviewStatus.approved ||
            session.remoteReviewStatus == WorkRemoteReviewStatus.live) &&
        session.hasVerifiedWorkspace &&
        session.activeWorkspace?.id == session.workspaceId) {
      _redirectQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          context.go('/app/work/workspace/dashboard');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => WorkPageScaffold(
        session: widget.session,
        title: 'Complete your Workspace',
        subtitle: widget.session.selectedProfile?.label ?? 'Workspace details',
        fallbackBackRoute: '/app/work/workspace/contact',
        activeLocalAction: 'workspace',
        showHeaderChat: false,
        showTrailingAction: false,
        onBack: _goBack,
        bottomAction: switch (_step) {
          0 => WorkPrimaryButton(
            keyName: 'work-details-continue',
            label: _reviewEditMode
                ? 'Save and return to review'
                : 'Continue to documents',
            onPressed: () {
              _saveFields();
              if (widget.session.validateDetails()) {
                _resetScroll();
                setState(() {
                  _step = _reviewEditMode ? 2 : 1;
                  _reviewEditMode = false;
                });
              }
            },
          ),
          1 => WorkPrimaryButton(
            keyName: 'work-proof-review',
            label: _reviewEditMode
                ? 'Save and return to review'
                : 'Review your information',
            onPressed: () {
              widget.session.clearMessages();
              _resetScroll();
              setState(() {
                _step = 2;
                _reviewEditMode = false;
              });
            },
          ),
          2 => WorkPrimaryButton(
            keyName: 'work-submit-profile',
            label: widget.session.reviewCorrectionDraft
                ? 'Send corrections for review'
                : _correctionMode
                ? 'Resubmit for review'
                : 'Submit for review',
            busy: widget.session.busy,
            onPressed: () async {
              final submitted = await widget.session.submitProfile();
              if (submitted && mounted) {
                _resetScroll();
                setState(() {
                  _step = 3;
                  _correctionMode = false;
                  _correctionInstruction = null;
                });
                _onReviewChanged();
              }
            },
            icon: Icons.send_rounded,
          ),
          _ => _InlineReviewAction(
            session: widget.session,
            onUpdateDetails: () => _beginCorrection(0),
          ),
        },
        body: ListView(
          key: const Key('work-proof-screen'),
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.sm,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            _ProgressHeader(step: _step),
            const SizedBox(height: MoolSpacing.md),
            if (_correctionMode && _correctionInstruction != null) ...[
              _CorrectionInstructionCard(instruction: _correctionInstruction!),
              const SizedBox(height: MoolSpacing.md),
            ],
            if (_step == 0) ...[
              const WorkSectionTitle(
                title: 'Business details',
                detail: 'Information needed to verify this Workspace',
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('work-name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _saveFields(),
                decoration: const InputDecoration(
                  labelText: 'Business name (as per PAN card)',
                  helperText:
                      'Enter the name shown on the PAN used for this business.',
                  helperMaxLines: 2,
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('work-area'),
                controller: _area,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _saveFields(),
                decoration: const InputDecoration(
                  labelText: 'Operating city or PIN code',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('work-activity'),
                controller: _activity,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _saveFields(),
                decoration: const InputDecoration(
                  labelText: 'Primary activity',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              DropdownButtonFormField<String>(
                key: const Key('work-business-relationship'),
                initialValue: widget.session.businessRelationship.isEmpty
                    ? null
                    : widget.session.businessRelationship,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Your connection to this business',
                  border: UnderlineInputBorder(),
                ),
                items:
                    const [
                          'Owner',
                          'Partner or director',
                          'Authorized representative',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) =>
                    widget.session.saveBusinessRelationship(value ?? ''),
              ),
            ] else if (_step == 1) ...[
              const WorkSectionTitle(
                title: 'Documents',
                detail: 'Add now or continue and provide them during review',
              ),
              const SizedBox(height: MoolSpacing.sm),
              const WorkCard(
                color: Color(0xFFEDEEFF),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: MoolColors.navy),
                    SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Text(
                        'Add the documents you have. PDF, JPG, JPEG, PNG or WebP · up to 10 MB each. MoolSocial will review what is needed for approval.',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final proof
                  in widget.session.selectedWorkspaceDocuments) ...[
                _ProofCard(
                  proof: proof,
                  added: widget.session.addedProofs.containsKey(proof.id),
                  file: widget.session.pickedProofs[proof.id],
                  onAdd: () => _showProofSource(context, proof),
                  onView: () => _showDocument(context, proof),
                  onRemove: () => widget.session.removeProof(proof.id),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
            ] else if (_step == 2) ...[
              _ReviewStepMotion(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const WorkSectionTitle(
                      title: 'Review and submit',
                      detail: 'Check your Workspace details and documents',
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    WorkCard(
                      child: Column(
                        children: [
                          _ReviewRow(
                            label: 'Workspace',
                            value:
                                widget.session.selectedProfile?.label ??
                                'Not selected',
                          ),
                          _ReviewRow(
                            label: 'Business name',
                            value: widget.session.workName,
                          ),
                          _ReviewRow(
                            label: 'Your name',
                            value: widget.session.authorizedPersonName,
                          ),
                          _ReviewRow(
                            label: 'Contact',
                            value: widget.session.primaryMobile,
                          ),
                          _ReviewRow(
                            label: 'Email',
                            value: widget.session.contactEmail,
                          ),
                          if (widget.session.alternateMobile.isNotEmpty)
                            _ReviewRow(
                              label: 'Alternate',
                              value: widget.session.alternateMobile,
                            ),
                          if (widget.session.businessRelationship.isNotEmpty)
                            _ReviewRow(
                              label: 'Connection',
                              value: widget.session.businessRelationship,
                            ),
                          _ReviewRow(
                            label: 'Area',
                            value: widget.session.workArea,
                          ),
                          _ReviewRow(
                            label: 'Activity',
                            value: widget.session.primaryActivity,
                          ),
                          _ReviewRow(
                            label: 'Documents',
                            value: '${widget.session.addedProofs.length} added',
                          ),
                          for (final proof
                              in widget.session.selectedWorkspaceDocuments)
                            if (widget.session.addedProofs.containsKey(
                              proof.id,
                            ))
                              _ReviewRow(
                                label: proof.label,
                                value:
                                    widget
                                        .session
                                        .pickedProofs[proof.id]
                                        ?.fileName ??
                                    'Document attached',
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Wrap(
                      key: const Key('work-review-corrections'),
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          key: const Key('work-review-edit-details'),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit details'),
                          onPressed: () {
                            widget.session.setDeclaration(false);
                            _resetScroll();
                            setState(() {
                              _step = 0;
                              _reviewEditMode = true;
                            });
                          },
                        ),
                        TextButton.icon(
                          key: const Key('work-review-edit-documents'),
                          icon: const Icon(
                            Icons.upload_file_outlined,
                            size: 18,
                          ),
                          label: const Text('Edit documents'),
                          onPressed: () {
                            widget.session.setDeclaration(false);
                            _resetScroll();
                            setState(() {
                              _step = 1;
                              _reviewEditMode = true;
                            });
                          },
                        ),
                        TextButton.icon(
                          key: const Key('work-review-edit-contact'),
                          icon: const Icon(Icons.person_outline, size: 18),
                          label: const Text('Edit contact'),
                          onPressed: () {
                            widget.session.setDeclaration(false);
                            context.push(
                              '/app/work/workspace/contact?return=review',
                            );
                          },
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      key: const Key('work-declaration'),
                      value: widget.session.declarationAccepted,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'These details are correct and I am authorized to provide them.',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      onChanged: (value) =>
                          widget.session.setDeclaration(value ?? false),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _InlineWorkspaceReviewStatus(
                session: widget.session,
                onAddDocuments: () => _beginCorrection(1),
                onUpdateDetails: () => _beginCorrection(0),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDocument(BuildContext context, WorkProofRequirement proof) {
    final file = widget.session.pickedProofs[proof.id];
    final format = file?.contentType == 'application/pdf' ? 'PDF' : 'Image';
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  proof.label,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(file?.fileName ?? 'Document attached'),
                if (file != null) ...[
                  Text(
                    '$format · ${(file.bytes.length / 1024).ceil()} KB',
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (file.contentType.startsWith('image/'))
                    Image.memory(
                      file.bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        'Preview unavailable. You can choose a replacement.',
                      ),
                    )
                  else
                    const Text(
                      'PDF attached. You can check the original file on your device or choose a replacement.',
                    ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showProofSource(context, proof);
                      },
                      child: const Text('Replace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showProofSource(
    BuildContext context,
    WorkProofRequirement proof,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _ProofSourceSheet(session: widget.session, proof: proof),
    );
  }
}

class _ProofSourceSheet extends StatefulWidget {
  const _ProofSourceSheet({required this.session, required this.proof});

  final WorkSession session;
  final WorkProofRequirement proof;

  @override
  State<_ProofSourceSheet> createState() => _ProofSourceSheetState();
}

class _ProofSourceSheetState extends State<_ProofSourceSheet> {
  String? _busySource;

  Future<void> _pick(String id, WorkProofSource source) async {
    if (_busySource != null) return;
    setState(() => _busySource = id);
    final added = await widget.session.addProof(widget.proof.id, source);
    if (!mounted) return;
    if (added) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busySource = null);
  }

  @override
  Widget build(BuildContext context) {
    final reportedBottom = _workViewBottomInset(context);
    final safeBottom = reportedBottom < 24 ? 24.0 : reportedBottom;
    const sources =
        <({String id, String label, IconData icon, WorkProofSource source})>[
          (
            id: 'camera',
            label: 'Camera',
            icon: Icons.camera_alt_outlined,
            source: WorkProofSource.camera,
          ),
          (
            id: 'gallery',
            label: 'Photo gallery',
            icon: Icons.photo_library_outlined,
            source: WorkProofSource.gallery,
          ),
          (
            id: 'upload',
            label: 'PDF or image',
            icon: Icons.upload_file_outlined,
            source: WorkProofSource.upload,
          ),
          (
            id: 'cloud',
            label: 'Cloud files',
            icon: Icons.cloud_outlined,
            source: WorkProofSource.cloudDrive,
          ),
        ];
    return SafeArea(
      key: const Key('work-proof-source-safe-area'),
      top: false,
      minimum: EdgeInsets.only(bottom: safeBottom + MoolSpacing.xs),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: MoolMotion.accessible(context, MoolMotion.standard),
        curve: MoolMotion.enter,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        ),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(MoolRadii.sheet),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xs + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DAE8),
                      borderRadius: BorderRadius.circular(MoolRadii.capsule),
                    ),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                Text(
                  'Add ${widget.proof.label}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'PDF, JPG, JPEG, PNG or WebP · up to 10 MB. Cloud files shows the providers available on this device.',
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < sources.length; index++) ...[
                      Expanded(
                        child: _ProofSourceTile(
                          keyName: 'work-proof-source-${sources[index].id}',
                          label: sources[index].label,
                          icon: sources[index].icon,
                          busy: _busySource == sources[index].id,
                          onTap: _busySource == null
                              ? () => _pick(
                                  sources[index].id,
                                  sources[index].source,
                                )
                              : null,
                        ),
                      ),
                      if (index < sources.length - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                TextButton(
                  key: const Key('work-proof-source-cancel'),
                  onPressed: _busySource == null
                      ? () => Navigator.of(context).pop()
                      : null,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProofSourceTile extends StatelessWidget {
  const _ProofSourceTile({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F4FA),
      borderRadius: BorderRadius.circular(MoolRadii.control),
      child: InkWell(
        key: Key(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(MoolRadii.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 82),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, color: MoolColors.navy, size: 24),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 9.5,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineReviewAction extends StatelessWidget {
  const _InlineReviewAction({
    required this.session,
    required this.onUpdateDetails,
  });
  final WorkSession session;
  final VoidCallback onUpdateDetails;
  @override
  Widget build(BuildContext context) {
    final status = session.remoteReviewStatus;
    final needsHelp =
        status == WorkRemoteReviewStatus.rejected ||
        status == WorkRemoteReviewStatus.suspended ||
        (session.reviewReason?.trim().isNotEmpty == true &&
            session.gateway is! ReviewWorkGateway);
    if (needsHelp) {
      return WorkPrimaryButton(
        keyName: 'work-inline-review-support',
        label: 'Contact MoolSocial',
        icon: Icons.chat_bubble_outline,
        onPressed: () => context.push(
          Uri(
            path: '/app/chat/inbox',
            queryParameters: const {'return': '/app/work/workspace/proof'},
          ).toString(),
        ),
      );
    }
    if (session.errorMessage != null) {
      return WorkPrimaryButton(
        keyName: 'work-inline-review-check',
        label: 'Retry update',
        busy: session.busy,
        onPressed: session.checkReview,
      );
    }
    return const SizedBox.shrink();
  }
}

class _CorrectionInstructionCard extends StatelessWidget {
  const _CorrectionInstructionCard({required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: 'work-correction-instruction',
      color: const Color(0xFFFFF4E5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_unread_chat_alt_outlined,
            color: MoolColors.orange,
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What needs your attention',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  instruction,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    height: 1.35,
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

class _InlineWorkspaceReviewStatus extends StatelessWidget {
  const _InlineWorkspaceReviewStatus({
    required this.session,
    required this.onAddDocuments,
    required this.onUpdateDetails,
  });
  final WorkSession session;
  final VoidCallback onAddDocuments, onUpdateDetails;
  @override
  Widget build(BuildContext context) {
    final status = session.remoteReviewStatus;
    final rejected = status == WorkRemoteReviewStatus.rejected;
    final suspended = status == WorkRemoteReviewStatus.suspended;
    final reason = session.reviewReason?.trim() ?? '';
    final clarification = !rejected && !suspended && reason.isNotEmpty;
    final title = rejected
        ? 'Application not approved'
        : suspended
        ? 'Workspace unavailable'
        : clarification
        ? 'More information needed'
        : 'Application received';
    final detail = reason.isNotEmpty
        ? reason
        : rejected
        ? 'Contact MoolSocial for the reason and the available next step.'
        : suspended
        ? 'Contact MoolSocial about access to this Workspace.'
        : 'MoolSocial is reviewing your application. Expect an update within 24 working hours.';
    return _ReviewStepMotion(
      child: Column(
        key: const Key('work-inline-review-status'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                rejected || suspended
                    ? Icons.info_outline
                    : Icons.fact_check_outlined,
                color: MoolColors.navy,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!rejected && !suspended && !clarification) ...[
            const SizedBox(height: 12),
            const Text(
              'No action needed now. Review updates appear here automatically.',
              style: TextStyle(color: MoolColors.muted, fontSize: 12),
            ),
          ],
          if (clarification && session.gateway is ReviewWorkGateway) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                TextButton.icon(
                  key: const Key('work-inline-add-documents'),
                  onPressed: onAddDocuments,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Add documents'),
                ),
                TextButton.icon(
                  key: const Key('work-inline-update-details'),
                  onPressed: onUpdateDetails,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update details'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (session.submittedProfile case final submitted?) ...[
            const Text(
              'Submitted information',
              style: TextStyle(
                color: MoolColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(),
            _ReviewRow(label: 'Business', value: submitted.name),
            _ReviewRow(
              label: 'Your name',
              value: submitted.authorizedPersonName,
            ),
            _ReviewRow(label: 'Contact', value: submitted.primaryMobile),
            _ReviewRow(label: 'Email', value: submitted.email),
            _ReviewRow(
              label: 'Documents',
              value: '${submitted.proofReferences.length} attached',
            ),
          ],
          if (session.reviewCaseId case final caseId?)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Application reference',
                style: TextStyle(fontSize: 13, color: MoolColors.muted),
              ),
              children: [
                SelectableText(caseId),
                const Text(
                  'Share this reference if you contact MoolSocial about this application.',
                  style: TextStyle(fontSize: 12, color: MoolColors.muted),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReviewStepMotion extends StatelessWidget {
  const _ReviewStepMotion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MoolMotion.accessible(context, MoolMotion.standard),
      curve: MoolMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: Transform.scale(
            scale: .985 + (.015 * value),
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    final labels = step > 2
        ? const ['Submitted', 'MoolSocial review']
        : const ['Details', 'Documents', 'Review'];
    return Column(
      key: const Key('work-workspace-progress'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          step > 2 ? 'Application status' : 'Step ${step + 1} of 3',
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: MoolMotion.accessible(
                        context,
                        MoolMotion.quick,
                      ),
                      height: 3,
                      color: (step > 2 ? i == 0 : i <= step)
                          ? MoolColors.navy
                          : const Color(0xFFE2E4EE),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: (step > 2 ? i == 1 : i == step)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: MoolColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < labels.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    required this.proof,
    required this.added,
    required this.onAdd,
    this.file,
    this.onView,
    this.onRemove,
  });
  final WorkProofRequirement proof;
  final bool added;
  final WorkPickedProof? file;
  final VoidCallback onAdd;
  final VoidCallback? onView, onRemove;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.description_outlined,
                color: MoolColors.navy,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  proof.label,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            added ? file?.fileName ?? 'Document attached' : proof.detail,
            style: const TextStyle(color: MoolColors.muted, fontSize: 12),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            children: [
              if (added) ...[
                TextButton(
                  key: Key('work-view-proof-${proof.id}'),
                  onPressed: onView,
                  child: const Text('View'),
                ),
                TextButton(
                  key: Key('work-replace-proof-${proof.id}'),
                  onPressed: onAdd,
                  child: const Text('Replace'),
                ),
                IconButton(
                  key: Key('work-remove-proof-${proof.id}'),
                  tooltip: 'Remove ${proof.label}',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ] else
                TextButton(
                  key: Key('work-add-proof-${proof.id}'),
                  onPressed: onAdd,
                  child: const Text('Add document'),
                ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    ),
  );
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
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkVerificationStatusScreen extends StatelessWidget {
  const WorkVerificationStatusScreen({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final approved = {
          WorkReviewStage.approved,
          WorkReviewStage.live,
        }.contains(session.reviewStage);
        final rejected =
            session.remoteReviewStatus == WorkRemoteReviewStatus.rejected;
        final suspended =
            session.remoteReviewStatus == WorkRemoteReviewStatus.suspended;
        return WorkPageScaffold(
          session: session,
          title: approved
              ? 'Work approved'
              : rejected
              ? 'Changes needed'
              : suspended
              ? 'Workspace unavailable'
              : 'Work profile review',
          subtitle: session.reviewCaseId ?? 'Review status',
          fallbackBackRoute: '/app/work/workspace/choose',
          activeLocalAction: 'workspace',
          showHeaderChat: false,
          showTrailingAction: false,
          bottomAction: approved
              ? WorkPrimaryButton(
                  keyName: 'work-open-ready',
                  label: 'Open Workspace dashboard',
                  onPressed: () => context.go('/app/work/workspace/dashboard'),
                )
              : rejected
              ? WorkPrimaryButton(
                  keyName: 'work-revise-profile',
                  label: 'Review and resubmit',
                  onPressed: () {
                    session.reviseRejectedProfile();
                    context.go('/app/work/workspace/proof');
                  },
                  icon: Icons.edit_outlined,
                )
              : suspended
              ? WorkPrimaryButton(
                  keyName: 'work-suspended-support',
                  label: 'Open support Chat',
                  onPressed: () =>
                      context.go('/app/chat/inbox?return=/app/work/status'),
                  icon: Icons.support_agent_rounded,
                )
              : WorkPrimaryButton(
                  keyName: 'work-check-review',
                  label: 'Check review update',
                  busy: session.busy,
                  onPressed: () async {
                    final ready = await session.checkReview();
                    if (ready && context.mounted) {
                      context.go('/app/work/workspace/dashboard');
                    }
                  },
                  icon: Icons.refresh_rounded,
                ),
          body: ListView(
            key: const Key('work-status-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const WorkCard(
                child: _ContactRow(
                  label: 'Account owner',
                  value: '+91 98••• ••321',
                  state: 'KYC received',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: approved
                    ? const Color(0xFFEAF7E8)
                    : const Color(0xFFFFF4E5),
                child: Column(
                  children: [
                    Icon(
                      approved
                          ? Icons.verified_rounded
                          : rejected
                          ? Icons.edit_note_rounded
                          : suspended
                          ? Icons.pause_circle_outline_rounded
                          : Icons.hourglass_top_rounded,
                      size: 50,
                      color: approved
                          ? MoolColors.success
                          : rejected || suspended
                          ? const Color(0xFFB42318)
                          : MoolColors.orange,
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      approved
                          ? 'Review approved'
                          : rejected
                          ? 'Please update this profile'
                          : suspended
                          ? 'Workspace temporarily unavailable'
                          : 'Review in progress',
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      session.selectedProfile?.label ?? 'Work profile',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      session.reviewCaseId ?? 'Review reference pending',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((rejected || suspended) &&
                        session.reviewReason?.isNotEmpty == true) ...[
                      const SizedBox(height: MoolSpacing.xs),
                      Text(
                        session.reviewReason!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: MoolColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const _StatusSteps(),
              const SizedBox(height: MoolSpacing.md),
              if (!approved && !rejected && !suspended)
                WorkCard(
                  color: const Color(0xFFFFF4E5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WorkPill(
                        label: 'Action available',
                        color: MoolColors.orange,
                        icon: Icons.schedule_rounded,
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      const Text(
                        'Complete business verification',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'GST certificate is pending. Add it when available, or save a reminder while review continues.',
                        style: TextStyle(color: MoolColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('work-remind-gst'),
                              onPressed: session.remindGstLater,
                              child: const Text('Remind later'),
                            ),
                          ),
                          const SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: FilledButton(
                              key: const Key('work-add-gst'),
                              onPressed: () => _showGstSheet(context),
                              child: const Text('Add GST'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkSectionTitle(
                      title: 'Review team',
                      detail: 'Updates and requested changes appear here',
                      trailing: WorkPill(
                        label: 'Chat enabled',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const Text(
                      'If a document needs attention, you’ll see what to update here. Your personal account stays active.',
                      style: TextStyle(color: MoolColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('work-status-open-chat'),
                            onPressed: () => context.go(
                              '/app/chat/inbox?return=/app/work/status',
                            ),
                            child: const Text('Open Chat'),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('work-status-open-my-work'),
                            onPressed: () =>
                                context.go('/app/work/workspace/choose'),
                            child: const Text('Open My Work'),
                          ),
                        ),
                      ],
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

  Future<void> _showGstSheet(BuildContext context) {
    final gst = TextEditingController(text: session.gstin);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: session,
        builder: (context, _) => Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            0,
            MoolSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add GST certificate',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Business review continues without this document, but the reminder remains until resolved.',
                  style: TextStyle(color: MoolColors.muted),
                ),
                const SizedBox(height: MoolSpacing.md),
                TextField(
                  key: const Key('work-gstin'),
                  controller: gst,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'GSTIN'),
                ),
                const SizedBox(height: MoolSpacing.sm),
                OutlinedButton.icon(
                  key: const Key('work-attach-gst'),
                  onPressed: () => _showGstProofSource(sheetContext),
                  icon: Icon(
                    session.gstAttachmentAdded
                        ? Icons.check_circle_rounded
                        : Icons.attach_file_rounded,
                  ),
                  label: Text(
                    session.gstAttachmentAdded
                        ? 'Certificate attached'
                        : 'Attach certificate',
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                FilledButton(
                  key: const Key('work-submit-gst'),
                  onPressed: session.busy
                      ? null
                      : () async {
                          final submitted = await session.submitGstProof(
                            gst.text,
                          );
                          if (submitted && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                  child: const Text('Submit GST'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGstProofSource(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sourceContext) => SafeArea(
        key: const Key('work-gst-source-safe-area'),
        top: false,
        minimum: EdgeInsets.only(
          bottom: _workViewBottomInset(sourceContext) + 12,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            0,
            MoolSpacing.lg,
            MoolSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add GST certificate',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              for (final source in const [
                (
                  'camera',
                  'Camera',
                  Icons.camera_alt_outlined,
                  WorkProofSource.camera,
                ),
                (
                  'gallery',
                  'Photo library',
                  Icons.photo_library_outlined,
                  WorkProofSource.gallery,
                ),
                (
                  'upload',
                  'Upload PDF or image',
                  Icons.upload_file_outlined,
                  WorkProofSource.upload,
                ),
              ]) ...[
                OutlinedButton.icon(
                  key: Key('work-gst-source-${source.$1}'),
                  onPressed: () async {
                    final added = await session.addGstProof(source.$4);
                    if (added && sourceContext.mounted) {
                      Navigator.pop(sourceContext);
                    }
                  },
                  icon: Icon(source.$3),
                  label: Text(source.$2),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              TextButton(
                key: const Key('work-gst-source-cancel'),
                onPressed: () => Navigator.pop(sourceContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSteps extends StatelessWidget {
  const _StatusSteps();

  @override
  Widget build(BuildContext context) {
    return const WorkCard(
      child: Row(
        children: [
          _StatusStep(
            icon: Icons.check_rounded,
            label: 'Submitted',
            done: true,
          ),
          _StatusStep(
            icon: Icons.fact_check_outlined,
            label: 'Checks',
            done: false,
          ),
          _StatusStep(
            icon: Icons.rocket_launch_outlined,
            label: 'Activation',
            done: false,
          ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: done
                ? MoolColors.success
                : const Color(0xFFEDEEFF),
            foregroundColor: done ? Colors.white : MoolColors.navy,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: MoolSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              color: done ? MoolColors.success : MoolColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkspaceReadyScreen extends StatelessWidget {
  const WorkspaceReadyScreen({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final workspace = session.activeWorkspace;
        return WorkPageScaffold(
          session: session,
          title: 'Workspace ready',
          subtitle: 'Approval creates no public listing',
          fallbackBackRoute: '/app/work/status',
          activeLocalAction: 'workspace',
          bottomAction: WorkPrimaryButton(
            keyName: 'work-set-up-shop',
            label: 'Set up my shop',
            onPressed: () {
              session.beginRetailerSetup();
              context.go('/app/work/retailer/setup');
            },
            icon: Icons.storefront_rounded,
          ),
          body: ListView(
            key: const Key('workspace-ready-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const WorkCard(
                child: _ContactRow(
                  label: 'Workspace owner',
                  value: '+91 98••• ••321',
                  state: 'Verified',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: const Color(0xFFEAF7E8),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 58,
                      color: MoolColors.success,
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    const Text(
                      'Review approved',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      workspace?.profileLabel ?? 'Grocery / Kirana Shop',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      workspace?.id ?? session.workspaceId ?? 'Workspace ready',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const WorkPill(
                      label: 'Not public yet',
                      color: MoolColors.orange,
                      icon: Icons.visibility_off_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkCard(
                child: Row(
                  children: [
                    _ReadyStep(
                      icon: Icons.check_rounded,
                      label: 'Approved',
                      done: true,
                    ),
                    _ReadyStep(
                      icon: Icons.tune_rounded,
                      label: 'Set up',
                      done: false,
                    ),
                    _ReadyStep(
                      icon: Icons.public_rounded,
                      label: 'Go live',
                      done: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkPill(
                      label: 'Next action',
                      color: Color(0xFF9EE89B),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    const Text(
                      'Finish shop setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      '4 steps · product, price, fulfilment and publishing',
                      style: TextStyle(
                        color: Color(0xFFD9DAFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const Text(
                      'Customers see products only after every readiness step is complete and you choose to open the store.',
                      style: TextStyle(color: Color(0xFFD9DAFF), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: 'Already completed',
                detail: 'Common identity is not collected again',
              ),
              const SizedBox(height: MoolSpacing.sm),
              const WorkCard(
                child: Column(
                  children: [
                    _CompletedRow(label: 'Profile approved'),
                    _CompletedRow(label: 'Account linked'),
                    _CompletedRow(label: 'Exact shop profile selected'),
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

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: done
                ? MoolColors.success
                : const Color(0xFFEDEEFF),
            foregroundColor: done ? Colors.white : MoolColors.navy,
            child: Icon(icon),
          ),
          const SizedBox(height: MoolSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              color: done ? MoolColors.success : MoolColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: MoolColors.success),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RetailerSetupScreen extends StatefulWidget {
  const RetailerSetupScreen({required this.session, super.key});

  final WorkSession session;

  @override
  State<RetailerSetupScreen> createState() => _RetailerSetupScreenState();
}

class _RetailerSetupScreenState extends State<RetailerSetupScreen> {
  late final TextEditingController _quantity = TextEditingController(
    text: widget.session.retailerQuantity == 0
        ? ''
        : '${widget.session.retailerQuantity}',
  );
  late final TextEditingController _buy = TextEditingController(
    text: widget.session.retailerBuyPrice == 0
        ? ''
        : '${widget.session.retailerBuyPrice}',
  );
  late final TextEditingController _sell = TextEditingController(
    text: widget.session.retailerSellPrice == 0
        ? ''
        : '${widget.session.retailerSellPrice}',
  );

  @override
  void dispose() {
    _quantity.dispose();
    _buy.dispose();
    _sell.dispose();
    super.dispose();
  }

  void _saveFields() {
    widget.session.saveRetailerProduct(
      quantity: int.tryParse(_quantity.text) ?? 0,
      buyPrice: int.tryParse(_buy.text) ?? 0,
      sellPrice: int.tryParse(_sell.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final complete =
            widget.session.reviewStage == WorkReviewStage.live &&
            widget.session.retailerSetupSaved;
        return WorkPageScaffold(
          session: widget.session,
          title: complete ? 'Shop ready' : 'Set up your shop',
          subtitle: complete
              ? widget.session.workspaceVisibleToCustomers
                    ? 'Available products are open for customers'
                    : 'Setup complete · store is off'
              : 'Stock, price, fulfilment and publishing',
          fallbackBackRoute: complete
              ? '/app/work/workspace/choose'
              : '/app/work/ready',
          activeLocalAction: 'workspace',
          bottomAction: WorkPrimaryButton(
            keyName: complete
                ? 'retailer-setup-open-my-work'
                : 'retailer-finish-setup',
            label: complete
                ? 'Open shop operations'
                : widget.session.retailerPublishAfterSetup
                ? 'Finish setup and open store'
                : 'Finish setup with store off',
            busy: widget.session.busy,
            onPressed: () async {
              if (complete) {
                context.go('/app/work/workspace/dashboard');
                return;
              }
              _saveFields();
              await widget.session.finishRetailerSetup();
            },
            icon: complete
                ? Icons.work_outline_rounded
                : Icons.rocket_launch_rounded,
          ),
          body: ListView(
            key: const Key('retailer-setup-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              WorkCard(
                color: complete ? const Color(0xFFEAF7E8) : MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete
                          ? '${widget.session.activeWorkspace?.name ?? widget.session.workName} is ready'
                          : '4 steps',
                      style: TextStyle(
                        color: complete ? MoolColors.ink : Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      complete
                          ? 'Customers see only available stock with the fulfilment you approved.'
                          : 'Products remain private until setup passes and you choose whether to open the store.',
                      style: TextStyle(
                        color: complete
                            ? MoolColors.muted
                            : const Color(0xFFD9DAFF),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: '1. Add a product',
                detail: 'Use the verified master catalogue',
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (!widget.session.retailerProductAdded)
                WorkCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: MoolColors.navy,
                        size: 42,
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      const Text(
                        'Aashirvaad Whole Wheat Atta',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '1 kg consumer pack · brand verified · barcode ready',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: MoolColors.muted),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      FilledButton.icon(
                        key: const Key('retailer-add-catalog-product'),
                        onPressed: widget.session.addRetailerProduct,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add to my shop'),
                      ),
                    ],
                  ),
                )
              else
                const WorkCard(
                  color: Color(0xFFEAF7E8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: MoolColors.success,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.check_rounded),
                      ),
                      SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aashirvaad Whole Wheat Atta',
                              style: TextStyle(
                                color: MoolColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '1 kg consumer pack · catalogue matched',
                              style: TextStyle(color: MoolColors.muted),
                            ),
                          ],
                        ),
                      ),
                      WorkPill(label: 'Added'),
                    ],
                  ),
                ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: '2. Set stock and price',
                detail:
                    'Quantity for customer sales · wholesale orders are managed separately',
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('retailer-product-quantity'),
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Available consumer quantity',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('retailer-product-buy-price'),
                      controller: _buy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Purchase ₹',
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: TextField(
                      key: const Key('retailer-product-sell-price'),
                      controller: _sell,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sell ₹'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: '3. Choose fulfilment',
                detail: 'Home delivery and store collection are distinct',
              ),
              const SizedBox(height: MoolSpacing.sm),
              WorkCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('retailer-home-delivery'),
                      contentPadding: EdgeInsets.zero,
                      value: widget.session.retailerHomeDelivery,
                      title: const Text(
                        'Home delivery',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: const Text(
                        'Customer orders from home and receives delivery',
                      ),
                      onChanged: (value) =>
                          widget.session.setRetailerFulfilment(
                            homeDelivery: value,
                            storeCollection:
                                widget.session.retailerStoreCollection,
                          ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('retailer-store-collection'),
                      contentPadding: EdgeInsets.zero,
                      value: widget.session.retailerStoreCollection,
                      title: const Text(
                        'Store collection',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: const Text(
                        'Customer explicitly chooses this shop and collects',
                      ),
                      onChanged: (value) =>
                          widget.session.setRetailerFulfilment(
                            homeDelivery: widget.session.retailerHomeDelivery,
                            storeCollection: value,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: '4. Choose store publishing',
                detail: 'You can open the store now or keep it off after setup',
              ),
              const SizedBox(height: MoolSpacing.sm),
              WorkCard(
                child: SwitchListTile.adaptive(
                  key: const Key('retailer-publish-after-setup'),
                  contentPadding: EdgeInsets.zero,
                  value: widget.session.retailerPublishAfterSetup,
                  title: const Text(
                    'Open store after setup',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    widget.session.retailerPublishAfterSetup
                        ? 'Available products will be public and ready for customer orders.'
                        : 'The store remains off and private until you choose Open.',
                  ),
                  onChanged: widget.session.setRetailerPublishAfterSetup,
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: const Color(0xFFFFF4E5),
                child: Row(
                  children: [
                    Icon(
                      complete && widget.session.workspaceVisibleToCustomers
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_outlined,
                      color:
                          complete && widget.session.workspaceVisibleToCustomers
                          ? MoolColors.success
                          : MoolColors.orange,
                    ),
                    const SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Text(
                        complete
                            ? widget.session.workspaceVisibleToCustomers
                                  ? 'Available products are public with the fulfilment you approved.'
                                  : 'Setup is complete. The store remains off until you choose Open.'
                            : widget.session.retailerPublishAfterSetup
                            ? 'The store will open after all four setup steps pass.'
                            : 'Nothing will be public after setup until you choose Open.',
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w700,
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
}
