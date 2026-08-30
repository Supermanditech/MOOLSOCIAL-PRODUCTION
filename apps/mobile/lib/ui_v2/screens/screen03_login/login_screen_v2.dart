import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../features/journey01/journey_services.dart';
import '../../../features/journey01/journey_session.dart';
import 'screen03_frame_v2.dart';

class LoginScreenV2 extends StatefulWidget {
  const LoginScreenV2({required this.session, super.key});

  final JourneySession session;

  @override
  State<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends State<LoginScreenV2> {
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _startProvider(SocialAuthProvider provider) async {
    final completed = await widget.session.signInWithSocial(provider);
    if (!mounted || completed || widget.session.isReady) return;
    await _showProviderRecovery(provider);
  }

  Future<void> _showProviderRecovery(SocialAuthProvider provider) async {
    final label = _providerLabel(provider);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$label sign-in wasn’t completed',
              style: const TextStyle(
                color: Screen03Colors.navy,
                fontSize: 22,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              widget.session.errorMessage ??
                  'Try again or choose another sign-in method.',
              key: const Key('social-auth-message'),
              style: const TextStyle(
                color: Screen03Colors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('social-auth-retry'),
              onPressed: () {
                Navigator.pop(sheetContext);
                _startProvider(provider);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: Screen03Colors.navy,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton(
              key: const Key('social-auth-change-method'),
              onPressed: () {
                widget.session.clearSocialAuthResult();
                Navigator.pop(sheetContext);
              },
              child: const Text('Choose another method'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOtpTarget(OtpChannel channel) async {
    widget.session.clearSocialAuthResult();
    final controller = channel == OtpChannel.mobile
        ? _mobileController
        : _emailController;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          final isMobile = channel == OtpChannel.mobile;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
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
                Text(
                  isMobile ? 'Mobile OTP' : 'Email OTP',
                  style: const TextStyle(
                    color: Screen03Colors.navy,
                    fontSize: 24,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isMobile
                      ? 'Enter the mobile number you want to use for MoolSocial.'
                      : 'Enter the email address you want to use for MoolSocial.',
                  style: const TextStyle(
                    color: Screen03Colors.navy,
                    fontSize: 13,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: Key(isMobile ? 'phone-field' : 'email-field'),
                  controller: controller,
                  autofocus: true,
                  keyboardType: isMobile
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  autofillHints: isMobile
                      ? const [AutofillHints.telephoneNumber]
                      : const [AutofillHints.email],
                  maxLength: isMobile ? 10 : 254,
                  inputFormatters: isMobile
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : null,
                  decoration: InputDecoration(
                    labelText: isMobile ? 'Mobile number' : 'Email address',
                    prefixText: isMobile ? '+91  ' : null,
                    counterText: '',
                  ),
                ),
                if (widget.session.errorMessage case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    key: const Key('sign-in-error'),
                    style: const TextStyle(
                      color: Screen03Colors.danger,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('send-otp'),
                  onPressed: widget.session.busy
                      ? null
                      : () async {
                          final sent = isMobile
                              ? await widget.session.requestOtp(controller.text)
                              : await widget.session.requestEmailOtp(
                                  controller.text,
                                );
                          if (sent && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Screen03Colors.navy,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    widget.session.busy ? 'Sending…' : 'Continue with OTP',
                    style: const TextStyle(fontWeight: FontWeight.w900),
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Screen03FrameV2(
      screenKey: const Key('screen03-login-v2'),
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sign in', style: Screen03Text.title),
              const SizedBox(height: 8),
              const Text(
                'Choose one method to continue.',
                style: Screen03Text.body,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Screen03Colors.navy),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SOCIAL ACCOUNT', style: Screen03Text.cardLabel),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.08,
                      children: [
                        for (final provider in SocialAuthProvider.values)
                          _ProviderButton(
                            provider: provider,
                            pending:
                                widget.session.busy &&
                                widget.session.socialAuthProvider == provider,
                            enabled: !widget.session.busy,
                            onTap: () => _startProvider(provider),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              _MethodButton(
                key: const Key('email-otp-method'),
                title: 'Email OTP',
                subtitle: 'Use any email address',
                icon: const _EmailArtwork(),
                onTap: widget.session.busy
                    ? null
                    : () => _showOtpTarget(OtpChannel.email),
              ),
              const SizedBox(height: 9),
              _MethodButton(
                key: const Key('mobile-otp-method'),
                title: 'Mobile OTP',
                subtitle: 'Use mobile number',
                icon: const _MobileArtwork(),
                onTap: widget.session.busy
                    ? null
                    : () => _showOtpTarget(OtpChannel.mobile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.pending,
    required this.enabled,
    required this.onTap,
  });

  final SocialAuthProvider provider;
  final bool pending;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _providerLabel(provider);
    return Semantics(
      button: true,
      label: 'Continue with $label',
      child: InkWell(
        key: Key('screen03-provider-${provider.name}'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProviderIcon(provider: provider, pending: pending),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Screen03Colors.navy,
                fontSize: 10,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.provider, required this.pending});

  final SocialAuthProvider provider;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final background = switch (provider) {
      SocialAuthProvider.apple || SocialAuthProvider.x => Colors.black,
      SocialAuthProvider.facebook => const Color(0xFF1877F2),
      SocialAuthProvider.instagram => null,
      _ => Colors.white,
    };
    final gradient = provider == SocialAuthProvider.instagram
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
    final borderColor = switch (provider) {
      SocialAuthProvider.apple || SocialAuthProvider.x => Colors.black,
      SocialAuthProvider.facebook => const Color(0xFF1877F2),
      SocialAuthProvider.instagram => const Color(0xFFDF3F8F),
      SocialAuthProvider.youtube => const Color(0xFFFF0033),
      SocialAuthProvider.google => Screen03Colors.borderSoft,
    };
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        gradient: gradient,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x21000080),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: pending
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Screen03Colors.green,
              ),
            )
          : SvgPicture.asset(
              'assets/prototype/provider-${provider.name}.svg',
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            border: Border.all(color: Screen03Colors.navy),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(width: 42, height: 38, child: Center(child: icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Screen03Colors.navy,
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Screen03Colors.navy,
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
                  color: Screen03Colors.navy,
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
          bottom: 4,
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
      color: Screen03Colors.green,
      size: 31,
    );
  }
}

String _providerLabel(SocialAuthProvider provider) {
  return switch (provider) {
    SocialAuthProvider.google => 'Google',
    SocialAuthProvider.youtube => 'YouTube',
    SocialAuthProvider.apple => 'Apple',
    SocialAuthProvider.x => 'X',
    SocialAuthProvider.instagram => 'Instagram',
    SocialAuthProvider.facebook => 'Facebook',
  };
}
