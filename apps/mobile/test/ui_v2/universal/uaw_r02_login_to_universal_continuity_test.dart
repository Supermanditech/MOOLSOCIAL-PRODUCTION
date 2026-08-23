import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  MemoryJourneyStore completedSetupStore({String? pendingRoute}) {
    return MemoryJourneyStore(
      snapshot: JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
        pendingRoute: pendingRoute,
      ),
    );
  }

  void expectPersonalUniversalEntry(JourneySession session) {
    expect(session.stage, JourneyStage.ready);
    expect(session.readyRoute(), '/app/social');
    expect(session.readyRoute(), isNot(contains('workspace')));
    expect(session.readyRoute(), isNot(contains('role')));
    expect(session.readyRoute(), isNot(contains('profession')));
  }

  test('email OTP reaches normal Personal Universal directly', () async {
    final session = JourneySession(store: completedSetupStore());
    addTearDown(session.dispose);
    await session.start();

    expect(session.stage, JourneyStage.signIn);
    expect(await session.requestEmailOtp('person@example.com'), isTrue);
    expect(session.stage, JourneyStage.verify);
    expect(await session.verifyOtp('123456'), isTrue);

    expectPersonalUniversalEntry(session);
  });

  test('mobile OTP reaches normal Personal Universal directly', () async {
    final session = JourneySession(store: completedSetupStore());
    addTearDown(session.dispose);
    await session.start();

    expect(session.stage, JourneyStage.signIn);
    expect(await session.requestOtp('9876543210'), isTrue);
    expect(session.stage, JourneyStage.verify);
    expect(await session.verifyOtp('123456'), isTrue);

    expectPersonalUniversalEntry(session);
  });

  test('retained authentication reaches Personal Universal directly', () async {
    final session = JourneySession(
      store: completedSetupStore(),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    addTearDown(session.dispose);

    await session.start();

    expectPersonalUniversalEntry(session);
  });

  test(
    'protected intent returns only after successful authentication',
    () async {
      const protectedIntent = '/app/buy?sub=medicine';
      final session = JourneySession(
        store: completedSetupStore(pendingRoute: protectedIntent),
      );
      addTearDown(session.dispose);
      await session.start();

      expect(session.stage, JourneyStage.signIn);
      expect(session.returnTo, protectedIntent);
      expect(await session.requestEmailOtp('person@example.com'), isTrue);
      expect(await session.verifyOtp('123456'), isTrue);

      expect(session.stage, JourneyStage.ready);
      expect(session.readyRoute(), protectedIntent);
      expect(session.readyRoute(), isNot(contains('workspace')));
    },
  );

  test('failed authentication never advances to Universal', () async {
    final session = JourneySession(store: completedSetupStore());
    addTearDown(session.dispose);
    await session.start();

    expect(await session.requestEmailOtp('person@example.com'), isTrue);
    expect(await session.verifyOtp('000000'), isFalse);

    expect(session.stage, JourneyStage.verify);
    expect(session.isReady, isFalse);
    expect(session.errorMessage, contains('not valid'));
  });
}
