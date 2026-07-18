import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/mool_theme.dart';
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
  final _otpFocus = FocusNode();
  Timer? _ticker;
  bool _reviewCodeApplied = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _otpController.addListener(_refreshOtp);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyReviewCode());
  }

  void _applyReviewCode() {
    if (_reviewCodeApplied) return;
    final code = widget.session.reviewCode;
    if (code == null || code.length != 6) return;
    _reviewCodeApplied = true;
    _otpController.text = code;
  }

  void _refreshOtp() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otpController
      ..removeListener(_refreshOtp)
      ..dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.session.phoneNumber ?? '';
    final masked = phone.length == 10 ? '******${phone.substring(6)}' : phone;
    final resendSeconds = widget.session.resendSeconds;

    return JourneyFrame(
      eyebrow: '',
      title: 'Enter verification code',
      description: 'Sent to +91 $masked',
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          if (!_reviewCodeApplied && widget.session.reviewCode != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _applyReviewCode(),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      'MOBILE VERIFICATION',
                      style: TextStyle(
                        color: MoolColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: MoolColors.navy),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+91 $masked',
                        style: const TextStyle(
                          color: MoolColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        GestureDetector(
                          key: const Key('otp-cells'),
                          onTap: _otpFocus.requestFocus,
                          child: Row(
                            children: List.generate(6, (index) {
                              final value = _otpController.text;
                              final digit = index < value.length
                                  ? value[index]
                                  : '';
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: index == 5 ? 0 : 7,
                                  ),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 44,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: MoolColors.navy,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      digit,
                                      style: const TextStyle(
                                        color: MoolColors.navy,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        Positioned(
                          width: 1,
                          height: 1,
                          child: Opacity(
                            opacity: .01,
                            child: TextField(
                              key: const Key('otp-field'),
                              focusNode: _otpFocus,
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.session.errorMessage case final message?) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        key: const Key('otp-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('verify-otp'),
                      onPressed: widget.session.busy
                          ? null
                          : () => widget.session.verifyOtp(_otpController.text),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: MoolColors.navy,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        widget.session.busy ? 'Verifying…' : 'Verify',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            key: const Key('resend-otp'),
                            onPressed: widget.session.canResend
                                ? widget.session.resendOtp
                                : null,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            child: Text(
                              resendSeconds > 0
                                  ? 'Resend in ${resendSeconds}s'
                                  : 'Send a new code',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('change-method'),
                          onPressed: widget.session.busy
                              ? null
                              : widget.session.changeSignInMethod,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text(
                            'Change method',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
