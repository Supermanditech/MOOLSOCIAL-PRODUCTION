import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design/mool_theme.dart';
import '../journey_session.dart';
import '../widgets/journey_frame.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({required this.session, super.key});

  final JourneySession session;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const _socialAuthEnabled = bool.fromEnvironment('ENABLE_SOCIAL_AUTH');
  static const _emailAuthEnabled = bool.fromEnvironment('ENABLE_EMAIL_AUTH');

  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _showUnavailableSignIn(String method) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$method sign-in is unavailable',
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Continue securely with your mobile number.',
              style: TextStyle(color: MoolColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('use-mobile-instead'),
              onPressed: () {
                Navigator.pop(sheetContext);
                _openMobileOtp();
              },
              child: const Text('Use mobile number'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMobileOtp() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: widget.session,
          builder: (context, _) => Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              12,
              18,
              MediaQuery.viewInsetsOf(context).bottom + 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7D9E8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Mobile OTP',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 24,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Enter the mobile number you want to use for MoolSocial.',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 13,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('phone-field'),
                  controller: _phoneController,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixText: '+91  ',
                    counterText: '',
                  ),
                ),
                if (widget.session.errorMessage case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    key: const Key('sign-in-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('send-otp'),
                  onPressed: widget.session.busy
                      ? null
                      : () => widget.session.requestOtp(_phoneController.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: MoolColors.navy,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    widget.session.busy ? 'Sending…' : 'Continue with OTP',
                  ),
                ),
                TextButton(
                  onPressed: widget.session.busy
                      ? null
                      : () => Navigator.pop(sheetContext),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return JourneyFrame(
      eyebrow: '',
      title: 'Sign in',
      description: 'Choose one method to continue.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_socialAuthEnabled) ...[
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: MoolColors.navy),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CONTINUE WITH',
                    style: TextStyle(
                      color: MoolColors.success,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final provider in const [
                        ('Google', _ProviderKind.google),
                        ('Apple', _ProviderKind.apple),
                        ('X', _ProviderKind.x),
                        ('Instagram', _ProviderKind.instagram),
                        ('Facebook', _ProviderKind.facebook),
                      ])
                        _ProviderButton(
                          label: provider.$1,
                          kind: provider.$2,
                          onTap: () => _showUnavailableSignIn(provider.$1),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
          ],
          if (_emailAuthEnabled) ...[
            _MethodButton(
              key: const Key('email-otp-method'),
              title: 'Email OTP',
              subtitle: 'Use any email address',
              icon: const _EmailArtwork(),
              onTap: () => _showUnavailableSignIn('Email OTP'),
            ),
            const SizedBox(height: 9),
          ],
          _MethodButton(
            key: const Key('mobile-otp-method'),
            title: 'Mobile OTP',
            subtitle: 'Use mobile number',
            icon: const _MobileArtwork(),
            onTap: _openMobileOtp,
          ),
        ],
      ),
    );
  }
}

enum _ProviderKind { google, apple, x, instagram, facebook }

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.kind,
    required this.onTap,
  });

  final String label;
  final _ProviderKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue with $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 58,
          child: Column(
            children: [
              _ProviderIcon(kind: kind),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.kind});

  final _ProviderKind kind;

  @override
  Widget build(BuildContext context) {
    final background = switch (kind) {
      _ProviderKind.apple || _ProviderKind.x => Colors.black,
      _ProviderKind.facebook => const Color(0xFF1877F2),
      _ProviderKind.instagram => null,
      _ProviderKind.google => Colors.white,
    };
    final gradient = kind == _ProviderKind.instagram
        ? const RadialGradient(
            center: Alignment(-.65, 1),
            radius: 1.3,
            colors: [
              Color(0xFFFEDA75),
              Color(0xFFFA7E1E),
              Color(0xFFD62976),
              Color(0xFF962FBF),
              Color(0xFF4F5BD5),
            ],
          )
        : null;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        gradient: gradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: kind == _ProviderKind.google
              ? const Color(0x24000080)
              : Colors.transparent,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x21000080),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: SvgPicture.asset(
        switch (kind) {
          _ProviderKind.google => 'assets/prototype/provider-google.svg',
          _ProviderKind.apple => 'assets/prototype/provider-apple.svg',
          _ProviderKind.x => 'assets/prototype/provider-x.svg',
          _ProviderKind.instagram => 'assets/prototype/provider-instagram.svg',
          _ProviderKind.facebook => 'assets/prototype/provider-facebook.svg',
        },
        width: 25,
        height: 25,
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            border: Border.all(color: MoolColors.navy),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(width: 42, height: 42, child: Center(child: icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: MoolColors.navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailArtwork extends StatelessWidget {
  const _EmailArtwork();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.mail_rounded, color: Color(0xFFEA4335), size: 31),
        Positioned(
          left: 5,
          bottom: 7,
          child: Icon(Icons.change_history, color: Color(0xFF34A853), size: 12),
        ),
      ],
    );
  }
}

class _MobileArtwork extends StatelessWidget {
  const _MobileArtwork();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.phone_android_rounded,
      color: MoolColors.success,
      size: 31,
    );
  }
}
