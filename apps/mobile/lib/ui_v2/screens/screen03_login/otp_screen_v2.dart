import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/journey01/journey_services.dart';
import '../../../features/journey01/journey_session.dart';
import 'screen03_frame_v2.dart';

class OtpScreenV2 extends StatefulWidget {
  const OtpScreenV2({required this.session, super.key});

  final JourneySession session;

  @override
  State<OtpScreenV2> createState() => _OtpScreenV2State();
}

class _OtpScreenV2State extends State<OtpScreenV2> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _ticker;
  String? _appliedReviewCode;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyReviewCode());
  }

  void _applyReviewCode() {
    final code = widget.session.reviewCode;
    if (code == null || code.length != 6) return;
    if (_appliedReviewCode == code) return;
    _appliedReviewCode = code;
    _controller.text = code;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Screen03FrameV2(
      screenKey: const Key('screen03-otp-v2'),
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          if (_appliedReviewCode != widget.session.reviewCode &&
              widget.session.reviewCode != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _applyReviewCode(),
            );
          }
          final isEmail = widget.session.otpChannel == OtpChannel.email;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter OTP', style: Screen03Text.title),
                const SizedBox(height: 8),
                Text(
                  'Sent to ${widget.session.maskedOtpDestination}',
                  key: const Key('screen03-otp-destination-copy'),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEmail ? 'EMAIL OTP' : 'MOBILE OTP',
                        style: Screen03Text.cardLabel,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Screen03Colors.navy),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.session.maskedOtpDestination,
                          style: const TextStyle(
                            color: Screen03Colors.navy,
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
                            onTap: _focusNode.requestFocus,
                            child: Row(
                              children: List.generate(6, (index) {
                                final value = _controller.text;
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
                                          color: Screen03Colors.navy,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        digit,
                                        style: const TextStyle(
                                          color: Screen03Colors.navy,
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
                                focusNode: _focusNode,
                                controller: _controller,
                                keyboardType: TextInputType.number,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode,
                                ],
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
                          style: const TextStyle(
                            color: Screen03Colors.danger,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('verify-otp'),
                        onPressed: widget.session.busy
                            ? null
                            : () => widget.session.verifyOtp(_controller.text),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Screen03Colors.navy,
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
                                widget.session.resendSeconds > 0
                                    ? 'Resend in '
                                          '${widget.session.resendSeconds}s'
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
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
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
            ),
          );
        },
      ),
    );
  }
}
