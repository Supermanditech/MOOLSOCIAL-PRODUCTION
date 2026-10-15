import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Isolated host tracking/owner fixtures; never actual orders or location data.
  (
    BuyV2Session,
    _LiveDeliveryAdapter,
    _Lf11OwnerStore,
    ValueNotifier<BuyV2CollectionIdentity?>,
  )
  lf11Fixture({bool manualDispose = false}) {
    final owner = _Lf11OwnerStore();
    final identity = ValueNotifier<BuyV2CollectionIdentity?>(
      const BuyV2CollectionIdentity(
        accountId: 'lf11-a',
        sessionId: 'lf11-session-a',
      ),
    );
    final core = BuySession();
    final adapter = _LiveDeliveryAdapter();
    final session = BuyV2Session(
      core: core,
      liveDeliveryAdapter: adapter,
      customerStateStore: owner,
      collectionIdentity: identity,
    );
    addTearDown(core.dispose);
    addTearDown(identity.dispose);
    if (!manualDispose) addTearDown(session.dispose);
    return (session, adapter, owner, identity);
  }

  for (final drift in ['owner', 'auth', 'dispose']) {
    for (final fails in [false, true]) {
      test('LF11 tracking $drift late failure $fails stays isolated', () async {
        final (session, adapter, owner, identity) = lf11Fixture(
          manualDispose: drift == 'dispose',
        );
        final pending = adapter.pending =
            Completer<BuyV2LiveDeliverySnapshot>();
        final request = session.refreshLiveDelivery('PO-240783');
        expect(adapter.loadCalls, 1);
        switch (drift) {
          case 'owner':
            owner.scope = 'lf11-owner-b';
          case 'auth':
            identity.value = const BuyV2CollectionIdentity(
              accountId: 'lf11-b',
              sessionId: 'lf11-session-b',
            );
          case 'dispose':
            session.dispose();
        }
        if (fails) {
          pending.completeError(StateError('isolated lost read'));
        } else {
          pending.complete(adapter.readySnapshot('PO-240783'));
        }
        expect(await request, isFalse);
        expect(session.liveDeliveryFor('PO-240783'), isNull);
        expect(session.liveDeliveryRefreshMessage('PO-240783'), isNull);
        expect(session.liveDeliveryBusy('PO-240783'), isFalse);
      });
    }
  }
  for (final drift in ['owner', 'auth']) {
    test('LF11 cached tracking disappears on $drift change', () async {
      final (session, _, owner, identity) = lf11Fixture();
      expect(await session.refreshLiveDelivery('PO-240783'), isTrue);
      expect(session.liveDeliveryFor('PO-240783')!.driverName, isNotNull);
      if (drift == 'owner') {
        owner.scope = 'lf11-owner-b';
      } else {
        identity.value = const BuyV2CollectionIdentity(
          accountId: 'lf11-b',
          sessionId: 'lf11-session-b',
        );
      }
      expect(session.liveDeliveryFor('PO-240783'), isNull);
      expect(session.liveDeliveryRefreshMessage('PO-240783'), isNull);
    });
  }
  test(
    'LF11 owner is rechecked after notification before tracking read',
    () async {
      final (session, adapter, owner, _) = lf11Fixture();
      session.addListener(() => owner.scope = 'lf11-owner-b');
      expect(await session.refreshLiveDelivery('PO-240783'), isFalse);
      expect(adapter.loadCalls, 0);
    },
  );
  test('LF11 old finally cannot clear next-owner tracking operation', () async {
    final (session, adapter, owner, _) = lf11Fixture();
    final first = adapter.pending = Completer<BuyV2LiveDeliverySnapshot>();
    final old = session.refreshLiveDelivery('PO-240783');
    owner.scope = 'lf11-owner-b';
    final second = adapter.pending = Completer<BuyV2LiveDeliverySnapshot>();
    final next = session.refreshLiveDelivery('PO-240783');
    expect(adapter.loadCalls, 2);
    first.complete(adapter.readySnapshot('PO-240783'));
    expect(await old, isFalse);
    expect(session.liveDeliveryBusy('PO-240783'), isTrue);
    expect(session.liveDeliveryFor('PO-240783'), isNull);
    second.complete(adapter.readySnapshot('PO-240783'));
    expect(await next, isTrue);
    expect(session.liveDeliveryBusy('PO-240783'), isFalse);
  });
  test('LF11 repeated polling makes only one read', () async {
    final (session, adapter, _, _) = lf11Fixture();
    final pending = adapter.pending = Completer<BuyV2LiveDeliverySnapshot>();
    final first = session.refreshLiveDelivery('PO-240783');
    expect(await session.refreshLiveDelivery('PO-240783'), isFalse);
    expect(adapter.loadCalls, 1);
    pending.complete(adapter.readySnapshot('PO-240783'));
    expect(await first, isTrue);
  });
  for (final sameStream in [true, false]) {
    test(
      'LF11 old timestamp same stream $sameStream is handled explicitly',
      () async {
        final (session, adapter, _, _) = lf11Fixture();
        final at = DateTime.now().subtract(const Duration(minutes: 1));
        adapter.snapshot = adapter.readySnapshot('PO-240783', updatedAt: at);
        expect(await session.refreshLiveDelivery('PO-240783'), isTrue);
        final original = session.liveDeliveryFor('PO-240783');
        adapter.snapshot = adapter.readySnapshot(
          'PO-240783',
          updatedAt: at.subtract(const Duration(minutes: 1)),
          trackingReference: sameStream ? 'TRACK-240783' : 'TRACK-REASSIGNED',
        );
        expect(await session.refreshLiveDelivery('PO-240783'), !sameStream);
        if (sameStream) {
          expect(session.liveDeliveryFor('PO-240783'), same(original));
          expect(session.liveDeliveryRefreshMessage('PO-240783'), isNotNull);
        } else {
          expect(
            session.liveDeliveryFor('PO-240783')!.trackingReference,
            'TRACK-REASSIGNED',
          );
        }
      },
    );
  }
  test(
    'LF11 missing stream reference does not invent timestamp ordering',
    () async {
      final (session, adapter, _, _) = lf11Fixture();
      final at = DateTime.now().subtract(const Duration(minutes: 1));
      adapter.snapshot = adapter.readySnapshot(
        'PO-240783',
        updatedAt: at,
        trackingReference: null,
      );
      expect(await session.refreshLiveDelivery('PO-240783'), isTrue);
      adapter.snapshot = adapter.readySnapshot(
        'PO-240783',
        updatedAt: at.subtract(const Duration(minutes: 1)),
        trackingReference: null,
      );
      expect(await session.refreshLiveDelivery('PO-240783'), isTrue);
    },
  );
  test(
    'LF11 valid newer tracking correction is not permanently frozen',
    () async {
      final (session, adapter, _, _) = lf11Fixture();
      final at = DateTime.now().subtract(const Duration(minutes: 1));
      adapter.snapshot = BuyV2LiveDeliverySnapshot(
        orderId: 'PO-240783',
        state: BuyV2LiveDeliveryState.delivered,
        customerMessage: 'Host confirmed',
        sourceId: 'delivery-location',
        trackingReference: 'TRACK-240783',
        lastUpdatedAt: at,
      );
      expect(await session.refreshLiveDelivery('PO-240783'), isTrue);
      adapter.snapshot = adapter.readySnapshot(
        'PO-240783',
        updatedAt: at.add(const Duration(seconds: 1)),
      );
      expect(await session.refreshLiveDelivery('PO-240783'), isTrue);
      expect(
        session.liveDeliveryFor('PO-240783')!.state,
        BuyV2LiveDeliveryState.ready,
      );
    },
  );
  for (final change in ['cached removal', 'pending removal', 'reassignment']) {
    test('LF11 tracking follows current order identity $change', () async {
      final commerce = _Lf11OrdersAdapter();
      final adapter = _LiveDeliveryAdapter();
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: commerce,
        liveDeliveryAdapter: adapter,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      const id = 'LF11-ORDER';
      expect(session.commerceLoadState, BuyV2CommerceLoadState.ready);
      expect(session.orders.map((o) => o.id), [id]);
      Future<bool>? pending;
      if (change == 'pending removal') {
        adapter.pending = Completer<BuyV2LiveDeliverySnapshot>();
        pending = session.refreshLiveDelivery(id);
      } else {
        expect(await session.refreshLiveDelivery(id), isTrue);
      }
      commerce.records = change == 'reassignment'
          ? [commerce.order('NEW-DELIVERY')]
          : [];
      await session.restoreCommerce();
      if (change == 'reassignment') {
        expect(session.orders.single.trackingReference, 'NEW-DELIVERY');
      }
      expect(session.liveDeliveryFor(id), isNull);
      expect(session.liveDeliveryBusy(id), isFalse);
      if (pending != null) {
        adapter.pending!.complete(adapter.readySnapshot(id));
        expect(await pending, isFalse);
        expect(session.liveDeliveryFor(id), isNull);
      }
    });
  }
  for (final failure in ['invalid', 'offline', 'unavailable', 'throw']) {
    test(
      'LF11 confirmed delivered survives $failure refresh without business effects',
      () async {
        final (session, adapter, _, _) = lf11Fixture();
        final originalOrders = [
          for (final o in session.orders)
            (
              o.id,
              o.status,
              o.amountPaidNow,
              o.balanceDue,
              o.proofOfDeliveryStatus,
            ),
        ];
        adapter.snapshot = const BuyV2LiveDeliverySnapshot(
          orderId: 'PO-240783',
          state: BuyV2LiveDeliveryState.delivered,
          customerMessage: 'Isolated confirmed delivery',
          sourceId: 'delivery-location',
        );
        expect(await session.refreshLiveDelivery('PO-240783'), isTrue);
        final delivered = session.liveDeliveryFor('PO-240783');
        adapter.throwOnLoad = failure == 'throw';
        adapter.snapshot = BuyV2LiveDeliverySnapshot(
          orderId: failure == 'invalid' ? 'OTHER' : 'PO-240783',
          state: failure == 'offline'
              ? BuyV2LiveDeliveryState.offline
              : BuyV2LiveDeliveryState.unavailable,
          customerMessage: 'Isolated read unavailable',
          sourceId: 'delivery-location',
        );
        expect(await session.refreshLiveDelivery('PO-240783'), isFalse);
        expect(session.liveDeliveryFor('PO-240783'), same(delivered));
        expect(session.liveDeliveryRefreshMessage('PO-240783'), isNotNull);
        expect([
          for (final o in session.orders)
            (
              o.id,
              o.status,
              o.amountPaidNow,
              o.balanceDue,
              o.proofOfDeliveryStatus,
            ),
        ], originalOrders);
      },
    );
  }

  test(
    'live delivery validates coordinates and retains the last known update',
    () async {
      final adapter = _LiveDeliveryAdapter();
      final session = BuyV2Session(
        core: BuySession(),
        liveDeliveryAdapter: adapter,
      );
      addTearDown(session.dispose);
      const orderId = 'PO-240783';

      expect(await session.refreshLiveDelivery(orderId), isTrue);
      final accepted = session.liveDeliveryFor(orderId);
      expect(accepted?.driverName, 'Ravi Kumar');
      expect(accepted?.courierPosition?.isValid, isTrue);

      adapter.snapshot = adapter.readySnapshot(
        orderId,
        courierPosition: const BuyV2GeoPoint(latitude: 121, longitude: 73.0243),
      );
      expect(await session.refreshLiveDelivery(orderId), isFalse);
      expect(session.liveDeliveryFor(orderId), same(accepted));
      expect(
        session.liveDeliveryRefreshMessage(orderId),
        'Live delivery details are temporarily unavailable. Try again.',
      );

      adapter.throwOnLoad = true;
      expect(await session.refreshLiveDelivery(orderId), isFalse);
      expect(session.liveDeliveryFor(orderId), same(accepted));
      expect(
        session.liveDeliveryRefreshMessage(orderId),
        contains('Check your connection'),
      );

      adapter.throwOnLoad = false;
      adapter.snapshot = const BuyV2LiveDeliverySnapshot(
        orderId: orderId,
        state: BuyV2LiveDeliveryState.offline,
        customerMessage:
            'The latest location is temporarily unavailable. Try again.',
        sourceId: 'delivery-location',
      );
      expect(await session.refreshLiveDelivery(orderId), isFalse);
      expect(session.liveDeliveryFor(orderId), same(accepted));
      expect(
        session.liveDeliveryRefreshMessage(orderId),
        'The latest location is temporarily unavailable. Try again.',
      );
    },
  );

  testWidgets('Tracking shows live map, courier, ETA and freshness', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final adapter = _LiveDeliveryAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      liveDeliveryAdapter: adapter,
    );
    addTearDown(session.dispose);
    expect(session.openTracking('PO-240783'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          orderId: 'PO-240783',
          liveDeliveryMapBuilder: (context, snapshot) => ColoredBox(
            key: const ValueKey('test-live-courier-map'),
            color: const Color(0xFFE7EAF4),
            child: Center(
              child: Text('Courier location · ${snapshot.etaLabel}'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('buy-live-delivery-PO-240783'));
    await tester.scrollUntilVisible(
      panel,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(panel, findsOneWidget);
    expect(find.byKey(const ValueKey('test-live-courier-map')), findsOneWidget);
    expect(find.text('Ravi Kumar · RJ 19 EV 4821'), findsOneWidget);
    expect(find.text('Arriving'), findsOneWidget);
    expect(find.text('About 12 minutes'), findsWidgets);
    expect(find.text('Just now'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('unavailable live delivery stays truthful and non-actionable', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final order = session.orders.firstWhere(
      (candidate) => candidate.status != BuyV2OrderStatus.delivered,
    );
    expect(session.openTracking(order.id), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          orderId: order.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(ValueKey('buy-live-delivery-${order.id}'));
    await tester.scrollUntilVisible(
      panel,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('Live delivery updates are not available for this order yet.'),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('buy-live-delivery-retry-${order.id}')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('foreground tracking refreshes and stops after disposal', (
    tester,
  ) async {
    final adapter = _LiveDeliveryAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      liveDeliveryAdapter: adapter,
    );
    addTearDown(session.dispose);
    final order = session.orders.firstWhere(
      (candidate) => candidate.status != BuyV2OrderStatus.delivered,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: BuyV2LiveDeliveryPanel(
            session: session,
            order: order,
            pollInterval: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(adapter.loadCalls, greaterThanOrEqualTo(2));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final callsWhilePaused = adapter.loadCalls;
    await tester.pump(const Duration(milliseconds: 350));
    expect(adapter.loadCalls, callsWhilePaused);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(adapter.loadCalls, greaterThan(callsWhilePaused));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final callsAfterDispose = adapter.loadCalls;
    await tester.pump(const Duration(milliseconds: 350));
    expect(adapter.loadCalls, callsAfterDispose);
  });

  testWidgets('map fallback remains readable at compact 140 percent text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final adapter = _LiveDeliveryAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      liveDeliveryAdapter: adapter,
    );
    addTearDown(session.dispose);
    expect(session.openTracking('PO-240783'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          orderId: 'PO-240783',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('buy-live-delivery-PO-240783'));
    await tester.scrollUntilVisible(
      panel,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Map view is not available right now.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-live-delivery-map-PO-240783')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-live-delivery-map-toggle-PO-240783')),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'Delivery map unavailable.*About 12 minutes'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.4]) {
    testWidgets(
      'provider map expands and resets for a different order at $scale text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final session = BuyV2Session(
          core: BuySession(),
          liveDeliveryAdapter: _LiveDeliveryAdapter(),
        );
        addTearDown(session.dispose);
        final orders = session.orders
            .where((order) => order.status != BuyV2OrderStatus.delivered)
            .take(2)
            .toList();
        expect(orders, hasLength(2));
        Future<void> show(BuyV2Order order) async {
          await session.refreshLiveDelivery(order.id);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => RepaintBoundary(
                key: const ValueKey('tracking-review-capture'),
                child: child!,
              ),
              theme: MoolTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: BuyV2LiveDeliveryPanel(
                    session: session,
                    order: order,
                    pollInterval: Duration.zero,
                    mapBuilder: (context, snapshot) => const ColoredBox(
                      color: Color(0xFFE7EAF4),
                      child: Center(
                        child: Text(
                          'Test map renderer\nNo live location',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await show(orders.first);
        final map = find.byKey(
          ValueKey('buy-live-delivery-map-${orders.first.id}'),
        );
        final compactHeight = tester.getSize(map).height;
        await _captureTracking(tester, 'compact-$scale');
        await tester.tap(find.text('Expand map'));
        await tester.pumpAndSettle();
        expect(tester.getSize(map).height, greaterThan(compactHeight));
        expect(find.text('Collapse map'), findsOneWidget);
        await _captureTracking(tester, 'expanded-$scale');
        await tester.tap(find.text('Collapse map'));
        await tester.pumpAndSettle();
        expect(tester.getSize(map).height, compactHeight);
        await tester.tap(find.text('Expand map'));
        await tester.pumpAndSettle();
        await show(orders.last);
        expect(find.text('Expand map'), findsOneWidget);
        expect(
          tester
              .getSize(
                find.byKey(ValueKey('buy-live-delivery-map-${orders.last.id}')),
              )
              .height,
          compactHeight,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final delivered in [true, false]) {
    testWidgets('T14 tracking guidance names the available action $delivered', (
      tester,
    ) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final order = session.orders.firstWhere(
        (order) => delivered
            ? order.status == BuyV2OrderStatus.delivered
            : order.status == BuyV2OrderStatus.preparing,
      );
      expect(session.openTracking(order.id), isTrue);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
            orderId: order.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = delivered ? 'Return, replace or refund' : 'Manage order';
      final scrollable = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      if (delivered) {
        await tester.scrollUntilVisible(
          find.text('What happens next'),
          250,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Check your products and use $label'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Check your products and use Manage order'),
          findsNothing,
        );
      }
      final action = find.byKey(
        ValueKey('buy-tracking-manage-order-${order.id}'),
      );
      await tester.scrollUntilVisible(action, 250, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: action, matching: find.text(label)),
        findsOneWidget,
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets);
      expect(session.selectedOrderOrNull?.id, order.id);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completed orders do not request a live courier location', (
    tester,
  ) async {
    final adapter = _LiveDeliveryAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      liveDeliveryAdapter: adapter,
    );
    addTearDown(session.dispose);
    final order = session.orders.firstWhere(
      (candidate) => candidate.status == BuyV2OrderStatus.delivered,
    );
    expect(session.openTracking(order.id), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          orderId: order.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('buy-live-delivery-${order.id}')), findsNothing);
    expect(adapter.loadCalls, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _captureTracking(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('TRACKING_CAPTURE_DIR');
  if (directory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('tracking-review-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

final class _LiveDeliveryAdapter implements BuyV2LiveDeliveryAdapter {
  int loadCalls = 0;
  bool throwOnLoad = false;
  BuyV2LiveDeliverySnapshot? snapshot;
  Completer<BuyV2LiveDeliverySnapshot>? pending;

  BuyV2LiveDeliverySnapshot readySnapshot(
    String orderId, {
    BuyV2GeoPoint courierPosition = const BuyV2GeoPoint(
      latitude: 26.2771,
      longitude: 73.0243,
    ),
    DateTime? updatedAt,
    String? trackingReference = 'TRACK-240783',
  }) => BuyV2LiveDeliverySnapshot(
    orderId: orderId,
    state: BuyV2LiveDeliveryState.ready,
    customerMessage: 'Your delivery partner is on the way.',
    sourceId: 'delivery-location',
    courierPosition: courierPosition,
    destinationPosition: const BuyV2GeoPoint(
      latitude: 26.2789,
      longitude: 73.0262,
    ),
    driverName: 'Ravi Kumar',
    vehicleLabel: 'RJ 19 EV 4821',
    etaLabel: 'About 12 minutes',
    lastUpdatedAt: updatedAt ?? DateTime.now(),
    routeProgress: .72,
    trackingReference: trackingReference,
  );

  @override
  Future<BuyV2LiveDeliverySnapshot> load({required String orderId}) async {
    loadCalls += 1;
    if (pending != null) return pending!.future;
    if (throwOnLoad) throw StateError('offline');
    return snapshot ?? readySnapshot(orderId);
  }
}

class _Lf11OwnerStore implements BuyV2CustomerStateStore {
  String scope = 'lf11-owner-a';
  @override
  String get ownerScope => scope;
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => null;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async => true;
}

class _Lf11OrdersAdapter implements BuyV2CommerceAdapter {
  late List<BuyV2Order> records = [order('ORIGINAL-DELIVERY')];
  BuyV2Order order(String reference) => BuyV2Order(
    id: 'LF11-ORDER',
    destination: BuyV2Destination.shop,
    title: 'Isolated host order',
    itemSummary: 'Original host item',
    total: 100,
    partner: 'host-store-a',
    partnerType: 'Store',
    promise: 'Provider timing unavailable',
    destinationLabel: 'Host address',
    progress: .4,
    status: BuyV2OrderStatus.preparing,
    purchaseId: 'LF11-PURCHASE',
    trackingReference: reference,
  );
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    orders: records,
  );
  // These read-only tests must never submit an order or financial operation.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
