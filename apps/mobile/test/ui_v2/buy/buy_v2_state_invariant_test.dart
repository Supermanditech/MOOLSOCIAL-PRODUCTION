import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
  group('Buy V2 deterministic state invariants', () {
    BuyV2Session createSession() => BuyV2Session(core: BuySession());

    test('all unrestricted offers preserve quantity and total floors', () {
      final availability = createSession();
      addTearDown(availability.dispose);
      final products = BuyV2Catalogue.products.where((product) {
        final facts = availability.productFactsFor(product);
        return !product.requiresPrescription &&
            facts.storeOperatingState != BuyV2StoreOperatingState.closed &&
            !facts.orderabilityLabel.toLowerCase().contains('unavailable');
      });

      for (final product in products) {
        final session = createSession();

        expect(session.addProduct(product.id), isTrue, reason: product.id);
        expect(
          session.quantityFor(product.id),
          product.minimumOrder,
          reason: product.id,
        );
        expect(session.itemCount, product.minimumOrder, reason: product.id);
        expect(
          session.cartTotal,
          product.price * product.minimumOrder,
          reason: product.id,
        );

        session.increase(product.id);
        expect(
          session.quantityFor(product.id),
          product.minimumOrder + 1,
          reason: product.id,
        );

        session.decrease(product.id);
        expect(
          session.quantityFor(product.id),
          product.minimumOrder,
          reason: product.id,
        );

        session.decrease(product.id);
        session.decrease(product.id);
        session.remove(product.id);
        expect(session.quantityFor(product.id), 0, reason: product.id);
        expect(session.itemCount, 0, reason: product.id);
        expect(session.cartTotal, 0, reason: product.id);
      }
    });

    test('every prescription offer fails closed before a matched approval', () {
      final products = BuyV2Catalogue.products.where(
        (product) => product.requiresPrescription,
      );

      expect(products, isNotEmpty);
      for (final product in products) {
        final session = createSession();

        expect(session.addProduct(product.id), isFalse, reason: product.id);
        expect(
          session.pendingPrescriptionProductId,
          product.id,
          reason: product.id,
        );
        expect(session.quantityFor(product.id), 0, reason: product.id);
        expect(session.itemCount, 0, reason: product.id);

        session.increase(product.id);
        session.decrease(product.id);
        session.remove(product.id);
        expect(session.quantityFor(product.id), 0, reason: product.id);
        expect(session.itemCount, 0, reason: product.id);
        expect(session.cartTotal, 0, reason: product.id);
      }
    });

    test('invalid external inputs cannot mutate established valid state', () {
      final session = createSession();
      final product = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );

      expect(session.addProduct(product.id), isTrue);
      expect(
        session.submitProductReview(
          productId: product.id,
          rating: 4,
          comment: 'Packaging was intact.',
        ),
        isTrue,
      );
      expect(
        session.reportProduct(
          productId: product.id,
          reason: 'Incorrect pack information',
        ),
        isTrue,
      );
      expect(session.chooseAddress('work'), isTrue);
      expect(session.choosePayment('Purchase order'), isTrue);

      final itemCount = session.itemCount;
      final cartTotal = session.cartTotal;
      final review = session.customerReviewFor(product.id);
      final wasSaved = session.isSaved(product.id);

      expect(session.openProduct('missing-product'), isFalse);
      expect(session.addProduct('missing-product'), isFalse);
      session.increase('missing-product');
      session.decrease('missing-product');
      session.remove('missing-product');
      session.toggleSaved('missing-product');
      expect(session.openOrderItems('missing-order'), isFalse);
      expect(session.openTracking('missing-order'), isFalse);
      expect(session.chooseAddress('missing-address'), isFalse);
      expect(session.choosePayment('UPI<script>'), isFalse);
      expect(
        session.submitProductReview(
          productId: 'missing-product',
          rating: 5,
          comment: 'Must not attach to another offer.',
        ),
        isFalse,
      );
      expect(
        session.submitProductReview(
          productId: product.id,
          rating: 6,
          comment: 'Must not replace the valid review.',
        ),
        isFalse,
      );
      expect(
        session.reportProduct(
          productId: 'missing-product',
          reason: 'Must not attach to another offer.',
        ),
        isFalse,
      );

      expect(() => session.product('missing-product'), throwsArgumentError);
      expect(session.itemCount, itemCount);
      expect(session.cartTotal, cartTotal);
      expect(session.quantityFor(product.id), 1);
      expect(session.isSaved(product.id), wasSaved);
      expect(session.customerReviewFor(product.id)?.rating, review?.rating);
      expect(session.customerReviewFor(product.id)?.comment, review?.comment);
      expect(session.hasReportedProduct(product.id), isTrue);
      expect(session.selectedAddressId, 'work');
      expect(session.selectedPayment, 'Purchase order');
    });

    test('checkout views are immutable and confirmation is single-use', () {
      final session = createSession();
      final products = [
        BuyV2Catalogue.products.firstWhere(
          (product) => product.destination == BuyV2Destination.shop,
        ),
        BuyV2Catalogue.products.firstWhere(
          (product) => product.destination == BuyV2Destination.wholesale,
        ),
        BuyV2Catalogue.products.firstWhere(
          (product) =>
              product.destination == BuyV2Destination.medicine &&
              !product.requiresPrescription,
        ),
      ];
      for (final product in products) {
        expect(session.addProduct(product.id), isTrue, reason: product.id);
      }

      session.openCart();
      session.openCheckout();
      final checkoutItemCount = session.checkoutItemCount;
      final checkoutTotal = session.checkoutTotal;
      final groups = session.checkoutFulfilmentGroups;

      expect(() => session.checkoutLines.clear(), throwsUnsupportedError);
      expect(
        () => session.checkoutDestinations.add(BuyV2Destination.orders),
        throwsUnsupportedError,
      );
      expect(() => groups.first.lines.clear(), throwsUnsupportedError);
      expect(session.checkoutItemCount, checkoutItemCount);
      expect(session.checkoutTotal, checkoutTotal);

      final orderCountBefore = session.orders.length;
      session.confirmOrder();
      final confirmed = session.confirmedOrders;
      final createdCount = confirmed.length;

      expect(createdCount, groups.length);
      expect(session.orders.length, orderCountBefore + createdCount);
      expect(() => confirmed.clear(), throwsUnsupportedError);
      expect(
        () => session.confirmedDestinations.add(BuyV2Destination.orders),
        throwsUnsupportedError,
      );

      session.confirmOrder();
      expect(session.orders.length, orderCountBefore + createdCount);
      expect(session.confirmedOrders, confirmed);
      expect(session.itemCount, 0);
    });

    test('repeated vertical traversal cannot leak transient search state', () {
      final session = createSession();
      final categoryByDestination = <BuyV2Destination, String>{
        BuyV2Destination.shop: BuyV2Catalogue.shopCategories[1].id,
        BuyV2Destination.wholesale: BuyV2Catalogue.wholesaleCategories[2].id,
        BuyV2Destination.medicine: BuyV2Catalogue.medicineCategories[1].id,
      };

      for (var cycle = 0; cycle < 12; cycle += 1) {
        for (final entry in categoryByDestination.entries) {
          session.openDestination(entry.key);
          expect(session.query, isEmpty, reason: '${entry.key.name} $cycle');
          expect(
            session.selectedFilter,
            isNull,
            reason: '${entry.key.name} $cycle',
          );
          if (cycle == 0) {
            session.chooseCategory(entry.value);
          }
          expect(
            session.selectedCategoryId,
            entry.value,
            reason: '${entry.key.name} $cycle',
          );
          session.updateQuery('cycle-$cycle-${entry.key.name}');
          session.chooseFilter('cycle-$cycle-filter');
        }
      }

      for (final entry in categoryByDestination.entries) {
        session.openDestination(entry.key);
        expect(session.selectedCategoryId, entry.value);
        expect(session.query, isEmpty);
        expect(session.selectedFilter, isNull);
      }
    });
  });
}
