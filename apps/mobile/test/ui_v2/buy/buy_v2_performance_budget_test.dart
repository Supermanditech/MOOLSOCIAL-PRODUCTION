import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
  group('Buy V2 conservative in-process performance budgets', () {
    BuyV2Session createSession() => BuyV2Session(core: BuySession());

    test(
      'repeated vertical search and filter projections remain bounded',
      () {
        final session = createSession();
        const destinations = [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ];
        const filters = {
          BuyV2Destination.shop: 'nearby',
          BuyV2Destination.wholesale: 'freight',
          BuyV2Destination.medicine: 'otc',
        };
        final exactOfferByDestination = {
          for (final destination in destinations)
            destination: BuyV2Catalogue.products.firstWhere(
              (product) =>
                  product.destination == destination &&
                  !product.requiresPrescription,
            ),
        };

        var projectedOffers = 0;
        var crossVerticalOffers = 0;
        final stopwatch = Stopwatch()..start();
        for (var cycle = 0; cycle < 400; cycle += 1) {
          for (final destination in destinations) {
            session.openDestination(destination);
            session.chooseCategory('all');
            if (cycle.isEven) {
              session.chooseFilter(null);
              session.updateQuery(exactOfferByDestination[destination]!.id);
            } else {
              session.chooseFilter(filters[destination]);
              session.updateQuery('');
            }
            final projected = session.visibleProducts;
            projectedOffers += projected.length;
            crossVerticalOffers += projected
                .where((product) => product.destination != destination)
                .length;
          }
        }
        stopwatch.stop();

        debugPrint(
          'BUY_PERF search_filter_cycles=1200 '
          'projected_offers=$projectedOffers '
          'elapsed_ms=${stopwatch.elapsedMilliseconds} budget_ms=8000',
        );
        expect(projectedOffers, greaterThan(0));
        expect(crossVerticalOffers, 0);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'full current-seed mixed cart and checkout projection remain bounded',
      () {
        final session = createSession();
        final unrestrictedProducts = BuyV2Catalogue.products
            .where((product) => !product.requiresPrescription)
            .toList(growable: false);
        final expectedItemCount = unrestrictedProducts.fold<int>(
          0,
          (total, product) => total + product.minimumOrder,
        );
        final expectedTotal = unrestrictedProducts.fold<int>(
          0,
          (total, product) => total + product.price * product.minimumOrder,
        );

        final stopwatch = Stopwatch()..start();
        for (final product in unrestrictedProducts) {
          expect(session.addProduct(product.id), isTrue, reason: product.id);
        }
        session.openCart();
        session.openCheckout();

        var projectedLineCount = 0;
        var projectedGroupCount = 0;
        for (var cycle = 0; cycle < 500; cycle += 1) {
          projectedLineCount += session.checkoutLines.length;
          projectedGroupCount += session.checkoutFulfilmentGroups.length;
          if (session.checkoutItemCount != expectedItemCount ||
              session.checkoutTotal != expectedTotal) {
            fail('Checkout arithmetic changed during projection cycle $cycle.');
          }
        }
        stopwatch.stop();

        debugPrint(
          'BUY_PERF mixed_cart_offers=${unrestrictedProducts.length} '
          'projection_cycles=500 lines=$projectedLineCount '
          'groups=$projectedGroupCount '
          'elapsed_ms=${stopwatch.elapsedMilliseconds} budget_ms=8000',
        );
        expect(session.checkoutItemCount, expectedItemCount);
        expect(session.checkoutTotal, expectedTotal);
        expect(projectedLineCount, unrestrictedProducts.length * 500);
        expect(projectedGroupCount, greaterThan(0));
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'repeated vertical state transitions remain bounded and isolated',
      () {
        final session = createSession();
        final categoryByDestination = <BuyV2Destination, String>{
          BuyV2Destination.shop: BuyV2Catalogue.shopCategories[1].id,
          BuyV2Destination.wholesale: BuyV2Catalogue.wholesaleCategories[2].id,
          BuyV2Destination.medicine: BuyV2Catalogue.medicineCategories[1].id,
        };
        for (final entry in categoryByDestination.entries) {
          session.openDestination(entry.key);
          session.chooseCategory(entry.value);
        }

        final stopwatch = Stopwatch()..start();
        for (var cycle = 0; cycle < 2000; cycle += 1) {
          for (final entry in categoryByDestination.entries) {
            session.openDestination(entry.key);
            session.updateQuery('bounded-$cycle-${entry.key.name}');
            session.chooseFilter('bounded-filter');
          }
        }
        stopwatch.stop();

        for (final entry in categoryByDestination.entries) {
          session.openDestination(entry.key);
          expect(session.selectedCategoryId, entry.value);
          expect(session.query, isEmpty);
          expect(session.selectedFilter, isNull);
        }
        debugPrint(
          'BUY_PERF vertical_transitions=6000 '
          'elapsed_ms=${stopwatch.elapsedMilliseconds} budget_ms=8000',
        );
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
