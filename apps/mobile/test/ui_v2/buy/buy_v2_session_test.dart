import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
  group('BuyV2Session approved contract', () {
    late BuyV2Session session;

    setUp(() {
      session = BuyV2Session(core: BuySession());
    });

    test('keeps definitive Shop, Wholesale and Medicine taxonomies', () {
      expect(BuyV2Catalogue.shopCategories.length, 35);
      expect(BuyV2Catalogue.wholesaleCategories.length, 35);
      expect(BuyV2Catalogue.medicineCategories.length, 14);

      final identities = BuyV2Catalogue.products
          .map((item) => item.id)
          .toList();
      expect(identities.toSet().length, identities.length);
      expect(
        BuyV2Catalogue.shopCategories
            .skip(1)
            .every(
              (category) => BuyV2Catalogue.products.any(
                (product) =>
                    product.destination == BuyV2Destination.shop &&
                    product.categoryId == category.id,
              ),
            ),
        isTrue,
      );
      expect(
        BuyV2Catalogue.wholesaleCategories
            .skip(1)
            .every(
              (category) => BuyV2Catalogue.products.any(
                (product) =>
                    product.destination == BuyV2Destination.wholesale &&
                    product.categoryId == category.id,
              ),
            ),
        isTrue,
      );
    });

    test('supports Shop, Wholesale and Medicine in one cart', () {
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );

      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct(wholesale.id), isTrue);
      expect(session.addProduct(medicine.id), isTrue);

      expect(session.countForDestination(BuyV2Destination.shop), 1);
      expect(
        session.countForDestination(BuyV2Destination.wholesale),
        wholesale.minimumOrder,
      );
      expect(session.countForDestination(BuyV2Destination.medicine), 1);
      expect(
        session.cartLines.map((line) => line.product.id),
        containsAll([shop.id, wholesale.id, medicine.id]),
      );
    });

    test('one saved prescription unlocks only its matched medicine lines', () {
      const telmisartan = 'm-telmisartan-40';
      const atorvastatin = 'm-atorvastatin-10';
      const metformin = 'm-metformin-500';

      expect(session.addProduct(telmisartan), isFalse);
      expect(session.pendingPrescriptionProductId, telmisartan);

      session.approveSavedPrescription('meera');

      expect(session.quantityFor(telmisartan), 1);
      expect(session.addProduct(atorvastatin), isTrue);
      expect(session.addProduct(metformin), isFalse);
      expect(session.pendingPrescriptionProductId, metformin);
    });

    test('removing the final item returns directly to its catalogue', () {
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );
      session.openDestination(BuyV2Destination.medicine);
      session.addProduct(medicine.id);
      session.openCart(scope: BuyV2CartScope.medicine);

      session.decrease(medicine.id);

      expect(session.itemCount, 0);
      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.catalogue);
    });

    test('all four Buy destinations remain independent from cart scope', () {
      session.openDestination(BuyV2Destination.wholesale);
      session.openCart(scope: BuyV2CartScope.wholesale);
      session.openDestination(BuyV2Destination.shop);

      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
      expect(BuyV2Destination.values, contains(BuyV2Destination.medicine));
      expect(BuyV2Destination.values, contains(BuyV2Destination.orders));
    });
  });
}
