import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  test('returning authenticated session restores directly to ready', () async {
    final store = MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'hi',
        areaMode: 'manual',
        areaLabel: 'Jodhpur',
        setupComplete: true,
      ),
    );
    final auth = ReviewOtpGateway(signedIn: true);
    final session = JourneySession(store: store, otpGateway: auth);
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.ready);
    expect(session.languageCode, 'hi');
    expect(session.areaChoice, AreaChoice.manual);
    expect(session.manualArea, 'Jodhpur');
  });

  test('boot failure changes nothing and exact retry restores state', () async {
    final store = MemoryJourneyStore(readFailure: StateError('disk'));
    final session = JourneySession(store: store);
    addTearDown(session.dispose);

    await session.start();
    expect(session.stage, JourneyStage.bootFailure);
    expect(session.errorMessage, contains('Nothing was changed'));

    store.readFailure = null;
    await session.retryBoot();
    expect(session.stage, JourneyStage.setup);
  });

  test('account bootstrap timeout reaches a retryable boot failure', () async {
    final session = JourneySession(
      otpGateway: ReviewOtpGateway(signedIn: true),
      accountBootstrapGateway: _NeverCompletesAccountBootstrap(),
      accountBootstrapTimeout: const Duration(milliseconds: 1),
    );
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.bootFailure);
    expect(session.busy, isFalse);
    expect(session.errorMessage, contains('Nothing was changed'));
  });

  test(
    'expired OTP fails, resend is cooled down, then retry succeeds',
    () async {
      var now = DateTime(2026, 7, 18, 20);
      final auth = ReviewOtpGateway();
      final session = JourneySession(
        otpGateway: auth,
        now: () => now,
        otpValidity: const Duration(minutes: 2),
        resendCooldown: const Duration(seconds: 30),
      );
      addTearDown(session.dispose);

      await session.start();
      session.selectArea(AreaChoice.skipped);
      await session.completeSetup();
      await session.requestOtp('9876543210');

      expect(await session.resendOtp(), isFalse);
      expect(session.errorMessage, contains('30 seconds'));

      now = now.add(const Duration(minutes: 3));
      expect(await session.verifyOtp('123456'), isFalse);
      expect(session.errorMessage, contains('expired'));

      expect(await session.resendOtp(), isTrue);
      expect(auth.requestCount, 2);
      expect(await session.verifyOtp('123456'), isTrue);
    },
  );

  test('successful verification is idempotent', () async {
    final auth = ReviewOtpGateway();
    final store = MemoryJourneyStore();
    final session = JourneySession(store: store, otpGateway: auth);
    addTearDown(session.dispose);

    await session.start();
    session.selectArea(AreaChoice.skipped);
    await session.completeSetup();
    await session.requestOtp('9876543210');

    expect(await session.verifyOtp('123456'), isTrue);
    expect(await session.verifyOtp('123456'), isTrue);
    expect(auth.verificationCount, 1);
    expect(session.stage, JourneyStage.ready);
  });

  test(
    'profile preferences persist and failed writes restore safe values',
    () async {
      final store = MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      );
      final session = JourneySession(
        store: store,
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(session.dispose);
      await session.start();

      expect(await session.updateLanguage('hi'), isTrue);
      expect(store.snapshot?.languageCode, 'hi');
      expect(
        await session.updateArea(AreaChoice.manual, label: 'Sardarpura'),
        isTrue,
      );
      expect(store.snapshot?.areaLabel, 'Sardarpura');

      store.writeFailure = StateError('disk full');
      expect(await session.updateLanguage('en'), isFalse);
      expect(session.languageCode, 'hi');
      expect(
        await session.updateArea(AreaChoice.manual, label: 'Ratanada'),
        isFalse,
      );
      expect(session.manualArea, 'Sardarpura');
    },
  );
}

class _NeverCompletesAccountBootstrap implements AccountBootstrapGateway {
  @override
  Future<void> prepareAuthenticatedAccount() =>
      Future<void>.delayed(const Duration(days: 1));
}
