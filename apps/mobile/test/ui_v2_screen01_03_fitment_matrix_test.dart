import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/launch/launch_presentation_gate.dart';
import 'package:moolsocial/ui_v2/screens/screen01_app_splash/app_splash_screen_v2.dart';
import 'package:moolsocial/ui_v2/screens/screen02_first_setup/first_setup_screen_v2.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/login_screen_v2.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/otp_screen_v2.dart';

const _phoneMatrix =
    <({Size size, double textScale, EdgeInsets safePadding, String label})>[
      (
        size: Size(320, 568),
        textScale: 1,
        safePadding: EdgeInsets.only(top: 20),
        label: 'compact Android/iPhone SE',
      ),
      (
        size: Size(360, 640),
        textScale: 1,
        safePadding: EdgeInsets.fromLTRB(0, 24, 0, 24),
        label: 'compact Android',
      ),
      (
        size: Size(360, 720),
        textScale: 1,
        safePadding: EdgeInsets.fromLTRB(0, 24, 0, 24),
        label: 'approved comparison',
      ),
      (
        size: Size(375, 667),
        textScale: 1,
        safePadding: EdgeInsets.only(top: 20),
        label: 'iPhone 8/SE',
      ),
      (
        size: Size(390, 844),
        textScale: 1,
        safePadding: EdgeInsets.fromLTRB(0, 47, 0, 34),
        label: 'iPhone 12-15',
      ),
      (
        size: Size(412, 915),
        textScale: 1,
        safePadding: EdgeInsets.fromLTRB(0, 24, 0, 24),
        label: 'large Android',
      ),
      (
        size: Size(430, 932),
        textScale: 1,
        safePadding: EdgeInsets.fromLTRB(0, 59, 0, 34),
        label: 'iPhone Pro Max',
      ),
      (
        size: Size(320, 568),
        textScale: 1.4,
        safePadding: EdgeInsets.only(top: 20),
        label: 'compact at 140% text',
      ),
      (
        size: Size(360, 640),
        textScale: 1.4,
        safePadding: EdgeInsets.fromLTRB(0, 24, 0, 24),
        label: 'Android at 140% text',
      ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Screen 01 normal, slow and recovery fit every phone viewport', (
    tester,
  ) async {
    for (final viewport in _phoneMatrix) {
      final pending = Completer<JourneySnapshot?>();
      final normalSession = JourneySession(
        store: _PendingJourneyStore(pending),
      );
      final normalGate = LaunchPresentationGate();
      await _mount(
        tester,
        AppSplashScreenV2(session: normalSession, presentationGate: normalGate),
        viewport,
      );
      expect(find.byKey(const Key('splash-v2-normal')), findsOneWidget);
      _expectNoLayoutFailure(tester, 'Screen 01 normal · ${viewport.label}');

      await tester.pump(const Duration(milliseconds: 3100));
      expect(find.byKey(const Key('splash-v2-handoff')), findsOneWidget);
      _expectNoLayoutFailure(tester, 'Screen 01 slow · ${viewport.label}');
      pending.complete(null);
      await _unmount(tester);
      normalSession.dispose();
      normalGate.dispose();

      final recoverySession = JourneySession(
        store: MemoryJourneyStore(readFailure: StateError('offline')),
      );
      final recoveryGate = LaunchPresentationGate();
      await _mount(
        tester,
        AppSplashScreenV2(
          session: recoverySession,
          presentationGate: recoveryGate,
        ),
        viewport,
      );
      await tester.pump();
      expect(find.byKey(const Key('splash-v2-recovery')), findsOneWidget);
      await _expectReachableAction(
        tester,
        const Key('retry-boot'),
        'Screen 01 Retry · ${viewport.label}',
      );
      await _expectReachableAction(
        tester,
        const Key('boot-help'),
        'Screen 01 Help · ${viewport.label}',
      );
      _expectNoLayoutFailure(tester, 'Screen 01 recovery · ${viewport.label}');
      await _unmount(tester);
      recoverySession.dispose();
      recoveryGate.dispose();
    }
  });

  testWidgets(
    'Screen 02 consent, resolved and recovery fit every phone viewport',
    (tester) async {
      for (final viewport in _phoneMatrix) {
        final consent = JourneySession();
        await consent.start();
        await _mount(tester, FirstSetupScreenV2(session: consent), viewport);
        await _expectReachableAction(
          tester,
          const Key('setup-v4-allow-location'),
          'Screen 02 Allow location · ${viewport.label}',
        );
        await _expectReachableAction(
          tester,
          const Key('setup-v4-continue-for-now'),
          'Screen 02 Continue for now · ${viewport.label}',
        );
        _expectNoLayoutFailure(tester, 'Screen 02 consent · ${viewport.label}');
        await _unmount(tester);
        consent.dispose();

        final resolved = JourneySession(
          currentAreaGateway: ReviewCurrentAreaGateway(),
        );
        await resolved.start();
        expect(await resolved.resolveCurrentArea(), isTrue);
        await _mount(tester, FirstSetupScreenV2(session: resolved), viewport);
        await tester.pump();
        await _expectReachableAction(
          tester,
          const Key('setup-v4-continue'),
          'Screen 02 Continue · ${viewport.label}',
        );
        _expectNoLayoutFailure(
          tester,
          'Screen 02 resolved · ${viewport.label}',
        );
        await _unmount(tester);
        resolved.dispose();

        final unavailable = JourneySession(
          currentAreaGateway: ReviewCurrentAreaGateway(
            failureReason: CurrentAreaFailureReason.unavailable,
          ),
        );
        await unavailable.start();
        await _mount(
          tester,
          FirstSetupScreenV2(session: unavailable),
          viewport,
        );
        await _expectReachableAction(
          tester,
          const Key('setup-v4-allow-location'),
          'Screen 02 recovery entry · ${viewport.label}',
        );
        await tester.tap(find.byKey(const Key('setup-v4-allow-location')));
        await tester.pumpAndSettle();
        await _expectReachableAction(
          tester,
          const Key('setup-v4-retry'),
          'Screen 02 Try again · ${viewport.label}',
        );
        await _expectReachableAction(
          tester,
          const Key('setup-v4-continue-for-now'),
          'Screen 02 recovery Continue · ${viewport.label}',
        );
        _expectNoLayoutFailure(
          tester,
          'Screen 02 recovery · ${viewport.label}',
        );
        await _unmount(tester);
        unavailable.dispose();
      }
    },
  );

  testWidgets(
    'Screen 03 login, mobile OTP and email OTP fit every phone viewport',
    (tester) async {
      for (final viewport in _phoneMatrix) {
        final login = await _signedOutSession();
        await _mount(tester, LoginScreenV2(session: login), viewport);
        await _expectReachableAction(
          tester,
          const Key('mobile-otp-method'),
          'Screen 03 Mobile OTP · ${viewport.label}',
        );
        await _expectReachableAction(
          tester,
          const Key('email-otp-method'),
          'Screen 03 Email OTP · ${viewport.label}',
        );
        _expectNoLayoutFailure(tester, 'Screen 03 login · ${viewport.label}');
        await _unmount(tester);
        login.dispose();

        final mobile = await _signedOutSession(otpGateway: ReviewOtpGateway());
        expect(await mobile.requestOtp('9876543210'), isTrue);
        await _mount(tester, OtpScreenV2(session: mobile), viewport);
        await _expectReachableAction(
          tester,
          const Key('verify-otp'),
          'Screen 03 mobile Verify · ${viewport.label}',
        );
        await _expectReachableAction(
          tester,
          const Key('change-method'),
          'Screen 03 mobile Change method · ${viewport.label}',
        );
        _expectNoLayoutFailure(
          tester,
          'Screen 03 mobile OTP · ${viewport.label}',
        );
        await _unmount(tester);
        mobile.dispose();

        final email = await _signedOutSession(
          emailOtpGateway: ReviewEmailOtpGateway(),
        );
        expect(await email.requestEmailOtp('member@moolsocial.in'), isTrue);
        await _mount(tester, OtpScreenV2(session: email), viewport);
        await _expectReachableAction(
          tester,
          const Key('verify-otp'),
          'Screen 03 email Verify · ${viewport.label}',
        );
        await _expectReachableAction(
          tester,
          const Key('change-method'),
          'Screen 03 email Change method · ${viewport.label}',
        );
        _expectNoLayoutFailure(
          tester,
          'Screen 03 email OTP · ${viewport.label}',
        );
        await _unmount(tester);
        email.dispose();
      }
    },
  );
}

Future<void> _mount(
  WidgetTester tester,
  Widget child,
  ({Size size, double textScale, EdgeInsets safePadding, String label})
  viewport,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport.size;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: viewport.size,
          textScaler: TextScaler.linear(viewport.textScale),
          padding: viewport.safePadding,
          viewPadding: viewport.safePadding,
        ),
        child: child,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void _expectNoLayoutFailure(WidgetTester tester, String state) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: '$state must render without an exception.');
}

Future<void> _expectReachableAction(
  WidgetTester tester,
  Key key,
  String state,
) async {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget, reason: '$state must exist.');
  await tester.ensureVisible(finder);
  await tester.pump();
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(44), reason: '$state tap width.');
  expect(size.height, greaterThanOrEqualTo(44), reason: '$state tap height.');
}

Future<JourneySession> _signedOutSession({
  OtpGateway? otpGateway,
  EmailOtpGateway? emailOtpGateway,
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
  );
  await session.start();
  return session;
}

class _PendingJourneyStore implements JourneyStore {
  _PendingJourneyStore(this.readResult);

  final Completer<JourneySnapshot?> readResult;

  @override
  Future<JourneySnapshot?> read() => readResult.future;

  @override
  Future<void> write(JourneySnapshot value) async {}
}
