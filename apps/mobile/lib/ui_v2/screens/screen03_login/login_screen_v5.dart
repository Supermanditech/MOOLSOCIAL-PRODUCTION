import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/journey01/journey_services.dart';
import '../../../features/journey01/journey_session.dart';
import 'screen03_frame_v2.dart';

/// Native successor for the founder-accepted Screen 03 visual v5.
///
/// The accepted v4 owner is immutable, so this file intentionally owns the
/// additive email-link presentation while reusing the locked Screen 03 frame.
typedef LegalUrlLauncher = Future<bool> Function(Uri uri);

class LoginScreenV5 extends StatefulWidget {
  const LoginScreenV5({
    required this.session,
    this.legalUrlLauncher,
    super.key,
  });

  final JourneySession session;
  final LegalUrlLauncher? legalUrlLauncher;

  @override
  State<LoginScreenV5> createState() => _LoginScreenV5State();
}

class _LoginScreenV5State extends State<LoginScreenV5> {
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  Timer? _resendTicker;

  @override
  void dispose() {
    _resendTicker?.cancel();
    _mobileController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> _startProvider(SocialAuthProvider provider) async {
    if (!widget.session.isSocialAuthProviderAvailable(provider)) {
      await _showProviderUnavailable(provider);
      return;
    }
    final completed = await widget.session.signInWithSocial(provider);
    if (!mounted || completed || widget.session.isReady) return;
    if (widget.session.socialAuthState == SocialAuthState.pending) return;
    await _showProviderRecovery(provider);
  }

  Future<void> _showProviderUnavailable(SocialAuthProvider provider) {
    return _showProviderMessage(
      title: '${_providerLabel(provider)} sign-in isn’t available',
      message: 'Choose another available sign-in method to continue.',
      allowRetry: false,
      provider: provider,
    );
  }

  Future<void> _openLegalUrl(Uri uri) async {
    var opened = false;
    try {
      opened = await (widget.legalUrlLauncher ?? _launchExternalLegalUrl)(uri);
    } on Object {
      opened = false;
    }
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This page could not be opened. Please try again.'),
      ),
    );
  }

  Widget _buildLegalCopy() => _LegalCopy(
    onTermsTap: () =>
        unawaited(_openLegalUrl(Uri.parse('https://moolsocial.com/terms/'))),
    onPrivacyTap: () =>
        unawaited(_openLegalUrl(Uri.parse('https://moolsocial.com/privacy/'))),
  );

  Future<void> _showProviderRecovery(SocialAuthProvider provider) {
    return _showProviderMessage(
      title: '${_providerLabel(provider)} sign-in wasn’t completed',
      message:
          widget.session.errorMessage ??
          'Try again or choose another sign-in method.',
      allowRetry: true,
      provider: provider,
    );
  }

  Future<void> _showProviderMessage({
    required String title,
    required String message,
    required bool allowRetry,
    required SocialAuthProvider provider,
  }) async {
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
              title,
              style: const TextStyle(
                color: Screen03Colors.navy,
                fontSize: 22,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              key: const Key('social-auth-message'),
              style: const TextStyle(
                color: Screen03Colors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (allowRetry)
              FilledButton(
                key: const Key('social-auth-retry'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _startProvider(provider);
                },
                style: _primaryButtonStyle,
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

  Future<void> _showMobileTarget() async {
    widget.session.clearSocialAuthResult();
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
        builder: (context, _) => Padding(
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
              const Text('Mobile OTP', style: Screen03Text.title),
              const SizedBox(height: 7),
              const Text(
                'Enter the mobile number you want to use for MoolSocial.',
                style: Screen03Text.body,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('phone-field'),
                controller: _mobileController,
                autofocus: true,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixText: '+91  ',
                  counterText: '',
                ),
              ),
              if (widget.session.errorMessage case final message?) ...[
                const SizedBox(height: 8),
                _ErrorText(message: message),
              ],
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('send-mobile-otp'),
                onPressed: widget.session.busy
                    ? null
                    : () async {
                        final sent = await widget.session.requestOtp(
                          _mobileController.text,
                        );
                        if (sent && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                style: _primaryButtonStyle,
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
        ),
      ),
    );
  }

  Future<void> _sendEmailLink() async {
    final sent = await widget.session.requestEmailLink(_emailController.text);
    if (sent) _startResendTicker();
  }

  Future<void> _resendEmailLink() async {
    final sent = await widget.session.resendEmailLink();
    if (sent) _startResendTicker();
  }

  void _startResendTicker() {
    _resendTicker?.cancel();
    _resendTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || widget.session.canResend) {
        timer.cancel();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Screen03FrameV2(
      screenKey: const Key('screen03-login-v5'),
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 32).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: _buildState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildState() {
    return switch (widget.session.emailLinkState) {
      EmailLinkState.idle => _buildMethodChooser(),
      EmailLinkState.entering || EmailLinkState.sending => _buildEmailEntry(),
      EmailLinkState.sent => _buildLinkSent(),
      EmailLinkState.awaitingEmail ||
      EmailLinkState.completing => _buildEmailConfirmation(),
      EmailLinkState.invalid ||
      EmailLinkState.expired ||
      EmailLinkState.used ||
      EmailLinkState.failed => _buildEmailRecovery(),
    };
  }

  Widget _buildMethodChooser() {
    final availableProviders = SocialAuthProvider.values
        .where(widget.session.isSocialAuthProviderAvailable)
        .toList(growable: false);
    final socialCreate =
        widget.session.authenticationPurpose ==
        JourneyAuthenticationPurpose.socialCreate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.session.canCancelSignIn)
          IconButton.outlined(
            key: const Key('sign-in-context-back'),
            tooltip: 'Back',
            onPressed: widget.session.cancelSignIn,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        if (widget.session.canCancelSignIn) const SizedBox(height: 8),
        Text(
          socialCreate ? 'Create on MoolSocial' : 'Sign in',
          style: Screen03Text.title,
        ),
        const SizedBox(height: 8),
        Text(
          socialCreate
              ? 'Sign in to create a post. After sign-in, you will return to Create with your intent retained.'
              : 'Choose one method to continue.',
          key: socialCreate ? const Key('sign-in-social-create-context') : null,
          style: Screen03Text.body,
        ),
        const SizedBox(height: 14),
        if (availableProviders.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Screen03Colors.navy),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SIGN-IN METHODS', style: Screen03Text.cardLabel),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.32,
                  children: [
                    for (final provider in availableProviders)
                      _ProviderButton(
                        provider: provider,
                        available: true,
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
        ],
        _MethodButton(
          key: const Key('email-link-method'),
          title: 'Email link',
          subtitle: widget.session.emailLinkAvailable
              ? 'Use any email address'
              : 'Choose another sign-in method',
          icon: const _EmailArtwork(),
          onTap: widget.session.busy || !widget.session.emailLinkAvailable
              ? null
              : widget.session.openEmailLinkEntry,
        ),
        if (widget.session.mobileOtpAvailable) ...[
          const SizedBox(height: 9),
          _MethodButton(
            key: const Key('mobile-otp-method'),
            title: 'Mobile OTP',
            subtitle: 'Use mobile number',
            icon: const _MobileArtwork(),
            onTap: widget.session.busy ? null : _showMobileTarget,
          ),
        ],
        const SizedBox(height: 24),
        _buildLegalCopy(),
      ],
    );
  }

  Widget _buildEmailEntry() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SECURE EMAIL SIGN-IN', style: Screen03Text.cardLabel),
          const SizedBox(height: 12),
          const Text('Enter your email', style: Screen03Text.title),
          const SizedBox(height: 5),
          const Text(
            'We’ll email you a secure link that signs you in.',
            style: Screen03Text.body,
          ),
          const SizedBox(height: 15),
          const Text(
            'Email address',
            style: TextStyle(
              color: Screen03Colors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('email-link-field'),
            controller: _emailController,
            autofocus: true,
            enabled: !widget.session.busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 254,
            decoration: _emailDecoration('name@example.com'),
            onSubmitted: widget.session.busy ? null : (_) => _sendEmailLink(),
          ),
          const SizedBox(height: 5),
          const Text(
            'Open the link on this device for the quickest return.',
            style: TextStyle(
              color: Screen03Colors.muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          if (widget.session.errorMessage case final message?) ...[
            const SizedBox(height: 8),
            _ErrorText(message: message),
          ],
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('send-email-link'),
            onPressed: widget.session.busy ? null : _sendEmailLink,
            style: _primaryButtonStyle,
            child: Text(
              widget.session.busy ? 'Sending…' : 'Send sign-in link',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(
            key: const Key('email-link-choose-another'),
            onPressed: widget.session.busy
                ? null
                : widget.session.cancelEmailLink,
            child: const Text('Choose another method'),
          ),
          const SizedBox(height: 24),
          _buildLegalCopy(),
        ],
      ),
    );
  }

  Widget _buildLinkSent() {
    final seconds = widget.session.resendSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MessageIcon(icon: Icons.mail_outline_rounded),
        const SizedBox(height: 10),
        const Text('LINK SENT', style: Screen03Text.cardLabel),
        const SizedBox(height: 10),
        const Text('Check your email', style: Screen03Text.title),
        const SizedBox(height: 10),
        const Text(
          'We sent a secure sign-in link to',
          style: Screen03Text.body,
        ),
        const SizedBox(height: 4),
        Text(
          widget.session.maskedEmailLinkDestination,
          key: const Key('masked-email-link-destination'),
          style: const TextStyle(
            color: Screen03Colors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap the link in the email to return and finish signing in.',
          style: Screen03Text.body,
        ),
        const SizedBox(height: 16),
        const _SecurityNote(),
        const SizedBox(height: 14),
        FilledButton(
          key: const Key('resend-email-link'),
          onPressed: widget.session.canResend ? _resendEmailLink : null,
          style: _primaryButtonStyle,
          child: Text(
            seconds == 0
                ? 'Resend sign-in link'
                : 'Resend available in ${seconds}s',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        if (widget.session.errorMessage case final message?) ...[
          const SizedBox(height: 8),
          _ErrorText(message: message),
        ],
        TextButton(
          key: const Key('email-link-different-email'),
          onPressed: widget.session.busy
              ? null
              : widget.session.useDifferentEmailForLink,
          child: const Text('Use a different email'),
        ),
        TextButton(
          key: const Key('email-link-sent-choose-another'),
          onPressed: widget.session.busy
              ? null
              : widget.session.cancelEmailLink,
          child: const Text('Choose another method'),
        ),
        const SizedBox(height: 24),
        _buildLegalCopy(),
      ],
    );
  }

  Widget _buildEmailConfirmation() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ONE MORE CHECK', style: Screen03Text.cardLabel),
          const SizedBox(height: 12),
          const Text('Confirm your email', style: Screen03Text.title),
          const SizedBox(height: 6),
          const Text(
            'Enter the same email that received the link to finish signing in.',
            style: Screen03Text.body,
          ),
          const SizedBox(height: 15),
          const Text(
            'Email address',
            style: TextStyle(
              color: Screen03Colors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('email-link-confirm-field'),
            controller: _confirmEmailController,
            autofocus: true,
            enabled: !widget.session.busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 254,
            decoration: _emailDecoration('name@example.com'),
            onSubmitted: widget.session.busy
                ? null
                : (_) => widget.session.completeEmailLink(
                    _confirmEmailController.text,
                  ),
          ),
          const SizedBox(height: 5),
          const Text(
            'This protects your account if a link is forwarded by mistake.',
            style: TextStyle(
              color: Screen03Colors.muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          if (widget.session.errorMessage case final message?) ...[
            const SizedBox(height: 8),
            _ErrorText(message: message),
          ],
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('complete-email-link'),
            onPressed: widget.session.busy
                ? null
                : () => widget.session.completeEmailLink(
                    _confirmEmailController.text,
                  ),
            style: _primaryButtonStyle,
            child: Text(
              widget.session.busy ? 'Finishing…' : 'Finish signing in',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(
            key: const Key('email-link-confirm-choose-another'),
            onPressed: widget.session.busy
                ? null
                : widget.session.cancelEmailLink,
            child: const Text('Choose another method'),
          ),
          const SizedBox(height: 24),
          _buildLegalCopy(),
        ],
      ),
    );
  }

  Widget _buildEmailRecovery() {
    final state = widget.session.emailLinkState;
    final expired =
        state == EmailLinkState.expired || state == EmailLinkState.used;
    final title = expired
        ? 'This link has expired'
        : state == EmailLinkState.invalid
        ? 'This link isn’t valid'
        : 'Email sign-in isn’t available';
    final body =
        widget.session.errorMessage ??
        (expired
            ? 'Sign-in links can be used only once and expire for your security.'
            : 'Choose another method or request a new link.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MessageIcon(icon: Icons.schedule_rounded),
        const SizedBox(height: 10),
        const Text('TRY AGAIN', style: Screen03Text.cardLabel),
        const SizedBox(height: 10),
        Text(title, style: Screen03Text.title),
        const SizedBox(height: 10),
        Text(
          body,
          key: const Key('email-link-recovery-message'),
          style: Screen03Text.body,
        ),
        const SizedBox(height: 18),
        FilledButton(
          key: const Key('email-link-new-link'),
          onPressed: widget.session.busy
              ? null
              : widget.session.useDifferentEmailForLink,
          style: _primaryButtonStyle,
          child: const Text(
            'Send a new link',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(
          key: const Key('email-link-recovery-choose-another'),
          onPressed: widget.session.busy
              ? null
              : widget.session.cancelEmailLink,
          child: const Text('Choose another method'),
        ),
        const SizedBox(height: 24),
        _buildLegalCopy(),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.available,
    required this.pending,
    required this.enabled,
    required this.onTap,
  });

  final SocialAuthProvider provider;
  final bool available;
  final bool pending;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _providerLabel(provider);
    return Semantics(
      button: true,
      enabled: available && enabled,
      label: available
          ? 'Continue with $label'
          : '$label sign-in is not available',
      child: InkWell(
        key: Key('screen03-v5-provider-${provider.name}'),
        onTap: available && enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: available ? 1 : .62,
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

class _MessageIcon extends StatelessWidget {
  const _MessageIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Screen03Colors.pale,
          shape: BoxShape.circle,
          border: Border.all(color: Screen03Colors.navy),
        ),
        child: Icon(icon, color: Screen03Colors.navy, size: 28),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Screen03Colors.green),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: Screen03Colors.green),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Never share or forward your sign-in link. MoolSocial will never ask you for the link.',
              style: TextStyle(
                color: Screen03Colors.navy,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      key: const Key('email-link-error'),
      style: const TextStyle(
        color: Screen03Colors.danger,
        fontSize: 12,
        height: 1.35,
      ),
    );
  }
}

class _LegalCopy extends StatelessWidget {
  const _LegalCopy({required this.onTermsTap, required this.onPrivacyTap});

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Screen03Colors.muted,
      fontSize: 9,
      height: 1.3,
    );
    final linkStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      minimumSize: const Size(0, 30),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: textStyle.copyWith(
        fontWeight: FontWeight.w800,
        decoration: TextDecoration.underline,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'By continuing, you agree to MoolSocial’s ',
              style: textStyle,
            ),
            TextButton(
              key: const Key('screen03-terms-link'),
              onPressed: onTermsTap,
              style: linkStyle,
              child: const Text('Terms'),
            ),
            const Text(' and acknowledge its ', style: textStyle),
            TextButton(
              key: const Key('screen03-privacy-link'),
              onPressed: onPrivacyTap,
              style: linkStyle,
              child: const Text('Privacy Policy'),
            ),
            const Text('.', style: textStyle),
          ],
        ),
      ),
    );
  }
}

Future<bool> _launchExternalLegalUrl(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

InputDecoration _emailDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Screen03Colors.navy),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Screen03Colors.saffron, width: 3),
    ),
  );
}

final ButtonStyle _primaryButtonStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(50),
  backgroundColor: Screen03Colors.navy,
  disabledBackgroundColor: const Color(0xFFCBC9E8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

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
