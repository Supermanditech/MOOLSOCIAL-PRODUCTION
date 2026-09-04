import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../features/journey01/journey_session.dart';
import 'global_profile_panel_v2.dart';

const _profileNavy = Color(0xFF000080);
const _profileViolet = Color(0xFF4D46A8);
const _profileGreen = Color(0xFF138808);

class GlobalPersonalProfileV2 extends StatelessWidget {
  const GlobalPersonalProfileV2({
    required this.session,
    this.surfaceTone = GlobalProfileSurfaceTone.light,
    super.key,
  });

  final JourneySession session;
  final GlobalProfileSurfaceTone surfaceTone;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      final identity = session.accountIdentity;
      final displayName =
          _present(session.profileDisplayName) ??
          _present(identity?.displayName);
      final email = _present(identity?.emailAddress);
      final phone = _present(identity?.phoneNumber);
      final area =
          _present(session.currentAreaLabel) ??
          _present(session.manualArea) ??
          'Not set';
      final completed = [
        displayName != null,
        email != null || phone != null,
        area != 'Not set',
      ].where((value) => value).length;
      final heroName =
          displayName ?? identity?.primaryLabel ?? 'MoolSocial member';
      final heroDetail = identity?.detailLabel ?? 'Personal account';
      final methods = identity?.signInMethods ?? const <String>[];
      final accountActive = session.isAuthenticated && identity != null;
      final missing = <String>[
        if (displayName == null) 'display name',
        if (email == null && phone == null) 'contact',
        if (area == 'Not set') 'service area',
      ];
      final palette = GlobalProfileSurfacePalette.forTone(surfaceTone);

