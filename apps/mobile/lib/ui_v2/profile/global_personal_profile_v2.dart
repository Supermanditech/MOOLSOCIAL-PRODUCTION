import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';
import '../../features/journey01/journey_services.dart';

const _profileNavy = Color(0xFF000080);
const _profileViolet = Color(0xFF4D46A8);
const _profileGreen = Color(0xFF138808);

class GlobalPersonalProfileV2 extends StatelessWidget {
  const GlobalPersonalProfileV2({
    required this.identity,
    required this.isAuthenticated,
    super.key,
  });

  final AuthenticatedAccountIdentity? identity;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final displayName = _present(identity?.displayName);
    final email = _present(identity?.emailAddress);
    final phone = _present(identity?.phoneNumber);
    final connectedAccount = _present(identity?.providerAccountLabel);
    final signInMethods = identity?.signInMethods
        .map((method) => method.trim())
        .where((method) => method.isNotEmpty)
        .toList(growable: false);

    return Scaffold(
      key: const Key('global-personal-profile-v2'),
      backgroundColor: MoolColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 68,
        automaticallyImplyLeading: false,
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: MoolSpacing.sm),
          child: IconButton.filledTonal(
            key: const Key('global-personal-profile-back'),
            tooltip: 'Back to profile',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/app/work/home');
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: _profileNavy.withValues(alpha: .06),
              foregroundColor: _profileNavy,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        titleSpacing: MoolSpacing.xs,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal profile',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Your MoolSocial account',
              style: TextStyle(
                color: MoolColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              key: const Key('global-personal-profile-content'),
              padding: const EdgeInsets.fromLTRB(
                MoolSpacing.md,
                MoolSpacing.sm,
                MoolSpacing.md,
                MoolSpacing.xxl,
              ),
              children: [
                _ProfileHero(
                  displayName: displayName,
                  isAuthenticated: isAuthenticated,
                ),
                const SizedBox(height: MoolSpacing.lg),
                const _SectionTitle('Profile details'),
                const SizedBox(height: MoolSpacing.xs),
                _DetailsCard(
                  children: [
                    _DetailRow(
                      keyName: 'global-personal-profile-name',
                      icon: Icons.person_outline_rounded,
                      label: 'Name',
                      value: displayName ?? 'Not added',
                    ),
                    _DetailRow(
                      keyName: 'global-personal-profile-email',
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: email ?? 'Not added',
                    ),
                    _DetailRow(
                      keyName: 'global-personal-profile-mobile',
                      icon: Icons.phone_android_rounded,
                      label: 'Mobile',
                      value: phone ?? 'Not added',
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.lg),
                const _SectionTitle('Account access'),
                const SizedBox(height: MoolSpacing.xs),
                _DetailsCard(
                  children: [
                    _DetailRow(
                      keyName: 'global-personal-profile-sign-in',
                      icon: Icons.key_outlined,
                      label: 'Sign-in methods',
                      value: signInMethods == null || signInMethods.isEmpty
                          ? isAuthenticated
                                ? 'Not available'
                                : 'Sign in to view'
                          : signInMethods.join(' · '),
                    ),
                    if (connectedAccount != null)
                      _DetailRow(
                        keyName: 'global-personal-profile-connected-account',
                        icon: Icons.account_circle_outlined,
                        label: 'Connected account',
                        value: connectedAccount,
                      ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.lg),
                _GradientAction(
                  isAuthenticated: isAuthenticated,
                  onPressed: () => context.push(
                    isAuthenticated
                        ? '/app/account/security'
                        : '/sign-in?return=/app/account/profile',
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const Text(
                  'Your personal profile remains separate from professional workspaces.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.isAuthenticated,
  });

  final String? displayName;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('global-personal-profile-hero'),
    padding: const EdgeInsets.all(MoolSpacing.md),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_profileNavy, _profileViolet, Color(0xFF6D4BC3)],
      ),
      borderRadius: BorderRadius.circular(MoolRadii.floating),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000080),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .34)),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName ?? 'Personal account',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAuthenticated
                    ? 'Signed in to MoolSocial'
                    : 'Sign in to add and manage personal details',
                style: const TextStyle(
                  color: Color(0xFFE7E7FF),
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (isAuthenticated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _profileGreen,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: MoolColors.ink,
      fontSize: 15,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MoolRadii.card),
      side: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const Divider(height: 1, indent: 54),
        ],
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.value,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    key: Key(keyName),
    padding: const EdgeInsets.symmetric(
      horizontal: MoolSpacing.sm,
      vertical: MoolSpacing.sm,
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _profileNavy.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _profileNavy, size: 19),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GradientAction extends StatelessWidget {
  const _GradientAction({
    required this.isAuthenticated,
    required this.onPressed,
  });

  final bool isAuthenticated;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_profileNavy, _profileViolet, Color(0xFF6D4BC3)],
      ),
      borderRadius: BorderRadius.circular(MoolRadii.control),
    ),
    child: FilledButton(
      key: const Key('global-personal-profile-primary-action'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoolRadii.control),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              isAuthenticated
                  ? 'Account security'
                  : 'Sign in to manage profile',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    ),
  );
}

String? _present(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
