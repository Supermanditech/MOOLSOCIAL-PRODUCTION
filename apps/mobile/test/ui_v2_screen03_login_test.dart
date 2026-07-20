import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/login_screen_v2.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/otp_screen_v2.dart';

void main() {
  Future<JourneySession> signedOutSession({
    OtpGateway? otpGateway,
    EmailOtpGateway? emailOtpGateway,
    SocialAuthGateway? socialAuthGateway,
    Duration resendCooldown = const Duration(seconds: 30),
  }) async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'current',
          currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
          setupComplete: true,
        ),
      ),
      otpGateway: otpGateway,
      emailOtpGateway: emailOtpGateway,
      socialAuthGateway: socialAuthGateway,
      resendCooldown: resendCooldown,
    );
    await session.start();
    return session;
  }

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(360, 720),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('approved login options fit the 360x720 viewport', (
    tester,
  ) async {
    final session = await signedOutSession();
    addTearDown(session.dispose);

    await mount(tester, LoginScreenV2(session: session));

    expect(find.byKey(const Key('screen03-login-v2')), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Choose one method to continue.'), findsOneWidget);
    for (final label in const [
      'Google',
      'YouTube',
      'Apple',
      'X',
      'Instagram',
      'Facebook',
      'Email OTP',
      'Mobile OTP',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('every provider tap reaches its own recoverable return state', (
    tester,
  ) async {
    final social = ReviewSocialAuthGateway();
    final session = await signedOutSession(socialAuthGateway: social);
    addTearDown(session.dispose);
    await mount(tester, LoginScreenV2(session: session));

    for (final provider in SocialAuthProvider.values) {
      await tester.tap(find.byKey(Key('screen03-provider-${provider.name}')));
      await tester.pumpAndSettle();

      expect(social.lastProvider, provider);
      expect(find.byKey(const Key('social-auth-message')), findsOneWidget);
      expect(find.byKey(const Key('social-auth-retry')), findsOneWidget);
      expect(
        find.byKey(const Key('social-auth-change-method')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('social-auth-change-method')));
      await tester.pumpAndSettle();
    }
    expect(social.signInCount, SocialAuthProvider.values.length);
  });

  testWidgets('mobile target validates then opens the accepted OTP state', (
    tester,
  ) async {
    final otp = ReviewOtpGateway();
    final session = await signedOutSession(otpGateway: otp);
    addTearDown(session.dispose);
    await mount(tester, LoginScreenV2(session: session));

    await tester.tap(find.byKey(const Key('mobile-otp-method')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '123');
    await tester.tap(find.byKey(const Key('send-otp')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign-in-error')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tester.tap(find.byKey(const Key('send-otp')));
    await tester.pumpAndSettle();

    expect(session.stage, JourneyStage.verify);
    expect(session.otpChannel, OtpChannel.mobile);
    expect(otp.lastPhoneNumber, '+919876543210');

    await mount(tester, OtpScreenV2(session: session));
    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('Sent to +91 ******3210'), findsOneWidget);
    expect(find.text('MOBILE OTP'), findsOneWidget);
    expect(find.textContaining('same verify screen'), findsNothing);
    expect(find.textContaining('instead of mobile'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('email target and verification complete to ready', (
    tester,
  ) async {
    final email = ReviewEmailOtpGateway();
    final session = await signedOutSession(emailOtpGateway: email);
    addTearDown(session.dispose);
    await mount(tester, LoginScreenV2(session: session));

    await tester.tap(find.byKey(const Key('email-otp-method')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('email-field')),
      'person@example.com',
    );
    await tester.tap(find.byKey(const Key('send-otp')));
    await tester.pumpAndSettle();

    expect(session.stage, JourneyStage.verify);
    expect(session.otpChannel, OtpChannel.email);
    expect(email.lastEmailAddress, 'person@example.com');

    await mount(tester, OtpScreenV2(session: session));
    expect(find.text('Sent to p*****@example.com'), findsOneWidget);
    expect(find.text('EMAIL OTP'), findsOneWidget);
    expect(find.textContaining('same verify screen'), findsNothing);
    expect(find.textContaining('instead of mobile'), findsNothing);
    await tester.tap(find.byKey(const Key('verify-otp')));
    await tester.pumpAndSettle();

    expect(session.stage, JourneyStage.ready);
    expect(email.verificationCount, 1);
  });

  testWidgets('resend replaces a stale review autofill code', (tester) async {
    final otp = _RotatingReviewOtpGateway();
    final session = await signedOutSession(
      otpGateway: otp,
      resendCooldown: Duration.zero,
    );
    addTearDown(session.dispose);
    expect(await session.requestOtp('9876543210'), isTrue);
    await mount(tester, OtpScreenV2(session: session));

    expect(find.text('1'), findsNWidgets(6));
    await tester.tap(find.byKey(const Key('resend-otp')));
    await tester.pumpAndSettle();

    expect(otp.requestCount, 2);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNWidgets(6));
  });

  testWidgets('customer viewport contains no internal working language', (
    tester,
  ) async {
    final session = await signedOutSession();
    addTearDown(session.dispose);
    await mount(tester, LoginScreenV2(session: session));

    final visibleCopy = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('screen03-login-v2')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data ?? '')
        .join(' ');
    expect(
      RegExp(
        r'\b(production|prototype|review|sample|working note|internal plan|'
        r'owner|route|workflow|implementation|fallback|test|next screen)\b',
        caseSensitive: false,
      ).hasMatch(visibleCopy),
      isFalse,
    );
  });
}

class _RotatingReviewOtpGateway implements OtpGateway {
  int requestCount = 0;

  @override
  Future<bool> hasAuthenticatedUser() async => false;

  @override
  Future<OtpRequestResult> requestCode(String phoneNumber) async {
    requestCount += 1;
    return const OtpRequestResult();
  }

  @override
  Future<String?> reviewCodeFor(String phoneNumber) async {
    return requestCount == 1 ? '111111' : '222222';
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String> verifyCode(String code) async => 'rotating-user';
}
