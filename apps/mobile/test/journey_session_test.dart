import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/review_journey_services.dart';

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

  test(
    'sign-out clears every auth gateway and a restart stays signed out',
    () async {
      final store = MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'hi',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      );
      final otp = ReviewOtpGateway(signedIn: true);
      final social = ReviewSocialAuthGateway(signedIn: true);
      final emailLink = ReviewEmailLinkGateway()..signedIn = true;
      final session = JourneySession(
        store: store,
        otpGateway: otp,
        socialAuthGateway: social,
        emailLinkGateway: emailLink,
      );
      addTearDown(session.dispose);
      await session.start();
      expect(session.stage, JourneyStage.ready);

      expect(await session.signOut(), isTrue);

      expect(otp.signOutCount, 1);
      expect(social.signOutCount, 1);
      expect(emailLink.signOutCount, 1);
      expect(otp.signedIn, isFalse);
      expect(social.signedIn, isFalse);
      expect(emailLink.signedIn, isFalse);
      expect(session.stage, JourneyStage.signIn);
      expect(session.noticeMessage, contains('signed out'));
      expect(session.languageCode, 'hi');
      expect(session.manualArea, 'Jodhpur');

      final restarted = JourneySession(
        store: store,
        otpGateway: otp,
        socialAuthGateway: social,
        emailLinkGateway: emailLink,
      );
      addTearDown(restarted.dispose);
      await restarted.start();

      expect(restarted.stage, JourneyStage.signIn);
      expect(restarted.isReady, isFalse);
      expect(restarted.languageCode, 'hi');
      expect(restarted.manualArea, 'Jodhpur');
    },
  );

  test(
    'explicit sign-out opens account choice even when guest browsing is allowed',
    () async {
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
        allowGuestReady: true,
      );
      addTearDown(session.dispose);
      await session.start();

      expect(session.isAuthenticated, isTrue);
      expect(session.stage, JourneyStage.ready);

      expect(await session.signOut(), isTrue);

      expect(session.isAuthenticated, isFalse);
      expect(session.stage, JourneyStage.signIn);
      expect(session.noticeMessage, contains('signed out'));
    },
  );

  test(
    'sign-out attempts every cleanup and removes local auth after invalidation',
    () async {
      final pendingAddress = MemoryPendingEmailLinkAddressStore();
      await pendingAddress.write('member@example.com');
      final otp = ReviewOtpGateway(signedIn: true);
      final social = ReviewSocialAuthGateway(
        signedIn: true,
        signOutFailure: StateError('private provider cleanup failure'),
      );
      final emailLink = ReviewEmailLinkGateway()..signedIn = true;
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        otpGateway: otp,
        socialAuthGateway: social,
        emailLinkGateway: emailLink,
        pendingEmailLinkAddressStore: pendingAddress,
      );
      addTearDown(session.dispose);
      await session.start();

      expect(await session.signOut(), isFalse);

      expect(otp.signOutCount, 1);
      expect(social.signOutCount, 1);
      expect(emailLink.signOutCount, 1);
      expect(await pendingAddress.read(), isNull);
      expect(session.isAuthenticated, isFalse);
      expect(session.stage, JourneyStage.signIn);
      expect(session.errorMessage, contains('signed out on this device'));
      expect(session.busy, isFalse);
    },
  );

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
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
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

  test('timeout principal change is invalid, never retryable', () async {
    final protector = const ReviewPrincipalBindingProtector();
    final before = await protector.protect('private-user-a');
    final after = await protector.protect('private-user-b');
    final bootstrap = _TimeoutPrincipalBootstrap([before, after]);
    final receiptStore = MemoryVerifiedPrincipalBindingStore(binding: before);
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
      accountBootstrapGateway: bootstrap,
      verifiedPrincipalBindingStore: receiptStore,
      accountBootstrapTimeout: const Duration(milliseconds: 1),
    );
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.signIn);
    expect(
      session.authenticatedBootstrapState,
      AuthenticatedAccountBootstrapState.invalidSession,
    );
    expect(bootstrap.invalidationCount, 1);
    expect(receiptStore.binding, isNull);
  });

  test(
    'timeout is retryable only across exact pre-post-receipt match',
    () async {
      final binding = await const ReviewPrincipalBindingProtector().protect(
        'private-user-a',
      );
      final bootstrap = _TimeoutPrincipalBootstrap([binding, binding]);
      final receiptStore = MemoryVerifiedPrincipalBindingStore(
        binding: binding,
      );
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
        accountBootstrapGateway: bootstrap,
        verifiedPrincipalBindingStore: receiptStore,
        accountBootstrapTimeout: const Duration(milliseconds: 1),
      );
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.bootFailure);
      expect(
        session.authenticatedBootstrapState,
        AuthenticatedAccountBootstrapState.retryableUnavailable,
      );
      expect(bootstrap.invalidationCount, 0);
      expect(receiptStore.binding!.matches(binding), isTrue);
    },
  );

  test('timeout with mismatched stored receipt invalidates session', () async {
    final protector = const ReviewPrincipalBindingProtector();
    final current = await protector.protect('private-user-a');
    final stored = await protector.protect('private-user-b');
    final bootstrap = _TimeoutPrincipalBootstrap([current, current]);
    final receiptStore = MemoryVerifiedPrincipalBindingStore(binding: stored);
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
      accountBootstrapGateway: bootstrap,
      verifiedPrincipalBindingStore: receiptStore,
      accountBootstrapTimeout: const Duration(milliseconds: 1),
    );
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.signIn);
    expect(
      session.authenticatedBootstrapState,
      AuthenticatedAccountBootstrapState.invalidSession,
    );
    expect(bootstrap.invalidationCount, 1);
    expect(receiptStore.binding, isNull);
  });

  test(
    'legacy online relaunch writes its first verified principal receipt',
    () async {
      final binding = await const ReviewPrincipalBindingProtector().protect(
        'private-user-a',
      );
      final receiptStore = MemoryVerifiedPrincipalBindingStore();
      final bootstrap = ReviewAccountBootstrapGateway(
        result: AuthenticatedAccountBootstrapResult.verified(binding),
        currentBinding: binding,
      );
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
        accountBootstrapGateway: bootstrap,
        verifiedPrincipalBindingStore: receiptStore,
      );
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.ready);
      expect(
        session.authenticatedBootstrapState,
        AuthenticatedAccountBootstrapState.verified,
      );
      expect(receiptStore.binding!.matches(binding), isTrue);
      expect(receiptStore.writeCount, 1);
    },
  );

  test(
    'retryable relaunch remains fail-closed even with matching receipt',
    () async {
      final binding = await const ReviewPrincipalBindingProtector().protect(
        'private-user-a',
      );
      final receiptStore = MemoryVerifiedPrincipalBindingStore(
        binding: binding,
      );
      final bootstrap = ReviewAccountBootstrapGateway(
        result: AuthenticatedAccountBootstrapResult.retryableUnavailable(
          binding,
        ),
        currentBinding: binding,
      );
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
        accountBootstrapGateway: bootstrap,
        verifiedPrincipalBindingStore: receiptStore,
      );
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.bootFailure);
      expect(
        session.authenticatedBootstrapState,
        AuthenticatedAccountBootstrapState.retryableUnavailable,
      );
      expect(receiptStore.binding!.matches(binding), isTrue);
      expect(bootstrap.invalidationCount, 0);
    },
  );

  test(
    'verified principal mismatch clears receipt and invalidates session',
    () async {
      final protector = const ReviewPrincipalBindingProtector();
      final stored = await protector.protect('private-user-a');
      final current = await protector.protect('private-user-b');
      final receiptStore = MemoryVerifiedPrincipalBindingStore(binding: stored);
      final bootstrap = ReviewAccountBootstrapGateway(
        result: AuthenticatedAccountBootstrapResult.verified(current),
        currentBinding: current,
      );
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
        accountBootstrapGateway: bootstrap,
        verifiedPrincipalBindingStore: receiptStore,
      );
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.signIn);
      expect(session.isAuthenticated, isFalse);
      expect(receiptStore.binding, isNull);
      expect(bootstrap.invalidationCount, 1);
    },
  );

  test('invalid session clears receipt and cannot restore ready', () async {
    final binding = await const ReviewPrincipalBindingProtector().protect(
      'private-user-a',
    );
    final receiptStore = MemoryVerifiedPrincipalBindingStore(binding: binding);
    final bootstrap = ReviewAccountBootstrapGateway(
      result: const AuthenticatedAccountBootstrapResult.invalidSession(
        code: 'auth-session-user-disabled',
      ),
      currentBinding: binding,
    );
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
      accountBootstrapGateway: bootstrap,
      verifiedPrincipalBindingStore: receiptStore,
    );
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.signIn);
    expect(receiptStore.binding, isNull);
    expect(bootstrap.invalidationCount, 1);
  });

  test('sign-out clears verified principal receipt', () async {
    final binding = await const ReviewPrincipalBindingProtector().protect(
      'private-user-a',
    );
    final receiptStore = MemoryVerifiedPrincipalBindingStore(binding: binding);
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
      verifiedPrincipalBindingStore: receiptStore,
    );
    addTearDown(session.dispose);
    await session.start();

    expect(await session.signOut(), isTrue);

    expect(receiptStore.binding, isNull);
    expect(receiptStore.clearCount, greaterThanOrEqualTo(1));
  });

  test('unsafe receipt write and clear failure blocks ready', () async {
    final binding = await const ReviewPrincipalBindingProtector().protect(
      'private-user-a',
    );
    final receiptStore = MemoryVerifiedPrincipalBindingStore(
      writeFailure: StateError('private write failure'),
      clearFailure: StateError('private clear failure'),
    );
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
      accountBootstrapGateway: ReviewAccountBootstrapGateway(
        result: AuthenticatedAccountBootstrapResult.verified(binding),
        currentBinding: binding,
      ),
      verifiedPrincipalBindingStore: receiptStore,
    );
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.bootFailure);
    expect(session.errorMessage, isNot(contains('private')));
  });

  test(
    'signed-out startup must clear stale receipt before authentication',
    () async {
      final binding = await const ReviewPrincipalBindingProtector().protect(
        'private-user-a',
      );
      final receiptStore = MemoryVerifiedPrincipalBindingStore(
        binding: binding,
        clearFailure: StateError('private clear failure'),
      );
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        verifiedPrincipalBindingStore: receiptStore,
      );
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.bootFailure);
      expect(session.principalBindingCleanupRequired, isTrue);
      expect(receiptStore.binding!.matches(binding), isTrue);

      receiptStore.clearFailure = null;
      await session.retryBoot();

      expect(session.stage, JourneyStage.signIn);
      expect(session.principalBindingCleanupRequired, isFalse);
      expect(receiptStore.binding, isNull);
    },
  );

  test(
    'social rollback clear failure blocks every retry before provider UI',
    () async {
      final binding = await const ReviewPrincipalBindingProtector().protect(
        'private-user-a',
      );
      final receiptStore = MemoryVerifiedPrincipalBindingStore();
      final social = ReviewSocialAuthGateway(
        results: const {
          SocialAuthProvider.google: SocialAuthResult.authenticated(
            'private-user-a',
          ),
        },
      );
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        socialAuthGateway: social,
        accountBootstrapGateway: ReviewAccountBootstrapGateway(
          result: const AuthenticatedAccountBootstrapResult.invalidSession(),
          currentBinding: binding,
        ),
        verifiedPrincipalBindingStore: receiptStore,
        availableSocialAuthProviders: const {SocialAuthProvider.google},
      );
      addTearDown(session.dispose);
      await session.start();
      receiptStore.binding = binding;
      receiptStore.clearFailure = StateError('private clear failure');

      expect(
        await session.signInWithSocial(SocialAuthProvider.google),
        isFalse,
      );
      expect(session.principalBindingCleanupRequired, isTrue);
      expect(social.signInCount, 1);

      expect(
        await session.signInWithSocial(SocialAuthProvider.google),
        isFalse,
      );
      expect(social.signInCount, 1);
    },
  );

  test('OTP rollback clear failure blocks a later OTP request', () async {
    final binding = await const ReviewPrincipalBindingProtector().protect(
      'private-user-a',
    );
    final receiptStore = MemoryVerifiedPrincipalBindingStore();
    final otp = ReviewOtpGateway();
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: otp,
      accountBootstrapGateway: ReviewAccountBootstrapGateway(
        result: const AuthenticatedAccountBootstrapResult.invalidSession(),
        currentBinding: binding,
      ),
      verifiedPrincipalBindingStore: receiptStore,
    );
    addTearDown(session.dispose);
    await session.start();
    expect(await session.requestOtp('9876543210'), isTrue);
    receiptStore.binding = binding;
    receiptStore.clearFailure = StateError('private clear failure');

    expect(await session.verifyOtp('123456'), isFalse);
    expect(session.principalBindingCleanupRequired, isTrue);
    final requestCount = otp.requestCount;

    expect(await session.requestOtp('9876543210'), isFalse);
    expect(otp.requestCount, requestCount);
  });

  test('explicit sign-out clear failure remains fail-closed', () async {
    final binding = await const ReviewPrincipalBindingProtector().protect(
      'private-user-a',
    );
    final receiptStore = MemoryVerifiedPrincipalBindingStore(binding: binding);
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
      accountBootstrapGateway: ReviewAccountBootstrapGateway(
        result: AuthenticatedAccountBootstrapResult.verified(binding),
        currentBinding: binding,
      ),
      verifiedPrincipalBindingStore: receiptStore,
    );
    addTearDown(session.dispose);
    await session.start();
    receiptStore.clearFailure = StateError('private clear failure');

    expect(await session.signOut(), isFalse);

    expect(session.principalBindingCleanupRequired, isTrue);
    expect(session.isAuthenticated, isFalse);
    expect(session.stage, JourneyStage.signIn);
    expect(session.errorMessage, isNot(contains('private')));
  });

  test(
    'corrupt receipt resets secure binding and requires fresh sign-in',
    () async {
      final values = <String, String?>{};
      final receiptStore = SecureVerifiedPrincipalBindingStore.forTesting(
        readValue: ({required key}) async => values[key],
        writeValue: ({required key, required value}) async {
          values[key] = value;
        },
        deleteValue: ({required key}) async {
          values.remove(key);
        },
        createSecret: () => List<int>.filled(32, 11),
      );
      final binding = await receiptStore.protect('private-user-a');
      await receiptStore.write(binding);
      final receiptKey = values.keys.singleWhere(
        (key) => key.contains('verified_principal'),
      );
      values[receiptKey] = 'v2:corrupt';
      final bootstrap = ReviewAccountBootstrapGateway(
        result: AuthenticatedAccountBootstrapResult.verified(binding),
        currentBinding: binding,
      );
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
        accountBootstrapGateway: bootstrap,
        verifiedPrincipalBindingStore: receiptStore,
      );
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.signIn);
      expect(session.isAuthenticated, isFalse);
      expect(values, isEmpty);
      expect(bootstrap.invalidationCount, 1);

      final replacement = await receiptStore.protect('private-user-a');
      await receiptStore.write(replacement);
      expect((await receiptStore.read())!.matches(replacement), isTrue);
    },
  );

  test('legacy completed setup must show approved Screen 02 once', () async {
    final store = MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'skipped',
        setupComplete: true,
        setupExperienceVersion: 1,
      ),
    );
    final session = JourneySession(store: store);
    addTearDown(session.dispose);

    await session.start();

    expect(session.stage, JourneyStage.setup);
    session.selectArea(AreaChoice.skipped);
    expect(await session.completeSetup(), isTrue);
    expect(session.stage, JourneyStage.signIn);
    expect(
      store.snapshot?.setupExperienceVersion,
      approvedSetupExperienceVersion,
    );
  });

  test(
    'completed Screen 02 V4 must show corrected Screen 02 V5 once',
    () async {
      final store = MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
          setupExperienceVersion: 4,
        ),
      );
      final session = JourneySession(store: store);
      addTearDown(session.dispose);

      await session.start();

      expect(session.stage, JourneyStage.setup);
      session.selectArea(AreaChoice.skipped);
      expect(await session.completeSetup(), isTrue);
      expect(session.stage, JourneyStage.signIn);
      expect(
        store.snapshot?.setupExperienceVersion,
        approvedSetupExperienceVersion,
      );
    },
  );

  test(
    'unrelated persistence cannot claim required Screen 02 completion',
    () async {
      final store = MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
          setupExperienceVersion: 4,
        ),
      );
      final session = JourneySession(store: store);

      await session.start();
      expect(session.stage, JourneyStage.setup);
      expect(session.completedSetupExperienceVersion, 4);

      expect(await session.updateLanguage('hi'), isTrue);
      expect(store.snapshot?.setupExperienceVersion, 4);

      session.captureReturnTo('/app/buy/grocery');
      await Future<void>.delayed(Duration.zero);
      expect(store.snapshot?.setupExperienceVersion, 4);

      final restarted = JourneySession(store: store);
      await restarted.start();
      expect(restarted.stage, JourneyStage.setup);
      expect(restarted.completedSetupExperienceVersion, 4);
    },
  );

  test(
    'fresh protected route cannot manufacture Screen 02 completion',
    () async {
      final store = MemoryJourneyStore();
      final session = JourneySession(store: store);

      session.captureReturnTo('/app/buy/grocery');
      await Future<void>.delayed(Duration.zero);

      expect(store.snapshot?.setupComplete, isFalse);
      expect(store.snapshot?.setupExperienceVersion, 0);

      await session.start();
      expect(session.stage, JourneyStage.setup);
      expect(session.completedSetupExperienceVersion, 0);
    },
  );

  test(
    'authenticated legacy setup returns ready after approved Screen 02',
    () async {
      final store = MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
          setupExperienceVersion: 1,
        ),
      );
      final session = JourneySession(
        store: store,
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(session.dispose);

      await session.start();
      expect(session.stage, JourneyStage.setup);
      session.selectArea(AreaChoice.manual, label: 'Jodhpur');
      expect(await session.completeSetup(), isTrue);
      expect(session.stage, JourneyStage.ready);
    },
  );

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

  test(
    'social callback fails closed when another account is authenticated',
    () async {
      final callbackGateway = _CallbackSocialAuthGateway(signedIn: true);
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'skipped',
            setupComplete: true,
            setupExperienceVersion: approvedSetupExperienceVersion,
          ),
        ),
        socialAuthGateway: callbackGateway,
      );
      addTearDown(session.dispose);

      final handled = await session.prepareSocialAuthReturn(
        'moolsocial://auth/x?code=provider-code&state=provider-state',
      );

      expect(handled, isTrue);
      expect(session.stage, JourneyStage.ready);
      expect(session.socialAuthState, SocialAuthState.failed);
      expect(
        session.socialAuthReceiptCode,
        'auth-callback-already-authenticated',
      );
      expect(callbackGateway.callbackCompletionCount, 0);
    },
  );

  test('provider denial remains a failed callback, not cancellation', () async {
    final callbackGateway = _CallbackSocialAuthGateway(
      callbackFailure: const JourneyServiceException(
        'X did not authorize this sign-in.',
        code: 'auth-authorization-denied',
      ),
    );
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
          setupExperienceVersion: approvedSetupExperienceVersion,
        ),
      ),
      socialAuthGateway: callbackGateway,
    );
    addTearDown(session.dispose);

    final handled = await session.prepareSocialAuthReturn(
      'moolsocial://auth/x?error=access_denied&state=provider-state',
    );

    expect(handled, isTrue);
    expect(session.socialAuthState, SocialAuthState.failed);
    expect(session.socialAuthReceiptCode, 'auth-authorization-denied');
    expect(callbackGateway.callbackCompletionCount, 1);
  });
}

