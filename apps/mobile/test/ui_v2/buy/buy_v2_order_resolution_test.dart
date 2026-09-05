import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_order_resolution_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
