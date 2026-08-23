import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    JourneySession session, {
    String initialLocation = '/sign-in',
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: initialLocation),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('foreground link completes once and opens exact destination', (
    tester,
  ) async {
    final gateway = ReviewEmailLinkGateway();
    final bootstrap = ReviewAccountBootstrapGateway();
    final session = JourneySession(
      store: _completedStore('/app/social?sub=create'),
      emailLinkGateway: gateway,
      emailLinkAvailable: true,
      accountBootstrapGateway: bootstrap,
    );
    addTearDown(session.dispose);
    await session.start();
    expect(await session.requestEmailLink('person@example.com'), isTrue);
    await mount(tester, session);

    await tester.binding.handlePushRoute(gateway.acceptedLink);
    await tester.pumpAndSettle();

    expect(session.isAuthenticated, isTrue);
    expect(session.stage, JourneyStage.ready);
    final frameworkException = tester.takeException();
    expect(frameworkException, isNull);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = materialApp.routerConfig! as GoRouter;
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/app/social?sub=create',
    );
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/app/social?sub=create',
    );
    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsOneWidget,
    );
    expect(session.readyRoute(), '/app/social');
    expect(gateway.completionCount, 1);
    expect(bootstrap.prepareCount, 1);

    await tester.binding.handlePushRoute(gateway.acceptedLink);
    await tester.pumpAndSettle();
    expect(gateway.completionCount, 1);
    expect(bootstrap.prepareCount, 1);
  });

  testWidgets('foreground process return asks for the same email', (
    tester,
  ) async {
    final store = _completedStore('/app/chat/inbox?return=/app/social');
    final gateway = ReviewEmailLinkGateway();
    final sender = JourneySession(
      store: store,
      emailLinkGateway: gateway,
      emailLinkAvailable: true,
    );
    await sender.start();
    expect(await sender.requestEmailLink('person@example.com'), isTrue);
    sender.dispose();

    final returned = JourneySession(
      store: store,
      emailLinkGateway: gateway,
      emailLinkAvailable: true,
    );
    addTearDown(returned.dispose);
    await returned.start();
    await mount(tester, returned);

    await tester.binding.handlePushRoute(gateway.acceptedLink);
    await tester.pumpAndSettle();

    expect(returned.isAuthenticated, isFalse);
    expect(returned.emailLinkState, EmailLinkState.awaitingEmail);
    expect(find.text('Confirm your email'), findsOneWidget);
    expect(find.byKey(const Key('email-link-confirm-field')), findsOneWidget);
  });

  testWidgets('unrecognized route never reaches email-link completion', (
    tester,
  ) async {
    final gateway = ReviewEmailLinkGateway();
    final bootstrap = ReviewAccountBootstrapGateway();
    final session = JourneySession(
      store: _completedStore('/app/social?sub=feed'),
      emailLinkGateway: gateway,
      emailLinkAvailable: true,
      accountBootstrapGateway: bootstrap,
    );
    addTearDown(session.dispose);
    await session.start();
    await mount(tester, session);

    await tester.binding.handlePushRoute('/not-an-email-link');
    await tester.pumpAndSettle();

    expect(session.isAuthenticated, isFalse);
    expect(session.emailLinkState, EmailLinkState.idle);
    expect(gateway.completionCount, 0);
    expect(bootstrap.prepareCount, 0);
  });
}

MemoryJourneyStore _completedStore(String pendingRoute) {
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
