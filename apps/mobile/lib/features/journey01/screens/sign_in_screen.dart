import 'package:flutter/material.dart';

import '../journey_session.dart';
import '../widgets/journey_frame.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({required this.session, super.key});

  final JourneySession session;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JourneyFrame(
      eyebrow: 'Secure account',
      title: 'Sign in once. Use every MoolSocial service.',
      description:
          'Mobile OTP is the first launch method. Google and Apple remain '
          'alternative methods, never additional requirements.',
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('phone-field'),
              controller: _phoneController,
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
              const SizedBox(height: 10),
              Text(
                message,
                key: const Key('sign-in-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('send-otp'),
              onPressed: () => widget.session.requestOtp(_phoneController.text),
              child: const Text('Send OTP'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.g_mobiledata_rounded),
              label: const Text('Continue with Google — staging setup pending'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'By continuing, you agree to the Terms and acknowledge the '
              'Privacy Notice. Promotional messages remain off by default.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
