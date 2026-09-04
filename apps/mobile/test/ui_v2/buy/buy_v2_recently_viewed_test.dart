import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      productId: session.selectedProductId,
    ),
  );

  test(
    'recently viewed keeps exact products, restores and stays bounded',
    () async {
      final store = _MemoryCustomerStateStore();
      final core = BuySession();
      final session = BuyV2Session(core: core, customerStateStore: store);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      final products = BuyV2Catalogue.products
          .where(
            (product) =>
                product.destination == BuyV2Destination.shop ||
                product.destination == BuyV2Destination.wholesale,
          )
          .toList(growable: false);
      expect(products.length, greaterThan(10));
      for (final product in products) {
        expect(session.openProduct(product.id), isTrue);
      }
      final retained = [
        ...session.recentlyViewedProductsFor(BuyV2Destination.shop),
        ...session.recentlyViewedProductsFor(BuyV2Destination.wholesale),
      ];
      expect(retained, hasLength(10));
      expect(retained.map((product) => product.id), contains(products.last.id));
      expect(store.snapshot?.recentlyViewedProductIds, hasLength(10));

      final restoredCore = BuySession();
      final restored = BuyV2Session(
        core: restoredCore,
        customerStateStore: store,
      );
      addTearDown(restored.dispose);
      addTearDown(restoredCore.dispose);
      await restored.restoreCustomerState();
      expect(
        restored.recentlyViewedProductsFor(BuyV2Destination.medicine),
        isEmpty,
      );
      expect([
        ...restored.recentlyViewedProductsFor(BuyV2Destination.shop),
        ...restored.recentlyViewedProductsFor(BuyV2Destination.wholesale),
      ], hasLength(10));

      restored.clearRecentlyViewed(BuyV2Destination.shop);
      expect(
        restored.recentlyViewedProductsFor(BuyV2Destination.shop),
        isEmpty,
      );
      expect(
        restored.recentlyViewedProductsFor(BuyV2Destination.wholesale),
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'recently viewed reopens exact variant and clears at large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);
      expect(session.selectProductVariant('s-milk-2l'), isTrue);
      session.closeProduct();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final rail = find.byKey(const ValueKey('buy-recently-viewed'));
      await tester.scrollUntilVisible(
        rail,
        240,
        scrollable: find
            .descendant(
              of: find.byType(BuyV2CatalogueView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Recently viewed'), findsOneWidget);
      expect(find.text('2 × 1 L pouches'), findsWidgets);

      final exactVariant = find.byKey(
        const ValueKey('buy-recently-viewed-product-s-milk-2l'),
      );
      await tester.tap(exactVariant);
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk-2l');
      expect(session.view, BuyV2View.product);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      await tester.scrollUntilVisible(
        rail,
        240,
        scrollable: find
            .descendant(
              of: find.byType(BuyV2CatalogueView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const ValueKey('buy-recently-viewed-clear')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-recently-viewed')), findsNothing);
      expect(session.view, BuyV2View.catalogue);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _MemoryCustomerStateStore implements BuyV2CustomerStateStore {
  BuyV2CustomerStateSnapshot? snapshot;

  @override
  String? get ownerScope => 'customer:recently-viewed';

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    snapshot = value;
    return true;
  }
}
