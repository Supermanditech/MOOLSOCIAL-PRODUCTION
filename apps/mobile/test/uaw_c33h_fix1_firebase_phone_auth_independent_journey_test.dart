import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/review_journey_services.dart';

void main() {
  test('phone verification gate allows one terminal callback per request', () {
    final gate = PhoneVerificationCompletionGate();
    final first = gate.beginAttempt();

    expect(gate.claimTerminal(first), isTrue);
    expect(gate.claimTerminal(first), isFalse);

    final second = gate.beginAttempt();
    expect(gate.isCurrent(first), isFalse);
    expect(gate.claimTerminal(first), isFalse);
    expect(gate.claimTerminal(second), isTrue);
  });

  test('phone verification gate invalidates callbacks after timeout', () {
    final gate = PhoneVerificationCompletionGate();
    final attempt = gate.beginAttempt();

    gate.invalidate(attempt);

    expect(gate.isCurrent(attempt), isFalse);
    expect(gate.claimTerminal(attempt), isFalse);
  });

  test(
    'Phone OTP rejects unavailable and invalid input before dispatch',
    () async {
      final gateway = ReviewOtpGateway();
      final unavailable = JourneySession(
        store: _completedStore(),
        otpGateway: gateway,
        mobileOtpAvailable: false,
        allowGuestReady: true,
      );
      addTearDown(unavailable.dispose);
      await unavailable.start();
      unavailable.beginSignIn(
        returnLocation: '/app/social?sub=create',
        cancelLocation: '/app/social?sub=feed',
      );

      expect(await unavailable.requestOtp('9876543210'), isFalse);
      expect(unavailable.errorMessage, contains('not available'));
      expect(gateway.requestCount, 0);

      final invalid = JourneySession(
        store: _completedStore(),
        otpGateway: gateway,
        allowGuestReady: true,
      );
      addTearDown(invalid.dispose);
      await invalid.start();
      invalid.beginSignIn(
        returnLocation: '/app/social?sub=create',
        cancelLocation: '/app/social?sub=feed',
      );
      expect(await invalid.requestOtp('12345'), isFalse);
      expect(invalid.errorMessage, contains('10-digit Indian mobile'));
      expect(gateway.requestCount, 0);
    },
  );

  test(
    'Phone OTP manual wrong expired resend and success remain independent',
    () async {
      var now = DateTime(2026, 8, 15, 12);
      final gateway = ReviewOtpGateway();
      final session = JourneySession(
        store: _completedStore(),
        otpGateway: gateway,
        allowGuestReady: true,
        now: () => now,
        otpValidity: const Duration(minutes: 2),
        resendCooldown: const Duration(seconds: 30),
      );
      addTearDown(session.dispose);
      await session.start();
      session.beginSignIn(
        returnLocation: '/app/social?sub=create',
        cancelLocation: '/app/social?sub=feed',
      );

      expect(await session.requestOtp('98765 43210'), isTrue);
      expect(gateway.lastPhoneNumber, '+919876543210');
      expect(session.stage, JourneyStage.verify);
      expect(await session.verifyOtp('000000'), isFalse);
      expect(session.errorMessage, contains('not valid'));
      expect(await session.resendOtp(), isFalse);
      expect(session.errorMessage, contains('30 seconds'));

      now = now.add(const Duration(minutes: 3));
      expect(await session.verifyOtp('123456'), isFalse);
      expect(session.errorMessage, contains('expired'));
      expect(await session.resendOtp(), isTrue);
      expect(gateway.requestCount, 2);
      expect(await session.verifyOtp('123456'), isTrue);
      expect(session.isAuthenticated, isTrue);
      expect(session.stage, JourneyStage.ready);
      expect(session.readyRoute(), '/app/social?sub=create');
    },
  );

  test(
    'manual Phone OTP rolls back partial auth when bootstrap fails',
    () async {
      final gateway = ReviewOtpGateway();
      final bootstrap = ReviewAccountBootstrapGateway(
        failure: const JourneyServiceException('Account setup is unavailable.'),
      );
      final session = JourneySession(
        store: _completedStore(),
        otpGateway: gateway,
        accountBootstrapGateway: bootstrap,
        allowGuestReady: true,
      );
      addTearDown(session.dispose);
      await session.start();
      session.beginSignIn(
        returnLocation: '/app/social?sub=create',
        cancelLocation: '/app/social?sub=feed',
      );
      expect(await session.requestOtp('9876543210'), isTrue);

      expect(await session.verifyOtp('123456'), isFalse);
      expect(gateway.signedIn, isFalse);
      expect(gateway.signOutCount, 1);
      expect(session.isAuthenticated, isFalse);
      expect(session.stage, JourneyStage.verify);
      expect(session.returnTo, '/app/social?sub=create');

      bootstrap.failure = null;
      expect(await session.verifyOtp('123456'), isTrue);
      expect(session.isAuthenticated, isTrue);
      expect(session.readyRoute(), '/app/social?sub=create');
    },
  );

  test(
    'automatic Phone verification rolls back and supports exact retry',
    () async {
      final gateway = _AutomaticOtpGateway();
      final bootstrap = ReviewAccountBootstrapGateway(
        failure: const JourneyServiceException('Account setup is unavailable.'),
      );
      final session = JourneySession(
        store: _completedStore(),
        otpGateway: gateway,
        accountBootstrapGateway: bootstrap,
        allowGuestReady: true,
      );
      addTearDown(session.dispose);
      await session.start();
      session.beginSignIn(
        returnLocation: '/app/social?sub=feed&action=like&item=post-1',
        cancelLocation: '/app/social?sub=feed',
      );

      expect(await session.requestOtp('9876543210'), isFalse);
      expect(gateway.signedIn, isFalse);
      expect(gateway.signOutCount, 1);
      expect(session.returnTo, '/app/social?sub=feed&action=like&item=post-1');

      bootstrap.failure = null;
      expect(await session.requestOtp('9876543210'), isTrue);
      expect(session.isAuthenticated, isTrue);
      expect(
        session.readyRoute(),
        '/app/social?sub=feed&action=like&item=post-1',
      );
    },
  );

  test(
    'Phone OTP provider failure stays retryable without fake auth',
    () async {
      final gateway = ReviewOtpGateway(
        requestFailure: const JourneyServiceException(
          'The verification service did not respond.',
        ),
      );
      final session = JourneySession(
        store: _completedStore(),
        otpGateway: gateway,
        allowGuestReady: true,
      );
      addTearDown(session.dispose);
      await session.start();
      session.beginSignIn(
        returnLocation: '/app/chat',
        cancelLocation: '/app/social?sub=feed',
      );

      expect(await session.requestOtp('9876543210'), isFalse);
      expect(session.stage, JourneyStage.signIn);
      expect(session.isAuthenticated, isFalse);
      expect(session.returnTo, '/app/chat');

      gateway.requestFailure = null;
      expect(await session.requestOtp('9876543210'), isTrue);
      expect(await session.verifyOtp('123456'), isTrue);
      expect(session.readyRoute(), '/app/chat');
    },
  );

  test(
    'Phone OTP process return drops private input and preserves intent',
    () async {
      final store = _completedStore();
      final gateway = ReviewOtpGateway();
      final first = JourneySession(
        store: store,
        otpGateway: gateway,
        allowGuestReady: true,
      );
      addTearDown(first.dispose);
      await first.start();
      first.beginSignIn(
        returnLocation: '/app/social?sub=create',
        cancelLocation: '/app/social?sub=feed',
      );
      expect(await first.requestOtp('9876543210'), isTrue);
      await _waitForPendingRoute(store, '/app/social?sub=create');

      final restarted = JourneySession(
        store: store,
        otpGateway: gateway,
        allowGuestReady: true,
      );
      addTearDown(restarted.dispose);
      await restarted.start();

      expect(restarted.stage, JourneyStage.signIn);
      expect(restarted.returnTo, '/app/social?sub=create');
      expect(restarted.phoneNumber, isNull);
      expect(restarted.otpChannel, isNull);
      expect(restarted.canCancelSignIn, isTrue);
      restarted.cancelSignIn();
      expect(restarted.stage, JourneyStage.ready);
      expect(restarted.readyRoute(), '/app/social?sub=feed');
    },
  );
}

MemoryJourneyStore _completedStore() => MemoryJourneyStore(
  snapshot: const JourneySnapshot(
    languageCode: 'en',
    areaMode: 'current',
    areaLabel: 'Jodhpur',
    setupComplete: true,
    setupExperienceVersion: approvedSetupExperienceVersion,
    lastReadyRoute: '/app/social?sub=feed',
  ),
);

Future<void> _waitForPendingRoute(
  MemoryJourneyStore store,
  String expected,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (store.snapshot?.pendingRoute == expected) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Journey persistence did not settle within 20 microtasks.');
}

class _AutomaticOtpGateway implements OtpGateway {
  bool signedIn = false;
  int signOutCount = 0;

  @override
  Future<bool> hasAuthenticatedUser() async => signedIn;

  @override
  Future<OtpRequestResult> requestCode(String phoneNumber) async {
    signedIn = true;
    return const OtpRequestResult(
      automaticallyVerified: true,
      userId: 'automatic-phone-user',
    );
  }

  @override
  Future<String?> reviewCodeFor(String phoneNumber) async => null;

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    signedIn = false;
  }

  @override
  Future<String> verifyCode(String code) async => 'automatic-phone-user';
}
