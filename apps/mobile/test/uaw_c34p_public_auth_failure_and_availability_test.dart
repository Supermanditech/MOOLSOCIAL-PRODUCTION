import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/auth/public_auth_failure.dart';
import 'package:moolsocial/core/auth/public_auth_runtime_configuration.dart';

void main() {
  group('sanitized Google identity failures', () {
    const expected = <String, PublicAuthFailureClass>{
      'canceled': PublicAuthFailureClass.cancelled,
      'clientConfigurationError': PublicAuthFailureClass.configuration,
      'providerConfigurationError':
          PublicAuthFailureClass.providerConfiguration,
      'interrupted': PublicAuthFailureClass.interrupted,
      'uiUnavailable': PublicAuthFailureClass.uiUnavailable,
      'userMismatch': PublicAuthFailureClass.userMismatch,
      'missing-id-token': PublicAuthFailureClass.missingIdentity,
    };

    for (final entry in expected.entries) {
      test('${entry.key} maps to ${entry.value.name}', () {
        final failure = sanitizedGoogleIdentityFailure(entry.key);

        expect(failure.failureClass, entry.value);
        expect(failure.code, startsWith('auth-'));
        expect(failure.publicMessage, isNotEmpty);
      });
    }

    test('unknown plugin detail is never returned to public copy', () {
      const privateDiagnostic = 'private-provider-diagnostic';

      final failure = sanitizedGoogleIdentityFailure(privateDiagnostic);

      expect(failure.failureClass, PublicAuthFailureClass.nativeBridge);
      expect(failure.code, 'auth-native-bridge');
      expect(failure.publicMessage, isNot(contains(privateDiagnostic)));
      expect(
        failure.publicMessage,
        'Google sign-in could not be completed. Please try again.',
      );
    });
  });

  group('sanitized Firebase authentication failures', () {
    const expected = <String, PublicAuthFailureClass>{
      'canceled': PublicAuthFailureClass.cancelled,
      'cancelled': PublicAuthFailureClass.cancelled,
      'popup-closed-by-user': PublicAuthFailureClass.cancelled,
      'web-context-cancelled': PublicAuthFailureClass.cancelled,
      'user-cancelled': PublicAuthFailureClass.cancelled,
      'account-exists-with-different-credential':
          PublicAuthFailureClass.accountCollision,
      'credential-already-in-use': PublicAuthFailureClass.accountCollision,
      'network-request-failed': PublicAuthFailureClass.network,
      'web-network-request-failed': PublicAuthFailureClass.network,
      'too-many-requests': PublicAuthFailureClass.throttled,
      'user-disabled': PublicAuthFailureClass.disabledAccount,
      'operation-not-allowed': PublicAuthFailureClass.providerUnavailable,
      'provider-already-linked': PublicAuthFailureClass.providerUnavailable,
      'invalid-oauth-provider': PublicAuthFailureClass.providerUnavailable,
      'invalid-credential': PublicAuthFailureClass.invalidCredential,
      'invalid-idp-response': PublicAuthFailureClass.invalidCredential,
      'invalid-custom-token': PublicAuthFailureClass.invalidCredential,
      'custom-token-mismatch': PublicAuthFailureClass.invalidCredential,
      'missing-or-invalid-nonce': PublicAuthFailureClass.invalidCredential,
      'expired-action-code': PublicAuthFailureClass.expiredCredential,
      'session-expired': PublicAuthFailureClass.expiredCredential,
    };

    for (final entry in expected.entries) {
      test('${entry.key} maps to ${entry.value.name}', () {
        final failure = sanitizedFirebaseAuthFailure(
          entry.key,
          providerLabel: 'Facebook',
        );

        expect(failure.failureClass, entry.value);
        expect(failure.code, startsWith('auth-'));
        expect(failure.publicMessage, isNotEmpty);
      });
    }

    test('unknown Firebase detail cannot enter public copy', () {
      const privateDiagnostic = 'private-firebase-diagnostic';

      final failure = sanitizedFirebaseAuthFailure(
        privateDiagnostic,
        providerLabel: 'X',
      );

      expect(failure.failureClass, PublicAuthFailureClass.firebaseUnclassified);
      expect(failure.code, 'auth-firebase-unclassified');
      expect(failure.publicMessage, isNot(contains(privateDiagnostic)));
      expect(failure.publicMessage, contains('could not be completed'));
    });
  });

  group('public authentication runtime availability', () {
    const ready = PublicAuthRuntimeConfiguration(
      googleServerClientConfigured: true,
      googleProviderQualified: true,
      playSigningQualified: true,
      emailLinkQualified: true,
      mobileOtpEnabled: true,
      mobileAttestationQualified: true,
      appleEnabled: true,
      appleProviderQualified: true,
      applePlatformConfigurationQualified: true,
      appleRevocationQualified: true,
      xPublicClientEnabled: true,
      xClientIdConfigured: true,
      xExactRedirectQualified: true,
      xPkceAdapterInstalled: true,
      xFirebaseBrokerQualified: true,
      instagramEnabled: true,
      instagramProfessionalLoginQualified: true,
      instagramExactRedirectQualified: true,
      instagramBrokerAdapterInstalled: true,
      instagramBrokerQualified: true,
      instagramRevocationQualified: true,
      facebookEnabled: true,
      facebookNativeAdapterInstalled: true,
      facebookProviderQualified: true,
      facebookAndroidConfigurationQualified: true,
      facebookRevocationQualified: true,
      facebookDataDeletionQualified: true,
    );

    test('all methods open only when every dependency is qualified', () {
      expect(ready.googleAndYoutubeAvailable, isTrue);
      expect(ready.passwordlessEmailAvailable, isTrue);
      expect(ready.mobileOtpAvailable, isTrue);
      expect(ready.appleAvailable, isTrue);
      expect(ready.xAvailable, isTrue);
      expect(ready.instagramAvailable, isTrue);
      expect(ready.facebookAvailable, isTrue);
    });

    test('email link and mobile OTP remain independent', () {
      const configuration = PublicAuthRuntimeConfiguration(
        googleServerClientConfigured: false,
        googleProviderQualified: false,
        playSigningQualified: false,
        emailLinkQualified: true,
        mobileOtpEnabled: true,
        mobileAttestationQualified: false,
        appleEnabled: false,
        appleProviderQualified: false,
        applePlatformConfigurationQualified: false,
        appleRevocationQualified: false,
        xPublicClientEnabled: false,
        xClientIdConfigured: false,
        xExactRedirectQualified: false,
        xPkceAdapterInstalled: false,
        xFirebaseBrokerQualified: false,
        instagramEnabled: false,
        instagramProfessionalLoginQualified: false,
        instagramExactRedirectQualified: false,
        instagramBrokerAdapterInstalled: false,
        instagramBrokerQualified: false,
        instagramRevocationQualified: false,
        facebookEnabled: false,
        facebookNativeAdapterInstalled: false,
        facebookProviderQualified: false,
        facebookAndroidConfigurationQualified: false,
        facebookRevocationQualified: false,
        facebookDataDeletionQualified: false,
      );

      expect(configuration.passwordlessEmailAvailable, isTrue);
      expect(configuration.mobileOtpAvailable, isFalse);
    });

    test('X remains closed without the Firebase custom-token broker', () {
      final configuration = _copy(ready, xFirebaseBrokerQualified: false);

      expect(configuration.xAvailable, isFalse);
      expect(configuration.facebookAvailable, isTrue);
    });

    test('Facebook remains closed without deletion readiness', () {
      final configuration = _copy(ready, facebookDataDeletionQualified: false);

      expect(configuration.facebookAvailable, isFalse);
      expect(configuration.xAvailable, isTrue);
    });

    test('Google and YouTube close together on one missing fact', () {
      final configuration = _copy(ready, playSigningQualified: false);

      expect(configuration.googleAndYoutubeAvailable, isFalse);
    });

    test('Google and YouTube can open for an explicit signed sideload', () {
      final configuration = _copy(
        ready,
        playSigningQualified: false,
        sideloadPreflightEnabled: true,
        googleSideloadSigningQualified: true,
      );

      expect(configuration.googleAndYoutubeAvailable, isTrue);
      expect(configuration.playSigningQualified, isFalse);
    });

    test('Apple remains closed without provider qualification', () {
      final configuration = _copy(ready, appleProviderQualified: false);

      expect(configuration.appleAvailable, isFalse);
    });

    test('Instagram remains closed without its Firebase broker', () {
      final configuration = _copy(ready, instagramBrokerQualified: false);

      expect(configuration.instagramAvailable, isFalse);
    });

    test('replay-protected brokers acquire limited-use App Check tokens', () {
      final mainSource = File('lib/main.dart').readAsStringSync();

      expect(
        _occurrences(
          mainSource,
          'FirebaseAppCheck.instance.getLimitedUseToken()',
        ),
        1,
      );
      expect(
        mainSource,
        isNot(contains('FirebaseAppCheck.instance.getToken()')),
      );
    });
  });
}

