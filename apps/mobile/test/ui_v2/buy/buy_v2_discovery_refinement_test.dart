import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openRefinement(WidgetTester tester, BuyV2Session session) async {
    await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-discovery-refinement')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-discovery-refinement-title')),
      findsOneWidget,
    );
    expect(session.destination, BuyV2Destination.shop);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('sort and filters combine, clear and return to exact Shop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    await openRefinement(tester, session);

    await tapVisible(tester, const ValueKey('buy-sort-priceLowToHigh'));
    await tapVisible(tester, const ValueKey('buy-refine-delivery-quickLocal'));
    await tapVisible(tester, const ValueKey('buy-refine-price-250'));
    await tapVisible(tester, const ValueKey('buy-refine-available-products'));
    expect(session.productSort, BuyV2ProductSort.priceLowToHigh);
    expect(session.selectedFulfilmentMode, BuyV2FulfilmentMode.quickLocal);
    expect(session.maximumProductPrice, 250);
    expect(session.availableProductsOnly, isTrue);
    expect(session.visibleProducts, isNotEmpty);
    final prices = session.visibleProducts
        .map((product) => session.productFactsFor(product).price)
        .toList(growable: false);
    expect(prices, orderedEquals([...prices]..sort()));

    await tester.tap(
      find.byKey(const ValueKey('buy-discovery-refinement-done')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);

    await openRefinement(tester, session);
    await tester.tap(
      find.byKey(const ValueKey('buy-discovery-refinement-clear')),
    );
    await tester.pumpAndSettle();
    expect(session.activeDiscoveryRefinementCount, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery browse actions open the category destination', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('buy-featured-browse-categories')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-category-sheet-route')), findsOne);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final browseMore = find.byKey(
      const ValueKey('buy-more-products-browse-categories'),
    );
    await tester.scrollUntilVisible(
      browseMore,
      220,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(browseMore);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-category-sheet-route')), findsOne);
    expect(tester.takeException(), isNull);
  });
}
