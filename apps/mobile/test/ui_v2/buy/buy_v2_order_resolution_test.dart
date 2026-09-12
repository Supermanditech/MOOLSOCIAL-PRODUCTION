import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_order_resolution_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/work/scan_and_pick_contract.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _collectionSessionCases();
  _collectionWidgetCases();
  _collectionCameraCases();
  _collectionOrdersReadabilityCases();

  for (final kind in [
    BuyV2OrderResolutionKind.returnItems,
    BuyV2OrderResolutionKind.replacement,
    BuyV2OrderResolutionKind.refund,
  ]) {
    test(
      'R66 015 ${kind.name} sends exact eligible purchased quantities',
      () async {
        final adapter = _AcceptedResolutionAdapter()..kind = kind;
        adapter.itemEligibility = [_eligible(kind: kind)];
        final session = await _sessionWithOrder(adapter);
        expect(await session.refreshOrderResolution('order-policy'), isTrue);
        expect(
          await session.submitOrderResolution(
            orderId: 'order-policy',
            kind: kind,
            reason: 'Damaged item',
            itemQuantities: const {'s-tomato': 2},
          ),
          isTrue,
        );
        final request = adapter.requests.single;
        expect(request.orderId, 'order-policy');
        expect(request.itemQuantities, {'s-tomato': 2});
        expect(request.reason, 'Damaged item');
        expect(request.eligibilitySourceId, 'order-service');
        expect(
          session.orderResolutionResultFor('order-policy')?.reference,
          'RR-1001',
        );
        expect(
          () => request.itemQuantities['s-tomato'] = 3,
          throwsUnsupportedError,
        );
      },
    );
  }

  for (final rejection in [
    'empty selection',
    'unknown item',
    'zero quantity',
    'negative quantity',
    'excess quantity',
    'missing policy',
    'missing deadline',
    'expired',
    'excluded',
    'duplicate facts',
    'negative eligibility',
    'excess eligibility',
    'different kind',
    'different order',
    'missing source',
    'missing facts',
    'wrong reason',
    'missing acknowledgement',
  ]) {
    test('R66 015 rejects $rejection', () async {
      final adapter = _AcceptedResolutionAdapter();
      var fact = _eligible();
      var quantities = <String, int>{'s-tomato': 1};
      switch (rejection) {
        case 'empty selection':
          quantities = {};
        case 'unknown item':
          quantities = {'s-atta': 1};
        case 'zero quantity':
          quantities = {'s-tomato': 0};
        case 'negative quantity':
          quantities = {'s-tomato': -1};
        case 'excess quantity':
          quantities = {'s-tomato': 3};
        case 'missing policy':
          fact = _eligible(policy: '');
        case 'missing deadline':
          fact = _eligible(withDeadline: false);
        case 'expired':
          fact = _eligible(until: DateTime.utc(2020));
        case 'excluded':
          fact = _eligible(exclusion: 'Opened food cannot be returned.');
        case 'negative eligibility':
          fact = _eligible(quantity: -1);
        case 'excess eligibility':
          fact = _eligible(quantity: 3);
        case 'different kind':
          fact = _eligible(kind: BuyV2OrderResolutionKind.replacement);
        case 'different order':
          adapter.orderIdOverride = 'another-order';
        case 'missing source':
          adapter.sourceId = ' ';
        case 'missing acknowledgement':
          adapter.reference = null;
      }
      adapter.itemEligibility = rejection == 'missing facts'
          ? []
          : rejection == 'duplicate facts'
          ? [fact, fact]
          : [fact];
      final session = await _sessionWithOrder(adapter);
      await session.refreshOrderResolution('order-policy');
      expect(
        await session.submitOrderResolution(
          orderId: 'order-policy',
          kind: BuyV2OrderResolutionKind.refund,
          reason: rejection == 'wrong reason'
              ? 'Unlisted reason'
              : 'Damaged item',
          itemQuantities: quantities,
        ),
        isFalse,
      );
      expect(
        adapter.submitCalls,
        rejection == 'missing acknowledgement' ? 1 : 0,
      );
      expect(
        session.orderResolutionResultFor('order-policy')?.accepted,
        isNot(true),
      );
    });
  }

  test(
    'R66 015 exact deadline closes selection and refreshed exclusion wins',
    () async {
      final deadline = DateTime.utc(2030);
      final fact = _eligible(until: deadline);
      expect(
        fact.unavailableReasonAt(
          deadline.subtract(const Duration(microseconds: 1)),
        ),
        isNull,
      );
      expect(fact.unavailableReasonAt(deadline), contains('window has ended'));
      final adapter = _AcceptedResolutionAdapter()..itemEligibility = [fact];
      final session = await _sessionWithOrder(adapter);
      await session.refreshOrderResolution('order-policy');
      expect(
        session.orderResolutionItemsAllowed(
          orderId: 'order-policy',
          kind: BuyV2OrderResolutionKind.refund,
          itemQuantities: const {'s-tomato': 1},
        ),
        isTrue,
      );
      adapter.itemEligibility = [
        _eligible(quantity: 0, exclusion: 'Already refunded.'),
      ];
      await session.refreshOrderResolution('order-policy');
      expect(
        await session.submitOrderResolution(
          orderId: 'order-policy',
          kind: BuyV2OrderResolutionKind.refund,
          reason: 'Damaged item',
          itemQuantities: const {'s-tomato': 1},
        ),
        isFalse,
      );
      expect(adapter.submitCalls, 0);
    },
  );

  test(
    'R66 015 cancellation retains its separate order-stage contract',
    () async {
      final adapter = _AcceptedResolutionAdapter()
        ..kind = BuyV2OrderResolutionKind.cancel;
      final session = await _sessionWithOrder(
        adapter,
        status: BuyV2OrderStatus.preparing,
      );
      await session.refreshOrderResolution('order-policy');
      expect(
        await session.submitOrderResolution(
          orderId: 'order-policy',
          kind: BuyV2OrderResolutionKind.cancel,
          reason: 'Damaged item',
          itemQuantities: const {'s-tomato': 1},
        ),
        isFalse,
      );
      expect(
        await session.submitOrderResolution(
          orderId: 'order-policy',
          kind: BuyV2OrderResolutionKind.cancel,
          reason: 'Damaged item',
        ),
        isTrue,
      );
      expect(adapter.requests.single.itemQuantities, isEmpty);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'R66 015 item policy quantity and support fit at 320 text $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 800);
        tester.view.viewPadding = const FakeViewPadding(bottom: 32);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final adapter = _AcceptedResolutionAdapter()
          ..itemEligibility = [
            _eligible(),
            const BuyV2OrderResolutionItemEligibility(
              productId: 's-atta',
              kind: BuyV2OrderResolutionKind.refund,
              eligibleQuantity: 0,
              policyWindow: 'Unopened packs only',
              exclusionReason: 'The seal was opened. Contact support for help.',
            ),
          ];
        final session = await _sessionWithOrder(adapter);
        var supportCalls = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) => RepaintBoundary(
              key: const ValueKey('r66-order-policy-capture'),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showBuyV2OrderResolutionSheet(
                    context,
                    session: session,
                    order: session.orders.single,
                    onOpenSupport: () => supportCalls += 1,
                  ),
                  child: const Text('Manage purchased order'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Manage purchased order'));
        await tester.pumpAndSettle();
        await _tapSheet(tester, 'buy-order-resolution-refund');
        expect(
          find.text(
            'Policy window: Quality issues within 24 hours of delivery',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Eligible until'), findsOneWidget);
        expect(
          find.text('The seal was opened. Contact support for help.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Checkbox>(
                find.byKey(const ValueKey('buy-order-resolution-item-s-atta')),
              )
              .onChanged,
          isNull,
        );
        // Commerce has no current catalogue. These are the purchased line snapshots.
        expect(session.findProduct('s-tomato'), isNull);
        await _tapSheet(tester, 'buy-order-resolution-item-s-tomato');
        await _tapSheet(tester, 'buy-order-resolution-item-s-tomato-increase');
        final plus = find.byKey(
          const ValueKey('buy-order-resolution-item-s-tomato-increase'),
        );
        expect(tester.widget<IconButton>(plus).onPressed, isNull);
        expect(tester.getSize(plus).height, greaterThanOrEqualTo(44));
        await Scrollable.ensureVisible(
          tester.element(
            find.byKey(const ValueKey('buy-order-resolution-item-s-tomato')),
          ),
          alignment: .1,
        );
        await tester.pumpAndSettle();
        await _captureOrderPolicy(tester, '$scale-policy');
        await _tapSheet(tester, 'buy-order-resolution-reason-refund');
        await tester.tap(find.text('Damaged item').last);
        await tester.pumpAndSettle();
        final reasonText = find.descendant(
          of: find.byKey(const ValueKey('buy-order-resolution-reason-refund')),
          matching: find.text('Damaged item'),
        );
        final paragraph = tester.renderObject<RenderParagraph>(reasonText);
        final natural = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout(maxWidth: paragraph.size.width);
        expect(
          paragraph.size.height,
          greaterThanOrEqualTo(natural.height - .1),
        );
        natural.dispose();
        final submit = find.byKey(
          const ValueKey('buy-order-resolution-submit'),
        );
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(tester.getRect(submit).bottom, lessThanOrEqualTo(768));
        await _captureOrderPolicy(tester, '$scale-submit');
        await _tapSheet(tester, 'buy-order-resolution-submit');
        expect(adapter.requests.single.itemQuantities, {'s-tomato': 2});
        expect(
          find.byKey(const ValueKey('buy-order-resolution-sheet')),
          findsNothing,
        );
        await tester.tap(find.text('Manage purchased order'));
        await tester.pumpAndSettle();
        await _tapSheet(tester, 'buy-order-resolution-refund');
        await _tapSheet(tester, 'buy-order-resolution-item-s-tomato');
        // Refresh invalidates the selected quantity before a support handoff.
        adapter.itemEligibility = [
          _eligible(quantity: 0, exclusion: 'The request window has ended.'),
        ];
        await _tapSheet(tester, 'buy-order-resolution-check-eligibility');
        expect(
          find.byKey(const ValueKey('buy-order-resolution-no-eligible-items')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-order-resolution-submit')),
          findsNothing,
        );
        await _tapSheet(tester, 'buy-order-resolution-support-instead');
        expect(supportCalls, 1);
        expect(adapter.submitCalls, 1);
        expect(find.text('Manage purchased order'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('R66 015 blocks refund without purchased-item eligibility', () async {
    final adapter = _AcceptedResolutionAdapter();
    final core = BuySession();
    final session = BuyV2Session(core: core, orderResolutionAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final order = session.orders.firstWhere(
      (candidate) => candidate.status == BuyV2OrderStatus.delivered,
    );

    expect(await session.refreshOrderResolution(order.id), isTrue);
    expect(
      session.orderResolutionFor(order.id)?.options.single.kind,
      BuyV2OrderResolutionKind.refund,
    );
    expect(
      await session.submitOrderResolution(
        orderId: order.id,
        kind: BuyV2OrderResolutionKind.refund,
        reason: 'Damaged item',
      ),
      isFalse,
    );
    expect(adapter.submitCalls, 0);
    expect(session.orderResolutionResultFor(order.id), isNull);
  });

  testWidgets(
    'R66 015 delivered order with unknown policy fails closed at 320',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final order = session.orders.firstWhere(
        (candidate) => candidate.status == BuyV2OrderStatus.delivered,
      );
      expect(session.openTracking(order.id), isTrue);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: BuyV2Destination.orders,
            initialView: BuyV2View.tracking,
            orderId: order.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final trackingScroll = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-tracking-${order.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      final manage = find.byKey(
        ValueKey('buy-tracking-manage-order-${order.id}'),
      );
      await tester.scrollUntilVisible(manage, 220, scrollable: trackingScroll);
      for (var attempt = 0; attempt < 3; attempt += 1) {
        if (tester.getCenter(manage).dy < 610) break;
        await tester.drag(trackingScroll, const Offset(0, -180));
        await tester.pumpAndSettle();
      }
      await tester.tap(manage);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-order-resolution-sheet')),
        findsOneWidget,
      );

      final refund = find.byKey(const ValueKey('buy-order-resolution-refund'));
      await tester.ensureVisible(refund);
      await tester.pumpAndSettle();
      await tester.tap(refund);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-order-resolution-no-eligible-items')),
        findsOneWidget,
      );
      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(boxes.length, order.productIds.length);
      expect(boxes.every((box) => box.onChanged == null), isTrue);
      expect(
        find.byKey(const ValueKey('buy-order-resolution-submit')),
        findsNothing,
      );
      expect(find.textContaining('Eligible until'), findsNothing);
      expect(session.orderResolutionResultFor(order.id), isNull);
      final support = find.byKey(
        const ValueKey('buy-order-resolution-support-instead'),
      );
      await tester.ensureVisible(support);
      await tester.pumpAndSettle();
      expect(tester.getSize(support).height, greaterThanOrEqualTo(44));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrderId, order.id);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _AcceptedResolutionAdapter implements BuyV2OrderResolutionAdapter {
  int submitCalls = 0;
  BuyV2OrderResolutionKind kind = BuyV2OrderResolutionKind.refund;
  List<BuyV2OrderResolutionItemEligibility> itemEligibility = [];
  String? orderIdOverride;
  String sourceId = 'order-service';
  String? reference = 'RR-1001';
  final List<BuyV2OrderResolutionRequest> requests = [];

  @override
  Future<BuyV2OrderResolutionSnapshot> load(BuyV2Order order) async =>
      BuyV2OrderResolutionSnapshot(
        orderId: orderIdOverride ?? order.id,
        state: BuyV2OrderResolutionState.ready,
        sourceId: sourceId,
        itemEligibility: itemEligibility,
        options: [
          BuyV2OrderResolutionOption(
            kind: kind,
            title: 'Request refund',
            detail: 'Request a refund review.',
            reasons: ['Damaged item'],
          ),
        ],
      );

  @override
  Future<BuyV2OrderResolutionResult> submit(
    BuyV2OrderResolutionRequest request,
  ) async {
    submitCalls += 1;
    requests.add(request);
    return BuyV2OrderResolutionResult(
      accepted: true,
      customerMessage: 'Your refund request was submitted.',
      reference: reference,
    );
  }
}

BuyV2OrderResolutionItemEligibility _eligible({
  BuyV2OrderResolutionKind kind = BuyV2OrderResolutionKind.refund,
  int quantity = 2,
  String policy = 'Quality issues within 24 hours of delivery',
  DateTime? until,
  bool withDeadline = true,
  String? exclusion,
}) => BuyV2OrderResolutionItemEligibility(
  productId: 's-tomato',
  kind: kind,
  eligibleQuantity: quantity,
  policyWindow: policy,
  eligibleUntil: withDeadline ? until ?? DateTime.utc(2030) : null,
  exclusionReason: exclusion,
);

Widget _collectionTestApp(
  _CollectionHarness h,
  double scale, {
  required ValueChanged<ValueChanged<String>> onCamera,
  bool nativeCamera = false,
}) => RepaintBoundary(
  key: const ValueKey('r5-collection-capture'),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        padding: const EdgeInsets.only(top: 24, bottom: 34),
        viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
      ),
      child: child!,
    ),
    home: BuyV2Screen(
      session: h.session,
      initialDestination: BuyV2Destination.orders,
      initialView: BuyV2View.tracking,
      orderId: 'collection-1',
      collectionCameraBuilder: nativeCamera
          ? null
          : (context, detected) {
              onCamera(detected);
              return const AspectRatio(
                aspectRatio: 4 / 3,
                child: ColoredBox(
                  key: ValueKey('r5-collection-test-camera'),
                  color: Color(0xFF10182B),
                  child: Center(
                    child: Text(
                      'Camera preview\nTest feed',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              );
            },
    ),
  ),
);

Finder _collectionScroll() => find
    .descendant(
      of: find.byKey(const PageStorageKey('buy-collection-order-collection-1')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _collectionReveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 100, scrollable: _collectionScroll());
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _captureCollection(WidgetTester tester, String name) async {
  const directoryName = String.fromEnvironment(
    'BUY_R5_COLLECTION_VISUAL_DIRECTORY',
  );
  if (directoryName.isEmpty) return;
  if (!directoryName.startsWith('build/r66-r5-collection-visual-') ||
      directoryName.contains('..')) {
    throw StateError('Unexpected collection capture directory');
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r5-collection-capture')),
  );
  boundary.markNeedsPaint();
  await tester.pump();
  await tester.runAsync(() async {
    final directory = Directory(directoryName);
    await directory.create(recursive: true);
    final file = File([directory.path, '/', name, '.png'].join());
    if (await file.exists()) {
      throw StateError('Collection capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _collectionWholeText(WidgetTester tester, String text) async {
  await _collectionReveal(tester, find.text(text));
  final visibleWindow = tester.getRect(_collectionScroll());
  if (tester.getRect(find.text(text)).top < visibleWindow.top + 16) {
    // Reveal text inside the window using a real drag, rather than pinning a
    // glyph's overhang exactly to the clipping edge with ensureVisible.
    await tester.drag(_collectionScroll(), const Offset(0, 40));
    await tester.pumpAndSettle();
  }
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  expect(paragraph.didExceedMaxLines, isFalse, reason: text);
  expect(paragraph.text.style?.fontFamily, 'Inter');
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  expect(boxes, isNotEmpty);
  final viewport = tester.getRect(_collectionScroll());
  for (final box in boxes) {
    // Inter's glyph side bearings can extend beyond the paragraph origin.
    // Check the actual clipped viewport, not an imaginary paragraph clip.
    final left = paragraph.localToGlobal(Offset(box.left, 0)).dx;
    final right = paragraph.localToGlobal(Offset(box.right, 0)).dx;
    final top = paragraph.localToGlobal(Offset(0, box.top)).dy;
    final bottom = paragraph.localToGlobal(Offset(0, box.bottom)).dy;
    expect(left, greaterThanOrEqualTo(viewport.left - .1), reason: text);
    expect(right, lessThanOrEqualTo(viewport.right + .1), reason: text);
    expect(top, greaterThanOrEqualTo(viewport.top - .1), reason: text);
    expect(bottom, lessThanOrEqualTo(viewport.bottom + .1), reason: text);
  }
}

void _collectionWidgetCases() {
  for (final size in [
    const Size(320, 700),
    const Size(360, 800),
    const Size(430, 900),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      final label = [
        size.width.toInt(),
        'x',
        size.height.toInt(),
        '-',
        (scale * 100).toInt(),
      ].join();
      testWidgets('R5 022 widget same paid order scans and collects $label', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final h = (await tester.runAsync(_CollectionHarness.create))!;
        ValueChanged<String>? detect;
        await tester.pumpWidget(
          _collectionTestApp(h, scale, onCamera: (value) => detect = value),
        );
        await tester.pumpAndSettle();
        expect(find.text('Collect at store'), findsOneWidget);
        expect(find.text('Ready at store'), findsOneWidget);
        expect(find.text('Paid ₹123.45'), findsOneWidget);
        expect(find.text('40%'), findsNothing);
        expect(
          find.textContaining('Order alerts could not load'),
          findsNothing,
        );
        await _captureCollection(tester, '$label-ready');
        final scan = find.byKey(const ValueKey('buy-collection-scan'));
        await _collectionReveal(tester, scan);
        expect(tester.getSize(scan).height, greaterThanOrEqualTo(48));
        await tester.tap(scan);
        await tester.pumpAndSettle();
        expect(detect, isNotNull);
        expect(
          find.byKey(const ValueKey('r5-collection-test-camera')),
          findsOneWidget,
        );
        expect(find.text('Enter code'), findsNothing);
        expect(find.text('Scan now'), findsNothing);
        final cameraBounds = tester.getRect(
          find.byKey(const ValueKey('r5-collection-test-camera')),
        );
        final viewportBounds = tester.getRect(_collectionScroll());
        expect(cameraBounds.top, greaterThanOrEqualTo(viewportBounds.top - .1));
        expect(
          cameraBounds.bottom,
          lessThanOrEqualTo(viewportBounds.bottom + .1),
        );
        await _captureCollection(tester, '$label-camera');
        detect!(' opaque-QR ');
        await tester.pumpAndSettle();
        expect(h.gateway.requests.last.operation, ScanPickOperation.authorise);
        expect(h.gateway.requests.last.qrPayload, ' opaque-QR ');
        expect(h.session.view, BuyV2View.tracking);
        expect(h.session.selectedOrderId, 'collection-1');
        expect(
          h.session.collectionStatusLabelFor('collection-1'),
          'Matched · awaiting handover',
          reason:
              'Correlated order state before checking its visible status; '
              'busy=${h.session.collectionBusy('collection-1')}; '
              'message=${h.session.collectionMessageFor('collection-1')}; '
              'pending=${h.journal.pending != null}',
        );
        expect(find.text('Matched · awaiting handover'), findsOneWidget);
        expect(
          find.text('Check your items, then scan at the counter.'),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('r5-collection-test-camera')),
          findsNothing,
        );
        expect(h.session.orderIsCompleted(h.session.orders.single), isFalse);
        await tester.drag(_collectionScroll(), const Offset(0, 2000));
        await tester.pumpAndSettle();
        await _captureCollection(tester, '$label-matched');
        await _collectionReveal(tester, find.text('Quantity 1.25'));
        await _collectionWholeText(tester, 'Tomatoes');
        await _captureCollection(tester, '$label-item-name');
        await _collectionWholeText(tester, 'Quantity 1.25');
        await _collectionWholeText(tester, '₹123.45');
        await _captureCollection(tester, '$label-items');
        h.gateway.respond = (r) async =>
            _collectionReply(r, state: ScanPickState.collected);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(h.session.collectionStatusLabelFor('collection-1'), 'Collected');
        expect(h.session.selectedOrderId, 'collection-1');
        expect(h.session.view, BuyV2View.tracking);
        await tester.drag(_collectionScroll(), const Offset(0, 2000));
        await tester.pumpAndSettle();
        await _captureCollection(tester, '$label-collected');
        await _collectionReveal(tester, find.text('collection-receipt-A'));
        await _collectionWholeText(tester, 'collection-receipt-A');
        await _captureCollection(tester, '$label-receipt');
        expect(find.text('I received my order'), findsNothing);
        expect(find.textContaining('before scanning'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }

  for (final condition in [
    'preparing',
    'waiting QR',
    'cancelled',
    'expired',
    'offline',
    'unavailable',
  ]) {
    for (final size in [const Size(320, 700), const Size(640, 360)]) {
      final label = [
        condition.replaceAll(' ', '-'),
        '-',
        size.width.toInt(),
        'x',
        size.height.toInt(),
        '-200',
      ].join();
      testWidgets('R5 022 widget inline state $label', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final h = (await tester.runAsync(
          () =>
              _CollectionHarness.create(connected: condition != 'unavailable'),
        ))!;
        h.gateway.respond = (r) async {
          if (condition == 'offline') {
            throw StateError('Test network unavailable');
          }
          return _collectionReply(
            r,
            state: switch (condition) {
              'preparing' => ScanPickState.preparing,
              'waiting QR' => ScanPickState.ready,
              'cancelled' => ScanPickState.cancelled,
              _ => ScanPickState.awaitingCustomer,
            },
            changes: {
              if (condition == 'expired')
                'challenge': {
                  'id': 'expired-A',
                  'expiresAt': '2026-09-07T11:59:59Z',
                },
            },
          );
        };
        await tester.pumpWidget(_collectionTestApp(h, 2, onCamera: (_) {}));
        await tester.pumpAndSettle();
        expect(h.session.canScanCollection('collection-1'), isFalse);
        expect(
          h.gateway.requests.where(
            (r) => r.operation == ScanPickOperation.authorise,
          ),
          isEmpty,
        );
        expect(find.byType(Checkbox), findsNothing);
        expect(find.text('Collect at store'), findsOneWidget);
        final guidance = switch (condition) {
          'waiting QR' =>
            'Waiting for the store’s QR. This order updates automatically.',
          'expired' =>
            'Ask the store to refresh this order’s QR. We’ll check again automatically.',
          _ => null,
        };
        if (guidance != null) expect(find.text(guidance), findsOneWidget);
        await _captureCollection(tester, label);
        final scan = find.byKey(const ValueKey('buy-collection-scan'));
        if (condition != 'cancelled') {
          await _collectionReveal(tester, scan);
          expect(tester.widget<FilledButton>(scan).onPressed, isNull);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }

  testWidgets('R5 022 Orders card opens the same paid collection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final h = (await tester.runAsync(_CollectionHarness.create))!;
    await tester.pumpWidget(_collectionTestApp(h, 2, onCamera: (_) {}));
    await tester.pumpAndSettle();
    final back = find.descendant(
      of: find.byKey(const ValueKey('buy-collection-return-orders')),
      matching: find.byType(InkWell),
    );
    await _collectionReveal(tester, back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(h.session.view, BuyV2View.catalogue);
    expect(h.session.destination, BuyV2Destination.orders);
    expect(find.text('1 collection · ₹123.45'), findsOneWidget);
    expect(find.text('1 delivery · ₹124'), findsNothing);
    final card = find.byKey(const ValueKey('buy-order-primary-collection-1'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, greaterThanOrEqualTo(44));
    await _captureCollection(tester, 'orders-card-collection');
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(h.session.view, BuyV2View.tracking);
    expect(h.session.selectedOrderId, 'collection-1');
    expect(find.text('Paid ₹123.45'), findsOneWidget);
    expect(find.text('Scan & Pick'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  for (final change in ['Back', 'account', 'new login', 'background']) {
    testWidgets('R5 022 widget ignores late camera callback after $change', (
      tester,
    ) async {
      final h = (await tester.runAsync(_CollectionHarness.create))!;
      ValueChanged<String>? detect;
      await tester.pumpWidget(
        _collectionTestApp(h, 1, onCamera: (value) => detect = value),
      );
      await tester.pumpAndSettle();
      final scan = find.byKey(const ValueKey('buy-collection-scan'));
      await _collectionReveal(tester, scan);
      await tester.tap(scan);
      await tester.pumpAndSettle();
      final oldCameraCallback = detect!;
      switch (change) {
        case 'Back':
          final back = find.descendant(
            of: find.byKey(const ValueKey('buy-collection-return-orders')),
            matching: find.byType(InkWell),
          );
          await _collectionReveal(tester, back);
          await tester.tap(back);
        case 'account':
          h.identity.value = const BuyV2CollectionIdentity(
            accountId: 'customer-2',
            sessionId: 'login-2',
          );
        case 'new login':
          h.identity.value = const BuyV2CollectionIdentity(
            accountId: 'customer-1',
            sessionId: 'login-2',
          );
        case 'background':
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
      }
      await tester.pumpAndSettle();
      oldCameraCallback('late-opaque-QR');
      await tester.pumpAndSettle();
      expect(
        h.gateway.requests.where(
          (r) => r.operation == ScanPickOperation.authorise,
        ),
        isEmpty,
      );
      expect(h.journal.pending, isNull);
      if (change == 'background') {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('r5-collection-test-camera')),
          findsNothing,
        );
        expect(h.session.canScanCollection('collection-1'), isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets(
    'R5 022 a timed-out durable write settles before recovery reads',
    (tester) async {
      final journal = _DelayedCollectionPending();
      final h = (await tester.runAsync(
        () => _CollectionHarness.create(journal: journal),
      ))!;
      journal.delayReservation = true;
      final submission = h.session.authoriseCollection(
        'collection-1',
        'opaque-QR',
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      expect(await submission, isFalse);
      expect(
        h.gateway.requests.where(
          (r) => r.operation == ScanPickOperation.authorise,
        ),
        isEmpty,
      );
      final recovery = h.session.refreshCollectionOrder('collection-1');
      await tester.pump();
      expect(h.session.collectionBusy('collection-1'), isTrue);
      journal.releaseReservation.complete();
      await tester.pump();
      expect(await recovery, isTrue);
      expect(h.gateway.requests.last.operation, ScanPickOperation.reconcile);
      expect(
        h.gateway.requests.where(
          (r) => r.operation == ScanPickOperation.authorise,
        ),
        isEmpty,
      );
      expect(journal.pending, isNull);
    },
  );

  for (final state in ['ready', 'matched', 'collected', 'camera']) {
    testWidgets(
      'R5 022 Order help preserves exact collection context from $state',
      (tester) async {
        final h = (await tester.runAsync(_CollectionHarness.create))!;
        h.gateway.respond = (r) async => _collectionReply(
          r,
          state: switch (state) {
            'matched' => ScanPickState.matched,
            'collected' => ScanPickState.collected,
            _ => ScanPickState.awaitingCustomer,
          },
        );
        Uri? helpLocation;
        ValueChanged<String>? detect;
        final router = GoRouter(
          initialLocation: '/app/buy',
          routes: [
            GoRoute(
              path: '/app/buy',
              builder: (_, _) => BuyV2Screen(
                session: h.session,
                initialDestination: BuyV2Destination.orders,
                initialView: BuyV2View.tracking,
                orderId: 'collection-1',
                collectionCameraBuilder: (_, callback) {
                  detect = callback;
                  return const SizedBox(
                    height: 160,
                    child: ColoredBox(color: Colors.black),
                  );
                },
              ),
            ),
            GoRoute(
              path: '/app/chat/thread/shop-assist',
              builder: (_, route) {
                helpLocation = route.uri;
                return const Scaffold(body: Text('Order support test route'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router, theme: MoolTheme.light()),
        );
        await tester.pumpAndSettle();
        if (state == 'camera') {
          final scan = find.byKey(const ValueKey('buy-collection-scan'));
          await _collectionReveal(tester, scan);
          await tester.tap(scan);
          await tester.pumpAndSettle();
        }
        final help = find.byKey(const ValueKey('buy-collection-help'));
        await _collectionReveal(tester, help);
        await tester.tap(help);
        await tester.pumpAndSettle();
        expect(find.text('Order support test route'), findsOneWidget);
        final query = helpLocation!.queryParameters;
        expect(query['draft'], 'Help with order collection-1');
        expect(query['directReturn'], 'true');
        expect(Uri.parse(query['return']!).queryParameters, {
          'sub': 'orders',
          'view': 'tracking',
          'order': 'collection-1',
        });
        for (final legacyFact in [
          'orderTotal',
          'orderLines',
          'skuIds',
          'quantities',
          'delivery',
        ]) {
          expect(query.containsKey(legacyFact), isFalse);
        }
        final requestsWhileAway = h.gateway.requests.length;
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        if (detect != null) detect!('late-camera-QR');
        await tester.pump(const Duration(seconds: 7));
        await tester.pumpAndSettle();
        expect(h.gateway.requests, hasLength(requestsWhileAway));
        expect(
          h.gateway.requests.where(
            (r) => r.operation == ScanPickOperation.authorise,
          ),
          isEmpty,
        );
        router.pop();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(h.session.selectedOrderId, 'collection-1');
        expect(h.session.view, BuyV2View.tracking);
        expect(find.text('Collect at store'), findsOneWidget);
        expect(h.session.collectionSnapshotFor('collection-1'), isNotNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }

  testWidgets('R5 022 timeout reconciles instead of retrying authorisation', (
    tester,
  ) async {
    final h = (await tester.runAsync(_CollectionHarness.create))!;
    final lateReply = Completer<ScanPickResult>();
    h.gateway.respond = (_) => lateReply.future;
    final submission = h.session.authoriseCollection(
      'collection-1',
      'opaque-QR',
    );
    await tester.pump();
    final request = h.gateway.requests.last;
    expect(request.operation, ScanPickOperation.authorise);
    await tester.pump(const Duration(seconds: 16));
    expect(await submission, isFalse);
    expect(h.journal.pending?.operationId, request.operationId);
    expect(h.session.canScanCollection('collection-1'), isFalse);
    lateReply.complete(_collectionReply(request, state: ScanPickState.matched));
    await tester.pump();
    expect(
      h.session.collectionStatusLabelFor('collection-1'),
      'Checking collection',
    );
    h.gateway.respond = (r) async =>
        _collectionReply(r, state: ScanPickState.matched);
    final recovery = h.session.refreshCollectionOrder('collection-1');
    await tester.pump();
    expect(await recovery, isTrue);
    expect(h.gateway.requests.last.operation, ScanPickOperation.reconcile);
    expect(h.gateway.requests.last.operationId, request.operationId);
  });
}

void _collectionOrdersReadabilityCases() {
  for (final size in [const Size(320, 700), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final label = [
        size.width.toInt(),
        'x',
        size.height.toInt(),
        '-',
        (scale * 100).toInt(),
      ].join();
      testWidgets('R5 029C Orders tabs and continuation cards fit $label', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final h = (await tester.runAsync(_CollectionHarness.create))!;
        await tester.pumpWidget(_collectionTestApp(h, scale, onCamera: (_) {}));
        await tester.pumpAndSettle();
        final back = find.descendant(
          of: find.byKey(const ValueKey('buy-collection-return-orders')),
          matching: find.byType(InkWell),
        );
        await _collectionReveal(tester, back);
        await tester.tap(back);
        await tester.pumpAndSettle();
        final ordersScroll = find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-orders')),
              matching: find.byType(Scrollable),
            )
            .first;
        for (final tab in [BuyV2OrdersTab.delivered, BuyV2OrdersTab.active]) {
          final target = find.byKey(ValueKey('buy-orders-tab-${tab.name}'));
          await tester.scrollUntilVisible(
            target,
            100,
            scrollable: ordersScroll,
          );
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(h.session.ordersTab, tab);
          expect(
            h.session.visibleOrders,
            hasLength(tab == BuyV2OrdersTab.active ? 1 : 0),
          );
          if (tab == BuyV2OrdersTab.active) {
            expect(find.text('1 collection · ₹123.45'), findsOneWidget);
          }
          for (final word in ['Active', 'Delivered']) {
            final text = find.descendant(
              of: find.byKey(const ValueKey('buy-orders-tabs')),
              matching: find.text(word),
            );
            final paragraph = tester.renderObject<RenderParagraph>(text);
            final origin = paragraph.localToGlobal(Offset.zero);
            final bounds = tester.getRect(
              find.byKey(
                ValueKey(
                  'buy-orders-tab-${word == 'Active' ? 'active' : 'delivered'}',
                ),
              ),
            );
            for (final box in paragraph.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: word.length),
            )) {
              expect(
                bounds.contains(origin + Offset(box.left, box.top)),
                isTrue,
              );
              expect(
                bounds.contains(origin + Offset(box.right, box.bottom)),
                isTrue,
              );
            }
            expect(paragraph.didExceedMaxLines, isFalse);
          }
          await _captureCollection(tester, 'orders-$label-${tab.name}');
        }
        final rail = find.byKey(const ValueKey('buy-orders-promotions'));
        await tester.scrollUntilVisible(rail, 150, scrollable: ordersScroll);
        await tester.pumpAndSettle();
        final railScroll = find.descendant(
          of: rail,
          matching: find.byType(Scrollable),
        );
        for (final destination in ['shop', 'wholesale', 'medicine']) {
          final card = find.byKey(
            ValueKey('buy-promotion-orders-$destination'),
          );
          await tester.scrollUntilVisible(card, 150, scrollable: railScroll);
          await tester.pumpAndSettle();
          expect(card.hitTestable(), findsOneWidget);
          await _captureCollection(
            tester,
            'orders-$label-continue-$destination',
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}

class _CollectionPendingMemory implements BuyV2CollectionPendingStore {
  BuyV2CollectionPendingIntent? pending;
  bool allowReserve = true;
  bool allowClear = true;
  bool failRead = false;

  @override
  Future<BuyV2CollectionPendingIntent?> read({
    required String accountId,
    required String orderId,
    required String storeId,
  }) async {
    if (failRead) throw StateError('Test storage unavailable');
    return pending;
  }

  @override
  Future<bool> reserve(BuyV2CollectionPendingIntent intent) async {
    if (!allowReserve || pending != null) return false;
    pending = intent;
    return true;
  }

  @override
  Future<bool> clear(BuyV2CollectionPendingIntent intent) async {
    if (allowClear && pending == null) return true;
    if (!allowClear ||
        pending?.operationId != intent.operationId ||
        pending?.requestFingerprint != intent.requestFingerprint) {
      return false;
    }
    pending = null;
    return true;
  }
}

class _CollectionScannerPlatform extends MobileScannerPlatform {
  final captures = StreamController<BarcodeCapture?>.broadcast();
  final starts = <StartOptions>[];
  int stops = 0;
  bool failStart = false;

  @override
  Stream<BarcodeCapture?> get barcodesStream => captures.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts.add(options);
    if (failStart) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
    }
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
      numberOfCameras: 1,
    );
  }

  @override
  Widget buildCameraView() => const ColoredBox(
    color: Color(0xFF10182B),
    child: Center(
      child: Text(
        'Camera adapter\nLocal test feed',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  );
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> updateScanWindow(Rect? window) async {}
  @override
  Future<void> dispose() async {}
}

void _collectionCameraCases() {
  for (final condition in [
    'permission denied',
    'camera settings',
    'start error',
    'runtime error',
  ]) {
    for (final cameraSize in [const Size(320, 700), const Size(640, 360)]) {
      testWidgets(
        'R5 022 native camera widget recovers inline from $condition at $cameraSize',
        (tester) async {
          await tester.binding.setSurfaceSize(cameraSize);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final previousPlatform = MobileScannerPlatform.instance;
          final platform = _CollectionScannerPlatform()
            ..failStart = condition == 'start error';
          MobileScannerPlatform.instance = platform;
          var permission = condition == 'permission denied'
              ? PermissionStatus.denied
              : condition == 'camera settings'
              ? PermissionStatus.permanentlyDenied
              : PermissionStatus.granted;
          var permissionRequests = 0;
          var settingsRequests = 0;
          const channel = MethodChannel(
            'flutter.baseflow.com/permissions/methods',
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (call) async {
              switch (call.method) {
                case 'requestPermissions':
                  permissionRequests++;
                  return {Permission.camera.value: permission.index};
                case 'checkPermissionStatus':
                  return permission.index;
                case 'openAppSettings':
                  settingsRequests++;
                  return true;
                default:
                  throw UnsupportedError(
                    'Unexpected permission method in camera test',
                  );
              }
            },
          );
          addTearDown(() async {
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              channel,
              null,
            );
            MobileScannerPlatform.instance = previousPlatform;
            await platform.captures.close();
          });
          final h = (await tester.runAsync(_CollectionHarness.create))!;
          await tester.pumpWidget(
            _collectionTestApp(h, 2, onCamera: (_) {}, nativeCamera: true),
          );
          await tester.pumpAndSettle();
          expect(permissionRequests, 0);
          final scan = find.byKey(const ValueKey('buy-collection-scan'));
          await _collectionReveal(tester, scan);
          await tester.tap(scan);
          await tester.pumpAndSettle();
          if (condition == 'runtime error') {
            final controller = tester
                .widget<MobileScanner>(find.byType(MobileScanner))
                .controller!;
            controller.value = controller.value.copyWith(
              error: const MobileScannerException(
                errorCode: MobileScannerErrorCode.genericError,
              ),
            );
            await tester.pumpAndSettle();
          }
          expect(permissionRequests, 1);
          final recoveryLabel = condition == 'camera settings'
              ? 'Open camera settings'
              : condition == 'permission denied'
              ? 'Allow camera'
              : 'Retry camera';
          final recovery = find.widgetWithText(TextButton, recoveryLabel);
          await _collectionReveal(tester, recovery);
          expect(tester.getSize(recovery).height, greaterThanOrEqualTo(44));
          await _captureCollection(
            tester,
            '${condition.replaceAll(' ', '-')}-${cameraSize.width.toInt()}',
          );
          permission = PermissionStatus.granted;
          platform.failStart = false;
          await tester.tap(recovery);
          await tester.pumpAndSettle();
          if (condition == 'camera settings') {
            expect(settingsRequests, 1);
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pumpAndSettle();
          }
          final controller = tester
              .widget<MobileScanner>(find.byType(MobileScanner))
              .controller!;
          expect(controller.value.isRunning, isTrue);
          expect(controller.value.error, isNull);
          final previewBounds = tester.getRect(
            find.byKey(const ValueKey('buy-collection-camera-preview')),
          );
          final viewportBounds = tester.getRect(_collectionScroll());
          expect(
            previewBounds.top,
            greaterThanOrEqualTo(viewportBounds.top - .1),
          );
          expect(
            previewBounds.bottom,
            lessThanOrEqualTo(viewportBounds.bottom + .1),
          );
          expect(platform.starts.last.formats, [BarcodeFormat.qrCode]);
          if (condition == 'runtime error') {
            final startsBeforePause = platform.starts.length;
            final stopsBeforePause = platform.stops;
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            await tester.pumpAndSettle();
            expect(platform.stops, greaterThan(stopsBeforePause));
            platform.captures.add(
              BarcodeCapture(
                barcodes: [
                  const Barcode(
                    format: BarcodeFormat.qrCode,
                    rawValue: 'background-QR',
                  ),
                ],
              ),
            );
            await tester.pumpAndSettle();
            expect(
              h.gateway.requests.where(
                (r) => r.operation == ScanPickOperation.authorise,
              ),
              isEmpty,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pumpAndSettle();
            expect(platform.starts.length, greaterThan(startsBeforePause));
          }
          expect(find.text('Enter code'), findsNothing);
          expect(find.text('Scan now'), findsNothing);
          platform.captures.add(
            BarcodeCapture(
              barcodes: [
                const Barcode(
                  format: BarcodeFormat.code128,
                  rawValue: 'not-a-QR',
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();
          expect(
            h.gateway.requests.where(
              (r) => r.operation == ScanPickOperation.authorise,
            ),
            isEmpty,
          );
          platform.captures.add(
            BarcodeCapture(
              barcodes: [
                const Barcode(
                  format: BarcodeFormat.qrCode,
                  rawValue: ' raw-order-QR ',
                ),
                const Barcode(
                  format: BarcodeFormat.qrCode,
                  rawValue: 'duplicate',
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();
          final mutations = h.gateway.requests
              .where((r) => r.operation == ScanPickOperation.authorise)
              .toList();
          expect(mutations, hasLength(1));
          expect(mutations.single.qrPayload, ' raw-order-QR ');
          expect(
            h.session.collectionStatusLabelFor('collection-1'),
            'Matched · awaiting handover',
          );
          expect(platform.stops, greaterThanOrEqualTo(1));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );
    }
  }
}

class _DelayedCollectionPending extends _CollectionPendingMemory {
  bool delayReservation = false;
  final releaseReservation = Completer<void>();
  Completer<void>? _reservationSettled;

  @override
  Future<bool> reserve(BuyV2CollectionPendingIntent intent) async {
    if (!delayReservation) return super.reserve(intent);
    _reservationSettled = Completer<void>();
    try {
      await releaseReservation.future;
      return await super.reserve(intent);
    } finally {
      _reservationSettled!.complete();
    }
  }

  @override
  Future<BuyV2CollectionPendingIntent?> read({
    required String accountId,
    required String orderId,
    required String storeId,
  }) async {
    await _reservationSettled?.future;
    return super.read(accountId: accountId, orderId: orderId, storeId: storeId);
  }
}

class _CollectionGateway implements ScanPickGateway {
  _CollectionGateway(this.journal);
  final _CollectionPendingMemory journal;
  final requests = <ScanPickRequest>[];
  Future<ScanPickResult> Function(ScanPickRequest)? respond;
  ScanPickState _currentState = ScanPickState.awaitingCustomer;

  @override
  Future<ScanPickResult> execute(ScanPickRequest request) async {
    requests.add(request);
    if (request.operation == ScanPickOperation.authorise) {
      // This callback can execute during a guarded WidgetTester frame pump.
      expectSync(journal.pending?.operationId, request.operationId);
      expectSync(
        journal.pending?.requestFingerprint,
        matches(r'^[a-f0-9]{64}$'),
      );
    }
    if (respond != null) return respond!(request);
    switch (request.operation) {
      case ScanPickOperation.read:
        break;
      case ScanPickOperation.authorise || ScanPickOperation.reconcile:
        _currentState = ScanPickState.matched;
      case ScanPickOperation.issueChallenge || ScanPickOperation.handOver:
        throw UnsupportedError(
          'Unexpected retailer operation in consumer test',
        );
    }
    return _collectionReply(request, state: _currentState);
  }
}

ScanPickResult _collectionReply(
  ScanPickRequest request, {
  ScanPickState state = ScanPickState.awaitingCustomer,
  ScanPickOutcome outcome = ScanPickOutcome.snapshot,
  ScanPickError? error,
  Map<String, Object?> changes = const {},
  String? requestId,
  String? operationId,
}) {
  const now = '2026-09-07T12:00:00Z';
  final snapshot = <String, Object?>{
    'purpose': scanPickPurpose,
    'orderId': 'collection-1',
    'storeId': 'store-1',
    'purchaserAccountId': 'customer-1',
    'customerName': 'Sample customer',
    'storeName': 'Sample neighbourhood store',
    'revision': 'opaque-revision-A',
    'serverTime': now,
    'state': state.name,
    'payment': 'paid',
    'readiness': state == ScanPickState.preparing ? 'preparing' : 'ready',
    'currency': 'INR',
    'totalMinor': 12345,
    'lines': [
      {
        'lineId': 'purchased-line-1',
        'productId': 's-tomato',
        'skuId': 'tomato-1kg',
        'name': 'Tomatoes',
        'pack': '1 kg',
        'quantity': '1.25',
        'amountMinor': 12345,
      },
    ],
    if (state == ScanPickState.awaitingCustomer)
      'challenge': {'id': 'challenge-A', 'expiresAt': '2026-09-07T12:01:00Z'},
    if (state == ScanPickState.matched)
      'approval': {'id': 'approval-A', 'expiresAt': '2026-09-07T12:01:00Z'},
    if (state == ScanPickState.collected)
      'receipt': {
        'id': 'collection-receipt-A',
        'collectedAt': now,
        'invoiceReference': 'invoice-A',
      },
    ...changes,
  };
  return ScanPickResult.fromJson({
    'protocolVersion': scanPickProtocolVersion,
    'requestId': requestId ?? request.requestId,
    'operation': request.operation.name,
    if (request.operationId != null)
      'operationId': operationId ?? request.operationId,
    'outcome': outcome.name,
    if (outcome != ScanPickOutcome.unknown) 'snapshot': snapshot,
    if (error != null) 'error': error.name,
  });
}

final class _CollectionOrderCommerce implements BuyV2CommerceAdapter {
  _CollectionOrderCommerce(this.order);
  final BuyV2Order order;

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    orders: [order],
  );

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: true,
        customerMessage: '',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected commerce call in collection test');
}

class _CollectionHarness {
  _CollectionHarness(_CollectionPendingMemory? journal)
    : journal = journal ?? _CollectionPendingMemory();
  final _CollectionPendingMemory journal;
  final core = BuySession();
  final identity = ValueNotifier<BuyV2CollectionIdentity?>(
    const BuyV2CollectionIdentity(
      accountId: 'customer-1',
      sessionId: 'login-1',
    ),
  );
  late final _CollectionGateway gateway = _CollectionGateway(journal);
  late final BuyV2Session session;
  bool disposed = false;

  static Future<_CollectionHarness> create({
    _CollectionPendingMemory? journal,
    bool connected = true,
  }) async {
    final h = _CollectionHarness(journal);
    final product = BuyV2Catalogue.allProducts.firstWhere(
      (value) => value.id == 's-tomato',
    );
    h.session = BuyV2Session(
      core: h.core,
      reviewDataEnabled: false,
      collectionGateway: connected ? h.gateway : null,
      collectionIdentity: h.identity,
      collectionPendingStore: connected ? h.journal : null,
      commerceAdapter: _CollectionOrderCommerce(
        BuyV2Order(
          id: 'collection-1',
          collection: const BuyV2CollectionOrderReference(
            storeId: 'store-1',
            purchaserAccountId: 'customer-1',
          ),
          destination: BuyV2Destination.shop,
          title: 'Sample store order',
          itemSummary: 'Tomatoes',
          total: 124,
          partner: 'Sample neighbourhood store',
          partnerType: 'Retailer',
          promise: 'Collect at store',
          destinationLabel: 'Store counter',
          progress: .4,
          status: BuyV2OrderStatus.preparing,
          purchaseId: 'purchase-1',
          lines: [BuyV2CartLine(product: product, quantity: 1)],
        ),
      ),
    );
    addTearDown(h.dispose);
    await h.session.restoreCommerce();
    expect(h.session.openTracking('collection-1'), isTrue);
    await h.idle();
    return h;
  }

  Future<void> idle() async {
    await Future<void>.delayed(Duration.zero);
    expect(session.collectionBusy('collection-1'), isFalse);
  }

  void dispose() {
    if (disposed) return;
    disposed = true;
    session.dispose();
    identity.dispose();
    core.dispose();
  }
}

void _collectionSessionCases() {
  test(
    'R5 022 paid collection uses exact purchased facts and server receipt',
    () async {
      final h = await _CollectionHarness.create();
      expect(h.session.canScanCollection('collection-1'), isTrue);
      expect(
        h.session.collectionSnapshotFor('collection-1')!.totalMinor,
        12345,
      );
      expect(
        h.session.collectionSnapshotFor('collection-1')!.lines.single.quantity,
        '1.25',
      );
      expect(h.session.activeQuickDeliveryOrder, isNull);
      expect(h.session.activeQuietDeliveryOrder, isNull);
      expect(h.session.activeOrderCount, 1);
      expect(
        await h.session.authoriseCollection('collection-1', ' opaque-QR '),
        isTrue,
      );
      final request = h.gateway.requests.last;
      expect(request.operation, ScanPickOperation.authorise);
      expect(request.qrPayload, ' opaque-QR ');
      expect(request.expectedRevision, 'opaque-revision-A');
      expect(h.journal.pending, isNull);
      expect(h.session.canScanCollection('collection-1'), isFalse);
      expect(
        h.session.collectionStatusLabelFor('collection-1'),
        'Matched · awaiting handover',
      );
      expect(h.session.orderIsCompleted(h.session.orders.single), isFalse);
      h.gateway.respond = (request) async =>
          _collectionReply(request, state: ScanPickState.collected);
      expect(await h.session.refreshOrder('collection-1'), isTrue);
      expect(
        h.session.collectionSnapshotFor('collection-1')!.receipt!.id,
        'collection-receipt-A',
      );
      expect(h.session.activeOrderCount, 0);
      expect(h.session.deliveredOrderCount, 1);
      expect(
        h.gateway.requests.any(
          (r) => r.operation == ScanPickOperation.handOver,
        ),
        isFalse,
      );
    },
  );

  for (final fault in [
    'wrong order',
    'wrong store',
    'wrong purchaser',
    'wrong request',
    'wrong operation',
    'retailer token',
    'wrong purpose',
  ]) {
    test('R5 022 rejects $fault in an authorisation reply', () async {
      final h = await _CollectionHarness.create();
      h.gateway.respond = (request) async => _collectionReply(
        request,
        state: fault == 'retailer token'
            ? ScanPickState.awaitingCustomer
            : ScanPickState.matched,
        requestId: fault == 'wrong request' ? 'different-request' : null,
        operationId: fault == 'wrong operation' ? 'different-operation' : null,
        changes: {
          if (fault == 'wrong order') 'orderId': 'collection-2',
          if (fault == 'wrong store') 'storeId': 'store-2',
          if (fault == 'wrong purchaser') 'purchaserAccountId': 'customer-2',
          if (fault == 'wrong purpose') 'purpose': 'bikerDelivery',
          if (fault == 'retailer token')
            'challenge': {
              'id': 'challenge-A',
              'expiresAt': '2026-09-07T12:01:00Z',
              'qrPayload': 'retailer-only-token',
            },
        },
      );
      expect(
        await h.session.authoriseCollection('collection-1', 'opaque-QR'),
        isFalse,
      );
      expect(h.journal.pending, isNotNull);
      expect(h.session.collectionReconciliationPending('collection-1'), isTrue);
      expect(h.session.canScanCollection('collection-1'), isFalse);
      expect(
        h.session.collectionStatusLabelFor('collection-1'),
        'Checking collection',
      );
      expect(h.session.orderIsCompleted(h.session.orders.single), isFalse);
    });
  }

  for (final outcome in ['unknown', 'network']) {
    test(
      'R5 022 $outcome reconciles original intent after process restart',
      () async {
        final h = await _CollectionHarness.create();
        h.gateway.respond = (request) async {
          if (outcome == 'network') throw StateError('Test transport failed');
          return _collectionReply(request, outcome: ScanPickOutcome.unknown);
        };
        expect(
          await h.session.authoriseCollection('collection-1', 'opaque-QR'),
          isFalse,
        );
        final original = h.journal.pending!;
        expect(
          await h.session.authoriseCollection('collection-1', 'different-QR'),
          isFalse,
        );
        expect(
          h.gateway.requests.where(
            (r) => r.operation == ScanPickOperation.authorise,
          ),
          hasLength(1),
        );
        h.dispose();
        final resumed = await _CollectionHarness.create(journal: h.journal);
        expect(
          resumed.gateway.requests.single.operation,
          ScanPickOperation.reconcile,
        );
        expect(
          resumed.gateway.requests.single.operationId,
          original.operationId,
        );
        expect(resumed.gateway.requests.single.qrPayload, isNull);
        expect(resumed.journal.pending, isNull);
        expect(
          resumed.session.collectionStatusLabelFor('collection-1'),
          'Matched · awaiting handover',
        );
      },
    );
  }

  test(
    'R5 022 missing journal record cannot clear an already uncertain scan',
    () async {
      final h = await _CollectionHarness.create();
      h.gateway.respond = (r) async =>
          _collectionReply(r, outcome: ScanPickOutcome.unknown);
      await h.session.authoriseCollection('collection-1', 'opaque-QR');
      final operation = h.journal.pending!.operationId;
      h.journal.pending = null;
      await h.session.refreshCollectionOrder('collection-1');
      expect(h.gateway.requests.last.operation, ScanPickOperation.reconcile);
      expect(h.gateway.requests.last.operationId, operation);
      expect(h.session.canScanCollection('collection-1'), isFalse);
    },
  );

  test(
    'R5 022 serializes duplicate detections and does not retry a mutation',
    () async {
      final h = await _CollectionHarness.create();
      final reply = Completer<ScanPickResult>();
      h.gateway.respond = (_) => reply.future;
      final first = h.session.authoriseCollection('collection-1', 'opaque-QR');
      await Future<void>.delayed(Duration.zero);
      expect(
        await h.session.authoriseCollection('collection-1', 'opaque-QR'),
        isFalse,
      );
      final request = h.gateway.requests.last;
      expect(
        h.gateway.requests.where(
          (r) => r.operation == ScanPickOperation.authorise,
        ),
        hasLength(1),
      );
      reply.complete(_collectionReply(request, state: ScanPickState.matched));
      expect(await first, isTrue);
    },
  );

  for (final change in ['Back', 'account', 'new login', 'background']) {
    test('R5 022 discards delayed scan reply after $change', () async {
      final h = await _CollectionHarness.create();
      final reply = Completer<ScanPickResult>();
      h.gateway.respond = (r) => r.operation == ScanPickOperation.authorise
          ? reply.future
          : Future.value(_collectionReply(r, outcome: ScanPickOutcome.unknown));
      final first = h.session.authoriseCollection('collection-1', 'opaque-QR');
      await Future<void>.delayed(Duration.zero);
      final request = h.gateway.requests.last;
      switch (change) {
        case 'Back':
          h.session.returnToOrders();
        case 'account':
          h.identity.value = const BuyV2CollectionIdentity(
            accountId: 'customer-2',
            sessionId: 'login-2',
          );
        case 'new login':
          h.identity.value = const BuyV2CollectionIdentity(
            accountId: 'customer-1',
            sessionId: 'login-2',
          );
        case 'background':
          h.session.pauseCollection();
      }
      reply.complete(_collectionReply(request, state: ScanPickState.matched));
      expect(await first, isFalse);
      expect(h.journal.pending?.operationId, request.operationId);
      expect(h.session.orderIsCompleted(h.session.orders.single), isFalse);
      if (change == 'account') {
        expect(h.session.visibleOrders, isEmpty);
        expect(h.session.collectionSnapshotFor('collection-1'), isNull);
      }
    });
  }

  for (final failure in ['reservation', 'read', 'clear']) {
    test(
      'R5 022 $failure failure cannot create a second scan or false success',
      () async {
        final h = await _CollectionHarness.create();
        h.journal.allowReserve = failure != 'reservation';
        h.journal.allowClear = failure != 'clear';
        h.journal.failRead = failure == 'read';
        expect(
          await h.session.authoriseCollection('collection-1', 'opaque-QR'),
          isFalse,
        );
        expect(h.session.canScanCollection('collection-1'), isFalse);
        expect(h.session.orderIsCompleted(h.session.orders.single), isFalse);
        expect(
          h.gateway.requests.where(
            (r) => r.operation == ScanPickOperation.authorise,
          ),
          hasLength(failure == 'clear' ? 1 : 0),
        );
        if (failure == 'clear') expect(h.journal.pending, isNotNull);
      },
    );
  }

  test(
    'R5 022 rejected Matched snapshot is not successful collection',
    () async {
      final h = await _CollectionHarness.create();
      h.gateway.respond = (r) async => _collectionReply(
        r,
        state: ScanPickState.matched,
        outcome: ScanPickOutcome.rejected,
        error: ScanPickError.revisionConflict,
      );
      expect(
        await h.session.authoriseCollection('collection-1', 'opaque-QR'),
        isFalse,
      );
      expect(h.session.collectionSnapshotFor('collection-1'), isNull);
      expect(h.session.canScanCollection('collection-1'), isFalse);
      expect(h.journal.pending, isNull);
    },
  );

  for (final condition in [
    'unpaid',
    'preparing',
    'expired',
    'oversize',
    'empty',
  ]) {
    test('R5 022 $condition cannot authorise collection', () async {
      final h = await _CollectionHarness.create();
      if (condition == 'unpaid' ||
          condition == 'preparing' ||
          condition == 'expired') {
        h.gateway.respond = (r) async => _collectionReply(
          r,
          state: condition == 'preparing'
              ? ScanPickState.preparing
              : condition == 'unpaid'
              ? ScanPickState.ready
              : ScanPickState.awaitingCustomer,
          changes: {
            if (condition == 'unpaid') 'payment': 'unpaid',
            if (condition == 'expired')
              'challenge': {
                'id': 'challenge-A',
                'expiresAt': '2026-09-07T11:59:59Z',
              },
          },
        );
        await h.session.refreshCollectionOrder('collection-1');
      }
      final payload = condition == 'oversize'
          ? List.filled(600, 'é').join()
          : condition == 'empty'
          ? ' '
          : 'opaque-QR';
      expect(
        await h.session.authoriseCollection('collection-1', payload),
        isFalse,
      );
      expect(
        h.gateway.requests.where(
          (r) => r.operation == ScanPickOperation.authorise,
        ),
        isEmpty,
      );
      expect(h.journal.pending, isNull);
    });
  }

  test(
    'R5 022 wrong QR guidance survives polling until a new QR or scan',
    () async {
      final h = await _CollectionHarness.create();
      h.gateway.respond = (r) async => _collectionReply(
        r,
        outcome: ScanPickOutcome.rejected,
        error: ScanPickError.wrongStore,
      );
      expect(
        await h.session.authoriseCollection('collection-1', 'wrong-store-QR'),
        isFalse,
      );
      const guidance = 'Use the QR for this order at the correct store.';
      expect(h.session.collectionMessageFor('collection-1'), guidance);
      h.gateway.respond = (r) async => _collectionReply(r);
      expect(await h.session.refreshCollectionOrder('collection-1'), isTrue);
      expect(h.session.collectionMessageFor('collection-1'), guidance);
      expect(h.session.canScanCollection('collection-1'), isTrue);
      h.gateway.respond = (r) async => _collectionReply(
        r,
        changes: {
          'challenge': {
            'id': 'replacement-QR',
            'expiresAt': '2026-09-07T12:01:00Z',
          },
        },
      );
      expect(await h.session.refreshCollectionOrder('collection-1'), isTrue);
      expect(h.session.collectionMessageFor('collection-1'), isNull);
    },
  );

  test('R5 022 response cannot clear a newer durable operation', () async {
    final h = await _CollectionHarness.create();
    final reply = Completer<ScanPickResult>();
    h.gateway.respond = (_) => reply.future;
    final submission = h.session.authoriseCollection(
      'collection-1',
      'opaque-QR',
    );
    await Future<void>.delayed(Duration.zero);
    final original = h.gateway.requests.last;
    final replacement = BuyV2CollectionPendingIntent(
      accountId: 'customer-1',
      orderId: 'collection-1',
      storeId: 'store-1',
      operationId: 'newer-operation',
      requestFingerprint: List.filled(64, 'b').join(),
    );
    h.journal.pending = replacement;
    reply.complete(_collectionReply(original, state: ScanPickState.matched));
    expect(await submission, isFalse);
    expect(identical(h.journal.pending, replacement), isTrue);
    expect(h.session.canScanCollection('collection-1'), isFalse);
    final count = h.gateway.requests.length;
    expect(await h.session.refreshCollectionOrder('collection-1'), isFalse);
    expect(h.gateway.requests, hasLength(count));
    expect(h.session.collectionReconciliationPending('collection-1'), isTrue);
  });

  test('R5 022 has no default successful collection connection', () async {
    final h = await _CollectionHarness.create(connected: false);
    expect(h.session.canScanCollection('collection-1'), isFalse);
    expect(h.session.collectionSnapshotFor('collection-1'), isNull);
    expect(h.gateway.requests, isEmpty);
  });
}

Future<BuyV2Session> _sessionWithOrder(
  _AcceptedResolutionAdapter adapter, {
  BuyV2OrderStatus status = BuyV2OrderStatus.delivered,
}) async {
  final core = BuySession();
  final session = BuyV2Session(
    core: core,
    reviewDataEnabled: false,
    orderResolutionAdapter: adapter,
    commerceAdapter: _PurchasedOrderCommerce(
      BuyV2Order(
        id: 'order-policy',
        destination: BuyV2Destination.shop,
        title: 'Purchased groceries',
        itemSummary: '2 products',
        total: 300,
        partner: 'Order store',
        partnerType: 'MoolSocial Fulfilment Store',
        promise: 'Delivered',
        destinationLabel: 'Home',
        progress: 1,
        status: status,
        lines: [
          BuyV2CartLine(
            product: BuyV2Catalogue.allProducts.firstWhere(
              (p) => p.id == 's-tomato',
            ),
            quantity: 2,
          ),
          BuyV2CartLine(
            product: BuyV2Catalogue.allProducts.firstWhere(
              (p) => p.id == 's-atta',
            ),
            quantity: 1,
          ),
        ],
      ),
    ),
  );
  addTearDown(session.dispose);
  addTearDown(core.dispose);
  await session.restoreCommerce();
  expect(session.orders.single.id, 'order-policy');
  return session;
}

final class _PurchasedOrderCommerce implements BuyV2CommerceAdapter {
  _PurchasedOrderCommerce(this.order);
  final BuyV2Order order;
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    orders: [order],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected commerce mutation in purchased-order test',
  );
}

Future<void> _tapSheet(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: key);
}

Future<void> _captureOrderPolicy(WidgetTester tester, String label) async {
  if (!const bool.fromEnvironment('BUY_R66_ORDER_POLICY_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-order-policy-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-order-policy-v2-20260906');
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Order policy capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) {
        throw StateError('Order policy capture encoding failed');
      }
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
