import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/review_journey_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'empty durable state returns the public seed without writing it',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = _publicReviewStore(preferences);

      final snapshot = await store.read();

      expect(snapshot?.setupComplete, isTrue);
      expect(snapshot?.setupExperienceVersion, approvedSetupExperienceVersion);
      expect(snapshot?.pendingRoute, '/app/social?sub=videos');
      expect(preferences.getKeys(), isEmpty);
    },
  );

  test('an existing durable snapshot wins over the public seed', () async {
    final preferences = await SharedPreferences.getInstance();
    final firstStore = _publicReviewStore(preferences);
    await firstStore.write(_feedSnapshot);

    final restored = await _publicReviewStore(preferences).read();

    expect(restored?.pendingRoute, isNull);
    expect(restored?.lastReadyRoute, '/app/social?sub=feed&item=retained');
    expect(restored?.currentAreaLabel, 'Jodhpur, Rajasthan');
  });

  test(
    'fresh store and session preserve shared-post destination cancel and Google success',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final first = JourneySession(
        store: _publicReviewStore(preferences),
        allowGuestReady: true,
      );
      await first.start();
      expect(first.stage, JourneyStage.ready);
      expect(first.readyRoute(), '/app/social?sub=videos');

      first.beginSignIn(
        returnLocation:
            '/app/social?sub=create&state=shared-post&item=c33m-fix4',
        cancelLocation: '/app/social?sub=feed&item=c33m-fix4',
      );
      await _waitForSnapshot(
        preferences,
        (snapshot) =>
            snapshot.pendingAuthenticationCancelRoute ==
            '/app/social?sub=feed&item=c33m-fix4',
      );
      first.dispose();

      final cancelled = JourneySession(
        store: _publicReviewStore(preferences),
        allowGuestReady: true,
      );
      await cancelled.start();
      expect(cancelled.stage, JourneyStage.signIn);
      expect(
        cancelled.returnTo,
        '/app/social?sub=create&state=shared-post&item=c33m-fix4',
      );
      expect(cancelled.canCancelSignIn, isTrue);
      expect(
        cancelled.authenticationPurpose,
        JourneyAuthenticationPurpose.general,
      );
      cancelled.cancelSignIn();
      expect(cancelled.readyRoute(), '/app/social?sub=feed&item=c33m-fix4');
      await _waitForSnapshot(
        preferences,
        (snapshot) =>
            snapshot.pendingRoute == null &&
            snapshot.pendingAuthenticationCancelRoute == null &&
            snapshot.pendingAuthenticationPurpose == null,
      );
      cancelled.dispose();

      final retry = JourneySession(
        store: _publicReviewStore(preferences),
        allowGuestReady: true,
      );
      await retry.start();
      retry.beginSignIn(
        returnLocation:
            '/app/social?sub=create&state=shared-post&item=c33m-fix4',
        cancelLocation: '/app/social?sub=feed&item=c33m-fix4',
      );
      await _waitForSnapshot(
        preferences,
        (snapshot) => snapshot.pendingRoute?.contains('shared-post') == true,
      );
      retry.dispose();

      final googleGateway = ReviewSocialAuthGateway(
        defaultResult: const SocialAuthResult.authenticated('fix4-user'),
      );
      final authenticated = JourneySession(
        store: _publicReviewStore(preferences),
        socialAuthGateway: googleGateway,
        allowGuestReady: true,
      );
      addTearDown(authenticated.dispose);
      await authenticated.start();

      expect(authenticated.stage, JourneyStage.signIn);
      expect(
        await authenticated.signInWithSocial(SocialAuthProvider.google),
        isTrue,
      );
      expect(authenticated.isAuthenticated, isTrue);
      expect(
        authenticated.readyRoute(),
        '/app/social?sub=create&state=shared-post&item=c33m-fix4',
      );
      expect(googleGateway.signInCount, 1);
    },
  );

  test(
    'fresh process preserves Mobile OTP intent but not private input',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final gateway = ReviewOtpGateway();
      final first = JourneySession(
        store: _publicReviewStore(preferences),
        otpGateway: gateway,
        allowGuestReady: true,
      );
      await first.start();
      first.beginSignIn(
        returnLocation: '/app/chat/inbox?return=/app/social',
        cancelLocation: '/app/social?sub=feed',
      );
      expect(await first.requestOtp('9876543210'), isTrue);
      await _waitForSnapshot(
        preferences,
        (snapshot) =>
            snapshot.pendingRoute == '/app/chat/inbox?return=/app/social',
      );
      first.dispose();

      final restarted = JourneySession(
        store: _publicReviewStore(preferences),
        otpGateway: gateway,
        allowGuestReady: true,
      );
      addTearDown(restarted.dispose);
      await restarted.start();

      expect(restarted.stage, JourneyStage.signIn);
      expect(restarted.returnTo, '/app/chat/inbox?return=/app/social');
      expect(restarted.phoneNumber, isNull);
      expect(restarted.otpChannel, isNull);
      expect(await restarted.requestOtp('9876543210'), isTrue);
      expect(await restarted.verifyOtp('123456'), isTrue);
      expect(restarted.readyRoute(), '/app/chat/inbox?return=/app/social');
      _expectNoPrivateAuthenticationValues(preferences);
    },
  );

  test(
    'cold email-link return asks again then resumes the exact intent',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final gateway = ReviewEmailLinkGateway();
      final sender = JourneySession(
        store: _publicReviewStore(preferences),
        emailLinkGateway: gateway,
        emailLinkAvailable: true,
        allowGuestReady: true,
      );
      await sender.start();
      sender.beginSignIn(
        returnLocation: '/app/social?sub=create&state=email-link',
        cancelLocation: '/app/social?sub=videos',
      );
      expect(await sender.requestEmailLink('person@example.com'), isTrue);
      await _waitForSnapshot(
        preferences,
        (snapshot) =>
            snapshot.pendingRoute == '/app/social?sub=create&state=email-link',
      );
      sender.dispose();

      final returned = JourneySession(
        store: _publicReviewStore(preferences),
        emailLinkGateway: gateway,
        emailLinkAvailable: true,
        allowGuestReady: true,
      );
      addTearDown(returned.dispose);

      expect(
        await returned.prepareEmailLinkReturn(gateway.acceptedLink),
        isTrue,
      );
      expect(returned.stage, JourneyStage.signIn);
      expect(returned.emailLinkState, EmailLinkState.awaitingEmail);
      expect(returned.emailAddress, isNull);
      expect(returned.returnTo, '/app/social?sub=create&state=email-link');
      expect(await returned.completeEmailLink('person@example.com'), isTrue);
      expect(returned.isAuthenticated, isTrue);
      expect(returned.readyRoute(), '/app/social?sub=create&state=email-link');
      _expectNoPrivateAuthenticationValues(preferences);
    },
  );

  test(
    'YouTube connection purpose and exact cancel survive a fresh process',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final first = JourneySession(
        store: _publicReviewStore(preferences),
        allowGuestReady: true,
      );
      await first.start();
      first.beginSignIn(
        returnLocation: '/app/creator/youtube-connect',
        cancelLocation: '/app/social?sub=videos',
        purpose: JourneyAuthenticationPurpose.youtubeChannelConnection,
      );
      await _waitForSnapshot(
        preferences,
        (snapshot) =>
            snapshot.pendingAuthenticationPurpose ==
            JourneyAuthenticationPurpose.youtubeChannelConnection.name,
      );
      first.dispose();

      final restarted = JourneySession(
        store: _publicReviewStore(preferences),
        allowGuestReady: true,
      );
      addTearDown(restarted.dispose);
      await restarted.start();

      expect(restarted.stage, JourneyStage.signIn);
      expect(
        restarted.authenticationPurpose,
        JourneyAuthenticationPurpose.youtubeChannelConnection,
      );
      expect(restarted.canCancelSignIn, isTrue);
      restarted.cancelSignIn();
      expect(restarted.readyRoute(), '/app/social?sub=videos');
    },
  );

  test('store read failure still reaches the existing boot recovery', () async {
    final failingDelegate = MemoryJourneyStore(
      readFailure: StateError('durable read unavailable'),
    );
    final session = JourneySession(
      store: SeededJourneyStore(delegate: failingDelegate, seed: _publicSeed),
      allowGuestReady: true,
    );
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.bootFailure);
    expect(session.errorMessage, contains('could not restore'));
    expect(failingDelegate.writeCount, 0);
  });
}

