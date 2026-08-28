import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/mool_design_system.dart';
import '../../features/journey01/journey_session.dart';
import 'global_profile_panel_v2.dart';

final _privacyPolicyUri = Uri.parse('https://moolsocial.com/privacy/');
const _safeProfileReturnRoots = <String>[
  '/app/social',
  '/app/buy',
  '/app/eat',
  '/app/ride',
  '/app/book',
  '/app/work',
  '/app/mool',
];

class GlobalPrivacyPreferencesV2 extends StatelessWidget {
  const GlobalPrivacyPreferencesV2({
    required this.session,
    this.surfaceTone = GlobalProfileSurfaceTone.light,
    this.openNotificationSettings,
    this.openPrivacyPolicy,
    super.key,
  });

  final JourneySession session;
  final GlobalProfileSurfaceTone surfaceTone;
  final Future<bool> Function()? openNotificationSettings;
  final Future<bool> Function()? openPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final palette = GlobalProfileSurfacePalette.forTone(surfaceTone);
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => Scaffold(
        key: const Key('global-privacy-preferences-v2'),
        backgroundColor: palette.canvas,
        appBar: AppBar(
          backgroundColor: palette.canvas,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: MoolSpacing.sm),
            child: IconButton.outlined(
              key: const Key('global-preferences-back'),
              tooltip: 'Back',
              onPressed: () => _leave(context),
              style: IconButton.styleFrom(
                foregroundColor: palette.ink,
                backgroundColor: palette.card,
                side: BorderSide(color: palette.border),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          titleSpacing: MoolSpacing.xs,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Privacy & preferences',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Your choices across MoolSocial',
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
                key: const Key('global-preferences-content'),
                padding: const EdgeInsets.fromLTRB(
                  MoolSpacing.md,
                  MoolSpacing.xs,
                  MoolSpacing.md,
                  MoolSpacing.xl,
                ),
                children: [
                  _PreferencesHero(palette: palette),
                  const SizedBox(height: MoolSpacing.md),
                  _PreferenceSection(
                    title: 'App preferences',
                    palette: palette,
                    children: [
                      _PreferenceTile(
                        keyName: 'global-preferences-language',
                        icon: Icons.language_rounded,
                        title: 'Language',
                        value: session.languageCode == 'hi'
                            ? 'हिन्दी'
                            : 'English',
                        palette: palette,
                        onTap: () => _showLanguage(context, palette),
                      ),
                      _PreferenceTile(
                        keyName: 'global-preferences-area',
                        icon: Icons.location_on_outlined,
                        title: 'Service area',
                        value:
                            session.currentAreaLabel ??
                            session.manualArea ??
                            session.homeOrWorkArea ??
                            'Not set',
                        palette: palette,
                        onTap: () => _showArea(context, palette),
                      ),
                    ],
                  ),
                  const SizedBox(height: MoolSpacing.md),
                  _PreferenceSection(
                    title: 'Device & privacy',
                    palette: palette,
                    children: [
                      _PreferenceTile(
                        keyName: 'global-preferences-notifications',
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        value: 'Manage in device settings',
                        palette: palette,
                        onTap: () => _openNotifications(context),
                      ),
                      _PreferenceTile(
                        keyName: 'global-preferences-privacy-policy',
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy policy',
                        value: 'How MoolSocial handles information',
                        palette: palette,
                        onTap: () => _openPrivacy(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_safeReturnLocation(context) ?? '/app/mool');
    }
  }

  String? _safeReturnLocation(BuildContext context) {
    final raw = GoRouterState.of(context).uri.queryParameters['return'];
    if (raw == null || !raw.startsWith('/')) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    final safe = _safeProfileReturnRoots.any(
      (root) => uri.path == root || uri.path.startsWith('$root/'),
    );
    return safe ? uri.toString() : null;
  }

  Future<void> _showLanguage(
    BuildContext context,
    GlobalProfileSurfacePalette palette,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: palette.card,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return SingleChildScrollView(
          key: const Key('global-preferences-language-sheet'),
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.sm,
            MoolSpacing.md,
            media.viewPadding.bottom + MoolSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose language',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final choice in const [
                (code: 'en', label: 'English'),
                (code: 'hi', label: 'हिन्दी'),
              ])
                Padding(
                  padding: EdgeInsets.only(
                    bottom: choice.code == 'en' ? MoolSpacing.xs : 0,
                  ),
                  child: Semantics(
                    selected: session.languageCode == choice.code,
                    button: true,
                    child: ListTile(
                      key: Key('global-preferences-language-${choice.code}'),
                      tileColor: palette.control,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MoolRadii.control),
                        side: BorderSide(color: palette.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: MoolSpacing.sm,
                      ),
                      minTileHeight: 56,
                      leading: Icon(
                        session.languageCode == choice.code
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: palette.accent,
                      ),
                      title: Text(
                        choice.label,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () async {
                        final saved = await session.updateLanguage(choice.code);
                        if (saved && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showArea(
    BuildContext context,
    GlobalProfileSurfacePalette palette,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: palette.card,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) =>
          _ServiceAreaSheet(session: session, palette: palette),
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    final opened = await (openNotificationSettings ?? openAppSettings)();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device settings could not be opened.')),
      );
    }
  }

  Future<void> _openPrivacy(BuildContext context) async {
    final opened = await (openPrivacyPolicy ?? _launchPrivacyPolicy)();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy policy could not be opened.')),
      );
    }
  }

  static Future<bool> _launchPrivacyPolicy() async {
    try {
      return await launchUrl(
        _privacyPolicyUri,
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      return false;
    }
  }
}

class _ServiceAreaSheet extends StatefulWidget {
  const _ServiceAreaSheet({required this.session, required this.palette});

  final JourneySession session;
  final GlobalProfileSurfacePalette palette;

  @override
  State<_ServiceAreaSheet> createState() => _ServiceAreaSheetState();
}

class _ServiceAreaSheetState extends State<_ServiceAreaSheet> {
  late final TextEditingController _controller = TextEditingController(
    text:
        widget.session.currentAreaLabel ??
        widget.session.manualArea ??
        widget.session.homeOrWorkArea ??
        '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final palette = widget.palette;
    final media = MediaQuery.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.sm,
        MoolSpacing.md,
        media.viewInsets.bottom + media.viewPadding.bottom + MoolSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Service area',
            style: TextStyle(
              color: palette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          TextField(
            key: const Key('global-preferences-area-input'),
            controller: _controller,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: palette.ink),
            decoration: const InputDecoration(
              labelText: 'Area, city or PIN code',
            ),
          ),
          if (session.errorMessage case final error?) ...[
            const SizedBox(height: MoolSpacing.xs),
            Text(
              error,
              key: const Key('global-preferences-area-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('global-preferences-area-save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: MoolSpacing.xs,
                    ),
                  ),
                  onPressed: () async {
                    final saved = await session.updateArea(
                      AreaChoice.manual,
                      label: _controller.text,
                    );
                    if (saved && context.mounted) {
                      Navigator.pop(context);
                    } else if (context.mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text('Save area'),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('global-preferences-area-current'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: MoolSpacing.xs,
                    ),
                  ),
                  onPressed: session.resolvingCurrentArea
                      ? null
                      : () async {
                          final resolved = await session.resolveCurrentArea();
                          if (resolved) {
                            await session.updateArea(AreaChoice.current);
                          }
                          if (resolved && context.mounted) {
                            Navigator.pop(context);
                          } else if (context.mounted) {
                            setState(() {});
                          }
                        },
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text(
                    'Use my location',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.xs),
          TextButton.icon(
            key: const Key('global-preferences-area-remove'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () async {
              final saved = await session.updateArea(AreaChoice.skipped);
              if (saved && context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.location_off_outlined, size: 18),
            label: const Text('Remove service area'),
          ),
        ],
      ),
    );
  }
}

class _PreferencesHero extends StatelessWidget {
  const _PreferencesHero({required this.palette});

  final GlobalProfileSurfacePalette palette;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('global-preferences-hero'),
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
        Icon(Icons.tune_rounded, color: Colors.white, size: 28),
        SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your experience, your choices',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Choose your language and service area for a more relevant experience.',
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

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
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

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.value,
    required this.palette,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String value;
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
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
    onTap: onTap,
  );
}
