import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/auth/facebook_login_contract.dart';

final class _FakeFacebookNativeSdkAdapter implements FacebookNativeSdkAdapter {
  const _FakeFacebookNativeSdkAdapter(this.isConfigured);

  @override
  final bool isConfigured;

  @override
  Future<FacebookLoginResult> signIn() async => const FacebookLoginResult(
    outcome: FacebookLoginOutcome.success,
    origin: FacebookLoginOrigin.completed,
  );

  @override
  Future<FacebookLoginOutcome> logOut() async => FacebookLoginOutcome.success;

  @override
  Future<FacebookLoginOutcome> revokeAccess() async =>
      FacebookLoginOutcome.success;
}

const _redirectExpectation = FacebookRedirectExpectation(
  host: 'auth.example.invalid',
  path: '/facebook/callback',
);

FacebookLoginConfiguration _configuration({
  String androidPackageName = FacebookLoginContract.expectedAndroidPackage,
  String androidLaunchActivity =
      FacebookLoginContract.expectedAndroidLaunchActivity,
  String keyHashReadinessFact =
      FacebookLoginContract.expectedKeyHashReadinessFact,
  Uri? redirectUri,
  bool includeRedirect = true,
  Uri? privacyPolicyUrl,
  bool includePrivacyPolicy = true,
  Uri? dataDeletionUrl,
  bool includeDataDeletionUrl = true,
  bool revocationConfigured = true,
  bool dataDeletionRequestConfigured = true,
  Set<String>? permissions,
}) {
  return FacebookLoginConfiguration(
    androidPackageName: androidPackageName,
    androidLaunchActivity: androidLaunchActivity,
    keyHashReadinessFact: keyHashReadinessFact,
    redirectUri: includeRedirect
        ? redirectUri ??
              Uri.parse('https://auth.example.invalid/facebook/callback')
        : null,
    privacyPolicyUrl: includePrivacyPolicy
        ? privacyPolicyUrl ?? Uri.parse('https://legal.example.invalid/privacy')
        : null,
    dataDeletionUrl: includeDataDeletionUrl
        ? dataDeletionUrl ??
              Uri.parse('https://legal.example.invalid/data-deletion')
        : null,
    revocationConfigured: revocationConfigured,
    dataDeletionRequestConfigured: dataDeletionRequestConfigured,
    permissions: permissions ?? FacebookLoginContract.defaultPermissions,
  );
}

FacebookLoginContract _contract({
  FacebookLoginConfiguration? configuration,
  FacebookRedirectExpectation redirectExpectation = _redirectExpectation,
  bool includeAdapter = true,
  bool adapterConfigured = true,
}) {
  return FacebookLoginContract(
    configuration: configuration ?? _configuration(),
    redirectExpectation: redirectExpectation,
    nativeSdkAdapter: includeAdapter
        ? _FakeFacebookNativeSdkAdapter(adapterConfigured)
        : null,
  );
}

