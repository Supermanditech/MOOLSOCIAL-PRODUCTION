import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/config/email_link_runtime_configuration.dart';
import 'package:moolsocial/features/journey01/review_journey_services.dart';

void main() {
  test('combined public and device review selects qualified Firebase', () {
    expect(
      resolveEmailLinkGatewaySelection(
        deviceReviewMode: true,
        publicReviewMode: true,
        runtimeConfigurationAvailable: true,
      ),
      EmailLinkGatewaySelection.firebase,
    );
  });

  test('public review fails closed without qualified email runtime', () {
    for (final deviceReviewMode in const [false, true]) {
      expect(
        resolveEmailLinkGatewaySelection(
          deviceReviewMode: deviceReviewMode,
          publicReviewMode: true,
          runtimeConfigurationAvailable: false,
        ),
        EmailLinkGatewaySelection.unavailable,
        reason: 'deviceReviewMode=$deviceReviewMode',
      );
    }
  });

  test('isolated non-release device review retains review gateway', () {
    for (final runtimeConfigurationAvailable in const [false, true]) {
      expect(
        resolveEmailLinkGatewaySelection(
          deviceReviewMode: true,
          publicReviewMode: false,
          runtimeConfigurationAvailable: runtimeConfigurationAvailable,
        ),
        EmailLinkGatewaySelection.review,
        reason: 'runtimeConfigurationAvailable=$runtimeConfigurationAvailable',
      );
    }
  });

  test('ordinary configured runtime selects Firebase', () {
    expect(
      resolveEmailLinkGatewaySelection(
        deviceReviewMode: false,
        publicReviewMode: false,
        runtimeConfigurationAvailable: true,
      ),
      EmailLinkGatewaySelection.firebase,
    );
  });

  test('ordinary unconfigured runtime remains unavailable', () {
    expect(
      resolveEmailLinkGatewaySelection(
        deviceReviewMode: false,
        publicReviewMode: false,
        runtimeConfigurationAvailable: false,
      ),
      EmailLinkGatewaySelection.unavailable,
    );
  });

  test('email-link Firebase failures retain exact sanitized stages', () {
    const cases = <String, String>{
      'invalid-recipient-email': 'invalid-recipient-email',
      'missing-continue-uri': 'missing-continue-uri',
      'unauthorized-domain': 'unauthorized-domain',
      'internal-error': 'internal-error',
      'provider-specific-unmapped-failure':
          'provider-specific-unmapped-failure',
      'timeout': 'timeout',
      '  NETWORK-REQUEST-FAILED  ': 'network-request-failed',
    };

    for (final entry in cases.entries) {
      final failure = sanitizedEmailLinkFailure(entry.key);
      expect(failure.code, entry.value, reason: entry.key);
      expect(failure.userMessage, isNot(contains(entry.key)));
    }
  });

  test('unsafe Firebase failure payloads never enter telemetry or copy', () {
    for (final unsafeCode in [
      '',
      'auth/error',
      'credential payload',
      'danger\ncode',
      'a' * 65,
    ]) {
      final failure = sanitizedEmailLinkFailure(unsafeCode);
      expect(failure.code, 'email-link-firebase-unclassified');
      if (unsafeCode.isNotEmpty) {
        expect(failure.userMessage, isNot(contains(unsafeCode)));
      }
    }
  });
}
