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
