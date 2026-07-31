import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

BuyV2Session _newSession() => BuyV2Session(core: BuySession());

BuyV2Product _shopProduct() => BuyV2Catalogue.products.firstWhere(
  (product) =>
      product.destination == BuyV2Destination.shop &&
      !product.requiresPrescription,
);

void main() {
  group('Buy V2 selected-record ownership', () {
    test('address and order projections cannot mutate session records', () {
      final session = _newSession();
      final addressCount = session.addresses.length;
      final orderCount = session.orders.length;

      expect(
        () => session.addresses.add(session.addresses.first),
        throwsUnsupportedError,
      );
      expect(() => session.orders.removeAt(0), throwsUnsupportedError);
      expect(session.addresses.length, addressCount);
      expect(session.orders.length, orderCount);
    });

    test('stale address never substitutes another saved address', () {
      final session = _newSession();
      final product = _shopProduct();
      expect(session.addProduct(product.id), isTrue);
      session.openCart();
      final orderCount = session.orders.length;

      expect(session.restoreSelectedAddressId('missing-address'), isFalse);
      expect(session.selectedAddressId, isNull);
      expect(session.selectedAddressOrNull, isNull);
      expect(() => session.selectedAddress, throwsStateError);
      expect(session.openCheckout(), isFalse);
      expect(session.view, BuyV2View.cart);
      expect(session.notice, 'Choose a delivery address to continue.');
      expect(session.confirmOrder(), isFalse);
      expect(session.itemCount, product.minimumOrder);
      expect(session.orders.length, orderCount);

      expect(session.chooseAddress('home'), isTrue);
      expect(session.selectedAddress.id, 'home');
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      expect(session.orders.length, greaterThan(orderCount));
    });

    test('stale order recovers to Orders without first-record fallback', () {
      final session = _newSession();
      expect(session.openTracking('MS-240782'), isTrue);
      expect(session.selectedOrder.id, 'MS-240782');

      expect(session.restoreSelectedOrderId('missing-order'), isFalse);
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);
      expect(session.selectedOrderId, isNull);
      expect(session.selectedOrderOrNull, isNull);
      expect(() => session.selectedOrder, throwsStateError);
      expect(session.notice, 'This order could not be found.');

      expect(session.restoreSelectedOrderId('RX-240784'), isTrue);
      expect(session.selectedOrder.id, 'RX-240784');
      expect(session.openOrderItems('RX-240784'), isTrue);
      expect(session.selectedOrder.id, 'RX-240784');
    });

    test('account return fails closed if its order selection is stale', () {
      final session = _newSession();
      expect(session.openTracking('PO-240783'), isTrue);
      session.openAccount();
      expect(session.view, BuyV2View.account);

      expect(session.restoreSelectedOrderId('removed-order'), isFalse);
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);
      expect(session.notice, 'This order could not be found.');
    });
  });
}