      return _PersonalProfilePaletteScope(
        palette: palette,
        child: Scaffold(
          key: const Key('global-personal-profile-v2'),
          backgroundColor: palette.canvas,
          appBar: AppBar(
            backgroundColor: palette.canvas,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: MoolSpacing.xs),
              child: GlobalProfileBackButtonV2(
                keyName: 'global-personal-profile-back',
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
                  'Personal profile',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Your MoolSocial identity',
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
                  key: const Key('global-personal-profile-content'),
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    MoolSpacing.xs,
                    MoolSpacing.md,
                    MoolSpacing.xl,
                  ),
                  children: [
                    _ProfileHero(
                      name: heroName,
                      detail: heroDetail,
                      completed: completed,
                      status: accountActive ? 'Active' : 'Sign in',
                      progressDetail: missing.isEmpty
                          ? 'Your essential profile details are complete.'
                          : 'Next: ${missing.join(' · ')}',
                      dark: surfaceTone == GlobalProfileSurfaceTone.socialDark,
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    _ProfileSection(
                      title: 'Personal details',
                      children: [
                        _ProfileDetail(
                          keyName: 'global-personal-profile-name',
                          icon: Icons.person_outline_rounded,
                          label: 'Display name',
                          value: displayName ?? 'Not added',
                          onTap: () => _openAccountRoute(
                            context,
                            '/app/account/identity/name',
                          ),
                        ),
                        _ProfileDetail(
                          keyName: 'global-personal-profile-email',
                          icon: Icons.alternate_email_rounded,
                          label: 'Email address',
                          value: email ?? 'Not added',
                          onTap: () => _openAccountRoute(
                            context,
                            '/app/account/security',
                          ),
                        ),
                        _ProfileDetail(
                          keyName: 'global-personal-profile-phone',
                          icon: Icons.phone_outlined,
                          label: 'Mobile number',
                          value: phone ?? 'Not added',
                          onTap: () => _openAccountRoute(
                            context,
                            '/app/account/security',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    _ProfileSection(
                      title: 'Preferences',
                      children: [
                        _ProfileDetail(
                          keyName: 'global-personal-profile-language',
                          icon: Icons.language_rounded,
                          label: 'Language',
                          value: session.languageCode == 'hi'
                              ? 'हिन्दी'
                              : 'English',
                          onTap: () => _openAccountRoute(
                            context,
                            '/app/account/workspaces/preferences',
                          ),
                        ),
                        _ProfileDetail(
                          keyName: 'global-personal-profile-area',
                          icon: Icons.location_on_outlined,
                          label: 'Service area',
                          value: area,
                          onTap: () => _openAccountRoute(
                            context,
                            '/app/account/workspaces/preferences',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    _ProfileSection(
                      title: 'Account access',
                      children: [
                        _ProfileDetail(
                          keyName: 'global-personal-profile-status',
                          icon: Icons.verified_user_outlined,
                          label: 'Account status',
                          value: accountActive ? 'Active' : 'Not signed in',
                          valueColor: accountActive
                              ? _profileGreen
                              : palette.muted,
                          onTap: () => _openAccountRoute(
                            context,
                            '/app/account/security',
                          ),
                        ),
                        _ProfileDetail(
                          keyName: 'global-personal-profile-methods',
                          icon: Icons.key_outlined,
                          label: 'Sign-in methods',
                          value: methods.isEmpty
                              ? accountActive
                                    ? 'MoolSocial sign-in'
                                    : 'Add a sign-in method'
                              : methods.join(' · '),
                          onTap: () => _openAccountRoute(
                            context,
                            '/app/account/security',
                          ),
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
    },
  );

  static void _openAccountRoute(BuildContext context, String route) {
    context.go(
      Uri(
        path: route,
        queryParameters: const {'return': '/app/account/identity'},
      ).toString(),
    );
  }

  static String? _present(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      final returnLocation = GoRouterState.of(
        context,
      ).uri.queryParameters['return'];
      context.go(
        globalProfileSafeReturnLocation(returnLocation) ?? '/app/mool',
      );
    }
  }
}

class GlobalPersonalProfileNameEditorV2 extends StatefulWidget {
  const GlobalPersonalProfileNameEditorV2({required this.session, super.key});

  final JourneySession session;

  @override
  State<GlobalPersonalProfileNameEditorV2> createState() =>
      _GlobalPersonalProfileNameEditorV2State();
}

class _GlobalPersonalProfileNameEditorV2State
    extends State<GlobalPersonalProfileNameEditorV2> {
  late final TextEditingController _controller = TextEditingController(
    text:
        widget.session.profileDisplayName ??
        widget.session.accountIdentity?.displayName ??
        '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await widget.session.updateProfileDisplayName(
      _controller.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) context.go('/app/account/identity');
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go('/app/account/identity');
    },
    child: Scaffold(
      key: const Key('global-personal-profile-name-editor'),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('global-personal-profile-name-back'),
          tooltip: 'Back',
          onPressed: () => context.go('/app/account/identity'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Display name'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'This is how people will see you across MoolSocial.',
                style: TextStyle(color: Color(0xFF5E6378)),
              ),
              const SizedBox(height: MoolSpacing.md),
              TextField(
                key: const Key('global-personal-profile-name-field'),
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 60,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Enter your name',
                  errorText: widget.session.errorMessage,
                ),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('global-personal-profile-name-save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save display name'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PersonalProfilePaletteScope extends InheritedWidget {
  const _PersonalProfilePaletteScope({
    required this.palette,
    required super.child,
  });

  final GlobalProfileSurfacePalette palette;

  static GlobalProfileSurfacePalette of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PersonalProfilePaletteScope>()!
      .palette;

  @override
  bool updateShouldNotify(_PersonalProfilePaletteScope oldWidget) =>
      palette != oldWidget.palette;
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.detail,
    required this.completed,
    required this.status,
    required this.progressDetail,
    required this.dark,
  });

  final String name;
  final String detail;
  final int completed;
  final String status;
  final String progressDetail;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final progress = completed / 3;
    return Container(
      key: const Key('global-personal-profile-hero'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF151515), Color(0xFF292929)]
              : const [_profileNavy, _profileViolet],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: .7)),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 10,
                        height: 1.25,
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
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Profile setup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  '$completed of 3 complete',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .76),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              key: const Key('global-personal-profile-progress'),
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            progressDetail,
            key: const Key('global-personal-profile-progress-detail'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .76),
              fontSize: 9,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = _PersonalProfilePaletteScope.of(context);
    return Column(
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
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = _PersonalProfilePaletteScope.of(context);
    return InkWell(
      key: ValueKey(keyName),
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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.control,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: palette.ink, size: 17),
            ),
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
            Icon(Icons.chevron_right_rounded, color: palette.muted),
          ],
        ),
      ),
    );
  }
}
