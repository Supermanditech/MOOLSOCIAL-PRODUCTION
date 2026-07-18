import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../journey_session.dart';
import '../widgets/journey_frame.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({required this.session, super.key});

  final JourneySession session;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.session.phoneNumber ?? '';
    final masked = phone.length == 10 ? '******${phone.substring(6)}' : phone;

    return JourneyFrame(
      eyebrow: 'Verify mobile',
      title: 'Enter the 6-digit code',
      description:
          'Sent to +91 $masked. Verification never changes your selected '
          'language, area or requested destination.',
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('otp-field'),
              controller: _otpController,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'OTP',
                counterText: '',
              ),
            ),
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Development code: ${widget.session.developmentOtp}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ),
            if (widget.session.errorMessage case final message?) ...[
              const SizedBox(height: 10),
              Text(
                message,
                key: const Key('otp-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('verify-otp'),
              onPressed: () => widget.session.verifyOtp(_otpController.text),
              child: const Text('Verify and continue'),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('change-method'),
              onPressed: widget.session.changeSignInMethod,
              child: const Text('Change mobile number or method'),
            ),
          ],
        ),
      ),
    );
  }
}
