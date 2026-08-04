import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_search_relevance.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  group('Buy V2 exact-first typo-tolerant search relevance', () {
    test('keeps correct exact, prefix and substring results above noise', () {
      final ranked = BuyV2SearchRelevance.rankProducts([
        product('fuzzy', title: 'Tamato pantry pack'),
        product('contains', title: 'Farm fresh tomato crate'),
        product('prefix', title: 'Tomato sauce'),
        product('exact', title: 'Tomato'),
      ], 'tomato');

      expect(ranked.map((item) => item.id), ['exact', 'prefix', 'contains']);
    });

    test('uses bounded fuzzy ranking only when no direct result exists', () {
      final ranked = BuyV2SearchRelevance.rankProducts([
        product('second', title: 'Tamato pantry pack'),
        product('first', title: 'Tomato'),
      ], 'tomatos');

      expect(ranked.map((item) => item.id), ['first', 'second']);
    });

    test('keeps catalogue order for equal relevance scores', () {
      final ranked = BuyV2SearchRelevance.rankProducts([
        product('first', title: 'Tommato pack one'),
        product('second', title: 'Tommato pack two'),
      ], 'tomato');

      expect(ranked.map((item) => item.id), ['first', 'second']);
    });

    test('recovers deletion, insertion and adjacent transposition typos', () {
      final session = BuyV2Session(core: BuySession());
      session.chooseCategory('all');

      session.updateQuery('tomatos');
      expect(session.visibleProducts.first.title, 'Fresh tomatoes');

      session.updateQuery('shmapoo');
      expect(
        session.visibleProducts.map((item) => item.title),
        contains('Daily care shampoo'),
      );

      session.openDestination(BuyV2Destination.medicine);
      session.chooseCategory('all');
      session.updateQuery('paracetmol');
      expect(
        session.visibleProducts.map((item) => item.title),
        contains('Paracetamol 500 mg tablets'),
      );
    });

    test('requires every multi-word query token to match', () {
      final session = BuyV2Session(core: BuySession());
      session.chooseCategory('all');

      session.updateQuery('frsh tomatos');
      expect(session.visibleProducts.first.title, 'Fresh tomatoes');

      session.updateQuery('frsh tractor');
      expect(session.visibleProducts, isEmpty);
    });

    test('does not fuzzy-expand tokens shorter than four characters', () {
      final session = BuyV2Session(core: BuySession());
      session.chooseCategory('all');
      session.updateQuery('mlk');

      expect(session.visibleProducts, isEmpty);
    });

    test('finds current seller/provider text without inventing a service', () {
      final session = BuyV2Session(core: BuySession());
      session.chooseCategory('all');
      session.updateQuery('balajii');

      expect(session.visibleProducts.first.id, 's-tomato');
      expect(session.visibleProducts.first.seller, 'Shree Balaji Fresh');
    });

    test('offer IDs remain literal-only and fail closed across verticals', () {
      final session = BuyV2Session(core: BuySession());
      session.chooseCategory('all');

      session.updateQuery('s-tomato');
      expect(session.visibleProducts.map((item) => item.id), ['s-tomato']);

      session.updateQuery('s-tomto');
      expect(session.visibleProducts, isEmpty);

      session.updateQuery('w-tomato');
      expect(session.visibleProducts, isEmpty);
    });

    test('category and filter ownership execute before fuzzy ranking', () {
      final session = BuyV2Session(core: BuySession());
      session.chooseCategory('dairy-bakery');
      session.updateQuery('tomatos');
      expect(session.visibleProducts, isEmpty);

      session.chooseCategory('all');
      session.chooseFilter('returns');
      session.updateQuery('tomatos');
      expect(
        session.visibleProducts.every(
          (item) => item.destination == BuyV2Destination.shop,
        ),
        isTrue,
      );
    });

    test(
      'current-seed near-spelling workload stays conservatively bounded',
      () {
        final session = BuyV2Session(core: BuySession());
        final stopwatch = Stopwatch()..start();
        for (var iteration = 0; iteration < 300; iteration++) {
          session.openDestination(BuyV2Destination.values[iteration % 3]);
          session.chooseCategory('all');
          session.updateQuery(
            const ['tomatos', 'sunflwer', 'paracetmol'][iteration % 3],
          );
          session.visibleProducts;
        }
        stopwatch.stop();

        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));
      },
    );

    testWidgets('near spelling renders the real result in the existing UI', (
      tester,
    ) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'tomatos',
      );
      await tester.pumpAndSettle();

      expect(session.query, 'tomatos');
      expect(session.visibleProducts.first.id, 's-tomato');
      expect(
        find.byKey(const ValueKey('buy-product-s-tomato')),
        findsOneWidget,
      );
      expect(find.textContaining('No matches for'), findsNothing);
    });
  });
}

BuyV2Product product(String id, {required String title}) => BuyV2Product(
  id: id,
  destination: BuyV2Destination.shop,
  categoryId: 'all',
  brand: 'Test brand',
  title: title,
  variant: 'Test variant',
  pack: '1 pack',
  price: 1,
  unitPrice: '₹1/pack',
  badge: 'Test',
  seller: 'Test seller',
  sellerType: 'Verified retailer',
  deliveryPromise: 'Today',
  origin: 'Jodhpur',
  confirmedOn: '2 Aug',
  visualLabel: title,
  visualKind: 'pack',
);
