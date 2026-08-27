import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';
import '../../features/work/widgets/work_widgets.dart';
import '../../features/work/work_models.dart';
import '../../features/work/work_session.dart';

class RetailerWorkspaceOnboardingV2 extends StatefulWidget {
  const RetailerWorkspaceOnboardingV2({required this.session, super.key});

  final WorkSession session;

  @override
  State<RetailerWorkspaceOnboardingV2> createState() =>
      _RetailerWorkspaceOnboardingV2State();
}

class _RetailerWorkspaceOnboardingV2State
    extends State<RetailerWorkspaceOnboardingV2> {
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  late final TextEditingController _activityController;

  WorkSession get session => widget.session;

  List<WorkProfileOption> get _retailerProfiles => session
      .profilesForFamily('products-trade')
      .where(
        (profile) =>
            profile.id == 'retailer-grocery' ||
            profile.id == 'retailer-speciality',
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    if (session.selectedFamilyId != 'products-trade') {
      session.selectFamily('products-trade');
    }
    _nameController = TextEditingController(text: session.workName);
    _areaController = TextEditingController(text: session.workArea);
    _activityController = TextEditingController(text: session.primaryActivity);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    session.saveDetails(
      name: _nameController.text,
      area: _areaController.text,
      activity: _activityController.text,
    );
    if (!session.validateDetails()) return;
    if (!session.continueToProof()) return;
    context.go('/app/work/workspace/proof');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => WorkPageScaffold(
        session: session,
        title: 'Retail workspace',
        subtitle: 'Business details · 1 of 4',
        fallbackBackRoute: '/app/work/my-work',
        activeLocalAction: 'workspace',
        bottomAction: WorkPrimaryButton(
          keyName: 'retailer-onboarding-continue',
          label: 'Continue to verification',
          onPressed: session.busy ? null : _continue,
          busy: session.busy,
        ),
        body: ListView(
          key: const Key('retailer-workspace-onboarding-v2'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            152,
          ),
          children: [
            const _OnboardingProgress(),
            const SizedBox(height: MoolSpacing.md),
            const WorkCard(
              color: Color(0xFFF0FDF4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: MoolColors.success),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your personal account stays active',
                          style: TextStyle(
                            color: MoolColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Customers see the workspace only after verification and shop readiness are complete.',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const WorkSectionTitle(
              title: 'Choose your retail business',
              detail:
                  'This controls the products, stock and orders you can manage',
            ),
            const SizedBox(height: MoolSpacing.sm),
            for (final profile in _retailerProfiles) ...[
              _RetailProfileCard(
                profile: profile,
                selected: session.selectedProfile?.id == profile.id,
                onTap: () => session.selectProfile(profile.id),
              ),
              const SizedBox(height: MoolSpacing.sm),
            ],
            const SizedBox(height: MoolSpacing.md),
            const WorkSectionTitle(
              title: 'Business details',
              detail: 'Use information customers and reviewers can recognise',
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('retailer-onboarding-name'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.organizationName],
              decoration: const InputDecoration(
                labelText: 'Shop or business name',
                hintText: 'For example, Mahadev Fresh Mart',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('retailer-onboarding-area'),
              controller: _areaController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Operating area or PIN code',
                hintText: 'Where the shop serves customers',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('retailer-onboarding-activity'),
              controller: _activityController,
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continue(),
              decoration: const InputDecoration(
                labelText: 'What do you sell?',
                hintText: 'Describe the main products your shop sells',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            if (session.errorMessage case final error?) ...[
              const SizedBox(height: MoolSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  key: const Key('retailer-onboarding-error'),
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: MoolSpacing.md),
            TextButton.icon(
              key: const Key('retailer-onboarding-not-now'),
              onPressed: () => context.go('/app/work/my-work'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Finish later'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Retail workspace setup, step 1 of 4',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: MoolSpacing.sm,
          runSpacing: MoolSpacing.xs,
          children: [
            WorkPill(
              label: 'Step 1 of 4',
              color: Color(0xFF4D46A8),
              icon: Icons.storefront_rounded,
            ),
            Text(
              'Business details',
              style: TextStyle(
                color: MoolColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            value: .25,
            minHeight: 6,
            color: Color(0xFF4D46A8),
            backgroundColor: Color(0xFFE7E5F5),
          ),
        ),
      ],
    ),
  );
}

class _RetailProfileCard extends StatelessWidget {
  const _RetailProfileCard({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final WorkProfileOption profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => WorkCard(
    keyName: 'retailer-profile-${profile.id}',
    color: selected ? const Color(0xFFF3F1FF) : Colors.white,
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4D46A8) : const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            profile.icon,
            color: selected ? Colors.white : MoolColors.ink,
          ),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.label,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${profile.sellSide}. ${profile.buySide}.',
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: MoolSpacing.xs),
        Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? const Color(0xFF4D46A8) : MoolColors.muted,
        ),
      ],
    ),
  );
}
