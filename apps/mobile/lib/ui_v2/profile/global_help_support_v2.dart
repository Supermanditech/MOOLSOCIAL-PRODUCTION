import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../features/journey01/journey_session.dart';
import 'global_profile_panel_v2.dart';

class GlobalHelpSupportV2 extends StatelessWidget {
  const GlobalHelpSupportV2({
    required this.session,
    this.surfaceTone = GlobalProfileSurfaceTone.light,
    super.key,
  });

  final JourneySession session;
  final GlobalProfileSurfaceTone surfaceTone;

  @override
  Widget build(BuildContext context) {
    final palette = GlobalProfileSurfacePalette.forTone(surfaceTone);
    return Scaffold(
      key: const Key('global-help-support-v2'),
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: MoolSpacing.xs),
          child: GlobalProfileBackButtonV2(
            keyName: 'global-help-back',
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
              'Help & support',
              style: TextStyle(
                color: palette.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Account help and support Chat',
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
              key: const Key('global-help-content'),
              padding: const EdgeInsets.fromLTRB(
                MoolSpacing.md,
                MoolSpacing.xs,
                MoolSpacing.md,
                MoolSpacing.xl,
              ),
              children: [
                _HelpHero(palette: palette),
                const SizedBox(height: MoolSpacing.md),
                _HelpSection(
                  title: 'Help topics',
                  palette: palette,
                  children: [
                    _HelpAction(
                      keyName: 'global-help-security',
                      icon: Icons.shield_outlined,
                      title: 'Account access & security',
                      detail: 'Sign-in methods, recovery and app permissions',
                      palette: palette,
                      onTap: () => context.push('/app/account/security'),
                    ),
                    _HelpAction(
                      keyName: 'global-help-preferences',
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy & preferences',
                      detail:
                          'Language, service area, notifications and privacy',
                      palette: palette,
                      onTap: () =>
                          context.push('/app/account/workspaces/preferences'),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.md),
                _SupportCard(
                  palette: palette,
                  onPressed: () => context.push(_supportLocation()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _supportLocation() => Uri(
    path: '/app/chat',
    queryParameters: const {'type': 'support', 'return': '/app/ask'},
  ).toString();

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/work/home');
    }
  }
}

class _HelpHero extends StatelessWidget {
  const _HelpHero({required this.palette});

  final GlobalProfileSurfacePalette palette;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('global-help-hero'),
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
    child: const Row(
      children: [
        Icon(Icons.support_agent_rounded, color: Colors.white, size: 30),
        SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Choose a topic or continue to support Chat.',
                style: TextStyle(
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

class _HelpSection extends StatelessWidget {
  const _HelpSection({
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

class _HelpAction extends StatelessWidget {
  const _HelpAction({
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
    leading: Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.control,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: palette.accent, size: 18),
    ),
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
        height: 1.25,
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

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.palette, required this.onPressed});

  final GlobalProfileSurfacePalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('global-help-support-card'),
    color: palette.card,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MoolRadii.floating),
      side: BorderSide(color: palette.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: palette.accent,
                size: 21,
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  'MoolSocial support',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            'Continue in Chat with your account context attached.',
            style: TextStyle(
              color: palette.muted,
              fontSize: 9.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [palette.accent, palette.accentSecondary],
              ),
              borderRadius: BorderRadius.circular(MoolRadii.control),
            ),
            child: FilledButton.icon(
              key: const Key('global-help-open-support-chat'),
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
              label: const Text('Open support Chat'),
            ),
          ),
        ],
      ),
    ),
  );
}
