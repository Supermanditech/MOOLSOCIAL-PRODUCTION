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

final _forbiddenCustomerCopy = RegExp(
  r'\b(?:production|prototype|founder review|review build|sample|example|demo|'
  r'mock|placeholder|working note|internal plan|implementation|workflow|'
  r'state machine|endpoint|payload|backend|provider callback|next screen|'
  r'screen 0[1-4]|same verify screen|instead of (?:email|mobile)|'
  r'this screen is used for|for (?:review|testing))\b',
  caseSensitive: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('state-complete customer-copy machine gate', () {
    testWidgets('Screen 01 audits normal, reduced-motion, slow and recovery', (
      tester,
    ) async {
      final sessions = <JourneySession>[];
      final gates = <LaunchPresentationGate>[];

      Future<void> auditSplash({
        required JourneyStore store,
        bool reducedMotion = false,
        bool waitForSlowState = false,
      }) async {
        final session = JourneySession(store: store);
        final gate = LaunchPresentationGate();
        sessions.add(session);
        gates.add(gate);
        await _mount(
          tester,
          AppSplashScreenV2(session: session, presentationGate: gate),
          reducedMotion: reducedMotion,
        );
        await tester.pump();
        if (waitForSlowState) {
          await tester.pump(const Duration(milliseconds: 3100));
        }
        _expectCustomerCopy(tester, const Key('screen01-v2'));
      }

      final normalRead = Completer<JourneySnapshot?>();
      await auditSplash(store: _PendingJourneyStore(normalRead));
      normalRead.complete(null);
      await tester.pump();

      final reducedRead = Completer<JourneySnapshot?>();
      await auditSplash(
        store: _PendingJourneyStore(reducedRead),
        reducedMotion: true,
      );
      reducedRead.complete(null);
      await tester.pump();

      final slowRead = Completer<JourneySnapshot?>();
      await auditSplash(
        store: _PendingJourneyStore(slowRead),
        waitForSlowState: true,
      );
      slowRead.complete(null);
      await tester.pump();

      await auditSplash(
        store: MemoryJourneyStore(readFailure: StateError('offline')),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      for (final session in sessions) {
        session.dispose();
      }
      for (final gate in gates) {
        gate.dispose();
      }
    });

    testWidgets(
      'Screen 02 audits consent, resolving, resolved and every recovery',
      (tester) async {
        final sessions = <JourneySession>[];
        final pendingArea = _PendingAreaGateway();
        final pendingSession = JourneySession(currentAreaGateway: pendingArea);
        sessions.add(pendingSession);
        await pendingSession.start();
        await _mount(tester, FirstSetupScreenV2(session: pendingSession));
        _expectCustomerCopy(tester, const Key('screen02-v4'));

        await tester.tap(find.byKey(const Key('setup-v4-allow-location')));
        await tester.pump();
        expect(find.byKey(const ValueKey('preparing')), findsOneWidget);
        _expectCustomerCopy(tester, const Key('screen02-v4'));

        pendingArea.complete(
          const ResolvedCurrentArea(
            primaryLabel: 'Sardarpura',
            secondaryLabel: 'Jodhpur, Rajasthan',
            fullLabel: 'Sardarpura, Jodhpur, Rajasthan',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('resolved')), findsOneWidget);
        _expectCustomerCopy(tester, const Key('screen02-v4'));

        for (final reason in CurrentAreaFailureReason.values) {
          final area = ReviewCurrentAreaGateway(failureReason: reason);
          final session = JourneySession(currentAreaGateway: area);
          sessions.add(session);
          await session.start();
          await _mount(tester, FirstSetupScreenV2(session: session));
          await tester.tap(find.byKey(const Key('setup-v4-allow-location')));
          await tester.pumpAndSettle();
          _expectCustomerCopy(tester, const Key('screen02-v4'));
        }
        await tester.pumpWidget(const SizedBox.shrink());
        for (final session in sessions) {
          session.dispose();
        }
      },
    );

    testWidgets(
      'Screen 03 audits login, every provider return, target sheets and OTP',
      (tester) async {
        final social = ReviewSocialAuthGateway();
        final session = await _signedOutSession(socialAuthGateway: social);
        await _mount(tester, LoginScreenV2(session: session));
        _expectCustomerCopy(tester, const Key('screen03-login-v2'));

        for (final provider in SocialAuthProvider.values) {
          await tester.tap(
            find.byKey(Key('screen03-provider-${provider.name}')),
          );
          await tester.pumpAndSettle();
          _expectCustomerCopy(tester, const Key('screen03-login-v2'));
          await tester.tap(find.byKey(const Key('social-auth-change-method')));
          await tester.pumpAndSettle();
        }

        for (final methodKey in const [
          Key('mobile-otp-method'),
          Key('email-otp-method'),
        ]) {
          await tester.tap(find.byKey(methodKey));
          await tester.pumpAndSettle();
          _expectCustomerCopy(tester, const Key('screen03-login-v2'));
          await tester.tap(find.text('Back'));
          await tester.pumpAndSettle();
        }
        session.dispose();

        final mobile = await _signedOutSession(otpGateway: ReviewOtpGateway());
        expect(await mobile.requestOtp('9876543210'), isTrue);
        await _mount(tester, OtpScreenV2(session: mobile));
        _expectCustomerCopy(tester, const Key('screen03-otp-v2'));
        expect(find.textContaining('same verify screen'), findsNothing);
        mobile.dispose();

        final email = await _signedOutSession(
          emailOtpGateway: ReviewEmailOtpGateway(),
        );
        expect(await email.requestEmailOtp('member@moolsocial.in'), isTrue);
        await _mount(tester, OtpScreenV2(session: email));
        _expectCustomerCopy(tester, const Key('screen03-otp-v2'));
        expect(find.textContaining('instead of mobile'), findsNothing);

        await tester.enterText(find.byKey(const Key('otp-field')), '000000');
        await tester.tap(find.byKey(const Key('verify-otp')));
        await tester.pumpAndSettle();
        _expectCustomerCopy(tester, const Key('screen03-otp-v2'));
        email.dispose();
      },
    );
  });
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(360, 720),
  double textScale = 1,
  bool reducedMotion = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
          accessibleNavigation: reducedMotion,
        ),
        child: child,
      ),
    ),
  );
  await tester.pump();
}

