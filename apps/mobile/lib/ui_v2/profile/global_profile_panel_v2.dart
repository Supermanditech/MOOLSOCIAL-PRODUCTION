import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';

const _profileNavy = Color(0xFF000080);
const _profileSaffron = Color(0xFFFF9933);
const _profileGreen = Color(0xFF138808);

class GlobalProfileWorkspaceContext {
  const GlobalProfileWorkspaceContext({
    required this.name,
    required this.roleLabel,
    required this.area,
  });

  final String name;
  final String roleLabel;
  final String area;
}

Future<void> showGlobalProfilePanelV2(
  BuildContext context, {
  required ValueChanged<String> onOpenRoute,
  GlobalProfileWorkspaceContext? activeWorkspace,
  bool applicationInProgress = false,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close global profile',
    barrierColor: Colors.black.withValues(alpha: .38),
    transitionDuration: MoolMotion.standard,
    pageBuilder: (dialogContext, _, _) => Align(
      alignment: Alignment.centerRight,
      child: GlobalProfilePanelV2(
        activeWorkspace: activeWorkspace,
        applicationInProgress: applicationInProgress,
        onClose: () => Navigator.pop(dialogContext),
        onOpenRoute: (route) {
          Navigator.pop(dialogContext);
          onOpenRoute(route);
        },
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: MoolMotion.enter,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class GlobalProfilePanelV2 extends StatelessWidget {
  const GlobalProfilePanelV2({
    required this.onClose,
    required this.onOpenRoute,
    this.activeWorkspace,
    this.applicationInProgress = false,
    super.key,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onOpenRoute;
  final GlobalProfileWorkspaceContext? activeWorkspace;
  final bool applicationInProgress;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final effectiveScale = media.textScaler.scale(1).clamp(.9, 1.15);
    final width = math.min(media.size.width * .8, 340.0);
    final height = math.min(media.size.height * .78, 680.0);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(effectiveScale)),
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
        child: Material(
          key: const Key('global-profile-panel-v2'),
          color: MoolColors.canvas,
          elevation: 24,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: Column(
              children: [
                _ProfileHeader(
                  onClose: onClose,
                  workspaceRoleLabel: activeWorkspace?.roleLabel,
                ),
                Expanded(
                  child: ListView(
                    key: const Key('global-profile-panel-content'),
                    padding: const EdgeInsets.fromLTRB(
                      MoolSpacing.sm,
                      MoolSpacing.sm,
                      MoolSpacing.sm,
                      MoolSpacing.md,
                    ),
                    children: [
                      if (activeWorkspace case final workspace?) ...[
                        _ActiveWorkspaceCard(workspace: workspace),
                        const SizedBox(height: MoolSpacing.md),
                        _ProfileQuickActions(onOpenRoute: onOpenRoute),
                        const SizedBox(height: MoolSpacing.md),
                        _PersonalAccountSection(
                          includeSupport: false,
                          onOpenRoute: onOpenRoute,
                        ),
                      ] else ...[
                        _PersonalAccountSection(
                          includeSupport: true,
                          onOpenRoute: onOpenRoute,
                        ),
                        const SizedBox(height: MoolSpacing.md),
                        _ProfileAccessCard(
                          applicationInProgress: applicationInProgress,
                          onOpenRoute: onOpenRoute,
                        ),
                      ],
                    ],
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onClose,
    required this.workspaceRoleLabel,
  });

  final VoidCallback onClose;
  final String? workspaceRoleLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      MoolSpacing.sm,
      MoolSpacing.xs,
      MoolSpacing.xs,
      MoolSpacing.xs,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
    ),
    child: Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_profileNavy, Color(0xFF4D46A8)],
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: _profileGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your MoolSocial profile',
                maxLines: 2,
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 14,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 7,
                runSpacing: 2,
                children: [
                  const Text(
                    'Personal account',
                    style: TextStyle(
                      color: MoolColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (workspaceRoleLabel != null)
                    Text(
                      workspaceRoleLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: _profileGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: _profileGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('global-profile-close'),
          tooltip: 'Close global profile',
          onPressed: onClose,
          color: MoolColors.ink,
          icon: const Icon(Icons.close_rounded, size: 22),
        ),
      ],
    ),
  );
}

class _PersonalAccountSection extends StatelessWidget {
  const _PersonalAccountSection({
    required this.includeSupport,
    required this.onOpenRoute,
  });

  final bool includeSupport;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) => _ProfileSection(
    title: includeSupport ? 'Your account' : 'Personal account',
    items: [
      const _ProfileDestination(
        id: 'identity',
        title: 'Personal profile',
        detail: 'Identity and contact',
        icon: Icons.badge_outlined,
        route: '/app/account/identity',
      ),
      const _ProfileDestination(
        id: 'preferences',
        title: 'Privacy and preferences',
        detail: 'Data and notifications',
        icon: Icons.privacy_tip_outlined,
        route: '/app/account/workspaces/preferences',
      ),
      const _ProfileDestination(
        id: 'security',
        title: 'Security',
        detail: 'Sign-in and recovery',
        icon: Icons.shield_outlined,
        route: '/app/account/security',
      ),
      if (includeSupport)
        const _ProfileDestination(
          id: 'ask',
          title: 'Help and support',
          detail: 'Account assistance',
          icon: Icons.support_agent_outlined,
          route: '/app/ask',
        ),
    ],
    onOpenRoute: onOpenRoute,
  );
}

class _ActiveWorkspaceCard extends StatelessWidget {
  const _ActiveWorkspaceCard({required this.workspace});

  final GlobalProfileWorkspaceContext workspace;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('global-profile-active-workspace'),
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MoolRadii.floating),
      side: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(MoolSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _profileGreen.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: _profileGreen,
              size: 19,
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspace.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${workspace.roleLabel} · ${workspace.area}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 9,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _profileGreen.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: _profileGreen,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileAccessCard extends StatelessWidget {
  const _ProfileAccessCard({
    required this.applicationInProgress,
    required this.onOpenRoute,
  });

  final bool applicationInProgress;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('global-profile-access-card'),
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MoolRadii.floating),
      side: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(MoolSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _profileSaffron.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  applicationInProgress
                      ? Icons.hourglass_top_rounded
                      : Icons.trending_up_rounded,
                  color: _profileSaffron,
                  size: 19,
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicationInProgress
                          ? 'Workspace application'
                          : 'Become a MoolSocial Partner',
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      applicationInProgress
                          ? 'Partner controls stay locked until approval and activation.'
                          : 'Choose how you work and submit one workspace application.',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 9,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('global-profile-explore-workspaces'),
              onPressed: () => onOpenRoute(
                applicationInProgress
                    ? '/app/work/my-work'
                    : '/app/work/workspace/choose',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _profileNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
              ),
              child: Text(
                applicationInProgress
                    ? 'View application'
                    : 'Explore workspaces',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileQuickActions extends StatelessWidget {
  const _ProfileQuickActions({required this.onOpenRoute});

  final ValueChanged<String> onOpenRoute;

  static const _actions = <_ProfileQuickAction>[
    _ProfileQuickAction(
      id: 'operations',
      label: 'Operations',
      icon: Icons.dashboard_customize_outlined,
      route: '/app/work/my-work',
      accent: Color(0xFF4D46A8),
    ),
    _ProfileQuickAction(
      id: 'activity',
      label: 'Activity',
      icon: Icons.notifications_none_rounded,
      route: '/app/activity',
      accent: Color(0xFFFF9933),
    ),
    _ProfileQuickAction(
      id: 'documents',
      label: 'Documents',
      icon: Icons.folder_outlined,
      route: '/app/files',
      accent: Color(0xFF2563EB),
    ),
    _ProfileQuickAction(
      id: 'plans',
      label: 'Plans',
      icon: Icons.workspace_premium_outlined,
      route: '/app/account/plans',
      accent: Color(0xFF7C3AED),
    ),
    _ProfileQuickAction(
      id: 'support',
      label: 'Support',
      icon: Icons.support_agent_outlined,
      route: '/app/ask',
      accent: Color(0xFF0F766E),
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('global-profile-quick-actions'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 2, bottom: MoolSpacing.xs),
        child: Text(
          'Workspace access',
          style: TextStyle(
            color: MoolColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          const gap = MoolSpacing.xs;
          final tileWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final action in _actions)
                SizedBox(
                  width: tileWidth,
                  child: Material(
                    key: Key('global-profile-quick-${action.id}'),
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MoolRadii.control),
                      side: const BorderSide(color: Color(0xFFE4E7EC)),
                    ),
                    child: InkWell(
                      onTap: () => onOpenRoute(action.route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MoolSpacing.xs,
                          vertical: MoolSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: action.accent.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                action.icon,
                                color: action.accent,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: MoolSpacing.xs),
                            Expanded(
                              child: Text(
                                action.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MoolColors.ink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _ProfileQuickAction {
  const _ProfileQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.accent,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;
  final Color accent;
}

class _ProfileDestination {
  const _ProfileDestination({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.route,
  });

  final String id;
  final String title;
  final String detail;
  final IconData icon;
  final String route;
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.items,
    required this.onOpenRoute,
  });

  final String title;
  final List<_ProfileDestination> items;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: MoolSpacing.xs),
        child: Text(
          title,
          style: const TextStyle(
            color: MoolColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoolRadii.card),
          side: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _ProfileDestinationTile(
                item: items[index],
                onTap: () => onOpenRoute(items[index].route),
              ),
              if (index != items.length - 1)
                const Divider(height: 1, indent: 60),
            ],
          ],
        ),
      ),
    ],
  );
}

class _ProfileDestinationTile extends StatelessWidget {
  const _ProfileDestinationTile({required this.item, required this.onTap});

  final _ProfileDestination item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('global-profile-${item.id}'),
    contentPadding: const EdgeInsets.symmetric(horizontal: MoolSpacing.xs),
    minVerticalPadding: 6,
    visualDensity: const VisualDensity(vertical: -1),
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _profileNavy.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(MoolRadii.control),
      ),
      child: Icon(item.icon, color: _profileNavy, size: 18),
    ),
    title: Text(
      item.title,
      style: const TextStyle(
        color: MoolColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
    subtitle: Text(
      item.detail,
      style: const TextStyle(
        color: MoolColors.muted,
        fontSize: 9.5,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: _profileNavy,
      size: 19,
    ),
    onTap: onTap,
  );
}
