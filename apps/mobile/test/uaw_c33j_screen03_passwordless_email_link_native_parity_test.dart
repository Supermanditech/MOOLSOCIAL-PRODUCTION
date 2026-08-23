import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/login_screen_v5.dart';

void main() {
  Future<JourneySession> sessionFor({
    MemoryJourneyStore? store,
    EmailLinkGateway? emailLinkGateway,
    SocialAuthGateway? socialAuthGateway,
    OtpGateway? otpGateway,
    AccountBootstrapGateway? accountBootstrapGateway,
    Set<SocialAuthProvider>? availableProviders,
    DateTime Function()? now,
    Duration resendCooldown = const Duration(seconds: 30),
  }) async {
    final session = JourneySession(
      store: store ?? _completedStore(),
      emailLinkGateway: emailLinkGateway ?? ReviewEmailLinkGateway(),
      emailLinkAvailable: true,
      socialAuthGateway: socialAuthGateway,
      otpGateway: otpGateway,
      accountBootstrapGateway: accountBootstrapGateway,
      availableSocialAuthProviders: availableProviders,
      now: now,
      resendCooldown: resendCooldown,
    );
    await session.start();
    return session;
  }

  Future<void> mount(
    WidgetTester tester,
    JourneySession session, {
    Size size = const Size(360, 720),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        home: LoginScreenV5(session: session),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('founder-final chooser preserves exact method structure', (
    tester,
  ) async {
    final session = await sessionFor();
    addTearDown(session.dispose);
    await mount(tester, session);

    expect(find.byKey(const Key('screen03-login-v5')), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Choose one method to continue.'), findsOneWidget);
    for (final label in const [
      'Google',
      'YouTube',
      'Apple',
      'X',
      'Instagram',
      'Facebook',
      'Email link',
      'Mobile OTP',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Email OTP'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product sign-in route selects v5 without changing v4 owner', (
    tester,
  ) async {
    final session = await sessionFor();
    addTearDown(session.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/sign-in'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen03-login-v5')), findsOneWidget);
    expect(find.byKey(const Key('screen03-login-v2')), findsNothing);
  });

  testWidgets('visible unavailable provider is physically non-actionable', (
    tester,
  ) async {
    final social = ReviewSocialAuthGateway();
    final session = await sessionFor(
      socialAuthGateway: social,
      availableProviders: const {SocialAuthProvider.google},
    );
    addTearDown(session.dispose);
    await mount(tester, session);

    final facebookButton = tester.widget<InkWell>(
      find.byKey(const Key('screen03-v5-provider-facebook')),
    );

    expect(facebookButton.onTap, isNull);
    expect(social.signInCount, 0);
    expect(find.text('Facebook sign-in isn’t available'), findsNothing);
    expect(find.byKey(const Key('social-auth-retry')), findsNothing);
    expect(find.byKey(const Key('social-auth-change-method')), findsNothing);
  });

  testWidgets('email link validates, masks and never claims early success', (
    tester,
  ) async {
    final gateway = ReviewEmailLinkGateway();
    final session = await sessionFor(emailLinkGateway: gateway);
    addTearDown(session.dispose);
    await mount(tester, session);

    await tester.tap(find.byKey(const Key('email-link-method')));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('email-link-field')),
      'not-an-email',
    );
    await tester.tap(find.byKey(const Key('send-email-link')));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(session.emailLinkReceiptCode, 'email-link-invalid-email');
    expect(gateway.sendCount, 0);

    await tester.enterText(
      find.byKey(const Key('email-link-field')),
      'Person@Example.com',
    );
    await tester.tap(find.byKey(const Key('send-email-link')));
    await tester.pump();

    expect(gateway.sendCount, 1);
    expect(gateway.lastEmailAddress, 'person@example.com');
    expect(session.emailLinkState, EmailLinkState.sent);
    expect(session.emailLinkReceiptCode, 'email-link-sent');
    expect(session.isAuthenticated, isFalse);
    expect(session.stage, JourneyStage.signIn);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('p•••••@example.com'), findsOneWidget);
    expect(find.text('person@example.com'), findsNothing);
  });

  test('resend is fail-closed until cooldown ends', () async {
    var now = DateTime.utc(2026, 8, 15, 1);
    final gateway = ReviewEmailLinkGateway();
    final session = await sessionFor(
      emailLinkGateway: gateway,
      now: () => now,
      resendCooldown: const Duration(seconds: 30),
    );
    addTearDown(session.dispose);

    expect(await session.requestEmailLink('person@example.com'), isTrue);
    expect(await session.resendEmailLink(), isFalse);
    expect(gateway.sendCount, 1);
    expect(session.errorMessage, contains('30 seconds'));

    now = now.add(const Duration(seconds: 30));
    expect(await session.resendEmailLink(), isTrue);
    expect(gateway.sendCount, 2);
  });

  test('same-session valid link completes exact pending destination', () async {
    final store = _completedStore(pendingRoute: '/app/social?sub=create');
    final gateway = ReviewEmailLinkGateway();
    final session = await sessionFor(store: store, emailLinkGateway: gateway);
    addTearDown(session.dispose);

    expect(await session.requestEmailLink('person@example.com'), isTrue);
    expect(await session.prepareEmailLinkReturn(gateway.acceptedLink), isTrue);

    expect(session.isAuthenticated, isTrue);
    expect(session.stage, JourneyStage.ready);
    expect(session.emailLinkReceiptCode, 'email-link-session-ready');
    expect(session.readyRoute(), '/app/social?sub=create');
    expect(gateway.completionCount, 1);
  });

  test('unclassified Firebase send failure remains stage-specific', () async {
    final gateway = ReviewEmailLinkGateway(
      sendFailure: const JourneyServiceException(
        'Email sign-in could not be classified safely. Please try again.',
        code: 'email-link-firebase-unclassified',
      ),
    );
    final session = await sessionFor(emailLinkGateway: gateway);
    addTearDown(session.dispose);

    expect(await session.requestEmailLink('person@example.com'), isFalse);
    expect(session.emailLinkState, EmailLinkState.failed);
    expect(session.emailLinkReceiptCode, 'email-link-firebase-unclassified');
    expect(session.errorMessage, isNot(contains('person@example.com')));
  });

  test(
    'exact safe Firebase email code drives matching-address recovery',
    () async {
      final gateway = ReviewEmailLinkGateway(
        completionFailure: const JourneyServiceException(
          'Enter the email address that received this link.',
          code: 'invalid-recipient-email',
        ),
      );
      final session = await sessionFor(emailLinkGateway: gateway);
      addTearDown(session.dispose);

      expect(await session.requestEmailLink('person@example.com'), isTrue);
      expect(
        await session.prepareEmailLinkReturn(gateway.acceptedLink),
        isTrue,
      );
      expect(session.emailLinkState, EmailLinkState.awaitingEmail);
      expect(session.emailLinkReceiptCode, 'invalid-recipient-email');
      expect(session.isAuthenticated, isFalse);
      expect(session.errorMessage, isNot(contains('person@example.com')));
    },
  );

  test('process return asks for matching email before completion', () async {
    final store = _completedStore(
      pendingRoute: '/app/chat/inbox?return=/app/social',
    );
    final gateway = ReviewEmailLinkGateway();
    final first = await sessionFor(store: store, emailLinkGateway: gateway);
    expect(await first.requestEmailLink('person@example.com'), isTrue);
    first.dispose();

    final returned = JourneySession(
      store: store,
      emailLinkGateway: gateway,
      emailLinkAvailable: true,
    );
    addTearDown(returned.dispose);
    expect(await returned.prepareEmailLinkReturn(gateway.acceptedLink), isTrue);
    expect(returned.emailLinkState, EmailLinkState.awaitingEmail);
    expect(returned.isAuthenticated, isFalse);

    expect(await returned.completeEmailLink('other@example.com'), isFalse);
    expect(returned.emailLinkState, EmailLinkState.awaitingEmail);
    expect(returned.isAuthenticated, isFalse);

    expect(await returned.completeEmailLink('person@example.com'), isTrue);
    expect(returned.isAuthenticated, isTrue);
    expect(returned.readyRoute(), '/app/chat/inbox?return=/app/social');
  });

  test('expired link and bootstrap failure stay recoverable', () async {
    final expiredGateway = ReviewEmailLinkGateway();
    final expired = await sessionFor(emailLinkGateway: expiredGateway);
    addTearDown(expired.dispose);
    expect(await expired.requestEmailLink('person@example.com'), isTrue);
    expiredGateway.completionFailure = const JourneyServiceException(
      'This sign-in link has expired. Request a new link.',
      code: 'expired-action-code',
    );
    expect(
      await expired.prepareEmailLinkReturn(expiredGateway.acceptedLink),
      isTrue,
    );
    expect(expired.emailLinkState, EmailLinkState.expired);
    expect(expired.isAuthenticated, isFalse);

    final rollbackGateway = ReviewEmailLinkGateway();
    final bootstrap = ReviewAccountBootstrapGateway(
      failure: StateError('bootstrap failed'),
    );
    final rollback = await sessionFor(
      emailLinkGateway: rollbackGateway,
      accountBootstrapGateway: bootstrap,
    );
    addTearDown(rollback.dispose);
    expect(await rollback.requestEmailLink('person@example.com'), isTrue);
    expect(
      await rollback.prepareEmailLinkReturn(rollbackGateway.acceptedLink),
      isTrue,
    );
    expect(rollback.isAuthenticated, isFalse);
    expect(rollback.stage, JourneyStage.signIn);
    expect(rollbackGateway.signOutCount, 1);
    expect(rollback.emailLinkState, EmailLinkState.failed);
  });

  testWidgets('small viewport and 140 percent text remain scroll-safe', (
    tester,
  ) async {
    final session = await sessionFor();
    addTearDown(session.dispose);
    await mount(tester, session, size: const Size(320, 568), textScale: 1.4);

    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('email-link-method')));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile OTP keeps the existing verified route contract', (
    tester,
  ) async {
    final otp = ReviewOtpGateway();
    final session = await sessionFor(otpGateway: otp);
    addTearDown(session.dispose);
    await mount(tester, session);

    await tester.tap(find.byKey(const Key('mobile-otp-method')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tester.tap(find.byKey(const Key('send-mobile-otp')));
    await tester.pumpAndSettle();

    expect(session.stage, JourneyStage.verify);
    expect(session.otpChannel, OtpChannel.mobile);
    expect(otp.lastPhoneNumber, '+919876543210');
  });
}

MemoryJourneyStore _completedStore({String? pendingRoute}) {
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
