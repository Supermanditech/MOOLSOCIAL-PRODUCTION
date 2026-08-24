import 'dart:async';
import 'dart:io';

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

    await gateway.prepareAuthenticatedAccount();
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

      await gateway.prepareAuthenticatedAccount(
        expectedUserId: 'firebase-user',
      );
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

      await expectLater(
        gateway.prepareAuthenticatedAccount(expectedUserId: 'firebase-user'),
        throwsA(
          isA<JourneyServiceException>().having(
            (error) => error.code,
            'code',
            'auth-session-user-mismatch',
          ),
        ),
      );
    },
  );

  test('Firebase session bootstrap rejects a missing user', () async {
    final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
      verifiedUserId: () async => null,
    );

    await expectLater(
      gateway.prepareAuthenticatedAccount(),
      throwsA(
        isA<JourneyServiceException>()
            .having((error) => error.code, 'code', 'auth-session-missing')
            .having(
              (error) => error.userMessage,
              'message',
              contains('sign in again'),
            ),
      ),
    );
  });

  test('Firebase session bootstrap sanitizes verification failure', () async {
    final gateway = FirebaseAuthenticatedSessionBootstrapGateway.forTesting(
      verifiedUserId: () async => throw StateError('private failure'),
    );

    await expectLater(
      gateway.prepareAuthenticatedAccount(),
      throwsA(
        isA<JourneyServiceException>()
            .having((error) => error.code, 'code', 'auth-session-verification')
            .having(
              (error) => error.userMessage,
              'message',
              isNot(contains('private failure')),
            ),
      ),
    );
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
