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
      alignment: Alignment.centerRight,
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
    super.key,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .88, 400.0);
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
                    _ProfileAccessCard(onOpenRoute: onOpenRoute),
                    const SizedBox(height: MoolSpacing.lg),
                    _ProfileSection(
                      title: 'Account details',
                      items: [
                        _ProfileDestination(
                          id: 'identity',
                          title: 'Personal profile',
                          detail: 'Identity, contact details and profile',
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
                          title: 'Documents',
                          detail: 'Identity and workspace records',
                          icon: Icons.folder_outlined,
                          route: '/app/files',
                        ),
                      ],
                      onOpenRoute: onOpenRoute,
                    ),
                    const SizedBox(height: MoolSpacing.lg),
                    _ProfileSection(
                      title: 'Privacy and preferences',
                      items: [
                        _ProfileDestination(
                          id: 'security',
                          title: 'Security',
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
                      title: 'Plans',
                      items: [
                        _ProfileDestination(
                          id: 'plans',
                          title: 'Plans and access',
                          detail: 'Personal, Creator, Business and Commerce',
                          icon: Icons.workspace_premium_outlined,
                          route: '/app/account/plans',
                        ),
                      ],
                      onOpenRoute: onOpenRoute,
                    ),
                    const SizedBox(height: MoolSpacing.lg),
                    _ProfileSection(
                      title: 'Help and support',
                      items: [
                        _ProfileDestination(
                          id: 'ask',
                          title: 'Ask MoolSocial',
                          detail: 'Support for your account and workspaces',
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
      MoolSpacing.md,
      MoolSpacing.xs,
      MoolSpacing.md,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_profileNavy, Color(0xFF34348F)],
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .38)),
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
                'MoolSocial account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Personal account',
                style: TextStyle(
                  color: Color(0xFFD6D6F5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('global-profile-close'),
          tooltip: 'Close global profile',
          onPressed: onClose,
          color: Colors.white,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _ProfileAccessCard extends StatelessWidget {
  const _ProfileAccessCard({required this.onOpenRoute});

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
      padding: const EdgeInsets.all(MoolSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your MoolSocial access',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'One personal account can hold verified workspaces.',
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          _AccessRoleTile(
            keyName: 'global-profile-personal-account',
            icon: Icons.person_outline_rounded,
            title: 'Personal account',
            detail: 'MoolSocial services and personal activity',
            status: 'Active',
            accent: _profileGreen,
            onTap: () => onOpenRoute('/app/account/identity'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          _AccessRoleTile(
            keyName: 'global-profile-creator-workspace',
            icon: Icons.auto_awesome_outlined,
            title: 'Creator workspace',
            detail: 'Apply to create, publish, measure and earn',
            accent: _profileSaffron,
            onTap: () => onOpenRoute('/app/account/workspaces?type=creator'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          _AccessRoleTile(
            keyName: 'global-profile-workspaces',
            icon: Icons.storefront_outlined,
            title: 'Business and Commerce workspaces',
            detail: 'Apply to sell, trade or fulfil orders',
            accent: _profileNavy,
            onTap: () => onOpenRoute('/app/account/workspaces?type=partner'),
          ),
        ],
      ),
    ),
  );
}

class _AccessRoleTile extends StatelessWidget {
  const _AccessRoleTile({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
    required this.onTap,
    this.status,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final Color accent;
  final VoidCallback onTap;
  final String? status;

  @override
  Widget build(BuildContext context) => Material(
    key: Key(keyName),
    color: accent.withValues(alpha: .07),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MoolRadii.control),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(MoolRadii.control),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MoolSpacing.sm,
          vertical: MoolSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 20),
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
                          title,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (status != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _profileGreen.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status!,
                            style: const TextStyle(
                              color: _profileGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: accent, size: 22),
          ],
        ),
      ),
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