int _occurrences(String body, String value) =>
    RegExp(RegExp.escape(value)).allMatches(body).length;

PublicAuthRuntimeConfiguration _copy(
  PublicAuthRuntimeConfiguration value, {
  bool? playSigningQualified,
  bool? sideloadPreflightEnabled,
  bool? googleSideloadSigningQualified,
  bool? appleProviderQualified,
  bool? xFirebaseBrokerQualified,
  bool? instagramBrokerQualified,
  bool? facebookDataDeletionQualified,
}) {
  return PublicAuthRuntimeConfiguration(
    googleServerClientConfigured: value.googleServerClientConfigured,
    googleProviderQualified: value.googleProviderQualified,
    playSigningQualified: playSigningQualified ?? value.playSigningQualified,
    sideloadPreflightEnabled:
        sideloadPreflightEnabled ?? value.sideloadPreflightEnabled,
    googleSideloadSigningQualified:
        googleSideloadSigningQualified ?? value.googleSideloadSigningQualified,
    emailLinkQualified: value.emailLinkQualified,
    mobileOtpEnabled: value.mobileOtpEnabled,
    mobileAttestationQualified: value.mobileAttestationQualified,
    appleEnabled: value.appleEnabled,
    appleProviderQualified:
        appleProviderQualified ?? value.appleProviderQualified,
    applePlatformConfigurationQualified:
        value.applePlatformConfigurationQualified,
    appleRevocationQualified: value.appleRevocationQualified,
    xPublicClientEnabled: value.xPublicClientEnabled,
    xClientIdConfigured: value.xClientIdConfigured,
    xExactRedirectQualified: value.xExactRedirectQualified,
    xPkceAdapterInstalled: value.xPkceAdapterInstalled,
    xFirebaseBrokerQualified:
        xFirebaseBrokerQualified ?? value.xFirebaseBrokerQualified,
    instagramEnabled: value.instagramEnabled,
    instagramProfessionalLoginQualified:
        value.instagramProfessionalLoginQualified,
    instagramExactRedirectQualified: value.instagramExactRedirectQualified,
    instagramBrokerAdapterInstalled: value.instagramBrokerAdapterInstalled,
    instagramBrokerQualified:
        instagramBrokerQualified ?? value.instagramBrokerQualified,
    instagramRevocationQualified: value.instagramRevocationQualified,
    facebookEnabled: value.facebookEnabled,
    facebookNativeAdapterInstalled: value.facebookNativeAdapterInstalled,
    facebookProviderQualified: value.facebookProviderQualified,
    facebookAndroidConfigurationQualified:
        value.facebookAndroidConfigurationQualified,
    facebookRevocationQualified: value.facebookRevocationQualified,
    facebookDataDeletionQualified:
        facebookDataDeletionQualified ?? value.facebookDataDeletionQualified,
  );
}
