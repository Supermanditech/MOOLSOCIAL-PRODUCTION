import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

BuyV2Session _newSession() => BuyV2Session(core: BuySession());

BuyV2Product _unrestrictedProduct(BuyV2Destination destination) =>
    BuyV2Catalogue.products.firstWhere(
      (product) =>
          product.destination == destination && !product.requiresPrescription,
    );

void main() {
  group('BuyV2Session deterministic coverage', () {
    test('Orders stays category-neutral and preserves commerce selection', () {
      final session = _newSession();
      final shopCategory = BuyV2Catalogue.shopCategories[1].id;
      session.chooseCategory(shopCategory);

      session.openDestination(BuyV2Destination.orders);

      expect(session.categories, isEmpty);
      expect(session.selectedCategoryId, 'all');

      session.chooseCategory('not-an-orders-category');

      expect(session.selectedCategoryId, 'all');
      expect(session.shopCategoryId, shopCategory);
    });

    test('vertical cart projections keep exact quantities and totals', () {
      final session = _newSession();
      final products = {
        for (final destination in const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ])
          destination: _unrestrictedProduct(destination),
      };

      for (final product in products.values) {
        expect(session.addProduct(product.id), isTrue);
      }

      expect(session.itemCount, greaterThan(3));
      for (final entry in products.entries) {
        final product = entry.value;
        final expectedQuantity = product.minimumOrder;
        final expectedTotal = product.price * expectedQuantity;
        expect(session.countForDestination(entry.key), expectedQuantity);
        expect(session.totalForDestination(entry.key), expectedTotal);

        final scope = switch (entry.key) {
          BuyV2Destination.shop => BuyV2CartScope.shop,
          BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
          BuyV2Destination.medicine => BuyV2CartScope.medicine,
          BuyV2Destination.orders => BuyV2CartScope.all,
        };
        session.chooseCartScope(scope);
        expect(
          session.cartLines.every(
            (line) => line.product.destination == entry.key,
          ),
          isTrue,
        );
        expect(session.scopedItemCount, expectedQuantity);
        expect(session.scopedCartTotal, expectedTotal);
      }
    });

    test('clearing each cart scope returns to its safe catalogue', () {
      final cases = <BuyV2CartScope, BuyV2Destination>{
        BuyV2CartScope.shop: BuyV2Destination.shop,
        BuyV2CartScope.wholesale: BuyV2Destination.wholesale,
        BuyV2CartScope.medicine: BuyV2Destination.medicine,
      };

      for (final entry in cases.entries) {
        final session = _newSession();
        final product = _unrestrictedProduct(entry.value);
        expect(session.addProduct(product.id), isTrue);
        session.openCart(scope: entry.key);

        session.clearCart();

        expect(session.itemCount, 0, reason: entry.key.name);
        expect(session.destination, entry.value, reason: entry.key.name);
        expect(session.view, BuyV2View.catalogue, reason: entry.key.name);
        expect(session.cartScope, BuyV2CartScope.all, reason: entry.key.name);
        expect(session.cartAcknowledgement, isNull, reason: entry.key.name);
      }

      final allFromOrders = _newSession();
      final shop = _unrestrictedProduct(BuyV2Destination.shop);
      expect(allFromOrders.addProduct(shop.id), isTrue);
      allFromOrders.openDestination(BuyV2Destination.orders);
      allFromOrders.openCart();

      allFromOrders.clearCart();

      expect(allFromOrders.destination, BuyV2Destination.shop);
      expect(allFromOrders.view, BuyV2View.catalogue);

      final allFromShop = _newSession();
      expect(allFromShop.addProduct(shop.id), isTrue);
      allFromShop.openCart();

      allFromShop.clearCart();

      expect(allFromShop.destination, BuyV2Destination.shop);
      expect(allFromShop.view, BuyV2View.catalogue);
    });

    test('empty entries and direct account actions normalize safely', () {
      final shopCart = _newSession()..openCart();
      expect(shopCart.destination, BuyV2Destination.shop);
      expect(shopCart.view, BuyV2View.catalogue);

      final ordersCart = _newSession()
        ..openDestination(BuyV2Destination.orders)
        ..openCart();
      expect(ordersCart.destination, BuyV2Destination.shop);
      expect(ordersCart.view, BuyV2View.catalogue);

      final medicineCart = _newSession()
        ..openCart(scope: BuyV2CartScope.medicine);
      expect(medicineCart.destination, BuyV2Destination.medicine);
      expect(medicineCart.view, BuyV2View.catalogue);

      final checkout = _newSession()
        ..chooseCartScope(BuyV2CartScope.medicine)
        ..openCheckout();
      expect(checkout.view, BuyV2View.catalogue);
      expect(checkout.notice, 'Choose a product to continue.');

      final directOrders = _newSession()..openOrdersFromAccount();
      expect(directOrders.destination, BuyV2Destination.orders);
      expect(directOrders.view, BuyV2View.catalogue);
      expect(directOrders.canReturnToAccount, isFalse);

      final directWholesale = _newSession()..openWholesaleFromAccount();
      expect(directWholesale.destination, BuyV2Destination.wholesale);
      expect(directWholesale.view, BuyV2View.catalogue);
      expect(directWholesale.canReturnToAccount, isFalse);

      final repeatedAccount = _newSession()
        ..openAccount()
        ..openOrdersFromAccount()
        ..openAccount();
      expect(repeatedAccount.view, BuyV2View.account);
      expect(repeatedAccount.canReturnToAccount, isFalse);
    });

    test('wholesale and prescription limits fail closed', () {
      final wholesaleSession = _newSession()..businessVerified = false;
      final wholesale = _unrestrictedProduct(BuyV2Destination.wholesale);

      expect(wholesaleSession.addProduct(wholesale.id), isFalse);
      expect(wholesaleSession.quantityFor(wholesale.id), 0);
      expect(
        wholesaleSession.notice,
        'Complete your Workspace business profile to place a wholesale order.',
      );

      const prescriptionId = 'm-telmisartan-40';
      final prescriptionSession = _newSession();
      expect(prescriptionSession.addProduct(prescriptionId), isFalse);
      expect(prescriptionSession.pendingPrescriptionProductId, prescriptionId);

      expect(prescriptionSession.attachNewPrescription(), isTrue);
      expect(prescriptionSession.quantityFor(prescriptionId), 1);
      expect(prescriptionSession.prescriptionMaximumFor(prescriptionId), 1);

      expect(prescriptionSession.addProduct(prescriptionId), isFalse);
      expect(prescriptionSession.quantityFor(prescriptionId), 1);
      expect(
        prescriptionSession.notice,
        contains('Prescription quantity reached'),
      );
    });

    test(
      'explicit Wholesale and Medicine reorders restore their own scopes',
      () {
        final cases = <BuyV2Destination, BuyV2CartScope>{
          BuyV2Destination.wholesale: BuyV2CartScope.wholesale,
          BuyV2Destination.medicine: BuyV2CartScope.medicine,
        };

        for (final entry in cases.entries) {
          final session = _newSession();
          final product = _unrestrictedProduct(entry.key);
          final order = BuyV2Order(
            id: 'TEST-${entry.key.name}',
            destination: entry.key,
            title: '${entry.key.label} test order',
            itemSummary: 'Synthetic test order',
            total: product.price * product.minimumOrder,
            partner: product.seller,
            partnerType: product.partnerRole,
            promise: product.deliveryPromise,
            destinationLabel: 'Test area · 000000',
            progress: 1,
            status: BuyV2OrderStatus.delivered,
            productIds: [product.id],
          );

          expect(session.reorder(order), isTrue, reason: entry.key.name);
          expect(session.destination, entry.key, reason: entry.key.name);
          expect(session.view, BuyV2View.cart, reason: entry.key.name);
          expect(session.cartScope, entry.value, reason: entry.key.name);
          expect(session.cartLines.map((line) => line.product.id), [
            product.id,
          ]);
        }
      },
    );

    test('back navigation retains cart, order and recovery depth', () {
      final session = _newSession();
      final shop = _unrestrictedProduct(BuyV2Destination.shop);
      expect(session.addProduct(shop.id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);

      session.goBack();
      expect(session.view, BuyV2View.catalogue);

      session.openCart(scope: BuyV2CartScope.shop);
      session.openCheckout();
      session.goBack();
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.shop);

      session.openCheckout();
      session.confirmOrder();
      expect(session.view, BuyV2View.confirmation);
      final confirmed = session.confirmedOrders.single;
      expect(session.productsForOrder(confirmed).map((product) => product.id), [
        shop.id,
      ]);

      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);

      expect(session.openOrderItems(confirmed.id), isTrue);
      session.goBack();
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, confirmed.id);

      final recoveryWithCart = _newSession();
      expect(recoveryWithCart.addProduct(shop.id), isTrue);
      recoveryWithCart.openRecovery(BuyV2RecoveryKind.paymentFailed);
      recoveryWithCart.retryRecovery();
      expect(recoveryWithCart.view, BuyV2View.catalogue);
      expect(recoveryWithCart.notice, isNull);

      recoveryWithCart.openRecovery(BuyV2RecoveryKind.networkInterruption);
      recoveryWithCart.goBack();
      expect(recoveryWithCart.view, BuyV2View.catalogue);

      final emptyRecovery = _newSession()
        ..openRecovery(BuyV2RecoveryKind.networkInterruption)
        ..goBack();
      expect(emptyRecovery.destination, BuyV2Destination.shop);
      expect(emptyRecovery.view, BuyV2View.catalogue);

      emptyRecovery.openRecovery(BuyV2RecoveryKind.networkInterruption);
      emptyRecovery.retryRecovery();
      expect(emptyRecovery.destination, BuyV2Destination.shop);
      expect(emptyRecovery.view, BuyV2View.catalogue);
      expect(emptyRecovery.notice, isNull);
    });

    test('final removal and a synthetic address preserve exact state', () {
      final session = _newSession();
      final medicine = _unrestrictedProduct(BuyV2Destination.medicine);
      session.openDestination(BuyV2Destination.medicine);
      expect(session.addProduct(medicine.id), isTrue);
      session.openCart(scope: BuyV2CartScope.medicine);

      session.remove(medicine.id);

      expect(session.itemCount, 0);
      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.catalogue);
      expect(session.cartScope, BuyV2CartScope.all);

      const address = BuyV2Address(
        id: 'test-address',
        kind: BuyV2AddressKind.other,
        label: 'Test address',
        recipient: 'Test customer',
        phone: '0000000000',
        line: 'Test line',
        area: 'Test area',
        pinCode: '000000',
        landmark: 'Test landmark',
      );
      session.addAddress(address);

      expect(session.selectedAddressId, address.id);
      expect(session.selectedAddress, same(address));
      expect(session.notice, 'Delivering to Test area · 000000');

      session.clearNotice();
      expect(session.notice, isNull);
    });
  });
}
