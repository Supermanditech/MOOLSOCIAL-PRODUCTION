import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
  group('BuyV2Session listener liveness', () {
    BuyV2Session newSession() => BuyV2Session(core: BuySession());

    final shop = BuyV2Catalogue.products.firstWhere(
      (product) => product.destination == BuyV2Destination.shop,
    );
    final wholesale = BuyV2Catalogue.products.firstWhere(
      (product) => product.destination == BuyV2Destination.wholesale,
    );
    const prescriptionId = 'm-telmisartan-40';

    void expectEmits(
      String name, {
      void Function(BuyV2Session session)? arrange,
      required void Function(BuyV2Session session) act,
    }) {
      final session = newSession();
      arrange?.call(session);
      var notifications = 0;
      session.addListener(() => notifications += 1);

      act(session);

      expect(notifications, greaterThan(0), reason: name);
      session.dispose();
    }

    void expectSilent(
      String name, {
      void Function(BuyV2Session session)? arrange,
      required void Function(BuyV2Session session) act,
    }) {
      final session = newSession();
      arrange?.call(session);
      var notifications = 0;
      session.addListener(() => notifications += 1);

      act(session);

      expect(notifications, 0, reason: name);
      session.dispose();
    }

    test('customer-visible state and navigation actions always notify', () {
      expectEmits(
        'open destination',
        act: (session) => session.openDestination(BuyV2Destination.wholesale),
      );
      expectEmits(
        'open product',
        act: (session) => session.openProduct(shop.id),
      );
      expectEmits(
        'close product',
        arrange: (session) => session.openProduct(shop.id),
        act: (session) => session.closeProduct(),
      );
      expectEmits('open empty cart', act: (session) => session.openCart());
      expectEmits(
        'open populated cart',
        arrange: (session) => session.addProduct(shop.id),
        act: (session) => session.openCart(scope: BuyV2CartScope.shop),
      );
      expectEmits(
        'open empty checkout',
        act: (session) => session.openCheckout(),
      );
      expectEmits(
        'open populated checkout',
        arrange: (session) {
          session.addProduct(shop.id);
          session.openCart(scope: BuyV2CartScope.shop);
        },
        act: (session) => session.openCheckout(),
      );
      expectEmits('open orders', act: (session) => session.openOrders());
      expectEmits(
        'direct account orders action',
        act: (session) => session.openOrdersFromAccount(),
      );
      expectEmits(
        'direct account wholesale action',
        act: (session) => session.openWholesaleFromAccount(),
      );
      expectEmits(
        'open tracking',
        act: (session) => session.openTracking('MS-240782'),
      );
      expectEmits(
        'open order items',
        act: (session) => session.openOrderItems('MS-240782'),
      );
      expectEmits(
        'toggle tracking alerts',
        act: (session) => session.toggleTrackingAlerts(),
      );
      expectEmits('open assist', act: (session) => session.openAssist());
      expectEmits(
        'close assist',
        arrange: (session) => session.openAssist(),
        act: (session) => session.closeAssist(),
      );
      expectEmits('open account', act: (session) => session.openAccount());
      expectEmits(
        'close account',
        arrange: (session) => session.openAccount(),
        act: (session) => session.closeAccount(),
      );
      expectEmits(
        'return to account',
        arrange: (session) {
          session.openAccount();
          session.openOrdersFromAccount();
        },
        act: (session) => session.returnToAccount(),
      );
      expectEmits(
        'go back',
        arrange: (session) =>
            session.openDestination(BuyV2Destination.wholesale),
        act: (session) => session.goBack(),
      );
      expectEmits(
        'show orders tab',
        act: (session) => session.showOrdersTab(BuyV2OrdersTab.delivered),
      );
      expectEmits(
        'return to catalogue',
        arrange: (session) => session.openProduct(shop.id),
        act: (session) => session.returnToCatalogue(),
      );
      expectEmits(
        'choose category',
        act: (session) =>
            session.chooseCategory(BuyV2Catalogue.shopCategories[1].id),
      );
      expectEmits(
        'update query',
        act: (session) => session.updateQuery(shop.title),
      );
      expectEmits(
        'choose filter',
        act: (session) => session.chooseFilter('nearby'),
      );
      expectEmits(
        'toggle saved',
        act: (session) => session.toggleSaved(shop.id),
      );
      expectEmits(
        'submit review',
        act: (session) => session.submitProductReview(
          productId: shop.id,
          rating: 5,
          comment: 'Synthetic liveness review.',
        ),
      );
      expectEmits(
        'report product',
        act: (session) => session.reportProduct(
          productId: shop.id,
          reason: 'Synthetic liveness reason',
        ),
      );
      expectEmits('add product', act: (session) => session.addProduct(shop.id));
      expectEmits(
        'approve saved prescription',
        act: (session) => session.approveSavedPrescription('meera'),
      );
      expectEmits(
        'attach new prescription',
        act: (session) => session.attachNewPrescription(),
      );
      expectEmits(
        'increase product',
        arrange: (session) => session.addProduct(shop.id),
        act: (session) => session.increase(shop.id),
      );
      expectEmits(
        'decrease product',
        arrange: (session) => session.addProduct(shop.id),
        act: (session) => session.decrease(shop.id),
      );
      expectEmits(
        'remove product',
        arrange: (session) => session.addProduct(shop.id),
        act: (session) => session.remove(shop.id),
      );
      expectEmits(
        'clear cart',
        arrange: (session) => session.addProduct(shop.id),
        act: (session) => session.clearCart(),
      );
      expectEmits(
        'choose cart scope',
        act: (session) => session.chooseCartScope(BuyV2CartScope.wholesale),
      );
      expectEmits(
        'choose address',
        act: (session) => session.chooseAddress('work'),
      );
      expectEmits(
        'add address',
        act: (session) => session.addAddress(
          const BuyV2Address(
            id: 'listener-test-address',
            kind: BuyV2AddressKind.other,
            label: 'Listener test',
            recipient: 'Test customer',
            phone: '0000000000',
            line: 'Test line',
            area: 'Test area',
            pinCode: '000000',
            landmark: 'Test landmark',
          ),
        ),
      );
      expectEmits(
        'choose payment',
        act: (session) => session.choosePayment('Bank transfer'),
      );
      expectEmits(
        'confirm order',
        arrange: (session) {
          session.addProduct(shop.id);
          session.openCart(scope: BuyV2CartScope.shop);
          session.openCheckout();
        },
        act: (session) => session.confirmOrder(),
      );
      expectEmits(
        'reorder',
        act: (session) => session.reorder(
          session.orders.firstWhere(
            (order) =>
                order.destination == BuyV2Destination.shop &&
                order.status == BuyV2OrderStatus.delivered,
          ),
        ),
      );
      expectEmits(
        'open recovery',
        act: (session) =>
            session.openRecovery(BuyV2RecoveryKind.networkInterruption),
      );
      expectEmits(
        'retry recovery',
        arrange: (session) =>
            session.openRecovery(BuyV2RecoveryKind.networkInterruption),
        act: (session) => session.retryRecovery(),
      );
      expectEmits(
        'clear notice',
        arrange: (session) => session.showNotice('Synthetic notice'),
        act: (session) => session.clearNotice(),
      );
      expectEmits(
        'clear cart acknowledgement',
        arrange: (session) => session.addProduct(shop.id),
        act: (session) => session.clearCartAcknowledgement(),
      );
      expectEmits(
        'show notice',
        act: (session) => session.showNotice('Synthetic notice'),
      );
    });

    test('fail-closed customer-visible actions always notify', () {
      expectEmits(
        'missing saved product',
        act: (session) => session.toggleSaved('missing-product'),
      );
      expectEmits(
        'missing product detail',
        act: (session) => session.openProduct('missing-product'),
      );
      expectEmits(
        'missing tracking order',
        act: (session) => session.openTracking('missing-order'),
      );
      expectEmits(
        'missing order items',
        act: (session) => session.openOrderItems('missing-order'),
      );
      expectEmits(
        'missing cart product',
        act: (session) => session.addProduct('missing-product'),
      );
      expectEmits(
        'unverified wholesale',
        arrange: (session) => session.businessVerified = false,
        act: (session) => session.addProduct(wholesale.id),
      );
      expectEmits(
        'prescription attachment required',
        act: (session) => session.addProduct(prescriptionId),
      );
      expectEmits(
        'prescription maximum',
        arrange: (session) {
          session.approveSavedPrescription('meera');
          session.addProduct(prescriptionId);
        },
        act: (session) => session.addProduct(prescriptionId),
      );
      expectEmits(
        'missing saved prescription',
        act: (session) =>
            session.approveSavedPrescription('missing-prescription'),
      );
      expectEmits(
        'invalid review',
        act: (session) => session.submitProductReview(
          productId: shop.id,
          rating: 0,
          comment: '',
        ),
      );
      expectEmits(
        'invalid report',
        act: (session) => session.reportProduct(productId: shop.id, reason: ''),
      );
      expectEmits(
        'missing address',
        act: (session) => session.chooseAddress('missing-address'),
      );
      expectEmits(
        'invalid payment',
        act: (session) => session.choosePayment('missing-payment'),
      );
      expectEmits('empty checkout', act: (session) => session.openCheckout());
      expectEmits(
        'empty confirmation',
        act: (session) => session.confirmOrder(),
      );
    });

    test('true no-op actions do not emit synthetic progress', () {
      expectSilent(
        'inactive account return',
        act: (session) => session.returnToAccount(),
      );
      expectSilent(
        'missing decrease',
        act: (session) => session.decrease('missing-product'),
      );
      expectSilent(
        'missing remove',
        act: (session) => session.remove('missing-product'),
      );
      expectSilent(
        'empty notice clear',
        act: (session) => session.clearNotice(),
      );
      expectSilent(
        'empty acknowledgement clear',
        act: (session) => session.clearCartAcknowledgement(),
      );
    });
  });
}
