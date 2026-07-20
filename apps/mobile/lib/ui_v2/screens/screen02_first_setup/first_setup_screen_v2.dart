import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/journey01/journey_services.dart';
import '../../../features/journey01/journey_session.dart';

class FirstSetupScreenV2 extends StatefulWidget {
  const FirstSetupScreenV2({required this.session, super.key});

  final JourneySession session;

  @override
  State<FirstSetupScreenV2> createState() => _FirstSetupScreenV2State();
}

enum _SetupView {
  consent,
  preparing,
  resolved,
  locationServicesOff,
  permissionNotAllowed,
  unavailable,
}

class _FirstSetupScreenV2State extends State<FirstSetupScreenV2>
    with WidgetsBindingObserver {
  _SetupView _view = _SetupView.consent;
  bool _recheckAfterSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final phoneLanguage = Localizations.localeOf(context).languageCode;
      widget.session.selectLanguage(phoneLanguage == 'hi' ? 'hi' : 'en');
      if (widget.session.currentAreaPrimary != null) {
        setState(() => _view = _SetupView.resolved);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_recheckAfterSettings) return;
    _recheckAfterSettings = false;
    _resolveCurrentArea(requestPermission: false);
  }

  Future<void> _resolveCurrentArea({bool requestPermission = true}) async {
    if (widget.session.resolvingCurrentArea) return;
    setState(() => _view = _SetupView.preparing);
    final resolved = await widget.session.resolveCurrentArea(
      requestPermission: requestPermission,
    );
    if (!mounted) return;
    setState(() {
      _view = resolved
          ? _SetupView.resolved
          : switch (widget.session.currentAreaFailureReason) {
              CurrentAreaFailureReason.locationServicesOff =>
                _SetupView.locationServicesOff,
              CurrentAreaFailureReason.permissionNotAllowed ||
              CurrentAreaFailureReason.permissionPermanentlyNotAllowed =>
                _SetupView.permissionNotAllowed,
              _ => _SetupView.unavailable,
            };
    });
  }

  Future<void> _openLocationServicesSettings() async {
    _recheckAfterSettings = true;
    try {
      await widget.session.openLocationServicesSettings();
    } on Object {
      _recheckAfterSettings = false;
      if (mounted) setState(() => _view = _SetupView.unavailable);
    }
  }

  Future<void> _openAppSettings() async {
    _recheckAfterSettings = true;
    try {
      await widget.session.openCurrentAreaAppSettings();
    } on Object {
      _recheckAfterSettings = false;
      if (mounted) setState(() => _view = _SetupView.unavailable);
    }
  }

  Future<void> _continueWithLocation() async {
    await _completeSetup();
  }

  Future<void> _continueForNow() async {
    widget.session.changeAreaLater();
    await _completeSetup();
  }

  Future<void> _completeSetup() async {
    final completed = await widget.session.completeSetup();
    if (!mounted || completed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.session.errorMessage ??
              'We couldn’t save your choice. Please try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _SetupColors.navy,
        systemNavigationBarColor: _SetupColors.navy,
      ),
      child: Scaffold(
        key: const Key('screen02-v4'),
        backgroundColor: _SetupColors.navy,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _BrandHeader(),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: ColoredBox(
                    color: Colors.white,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _buildView(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildView() {
    return switch (_view) {
      _SetupView.consent => _ConsentView(
        key: const ValueKey('consent'),
        onAllow: () => _resolveCurrentArea(),
        onContinue: _continueForNow,
      ),
      _SetupView.preparing => const _PreparingView(key: ValueKey('preparing')),
      _SetupView.resolved => _ResolvedView(
        key: const ValueKey('resolved'),
        session: widget.session,
        onContinue: _continueWithLocation,
      ),
      _SetupView.locationServicesOff => _LocationServicesOffView(
        key: const ValueKey('location-services-off'),
        onOpenSettings: _openLocationServicesSettings,
        onContinue: _continueForNow,
      ),
      _SetupView.permissionNotAllowed => _PermissionNotAllowedView(
        key: const ValueKey('permission-not-allowed'),
        onOpenSettings: _openAppSettings,
        onContinue: _continueForNow,
      ),
      _SetupView.unavailable => _UnavailableView(
        key: const ValueKey('unavailable'),
        onRetry: () => _resolveCurrentArea(),
        onContinue: _continueForNow,
      ),
    };
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 116),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(27, 20, 27, 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MoolSocial',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const SizedBox(
                  width: 128,
                  height: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: ColoredBox(color: _SetupColors.saffron)),
                      Expanded(child: ColoredBox(color: Colors.white)),
                      Expanded(child: ColoredBox(color: _SetupColors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                'India Ka Socio Commerce App',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentView extends StatelessWidget {
  const _ConsentView({
    required this.onAllow,
    required this.onContinue,
    super.key,
  });

  final Future<void> Function() onAllow;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('See what’s around you', style: _SetupText.title),
          const SizedBox(height: 8),
          const Text(
            'Allow location to find products, services and earning '
            'opportunities near you.',
            style: _SetupText.body,
          ),
          const SizedBox(height: 16),
          const _LanguageSummary(),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(15, 17, 15, 14),
            decoration: BoxDecoration(
              color: _SetupColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your location stays in your control',
                  style: _SetupText.whiteCardTitle,
                ),
                const SizedBox(height: 7),
                const Text(
                  'MoolSocial uses it only to make nearby results more useful.',
                  style: _SetupText.whiteBody,
                ),
                const SizedBox(height: 13),
                _LocationActionButton(
                  key: const Key('setup-v4-allow-location'),
                  title: 'Allow location',
                  hint: 'Your phone will ask for permission next',
                  onPressed: onAllow,
                ),
                const SizedBox(height: 10),
                _WhiteTextButton(
                  key: const Key('setup-v4-continue-for-now'),
                  label: 'Continue for now',
                  onPressed: onContinue,
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'After login, choose your permanent serviceable area '
                    'from your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparingView extends StatelessWidget {
  const _PreparingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your area', style: _SetupText.kicker),
          SizedBox(height: 6),
          Text('Getting your area ready', style: _SetupText.title),
          SizedBox(height: 8),
          Text(
            'Preparing nearby products, services and earning opportunities.',
            style: _SetupText.body,
          ),
          SizedBox(height: 22),
          LinearProgressIndicator(
            color: _SetupColors.green,
            backgroundColor: _SetupColors.paleGreen,
          ),
          SizedBox(height: 12),
          Center(child: Text('Almost ready', style: _SetupText.cardTitle)),
        ],
      ),
    );
  }
}

class _ResolvedView extends StatelessWidget {
  const _ResolvedView({
    required this.session,
    required this.onContinue,
    super.key,
  });

  final JourneySession session;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final primary = session.currentAreaPrimary ?? '';
    final secondary =
        session.currentAreaSecondary ?? 'Nearby results are ready';
    final city = secondary.split(',').first.trim();
    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You’re in $primary', style: _SetupText.title),
          const SizedBox(height: 8),
          Text(secondary, style: _SetupText.body),
          const SizedBox(height: 16),
          const _LanguageSummary(),
          const SizedBox(height: 12),
          Container(
            key: const Key('setup-v4-resolved-location'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
            decoration: BoxDecoration(
              color: _SetupColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore what’s around you',
                  style: _SetupText.whiteCardTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'See nearby products, services and earning opportunities '
                  'in $primary and $city.',
                  style: _SetupText.whiteBody,
                ),
                const SizedBox(height: 12),
                _LocationActionButton(
                  key: const Key('setup-v4-continue'),
                  title: session.busy ? 'Saving…' : 'Continue',
                  hint: 'Use $primary for nearby results',
                  onPressed: session.busy ? null : onContinue,
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'After login, choose your permanent serviceable area '
                    'from your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationServicesOffView extends StatelessWidget {
  const _LocationServicesOffView({
    required this.onOpenSettings,
    required this.onContinue,
    super.key,
  });

  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return _DecisionView(
      kicker: 'Location Services',
      title: 'Turn on Location Services',
      copy:
          'Location Services are off on your phone. Turn them on to find '
          'products, services and earning opportunities near you.',
      cardTitle: 'You stay in control',
      cardBody:
          'After you turn it on, return to MoolSocial and your nearby area '
          'will appear here.',
      primaryKey: const Key('setup-v4-open-location-settings'),
      primaryLabel: 'Open phone settings',
      onPrimary: onOpenSettings,
      secondaryKey: const Key('setup-v4-continue-for-now'),
      secondaryLabel: 'Continue for now',
      onSecondary: onContinue,
    );
  }
}

class _PermissionNotAllowedView extends StatelessWidget {
  const _PermissionNotAllowedView({
    required this.onOpenSettings,
    required this.onContinue,
    super.key,
  });

  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return _DecisionView(
      kicker: 'Location access',
      title: 'Allow location in phone settings',
      copy:
          'Location access is off for MoolSocial. Allow it in app settings '
          'to see what’s near you.',
      cardTitle: 'Your choice can be changed anytime',
      cardBody:
          'MoolSocial uses location to show nearby products, services and '
          'opportunities.',
      primaryKey: const Key('setup-v4-open-app-settings'),
      primaryLabel: 'Open app settings',
      onPrimary: onOpenSettings,
      secondaryKey: const Key('setup-v4-continue-for-now'),
      secondaryLabel: 'Continue for now',
      onSecondary: onContinue,
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({
    required this.onRetry,
    required this.onContinue,
    super.key,
  });

  final Future<void> Function() onRetry;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return _DecisionView(
      kicker: 'Your location',
      title: 'We couldn’t get your location',
      copy:
          'Try again or continue to sign in. After login, choose your '
          'permanent serviceable area from your account.',
      cardTitle: 'You can keep moving',
      cardBody: 'Sign-in and access to MoolSocial will not be blocked.',
      primaryKey: const Key('setup-v4-retry'),
      primaryLabel: 'Try again',
      onPrimary: onRetry,
      secondaryKey: const Key('setup-v4-continue-for-now'),
      secondaryLabel: 'Continue for now',
      onSecondary: onContinue,
    );
  }
}

class _DecisionView extends StatelessWidget {
  const _DecisionView({
    required this.kicker,
    required this.title,
    required this.copy,
    required this.cardTitle,
    required this.cardBody,
    required this.primaryKey,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryKey,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String kicker;
  final String title;
  final String copy;
  final String cardTitle;
  final String cardBody;
  final Key primaryKey;
  final String primaryLabel;
  final Future<void> Function() onPrimary;
  final Key secondaryKey;
  final String secondaryLabel;
  final Future<void> Function() onSecondary;

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker, style: _SetupText.kicker),
          const SizedBox(height: 6),
          Text(title, style: _SetupText.title),
          const SizedBox(height: 8),
          Text(copy, style: _SetupText.body),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _SetupColors.warning,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cardTitle, style: _SetupText.cardTitle),
                const SizedBox(height: 5),
                Text(cardBody, style: _SetupText.body),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            key: primaryKey,
            label: primaryLabel,
            onPressed: onPrimary,
          ),
          const SizedBox(height: 8),
          _OutlineButton(
            key: secondaryKey,
            label: secondaryLabel,
            onPressed: onSecondary,
          ),
        ],
      ),
    );
  }
}