class _NeverCompletesAccountBootstrap implements AccountBootstrapGateway {
  @override
  Future<AuthenticatedAccountBootstrapResult> prepareAuthenticatedAccount({
    String? expectedUserId,
  }) => Future<AuthenticatedAccountBootstrapResult>.delayed(
    const Duration(days: 1),
  );

  @override
  Future<VerifiedPrincipalBinding?> currentPrincipalBinding() async => null;

  @override
  Future<void> invalidateLocalSession() async {}
}

class _TimeoutPrincipalBootstrap implements AccountBootstrapGateway {
  _TimeoutPrincipalBootstrap(this.bindings);

  final List<VerifiedPrincipalBinding?> bindings;
  int bindingReadCount = 0;
  int invalidationCount = 0;

  @override
  Future<VerifiedPrincipalBinding?> currentPrincipalBinding() async {
    final index = bindingReadCount < bindings.length
        ? bindingReadCount
        : bindings.length - 1;
    bindingReadCount += 1;
    return bindings[index];
  }

  @override
  Future<void> invalidateLocalSession() async {
    invalidationCount += 1;
  }

  @override
  Future<AuthenticatedAccountBootstrapResult> prepareAuthenticatedAccount({
    String? expectedUserId,
  }) => Completer<AuthenticatedAccountBootstrapResult>().future;
}

