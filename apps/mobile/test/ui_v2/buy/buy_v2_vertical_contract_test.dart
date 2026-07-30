import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
  group('Buy V2 independent vertical contracts', () {
    late BuyV2Session session;

    setUp(() {
      session = BuyV2Session(core: BuySession());
    });

    List<BuyV2Product> productsFor(BuyV2Destination destination) =>
        BuyV2Catalogue.products
            .where((product) => product.destination == destination)
            .toList(growable: false);

    List<BuyV2Category> categoriesFor(BuyV2Destination destination) =>
        switch (destination) {
          BuyV2Destination.shop => BuyV2Catalogue.shopCategories,
          BuyV2Destination.wholesale => BuyV2Catalogue.wholesaleCategories,
          BuyV2Destination.medicine => BuyV2Catalogue.medicineCategories,
          BuyV2Destination.orders => const [],
        };

    test('every product is complete and belongs to its vertical taxonomy', () {
      expect(productsFor(BuyV2Destination.shop), hasLength(84));
      expect(productsFor(BuyV2Destination.wholesale), hasLength(84));
      expect(productsFor(BuyV2Destination.medicine), hasLength(8));
      expect(productsFor(BuyV2Destination.orders), isEmpty);

      final ids = <String>{};
      for (final product in BuyV2Catalogue.products) {
        expect(ids.add(product.id), isTrue, reason: product.id);
        expect(product.id.trim(), isNotEmpty, reason: product.id);
        expect(product.canonicalId.trim(), isNotEmpty, reason: product.id);
        expect(product.title.trim(), isNotEmpty, reason: product.id);
        expect(product.brand.trim(), isNotEmpty, reason: product.id);
        expect(product.variant.trim(), isNotEmpty, reason: product.id);
        expect(product.pack.trim(), isNotEmpty, reason: product.id);
        expect(product.price, greaterThan(0), reason: product.id);
        expect(product.minimumOrder, greaterThan(0), reason: product.id);
        expect(product.seller.trim(), isNotEmpty, reason: product.id);
        expect(product.sellerType.trim(), isNotEmpty, reason: product.id);
        expect(product.deliveryPromise.trim(), isNotEmpty, reason: product.id);
        expect(product.origin.trim(), isNotEmpty, reason: product.id);
        expect(product.confirmedOn.trim(), isNotEmpty, reason: product.id);
        expect(
          categoriesFor(product.destination).map((category) => category.id),
          contains(product.categoryId),
          reason: '${product.id} -> ${product.categoryId}',
        );
        if (product.mrp case final mrp?) {
          expect(mrp, greaterThanOrEqualTo(product.price), reason: product.id);
        }
      }

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        final categoryIds = categoriesFor(
          destination,
        ).map((category) => category.id).toList(growable: false);
        expect(
          categoryIds.toSet(),
          hasLength(categoryIds.length),
          reason: destination.name,
        );
      }
    });

    test('Shop and Wholesale share identity, never offer records', () {
      final shops = productsFor(BuyV2Destination.shop);
      final wholesaleByCanonicalId = {
        for (final product in productsFor(BuyV2Destination.wholesale))
          product.canonicalId: product,
      };

      for (final shop in shops) {
        final wholesale = wholesaleByCanonicalId[shop.canonicalId];
        expect(wholesale, isNotNull, reason: shop.canonicalId);
        expect(wholesale!.id, isNot(shop.id), reason: shop.canonicalId);
        expect(shop.id, startsWith('s-'), reason: shop.canonicalId);
        expect(wholesale.id, startsWith('w-'), reason: shop.canonicalId);
        expect(wholesale.title, shop.title, reason: shop.canonicalId);
        expect(wholesale.brand, shop.brand, reason: shop.canonicalId);
        expect(shop.minimumOrder, 1, reason: shop.canonicalId);
        expect(shop.freightIncluded, isFalse, reason: shop.canonicalId);
        expect(wholesale.freightIncluded, isTrue, reason: shop.canonicalId);
      }
    });

    test('Medicine remains licensed and regulatory facts stay attached', () {
      for (final product in productsFor(BuyV2Destination.medicine)) {
        expect(product.id, startsWith('m-'), reason: product.id);
        expect(product.canonicalId, product.id, reason: product.id);
        expect(product.sellerType, 'Licensed pharmacy', reason: product.id);
        expect(product.composition?.trim(), isNotEmpty, reason: product.id);
        expect(product.regulatoryNote?.trim(), isNotEmpty, reason: product.id);
        if (product.requiresPrescription) {
          expect(
            product.confirmedOn.toLowerCase(),
            contains('pharmacist'),
            reason: product.id,
          );
          expect(
            product.badge.toLowerCase(),
            contains('prescription'),
            reason: product.id,
          );
        }
      }
    });

    test('exact offer search never crosses destination boundaries', () {
      session.openDestination(BuyV2Destination.shop);
      session.updateQuery('s-tomato');
      expect(session.visibleProducts.map((product) => product.id), [
        's-tomato',
      ]);
      session.updateQuery('w-tomato');
      expect(session.visibleProducts, isEmpty);

      session.openDestination(BuyV2Destination.wholesale);
      session.updateQuery('w-tomato');
      expect(session.visibleProducts.map((product) => product.id), [
        'w-tomato',
      ]);
      session.updateQuery('s-tomato');
      expect(session.visibleProducts, isEmpty);

      session.openDestination(BuyV2Destination.medicine);
      session.updateQuery('m-ors');
      expect(session.visibleProducts.map((product) => product.id), ['m-ors']);
      session.updateQuery('s-tomato');
      expect(session.visibleProducts, isEmpty);
    });

    test('category state is independent and transient search state resets', () {
      session.openDestination(BuyV2Destination.shop);
      session.chooseCategory('fruits-vegetables');
      session.updateQuery('tomato');
      session.chooseFilter('nearby');

      session.openDestination(BuyV2Destination.wholesale);
      expect(session.selectedCategoryId, 'all');
      expect(session.query, isEmpty);
      expect(session.selectedFilter, isNull);
      session.chooseCategory('flour-rice-grains');

      session.openDestination(BuyV2Destination.medicine);
      session.chooseCategory('rx');

      session.openDestination(BuyV2Destination.shop);
      expect(session.selectedCategoryId, 'fruits-vegetables');
      expect(session.query, isEmpty);
      expect(session.selectedFilter, isNull);

      session.openDestination(BuyV2Destination.wholesale);
      expect(session.selectedCategoryId, 'flour-rice-grains');
      session.openDestination(BuyV2Destination.medicine);
      expect(session.selectedCategoryId, 'rx');
    });

    test(
      'filters and exposed cart collections cannot cross or mutate state',
      () {
        for (final entry in const {
          BuyV2Destination.shop: 'nearby',
          BuyV2Destination.wholesale: 'freight',
          BuyV2Destination.medicine: 'otc',
        }.entries) {
          session.openDestination(entry.key);
          session.chooseCategory('all');
          session.chooseFilter(entry.value);
          expect(session.visibleProducts, isNotEmpty, reason: entry.key.name);
          expect(
            session.visibleProducts.every(
              (product) => product.destination == entry.key,
            ),
            isTrue,
            reason: entry.key.name,
          );
        }

        final shop = productsFor(BuyV2Destination.shop).first;
        final wholesale = productsFor(BuyV2Destination.wholesale).first;
        session.addProduct(shop.id);
        session.addProduct(wholesale.id);

        expect(
          () =>
              session.cartLines.add(BuyV2CartLine(product: shop, quantity: 1)),
          throwsUnsupportedError,
        );
        expect(
          () => session.cartDestinations.add(BuyV2Destination.medicine),
          throwsUnsupportedError,
        );
        expect(session.quantityFor(shop.id), 1);
        expect(session.quantityFor(wholesale.id), wholesale.minimumOrder);
      },
    );
  });
}
