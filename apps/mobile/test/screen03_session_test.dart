import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  MemoryJourneyStore completedSetupStore() {
    return MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
      ),
    );
  }

  test(
    'provider success preserves Screen 02 state and opens Universal',
    () async {
      final store = completedSetupStore();
      final social = ReviewSocialAuthGateway(
        results: const {
          SocialAuthProvider.google: SocialAuthResult.authenticated(
            'google-user',
          ),
        },
      );
      final session = JourneySession(store: store, socialAuthGateway: social);
      addTearDown(session.dispose);
      await session.start();

      expect(await session.signInWithSocial(SocialAuthProvider.google), isTrue);

      expect(session.stage, JourneyStage.ready);
      expect(session.readyRoute(), '/app/social');
      expect(
        store.snapshot?.currentAreaLabel,
        'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
      );
      expect(social.lastProvider, SocialAuthProvider.google);
    },
  );

  test(
    'YouTube uses its own selected context and can recover from cancel',
    () async {
      final social = ReviewSocialAuthGateway();
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: social,
      );
      addTearDown(session.dispose);
      await session.start();

      expect(
        await session.signInWithSocial(SocialAuthProvider.youtube),
        isFalse,
      );

      expect(session.stage, JourneyStage.signIn);
      expect(session.socialAuthProvider, SocialAuthProvider.youtube);
      expect(session.socialAuthState, SocialAuthState.cancelled);
      expect(session.errorMessage, contains('YouTube'));

      session.clearSocialAuthResult();
      expect(session.socialAuthProvider, isNull);
      expect(session.socialAuthState, SocialAuthState.idle);
    },
  );

  test(
    'social provider failure stays retryable and never marks ready',
    () async {
      final social = ReviewSocialAuthGateway(
        failures: const {
          SocialAuthProvider.facebook: JourneyServiceException(
            'You appear to be offline. Reconnect and try again.',
          ),
        },
      );
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: social,
      );
      addTearDown(session.dispose);
      await session.start();

      expect(
        await session.signInWithSocial(SocialAuthProvider.facebook),
        isFalse,
      );

      expect(session.stage, JourneyStage.signIn);
      expect(session.socialAuthState, SocialAuthState.failed);
      expect(session.errorMessage, contains('offline'));
    },
  );

  test(
    'a provider outside the production allow-list never reaches auth',
    () async {
      final social = ReviewSocialAuthGateway(
        defaultResult: const SocialAuthResult.authenticated('must-not-run'),
      );
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: social,
        availableSocialAuthProviders: const {
          SocialAuthProvider.google,
          SocialAuthProvider.youtube,
        },
      );
      addTearDown(session.dispose);
      await session.start();

      expect(
        await session.signInWithSocial(SocialAuthProvider.facebook),
        isFalse,
      );
      expect(social.signInCount, 0);
      expect(session.socialAuthProvider, SocialAuthProvider.facebook);
      expect(session.socialAuthState, SocialAuthState.failed);
      expect(session.errorMessage, contains('not available'));
    },
  );

  test(
    'successful auth ignores the cancellation origin and opens requested route',
    () async {
      final social = ReviewSocialAuthGateway(
        defaultResult: const SocialAuthResult.authenticated('user-1'),
      );
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: social,
        allowGuestReady: true,
      );
      addTearDown(session.dispose);
      await session.start();
      session.beginSignIn(
        returnLocation: '/app/social?sub=create',
        cancelLocation: '/app/social?sub=feed',
        purpose: JourneyAuthenticationPurpose.youtubeChannelConnection,
      );

      expect(
        session.authenticationPurpose,
        JourneyAuthenticationPurpose.youtubeChannelConnection,
      );

      expect(await session.signInWithSocial(SocialAuthProvider.google), isTrue);
      expect(session.readyRoute(), '/app/social?sub=create');
      expect(
        session.authenticationPurpose,
        JourneyAuthenticationPurpose.general,
      );
    },
  );

  test(
    'mandatory first-open sign-in cannot be cancelled into guest mode',
    () async {
      final session = JourneySession(store: completedSetupStore());
      addTearDown(session.dispose);
      await session.start();

      expect(session.stage, JourneyStage.signIn);
      expect(session.canCancelSignIn, isFalse);
      session.cancelSignIn();
      expect(session.stage, JourneyStage.signIn);
    },
  );

  test(
    'YouTube channel handoff restores its purpose and cancel route after restart',
    () async {
      final store = completedSetupStore();
      final first = JourneySession(store: store, allowGuestReady: true);
      await first.start();
      first.beginSignIn(
        returnLocation: '/app/creator/youtube-connect',
        cancelLocation: '/app/social?sub=videos',
        purpose: JourneyAuthenticationPurpose.youtubeChannelConnection,
      );
      await Future<void>.delayed(Duration.zero);
      first.dispose();

      final restarted = JourneySession(store: store, allowGuestReady: true);
      addTearDown(restarted.dispose);
      await restarted.start();

      expect(restarted.stage, JourneyStage.signIn);
      expect(
        restarted.authenticationPurpose,
        JourneyAuthenticationPurpose.youtubeChannelConnection,
      );
      expect(restarted.returnTo, '/app/creator/youtube-connect');
      expect(restarted.canCancelSignIn, isTrue);
      restarted.cancelSignIn();
      expect(restarted.readyRoute(), '/app/social?sub=videos');
    },
  );

  test(
    'process death during OTP returns to sign-in without skipping auth',
    () async {
      final store = completedSetupStore();
      final first = JourneySession(store: store);
      await first.start();
      expect(await first.requestOtp('9876543210'), isTrue);
      expect(first.stage, JourneyStage.verify);
      first.dispose();

      final restarted = JourneySession(store: store);
      addTearDown(restarted.dispose);
      await restarted.start();

      expect(restarted.stage, JourneyStage.signIn);
      expect(restarted.isReady, isFalse);
      expect(restarted.currentAreaLabel, 'Khema-Ka-Kuwa, Jodhpur, Rajasthan');
    },
  );

  test('background-like provider return completes exactly once', () async {
    final gateway = _CompletingSocialGateway();
    final bootstrap = ReviewAccountBootstrapGateway();
    final session = JourneySession(
      store: completedSetupStore(),
      socialAuthGateway: gateway,
      accountBootstrapGateway: bootstrap,
    );
    addTearDown(session.dispose);
    await session.start();

    final pending = session.signInWithSocial(SocialAuthProvider.x);
    expect(session.socialAuthState, SocialAuthState.pending);
    expect(session.busy, isTrue);

    gateway.complete(const SocialAuthResult.authenticated('x-user'));
    expect(await pending, isTrue);
    expect(session.stage, JourneyStage.ready);
    expect(bootstrap.prepareCount, 1);
  });

  test('unavailable auth methods fail before gateway dispatch', () async {
    final otp = ReviewOtpGateway();
    final email = ReviewEmailOtpGateway();
    final social = ReviewSocialAuthGateway(
      defaultResult: const SocialAuthResult.authenticated('google-user'),
    );
    final session = JourneySession(
      store: completedSetupStore(),
      otpGateway: otp,
      emailOtpGateway: email,
      socialAuthGateway: social,
      availableSocialAuthProviders: const {SocialAuthProvider.google},
      emailOtpAvailable: false,
      mobileOtpAvailable: false,
    );
    addTearDown(session.dispose);
    await session.start();

    expect(await session.signInWithSocial(SocialAuthProvider.x), isFalse);
    expect(social.signInCount, 0);
    expect(session.errorMessage, contains('X sign-in is not available'));

    expect(await session.requestEmailOtp('person@example.com'), isFalse);
    expect(email.requestCount, 0);
    expect(session.errorMessage, contains('Email OTP is not available'));

    expect(await session.requestOtp('9876543210'), isFalse);
    expect(otp.requestCount, 0);
    expect(session.errorMessage, contains('Mobile OTP is not available'));

    expect(await session.signInWithSocial(SocialAuthProvider.google), isTrue);
    expect(social.signInCount, 1);
    expect(session.isAuthenticated, isTrue);
  });

  test(
    'account bootstrap failure rolls back partial social identity',
    () async {
      final social = ReviewSocialAuthGateway(
        defaultResult: const SocialAuthResult.authenticated('google-user'),
      );
      final bootstrap = ReviewAccountBootstrapGateway(
        failure: const JourneyServiceException(
          'Your account service is unavailable. Please retry.',
        ),
      );
      final session = JourneySession(
        store: completedSetupStore(),
        socialAuthGateway: social,
        accountBootstrapGateway: bootstrap,
      );
      addTearDown(session.dispose);
      await session.start();

      expect(
        await session.signInWithSocial(SocialAuthProvider.google),
        isFalse,
      );
      expect(bootstrap.prepareCount, 1);
      expect(social.signOutCount, 1);
      expect(social.signedIn, isFalse);
      expect(session.isAuthenticated, isFalse);
      expect(session.stage, JourneyStage.signIn);
      expect(session.errorMessage, contains('account service is unavailable'));
    },
  );

  test('authenticated identity loads and sign-out clears it', () async {
    final social = ReviewSocialAuthGateway(
      defaultResult: const SocialAuthResult.authenticated('google-user'),
    );
    final identityGateway = ReviewAuthenticatedAccountIdentityGateway(
      identity: const AuthenticatedAccountIdentity(
        displayName: 'Test Member',
        emailAddress: 'member@example.com',
        signInMethods: ['Google'],
      ),
    );
    final session = JourneySession(
      store: completedSetupStore(),
      socialAuthGateway: social,
      accountIdentityGateway: identityGateway,
    );
    addTearDown(session.dispose);
    await session.start();

    expect(await session.signInWithSocial(SocialAuthProvider.google), isTrue);
    expect(session.accountIdentity?.primaryLabel, 'Test Member');
    expect(session.accountIdentity?.detailLabel, 'member@example.com · Google');
    expect(identityGateway.readCount, 1);

    await session.signOut();
    expect(session.accountIdentity, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.stage, JourneyStage.signIn);
  });
}

class _CompletingSocialGateway implements SocialAuthGateway {
  final _result = Completer<SocialAuthResult>();

  void complete(SocialAuthResult result) => _result.complete(result);

  @override
  Future<bool> hasAuthenticatedUser() async => false;

  @override
  Future<SocialAuthResult> signIn(SocialAuthProvider provider) =>
      _result.future;

  @override
  Future<void> signOut() async {}
}