void main() {
  group('Facebook public Login configuration', () {
    test('uses public_profile alone and never requests email by default', () {
      expect(FacebookLoginContract.defaultPermissions, const <String>{
        'public_profile',
      });
      expect(FacebookLoginContract.emailPermissionRequestedByDefault, isFalse);
      expect(_configuration().requestsEmail, isFalse);
      expect(
        () => FacebookLoginContract.defaultPermissions.add('email'),
        throwsUnsupportedError,
      );
    });

    test('accepts only the exact package, activity, and readiness facts', () {
      expect(_contract().readiness.isReady, isTrue);
      expect(_contract().readiness.issues, isEmpty);

      final packageMismatch = _contract(
        configuration: _configuration(androidPackageName: 'com.example.app'),
      ).readiness;
      expect(
        packageMismatch.issues,
        contains(FacebookLoginConfigurationIssue.androidPackageMismatch),
      );

      final activityMismatch = _contract(
        configuration: _configuration(androidLaunchActivity: 'MainActivity'),
      ).readiness;
      expect(
        activityMismatch.issues,
        contains(FacebookLoginConfigurationIssue.androidLaunchActivityMismatch),
      );

      for (final readinessFact in <String>['', 'not_qualified']) {
        final readiness = _contract(
          configuration: _configuration(keyHashReadinessFact: readinessFact),
        ).readiness;
        expect(
          readiness.issues,
          contains(FacebookLoginConfigurationIssue.keyHashReadinessMissing),
        );
      }
    });

    test('fails closed until the separate native adapter is configured', () {
      for (final contract in <FacebookLoginContract>[
        _contract(includeAdapter: false),
        _contract(adapterConfigured: false),
      ]) {
        expect(contract.readiness.isReady, isFalse);
        expect(
          contract.readiness.issues,
          contains(FacebookLoginConfigurationIssue.nativeAdapterUnavailable),
        );
        expect(contract.beginProviderAttempt, throwsStateError);
      }
    });

    test('rejects email, extra, and missing permissions', () {
      final email = _contract(
        configuration: _configuration(
          permissions: const <String>{'public_profile', 'email'},
        ),
      ).readiness;
      expect(
        email.issues,
        containsAll(<FacebookLoginConfigurationIssue>{
          FacebookLoginConfigurationIssue.permissionsNotMinimal,
          FacebookLoginConfigurationIssue.emailPermissionForbidden,
        }),
      );

      for (final permissions in <Set<String>>[
        const <String>{},
        const <String>{'public_profile', 'friends'},
      ]) {
        final readiness = _contract(
          configuration: _configuration(permissions: permissions),
        ).readiness;
        expect(
          readiness.issues,
          contains(FacebookLoginConfigurationIssue.permissionsNotMinimal),
        );
      }
    });
  });

  group('Facebook redirect and public policy configuration', () {
    test('requires the exact clean HTTPS redirect host and path', () {
      final invalidRedirects = <Uri>[
        Uri.parse('http://auth.example.invalid/facebook/callback'),
        Uri.parse('https://other.example.invalid/facebook/callback'),
        Uri.parse('https://auth.example.invalid/facebook/other'),
        Uri.parse('https://auth.example.invalid/facebook/callback?code=fake'),
        Uri.parse('https://auth.example.invalid/facebook/callback#return'),
      ];
      for (final redirect in invalidRedirects) {
        final readiness = _contract(
          configuration: _configuration(redirectUri: redirect),
        ).readiness;
        expect(
          readiness.issues,
          contains(FacebookLoginConfigurationIssue.redirectMismatch),
        );
      }

      expect(
        _contract(
          configuration: _configuration(includeRedirect: false),
        ).readiness.issues,
        contains(FacebookLoginConfigurationIssue.redirectMismatch),
      );
    });

    test('rejects wildcard, noncanonical, and root redirect expectations', () {
      for (final expectation in <FacebookRedirectExpectation>[
        const FacebookRedirectExpectation(
          host: '*.example.invalid',
          path: '/facebook/callback',
        ),
        const FacebookRedirectExpectation(
          host: 'AUTH.example.invalid',
          path: '/facebook/callback',
        ),
        const FacebookRedirectExpectation(
          host: 'auth.example.invalid',
          path: '/',
        ),
      ]) {
        expect(expectation.isWellFormed, isFalse);
        expect(
          _contract(redirectExpectation: expectation).readiness.issues,
          contains(FacebookLoginConfigurationIssue.redirectMismatch),
        );
      }
    });

    test('requires secure distinct privacy and data-deletion endpoints', () {
      final publicPrivacy = Uri.parse('https://legal.example.invalid/privacy');
      final invalidConfigurations = <FacebookLoginConfiguration>[
        _configuration(includePrivacyPolicy: false),
        _configuration(
          privacyPolicyUrl: Uri.parse('http://legal.example.invalid/privacy'),
        ),
        _configuration(includeDataDeletionUrl: false),
        _configuration(dataDeletionRequestConfigured: false),
        _configuration(
          privacyPolicyUrl: publicPrivacy,
          dataDeletionUrl: publicPrivacy,
        ),
      ];
      for (final configuration in invalidConfigurations) {
        expect(
          _contract(configuration: configuration).readiness.isReady,
          false,
        );
      }
    });

    test('requires revocation readiness', () {
      final readiness = _contract(
        configuration: _configuration(revocationConfigured: false),
      ).readiness;
      expect(
        readiness.issues,
        contains(FacebookLoginConfigurationIssue.revocationUnavailable),
      );
    });
  });

  group('Facebook provider attempt state and sanitized outcomes', () {
    test('starts exactly one provider attempt', () {
      const initial = FacebookProviderAttempt.notStarted();
      expect(initial.phase, FacebookProviderAttemptPhase.notStarted);
      expect(initial.providerStartCount, 0);
      expect(initial.callbackCount, 0);
      expect(initial.terminalOutcomeCount, 0);

      final pending = initial.startProvider();
      expect(pending.phase, FacebookProviderAttemptPhase.awaitingProvider);
      expect(pending.providerStartCount, 1);
      expect(pending.callbackCount, 0);
      expect(pending.terminalOutcomeCount, 0);
      expect(pending.outcome, isNull);
      expect(pending.startProvider, throwsStateError);

      final contractPending = _contract().beginProviderAttempt();
      expect(
        contractPending.phase,
        FacebookProviderAttemptPhase.awaitingProvider,
      );
      expect(contractPending.providerStartCount, 1);
    });

    test('accepts every sanitized outcome with one verified callback', () {
      for (final outcome in FacebookLoginOutcome.values) {
        final completed = const FacebookProviderAttempt.notStarted()
            .startProvider()
            .completeCallback(
              FacebookProviderCallback(
                outcome: outcome,
                providerStateVerified: true,
              ),
            );
        expect(completed.phase, FacebookProviderAttemptPhase.terminal);
        expect(completed.providerStartCount, 1);
        expect(completed.callbackCount, 1);
        expect(completed.terminalOutcomeCount, 1);
        expect(completed.outcome, outcome);
        expect(outcome.safeMessage, isNotEmpty);
      }
    });

    test('fails closed on unverified provider state and callback replay', () {
      final pending = const FacebookProviderAttempt.notStarted()
          .startProvider();
      final completed = pending.completeCallback(
        const FacebookProviderCallback(
          outcome: FacebookLoginOutcome.success,
          providerStateVerified: false,
        ),
      );
      expect(completed.outcome, FacebookLoginOutcome.configurationUnavailable);
      expect(
        () => completed.completeCallback(
          const FacebookProviderCallback(
            outcome: FacebookLoginOutcome.success,
            providerStateVerified: true,
          ),
        ),
        throwsStateError,
      );
    });

    test('allows one sanitized terminal failure without a callback', () {
      final pending = const FacebookProviderAttempt.notStarted()
          .startProvider();
      final networkFailure = pending.failWithoutCallback(
        FacebookLoginOutcome.networkUnavailable,
      );
      expect(networkFailure.callbackCount, 0);
      expect(networkFailure.terminalOutcomeCount, 1);
      expect(networkFailure.outcome, FacebookLoginOutcome.networkUnavailable);
      expect(networkFailure.expire, throwsStateError);

      final expired = const FacebookProviderAttempt.notStarted()
          .startProvider()
          .expire();
      expect(expired.callbackCount, 0);
      expect(expired.terminalOutcomeCount, 1);
      expect(expired.outcome, FacebookLoginOutcome.configurationUnavailable);
      expect(
        () => pending.failWithoutCallback(FacebookLoginOutcome.success),
        throwsArgumentError,
      );
    });
  });

  group('Facebook logout, revocation, and data-deletion requests', () {
    test('creates declarative requests without account or token payloads', () {
      final contract = _contract();
      final logout = contract.createLogoutRequest();
      final revocation = contract.createRevocationRequest();
      final dataDeletion = contract.createDataDeletionRequest();

      expect(logout.kind, FacebookAccountRequestKind.logout);
      expect(revocation.kind, FacebookAccountRequestKind.revokeAccess);
      expect(dataDeletion.kind, FacebookAccountRequestKind.dataDeletion);
      expect(
        dataDeletion.destination,
        Uri.parse('https://legal.example.invalid/data-deletion'),
      );
    });

    test('blocks every request when the native adapter is unavailable', () {
      for (final contract in <FacebookLoginContract>[
        _contract(includeAdapter: false),
        _contract(adapterConfigured: false),
      ]) {
        expect(contract.createLogoutRequest, throwsStateError);
        expect(contract.createRevocationRequest, throwsStateError);
        expect(contract.createDataDeletionRequest, throwsStateError);
      }
    });

    test('blocks revocation until its configuration is ready', () {
      final contract = _contract(
        configuration: _configuration(revocationConfigured: false),
      );
      expect(contract.createRevocationRequest, throwsStateError);
    });

    test('blocks an absent, insecure, or aliased data-deletion target', () {
      final privacy = Uri.parse('https://legal.example.invalid/privacy');
      final blockedConfigurations = <FacebookLoginConfiguration>[
        _configuration(includeDataDeletionUrl: false),
        _configuration(dataDeletionRequestConfigured: false),
        _configuration(
          dataDeletionUrl: Uri.parse(
            'http://legal.example.invalid/data-deletion',
          ),
        ),
        _configuration(privacyPolicyUrl: privacy, dataDeletionUrl: privacy),
      ];
      for (final configuration in blockedConfigurations) {
        final contract = _contract(configuration: configuration);
        expect(contract.createDataDeletionRequest, throwsStateError);
      }
    });
  });

  group('Facebook privacy and dependency containment', () {
    test('keeps the contract pure Dart with no provider execution surface', () {
      final sourceFile = File('lib/core/auth/facebook_login_contract.dart');
      expect(sourceFile.existsSync(), isTrue);
      final source = sourceFile.readAsStringSync();
      expect(RegExp(r'^import ', multiLine: true).allMatches(source), isEmpty);

      const forbiddenSourceTokens = <String>[
        'package:facebook',
        'flutter_facebook_auth',
        'MethodChannel',
        'FirebaseAuthProvider',
        'accessToken',
        'clientToken',
        'appSecret',
        'accountIdentifier',
        'accountEmail',
        'launchUrl',
        'HttpClient',
        'package:http',
        'facebook.com',
        'moolsocial.com/',
      ];
      for (final token in forbiddenSourceTokens) {
        expect(source, isNot(contains(token)), reason: token);
      }
    });

    test('exposes only fixed sanitized customer outcomes', () {
      expect(FacebookLoginOutcome.values, hasLength(10));
      for (final outcome in FacebookLoginOutcome.values) {
        final message = outcome.safeMessage;
        expect(message, isNotEmpty);
        expect(message, isNot(contains('@')));
        expect(message, isNot(contains('://')));
        expect(message.toLowerCase(), isNot(contains('token')));
      }
    });

    test('stores only an out-of-band key-hash readiness fact', () {
      expect(
        FacebookLoginContract.expectedKeyHashReadinessFact,
        'debug_and_release_key_hashes_qualified_separately',
      );
      expect(
        FacebookLoginContract.expectedKeyHashReadinessFact,
        isNot(matches(RegExp(r'^[A-Fa-f0-9:]{20,}$'))),
      );
    });
  });
}
