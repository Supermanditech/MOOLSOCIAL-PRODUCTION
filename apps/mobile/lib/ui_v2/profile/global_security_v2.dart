import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/design/mool_design_system.dart';
import '../../features/journey01/journey_session.dart';
import 'global_profile_panel_v2.dart';

class GlobalSecurityV2 extends StatelessWidget {
  const GlobalSecurityV2({
    required this.session,
    this.surfaceTone = GlobalProfileSurfaceTone.light,
    this.onSignOut,
    this.openDeviceSettings,
    super.key,
  });

  final JourneySession session;
  final GlobalProfileSurfaceTone surfaceTone;
  final Future<bool> Function()? onSignOut;
  final Future<bool> Function()? openDeviceSettings;

  @override
  Widget build(BuildContext context) {
    final palette = GlobalProfileSurfacePalette.forTone(surfaceTone);
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final identity = session.accountIdentity;
        final methods = identity?.signInMethods ?? const <String>[];
        final recovery =
            _present(identity?.emailAddress) ??
            _present(identity?.phoneNumber) ??
            _present(session.emailAddress) ??
            _present(session.phoneNumber) ??
            'Not added';
        return Scaffold(
          key: const Key('global-security-v2'),
          backgroundColor: palette.canvas,
          appBar: AppBar(
            backgroundColor: palette.canvas,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: MoolSpacing.xs),
              child: GlobalProfileBackButtonV2(
                keyName: 'global-security-back',
                palette: palette,
                onPressed: () => _leave(context),
              ),
            ),
            titleSpacing: MoolSpacing.xs,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Security',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Sign-in, recovery and device access',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  key: const Key('global-security-content'),
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    MoolSpacing.xs,
                    MoolSpacing.md,
                    MoolSpacing.xl,
                  ),
                  children: [
                    _SecurityHero(
                      authenticated: session.isAuthenticated,
                      name: identity?.primaryLabel ?? 'MoolSocial account',
                      palette: palette,
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    _SecuritySection(
                      title: 'Account access',
                      palette: palette,
                      children: [
                        if (session.isAuthenticated) ...[
                          _SecurityDetail(
                            keyName: 'global-security-status',
                            icon: Icons.verified_user_outlined,
                            label: 'Account status',
                            value: 'Signed in',
                            valueColor: const Color(0xFF138808),
                            palette: palette,
                          ),
                          _SecurityDetail(
                            keyName: 'global-security-methods',
                            icon: Icons.key_outlined,
                            label: 'Sign-in methods',
                            value: methods.isEmpty
                                ? 'MoolSocial sign-in'
                                : methods.join(' · '),
                            palette: palette,
                          ),
                          _SecurityDetail(
                            keyName: 'global-security-recovery',
                            icon: Icons.contact_mail_outlined,
                            label: 'Recovery contact',
                            value: recovery,
                            palette: palette,
                          ),
                        ] else
                          _SecurityAction(
                            keyName: 'global-security-sign-in',
                            icon: Icons.login_rounded,
                            title: 'Sign in',
                            detail:
                                'Manage account recovery and access methods',
                            palette: palette,
                            onTap: () => context.go('/sign-in'),
                          ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    _SecuritySection(
                      title: 'Device access',
                      palette: palette,
                      children: [
                        _SecurityAction(
                          keyName: 'global-security-device-settings',
                          icon: Icons.settings_outlined,
                          title: 'App permissions',
                          detail:
                              'Camera, location, microphone and notifications',
                          palette: palette,
                          onTap: () => _openSettings(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    if (session.isAuthenticated)
                      OutlinedButton.icon(
                        key: const Key('global-security-sign-out'),
                        onPressed: () => _confirmSignOut(context, palette),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                          side: const BorderSide(color: Color(0xFFF0B6B2)),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Sign out'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    final opened = await (openDeviceSettings ?? openAppSettings)();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device settings could not be opened.')),
      );
    }
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    GlobalProfileSurfacePalette palette,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('global-security-sign-out-dialog'),
        backgroundColor: palette.card,
        title: Text('End this session?', style: TextStyle(color: palette.ink)),
        content: Text(
          'Your language and service area remain saved on this device.',
          style: TextStyle(color: palette.muted),
        ),
        actions: [
          TextButton(
            key: const Key('global-security-sign-out-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('global-security-sign-out-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final signedOut = await (onSignOut ?? session.signOut)();
    if (!context.mounted) return;
    if (signedOut || !session.isAuthenticated) {
      context.go('/sign-in');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session.errorMessage ??
                'Sign-out could not be completed. Please try again.',
          ),
        ),
      );
    }
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/work/home');
    }
  }

  static String? _present(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class _SecurityHero extends StatelessWidget {
  const _SecurityHero({
    required this.authenticated,
    required this.name,
    required this.palette,
  });

  final bool authenticated;
  final String name;
  final GlobalProfileSurfacePalette palette;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('global-security-hero'),
    padding: const EdgeInsets.all(MoolSpacing.md),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.accent, palette.accentSecondary],
      ),
      borderRadius: BorderRadius.circular(MoolRadii.floating),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24000080),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.shield_outlined, color: Colors.white, size: 30),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                authenticated
                    ? 'Your account session is active.'
                    : 'Account access is required for recovery controls.',
                style: const TextStyle(
                  color: Color(0xFFDADAF3),
                  fontSize: 10,
                  height: 1.25,
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

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({
    required this.title,
    required this.palette,
    required this.children,
  });

  final String title;
  final GlobalProfileSurfacePalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: MoolSpacing.xs),
        child: Text(
          title,
          style: TextStyle(
            color: palette.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Material(
        color: palette.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoolRadii.card),
          side: BorderSide(color: palette.border),
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                Divider(height: 1, indent: 52, color: palette.border),
            ],
          ],
        ),
      ),
    ],
  );
}

class _SecurityDetail extends StatelessWidget {
  const _SecurityDetail({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
    this.valueColor,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final String value;
  final GlobalProfileSurfacePalette palette;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey(keyName),
    padding: const EdgeInsets.symmetric(
      horizontal: MoolSpacing.sm,
      vertical: MoolSpacing.xs,
    ),
    child: Row(
      children: [
        _SecurityIcon(icon: icon, palette: palette),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor ?? palette.ink,
                  fontSize: 12,
                  height: 1.2,
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

class _SecurityAction extends StatelessWidget {
  const _SecurityAction({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.palette,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final GlobalProfileSurfacePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey(keyName),
    contentPadding: const EdgeInsets.symmetric(horizontal: MoolSpacing.sm),
    visualDensity: const VisualDensity(vertical: -1),
    leading: _SecurityIcon(icon: icon, palette: palette),
    title: Text(
      title,
      style: TextStyle(
        color: palette.ink,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
    subtitle: Text(
      detail,
      style: TextStyle(
        color: palette.muted,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    trailing: Icon(
      Icons.chevron_right_rounded,
      color: palette.accent,
      size: 19,
    ),
    splashColor: palette.accent.withValues(alpha: .08),
    onTap: onTap,
  );
}

class _SecurityIcon extends StatelessWidget {
  const _SecurityIcon({required this.icon, required this.palette});

  final IconData icon;
  final GlobalProfileSurfacePalette palette;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: palette.control,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, color: palette.accent, size: 18),
  );
}
