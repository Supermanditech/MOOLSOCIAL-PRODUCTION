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
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
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
                size: 21,
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
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
                  fontSize: 16,
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
                      fontSize: 11,
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
                          fontSize: 10,
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
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account and workspaces',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Personal access stays separate from verified workspaces.',
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 10,
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
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: _profileNavy, size: 18),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  'Grow with MoolSocial',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Choose how you want to work.',
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          _AccessRoleTile(
            keyName: 'global-profile-creator-workspace',
            icon: Icons.auto_awesome_outlined,
            title: 'Create and earn',
            detail: 'Apply for a Creator workspace',
            accent: _profileSaffron,
            onTap: () => onOpenRoute('/app/work/workspace/choose?path=creator'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          _AccessRoleTile(
            keyName: 'global-profile-workspaces',
            icon: Icons.storefront_outlined,
            title: 'Build your business',
            detail: 'Apply for a Business or Commerce workspace',
            accent: _profileNavy,
            onTap: () =>
                onOpenRoute('/app/work/workspace/choose?path=business'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          _AccessRoleTile(
            keyName: 'global-profile-work-access',
            icon: Icons.delivery_dining_outlined,
            title: 'Delivery and field work',
            detail: 'Apply for an Earn or Delivery workspace',
            accent: const Color(0xFF2563EB),
            onTap: () => onOpenRoute('/app/work/workspace/choose?path=work'),
          ),
          const SizedBox(height: MoolSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('global-profile-explore-workspaces'),
              onPressed: () => onOpenRoute('/app/work/workspace/choose'),
              style: FilledButton.styleFrom(
                backgroundColor: _profileNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
              ),
              child: const Text(
                'Explore workspaces',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Your personal account remains active during application and approval.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 9,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
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
          vertical: MoolSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 18),
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
                            fontSize: 12,
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
                              fontSize: 9,
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
                      fontSize: 10,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: accent, size: 20),
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
            fontSize: 14,
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
