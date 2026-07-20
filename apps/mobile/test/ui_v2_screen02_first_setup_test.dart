import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/screens/screen02_first_setup/first_setup_screen_v2.dart';

void main() {
  Future<void> mountScreen(WidgetTester tester, JourneySession session) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        home: FirstSetupScreenV2(session: session),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('consent appears before any phone location request', (
    tester,
  ) async {
    final area = ReviewCurrentAreaGateway();
    final session = JourneySession(currentAreaGateway: area);
    addTearDown(session.dispose);
    await session.start();

    await mountScreen(tester, session);

    expect(find.byKey(const Key('screen02-v4')), findsOneWidget);
    expect(find.text('See what’s around you'), findsOneWidget);
    expect(find.byKey(const Key('setup-v4-allow-location')), findsOneWidget);
    expect(find.byKey(const Key('setup-v4-language-summary')), findsOneWidget);
    expect(area.resolveCount, 0);
    expect(find.textContaining('Where do you usually'), findsNothing);
    expect(find.textContaining('home or work'), findsNothing);
    expect(find.textContaining('Choose my city'), findsNothing);
    expect(find.byKey(const Key('otp-field')), findsNothing);
  });

  testWidgets('consent resolves the current location name then continues', (
    tester,
  ) async {
    final store = MemoryJourneyStore();
    final area = ReviewCurrentAreaGateway();
    final session = JourneySession(store: store, currentAreaGateway: area);
    addTearDown(session.dispose);
    await session.start();
    await mountScreen(tester, session);

    await tap(tester, const Key('setup-v4-allow-location'));

    expect(area.resolveCount, 1);
    expect(find.text('You’re in Sardarpura'), findsOneWidget);
    expect(find.text('Jodhpur, Rajasthan'), findsOneWidget);
    expect(find.byKey(const Key('setup-v4-continue')), findsOneWidget);

    await tap(tester, const Key('setup-v4-continue'));

    expect(session.stage, JourneyStage.signIn);
    expect(store.snapshot?.currentAreaLabel, 'Sardarpura, Jodhpur, Rajasthan');
  });

  testWidgets('Location Services off opens phone settings and rechecks', (
    tester,
  ) async {
    final area = ReviewCurrentAreaGateway(
      failureReason: CurrentAreaFailureReason.locationServicesOff,
    );
    final session = JourneySession(currentAreaGateway: area);
    addTearDown(session.dispose);
    await session.start();
    await mountScreen(tester, session);

    await tap(tester, const Key('setup-v4-allow-location'));

    expect(find.text('Turn on Location Services'), findsOneWidget);
    expect(
      find.byKey(const Key('setup-v4-open-location-settings')),
      findsOneWidget,
    );

    await tap(tester, const Key('setup-v4-open-location-settings'));
    expect(area.openLocationServicesSettingsCount, 1);

    area.failureReason = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(area.resolveCount, 2);
    expect(area.requestPermissionHistory, <bool>[true, false]);
    expect(find.text('You’re in Sardarpura'), findsOneWidget);
  });

  testWidgets('permission not allowed opens app settings', (tester) async {
    final area = ReviewCurrentAreaGateway(
      failureReason: CurrentAreaFailureReason.permissionPermanentlyNotAllowed,
    );
    final session = JourneySession(currentAreaGateway: area);
    addTearDown(session.dispose);
    await session.start();
    await mountScreen(tester, session);

    await tap(tester, const Key('setup-v4-allow-location'));

    expect(find.text('Allow location in phone settings'), findsOneWidget);
    await tap(tester, const Key('setup-v4-open-app-settings'));
    expect(area.openAppSettingsCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(area.resolveCount, 2);
    expect(area.requestPermissionHistory, <bool>[true, false]);
    expect(find.text('Allow location in phone settings'), findsOneWidget);
  });

  testWidgets('continue for now keeps the path clean and reaches sign-in', (
    tester,
  ) async {
    final store = MemoryJourneyStore();
    final area = ReviewCurrentAreaGateway();
    final session = JourneySession(store: store, currentAreaGateway: area);
    addTearDown(session.dispose);
    await session.start();
    await mountScreen(tester, session);

    await tap(tester, const Key('setup-v4-continue-for-now'));

    expect(area.resolveCount, 0);
    expect(session.areaChoice, AreaChoice.skipped);
    expect(session.stage, JourneyStage.signIn);
    expect(store.snapshot?.currentAreaLabel, isNull);
  });

  testWidgets('customer viewport excludes internal working language', (
    tester,
  ) async {
    final session = JourneySession();
    addTearDown(session.dispose);
    await session.start();
    await mountScreen(tester, session);

    final visibleCopy = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('screen02-v4')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data ?? '')
        .join(' ');
    expect(
      RegExp(
        r'\b(production|prototype|review|sample|working note|internal plan|'
        r'owner|route|workflow|implementation|provider|fallback|test|'
        r'next screen|detect my current)\b',
        caseSensitive: false,
      ).hasMatch(visibleCopy),
      isFalse,
    );
  });

  testWidgets('verify route is blocked until Screen 02 completes', (
    tester,
  ) async {
    final session = JourneySession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/verify'),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen02-v4')), findsOneWidget);
    expect(find.byKey(const Key('otp-field')), findsNothing);
  });
}