SeededJourneyStore _publicReviewStore(SharedPreferences preferences) {
  return SeededJourneyStore(
    delegate: SharedPreferencesJourneyStore(preferences),
    seed: _publicSeed,
  );
}

Future<void> _waitForSnapshot(
  SharedPreferences preferences,
  bool Function(JourneySnapshot snapshot) predicate,
) async {
  for (var attempt = 0; attempt < 40; attempt += 1) {
    final snapshot = await SharedPreferencesJourneyStore(preferences).read();
    if (snapshot != null && predicate(snapshot)) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError(
    'Durable journey state did not settle within 40 microtasks.',
  );
}

void _expectNoPrivateAuthenticationValues(SharedPreferences preferences) {
  for (final key in preferences.getKeys()) {
    final normalizedKey = key.toLowerCase();
    expect(normalizedKey, isNot(contains('email')));
    expect(normalizedKey, isNot(contains('phone')));
    expect(normalizedKey, isNot(contains('token')));
    expect(normalizedKey, isNot(contains('link')));
    final value = preferences.get(key)?.toString().toLowerCase() ?? '';
    expect(value, isNot(contains('person@example.com')));
    expect(value, isNot(contains('9876543210')));
    expect(value, isNot(contains('actioncode')));
  }
}

const _publicSeed = JourneySnapshot(
  languageCode: 'en',
  areaMode: 'current',
  areaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
  setupComplete: true,
  setupExperienceVersion: approvedSetupExperienceVersion,
  pendingRoute: '/app/social?sub=videos',
);

const _feedSnapshot = JourneySnapshot(
  languageCode: 'en',
  areaMode: 'current',
  currentAreaLabel: 'Jodhpur, Rajasthan',
  setupComplete: true,
  setupExperienceVersion: approvedSetupExperienceVersion,
  lastReadyRoute: '/app/social?sub=feed&item=retained',
);
