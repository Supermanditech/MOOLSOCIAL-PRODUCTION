import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  BuyV2LiveDeliverySnapshot readySnapshot(
    String orderId, {
    BuyV2GeoPoint courierPosition = const BuyV2GeoPoint(
      latitude: 26.2771,
      longitude: 73.0243,
    ),
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
    lastUpdatedAt: DateTime.now(),
    routeProgress: .72,
    trackingReference: 'TRACK-240783',
  );

  @override
  Future<BuyV2LiveDeliverySnapshot> load({required String orderId}) async {
    loadCalls += 1;
    if (throwOnLoad) throw StateError('offline');
    return snapshot ?? readySnapshot(orderId);
  }
}