void _expectCustomerCopy(WidgetTester tester, Key rootKey) {
  final root = find.byKey(rootKey);
  expect(root, findsOneWidget);

  final copy = <String>[];
  for (final text in tester.widgetList<Text>(
    find.descendant(of: root, matching: find.byType(Text)),
  )) {
    copy.add(text.data ?? text.textSpan?.toPlainText() ?? '');
  }
  for (final field in tester.widgetList<TextField>(
    find.descendant(of: root, matching: find.byType(TextField)),
  )) {
    final decoration = field.decoration;
    copy.addAll([
      decoration?.labelText ?? '',
      decoration?.hintText ?? '',
      decoration?.helperText ?? '',
      decoration?.prefixText ?? '',
      decoration?.suffixText ?? '',
    ]);
  }
  for (final semantics in tester.widgetList<Semantics>(
    find.descendant(of: root, matching: find.byType(Semantics)),
  )) {
    copy.add(semantics.properties.label ?? '');
    copy.add(semantics.properties.hint ?? '');
  }

  final visibleCopy = copy.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final match = _forbiddenCustomerCopy.firstMatch(visibleCopy);
  expect(
    match,
    isNull,
    reason:
        'Forbidden customer-facing wording "${match?.group(0)}" found in '
        '$rootKey. Visible copy: $visibleCopy',
  );
  expect(tester.takeException(), isNull);
}

Future<JourneySession> _signedOutSession({
  OtpGateway? otpGateway,
  EmailOtpGateway? emailOtpGateway,
  SocialAuthGateway? socialAuthGateway,
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

class _PendingAreaGateway implements CurrentAreaGateway {
  final _result = Completer<ResolvedCurrentArea>();

  void complete(ResolvedCurrentArea area) => _result.complete(area);

  @override
  Future<ResolvedCurrentArea> resolve({bool requestPermission = true}) {
    return _result.future;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationServicesSettings() async {}
}