class _LanguageSummary extends StatelessWidget {
  const _LanguageSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('setup-v4-language-summary'),
      constraints: const BoxConstraints(minHeight: 57),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _SetupColors.paleGreen,
        border: Border.all(color: _SetupColors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: _SetupColors.green,
            child: Text(
              'A',
              style: TextStyle(
                color: _SetupColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('English', style: _SetupText.languageTitle),
                SizedBox(height: 2),
                Text(
                  'Change language anytime in Settings',
                  style: _SetupText.languageHint,
                ),
              ],
            ),
          ),
          Text(
            '✓',
            style: TextStyle(
              color: _SetupColors.green,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationActionButton extends StatelessWidget {
  const _LocationActionButton({
    required this.title,
    required this.hint,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.red, size: 31),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _SetupText.whiteButtonTitle),
                  const SizedBox(height: 3),
                  Text(hint, style: _SetupText.whiteButtonHint),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteTextButton extends StatelessWidget {
  const _WhiteTextButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _SetupColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        child: Text(label),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _SetupColors.navy,
          side: const BorderSide(color: _SetupColors.navy),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        child: Text(label),
      ),
    );
  }
}

class _PagePadding extends StatelessWidget {
  const _PagePadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 17, 26, 24),
      child: child,
    );
  }
}

