import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';

const _profileNavy = Color(0xFF000080);
const _profileSaffron = Color(0xFFFF9933);
const _profileGreen = Color(0xFF138808);

Future<void> showGlobalProfilePanelV2(
  BuildContext context, {
  required ValueChanged<String> onOpenRoute,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close global profile',
    barrierColor: Colors.black.withValues(alpha: .38),
    transitionDuration: MoolMotion.standard,
    pageBuilder: (dialogContext, _, _) => Align(
      alignment: Alignment.centerLeft,
      child: GlobalProfilePanelV2(
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
          begin: const Offset(-1, 0),
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
    super.key,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .92, 420.0);
    return Material(
      key: const Key('global-profile-panel-v2'),
      color: MoolColors.canvas,
      elevation: 24,
      child: SafeArea(
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Column(
            children: [
              _ProfileHeader(onClose: onClose),
              Expanded(
                child: ListView(
                  key: const Key('global-profile-panel-content'),
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    MoolSpacing.sm,
                    MoolSpacing.md,
                    MoolSpacing.xxl,
                  ),
                  children: [
                    const _ProgressiveProfileCard(),
                    const SizedBox(height: MoolSpacing.lg),
                    _ProfileSection(
                      title: 'Profile details',
                      items: [
                        _ProfileDestination(
                          id: 'identity',
                          title: 'Personal identity',
                          detail: 'Name, contact and account identity',
                          icon: Icons.badge_outlined,
                          route: '/app/account/identity',
                        ),
                        _ProfileDestination(
                          id: 'activity',
                          title: 'Activity',
                          detail: 'Account and workspace updates',
                          icon: Icons.notifications_none_rounded,
                          route: '/app/activity',
                        ),
                        _ProfileDestination(
                          id: 'files',
                          title: 'Files and proofs',
                          detail: 'Identity and workspace documents',
                          icon: Icons.folder_outlined,
                          route: '/app/files',
                        ),
                      ],
                      onOpenRoute: onOpenRoute,
                    ),
                    const SizedBox(height: MoolSpacing.lg),
                    _ProfileSection(
                      title: 'Access and safety',
                      items: [
                        _ProfileDestination(
                          id: 'security',
                          title: 'Sign-in and security',
                          detail: 'Sign-in, recovery and active sessions',
                          icon: Icons.shield_outlined,
                          route: '/app/account/security',
                        ),
                        _ProfileDestination(
                          id: 'preferences',
                          title: 'Preferences',
                          detail: 'Language, location and notifications',
                          icon: Icons.tune_rounded,
                          route: '/app/account/workspaces/preferences',
                        ),
                      ],
                      onOpenRoute: onOpenRoute,
                    ),
                    const SizedBox(height: MoolSpacing.lg),
                    _ProfileSection(
                      title: 'Provider workspaces',
                      items: [
                        _ProfileDestination(
                          id: 'workspaces',
                          title: 'Your workspaces',
                          detail: 'Product and service-provider access',
                          icon: Icons.dashboard_customize_outlined,
                          route: '/app/account/workspaces',
                        ),
                        _ProfileDestination(
                          id: 'plans',
                          title: 'Plans and capabilities',
                          detail:
                              'Free profile access and approved workspace capabilities',
                          icon: Icons.workspace_premium_outlined,
                          route: '/app/account/plans',
                        ),
                      ],
                      onOpenRoute: onOpenRoute,
                    ),
                    const SizedBox(height: MoolSpacing.lg),
                    _ProfileSection(
                      title: 'Help',
                      items: [
                        _ProfileDestination(
                          id: 'ask',
                          title: 'Ask MoolSocial',
                          detail: 'Account and workspace support',
                          icon: Icons.support_agent_outlined,
                          route: '/app/ask',
                        ),
                      ],
                      onOpenRoute: onOpenRoute,
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
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      MoolSpacing.md,
      MoolSpacing.sm,
      MoolSpacing.xs,
      MoolSpacing.sm,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _profileNavy,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person_rounded, color: Colors.white),
        ),
        const SizedBox(width: MoolSpacing.sm),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your profile',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Personal access across MoolSocial',
                style: TextStyle(
                  color: MoolColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('global-profile-close'),
          tooltip: 'Close global profile',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _ProgressiveProfileCard extends StatelessWidget {
  const _ProgressiveProfileCard();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('global-profile-progressive-card'),
    padding: const EdgeInsets.all(MoolSpacing.md),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_profileNavy, Color(0xFF34348F)],
      ),
      borderRadius: BorderRadius.circular(MoolRadii.floating),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile and workspace access',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: MoolSpacing.sm),
        _ProfileStep(
          number: '1',
          title: 'Personal profile',
          detail: 'Active personal access',
          color: _profileGreen,
        ),
        _ProfileStep(
          number: '2',
          title: 'Provider workspace',
          detail: 'Documents and approval required',
          color: _profileSaffron,
        ),
        _ProfileStep(
          number: '3',
          title: 'Workspace capabilities',
          detail: 'Available after activation',
          color: Color(0xFF8CC8FF),
          showConnector: false,
        ),
      ],
    ),
  );
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.number,
    required this.title,
    required this.detail,
    required this.color,
    this.showConnector = true,
  });

  final String number;
  final String title;
  final String detail;
  final Color color;
  final bool showConnector;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (showConnector)
              Expanded(child: Container(width: 2, color: Color(0x55FFFFFF))),
          ],
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: MoolSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFD6D6F5),
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
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
            fontSize: 16,
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
    contentPadding: const EdgeInsets.symmetric(
      horizontal: MoolSpacing.sm,
      vertical: 3,
    ),
    minVerticalPadding: MoolSpacing.xs,
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _profileNavy.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(MoolRadii.control),
      ),
      child: Icon(item.icon, color: _profileNavy, size: 21),
    ),
    title: Text(
      item.title,
      style: const TextStyle(
        color: MoolColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    ),
    subtitle: Text(
      item.detail,
      style: const TextStyle(
        color: MoolColors.muted,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: _profileNavy),
    onTap: onTap,
  );
}
