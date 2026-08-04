import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

Widget host(
  BuyV2Session session, {
  bool reduced = false,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: reduced,
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

AnimatedSwitcher switcherInside(WidgetTester tester, Finder owner) {
  return tester.widget<AnimatedSwitcher>(
    find.descendant(of: owner, matching: find.byType(AnimatedSwitcher)).first,
  );
}

BuyV2Product firstProduct(BuyV2Destination destination) {
  return BuyV2Catalogue.products.firstWhere(
    (product) =>
        product.destination == destination &&
        (destination != BuyV2Destination.medicine ||
            !product.requiresPrescription),
  );
}

void main() {
  testWidgets('Saved and catalogue quantity motion keep fixed hit owners', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    final product = firstProduct(BuyV2Destination.shop);
    session.addProduct(product.id);
    session.clearCartAcknowledgement();
    await tester.pumpWidget(host(session));
    await tester.pumpAndSettle();

    final save = find.byKey(ValueKey('buy-save-${product.id}'));
    final saveVisual = find.byKey(ValueKey('buy-save-visual-${product.id}'));
    final quantity = find.byKey(ValueKey('buy-quantity-${product.id}'));
    final value = find.descendant(
      of: quantity,
      matching: find.byType(BuyV2FiniteValueTransition),
    );
    expect(save, findsOneWidget);
    expect(saveVisual, findsOneWidget);
    expect(quantity, findsOneWidget);
    expect(value, findsOneWidget);
    expect(
      switcherInside(tester, saveVisual).duration,
      BuyV2Motion.stateChange,
    );
    expect(switcherInside(tester, value).duration, BuyV2Motion.stateChange);
    for (final action in [
      'Decrease ${product.title} quantity from ${product.minimumOrder}',
      'Increase ${product.title} quantity from ${product.minimumOrder}',
    ]) {
      final owner = find.bySemanticsLabel(action);
      expect(owner, findsOneWidget);
      expect(
        tester
            .getSemantics(owner)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }

    final saveRect = tester.getRect(save);
    final quantityRect = tester.getRect(quantity);
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 90));
    expect(session.isSaved(product.id), isTrue);
    expect(tester.getRect(save), saveRect);
    expect(
      find.descendant(of: save, matching: find.byIcon(Icons.bookmark_rounded)),
      findsOneWidget,
    );

    session.increase(product.id);
    await tester.pump(const Duration(milliseconds: 90));
    expect(session.quantityFor(product.id), product.minimumOrder + 1);
    expect(tester.getRect(quantity), quantityRect);
    expect(
      tester.widget<BuyV2FiniteValueTransition>(value).text,
      '${product.minimumOrder + 1}',
    );
    await tester.pumpAndSettle();
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mini Cart and Cart values settle from real session arithmetic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    final session = BuyV2Session(core: BuySession());
    final product = firstProduct(BuyV2Destination.shop);
    session.addProduct(product.id);
    session.clearCartAcknowledgement();
    await tester.pumpWidget(host(session));
    await tester.pumpAndSettle();

    final miniCart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    final miniTotal = find.byKey(const ValueKey('buy-mini-cart-total-motion'));
    final miniRect = tester.getRect(miniCart);
    expect(switcherInside(tester, miniTotal).duration, BuyV2Motion.stateChange);
    expect(
      tester
          .getSemantics(miniCart)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    session.increase(product.id);
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.getRect(miniCart), miniRect);
    expect(
      tester.getSemantics(miniCart).label,
      contains(buyV2Money(session.cartTotal)),
    );
    await tester.pumpAndSettle();

    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    final line = find.byKey(ValueKey('buy-cart-line-${product.id}'));
    final lineQuantity = find.byKey(
      ValueKey('buy-cart-line-quantity-motion-${product.id}'),
    );
    final lineTotal = find.byKey(
      ValueKey('buy-cart-line-total-motion-${product.id}'),
    );
    final payable = find.byKey(const ValueKey('buy-cart-payable-total-motion'));
    final lineRect = tester.getRect(line);
    final quantityRect = tester.getRect(lineQuantity);
    final totalRect = tester.getRect(lineTotal);

    session.increase(product.id);
    await tester.pump(const Duration(milliseconds: 90));
    final expectedQuantity = product.minimumOrder + 2;
    expect(session.quantityFor(product.id), expectedQuantity);
    expect(session.cartTotal, product.price * expectedQuantity);
    expect(tester.getRect(line), lineRect);
    expect(tester.getRect(lineQuantity), quantityRect);
    expect(tester.getRect(lineTotal), totalRect);
    expect(
      tester.widget<BuyV2FiniteValueTransition>(lineQuantity).text,
      '$expectedQuantity',
    );
    expect(
      tester.widget<BuyV2FiniteValueTransition>(payable).text,
      buyV2Money(session.scopedPayableTotal),
    );
    await tester.pumpAndSettle();
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saved filter retains one accessible tap action', (tester) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(host(session));
    await tester.pumpAndSettle();

    final savedFilter = find.bySemanticsLabel('Show Saved products, 0 saved');
    expect(savedFilter, findsOneWidget);
    expect(
      tester
          .getSemantics(savedFilter)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });

  test('Shop, Wholesale and Medicine quantity rules remain session-owned', () {
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      final session = BuyV2Session(core: BuySession());
      final product = firstProduct(destination);
      session.addProduct(product.id);
      expect(session.quantityFor(product.id), product.minimumOrder);
      expect(session.cartTotal, product.price * product.minimumOrder);

      session.increase(product.id);
      expect(session.quantityFor(product.id), product.minimumOrder + 1);
      expect(session.cartTotal, product.price * (product.minimumOrder + 1));

      session.decrease(product.id);
      expect(session.quantityFor(product.id), product.minimumOrder);
      expect(session.cartTotal, product.price * product.minimumOrder);
    }
  });

  testWidgets('reduced motion is zero and Cart fits 320 px at 140 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      session.addProduct(firstProduct(destination).id);
    }
    session.openCart();
    await tester.pumpWidget(host(session, reduced: true, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final owner in <Finder>[
      find.byKey(const ValueKey('buy-cart-header-value-motion')),
      find.byKey(const ValueKey('buy-cart-payable-total-motion')),
      find.byKey(
        ValueKey(
          'buy-cart-line-quantity-motion-'
          '${firstProduct(BuyV2Destination.shop).id}',
        ),
      ),
    ]) {
      expect(owner, findsOneWidget);
      expect(switcherInside(tester, owner).duration, Duration.zero);
    }
    expect(find.byKey(const ValueKey('buy-cart-action-bar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
