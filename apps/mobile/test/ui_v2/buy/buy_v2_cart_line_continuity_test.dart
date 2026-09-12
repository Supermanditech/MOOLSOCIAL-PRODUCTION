import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
        initialCartScope: session.cartScope,
      ),
    );
  }

  BuyV2CartScope scopeFor(BuyV2Destination destination) =>
      switch (destination) {
        BuyV2Destination.shop => BuyV2CartScope.shop,
        BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
        BuyV2Destination.medicine => BuyV2CartScope.medicine,
        BuyV2Destination.orders => BuyV2CartScope.all,
      };

  BuyV2Product productFor(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == destination && !product.requiresPrescription,
      );

  testWidgets(
    'Shop Wholesale and Medicine Cart lines open exact details without owning quantity',
    (tester) async {
      final semantics = tester.ensureSemantics();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        final session = BuyV2Session(core: BuySession());
        final product = productFor(destination);
        expect(session.addProduct(product.id), isTrue);
        session.openCart(scope: scopeFor(destination));
        final originalQuantity = session.quantityFor(product.id);

        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();

        final details = find.byKey(
          ValueKey('buy-cart-product-details-${product.id}'),
        );
        expect(details, findsOneWidget, reason: destination.name);
        expect(tester.getSize(details).height, greaterThanOrEqualTo(44));
        final node = tester.getSemantics(details).getSemanticsData();
        expect(node.label, 'View ${product.title} product details');
        expect(node.hasAction(SemanticsAction.tap), isTrue);
        if (destination == BuyV2Destination.wholesale) {
          expect(
            find.byTooltip('Remove ${product.title} from Cart'),
            findsOneWidget,
          );
          expect(find.byTooltip('Add one trade pack'), findsOneWidget);
        } else {
          expect(find.byTooltip('Remove one'), findsOneWidget);
          expect(find.byTooltip('Add one'), findsOneWidget);
        }

        await tester.tap(details);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, product.id);
        expect(session.quantityFor(product.id), originalQuantity);

        session.goBack();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(session.cartScope, scopeFor(destination));
        expect(session.quantityFor(product.id), originalQuantity);
        expect(details, findsOneWidget);

        await tester.tap(
          find.byTooltip(
            destination == BuyV2Destination.wholesale
                ? 'Add one trade pack'
                : 'Add one',
          ),
        );
        await tester.pump();
        expect(session.view, BuyV2View.cart);
        expect(session.quantityFor(product.id), originalQuantity + 1);
        expect(tester.takeException(), isNull, reason: destination.name);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      semantics.dispose();
    },
  );

  testWidgets('two product hops return to exact Cart scope and scroll owner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final products = BuyV2Catalogue.products
        .where((product) => product.destination == BuyV2Destination.shop)
        .take(7)
        .toList(growable: false);
    for (final product in products) {
      expect(session.addProduct(product.id), isTrue);
    }
    session.openCart(scope: BuyV2CartScope.shop);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final target = find.byKey(
      ValueKey('buy-cart-product-details-${products.last.id}'),
    );
    await tester.scrollUntilVisible(
      target,
      260,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await tester.pumpAndSettle();
    final before = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;

    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(session.selectedProductId, products.last.id);
    final next = products.firstWhere(
      (product) => product.id != session.selectedProductId,
    );
    expect(session.openProduct(next.id), isTrue);
    await tester.pumpAndSettle();

    session.goBack();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);
    expect(session.cartLines, hasLength(products.length));
    final after = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    expect(after, closeTo(before, 1));
    expect(target, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cart detail owner is static and stable at 320px 140 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    final product = productFor(BuyV2Destination.wholesale);
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.wholesale);

    await tester.pumpWidget(
      app(session, disableAnimations: true, textScale: 1.4),
    );
    await tester.pump();

    final details = find.byKey(
      ValueKey('buy-cart-product-details-${product.id}'),
    );
    expect(details, findsOneWidget);
    expect(tester.getSize(details).height, greaterThanOrEqualTo(44));
    expect(find.byTooltip('Remove ${product.title} from Cart'), findsOneWidget);
    expect(find.byTooltip('Add one trade pack'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(details);
    await tester.pump();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);
    expect(tester.takeException(), isNull);
  });
}
