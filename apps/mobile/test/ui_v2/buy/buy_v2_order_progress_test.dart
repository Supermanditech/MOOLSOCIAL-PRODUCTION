import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
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
