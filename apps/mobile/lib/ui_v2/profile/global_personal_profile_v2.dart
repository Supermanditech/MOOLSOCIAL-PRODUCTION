import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../features/journey01/journey_session.dart';
import 'global_profile_panel_v2.dart';

const _profileNavy = Color(0xFF000080);
const _profileViolet = Color(0xFF4D46A8);

class GlobalPersonalProfileV2 extends StatefulWidget {
  const GlobalPersonalProfileV2({
    required this.session,
    this.gstDetails,
    this.onOpenAddresses,
    this.surfaceTone = GlobalProfileSurfaceTone.light,
    super.key,
  });

  final JourneySession session;
  final Widget? gstDetails;
  final VoidCallback? onOpenAddresses;
  final GlobalProfileSurfaceTone surfaceTone;

  @override
  State<GlobalPersonalProfileV2> createState() => _GlobalPersonalProfileV2State();
}

class _GlobalPersonalProfileV2State extends State<GlobalPersonalProfileV2> {
  JourneySession get session => widget.session;
  Widget? get gstDetails => widget.gstDetails;
  VoidCallback? get onOpenAddresses => widget.onOpenAddresses;
  GlobalProfileSurfaceTone get surfaceTone => widget.surfaceTone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(session.refreshAccountProfile());
    });
  }

  @override
  void didUpdateWidget(GlobalPersonalProfileV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, session)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(session.refreshAccountProfile());
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      final identity = session.isAuthenticated ? session.accountIdentity : null;
      // The legacy device alias has no account owner. Never present it as the
      // identity of a newly signed-in account (PROFILE-B01 owns durable edits).
      final source = session.accountProfileGateway;
      final canonicalUnavailable = source != null && source.snapshot == null;
      final displayName = canonicalUnavailable ? null : _present(identity?.displayName);
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

      return PopScope<Object?>(
        canPop: context.canPop(),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave(context);
        },
        child: _PersonalProfilePaletteScope(
          palette: palette,
          child: Scaffold(
            key: const Key('global-personal-profile-v2'),
            backgroundColor: palette.canvas,
            appBar: AppBar(
              backgroundColor: palette.canvas,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 56,
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
                    surfaceTone == GlobalProfileSurfaceTone.light
                        ? 'My details'
                        : 'Personal profile',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                    ),
                  ),
                  if (surfaceTone == GlobalProfileSurfaceTone.socialDark) ...[
                    const SizedBox(height: 1),
                    Text(
                      'Your MoolSocial identity',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                      if (surfaceTone == GlobalProfileSurfaceTone.socialDark)
                        _ProfileHero(
                          name: heroName,
                          detail: heroDetail,
                          completed: completed,
                          status: accountActive ? 'Active' : 'Sign in',
                          progressDetail: missing.isEmpty
                              ? 'Your essential profile details are complete.'
                              : 'Next: ${missing.join(' · ')}',
                          dark:
                              surfaceTone ==
                              GlobalProfileSurfaceTone.socialDark,
                        )
                      else
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF0F2FF),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF0000FF),
                            ),
                          ),
                          title: Text(
                            accountActive ? heroName : 'Your account',
                            key: const Key('global-personal-profile-hero-name'),
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            accountActive
                                ? heroDetail
                                : 'Sign in with email or mobile OTP',
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 13,
                            ),
                          ),
                          onTap: () => _openAccountRoute(
                            context,
                            '/app/account/security',
                          ),
                          trailing: accountActive
                              ? null
                              : const Icon(Icons.chevron_right_rounded),
                        ),
                      const SizedBox(height: MoolSpacing.md),
                      _ProfileSection(
                        title: 'Identity',
                        children: [
                          _ProfileDetail(
                            keyName: 'global-personal-profile-name',
                            icon: Icons.person_outline_rounded,
                            label: 'Display name',
                              value: displayName ?? (canonicalUnavailable ? 'Not available' : 'Not added'),
                            onTap: () => _openAccountRoute(
                              context,
                              accountActive
                                  ? '/app/account/identity/name'
                                  : '/app/account/security',
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
                      if (gstDetails != null) ...[
                        _ProfileSection(
                          title: 'Buying details',
                          children: [
                            if (onOpenAddresses != null)
                              _ProfileDetail(
                                keyName: 'global-personal-profile-addresses',
                                icon: Icons.location_on_outlined,
                                label: 'Delivery addresses',
                                value: 'Choose or edit an address',
                                onTap: onOpenAddresses!,
                              ),
                            ExpansionTile(
                              key: const Key(
                                'global-personal-profile-invoice-details',
                              ),
                              shape: const Border(),
                              collapsedShape: const Border(),
                              iconColor: palette.accent,
                              leading: const Icon(
                                Icons.receipt_long_outlined,
                                size: 22,
                              ),
                              title: const Text(
                                'Invoice details',
                                style: TextStyle(fontSize: 15),
                              ),
                              subtitle: const Text(
                                'Personal or business billing',
                                style: TextStyle(fontSize: 12),
                              ),
                              children: [gstDetails!],
                            ),
                          ],
                        ),
                        const SizedBox(height: MoolSpacing.md),
                      ],
                      if (surfaceTone ==
                          GlobalProfileSurfaceTone.socialDark) ...[
                        _ProfileSection(
                          title: 'Plans & Workspaces',
                          children: [
                            _ProfileDetail(
                              keyName: 'global-personal-profile-plans',
                              icon: Icons.workspace_premium_outlined,
                              label: 'Plans & billing',
                              value: 'Upgrade plan',
                              onTap: () => _openAccountRoute(
                                context,
                                '/app/account/plans?scope=account',
                              ),
                            ),
                            _ProfileDetail(
                              keyName: 'global-personal-profile-workspaces',
                              icon: Icons.storefront_outlined,
                              label: 'My Workspaces',
                              value: 'Application or Store access',
                              onTap: () => _openAccountRoute(
                                context,
                                '/app/account/workspaces',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MoolSpacing.md),
                        _ProfileSection(
                          title: 'Account settings',
                          children: [
                            _ProfileDetail(
                              keyName: 'global-personal-profile-language',
                              icon: Icons.language_rounded,
                              label: 'Communication preference',
                              value: session.languageCode == 'hi'
                                  ? 'Hindi preferred · App screens: English'
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
                                  ? palette.accent
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  static void _openAccountRoute(BuildContext context, String route) {
    final profileLocation = GoRouterState.of(context).uri;
    final target = Uri.parse(route);
    context.push(
      Uri(
        path: target.path,
        queryParameters: {
          ...target.queryParameters,
          'return': profileLocation.toString(),
          if (profileLocation.queryParameters['surface'] == 'social')
            'surface': 'social',
        },
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
  const GlobalPersonalProfileNameEditorV2({
    required this.session,
    this.onSaveDisplayName,
    super.key,
  });

  final JourneySession session;

  /// PROFILE-B01 must supply an account/revision-bound writer. True means a
  /// confirmed write/readback, never an optimistic local device-snapshot save.
  final Future<bool> Function(String name)? onSaveDisplayName;

  @override
  State<GlobalPersonalProfileNameEditorV2> createState() =>
      _GlobalPersonalProfileNameEditorV2State();
}

class _GlobalPersonalProfileNameEditorV2State
    extends State<GlobalPersonalProfileNameEditorV2> {
  late final TextEditingController _controller = TextEditingController(
    text:
        (widget.session.isAuthenticated
            ? widget.session.accountIdentity?.displayName
            : null) ??
        '',
  );
  bool _saving = false;
  bool _loadingCanonical = false, _canonicalLoadFailed = false;
  String? _nameError;
  late final int? _openingGeneration;
  late final Object? _openingIdentity;
  late final Object? _openingAccountScope;
  bool get _sameAccount =>
      widget.session.isAuthenticated &&
      widget.session.navigationAuthenticationGeneration == _openingGeneration &&
      (_openingAccountScope != null
          ? widget.session.authenticatedBuyPersistenceIdentity ==
                _openingAccountScope
          : identical(widget.session.accountIdentity, _openingIdentity));

  @override
  void initState() {
    super.initState();
    _openingGeneration=widget.session.navigationAuthenticationGeneration;
    _openingIdentity=widget.session.accountIdentity;
    _openingAccountScope=widget.session.authenticatedBuyPersistenceIdentity;
    if (widget.session.accountProfileGateway != null) {
      _loadingCanonical = true;
      _controller.clear();
      unawaited(_loadCanonical());
    }
  }

  Future<void> _loadCanonical() async {
    final loaded=await widget.session.refreshAccountProfile();
    if (!mounted || !_sameAccount) return;
    setState(() {
      _loadingCanonical=false;
      _canonicalLoadFailed=!loaded;
      if (loaded) _controller.text=widget.session.accountIdentity?.displayName ?? '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _loadingCanonical || _canonicalLoadFailed ||
        !_sameAccount || widget.onSaveDisplayName == null) return;
    final name = _controller.text.trim();
    if (name.length < 2 || name.length > 60) {
      setState(
        () => _nameError = 'Enter a display name from 2 to 60 characters.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });
    var saved = false;
    try {
      saved = await widget.onSaveDisplayName!(name);
    } on Object {
      saved = false;
    }
    if (!mounted || !_sameAccount) return;
    setState(() {
      _saving = false;
      if (!saved)
        _nameError =
            'Could not save your name. Check your account and try again.';
    });
    if (saved) _leave();
  }

  void _leave() {
    // The editor owns a deterministic Profile return. Keyboard/local history
    // must not consume it or pop past Profile after an asynchronous save.
    final destination = globalProfileSafeReturnLocation(
      GoRouterState.of(context).uri.queryParameters['return'],
    );
    context.go(
      destination != null &&
              Uri.parse(destination).path == '/app/account/identity'
          ? destination
          : '/app/account/identity',
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) => PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        key: const Key('global-personal-profile-name-editor'),
        appBar: AppBar(
          leading: IconButton(
            key: const Key('global-personal-profile-name-back'),
            tooltip: 'Back',
            onPressed: _leave,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Display name'),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _loadingCanonical ? 'Loading your account name…' :
                          _canonicalLoadFailed ? 'Your name could not be loaded. Reopen Profile to try again.' :
                          widget.onSaveDisplayName == null
                              ? 'Account name updates are not available right now.'
                              : 'Use the name you want on your account.',
                          style: TextStyle(color: Color(0xFF5E6378)),
                        ),
                        const SizedBox(height: MoolSpacing.md),
                        TextField(
                          key: const Key('global-personal-profile-name-field'),
                          controller: _controller,
                          enabled: !_saving && _sameAccount,
                          readOnly: widget.onSaveDisplayName == null || _loadingCanonical || _canonicalLoadFailed,
                          autofocus: widget.onSaveDisplayName != null && !_loadingCanonical,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          maxLength: 60,
                          onSubmitted: (_) => _save(),
                          decoration: InputDecoration(
                            labelText: 'Display name',
                            hintText: 'Enter your name',
                            error: _nameError == null
                                ? null
                                : Text(_nameError!),
                          ),
                        ),
                        const Spacer(),
                        if (!_sameAccount)
                          const Text(
                            'Your account changed. Reopen Profile to edit your name.',
                          ),
                        FilledButton(
                          key: const Key('global-personal-profile-name-save'),
                          onPressed:
                              _saving ||
                                  _loadingCanonical || _canonicalLoadFailed ||
                                  !_sameAccount ||
                                  widget.onSaveDisplayName == null
                              ? null
                              : _save,
                          child: Text(
                            _saving ? 'Saving…' : 'Save display name',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
    final enlarged = MediaQuery.textScalerOf(context).scale(17) > 24;
    final avatar = Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .7)),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 27),
    );
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          key: const Key('global-personal-profile-hero-name'),
          maxLines: enlarged ? null : 1,
          overflow: enlarged ? TextOverflow.visible : TextOverflow.ellipsis,
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
          key: const Key('global-personal-profile-hero-detail'),
          maxLines: enlarged ? null : 2,
          overflow: enlarged ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .78),
            fontSize: 10,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final statusBadge = Container(
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
    );
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
              avatar,
              const SizedBox(width: MoolSpacing.sm),
              if (enlarged) const Spacer() else Expanded(child: identity),
              const SizedBox(width: MoolSpacing.xs),
              statusBadge,
            ],
          ),
          if (enlarged) ...[const SizedBox(height: MoolSpacing.sm), identity],
          const SizedBox(height: MoolSpacing.md),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Profile setup',
                  key: Key('global-personal-profile-hero-setup'),
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
                  key: const Key('global-personal-profile-hero-completion'),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
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
                child: Icon(icon, color: palette.ink, size: 22),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? palette.ink,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}
