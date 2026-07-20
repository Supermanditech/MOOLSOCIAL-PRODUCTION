import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/login_screen_v2.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/otp_screen_v2.dart';

void main() {
  Future<JourneySession> signInSession() async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'current',
          currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
          setupComplete: true,
        ),
      ),
    );
    await session.start();
    return session;
  }

  Future<void> mount(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Screen 03 login candidate at 360x720', (tester) async {
    final session = await signInSession();
    addTearDown(session.dispose);
    await mount(tester, LoginScreenV2(session: session));

    await expectLater(
      find.byKey(const Key('screen03-login-v2')),
      matchesGoldenFile('goldens/ui_v2_screen03_login-360x720.png'),
    );
  });

  testWidgets('Screen 03 mobile OTP candidate at 360x720', (tester) async {
    final session = await signInSession();
    addTearDown(session.dispose);
    expect(await session.requestOtp('9876543210'), isTrue);
    await mount(tester, OtpScreenV2(session: session));

    await expectLater(
      find.byKey(const Key('screen03-otp-v2')),
      matchesGoldenFile('goldens/ui_v2_screen03_mobile-otp-360x720.png'),
    );
  });

  testWidgets('Screen 03 email OTP candidate at 360x720', (tester) async {
    final session = await signInSession();
    addTearDown(session.dispose);
    expect(await session.requestEmailOtp('member@moolsocial.in'), isTrue);
    await mount(tester, OtpScreenV2(session: session));

    await expectLater(
      find.byKey(const Key('screen03-otp-v2')),
      matchesGoldenFile('goldens/ui_v2_screen03_email-otp-360x720.png'),
    );
  });
}
