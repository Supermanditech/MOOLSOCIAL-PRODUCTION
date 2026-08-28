import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_service_home.dart';
import '../../core/design/mool_theme.dart';
import '../../features/work/work_models.dart';
import '../../features/work/widgets/work_widgets.dart';
import '../../features/work/work_session.dart';
import '../profile/global_profile_panel_v2.dart';

const _workNavy = Color(0xFF000080);
const _workViolet = Color(0xFF4D46A8);

GlobalProfileContextAction _workProfileContext(
  WorkSession session,
  ValueChanged<String> onOpenRoute,
) {
  final workspace = session.activeWorkspace;
  if (session.reviewStage == WorkReviewStage.live && workspace != null) {
    return GlobalProfileContextAction(
      id: 'work-workspace-active',
      title: workspace.name,
      detail: '${workspace.profileLabel} · ${workspace.area}',
      actionLabel: 'Open workspace',
      icon: Icons.dashboard_customize_outlined,
      accentColor: _workViolet,
      gradientColors: const [_workNavy, _workViolet],
      onPressed: () => onOpenRoute('/app/work/my-work'),
    );
  }

  if (session.reviewCaseId != null &&
      session.reviewStage != WorkReviewStage.live) {
    return GlobalProfileContextAction(
      id: 'work-workspace-application',
      title: 'Workspace application',
      detail:
          'Review status and provide additional information when requested.',
      actionLabel: 'View application',
      icon: Icons.fact_check_outlined,
      accentColor: _workViolet,
      gradientColors: const [_workNavy, _workViolet],
      onPressed: () => onOpenRoute('/app/work/my-work'),
    );
  }

  return GlobalProfileContextAction(
    id: 'work-workspace-create',
    title: 'Create a provider workspace',
    detail:
        'Choose how you work and submit the required information for review.',
    actionLabel: 'Start workspace setup',
    icon: Icons.add_business_outlined,
    accentColor: _workViolet,
    gradientColors: const [_workNavy, _workViolet],
    onPressed: () => onOpenRoute('/app/work/workspace/choose'),
  );
}

class WorkMainV2 extends StatelessWidget {
  const WorkMainV2({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    void openProfileRoute(String route) {
      if (route.startsWith('/app/work/workspace/choose')) {
        session.startAnotherWork();
      }
      context.push(route);
    }

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => WorkPageScaffold(
        session: session,
        title: 'Work',
        subtitle: 'Opportunities and provider workspaces',
        fallbackBackRoute: '/app/mool?from=work',
        showBack: false,
        showHeaderChat: false,
        activeLocalAction: 'home',
        trailing: MoolGlobalProfileShortcutV2(
          keyName: 'work-main-global-profile',
          onPressed: () => showGlobalProfilePanelV2(
            context,
            contextAction: _workProfileContext(session, openProfileRoute),
            onOpenRoute: openProfileRoute,
          ),
        ),
        body: ListView(
          key: const Key('work-main-v2'),
          padding: const EdgeInsets.fromLTRB(
            MoolServiceHomeTokens.pagePadding,
            MoolSpacing.xs,
            MoolServiceHomeTokens.pagePadding,
            MoolSpacing.xxl,
          ),
          children: [
            _WorkHero(session: session),
            const SizedBox(height: MoolSpacing.lg),
            const WorkSectionTitle(
              title: 'Choose your next action',
              detail: 'Review opportunities or manage provider access',
            ),
            const SizedBox(height: MoolSpacing.sm),
            _WorkActionCard(
              keyName: 'work-main-earn',
              icon: Icons.bolt_rounded,
              title: 'Find paid opportunities',
              detail:
                  'See pay, eligibility, location and timing before you apply.',
              actionLabel: 'Open Earn Today',
              accent: const Color(0xFFF59E0B),
              onTap: () => context.go('/app/work/earn'),
            ),
            const SizedBox(height: MoolSpacing.sm),
            _WorkActionCard(
              keyName: 'work-main-workspace',
              icon: Icons.dashboard_customize_outlined,
              title: session.activeWorkspace == null
                  ? 'Create a provider workspace'
                  : session.activeWorkspace!.name,
              detail: session.activeWorkspace == null
                  ? 'Choose your provider type and submit the required information for review.'
                  : '${session.activeWorkspace!.profileLabel} · ${session.activeWorkspace!.area}',
              actionLabel: session.activeWorkspace == null
                  ? 'Start Workspace setup'
                  : 'Open Workspace',
              accent: _workViolet,
              onTap: () {
                session.startMyWork();
                context.go('/app/work/my-work');
              },
            ),
            if (session.savedOpportunity case final saved?) ...[
              const SizedBox(height: MoolSpacing.lg),
              const WorkSectionTitle(
                title: 'Continue where you left off',
                detail: 'Your saved opportunity remains unchanged',
              ),
              const SizedBox(height: MoolSpacing.sm),
              WorkCard(
                keyName: 'work-main-saved-opportunity',
                color: const Color(0xFFFFF8E8),
                onTap: () {
                  session.openOpportunity(saved.id);
                  context.go('/app/work/opportunity/${saved.id}');
                },
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_added_outlined, color: _workNavy),
                    const SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saved.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${saved.payment} · ${saved.location}',
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: _workNavy),
                  ],
                ),
              ),
            ],
            const SizedBox(height: MoolSpacing.lg),
            const WorkCard(
              color: Color(0xFFF0FDF4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkPill(
                    label: 'Clear outcomes',
                    color: MoolColors.success,
                    icon: Icons.verified_outlined,
                  ),
                  SizedBox(height: MoolSpacing.sm),
                  Text(
                    'Clear terms and protected access',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Review pay and eligibility before applying. Provider workspaces remain private until approval.',
                    style: TextStyle(
                      color: MoolColors.muted,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkHero extends StatelessWidget {
  const _WorkHero({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final workspaceReady = session.activeWorkspace?.verified == true;
    return Container(
      key: const Key('work-main-hero'),
      padding: const EdgeInsets.all(MoolSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_workNavy, _workViolet],
        ),
        borderRadius: BorderRadius.circular(MoolRadii.floating),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000080),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkPill(
            label: 'MoolSocial Work',
            color: Color(0xFFFFB547),
            icon: Icons.work_outline_rounded,
          ),
          const SizedBox(height: MoolSpacing.md),
          const Text(
            'Earn, provide services and grow your business',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Review paid opportunities or manage a verified provider workspace.',
            style: TextStyle(
              color: Color(0xFFE7E7FF),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: [
              _HeroFact(
                icon: Icons.account_circle_outlined,
                label: 'One global profile',
              ),
              _HeroFact(
                icon: workspaceReady
                    ? Icons.verified_rounded
                    : Icons.add_business_outlined,
                label: workspaceReady
                    ? 'Provider workspace verified'
                    : 'Provider workspace separate',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: MoolSpacing.sm,
      vertical: MoolSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(MoolRadii.capsule),
      border: Border.all(color: Colors.white.withValues(alpha: .24)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _WorkActionCard extends StatelessWidget {
  const _WorkActionCard({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.accent,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => WorkCard(
    keyName: keyName,
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(MoolRadii.control),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              Text(
                actionLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_rounded, color: accent),
      ],
    ),
  );
}
