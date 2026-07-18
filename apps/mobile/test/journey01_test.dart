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
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  Future<void> reachSignIn(
    WidgetTester tester,
    JourneySession session, {
    String initialLocation = '/boot',
  }) async {
    await openApp(tester, session, initialLocation: initialLocation);
    await tapVisible(tester, const Key('area-skip'));
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

  testWidgets('clean install offers the approved manual area path', (
    tester,
  ) async {
    final location = ReviewLocationPermissionGateway();
    final session = JourneySession(locationGateway: location);
    addTearDown(session.dispose);

    await openApp(tester, session);
    expect(find.text('Almost ready'), findsOneWidget);
    expect(find.text('Set your area'), findsOneWidget);

    await tapVisible(tester, const Key('area-manual'));
    await tester.enterText(find.byKey(const Key('manual-area-field')), '');
    await tapVisible(tester, const Key('continue-to-sign-in'));
    expect(find.text('Enter at least 3 characters for your area.'), findsOne);

    await tester.enterText(
      find.byKey(const Key('manual-area-field')),
      'Sardarpura',
    );
    await tapVisible(tester, const Key('continue-to-sign-in'));
    expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
    expect(location.requestCount, 0);
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
    expect(find.text('Almost ready'), findsOneWidget);
    expect(find.byKey(const Key('area-current')), findsOneWidget);
  });

  testWidgets('language selection is visible and retained through setup', (
    tester,
  ) async {
    final store = MemoryJourneyStore();
    final session = JourneySession(store: store);
    addTearDown(session.dispose);

    await openApp(tester, session);
    await tapVisible(tester, const Key('language-hi'));
    expect(session.languageCode, 'hi');
    await tapVisible(tester, const Key('area-skip'));
    expect(store.snapshot?.languageCode, 'hi');
    expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
    expect(find.byKey(const Key('email-otp-method')), findsNothing);
    expect(find.text('Google'), findsNothing);
  });

  testWidgets(
    'location denial is recoverable and skip requests no permission',
    (tester) async {
      final location = ReviewLocationPermissionGateway(
        result: LocationPermissionResult.denied,
      );
      final session = JourneySession(locationGateway: location);
      addTearDown(session.dispose);

      await openApp(tester, session);
      await tapVisible(tester, const Key('area-current'));
      expect(location.requestCount, 1);
      expect(find.byKey(const Key('setup-error')), findsOneWidget);
      expect(find.byKey(const Key('mobile-otp-method')), findsNothing);
      await tapVisible(tester, const Key('area-skip'));
      expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
    },
  );

  testWidgets('location failure recovers through a suggested manual area', (
    tester,
  ) async {
    final location = ReviewLocationPermissionGateway(
      failure: StateError('location unavailable'),
    );
    final session = JourneySession(locationGateway: location);
    addTearDown(session.dispose);

    await openApp(tester, session);
    await tapVisible(tester, const Key('area-current'));
    expect(
      find.text(
        'Your location could not be detected. Enter your area or skip for now.',
      ),
      findsOneWidget,
    );
    await tapVisible(tester, const Key('area-manual'));
    await tapVisible(tester, const Key('area-suggestion-sardarpura'));
    await tapVisible(tester, const Key('continue-to-sign-in'));
    expect(session.manualArea, 'Sardarpura');
    expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
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
    expect(session.areaChoice, AreaChoice.skipped);

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
    expect(session.areaChoice, AreaChoice.skipped);
  });

  testWidgets('protected deep link survives setup and sign-in', (tester) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await authenticate(tester, session, initialLocation: '/app/work');
    expect(find.byKey(const Key('section-work')), findsOneWidget);
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
    expect(find.text('Work'), findsWidgets);

    await tapVisible(tester, const Key('nav-mool'));
    expect(find.byKey(const Key('mool-action-buy')), findsOneWidget);
    await tapVisible(tester, const Key('close-mool'));
    expect(find.byKey(const Key('section-work')), findsOneWidget);
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
    expect(find.text('Message people you know'), findsOne);
    expect(find.text('Back to Buy'), findsOne);
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
    expect(session.areaChoice, AreaChoice.skipped);
    expect(auth.signedIn, isFalse);
  });
}
