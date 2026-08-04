import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'safe Buy destination restores and malformed routes fail closed',
    () async {
      for (final entry in const <String, String>{
        '/app/buy?sub=shop': '/app/buy?sub=shop',
        '/app/buy?sub=wholesale': '/app/buy?sub=wholesale',
        '/app/buy/medicine': '/app/buy?sub=medicine',
        '/app/buy/order/MS-240782': '/app/buy?sub=orders',
      }.entries) {
        final session = JourneySession(
          store: MemoryJourneyStore(
            snapshot: JourneySnapshot(
              languageCode: 'en',
              areaMode: 'manual',
              setupComplete: true,
              lastReadyRoute: entry.key,
            ),
          ),
          otpGateway: ReviewOtpGateway(signedIn: true),
        );
        await session.start();
        expect(session.readyRoute(), entry.value, reason: entry.key);
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
    'route confirmation persists safe state and Social owns Buy root exit',
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
      expect(session.buyExitRoute(), '/app/social?openMool=1');
      expect(
        session.buyExitRoute(requestedRoute: '/app/eat'),
        '/app/social?openMool=1',
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

  testWidgets(
    'root Back returns to Social through repeated real-router cycles',
    (tester) async {
      final session = await _mount(tester, initialLocation: '/app/social');
      addTearDown(session.dispose);

      for (var cycle = 0; cycle < 3; cycle += 1) {
        if (find.byKey(const Key('screen04-rail-buy')).evaluate().isEmpty) {
          await tester.tap(find.byKey(const Key('screen04-mool')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const Key('screen04-rail-buy')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
        expect(find.byKey(const Key('buy-v2-screen')), findsNothing);
      }
    },
  );

  testWidgets(
    'root Back ignores an Eat invoker and keeps Buy one tap from Social',
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
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.byKey(const Key('screen04-rail-buy')), findsOneWidget);
      expect(find.byKey(const Key('buy-v2-screen')), findsNothing);
    },
  );

  testWidgets(
    'stateful Eat world is replaced before Buy so root Back renders Social',
    (tester) async {
      final session = await _mount(tester, initialLocation: '/app/social');
      addTearDown(session.dispose);

      await tester.tap(find.byKey(const Key('screen04-mool')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('screen04-rail-eat')));
      await tester.pumpAndSettle();
      expect(find.text('Search restaurants, tiffin or tables'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-mool')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('screen04-rail-buy')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        find.byKey(const Key('screen04-shorts-page-view')),
        findsOneWidget,
      );
      expect(find.text('Search restaurants, tiffin or tables'), findsNothing);
      expect(find.byKey(const Key('screen04-rail-buy')), findsOneWidget);
    },
  );

  testWidgets(
    'catalogue vertical updates the route before a router refresh can persist it',
    (tester) async {
      final session = await _mount(tester, initialLocation: '/app/buy');
      addTearDown(session.dispose);

      await tester.tap(find.byKey(const Key('buy-dock-medicine')));
      await tester.pumpAndSettle();

      final router = GoRouter.of(
        tester.element(find.byKey(const Key('buy-v2-screen'))),
      );
      expect(router.routeInformationProvider.value.uri.path, '/app/buy');
      expect(
        router.routeInformationProvider.value.uri.queryParameters['sub'],
        'medicine',
      );

      expect(await session.updateLanguage('hi'), isTrue);
      await tester.pumpAndSettle();
      expect(session.readyRoute(), '/app/buy?sub=medicine');
      expect(find.text('Search medicines and wellness'), findsOneWidget);
    },
  );

  testWidgets('search and internal Buy state own Back before root exit', (
    tester,
  ) async {
    final session = await _mount(tester, initialLocation: '/app/social');
    addTearDown(session.dispose);
    await tester.tap(find.byKey(const Key('screen04-mool')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-rail-buy')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);

    await tester.tap(find.byKey(const Key('buy-open-account')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-account-hub')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byKey(const Key('buy-account-hub')), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
  });

  testWidgets('deliberate Social departure makes Buy a one-tap return', (
    tester,
  ) async {
    final session = await _mount(tester, initialLocation: '/app/buy');
    addTearDown(session.dispose);

    await tester.tap(find.byKey(const Key('buy-dock-mool')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy-mool-social')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(find.byKey(const Key('screen04-rail-buy')), findsOneWidget);
    await tester.tap(find.byKey(const Key('screen04-rail-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
  });

  testWidgets('stored Medicine route restores through the production router', (
    tester,
  ) async {
    final session = await _mount(
      tester,
      initialLocation: '/boot',
      lastReadyRoute: '/app/buy?sub=medicine',
    );
    addTearDown(session.dispose);

    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.text('Search medicines and wellness'), findsOneWidget);
  });

  testWidgets('internal destination changes update the persisted safe route', (
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
      (key: 'buy-dock-wholesale', route: '/app/buy?sub=wholesale'),
      (key: 'buy-dock-medicine', route: '/app/buy?sub=medicine'),
      (key: 'buy-dock-orders', route: '/app/buy?sub=orders'),
      (key: 'buy-dock-shop', route: '/app/buy?sub=shop'),
    ]) {
      await tester.tap(find.byKey(Key(entry.key)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(store.snapshot?.lastReadyRoute, entry.route);
    }
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
