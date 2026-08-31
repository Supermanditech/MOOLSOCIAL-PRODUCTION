import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('product options preserve exact pack Cart and Back state', (
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
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          productId: session.selectedProductId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selector = find.byKey(const ValueKey('buy-product-variants-milk'));
    await tester.scrollUntilVisible(
      selector,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(selector, findsOneWidget);
    for (final id in const ['s-milk', 's-milk-500ml', 's-milk-2l']) {
      expect(find.byKey(ValueKey('buy-product-variant-$id')), findsOneWidget);
    }

    await tester.tap(
      find.byKey(const ValueKey('buy-product-variant-s-milk-500ml')),
    );
    await tester.pumpAndSettle();
    expect(session.selectedProduct?.id, 's-milk-500ml');
    expect(find.text('500 ml pouch'), findsWidgets);

    final add = find.byKey(const ValueKey('buy-product-primary-s-milk-500ml'));
    await tester.scrollUntilVisible(
      add,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk-500ml')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-product-action-delivery-s-milk-500ml')),
      findsOneWidget,
    );
    expect(find.textContaining('Standard/courier delivery'), findsWidgets);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-milk-500ml'), 1);
    expect(session.quantityFor('s-milk'), 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view.name, 'catalogue');
    expect(tester.takeException(), isNull);
  });
}
