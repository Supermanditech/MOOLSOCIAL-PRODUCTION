import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openApp(
    WidgetTester tester,
    JourneySession session, {
    String initialLocation = '/boot',
  }) async {
    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: initialLocation),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  Future<void> reachSignIn(
    WidgetTester tester,
    JourneySession session, {
    String initialLocation = '/boot',
  }) async {
    await openApp(tester, session, initialLocation: initialLocation);
    await tapVisible(tester, const Key('setup-v4-allow-location'));
    await tapVisible(tester, const Key('setup-v4-continue'));
  }

  Future<void> authenticate(
    WidgetTester tester,
    JourneySession session, {
    String initialLocation = '/boot',
  }) async {
    await reachSignIn(tester, session, initialLocation: initialLocation);
    await tapVisible(tester, const Key('mobile-otp-method'));
    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tapVisible(tester, const Key('send-otp'));
    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await tapVisible(tester, const Key('verify-otp'));
  }

  testWidgets('clean install asks before resolving the current area', (
    tester,
  ) async {
    final store = MemoryJourneyStore();
    final area = ReviewCurrentAreaGateway();
    final session = JourneySession(store: store, currentAreaGateway: area);
    addTearDown(session.dispose);

    await openApp(tester, session);
    expect(find.byKey(const Key('screen02-v4')), findsOneWidget);
    expect(find.text('See what’s around you'), findsOneWidget);
    expect(area.resolveCount, 0);

    await tapVisible(tester, const Key('setup-v4-allow-location'));
    expect(find.text('You’re in Sardarpura'), findsOneWidget);
    expect(area.resolveCount, 1);

    await tapVisible(tester, const Key('setup-v4-continue'));
    expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
    expect(session.currentAreaLabel, 'Sardarpura, Jodhpur, Rajasthan');
    expect(store.snapshot?.currentAreaLabel, session.currentAreaLabel);
  });

  testWidgets('boot failure exact retry returns to the safe setup screen', (
    tester,
  ) async {
    final store = MemoryJourneyStore(readFailure: StateError('read failed'));
    final session = JourneySession(store: store);
    addTearDown(session.dispose);

    await openApp(tester, session);
    expect(find.byKey(const Key('boot-error')), findsOneWidget);
    store.readFailure = null;
    await tapVisible(tester, const Key('retry-boot'));
    expect(find.byKey(const Key('screen02-v4')), findsOneWidget);
    expect(find.byKey(const Key('setup-v4-allow-location')), findsOneWidget);
  });

  testWidgets('phone language is summarized and retained through setup', (
    tester,
  ) async {
    final store = MemoryJourneyStore();
    final session = JourneySession(store: store);
    addTearDown(session.dispose);

    await openApp(tester, session);
    expect(find.byKey(const Key('setup-v4-language-summary')), findsOneWidget);
    expect(find.byKey(const Key('language-hi')), findsNothing);
    expect(find.byKey(const Key('language-en')), findsNothing);
    expect(session.languageCode, 'en');
    await tapVisible(tester, const Key('setup-v4-continue-for-now'));
    expect(store.snapshot?.languageCode, 'en');
    expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
    expect(find.byKey(const Key('email-otp-method')), findsOneWidget);
    for (final provider in const [
      'Google',
      'YouTube',
      'Apple',
      'X',
      'Instagram',
      'Facebook',
    ]) {
      expect(find.text(provider), findsOneWidget);
    }
  });

  testWidgets('unavailable current area can continue without branching', (
    tester,
  ) async {
    final area = ReviewCurrentAreaGateway(
      failureReason: CurrentAreaFailureReason.unavailable,
    );
    final session = JourneySession(currentAreaGateway: area);
    addTearDown(session.dispose);

    await openApp(tester, session);
    expect(area.resolveCount, 0);
    await tapVisible(tester, const Key('setup-v4-allow-location'));
    expect(area.resolveCount, 1);
    expect(find.text('We couldn’t get your location'), findsOneWidget);
    expect(find.byKey(const Key('mobile-otp-method')), findsNothing);
    await tapVisible(tester, const Key('setup-v4-continue-for-now'));
    expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
    expect(session.areaChoice, AreaChoice.skipped);
  });

  testWidgets('area failure retries without exposing a pre-login area form', (
    tester,
  ) async {
    final area = ReviewCurrentAreaGateway(
      failureReason: CurrentAreaFailureReason.unavailable,
    );
    final session = JourneySession(currentAreaGateway: area);
    addTearDown(session.dispose);

    await openApp(tester, session);
    await tapVisible(tester, const Key('setup-v4-allow-location'));
    expect(find.text('We couldn’t get your location'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    area.failureReason = null;
    await tapVisible(tester, const Key('setup-v4-retry'));
    expect(find.text('You’re in Sardarpura'), findsOneWidget);
    expect(area.resolveCount, 2);
  });

  testWidgets('invalid mobile and OTP remain recoverable', (tester) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await reachSignIn(tester, session);
    await tapVisible(tester, const Key('mobile-otp-method'));
    await tester.enterText(find.byKey(const Key('phone-field')), '123');
    await tapVisible(tester, const Key('send-otp'));
    expect(find.byKey(const Key('sign-in-error')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tapVisible(tester, const Key('send-otp'));
    await tester.enterText(find.byKey(const Key('otp-field')), '000000');
    await tapVisible(tester, const Key('verify-otp'));
    expect(find.byKey(const Key('otp-error')), findsOneWidget);
    expect(session.stage, JourneyStage.verify);

    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await tapVisible(tester, const Key('verify-otp'));
    expect(find.byKey(const Key('universal-navigation')), findsOneWidget);
  });

  testWidgets('request failure retains state and exact retry succeeds', (
    tester,
  ) async {
    final auth = ReviewOtpGateway(
      requestFailure: const JourneyServiceException(
        'You appear to be offline. Reconnect and retry.',
      ),
    );
    final session = JourneySession(otpGateway: auth);
    addTearDown(session.dispose);

    await reachSignIn(tester, session);
    await tapVisible(tester, const Key('mobile-otp-method'));
    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tapVisible(tester, const Key('send-otp'));
    expect(
      find.text('You appear to be offline. Reconnect and retry.'),
      findsOne,
    );
    expect(session.areaChoice, AreaChoice.current);

    auth.requestFailure = null;
    await tapVisible(tester, const Key('send-otp'));
    expect(find.byKey(const Key('otp-field')), findsOneWidget);
    expect(auth.requestCount, 2);
  });

  testWidgets('change mobile cancels verification without losing setup', (
    tester,
  ) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await reachSignIn(tester, session);
    await tapVisible(tester, const Key('mobile-otp-method'));
    await tester.enterText(find.byKey(const Key('phone-field')), '9876543210');
    await tapVisible(tester, const Key('send-otp'));
    await tapVisible(tester, const Key('change-method'));

    expect(find.text('Sign in'), findsOneWidget);
    expect(session.areaChoice, AreaChoice.current);
  });

  testWidgets('protected deep link survives setup and sign-in', (tester) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await authenticate(tester, session, initialLocation: '/app/work');
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    expect(session.returnTo, isNull);
  });

  testWidgets('Mool returns to the previously focused primary section', (
    tester,
  ) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await authenticate(tester, session);
    await tapVisible(tester, const Key('nav-mool'));
    await tapVisible(tester, const Key('mool-action-work'));
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);

    await tapVisible(tester, const Key('work-dock-mool'));
    expect(find.byKey(const Key('mool-action-buy')), findsOneWidget);
    await tapVisible(tester, const Key('close-mool'));
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
  });

  testWidgets('universal screen visible controls complete their tap intents', (
    tester,
  ) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await authenticate(tester, session);

    expect(
      tester.getSemantics(find.byKey(const Key('open-profile'))),
      matchesSemantics(
        label: 'Open your account',
        isButton: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    await tapVisible(tester, const Key('open-profile'));
    expect(find.text('Your account'), findsOneWidget);
    await tapVisible(tester, const Key('close-profile'));

    await tapVisible(tester, const Key('open-search'));
    await tester.enterText(find.byKey(const Key('search-field')), 'ride');
    await tester.pumpAndSettle();
    await tapVisible(tester, const Key('search-result-ride'));
    expect(find.text('Book a bike ride'), findsOne);

    await tapVisible(tester, const Key('nav-mool'));
    await tapVisible(tester, const Key('mool-action-social'));
    await tapVisible(tester, const Key('social-tab-shorts'));
    expect(find.text('Short videos start instantly'), findsOneWidget);
    await tapVisible(tester, const Key('nav-mool'));
    await tapVisible(tester, const Key('mool-action-buy'));
    expect(find.text('Groceries delivered to your home'), findsOne);

    await tapVisible(tester, const Key('nav-chat'));
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    await tapVisible(tester, const Key('chat-back'));
    expect(find.byKey(const Key('section-buy')), findsOneWidget);
  });

  testWidgets('sign-out cancellation and confirmation are explicit', (
    tester,
  ) async {
    final auth = ReviewOtpGateway();
    final session = JourneySession(otpGateway: auth);
    addTearDown(session.dispose);

    await authenticate(tester, session);
    await tapVisible(tester, const Key('open-profile'));
    await tapVisible(tester, const Key('sign-out'));
    await tapVisible(tester, const Key('cancel-sign-out'));
    expect(session.isReady, isTrue);

    await tapVisible(tester, const Key('open-profile'));
    await tapVisible(tester, const Key('sign-out'));
    await tapVisible(tester, const Key('confirm-sign-out'));
    expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
    expect(session.areaChoice, AreaChoice.current);
    expect(auth.signedIn, isFalse);
  });
}
