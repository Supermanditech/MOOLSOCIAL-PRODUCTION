import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moolsocial/core/auth/facebook_login_contract.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/review_journey_services.dart';

void main() {
  group('FirebaseSocialAuthGateway', () {
    const knownGoogleFirebaseFailures = <String, String>{
      'canceled': 'auth-cancelled',
      'cancelled': 'auth-cancelled',
      'popup-closed-by-user': 'auth-cancelled',
      'web-context-cancelled': 'auth-cancelled',
      'user-cancelled': 'auth-cancelled',
      'account-exists-with-different-credential': 'auth-account-collision',
      'credential-already-in-use': 'auth-account-collision',
      'network-request-failed': 'auth-network',
      'web-network-request-failed': 'auth-network',
      'too-many-requests': 'auth-throttled',
      'user-disabled': 'auth-account-disabled',
      'operation-not-allowed': 'auth-provider-unavailable',
      'provider-already-linked': 'auth-provider-unavailable',
      'invalid-oauth-provider': 'auth-provider-unavailable',
      'invalid-credential': 'auth-invalid-credential',
      'invalid-idp-response': 'auth-invalid-credential',
      'invalid-custom-token': 'auth-invalid-credential',
      'custom-token-mismatch': 'auth-invalid-credential',
      'missing-or-invalid-nonce': 'auth-invalid-credential',
      'expired-action-code': 'auth-expired-credential',
      'session-expired': 'auth-expired-credential',
      'unknown': 'auth-firebase-unclassified',
    };

    for (final entry in knownGoogleFirebaseFailures.entries) {
      test('Google Firebase ${entry.key} preserves its safe code', () async {
        const privateDiagnostic = 'private-firebase-diagnostic';
        final stages = <String>[];
        final gateway = FirebaseSocialAuthGateway.forTesting(
          authClient: _FakeFirebaseSocialAuthClient(
            userIdAfterSignIn: null,
            googleFailure: FirebaseAuthException(
              code: entry.key,
              message: privateDiagnostic,
            ),
          ),
          googleIdentityGateway: _FakeGoogleIdentityGateway(
            idToken: 'synthetic-id-token',
          ),
          googleStageObserver: stages.add,
        );

        if (entry.value == 'auth-cancelled') {
          final result = await gateway.signIn(SocialAuthProvider.google);
          expect(result.outcome, SocialAuthOutcome.cancelled);
          expect(result.code, entry.value);
        } else {
          await expectLater(
            gateway.signIn(SocialAuthProvider.google),
            throwsA(
              isA<JourneyServiceException>().having(
                (error) => error.code,
                'code',
                entry.value,
              ),
            ),
          );
        }
        expect(
          stages,
          contains('auth-google-firebase-exception-code-${entry.key}'),
        );
        expect(stages.join(' '), isNot(contains(privateDiagnostic)));
      });
    }

    test('Google uses the native identity proof before Firebase', () async {
      final auth = _FakeFirebaseSocialAuthClient(userIdAfterSignIn: 'user-1');
      final google = _FakeGoogleIdentityGateway(
        idToken: 'synthetic-google-id-token',
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: google,
      );

      final result = await gateway.signIn(SocialAuthProvider.google);

      expect(result.outcome, SocialAuthOutcome.authenticated);
      expect(result.userId, 'user-1');
      expect(result.code, 'auth-google-firebase-credential-complete');
      expect(google.authenticateCount, 1);
      expect(auth.googleCredentialCount, 1);
      expect(auth.genericProviderCount, 0);
    });

    test(
      'YouTube identity uses Google without requesting a provider flow',
      () async {
        final auth = _FakeFirebaseSocialAuthClient(
          userIdAfterSignIn: 'youtube-user',
        );
        final google = _FakeGoogleIdentityGateway(
          idToken: 'synthetic-youtube-identity-token',
        );
        final gateway = FirebaseSocialAuthGateway.forTesting(
          authClient: auth,
          googleIdentityGateway: google,
        );

        final result = await gateway.signIn(SocialAuthProvider.youtube);

        expect(result.outcome, SocialAuthOutcome.authenticated);
        expect(result.userId, 'youtube-user');
        expect(
          result.code,
          'auth-youtube-shared-google-firebase-credential-complete',
        );
        expect(google.authenticateCount, 1);
        expect(auth.googleCredentialCount, 1);
        expect(auth.genericProviderCount, 0);
      },
    );

    test('Apple uses one Firebase provider dispatch', () async {
      final auth = _FakeFirebaseSocialAuthClient(
        userIdAfterSignIn: 'apple-user',
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
      );

      final result = await gateway.signIn(SocialAuthProvider.apple);

      expect(result.outcome, SocialAuthOutcome.authenticated);
      expect(result.userId, 'apple-user');
      expect(result.code, 'auth-apple-firebase-credential-complete');
      expect(auth.genericProviderCount, 1);
      expect(auth.lastProvider, isA<AppleAuthProvider>());
      expect(auth.googleCredentialCount, 0);
    });

    test('Apple cancellation returns a local cancelled outcome', () async {
      final auth = _FakeFirebaseSocialAuthClient(
        userIdAfterSignIn: null,
        providerFailure: FirebaseAuthException(code: 'web-context-cancelled'),
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
      );

      final result = await gateway.signIn(SocialAuthProvider.apple);

      expect(result.outcome, SocialAuthOutcome.cancelled);
      expect(auth.genericProviderCount, 1);
    });

    test('Apple nonce failure never exposes provider detail', () async {
      const privateDiagnostic = 'private-apple-provider-diagnostic';
      final auth = _FakeFirebaseSocialAuthClient(
        userIdAfterSignIn: null,
        providerFailure: FirebaseAuthException(
          code: 'missing-or-invalid-nonce',
          message: privateDiagnostic,
        ),
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
      );

      await expectLater(
        gateway.signIn(SocialAuthProvider.apple),
        throwsA(
          isA<JourneyServiceException>()
              .having((error) => error.code, 'code', 'auth-invalid-credential')
              .having(
                (error) => error.userMessage,
                'safe message',
                isNot(contains(privateDiagnostic)),
              ),
        ),
      );
      expect(auth.genericProviderCount, 1);
    });

    test('native Google cancellation never reaches Firebase', () async {
      final auth = _FakeFirebaseSocialAuthClient(userIdAfterSignIn: 'unused');
      final google = _FakeGoogleIdentityGateway(idToken: null);
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: google,
      );

      final result = await gateway.signIn(SocialAuthProvider.google);

      expect(result.outcome, SocialAuthOutcome.cancelled);
      expect(auth.googleCredentialCount, 0);
      expect(auth.genericProviderCount, 0);
    });

    test('X never falls back to the Firebase OAuth 1 provider', () async {
      final auth = _FakeFirebaseSocialAuthClient(userIdAfterSignIn: 'x-user');
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
      );

      await expectLater(
        gateway.signIn(SocialAuthProvider.x),
        throwsA(
          isA<JourneyServiceException>()
              .having(
                (error) => error.code,
                'code',
                'auth-provider-configuration',
              )
              .having(
                (error) => error.userMessage,
                'safe message',
                contains('not available'),
              ),
        ),
      );

      expect(auth.genericProviderCount, 0);
      expect(auth.googleCredentialCount, 0);
    });

    test(
      'Facebook fails closed until its native adapter is installed',
      () async {
        final auth = _FakeFirebaseSocialAuthClient(
          userIdAfterSignIn: 'facebook-user',
        );
        final gateway = FirebaseSocialAuthGateway.forTesting(
          authClient: auth,
          googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
        );

        await expectLater(
          gateway.signIn(SocialAuthProvider.facebook),
          throwsA(
            isA<JourneyServiceException>().having(
              (error) => error.code,
              'code',
              'auth-provider-configuration',
            ),
          ),
        );

        expect(auth.genericProviderCount, 0);
      },
    );

    test('Facebook native adapter success uses the Firebase session', () async {
      final auth = _FakeFirebaseSocialAuthClient(
        userIdAfterSignIn: 'unused',
        currentUserIdValue: 'facebook-user',
      );
      final facebook = _FakeFacebookNativeSdkAdapter(
        signInOutcome: FacebookLoginOutcome.success,
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
        facebookAdapter: facebook,
      );

      final result = await gateway.signIn(SocialAuthProvider.facebook);

      expect(result.outcome, SocialAuthOutcome.authenticated);
      expect(result.userId, 'facebook-user');
      expect(result.code, 'auth-facebook-completed-success');
      expect(facebook.signInCount, 1);
      expect(auth.genericProviderCount, 0);
    });

    test(
      'Facebook success without a Firebase session is stage-specific',
      () async {
        final facebook = _FakeFacebookNativeSdkAdapter(
          signInOutcome: FacebookLoginOutcome.success,
        );
        final gateway = FirebaseSocialAuthGateway.forTesting(
          authClient: _FakeFirebaseSocialAuthClient(userIdAfterSignIn: null),
          googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
          facebookAdapter: facebook,
        );

        await expectLater(
          gateway.signIn(SocialAuthProvider.facebook),
          throwsA(
            isA<JourneyServiceException>().having(
              (error) => error.code,
              'code',
              'auth-facebook-session-missing',
            ),
          ),
        );
      },
    );

    test('Facebook network outcome stays sanitized in the gateway', () async {
      final facebook = _FakeFacebookNativeSdkAdapter(
        signInOutcome: FacebookLoginOutcome.networkUnavailable,
        signInOrigin: FacebookLoginOrigin.firebaseCredentialExchange,
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: _FakeFirebaseSocialAuthClient(userIdAfterSignIn: null),
        googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
        facebookAdapter: facebook,
      );

      await expectLater(
        gateway.signIn(SocialAuthProvider.facebook),
        throwsA(
          isA<JourneyServiceException>()
              .having(
                (error) => error.code,
                'code',
                'auth-facebook-firebase-network',
              )
              .having(
                (error) => error.userMessage,
                'safe message',
                FacebookLoginOutcome.networkUnavailable.safeMessage,
              ),
        ),
      );
      expect(facebook.signInCount, 1);
    });

    test(
      'Instagram fails truthfully without invoking another provider',
      () async {
        final auth = _FakeFirebaseSocialAuthClient(userIdAfterSignIn: 'unused');
        final gateway = FirebaseSocialAuthGateway.forTesting(
          authClient: auth,
          googleIdentityGateway: _FakeGoogleIdentityGateway(idToken: null),
        );

        await expectLater(
          gateway.signIn(SocialAuthProvider.instagram),
          throwsA(
            isA<JourneyServiceException>().having(
              (error) => error.userMessage,
              'message',
              contains('not available'),
            ),
          ),
        );
        expect(auth.googleCredentialCount, 0);
        expect(auth.genericProviderCount, 0);
      },
    );

    test('Firebase account collision never exposes provider detail', () async {
      const privateDiagnostic = 'private-provider-diagnostic';
      final auth = _FakeFirebaseSocialAuthClient(
        userIdAfterSignIn: null,
        googleFailure: FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: privateDiagnostic,
        ),
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: _FakeGoogleIdentityGateway(
          idToken: 'synthetic-id-token',
        ),
      );

      await expectLater(
        gateway.signIn(SocialAuthProvider.google),
        throwsA(
          isA<JourneyServiceException>()
              .having((error) => error.code, 'code', 'auth-account-collision')
              .having(
                (error) => error.userMessage,
                'safe message',
                isNot(contains(privateDiagnostic)),
              ),
        ),
      );
    });

    test('unknown Firebase error never exposes provider detail', () async {
      const privateDiagnostic = 'private-firebase-diagnostic';
      final auth = _FakeFirebaseSocialAuthClient(
        userIdAfterSignIn: null,
        googleFailure: FirebaseAuthException(
          code: 'unexpected-provider-code',
          message: privateDiagnostic,
        ),
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: _FakeGoogleIdentityGateway(
          idToken: 'synthetic-id-token',
        ),
      );

      await expectLater(
        gateway.signIn(SocialAuthProvider.youtube),
        throwsA(
          isA<JourneyServiceException>()
              .having(
                (error) => error.code,
                'code',
                'auth-firebase-unclassified',
              )
              .having(
                (error) => error.userMessage,
                'safe message',
                isNot(contains(privateDiagnostic)),
              ),
        ),
      );
    });

    test(
      'Google Firebase rejection preserves only the exact safe exception code',
      () async {
        const privateDiagnostic = 'private-firebase-diagnostic';
        final stages = <String>[];
        final gateway = FirebaseSocialAuthGateway.forTesting(
          authClient: _FakeFirebaseSocialAuthClient(
            userIdAfterSignIn: null,
            googleFailure: FirebaseAuthException(
              code: 'invalid-credential',
              message: privateDiagnostic,
            ),
          ),
          googleIdentityGateway: _FakeGoogleIdentityGateway(
            idToken: 'synthetic-id-token',
          ),
          googleStageObserver: stages.add,
        );

        await expectLater(
          gateway.signIn(SocialAuthProvider.google),
          throwsA(
            isA<JourneyServiceException>().having(
              (error) => error.code,
              'code',
              'auth-invalid-credential',
            ),
          ),
        );

        expect(stages, <String>[
          'auth-google-native-request-started',
          'auth-google-firebase-credential-started',
          'auth-google-firebase-exception-code-invalid-credential',
          'auth-google-firebase-cause-credential-rejected',
          'auth-google-firebase-credential-failed',
        ]);
        expect(stages.join(' '), isNot(contains(privateDiagnostic)));
      },
    );

    test('Google Firebase telemetry rejects a non-code payload', () async {
      const privateCodePayload = 'private@example.com';
      final stages = <String>[];
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: _FakeFirebaseSocialAuthClient(
          userIdAfterSignIn: null,
          googleFailure: FirebaseAuthException(code: privateCodePayload),
        ),
        googleIdentityGateway: _FakeGoogleIdentityGateway(
          idToken: 'synthetic-id-token',
        ),
        googleStageObserver: stages.add,
      );

      await expectLater(
        gateway.signIn(SocialAuthProvider.google),
        throwsA(
          isA<JourneyServiceException>().having(
            (error) => error.code,
            'code',
            'auth-firebase-unclassified',
          ),
        ),
      );

      expect(
        stages,
        contains('auth-google-firebase-exception-code-unavailable'),
      );
      expect(stages, contains('auth-google-firebase-cause-unavailable'));
      expect(stages.join(' '), isNot(contains(privateCodePayload)));
    });

    const safeCauseCases = <(String, String, String)>[
      ('unknown', 'App Check token rejected.', 'app-check-rejected'),
      ('unknown', 'API key request blocked.', 'api-key-restriction'),
      (
        'unknown',
        'Identity Toolkit service disabled.',
        'identity-toolkit-unavailable',
      ),
      (
        'blocking-function-error-response',
        'Authentication rejected.',
        'blocking-function-rejected',
      ),
      ('unknown', 'Tenant configuration mismatch.', 'tenant-configuration'),
    ];

    for (final (code, message, expectedCause) in safeCauseCases) {
      test('Google Firebase emits safe $expectedCause cause only', () async {
        final stages = <String>[];
        final gateway = FirebaseSocialAuthGateway.forTesting(
          authClient: _FakeFirebaseSocialAuthClient(
            userIdAfterSignIn: null,
            googleFailure: FirebaseAuthException(code: code, message: message),
          ),
          googleIdentityGateway: _FakeGoogleIdentityGateway(
            idToken: 'synthetic-id-token',
          ),
          googleStageObserver: stages.add,
        );

        await expectLater(
          gateway.signIn(SocialAuthProvider.google),
          throwsA(isA<JourneyServiceException>()),
        );

        expect(stages, contains('auth-google-firebase-exception-code-$code'));
        expect(stages, contains('auth-google-firebase-cause-$expectedCause'));
        expect(stages.join(' '), isNot(contains(message)));
      });
    }

    test('sign-out clears Firebase before the Google account cache', () async {
      final events = <String>[];
      final auth = _FakeFirebaseSocialAuthClient(
        userIdAfterSignIn: 'user-1',
        events: events,
      );
      final google = _FakeGoogleIdentityGateway(
        idToken: 'synthetic-google-id-token',
        events: events,
      );
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: auth,
        googleIdentityGateway: google,
      );

      await gateway.signOut();

      expect(events, ['firebase-sign-out', 'google-sign-out']);
    });

    test('sign-out also clears the configured Facebook SDK session', () async {
      final events = <String>[];
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: _FakeFirebaseSocialAuthClient(
          userIdAfterSignIn: 'user-1',
          events: events,
        ),
        googleIdentityGateway: _FakeGoogleIdentityGateway(
          idToken: 'synthetic-google-id-token',
          events: events,
        ),
        facebookAdapter: _FakeFacebookNativeSdkAdapter(
          signInOutcome: FacebookLoginOutcome.success,
          events: events,
        ),
      );

      await gateway.signOut();

      expect(events, [
        'firebase-sign-out',
        'google-sign-out',
        'facebook-sign-out',
      ]);
    });
  });

  group('NativeGoogleIdentityGateway', () {
    test(
      'official Credential Manager path initializes once before authentication',
      () async {
        var initializeCount = 0;
        var authenticateCount = 0;
        final stages = <String>[];
        final gateway = NativeGoogleIdentityGateway(
          serverClientId: ' synthetic-client-id ',
          initialize: (clientId) async {
            expect(clientId, 'synthetic-client-id');
            initializeCount += 1;
          },
          supportsAuthenticate: () => true,
          authenticateIdToken: () async {
            authenticateCount += 1;
            return 'synthetic-id-token';
          },
          stageObserver: stages.add,
        );

        expect(await gateway.authenticateIdToken(), 'synthetic-id-token');
        expect(initializeCount, 1);
        expect(authenticateCount, 1);
        expect(stages, <String>[
          'auth-google-native-initialize-started',
          'auth-google-native-initialize-complete',
          'auth-google-native-ui-requested',
          'auth-google-native-identity-returned',
        ]);
      },
    );

    test('Credential Manager cancellation emits no-identity stage', () async {
      final stages = <String>[];
      final gateway = NativeGoogleIdentityGateway(
        serverClientId: 'synthetic-client-id',
        initialize: (_) async {},
        supportsAuthenticate: () => true,
        authenticateIdToken: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'private configuration-or-cancellation detail',
        ),
        stageObserver: stages.add,
      );

      expect(await gateway.authenticateIdToken(), isNull);
      expect(stages, contains('auth-google-native-ui-requested'));
      expect(stages, contains('auth-google-native-no-identity'));
      expect(stages.join(' '), isNot(contains('private')));
    });

    test(
      'Google stage telemetry spans native identity and Firebase exchange',
      () async {
        final stages = <String>[];
        final gateway = FirebaseSocialAuthGateway.forTesting(
          authClient: _FakeFirebaseSocialAuthClient(
            userIdAfterSignIn: 'firebase-user',
          ),
          googleIdentityGateway: _FakeGoogleIdentityGateway(
            idToken: 'synthetic-id-token',
          ),
          googleStageObserver: stages.add,
        );

        final result = await gateway.signIn(SocialAuthProvider.google);

        expect(result.outcome, SocialAuthOutcome.authenticated);
        expect(stages, <String>[
          'auth-google-native-request-started',
          'auth-google-firebase-credential-started',
          'auth-google-firebase-credential-complete',
        ]);
      },
    );

    test(
      'missing release client configuration fails before native UI',
      () async {
        var initializeCount = 0;
        final gateway = NativeGoogleIdentityGateway(
          serverClientId: '   ',
          initialize: (_) async => initializeCount += 1,
          supportsAuthenticate: () => true,
          authenticateIdToken: () async => 'unused',
        );

        await expectLater(
          gateway.authenticateIdToken(),
          throwsA(
            isA<JourneyServiceException>().having(
              (error) => error.userMessage,
              'message',
              contains('not configured'),
            ),
          ),
        );
        expect(initializeCount, 0);
      },
    );

    test('native cancellation maps to a cancelled identity result', () async {
      final gateway = NativeGoogleIdentityGateway(
        serverClientId: 'synthetic-client-id',
        initialize: (_) async {},
        supportsAuthenticate: () => true,
        authenticateIdToken: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      );

      expect(await gateway.authenticateIdToken(), isNull);
    });

    test(
      'native configuration detail is replaced with safe customer copy',
      () async {
        final gateway = NativeGoogleIdentityGateway(
          serverClientId: 'synthetic-client-id',
          initialize: (_) async {},
          supportsAuthenticate: () => true,
          authenticateIdToken: () async => throw const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
            description: 'internal configuration diagnostic',
          ),
        );

        await expectLater(
          gateway.authenticateIdToken(),
          throwsA(
            isA<JourneyServiceException>()
                .having(
                  (error) => error.userMessage,
                  'message',
                  'Google sign-in is not configured for this app. '
                      'Choose another method.',
                )
                .having(
                  (error) => error.userMessage,
                  'safe message',
                  isNot(contains('diagnostic')),
                ),
          ),
        );
      },
    );

    test('initializes exactly once across a retry', () async {
      var initializeCount = 0;
      var authenticateCount = 0;
      final gateway = NativeGoogleIdentityGateway(
        serverClientId: ' synthetic-client-id ',
        initialize: (clientId) async {
          expect(clientId, 'synthetic-client-id');
          initializeCount += 1;
        },
        supportsAuthenticate: () => true,
        authenticateIdToken: () async {
          authenticateCount += 1;
          return 'synthetic-id-token-$authenticateCount';
        },
      );

      expect(await gateway.authenticateIdToken(), isNotEmpty);
      expect(await gateway.authenticateIdToken(), isNotEmpty);
      expect(initializeCount, 1);
      expect(authenticateCount, 2);
    });

    test('failed initialization is not cached across a retry', () async {
      var initializeCount = 0;
      var authenticateCount = 0;
      final gateway = NativeGoogleIdentityGateway(
        serverClientId: 'synthetic-client-id',
        initialize: (_) async {
          initializeCount += 1;
          if (initializeCount == 1) {
            throw const GoogleSignInException(
              code: GoogleSignInExceptionCode.clientConfigurationError,
            );
          }
        },
        supportsAuthenticate: () => true,
        authenticateIdToken: () async {
          authenticateCount += 1;
          return 'synthetic-id-token';
        },
      );

      await expectLater(
        gateway.authenticateIdToken(),
        throwsA(
          isA<JourneyServiceException>().having(
            (error) => error.code,
            'code',
            'auth-client-configuration',
          ),
        ),
      );
      expect(await gateway.authenticateIdToken(), 'synthetic-id-token');
      expect(initializeCount, 2);
      expect(authenticateCount, 1);
    });

    test(
      'native Android identity return is bounded by a safe timeout',
      () async {
        final gateway = NativeGoogleIdentityGateway(
          serverClientId: 'synthetic-client-id',
          authenticationTimeout: const Duration(milliseconds: 5),
          initialize: (_) async {},
          supportsAuthenticate: () => true,
          authenticateIdToken: () => Completer<String?>().future,
        );

        await expectLater(
          gateway.authenticateIdToken(),
          throwsA(
            isA<JourneyServiceException>().having(
              (error) => error.code,
              'code',
              'auth-native-return-timeout',
            ),
          ),
        );
      },
    );

    test('Firebase credential exchange is bounded by a safe timeout', () async {
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: _FakeFirebaseSocialAuthClient(
          userIdAfterSignIn: null,
          googleResult: Completer<String?>().future,
        ),
        googleIdentityGateway: _FakeGoogleIdentityGateway(
          idToken: 'synthetic-id-token',
        ),
        firebaseCredentialTimeout: const Duration(milliseconds: 5),
      );

      await expectLater(
        gateway.signIn(SocialAuthProvider.google),
        throwsA(
          isA<JourneyServiceException>().having(
            (error) => error.code,
            'code',
            'auth-firebase-credential-timeout',
          ),
        ),
      );
    });
  });
}

