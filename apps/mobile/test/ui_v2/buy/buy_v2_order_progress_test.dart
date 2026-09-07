import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

class _R5ArrivalSound implements BuyV2DeliveryArrivalSound {
  int preparations = 0;
  int plays = 0;
  int stops = 0;
  int disposals = 0;
  bool ready = true;
  bool playable = true;
  Completer<bool>? preparation;
  Completer<bool>? playback;

  @override
  Future<bool> prepare() async {
    preparations++;
    return preparation == null ? ready : preparation!.future;
  }

  @override
  Future<bool> play() async {
    plays++;
    return playback == null ? playable : playback!.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class _R5CuePlayer implements AudioPlayer {
  int plays = 0;
  int disposals = 0;
  String? loadedPath;
  List<int>? wave;
  Completer<Duration?>? loadGate;
  final loaded = Completer<void>();
  bool failPlayback = false;
  ProcessingState state = ProcessingState.idle;

  @override
  ProcessingState get processingState => state;

  @override
  Future<Duration?> setFilePath(
    String filePath, {
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    loadedPath = filePath;
    wave = await File(filePath).readAsBytes();
    loaded.complete();
    final gate = loadGate;
    if (gate != null) await gate.future;
    state = ProcessingState.ready;
    return const Duration(milliseconds: 400);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> play() async {
    plays++;
    if (failPlayback) throw StateError('Audio device unavailable');
    state = ProcessingState.completed;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    state = ProcessingState.idle;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _R66TrackingSession extends BuyV2Session {
  _R66TrackingSession({required super.core, required this.order});
  BuyV2Order order;

  void updateOrder(BuyV2Order value) {
    order = value;
    notifyListeners();
  }

  @override
  List<BuyV2Order> get orders => [order];

  @override
  List<BuyV2Order> get visibleOrders {
    final completed = order.status == BuyV2OrderStatus.delivered;
    final showCompleted = ordersTab == BuyV2OrdersTab.delivered;
    final normalizedQuery = query.trim().toLowerCase();
    if (order.destination == BuyV2Destination.medicine ||
        completed != showCompleted ||
        (destination == BuyV2Destination.orders &&
            normalizedQuery.isNotEmpty &&
            ![
              order.id,
              order.title,
              order.partner,
              order.partnerType,
              order.itemSummary,
            ].any((value) => value.toLowerCase().contains(normalizedQuery)))) {
      return const [];
    }
    return orders;
  }

  @override
  int get activeOrderCount =>
      order.destination != BuyV2Destination.medicine &&
          order.status != BuyV2OrderStatus.delivered
      ? 1
      : 0;

  @override
  int get deliveredOrderCount =>
      order.destination != BuyV2Destination.medicine &&
          order.status == BuyV2OrderStatus.delivered
      ? 1
      : 0;

  @override
  BuyV2Order get selectedOrderOrNull => order;

  @override
  BuyV2Order? get activeQuickDeliveryOrder =>
      order.destination == BuyV2Destination.shop &&
          order.status != BuyV2OrderStatus.delivered
      ? order
      : null;
}

BuyV2Order _r66Order(BuyV2OrderStatus status, BuyV2Destination destination) =>
    BuyV2Order(
      id: destination == BuyV2Destination.shop ? 'MS-240782' : 'PO-240783',
      destination: destination,
      title: '${destination.label} order',
      itemSummary: '1 product',
      total: 74,
      partner: 'Shree Balaji Fresh and Provisions',
      partnerType: 'Retailer',
      promise: 'Delivered in 12 min',
      promisedByLabel: 'by 6:35 PM',
      destinationLabel: 'Sardarpura, Jodhpur · 342003',
      progress: switch (status) {
        BuyV2OrderStatus.confirmed => .1,
        BuyV2OrderStatus.preparing => .4,
        BuyV2OrderStatus.dispatched => .7,
        BuyV2OrderStatus.arriving => .9,
        BuyV2OrderStatus.delivered => 1,
      },
      status: status,
      deliveryPartnerName:
          status == BuyV2OrderStatus.dispatched ||
              status == BuyV2OrderStatus.arriving
          ? 'Assigned delivery partner'
          : null,
    );

void main() {
  Widget app(
    BuyV2Session session,
    double scale, {
    BuyV2DeliveryArrivalSound? sound,
    EdgeInsets insets = EdgeInsets.zero,
  }) => RepaintBoundary(
    key: const ValueKey('r66-order-state-app-capture'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: insets,
          padding: const EdgeInsets.only(top: 24, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
        ),
        child: child!,
      ),
      home: BuyV2Screen(session: session, deliveryArrivalSound: sound),
    ),
  );

  Future<void> capture(WidgetTester tester, String name) async {
    const currentDirectory = String.fromEnvironment(
      'BUY_R664_VISUAL_DIRECTORY',
    );
    if (currentDirectory.isEmpty &&
        !const bool.fromEnvironment('BUY_R66_ORDER_STATE_CAPTURE')) {
      return;
    }
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await tester.runAsync(
        () => precacheImage(image.image, tester.element(find.byWidget(image))),
      );
    }
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-order-state-app-capture')),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      repaint(boundary);
      await tester.pump();
      await tester.runAsync(() async {
        final directory = Directory(
          currentDirectory.isNotEmpty
              ? currentDirectory
              : 'build/r66-order-state-v1-20260905',
        );
        await directory.create(recursive: true);
        final file = File('${directory.path}/$name.png');
        if (await file.exists()) {
          throw StateError('Capture already exists');
        }
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    } finally {
      debugDisableShadows = previousShadows;
      repaint(boundary);
      await tester.pump();
    }
  }

  for (final behavior in ['progress', 'keep', 'hide']) {
    testWidgets('R5 delivery 011 reproduces $behavior', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = _R66TrackingSession(
        core: core,
        order: _r66Order(BuyV2OrderStatus.preparing, BuyV2Destination.shop),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, 1));
      await tester.pumpAndSettle();
      if (behavior == 'progress') {
        final progress = find.byKey(
          const ValueKey('buy-quick-delivery-compact-progress'),
        );
        expect(progress, findsOneWidget);
        expect(
          tester.widget<BuyV2HonestProgressIndicator>(progress).progress,
          .4,
        );
      } else {
        await tester.tap(
          find.byKey(const ValueKey('buy-quick-delivery-toggle')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('buy-quick-delivery-$behavior')));
        await tester.pumpAndSettle();
        if (behavior == 'keep') {
          await tester.pump(const Duration(seconds: 46));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
            findsOneWidget,
          );
        } else {
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-toggle')),
            findsNothing,
          );
          expect(session.openTracking(session.order.id), isTrue);
          await tester.pumpAndSettle();
          final restore = find.byKey(
            const ValueKey('buy-quick-delivery-restore'),
          );
          expect(restore, findsOneWidget);
          await tester.tap(restore);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          session.returnToOrders();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-toggle')),
            findsOneWidget,
          );
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> tapDelivery(WidgetTester tester, String action) async {
    final target = find.byKey(ValueKey('buy-quick-delivery-$action'));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 780),
    const Size(360, 800),
    const Size(430, 932),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R5 delivery 011 choices ${size.width}x${size.height} at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = _R66TrackingSession(
            core: core,
            order: _r66Order(BuyV2OrderStatus.preparing, BuyV2Destination.shop),
          );
          final sound = _R5ArrivalSound();
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(app(session, scale, sound: sound));
          await tester.pumpAndSettle();
          final prefix =
              'r5-delivery-${size.width.toInt()}x${size.height.toInt()}-$scale';
          final toggle = find.byKey(
            const ValueKey('buy-quick-delivery-toggle'),
          );
          expect(tester.getSize(toggle), const Size(44, 44));
          await capture(tester, '$prefix-compact');
          await tapDelivery(tester, 'toggle');
          await capture(tester, '$prefix-expanded');
          await tapDelivery(tester, 'keep');
          await tester.pump(const Duration(seconds: 46));
          await tester.pumpAndSettle();
          expect(find.text('Kept'), findsOneWidget);
          expect(session.addProduct('s-tomato'), isTrue);
          final quantity = session.quantityFor('s-tomato');
          session.openDestination(BuyV2Destination.wholesale);
          await tester.pumpAndSettle();
          expect(find.text('Kept'), findsOneWidget);
          await capture(tester, '$prefix-kept-wholesale-cart');
          await tapDelivery(tester, 'sound');
          expect(sound.preparations, 1);
          expect(sound.plays, 0);
          expect(
            tester
                .widget<FilterChip>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .selected,
            isTrue,
          );
          await capture(tester, '$prefix-sound-on');
          await tapDelivery(tester, 'hide');
          expect(toggle, findsNothing);
          expect(session.quantityFor('s-tomato'), quantity);
          await capture(tester, '$prefix-hidden');
          expect(session.openTracking(session.order.id), isTrue);
          await tester.pumpAndSettle();
          expect(toggle, findsNothing);
          await capture(tester, '$prefix-tracking-restore');
          await tapDelivery(tester, 'restore');
          expect(session.view, BuyV2View.tracking);
          session.returnToOrders();
          await tester.pumpAndSettle();
          expect(toggle, findsOneWidget);
          await tapDelivery(tester, 'toggle');
          expect(find.text('Keep'), findsOneWidget);
          expect(
            tester
                .widget<FilterChip>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .selected,
            isTrue,
          );
          await tapDelivery(tester, 'sound');
          expect(sound.plays, 0);
          expect(sound.stops, greaterThan(0));
          await capture(tester, '$prefix-restored-sound-off');
          final panel = find.byKey(
            const ValueKey('buy-quick-delivery-status-expanded'),
          );
          final progressSurface = find.descendant(
            of: panel,
            matching: find.byType(BuyV2HonestProgressIndicator),
          );
          await tester.ensureVisible(progressSurface);
          await tester.pumpAndSettle();
          final gesture = await tester.startGesture(
            tester.getCenter(progressSurface),
          );
          await tester.pump(const Duration(seconds: 46));
          expect(panel, findsOneWidget);
          await gesture.up();
          await tester.pump(const Duration(seconds: 44));
          expect(panel, findsOneWidget);
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
          expect(panel, findsNothing);
          expect(
            tester
                .widget<BuyV2HonestProgressIndicator>(
                  find.byKey(
                    const ValueKey('buy-quick-delivery-compact-progress'),
                  ),
                )
                .progress,
            .4,
          );
          expect(session.quantityFor('s-tomato'), quantity);
          await capture(tester, '$prefix-automatic-collapse');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final scenario in [
    'arriving',
    'delivered',
    'off',
    'background',
    'already-arriving',
    'failure',
    'pending-background',
    'pending-dispose',
    'prepare-unavailable',
    'prepare-timeout',
  ]) {
    testWidgets('R5 delivery 011 sound $scenario', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = _R66TrackingSession(
        core: core,
        order: _r66Order(
          scenario == 'already-arriving'
              ? BuyV2OrderStatus.arriving
              : BuyV2OrderStatus.dispatched,
          BuyV2Destination.shop,
        ),
      );
      final sound = _R5ArrivalSound()
        ..playable = scenario != 'failure'
        ..ready = scenario != 'prepare-unavailable';
      if (scenario.startsWith('pending') || scenario == 'prepare-timeout') {
        sound.preparation = Completer<bool>();
      }
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, 1, sound: sound));
      await tester.pumpAndSettle();
      await tapDelivery(tester, 'toggle');
      await tapDelivery(tester, 'sound');
      expect(sound.plays, 0, reason: 'Selecting sound is not an arrival.');
      if (scenario.startsWith('pending')) {
        expect(find.text('Setting sound'), findsOneWidget);
        if (scenario == 'pending-dispose') {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump();
        }
        sound.preparation!.complete(true);
        await tester.pumpAndSettle();
        expect(sound.plays, 0);
        if (scenario == 'pending-background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<FilterChip>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .selected,
            isFalse,
          );
        } else {
          expect(sound.disposals, 1);
        }
      } else if (scenario == 'prepare-timeout' ||
          scenario == 'prepare-unavailable') {
        if (scenario == 'prepare-timeout') {
          await tester.pump(const Duration(seconds: 9));
          await tester.pumpAndSettle();
          sound.preparation!.complete(true);
          await tester.pumpAndSettle();
        }
        expect(find.text('Sound unavailable. Try again.'), findsOneWidget);
        expect(
          tester
              .widget<FilterChip>(
                find.byKey(const ValueKey('buy-quick-delivery-sound')),
              )
              .selected,
          isFalse,
        );
        expect(sound.plays, 0);
        await capture(tester, 'r5-delivery-sound-$scenario');
      } else {
        if (scenario == 'off') await tapDelivery(tester, 'sound');
        if (scenario == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
        }
        session.updateOrder(
          _r66Order(
            scenario == 'delivered'
                ? BuyV2OrderStatus.delivered
                : BuyV2OrderStatus.arriving,
            BuyV2Destination.shop,
          ),
        );
        await tester.pumpAndSettle();
        final expected =
            ['off', 'background', 'already-arriving'].contains(scenario)
            ? 0
            : 1;
        expect(sound.plays, expected);
        session.updateOrder(session.order);
        await tester.pumpAndSettle();
        if (scenario == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
        }
        session.openOrders();
        await tester.pumpAndSettle();
        expect(
          sound.plays,
          expected,
          reason: 'Rebuild, Back and resume must not replay.',
        );
        if (scenario == 'failure') {
          await tapDelivery(tester, 'toggle');
          expect(find.text('Sound unavailable. Try again.'), findsOneWidget);
          expect(
            tester
                .widget<FilterChip>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .selected,
            isFalse,
          );
          await capture(tester, 'r5-delivery-sound-playback-unavailable');
        }
        if (scenario == 'arriving') {
          session.updateOrder(
            _r66Order(BuyV2OrderStatus.dispatched, BuyV2Destination.shop),
          );
          session.updateOrder(
            _r66Order(BuyV2OrderStatus.arriving, BuyV2Destination.shop),
          );
          session.updateOrder(
            _r66Order(BuyV2OrderStatus.delivered, BuyV2Destination.shop),
          );
          await tester.pumpAndSettle();
          expect(sound.plays, 1, reason: 'One arrival cue for this order.');
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final failure in [false, true]) {
    test(
      'R5 delivery 011 local cue file and cleanup playbackFailure=$failure',
      () async {
        final root = await Directory(
          'build/r66-r5-delivery-audio-fixtures',
        ).create(recursive: true);
        final player = _R5CuePlayer()..failPlayback = failure;
        final sound = BuyV2LocalDeliveryArrivalSound(
          temporaryDirectory: () async => root,
          playerFactory: () => player,
          supportedPlatform: true,
        );
        expect(await sound.prepare(), isTrue);
        expect(player.plays, 0);
        final wave = player.wave!;
        expect(wave.length, 12844);
        expect(String.fromCharCodes(wave.take(4)), 'RIFF');
        expect(String.fromCharCodes(wave.sublist(8, 12)), 'WAVE');
        expect(String.fromCharCodes(wave.sublist(36, 40)), 'data');
        expect(wave.sublist(20, 24), [1, 0, 1, 0]);
        expect(wave.sublist(34, 36), [16, 0]);
        expect(wave.skip(44).any((value) => value != 0), isTrue);
        expect(await sound.play(), !failure);
        expect(player.plays, 1);
        expect(player.disposals, 1);
        expect(await File(player.loadedPath!).exists(), isFalse);
        await sound.dispose();
        expect(await sound.prepare(), isFalse);
      },
    );
  }

  test('R5 delivery 011 unsupported platform never loads or plays', () async {
    final sound = BuyV2LocalDeliveryArrivalSound(
      supportedPlatform: false,
      temporaryDirectory: () => throw StateError('Must not read storage'),
      playerFactory: () => throw StateError('Must not create a player'),
    );
    expect(await sound.prepare(), isFalse);
    expect(await sound.play(), isFalse);
    await sound.dispose();
  });

  for (final size in [const Size(320, 780), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R5 delivery 011 keyboard ${size.width} at $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final core = BuySession();
        final session = _R66TrackingSession(
          core: core,
          order: _r66Order(BuyV2OrderStatus.preparing, BuyV2Destination.shop),
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final bottom = size.width > size.height ? 140.0 : 260.0;
        final sound = _R5ArrivalSound();
        await tester.pumpWidget(
          app(
            session,
            scale,
            sound: sound,
            insets: EdgeInsets.only(bottom: bottom),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const ValueKey('buy-quick-delivery-toggle'));
        expect(toggle.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(toggle).bottom,
          lessThanOrEqualTo(size.height - bottom),
        );
        await tapDelivery(tester, 'toggle');
        await tapDelivery(tester, 'keep');
        await tester.pump(const Duration(seconds: 46));
        await tester.pumpAndSettle();
        final kept = find.byKey(const ValueKey('buy-quick-delivery-keep'));
        await tester.ensureVisible(kept);
        await tester.pumpAndSettle();
        expect(kept.hitTestable(), findsOneWidget);
        await capture(
          tester,
          'r5-delivery-keyboard-${size.width.toInt()}-$scale-kept',
        );
        await tapDelivery(tester, 'hide');
        expect(toggle, findsNothing);
        await tester.pumpWidget(app(session, scale, sound: sound));
        await tester.pumpAndSettle();
        expect(toggle, findsNothing);
        expect(session.openTracking(session.order.id), isTrue);
        await tester.pumpAndSettle();
        await tapDelivery(tester, 'restore');
        session.returnToOrders();
        await tester.pumpAndSettle();
        expect(toggle.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final interruption in ['background', 'dispose', 'session']) {
    testWidgets('R5 delivery 011 playing cancellation $interruption', (
      tester,
    ) async {
      final core = BuySession();
      final session = _R66TrackingSession(
        core: core,
        order: _r66Order(BuyV2OrderStatus.dispatched, BuyV2Destination.shop),
      );
      final sound = _R5ArrivalSound()..playback = Completer<bool>();
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, 1, sound: sound));
      await tester.pumpAndSettle();
      await tapDelivery(tester, 'toggle');
      await tapDelivery(tester, 'sound');
      session.updateOrder(
        _r66Order(BuyV2OrderStatus.arriving, BuyV2Destination.shop),
      );
      await tester.pumpAndSettle();
      expect(sound.plays, 1);
      if (interruption == 'background') {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(sound.stops, greaterThan(0));
      } else if (interruption == 'dispose') {
        await tester.pumpWidget(const SizedBox.shrink());
        expect(sound.disposals, 1);
      } else {
        final replacementCore = BuySession();
        final replacement = _R66TrackingSession(
          core: replacementCore,
          order: _r66Order(BuyV2OrderStatus.arriving, BuyV2Destination.shop),
        );
        addTearDown(replacementCore.dispose);
        addTearDown(replacement.dispose);
        await tester.pumpWidget(app(replacement, 1, sound: sound));
        await tester.pumpAndSettle();
        await tapDelivery(tester, 'toggle');
        expect(
          tester
              .widget<FilterChip>(
                find.byKey(const ValueKey('buy-quick-delivery-sound')),
              )
              .selected,
          isFalse,
        );
      }
      sound.playback!.complete(false);
      await tester.pumpAndSettle();
      if (interruption == 'background') {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
      }
      expect(sound.plays, 1);
      expect(
        find.text('Sound unavailable. Try again.'),
        findsNothing,
        reason: 'A cancelled old operation cannot change the current UI.',
      );
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'R5 delivery 011 cancellation retires a pending native load once',
    () async {
      final root = await Directory(
        'build/r66-r5-delivery-audio-fixtures',
      ).create(recursive: true);
      final player = _R5CuePlayer()..loadGate = Completer<Duration?>();
      final sound = BuyV2LocalDeliveryArrivalSound(
        temporaryDirectory: () async => root,
        playerFactory: () => player,
        supportedPlatform: true,
      );
      final preparation = sound.prepare();
      await player.loaded.future.timeout(const Duration(seconds: 3));
      await sound.stop();
      player.loadGate!.complete(const Duration(milliseconds: 400));
      expect(await preparation, isFalse);
      expect(player.plays, 0);
      expect(player.disposals, 1);
      expect(await File(player.loadedPath!).exists(), isFalse);
      await sound.dispose();
    },
  );

  for (final status in BuyV2OrderStatus.values) {
    for (final scale in [1.0, 2.0]) {
      if (status != BuyV2OrderStatus.delivered) {
        testWidgets(
          'R66 active delivery stays truthful for ${status.name} at $scale',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(320, 844));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final core = BuySession();
            final order = _r66Order(status, BuyV2Destination.shop);
            final session = _R66TrackingSession(core: core, order: order);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            await tester.pumpWidget(app(session, scale));
            await tester.pumpAndSettle();
            final bar = find.byKey(
              const ValueKey('buy-quick-delivery-status-minimized'),
            );
            expect(bar, findsOneWidget);
            final toggle = find.byKey(
              const ValueKey('buy-quick-delivery-toggle'),
            );
            expect(tester.getSize(toggle), const Size(44, 44));
            final semantics = tester.ensureSemantics();
            late String announcement;
            try {
              announcement = tester.getSemantics(bar).getSemanticsData().label;
            } finally {
              semantics.dispose();
            }
            expect(announcement, contains('Delivery in 12 min · by 6:35 PM'));
            expect(announcement, isNot(contains('Delivered')));
            expect(announcement, contains(order.id));
            expect(tester.getSize(bar).width, lessThanOrEqualTo(48));
            await capture(tester, 'active-${status.name}-$scale-collapsed');
            await tester.tap(toggle);
            await tester.pumpAndSettle();
            final expanded = find.byKey(
              const ValueKey('buy-quick-delivery-status-expanded'),
            );
            expect(expanded, findsOneWidget);
            expect(find.text(order.id), findsOneWidget);
            expect(
              find.textContaining('Delivery in 12 min · by 6:35 PM'),
              findsOneWidget,
            );
            final labels = find.descendant(
              of: expanded,
              matching: find.byType(Text),
            );
            expect(labels, findsWidgets);
            for (final text in tester.widgetList<Text>(labels)) {
              expect(text.data, isNot(contains('Delivered')));
            }
            for (final element in labels.evaluate()) {
              final paragraph = element.renderObject! as RenderParagraph;
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason:
                    'label=${paragraph.text.toPlainText()} available=${paragraph.size.width} '
                    'panel=${tester.getSize(expanded).width}',
              );
            }
            await capture(tester, 'active-${status.name}-$scale-expanded');
            final hide = find.byKey(const ValueKey('buy-quick-delivery-hide'));
            await tester.tap(hide);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('buy-quick-delivery-toggle')),
              findsNothing,
            );
            expect(session.openTracking(order.id), isTrue);
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('buy-quick-delivery-restore')),
            );
            await tester.pumpAndSettle();
            session.returnToOrders();
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('buy-quick-delivery-toggle')),
            );
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('buy-quick-delivery-open')),
            );
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.tracking);
            expect(session.selectedOrderId, order.id);
            expect(order.promise, 'Delivered in 12 min');
            expect(order.promisedByLabel, 'by 6:35 PM');
            expect(tester.takeException(), isNull);
          },
        );
      }
      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        testWidgets(
          'R66 route is not travel progress for ${destination.name} ${status.name} at $scale',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(320, 844));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final core = BuySession();
            final order = _r66Order(status, destination);
            final session = _R66TrackingSession(core: core, order: order);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            await tester.pumpWidget(app(session, scale));
            expect(session.openTracking(order.id), isTrue);
            await tester.pumpAndSettle();
            final route = find.byKey(const ValueKey('buy-tracking-route'));
            await tester.scrollUntilVisible(
              route,
              220,
              scrollable: find.byType(Scrollable).last,
            );
            expect(
              find.descendant(
                of: route,
                matching: find.byType(BuyV2HonestProgressIndicator),
              ),
              findsNothing,
            );
            expect(
              find.descendant(
                of: route,
                matching: find.byType(LinearProgressIndicator),
              ),
              findsNothing,
            );
            for (final value in [order.partner, order.destinationLabel]) {
              final text = find.descendant(
                of: route,
                matching: find.text(value),
              );
              expect(text, findsOneWidget);
              expect(
                tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
                isFalse,
              );
            }
            expect(session.selectedOrderOrNull.status, status);
            expect(session.selectedOrderOrNull.progress, order.progress);
            await capture(
              tester,
              'route-${destination.name}-${status.name}-$scale',
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  group('Buy V2 order progress integrity', () {
    late BuyV2Session session;

    setUp(() {
      session = BuyV2Session(core: BuySession());
    });

    test('every established order is complete and progress is truthful', () {
      final ids = <String>{};

      for (final order in session.orders) {
        expect(order.id.trim(), isNotEmpty);
        expect(ids.add(order.id), isTrue, reason: order.id);
        expect(
          order.destination,
          isNot(BuyV2Destination.orders),
          reason: order.id,
        );
        expect(order.title.trim(), isNotEmpty, reason: order.id);
        expect(order.itemSummary.trim(), isNotEmpty, reason: order.id);
        expect(order.total, greaterThan(0), reason: order.id);
        expect(order.partner.trim(), isNotEmpty, reason: order.id);
        expect(order.partnerType, startsWith('Mool'), reason: order.id);
        expect(order.promise.trim(), isNotEmpty, reason: order.id);
        expect(order.destinationLabel.trim(), isNotEmpty, reason: order.id);
        expect(order.progress, greaterThan(0), reason: order.id);
        expect(order.progress, lessThanOrEqualTo(1), reason: order.id);

        if (order.status == BuyV2OrderStatus.delivered) {
          expect(order.progress, 1, reason: order.id);
        } else {
          expect(order.progress, lessThan(1), reason: order.id);
        }

        for (final productId in order.productIds) {
          final product = session.findProduct(productId);
          expect(product, isNotNull, reason: '${order.id}: $productId');
          expect(
            product!.destination,
            order.destination,
            reason: '${order.id}: $productId',
          );
        }
      }
    });

    test('Active and Delivered partition history without loss', () {
      final shopOrders = session.orders
          .where((order) => order.destination != BuyV2Destination.medicine)
          .toList(growable: false);
      final allIds = shopOrders.map((order) => order.id).toSet();
      final expectedActive = shopOrders
          .where((order) => order.status != BuyV2OrderStatus.delivered)
          .map((order) => order.id)
          .toSet();
      final expectedDelivered = shopOrders
          .where((order) => order.status == BuyV2OrderStatus.delivered)
          .map((order) => order.id)
          .toSet();

      session.showOrdersTab(BuyV2OrdersTab.active);
      final activeIds = session.visibleOrders.map((order) => order.id).toSet();
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      final deliveredIds = session.visibleOrders
          .map((order) => order.id)
          .toSet();

      expect(activeIds, expectedActive);
      expect(deliveredIds, expectedDelivered);
      expect(activeIds.intersection(deliveredIds), isEmpty);
      expect(activeIds.union(deliveredIds), allIds);
      expect(session.activeOrderCount, activeIds.length);
      expect(session.deliveredOrderCount, deliveredIds.length);

      expect(
        session.visibleOrders,
        everyElement(
          isA<BuyV2Order>().having(
            (order) => order.destination,
            'destination',
            isNot(BuyV2Destination.medicine),
          ),
        ),
      );

      for (final order in shopOrders) {
        session.showOrdersTab(
          order.status == BuyV2OrderStatus.delivered
              ? BuyV2OrdersTab.delivered
              : BuyV2OrdersTab.active,
        );
        session.updateQuery(order.id.toLowerCase());
        expect(session.visibleOrders.map((candidate) => candidate.id), [
          order.id,
        ], reason: order.id);
      }

      session.updateQuery('missing-order-id');
      expect(session.visibleOrders, isEmpty);
    });

    test('mixed confirmation creates exact live vertical orders', () {
      final selected = {
        for (final destination in const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ])
          destination: BuyV2Catalogue.products.firstWhere(
            (product) =>
                product.destination == destination &&
                !product.requiresPrescription,
          ),
      };
      for (final product in selected.values) {
        expect(session.addProduct(product.id), isTrue);
      }
      session.openCart();
      session.openCheckout();

      final expectedTotals = {
        for (final entry in selected.entries)
          entry.key: entry.value.price * entry.value.minimumOrder,
      };

      session.confirmOrder();

      expect(session.confirmedOrders, hasLength(3));
      expect(session.confirmedDestinations, selected.keys.toSet());
      for (final order in session.confirmedOrders) {
        final product = selected[order.destination]!;
        final expectedPrefix = switch (order.destination) {
          BuyV2Destination.shop => 'MS-NEW-',
          BuyV2Destination.wholesale => 'PO-NEW-',
          BuyV2Destination.medicine => 'RX-NEW-',
          BuyV2Destination.orders => throw StateError(
            'Orders cannot own a product order.',
          ),
        };
        expect(order.id, startsWith(expectedPrefix));
        expect(order.productIds, [product.id]);
        expect(order.total, expectedTotals[order.destination]);
        expect(order.progress, greaterThan(0));
        expect(order.progress, lessThan(1));
        expect(order.status, isNot(BuyV2OrderStatus.delivered));
        expect(session.productsForOrder(order).map((item) => item.id), [
          product.id,
        ]);
        expect(session.openTracking(order.id), isTrue);
        expect(session.selectedOrder.id, order.id);
        expect(session.selectedOrder.progress, order.progress);
      }

      session.showOrdersTab(BuyV2OrdersTab.active);
      final shopConfirmedIds = session.confirmedOrders
          .where((order) => order.destination != BuyV2Destination.medicine)
          .map((order) => order.id)
          .toSet();
      expect(
        session.visibleOrders.map((order) => order.id).toSet(),
        containsAll(shopConfirmedIds),
      );
      expect(
        session.visibleOrders,
        everyElement(
          isA<BuyV2Order>().having(
            (order) => order.destination,
            'destination',
            isNot(BuyV2Destination.medicine),
          ),
        ),
      );
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      expect(
        session.visibleOrders
            .map((order) => order.id)
            .toSet()
            .intersection(shopConfirmedIds),
        isEmpty,
      );
    });
  });
}