abstract final class _SetupColors {
  static const navy = Color(0xFF080090);
  static const green = Color(0xFF079216);
  static const saffron = Color(0xFFFFA51A);
  static const paleGreen = Color(0xFFF1FAF1);
  static const warning = Color(0xFFFFF3D6);
  static const muted = Color(0xFF4C4C62);
}

abstract final class _SetupText {
  static const title = TextStyle(
    color: _SetupColors.navy,
    fontSize: 25,
    height: 1.06,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.55,
  );
  static const body = TextStyle(
    color: _SetupColors.muted,
    fontSize: 11,
    height: 1.35,
  );
  static const kicker = TextStyle(
    color: _SetupColors.green,
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.2,
  );
  static const cardTitle = TextStyle(
    color: _SetupColors.navy,
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );
  static const whiteCardTitle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    height: 1.15,
    fontWeight: FontWeight.w900,
  );
  static const whiteBody = TextStyle(
    color: Colors.white,
    fontSize: 11,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );
  static const whiteButtonTitle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
  static const whiteButtonHint = TextStyle(
    color: Colors.white,
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );
  static const languageTitle = TextStyle(
    color: _SetupColors.navy,
    fontSize: 11,
    fontWeight: FontWeight.w900,
  );
  static const languageHint = TextStyle(color: _SetupColors.navy, fontSize: 9);
}
