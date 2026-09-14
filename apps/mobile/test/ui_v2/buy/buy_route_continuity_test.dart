import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapHomeTarget(WidgetTester tester, Key key) async {
    final target = find.byKey(key);
    expect(target, findsOneWidget, reason: 'Missing Home target $key');
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> tapNavigatorTarget(WidgetTester tester, Key key) async {
    final target = find.byKey(key);
    expect(target, findsOneWidget, reason: 'Missing navigator target $key');
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  test(
    'persisted Buy destinations never replace the Social cold-launch owner',
    () async {
      for (final route in const [
        '/app/buy?sub=shop',
        '/app/buy?sub=wholesale',
        '/app/buy/medicine',
        '/app/buy/order/MS-240782',
      ]) {
        final session = JourneySession(
          store: MemoryJourneyStore(
            snapshot: JourneySnapshot(
              languageCode: 'en',
              areaMode: 'manual',
              setupComplete: true,
              lastReadyRoute: route,
            ),
          ),
          otpGateway: ReviewOtpGateway(signedIn: true),
        );
        await session.start();
        expect(session.readyRoute(), '/app/social', reason: route);
        session.dispose();
      }

      for (final route in const [
        'https://example.com/app/buy',
        '/app/buy/unknown',
        '/app/../buy',
        '/sign-in',
      ]) {
        final session = JourneySession(
          store: MemoryJourneyStore(
            snapshot: JourneySnapshot(
              languageCode: 'en',
              areaMode: 'manual',
              setupComplete: true,
              lastReadyRoute: route,
            ),
          ),
          otpGateway: ReviewOtpGateway(signedIn: true),
        );
        await session.start();
        expect(session.readyRoute(), '/app/social', reason: route);
        session.dispose();
      }
    },
  );

  test(
    'route confirmation persists safe state and Mool owns Buy root exit',
    () async {
      final store = MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          setupComplete: true,
        ),
      );
      final session = JourneySession(
        store: store,
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(session.dispose);
      await session.start();

      session.confirmReadyRoute('/app/eat');
      session.confirmReadyRoute('/app/buy?sub=medicine');
      await Future<void>.delayed(Duration.zero);

      expect(store.snapshot?.lastReadyRoute, '/app/buy?sub=medicine');
      expect(session.buyExitRoute(), '/app/mool?from=buy');
      expect(
        session.buyExitRoute(requestedRoute: '/app/eat'),
        '/app/mool?from=buy',
      );
    },
  );

  test(
    'route snapshots persist in invocation order and latest route wins',
    () async {
      final store = _SerialProbeJourneyStore(blockFirstWrite: true);
      final session = JourneySession(store: store);
      addTearDown(session.dispose);

      session.confirmReadyRoute('/app/buy?sub=shop');
      await store.firstWriteStarted.future;
      session.confirmReadyRoute('/app/buy?sub=wholesale');
      await Future<void>.delayed(Duration.zero);

      expect(store.startedRoutes, ['/app/buy?sub=shop']);

      store.releaseFirstWrite.complete();
      await store.twoWritesCompleted.future.timeout(const Duration(seconds: 1));

      expect(store.maximumConcurrentWrites, 1);
      expect(store.startedRoutes, [
        '/app/buy?sub=shop',
        '/app/buy?sub=wholesale',
      ]);
      expect(store.snapshot?.lastReadyRoute, '/app/buy?sub=wholesale');
    },
  );

  test(
    'a failed snapshot does not poison the next persistence operation',
    () async {
      final store = _SerialProbeJourneyStore(failFirstWrite: true);
      final session = JourneySession(store: store);
      addTearDown(session.dispose);

      expect(await session.updateLanguage('hi'), isFalse);
      expect(await session.updateLanguage('hi'), isTrue);
      expect(store.maximumConcurrentWrites, 1);
      expect(store.snapshot?.languageCode, 'hi');
    },
  );

  testWidgets('root Back returns to Mool through repeated real-router cycles', (
    tester,
  ) async {
    final session = await _mount(tester, initialLocation: '/app/mool');
    addTearDown(session.dispose);

    for (var cycle = 0; cycle < 3; cycle += 1) {
      await tapHomeTarget(tester, const Key('mool-home-family-buy'));
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
      expect(find.byKey(const Key('buy-v2-screen')), findsNothing);
    }
  });

  testWidgets(
    'root Back ignores an invalid Eat return and falls back to Mool',
    (tester) async {
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Sardarpura',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(session.dispose);
      await session.start();
      session.confirmReadyRoute('/app/eat');

      await tester.pumpWidget(
        MoolSocialApp(
          session: session,
          initialLocation: '/app/buy?return=%2Fapp%2Feat',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
      expect(find.byKey(const Key('screen04-universal-v2')), findsNothing);
      expect(find.byKey(const Key('buy-v2-screen')), findsNothing);
    },
  );

  testWidgets(
    'connected targets restore prior Social without an intermediate Home',
    (tester) async {
      final session = await _mount(tester, initialLocation: '/app/social');
      addTearDown(session.dispose);

      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      await tapNavigatorTarget(tester, const Key('mool-navigator-family-eat'));
      expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
      expect(find.byKey(const Key('eat-local-order')), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(find.byKey(const Key('mvp-action-root-eat')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);

      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      await tapNavigatorTarget(tester, const Key('mool-navigator-family-buy'));
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
    },
  );

  testWidgets(
    'visible Buy route retains its exact subaction across router refresh',
    (tester) async {
      final session = await _mount(tester, initialLocation: '/app/buy');
      addTearDown(session.dispose);

      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      await tapNavigatorTarget(tester, const Key('mool-navigator-family-book'));
      await tester.tap(find.byKey(const Key('care-local-medicine')));
      await tester.pumpAndSettle();

      var visibleState = GoRouterState.of(
        tester.element(find.byKey(const Key('buy-v2-screen'))),
      );
      expect(visibleState.uri.path, '/app/buy');
      expect(visibleState.uri.queryParameters['sub'], 'medicine');

      expect(await session.updateLanguage('hi'), isTrue);
      await tester.pumpAndSettle();
      expect(session.readyRoute(), '/app/social');
      visibleState = GoRouterState.of(
        tester.element(find.byKey(const Key('buy-v2-screen'))),
      );
      expect(visibleState.uri.path, '/app/buy');
      expect(visibleState.uri.queryParameters['sub'], 'medicine');
      expect(find.text('Search medicines'), findsOneWidget);
    },
  );

  testWidgets('search and internal Buy state own Back before root exit', (
    tester,
  ) async {
    final session = await _mount(tester, initialLocation: '/app/mool');
    addTearDown(session.dispose);
    await tapHomeTarget(tester, const Key('mool-home-family-buy'));

    await tester.tap(find.byKey(const Key('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
  });

  testWidgets('Buy MoolSocial chooser Back preserves Medicine in place', (
    tester,
  ) async {
    final session = await _mount(
      tester,
      initialLocation: '/app/buy?sub=medicine',
    );
    addTearDown(session.dispose);
    expect(find.text('Search medicines'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('screen04-universal-v2')), findsNothing);
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
    expect(find.text('Search medicines'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.text('Search medicines'), findsOneWidget);
  });

  testWidgets('stored Medicine route cannot replace Social cold launch', (
    tester,
  ) async {
    final session = await _mount(
      tester,
      initialLocation: '/boot',
      lastReadyRoute: '/app/buy?sub=medicine',
    );
    addTearDown(session.dispose);

    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(find.byKey(const Key('buy-v2-screen')), findsNothing);
  });

  testWidgets('Buy destination owner updates the persisted safe route', (
    tester,
  ) async {
    final store = MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'manual',
        areaLabel: 'Sardarpura',
        setupComplete: true,
      ),
    );
    final session = JourneySession(
      store: store,
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final core = BuySession();
    final buy = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(buy.dispose);
    addTearDown(core.dispose);
    await session.start();
    await tester.pumpWidget(
      MaterialApp(
        home: BuyV2Screen(
          session: buy,
          onDestinationChanged: (destination) {
            session.confirmReadyRoute('/app/buy?sub=${destination.name}');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final entry in const [
      (
        destination: BuyV2Destination.wholesale,
        route: '/app/buy?sub=wholesale',
      ),
      (destination: BuyV2Destination.medicine, route: '/app/buy?sub=medicine'),
      (destination: BuyV2Destination.orders, route: '/app/buy?sub=orders'),
      (destination: BuyV2Destination.shop, route: '/app/buy?sub=shop'),
    ]) {
      buy.openDestination(entry.destination);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(store.snapshot?.lastReadyRoute, entry.route);
    }
    expect(find.byKey(const Key('buy-local-tab-wholesale')), findsOneWidget);
    expect(find.byKey(const Key('buy-local-tab-medicine')), findsNothing);
  });
}

Future<JourneySession> _mount(
  WidgetTester tester, {
  required String initialLocation,
  String? lastReadyRoute,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  final session = JourneySession(
    store: MemoryJourneyStore(
      snapshot: JourneySnapshot(
        languageCode: 'en',
        areaMode: 'manual',
        areaLabel: 'Sardarpura',
        setupComplete: true,
        lastReadyRoute: lastReadyRoute,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );
  await session.start();
  await tester.pumpWidget(
    MoolSocialApp(session: session, initialLocation: initialLocation),
  );
  if (initialLocation == '/boot') {
    await tester.pump(const Duration(seconds: 3));
  }
  await tester.pumpAndSettle();
  return session;
}

class _SerialProbeJourneyStore implements JourneyStore {
  _SerialProbeJourneyStore({
    this.blockFirstWrite = false,
    this.failFirstWrite = false,
  });

  final bool blockFirstWrite;
  final bool failFirstWrite;
  final Completer<void> firstWriteStarted = Completer<void>();
  final Completer<void> releaseFirstWrite = Completer<void>();
  final Completer<void> twoWritesCompleted = Completer<void>();
  final List<String?> startedRoutes = <String?>[];

  JourneySnapshot? snapshot;
  int activeWrites = 0;
  int completedWrites = 0;
  int maximumConcurrentWrites = 0;

  @override
  Future<JourneySnapshot?> read() async => snapshot;

  @override
  Future<void> write(JourneySnapshot value) async {
    final writeIndex = startedRoutes.length;
    startedRoutes.add(value.lastReadyRoute);
    activeWrites += 1;
    if (activeWrites > maximumConcurrentWrites) {
      maximumConcurrentWrites = activeWrites;
    }
    if (writeIndex == 0 && !firstWriteStarted.isCompleted) {
      firstWriteStarted.complete();
    }

    try {
      if (writeIndex == 0 && blockFirstWrite) {
        await releaseFirstWrite.future;
      }
      if (writeIndex == 0 && failFirstWrite) {
        throw StateError('controlled first write failure');
      }
      snapshot = value;
    } finally {
      activeWrites -= 1;
      completedWrites += 1;
      if (completedWrites == 2 && !twoWritesCompleted.isCompleted) {
        twoWritesCompleted.complete();
      }
    }
  }
}