class _FakeGoogleIdentityGateway implements GoogleIdentityGateway {
  _FakeGoogleIdentityGateway({required this.idToken, this.events});

  final String? idToken;
  final List<String>? events;
  int authenticateCount = 0;

  @override
  Future<String?> authenticateIdToken() async {
    authenticateCount += 1;
    return idToken;
  }

  @override
  Future<void> signOut() async {
    events?.add('google-sign-out');
  }
}

class _FakeFirebaseSocialAuthClient implements FirebaseSocialAuthClient {
  _FakeFirebaseSocialAuthClient({
    required this.userIdAfterSignIn,
    this.events,
    this.googleFailure,
    this.providerFailure,
    this.currentUserIdValue,
    this.googleResult,
  });

  final String? userIdAfterSignIn;
  final List<String>? events;
  final Object? googleFailure;
  final Object? providerFailure;
  final String? currentUserIdValue;
  final Future<String?>? googleResult;
  int googleCredentialCount = 0;
  int genericProviderCount = 0;
  AuthProvider? lastProvider;

  @override
  String? get currentUserId => currentUserIdValue;

  @override
  Future<String?> signInWithGoogleIdToken(String idToken) async {
    googleCredentialCount += 1;
    if (googleFailure case final failure?) throw failure;
    if (googleResult case final result?) return result;
    return userIdAfterSignIn;
  }

  @override
  Future<String?> signInWithProvider(AuthProvider provider) async {
    genericProviderCount += 1;
    lastProvider = provider;
    if (providerFailure case final failure?) throw failure;
    return userIdAfterSignIn;
  }

  @override
  Future<void> signOut() async {
    events?.add('firebase-sign-out');
  }
}

final class _FakeFacebookNativeSdkAdapter implements FacebookNativeSdkAdapter {
  _FakeFacebookNativeSdkAdapter({
    required this.signInOutcome,
    this.signInOrigin = FacebookLoginOrigin.completed,
    this.events,
  });

  final FacebookLoginOutcome signInOutcome;
  final FacebookLoginOrigin signInOrigin;
  final List<String>? events;
  int signInCount = 0;
  int logOutCount = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<FacebookLoginResult> signIn() async {
    signInCount += 1;
    return FacebookLoginResult(outcome: signInOutcome, origin: signInOrigin);
  }

  @override
  Future<FacebookLoginOutcome> logOut() async {
    logOutCount += 1;
    events?.add('facebook-sign-out');
    return FacebookLoginOutcome.success;
  }

  @override
  Future<FacebookLoginOutcome> revokeAccess() async =>
      FacebookLoginOutcome.success;
}