class _CallbackSocialAuthGateway
    implements SocialAuthGateway, SocialAuthCallbackGateway {
  _CallbackSocialAuthGateway({this.signedIn = false, this.callbackFailure});

  bool signedIn;
  final JourneyServiceException? callbackFailure;
  int callbackCompletionCount = 0;

  @override
  Future<bool> hasAuthenticatedUser() async => signedIn;

  @override
  Future<SocialAuthResult> signIn(SocialAuthProvider provider) async =>
      const SocialAuthResult.cancelled();

  @override
  Future<void> signOut() async {
    signedIn = false;
  }

  @override
  SocialAuthProvider? providerForCallback(Uri callbackUri) =>
      callbackUri.host == 'auth' && callbackUri.path == '/x'
      ? SocialAuthProvider.x
      : null;

  @override
  Future<SocialAuthResult> completeForegroundCallback(Uri callbackUri) =>
      _completeCallback();

  @override
  Future<SocialAuthResult> completeColdStartCallback(Uri callbackUri) =>
      _completeCallback();

  Future<SocialAuthResult> _completeCallback() async {
    callbackCompletionCount += 1;
    if (callbackFailure case final failure?) throw failure;
    signedIn = true;
    return const SocialAuthResult.authenticated(
      'callback-user',
      code: 'auth-provider-credential-complete',
    );
  }
}
