import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  Future<void> openSetup(WidgetTester tester, JourneySession session) async {
    await tester.pumpWidget(MoolSocialApp(session: session));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Future<void> reachSignIn(WidgetTester tester, JourneySession session) async {
    await openSetup(tester, session);
    await tapVisible(tester, const Key('area-skip'));
    await tapVisible(tester, const Key('continue-to-sign-in'));
    await tester.pumpAndSettle();
  }

  testWidgets('clean install reaches setup and requires an area decision', (
    tester,
  ) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await openSetup(tester, session);
    expect(find.text('Make MoolSocial useful where you are'), findsOneWidget);

    await tapVisible(tester, const Key('continue-to-sign-in'));
    await tester.pump();

    expect(find.byKey(const Key('setup-error')), findsOneWidget);
    expect(session.stage, JourneyStage.setup);
  });

  testWidgets('invalid mobile and OTP remain recoverable', (tester) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await reachSignIn(tester, session);
    await tester.enterText(find.byKey(const Key('phone-field')), '123');
    await tapVisible(tester, const Key('send-otp'));
    await tester.pump();
    expect(find.byKey(const Key('sign-in-error')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tapVisible(tester, const Key('send-otp'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('otp-field')), '000000');
    await tapVisible(tester, const Key('verify-otp'));
    await tester.pump();
    expect(find.byKey(const Key('otp-error')), findsOneWidget);
    expect(session.stage, JourneyStage.verify);
  });

  testWidgets('successful OTP opens Social and Mool stays one tap away', (
    tester,
  ) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await reachSignIn(tester, session);
    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tapVisible(tester, const Key('send-otp'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await tapVisible(tester, const Key('verify-otp'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your people, local life and useful actions—together.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('nav-mool')));
    await tester.pumpAndSettle();
    expect(find.text('What do you want to get done?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-action-buy')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Buy is connected'), findsOneWidget);
  });

  testWidgets('change method returns from OTP without losing setup', (
    tester,
  ) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await reachSignIn(tester, session);
    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tapVisible(tester, const Key('send-otp'));
    await tester.pumpAndSettle();
    await tapVisible(tester, const Key('change-method'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sign in once. Use every MoolSocial service.'),
      findsOneWidget,
    );
    expect(session.areaChoice, AreaChoice.skipped);
  });
}
