import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

class _R66TrackingSession extends BuyV2Session {
  _R66TrackingSession({required super.core, required this.order});
  final BuyV2Order order;

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
  Widget app(BuyV2Session session, double scale) => RepaintBoundary(
    key: const ValueKey('r66-order-state-app-capture'),
    child: MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 24, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
        ),
        child: child!,
      ),
      home: BuyV2Screen(session: session),
    ),
  );

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('BUY_R66_ORDER_STATE_CAPTURE')) {
      return;
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-order-state-app-capture')),
    );
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final directory = Directory('build/r66-order-state-v1-20260905');
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
  }

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
            final open = find.byKey(
              const ValueKey('buy-quick-delivery-open-minimized'),
            );
            expect(tester.getSize(open).height, greaterThanOrEqualTo(44));
            final semantics = tester.ensureSemantics();
            late String announcement;
            try {
              announcement = tester.getSemantics(open).getSemanticsData().label;
            } finally {
              semantics.dispose();
            }
            expect(announcement, contains('Delivery in 12 min · by 6:35 PM'));
            expect(announcement, isNot(contains('Delivered')));
            final labels = find.descendant(
              of: bar,
              matching: find.byType(Text),
            );
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
                    'bar=${tester.getSize(bar).width} expand=${tester.getSize(find.byKey(const ValueKey('buy-quick-delivery-expand'))).width}',
              );
            }
            final expand = find.byKey(
              const ValueKey('buy-quick-delivery-expand'),
            );
            expect(tester.getSize(expand).height, greaterThanOrEqualTo(44));
            expect(tester.getSize(bar).width, lessThanOrEqualTo(304));
            await capture(tester, 'active-${status.name}-$scale-collapsed');
            await tester.tap(expand);
            await tester.pumpAndSettle();
            expect(
              find.textContaining('Delivery in 12 min · by 6:35 PM'),
              findsOneWidget,
            );
            await capture(tester, 'active-${status.name}-$scale-expanded');
            final hide = find.byKey(const ValueKey('buy-quick-delivery-hide'));
            await tester.tap(hide);
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('buy-quick-delivery-restore')),
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
