import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/review_journey_services.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/login_screen_v5.dart';

void main() {
  MemoryJourneyStore completedSetupStore() => MemoryJourneyStore(
    snapshot: const JourneySnapshot(
      languageCode: 'en',
      areaMode: 'current',
      currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
      setupComplete: true,
    ),
  );

  test('main composes the explicit live global social login audit lane', () {
    final source = File('lib/main.dart').readAsStringSync();

    for (final token in const [
      "'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT'",
      "'MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE'",
      'resolveGlobalSocialLoginAuditComposition(',
      '_globalSocialLoginAuditMode && !_googleOnlyForensicMode',
      'googleOnlyForensicMode: _googleOnlyForensicMode',
      'globalSocialLoginAuditComposition.useReviewAuthentication',
      '.useProductionProviderAvailability',
      'FirebaseAuthenticatedSessionBootstrapGateway(',
      'globalSocialLoginAudit: _globalSocialLoginAuditMode',
    ]) {
      expect(source, contains(token), reason: token);
    }
  });

  test('Android Credential Manager plugin is complete and legacy bridge absent', () {
    final activity = File(
      'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
    ).readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();
    final gateway = File(
      'lib/features/journey01/review_journey_services.dart',
    ).readAsStringSync();
    final googleBridge = _googleIdentityBridgeBlocks(activity);

    for (final token in const <String>[
      'Official google_sign_in owns the Android Credential Manager integration.',
      'GeneratedPluginRegistrant registers the official Google identity plugin.',
      'No legacy activity-result identity bridge is permitted in the FIX11 path.',
    ]) {
      expect(activity, contains(token), reason: token);
    }
    for (final forbidden in const <String>[
      'com.moolsocial.app/google_identity',
      'GoogleSignInOptions',
      'GoogleSignIn.getSignedInAccountFromIntent',
    ]) {
      expect(activity, isNot(contains(forbidden)), reason: forbidden);
      expect(gateway, isNot(contains(forbidden)), reason: forbidden);
    }
    expect(
      googleBridge,
      isNot(contains('startActivityForResult')),
      reason: 'legacy Google activity-result bridge',
    );
    expect(
      gateway,
      isNot(contains('startActivityForResult')),
      reason: 'legacy Google activity-result bridge',
    );
    expect(gradle, isNot(contains('play-services-auth')));
    expect(lock, contains('google_sign_in_android:'));
    expect(lock, contains('version: "7.2.16"'));
    for (final token in const <String>[
      'GoogleSignIn.instance.initialize(',
      'GoogleSignIn.instance.authenticate()',
      "'auth-google-native-ui-requested'",
      "'auth-google-native-no-identity'",
      "'auth-google-firebase-credential-complete'",
      'GoogleAuthProvider.credential(idToken: idToken)',
      '_auth.signInWithCredential(credential)',
      "'auth-google-firebase-exception-code-'",
    ]) {
      expect(gateway, contains(token), reason: token);
    }
  });

  test('Firebase session bootstrap accepts one verified user', () async {
    final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
      verifiedUserId: () async => 'firebase-user',
    );

    final result = await gateway.prepareAuthenticatedAccount();

    expect(result.state, AuthenticatedAccountBootstrapState.verified);
    expect(result.currentBinding, isNotNull);
    expect(result.toString(), isNot(contains('firebase-user')));
  });

  test(
    'interactive bootstrap skips reload and binds the credential UID',
    () async {
      var revalidatedCount = 0;
      var interactiveCount = 0;
      final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
        verifiedUserId: () async {
          revalidatedCount += 1;
          throw StateError('reload should not run');
        },
        interactiveVerifiedUserId: () async {
          interactiveCount += 1;
          return 'firebase-user';
        },
      );

      final result = await gateway.prepareAuthenticatedAccount(
        expectedUserId: 'firebase-user',
      );
      expect(result.state, AuthenticatedAccountBootstrapState.verified);
      expect(interactiveCount, 1);
      expect(revalidatedCount, 0);
    },
  );

  test(
    'interactive bootstrap rejects a different current Firebase UID',
    () async {
      final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
        verifiedUserId: () async => 'unused-relaunch-user',
        interactiveVerifiedUserId: () async => 'different-user',
      );

      final result = await gateway.prepareAuthenticatedAccount(
        expectedUserId: 'firebase-user',
      );
      expect(result.state, AuthenticatedAccountBootstrapState.invalidSession);
      expect(result.code, 'auth-session-user-mismatch');
      expect(result.currentBinding, isNull);
    },
  );

  test('Firebase session bootstrap rejects a missing user', () async {
    final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
      verifiedUserId: () async => null,
    );

    final result = await gateway.prepareAuthenticatedAccount();

    expect(result.state, AuthenticatedAccountBootstrapState.invalidSession);
    expect(result.code, 'auth-session-missing');
    expect(result.currentBinding, isNull);
  });

  test('Firebase session bootstrap sanitizes verification failure', () async {
    final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
      verifiedUserId: () async => throw StateError('private failure'),
    );

    final result = await gateway.prepareAuthenticatedAccount();

    expect(result.state, AuthenticatedAccountBootstrapState.fatal);
    expect(result.code, 'auth-session-verification-fatal');
    expect(result.toString(), isNot(contains('private failure')));
  });

  group('verified principal binding security', () {
    test(
      'secure HMAC binding is opaque, deterministic and install-scoped',
      () async {
        final values = <String, String?>{};
        var secretCreationCount = 0;
        final store = SecureVerifiedPrincipalBindingStore.forTesting(
          readValue: ({required key}) async => values[key],
          writeValue: ({required key, required value}) async {
            values[key] = value;
          },
          deleteValue: ({required key}) async {
            values.remove(key);
          },
          createSecret: () {
            secretCreationCount += 1;
            return List<int>.generate(32, (index) => index);
          },
        );

        final first = await store.protect('private-user-a');
        final repeated = await store.protect('private-user-a');
        final different = await store.protect('private-user-b');
        await store.write(first);

        expect(first.matches(repeated), isTrue);
        expect(first.matches(different), isFalse);
        expect(first.storageValue, matches(RegExp(r'^v1:[0-9a-f]{64}$')));
        expect(first.toString(), 'VerifiedPrincipalBinding(redacted)');
        expect(values.values.join('|'), isNot(contains('private-user-a')));
        expect(secretCreationCount, 1);
        expect((await store.read())!.matches(first), isTrue);
      },
    );

    test('concurrent first use creates one install secret', () async {
      final values = <String, String?>{};
      var secretCreationCount = 0;
      var secretWriteCount = 0;
      final store = SecureVerifiedPrincipalBindingStore.forTesting(
        readValue: ({required key}) async {
          await Future<void>.delayed(Duration.zero);
          return values[key];
        },
        writeValue: ({required key, required value}) async {
          values[key] = value;
          if (key.contains('secret')) secretWriteCount += 1;
        },
        deleteValue: ({required key}) async {
          values.remove(key);
        },
        createSecret: () {
          secretCreationCount += 1;
          return List<int>.filled(32, 7);
        },
      );

      await Future.wait([
        store.protect('principal-a'),
        store.protect('principal-b'),
        store.protect('principal-c'),
      ]);

      expect(secretCreationCount, 1);
      expect(secretWriteCount, 1);
    });

    test('missing install secret never accepts an existing receipt', () async {
      final receipt = 'v1:${List.filled(64, 'a').join()}';
      final store = SecureVerifiedPrincipalBindingStore.forTesting(
        readValue: ({required key}) async =>
            key.contains('secret') ? null : receipt,
        writeValue: ({required key, required value}) async {},
        deleteValue: ({required key}) async {},
        createSecret: () => List<int>.filled(32, 1),
      );

      await expectLater(
        store.protect('private-user'),
        throwsA(
          isA<JourneyServiceException>().having(
            (error) => error.code,
            'code',
            'auth-binding-secret-missing',
          ),
        ),
      );
    });

    test('corrupt or unknown receipt version fails closed', () async {
      final store = SecureVerifiedPrincipalBindingStore.forTesting(
        readValue: ({required key}) async => 'v2:not-a-valid-receipt',
        writeValue: ({required key, required value}) async {},
        deleteValue: ({required key}) async {},
        createSecret: () => List<int>.filled(32, 1),
      );

      await expectLater(
        store.read(),
        throwsA(
          isA<JourneyServiceException>().having(
            (error) => error.code,
            'code',
            'auth-binding-read-failed',
          ),
        ),
      );
    });

    test(
      'same UID binds differently under different install secrets',
      () async {
        SecureVerifiedPrincipalBindingStore storeFor(int byte) {
          final values = <String, String?>{};
          return SecureVerifiedPrincipalBindingStore.forTesting(
            readValue: ({required key}) async => values[key],
            writeValue: ({required key, required value}) async {
              values[key] = value;
            },
            deleteValue: ({required key}) async {
              values.remove(key);
            },
            createSecret: () => List<int>.filled(32, byte),
          );
        }

        final first = await storeFor(1).protect('private-user');
        final second = await storeFor(2).protect('private-user');

        expect(first.matches(second), isFalse);
      },
    );

    test(
      'opaque UID whitespace is bound exactly and never normalized',
      () async {
        final review = const ReviewPrincipalBindingProtector();
        final plain = await review.protect('private-user');
        final padded = await review.protect(' private-user ');
        final whitespace = await review.protect(' ');

        expect(plain.matches(padded), isFalse);
        expect(plain.matches(whitespace), isFalse);
        await expectLater(
          review.protect(''),
          throwsA(
            isA<JourneyServiceException>().having(
              (error) => error.code,
              'code',
              'auth-session-missing',
            ),
          ),
        );

        final values = <String, String?>{};
        final secure = SecureVerifiedPrincipalBindingStore.forTesting(
          readValue: ({required key}) async => values[key],
          writeValue: ({required key, required value}) async {
            values[key] = value;
          },
          deleteValue: ({required key}) async {
            values.remove(key);
          },
          createSecret: () => List<int>.filled(32, 9),
        );
        expect(
          (await secure.protect(
            'private-user',
          )).matches(await secure.protect(' private-user ')),
          isFalse,
        );
      },
    );

    test('missing secret resets local session before fresh sign-in', () async {
      final values = <String, String?>{};
      SecureVerifiedPrincipalBindingStore createStore() =>
          SecureVerifiedPrincipalBindingStore.forTesting(
            readValue: ({required key}) async => values[key],
            writeValue: ({required key, required value}) async {
              values[key] = value;
            },
            deleteValue: ({required key}) async {
              values.remove(key);
            },
            createSecret: () => List<int>.filled(32, 5),
          );

      final seedStore = createStore();
      final binding = await seedStore.protect('private-user');
      await seedStore.write(binding);
      values.remove(values.keys.singleWhere((key) => key.contains('secret')));

      var invalidationCount = 0;
      final runtimeStore = createStore();
      final bootstrap = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
        currentUserId: () async => 'private-user',
        verifiedUserId: () async => 'private-user',
        bindingProtector: runtimeStore,
        invalidateLocalSession: () async {
          invalidationCount += 1;
        },
      );
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: ReviewSocialAuthGateway(signedIn: true),
        accountBootstrapGateway: bootstrap,
        verifiedPrincipalBindingStore: runtimeStore,
      );
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.signIn);
      expect(session.isAuthenticated, isFalse);
      expect(invalidationCount, 1);
      expect(values, isEmpty);
    });

    test(
      'corrupt install secret resets local session before fresh sign-in',
      () async {
        final values = <String, String?>{};
        SecureVerifiedPrincipalBindingStore createStore() =>
            SecureVerifiedPrincipalBindingStore.forTesting(
              readValue: ({required key}) async => values[key],
              writeValue: ({required key, required value}) async {
                values[key] = value;
              },
              deleteValue: ({required key}) async {
                values.remove(key);
              },
              createSecret: () => List<int>.filled(32, 6),
            );

        final seedStore = createStore();
        final binding = await seedStore.protect('private-user');
        await seedStore.write(binding);
        values[values.keys.singleWhere((key) => key.contains('secret'))] =
            'not-valid-base64';

        var invalidationCount = 0;
        final runtimeStore = createStore();
        final session = JourneySession(
          store: completedSetupStore(),
          socialAuthGateway: ReviewSocialAuthGateway(signedIn: true),
          accountBootstrapGateway:
              FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
                currentUserId: () async => 'private-user',
                verifiedUserId: () async => 'private-user',
                bindingProtector: runtimeStore,
                invalidateLocalSession: () async {
                  invalidationCount += 1;
                },
              ),
          verifiedPrincipalBindingStore: runtimeStore,
        );
        addTearDown(session.dispose);

        await session.start();

        expect(session.stage, JourneyStage.signIn);
        expect(session.isAuthenticated, isFalse);
        expect(invalidationCount, 1);
        expect(values, isEmpty);
      },
    );

    test(
      'unsafe reset attempts both deletes and reports any failure',
      () async {
        final values = <String, String?>{};
        final deleted = <String>[];
        final seedStore = SecureVerifiedPrincipalBindingStore.forTesting(
          readValue: ({required key}) async => values[key],
          writeValue: ({required key, required value}) async {
            values[key] = value;
          },
          deleteValue: ({required key}) async {
            values.remove(key);
          },
          createSecret: () => List<int>.filled(32, 4),
        );
        await seedStore.write(await seedStore.protect('private-user'));
        final runtimeStore = SecureVerifiedPrincipalBindingStore.forTesting(
          readValue: ({required key}) async => values[key],
          writeValue: ({required key, required value}) async {
            values[key] = value;
          },
          deleteValue: ({required key}) async {
            deleted.add(key);
            if (key.contains('secret')) {
              throw StateError('private delete failure');
            }
            values.remove(key);
          },
          createSecret: () => List<int>.filled(32, 4),
        );

        await expectLater(
          runtimeStore.resetUnsafeState(),
          throwsA(
            isA<JourneyServiceException>().having(
              (error) => error.code,
              'code',
              'auth-binding-reset-failed',
            ),
          ),
        );

        expect(deleted.length, 2);
        expect(
          deleted.any((key) => key.contains('verified_principal')),
          isTrue,
        );
        expect(deleted.any((key) => key.contains('secret')), isTrue);
      },
    );
  });

  group('typed Firebase principal revalidation', () {
    test('interactive expected UID comparison uses exact bytes', () async {
      final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
        verifiedUserId: () async => 'unused',
        interactiveVerifiedUserId: () async => ' private-user ',
      );

      final exact = await gateway.prepareAuthenticatedAccount(
        expectedUserId: ' private-user ',
      );
      final normalized = await gateway.prepareAuthenticatedAccount(
        expectedUserId: 'private-user',
      );

      expect(exact.state, AuthenticatedAccountBootstrapState.verified);
      expect(
        normalized.state,
        AuthenticatedAccountBootstrapState.invalidSession,
      );
      expect(normalized.code, 'auth-session-user-mismatch');
    });

    test('explicit network failure is retryable with local binding', () async {
      final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
        currentUserId: () async => 'private-user',
        verifiedUserId: () async => throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'private network detail',
        ),
      );

      final result = await gateway.prepareAuthenticatedAccount();

      expect(
        result.state,
        AuthenticatedAccountBootstrapState.retryableUnavailable,
      );
      expect(result.code, 'auth-session-network-unavailable');
      expect(result.currentBinding, isNotNull);
      expect(result.toString(), isNot(contains('private-user')));
      expect(result.toString(), isNot(contains('private network detail')));
    });

    for (final code in const [
      'web-network-request-failed',
      'too-many-requests',
    ]) {
      test('$code is retryable only with a local binding', () async {
        final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
          currentUserId: () async => 'private-user',
          verifiedUserId: () async =>
              throw FirebaseAuthException(code: code, message: 'private'),
        );

        final result = await gateway.prepareAuthenticatedAccount();

        expect(
          result.state,
          AuthenticatedAccountBootstrapState.retryableUnavailable,
        );
        expect(result.currentBinding, isNotNull);
      });
    }

    test('missing local principal is invalid before network work', () async {
      var revalidationCount = 0;
      final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
        currentUserId: () async => null,
        verifiedUserId: () async {
          revalidationCount += 1;
          return 'private-user';
        },
      );

      final result = await gateway.prepareAuthenticatedAccount();

      expect(result.state, AuthenticatedAccountBootstrapState.invalidSession);
      expect(result.code, 'auth-session-missing');
      expect(result.currentBinding, isNull);
      expect(revalidationCount, 0);
    });

    for (final code in const [
      'user-disabled',
      'user-token-expired',
      'invalid-user-token',
      'user-not-found',
    ]) {
      test('$code is invalid-session and never retryable', () async {
        final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
          currentUserId: () async => 'private-user',
          verifiedUserId: () async =>
              throw FirebaseAuthException(code: code, message: 'private'),
        );

        final result = await gateway.prepareAuthenticatedAccount();

        expect(result.state, AuthenticatedAccountBootstrapState.invalidSession);
        expect(result.currentBinding, isNull);
      });
    }

    test('principal change across reload is invalid-session', () async {
      final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
        currentUserId: () async => 'private-user-a',
        verifiedUserId: () async => 'private-user-b',
      );

      final result = await gateway.prepareAuthenticatedAccount();

      expect(result.state, AuthenticatedAccountBootstrapState.invalidSession);
      expect(result.code, 'auth-session-user-mismatch');
      expect(result.currentBinding, isNull);
    });

    test('unknown and TLS-like failures default fatal', () async {
      for (final failure in <Object>[
        StateError('private parse detail'),
        const HandshakeException('private TLS detail'),
      ]) {
        final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
          currentUserId: () async => 'private-user',
          verifiedUserId: () async => throw failure,
        );

        final result = await gateway.prepareAuthenticatedAccount();

        expect(result.state, AuthenticatedAccountBootstrapState.fatal);
        expect(result.code, 'auth-session-verification-fatal');
        expect(result.currentBinding, isNull);
        expect(result.toString(), isNot(contains('private')));
      }
    });
  });

  group('Data Connect account bootstrap boundary', () {
    test('retryable principal result prevents account upsert', () async {
      final binding = await const ReviewPrincipalBindingProtector().protect(
        'private-user',
      );
      var upsertCount = 0;
      final gateway = DataConnectAccountBootstrapGateway.forTesting(
        ReviewAccountBootstrapGateway(
          result: AuthenticatedAccountBootstrapResult.retryableUnavailable(
            binding,
          ),
          currentBinding: binding,
        ),
        () async {
          upsertCount += 1;
        },
      );

      final result = await gateway.prepareAuthenticatedAccount();

      expect(
        result.state,
        AuthenticatedAccountBootstrapState.retryableUnavailable,
      );
      expect(upsertCount, 0);
    });

    for (final principalState in const [
      AuthenticatedAccountBootstrapState.invalidSession,
      AuthenticatedAccountBootstrapState.fatal,
    ]) {
      test(
        '${principalState.name} principal result prevents account upsert',
        () async {
          var upsertCount = 0;
          final principalResult =
              principalState ==
                  AuthenticatedAccountBootstrapState.invalidSession
              ? const AuthenticatedAccountBootstrapResult.invalidSession()
              : const AuthenticatedAccountBootstrapResult.fatal();
          final gateway = DataConnectAccountBootstrapGateway.forTesting(
            ReviewAccountBootstrapGateway(result: principalResult),
            () async {
              upsertCount += 1;
            },
          );

          final result = await gateway.prepareAuthenticatedAccount();

          expect(result.state, principalState);
          expect(upsertCount, 0);
        },
      );
    }

    test(
      'verified principal and account upsert retain exact binding',
      () async {
        final binding = await const ReviewPrincipalBindingProtector().protect(
          'private-user',
        );
        var upsertCount = 0;
        final gateway = DataConnectAccountBootstrapGateway.forTesting(
          ReviewAccountBootstrapGateway(
            result: AuthenticatedAccountBootstrapResult.verified(binding),
            currentBinding: binding,
          ),
          () async {
            upsertCount += 1;
          },
        );

        final result = await gateway.prepareAuthenticatedAccount();

        expect(result.state, AuthenticatedAccountBootstrapState.verified);
        expect(result.currentBinding!.matches(binding), isTrue);
        expect(upsertCount, 1);
      },
    );

    test('unknown account upsert failure is fatal and sanitized', () async {
      final binding = await const ReviewPrincipalBindingProtector().protect(
        'private-user',
      );
      final gateway = DataConnectAccountBootstrapGateway.forTesting(
        ReviewAccountBootstrapGateway(
          result: AuthenticatedAccountBootstrapResult.verified(binding),
          currentBinding: binding,
        ),
        () async => throw StateError('private account failure'),
      );

      final result = await gateway.prepareAuthenticatedAccount();

      expect(result.state, AuthenticatedAccountBootstrapState.fatal);
      expect(result.code, 'auth-account-bootstrap-fatal');
      expect(result.currentBinding, isNull);
      expect(result.toString(), isNot(contains('private account failure')));
    });
  });

  test(
    'provider success completes through the verified Firebase session',
    () async {
      var bootstrapCount = 0;
      final social = ReviewSocialAuthGateway(
        results: const {
          SocialAuthProvider.google: SocialAuthResult.authenticated(
            'firebase-user',
            code: 'auth-google-firebase-credential-complete',
          ),
        },
      );
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: social,
        accountBootstrapGateway:
            FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
              verifiedUserId: () async {
                bootstrapCount += 1;
                return 'firebase-user';
              },
            ),
        availableSocialAuthProviders: const {SocialAuthProvider.google},
      );
      addTearDown(session.dispose);
      await session.start();

      expect(await session.signInWithSocial(SocialAuthProvider.google), isTrue);
      expect(bootstrapCount, 1);
      expect(session.isAuthenticated, isTrue);
      expect(session.stage, JourneyStage.ready);
      expect(session.socialAuthReceiptCode, 'auth-session-ready');
      expect(session.socialAuthReceiptSequence, const <String>[
        'auth-started',
        'auth-google-firebase-credential-complete',
        'auth-session-ready',
      ]);
      expect(session.readyRoute(), '/app/social');
    },
  );

  test('bootstrap rejection rolls back the partial provider session', () async {
    final social = ReviewSocialAuthGateway(
      results: const {
        SocialAuthProvider.x: SocialAuthResult.authenticated('firebase-user'),
      },
    );
    final session = JourneySession(
      store: completedSetupStore(),
      socialAuthGateway: social,
      accountBootstrapGateway:
          FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
            verifiedUserId: () async => null,
          ),
      availableSocialAuthProviders: const {SocialAuthProvider.x},
    );
    addTearDown(session.dispose);
    await session.start();

    expect(await session.signInWithSocial(SocialAuthProvider.x), isFalse);
    expect(social.signOutCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(session.stage, JourneyStage.signIn);
    expect(session.socialAuthReceiptCode, 'auth-session-missing');
    expect(session.errorMessage, contains('sign in again'));
  });

  test('failed rollback blocks a second provider attempt', () async {
    final social = ReviewSocialAuthGateway(
      results: const {
        SocialAuthProvider.x: SocialAuthResult.authenticated('firebase-user'),
      },
      signOutFailure: StateError('private cleanup failure'),
    );
    final session = JourneySession(
      store: completedSetupStore(),
      socialAuthGateway: social,
      accountBootstrapGateway:
          FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
            verifiedUserId: () async => null,
          ),
      availableSocialAuthProviders: const {SocialAuthProvider.x},
      socialAuthRollbackTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(session.dispose);
    await session.start();

    expect(await session.signInWithSocial(SocialAuthProvider.x), isFalse);
    expect(session.socialAuthReceiptCode, 'auth-rollback-failed');
    expect(session.socialAuthCleanupRequired, isTrue);
    expect(social.signInCount, 1);

    expect(await session.signInWithSocial(SocialAuthProvider.x), isFalse);
    expect(social.signInCount, 1);
    expect(social.signOutCount, 2);
    expect(session.stage, isNot(JourneyStage.ready));
  });

  test(
    'bootstrap timeout is stage-specific before any successor APK',
    () async {
      final never = Completer<String?>();
      final social = ReviewSocialAuthGateway(
        results: const {
          SocialAuthProvider.google: SocialAuthResult.authenticated(
            'firebase-user',
            code: 'auth-google-firebase-credential-complete',
          ),
        },
      );
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: social,
        accountBootstrapGateway:
            FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
              verifiedUserId: () => never.future,
            ),
        accountBootstrapTimeout: const Duration(milliseconds: 5),
        availableSocialAuthProviders: const {SocialAuthProvider.google},
      );
      addTearDown(session.dispose);
      await session.start();

      expect(
        await session.signInWithSocial(SocialAuthProvider.google),
        isFalse,
      );
      expect(session.socialAuthReceiptCode, 'auth-session-timeout');
      expect(session.isAuthenticated, isFalse);
      expect(social.signOutCount, 1);
      expect(session.errorMessage, contains('did not respond'));
    },
  );

  test('authenticated relaunch re-verifies before restoring ready', () async {
    var bootstrapCount = 0;
    final social = ReviewSocialAuthGateway(signedIn: true);
    final session = JourneySession(
      store: completedSetupStore(),
      socialAuthGateway: social,
      accountBootstrapGateway:
          FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
            verifiedUserId: () async {
              bootstrapCount += 1;
              return 'firebase-user';
            },
          ),
    );
    addTearDown(session.dispose);

    await session.start();

    expect(bootstrapCount, 1);
    expect(session.isAuthenticated, isTrue);
    expect(session.stage, JourneyStage.ready);
    expect(session.readyRoute(), '/app/social');
  });

  for (final provider in const <SocialAuthProvider>[
    SocialAuthProvider.x,
    SocialAuthProvider.instagram,
  ]) {
    testWidgets(
      '${provider.name} browser-open pending state is not shown as failure',
      (tester) async {
        final social = ReviewSocialAuthGateway(
          results: <SocialAuthProvider, SocialAuthResult>{
            provider: const SocialAuthResult.authorizationPending(),
          },
        );
        final session = JourneySession(
          store: completedSetupStore(),
          socialAuthGateway: social,
          availableSocialAuthProviders: <SocialAuthProvider>{provider},
        );
        addTearDown(session.dispose);
        await session.start();

        await tester.pumpWidget(
          MaterialApp(home: LoginScreenV5(session: session)),
        );
        final providerButton = find.byKey(
          Key('screen03-v5-provider-${provider.name}'),
        );
        await tester.ensureVisible(providerButton);
        await tester.tap(providerButton);
        await tester.pumpAndSettle();

        expect(session.socialAuthState, SocialAuthState.pending);
        expect(session.socialAuthReceiptCode, 'auth-browser-opened');
        expect(session.noticeMessage, contains('secure browser'));
        expect(find.byKey(const Key('social-auth-message')), findsNothing);
        expect(find.byKey(const Key('social-auth-retry')), findsNothing);
      },
    );
  }

  testWidgets('cancelled provider still opens truthful recovery', (
    tester,
  ) async {
    final session = JourneySession(
      store: completedSetupStore(),
      socialAuthGateway: ReviewSocialAuthGateway(),
      availableSocialAuthProviders: const <SocialAuthProvider>{
        SocialAuthProvider.google,
      },
    );
    addTearDown(session.dispose);
    await session.start();

    await tester.pumpWidget(MaterialApp(home: LoginScreenV5(session: session)));
    final providerButton = find.byKey(const Key('screen03-v5-provider-google'));
    await tester.ensureVisible(providerButton);
    await tester.tap(providerButton);
    await tester.pumpAndSettle();

    expect(session.socialAuthState, SocialAuthState.cancelled);
    expect(session.socialAuthReceiptCode, 'auth-cancelled');
    expect(find.byKey(const Key('social-auth-message')), findsOneWidget);
    expect(find.byKey(const Key('social-auth-retry')), findsOneWidget);
  });

  testWidgets(
    'Google no-identity return preserves stage code and sanitized recovery',
    (tester) async {
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: ReviewSocialAuthGateway(
          results: const <SocialAuthProvider, SocialAuthResult>{
            SocialAuthProvider.google: SocialAuthResult.cancelled(
              code: 'auth-google-native-no-identity',
            ),
          },
        ),
        availableSocialAuthProviders: const <SocialAuthProvider>{
          SocialAuthProvider.google,
        },
      );
      addTearDown(session.dispose);
      await session.start();

      await tester.pumpWidget(
        MaterialApp(home: LoginScreenV5(session: session)),
      );
      final providerButton = find.byKey(
        const Key('screen03-v5-provider-google'),
      );
      await tester.ensureVisible(providerButton);
      await tester.tap(providerButton);
      await tester.pumpAndSettle();

      expect(session.socialAuthState, SocialAuthState.cancelled);
      expect(session.socialAuthReceiptCode, 'auth-google-native-no-identity');
      expect(find.textContaining('GSI-N01'), findsOneWidget);
      expect(find.byKey(const Key('social-auth-retry')), findsOneWidget);
    },
  );

  test(
    'sanitized provider failure code remains transiently observable',
    () async {
      final social = ReviewSocialAuthGateway(
        failures: const <SocialAuthProvider, Object>{
          SocialAuthProvider.facebook: JourneyServiceException(
            'Facebook sign-in could not reach the provider.',
            code: 'auth-facebook-firebase-network',
          ),
        },
      );
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: social,
        availableSocialAuthProviders: const <SocialAuthProvider>{
          SocialAuthProvider.facebook,
        },
      );
      addTearDown(session.dispose);
      await session.start();

      expect(
        await session.signInWithSocial(SocialAuthProvider.facebook),
        isFalse,
      );
      expect(session.socialAuthState, SocialAuthState.failed);
      expect(session.socialAuthReceiptCode, 'auth-facebook-firebase-network');
      session.clearSocialAuthResult();
      expect(session.socialAuthReceiptCode, isNull);
    },
  );

  testWidgets('unavailable auth methods are physically non-actionable', (
    tester,
  ) async {
    final session = JourneySession(
      store: completedSetupStore(),
      availableSocialAuthProviders: const <SocialAuthProvider>{},
      emailLinkAvailable: false,
      mobileOtpAvailable: false,
    );
    addTearDown(session.dispose);
    await session.start();

    await tester.pumpWidget(MaterialApp(home: LoginScreenV5(session: session)));

    final appleButton = tester.widget<InkWell>(
      find.byKey(const Key('screen03-v5-provider-apple')),
    );
    expect(appleButton.onTap, isNull);

    for (final methodKey in const <Key>[
      Key('email-link-method'),
      Key('mobile-otp-method'),
    ]) {
      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(methodKey),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.onTap, isNull, reason: methodKey.toString());
    }
    expect(find.text('Not available on this build'), findsNWidgets(2));
  });

  testWidgets('login legal actions open only exact public destinations', (
    tester,
  ) async {
    final opened = <Uri>[];
    final session = JourneySession(
      store: completedSetupStore(),
      availableSocialAuthProviders: const <SocialAuthProvider>{},
      emailLinkAvailable: true,
      mobileOtpAvailable: false,
    );
    addTearDown(session.dispose);
    await session.start();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreenV5(
          session: session,
          legalUrlLauncher: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );

    for (final linkKey in const <Key>[
      Key('screen03-terms-link'),
      Key('screen03-privacy-link'),
    ]) {
      await tester.ensureVisible(find.byKey(linkKey));
      await tester.tap(find.byKey(linkKey));
      await tester.pump();
    }

    expect(opened, <Uri>[
      Uri.parse('https://moolsocial.com/terms/'),
      Uri.parse('https://moolsocial.com/privacy/'),
    ]);
  });
}

String _googleIdentityBridgeBlocks(String source) {
  final matches = RegExp(
    r'MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_[A-Z_]+_BEGIN([\s\S]*?)'
    r'MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_[A-Z_]+_END',
  ).allMatches(source);
  return matches.map((match) => match.group(1) ?? '').join('\n');
}
