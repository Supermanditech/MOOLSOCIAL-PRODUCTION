import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
  group('Buy V2 exhaustive discovery contracts', () {
    late BuyV2Session session;

    setUp(() {
      session = BuyV2Session(core: BuySession());
    });

    const commerceDestinations = [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ];

    List<BuyV2Category> categoriesFor(BuyV2Destination destination) =>
        switch (destination) {
          BuyV2Destination.shop => BuyV2Catalogue.shopCategories,
          BuyV2Destination.wholesale => BuyV2Catalogue.wholesaleCategories,
          BuyV2Destination.medicine => BuyV2Catalogue.medicineCategories,
          BuyV2Destination.orders => const [],
        };

    List<BuyV2Product> expectedCategoryProducts(
      BuyV2Destination destination,
      String categoryId,
    ) {
      return BuyV2Catalogue.products
          .where((product) {
            if (product.destination != destination) return false;
            return categoryId == 'all' ||
                (categoryId == 'rx' && product.requiresPrescription) ||
                product.categoryId == categoryId;
          })
          .toList(growable: false);
    }

    test('every offer ID is discoverable only in its owning vertical', () {
      expect(BuyV2Catalogue.products, hasLength(176));

      for (final product in BuyV2Catalogue.products) {
        for (final destination in commerceDestinations) {
          session.openDestination(destination);
          session.chooseCategory('all');
          session.updateQuery(product.id);

          final results = session.visibleProducts;
          if (destination == product.destination) {
            expect(
              results.map((candidate) => candidate.id),
              contains(product.id),
              reason: '${product.id} searched in ${destination.name}',
            );
            expect(
              results.every(
                (candidate) => candidate.destination == product.destination,
              ),
              isTrue,
              reason: '${product.id} searched in ${destination.name}',
            );
          } else {
            expect(
              results,
              isEmpty,
              reason: '${product.id} searched in ${destination.name}',
            );
          }
        }
      }
    });

    test('every category projects its exact ordered catalogue membership', () {
      expect(
        commerceDestinations
            .expand(categoriesFor)
            .map((category) => category.id)
            .length,
        84,
      );

      for (final destination in commerceDestinations) {
        session.openDestination(destination);
        for (final category in categoriesFor(destination)) {
          session.chooseCategory(category.id);

          final expected = expectedCategoryProducts(destination, category.id);
          final actual = session.visibleProducts;
          final projectedExpected = category.id == 'all' && expected.length > 18
              ? expected.take(18)
              : expected;

          expect(
            actual.map((product) => product.id),
            projectedExpected.map((product) => product.id),
            reason: '${destination.name}/${category.id}',
          );
          expect(
            actual.every((product) => product.destination == destination),
            isTrue,
            reason: '${destination.name}/${category.id}',
          );
        }
      }
    });

    test(
      'category suggestions stay bounded, unique and projection-truthful',
      () {
        for (final destination in commerceDestinations) {
          session.openDestination(destination);
          for (final category in categoriesFor(destination)) {
            session.chooseCategory(category.id);

            final visibleIds = session.visibleProducts
                .map((product) => product.id)
                .toSet();
            final suggestions = session.searchSuggestions;
            final normalized = suggestions
                .map((suggestion) => suggestion.toLowerCase())
                .toSet();

            expect(
              suggestions.length,
              lessThanOrEqualTo(4),
              reason: '${destination.name}/${category.id}',
            );
            expect(
              normalized,
              hasLength(suggestions.length),
              reason: '${destination.name}/${category.id}',
            );

            for (final suggestion in suggestions) {
              expect(suggestion.trim(), isNotEmpty);
              expect(
                session.visibleProducts.any(
                  (product) => product.title == suggestion,
                ),
                isTrue,
                reason: '${destination.name}/${category.id}: $suggestion',
              );

              session.updateQuery(suggestion);
              expect(
                session.visibleProducts,
                isNotEmpty,
                reason: '${destination.name}/${category.id}: $suggestion',
              );
              expect(
                session.visibleProducts.every(
                  (product) =>
                      product.destination == destination &&
                      visibleIds.contains(product.id),
                ),
                isTrue,
                reason: '${destination.name}/${category.id}: $suggestion',
              );
              expect(session.searchSuggestions, isEmpty);
              session.updateQuery('');
            }
          }
        }

        session.openDestination(BuyV2Destination.orders);
        expect(session.searchSuggestions, isEmpty);
      },
    );
  });
}
