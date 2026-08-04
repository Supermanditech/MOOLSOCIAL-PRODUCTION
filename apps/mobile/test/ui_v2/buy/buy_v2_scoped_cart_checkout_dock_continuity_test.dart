import 'dart:ui' show SemanticsAction, Tristate;

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
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reducedMotion = false,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: size,
          padding: safeArea,
          viewPadding: safeArea,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
        initialCartScope: session.cartScope,
      ),
    );
  }

  BuyV2Product productFor(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == destination && !product.requiresPrescription,
      );

  BuyV2Session mixedSession() {
    final session = BuyV2Session(core: BuySession());
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      expect(session.addProduct(productFor(destination).id), isTrue);
    }
    return session;
  }

  void expectDockSelection(WidgetTester tester, BuyV2Destination expected) {
    final destinations = {
      BuyV2Destination.shop: 'shop',
      BuyV2Destination.wholesale: 'wholesale',
      BuyV2Destination.medicine: 'medicine',
      BuyV2Destination.orders: 'orders',
    };
    for (final entry in destinations.entries) {
      final node = tester.getSemantics(
        find.byKey(ValueKey('buy-dock-${entry.value}')),
      );
      expect(
        node.flagsCollection.isSelected,
        entry.key == expected ? Tristate.isTrue : Tristate.isFalse,
        reason: '${entry.key.name} for ${expected.name}',
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    }
  }

  const cases = [
    (
      scope: BuyV2CartScope.shop,
      last: BuyV2Destination.medicine,
      expected: BuyV2Destination.shop,
    ),
    (
      scope: BuyV2CartScope.wholesale,
      last: BuyV2Destination.shop,
      expected: BuyV2Destination.wholesale,
    ),
    (
      scope: BuyV2CartScope.medicine,
      last: BuyV2Destination.wholesale,
      expected: BuyV2Destination.medicine,
    ),
  ];

  test(
    'derived dock owner follows scoped Cart and Checkout without routing',
    () {
      for (final testCase in cases) {
        final session = mixedSession();
        addTearDown(session.dispose);
        session.openDestination(testCase.last);
        session.openCart(scope: testCase.scope);

        expect(session.destination, testCase.last);
        expect(session.activeDockDestination, testCase.expected);
        expect(session.openCheckout(), isTrue);
        expect(session.destination, testCase.last);
        expect(session.checkoutScope, testCase.scope);
        expect(session.activeDockDestination, testCase.expected);

        session.openCart(scope: session.checkoutScope);
        expect(session.destination, testCase.last);
        expect(session.cartScope, testCase.scope);
        expect(session.activeDockDestination, testCase.expected);
      }

      final combined = mixedSession();
      addTearDown(combined.dispose);
      combined.openDestination(BuyV2Destination.shop);
      combined.openCart();
      expect(combined.activeDockDestination, BuyV2Destination.shop);
      expect(combined.openCheckout(), isTrue);
      expect(combined.activeDockDestination, BuyV2Destination.shop);
      expect(combined.destination, BuyV2Destination.shop);
    },
  );

  testWidgets(
    'scoped Cart and Checkout expose one truthful selected dock item',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();

      for (final testCase in cases) {
        final session = mixedSession();
        addTearDown(session.dispose);
        session.openDestination(testCase.last);
        session.openCart(scope: testCase.scope);

        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        expectDockSelection(tester, testCase.expected);
        expect(session.destination, testCase.last);

        expect(session.openCheckout(), isTrue);
        await tester.pumpAndSettle();
        expectDockSelection(tester, testCase.expected);
        expect(session.destination, testCase.last);

        await tester.tap(
          find.byKey(ValueKey('buy-dock-${testCase.expected.name}')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
        expect(session.destination, testCase.expected);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
      semantics.dispose();
    },
  );

  testWidgets('combined scope retains its valid entry vertical', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.shop);
    session.openCart();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expectDockSelection(tester, BuyV2Destination.shop);
    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    expectDockSelection(tester, BuyV2Destination.shop);
    expect(session.destination, BuyV2Destination.shop);
    semantics.dispose();
  });

  testWidgets('320px 140% reduced motion is immediate and semantically exact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.medicine);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);

    await tester.pumpWidget(
      app(
        session,
        size: const Size(320, 568),
        textScale: 1.4,
        reducedMotion: true,
      ),
    );
    await tester.pump();
    expectDockSelection(tester, BuyV2Destination.shop);
    expect(session.destination, BuyV2Destination.medicine);
    expect(find.textContaining('Shop fulfilment ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('R58.8.7 responsive Android and iOS candidate captures', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final viewport in const [
      (
        size: Size(320, 568),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.0,
        reduced: false,
        checkout: true,
        label: '320x568-android-checkout',
      ),
      (
        size: Size(360, 800),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.0,
        reduced: false,
        checkout: false,
        label: '360x800-android-cart',
      ),
      (
        size: Size(390, 844),
        safe: EdgeInsets.only(top: 47, bottom: 34),
        textScale: 1.0,
        reduced: false,
        checkout: true,
        label: '390x844-ios-checkout',
      ),
      (
        size: Size(430, 932),
        safe: EdgeInsets.only(top: 59, bottom: 34),
        textScale: 1.0,
        reduced: false,
        checkout: false,
        label: '430x932-ios-cart',
      ),
      (
        size: Size(320, 568),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.4,
        reduced: true,
        checkout: true,
        label: '320x568-a11y140-reduced',
      ),
    ]) {
      tester.view.physicalSize = viewport.size;
      final session = mixedSession();
      session.openDestination(BuyV2Destination.medicine);
      session.openCart(scope: BuyV2CartScope.shop);
      if (viewport.checkout) {
        expect(session.openCheckout(), isTrue);
      }

      await tester.pumpWidget(
        app(
          session,
          size: viewport.size,
          textScale: viewport.textScale,
          reducedMotion: viewport.reduced,
          safeArea: viewport.safe,
        ),
      );
      await tester.pumpAndSettle();
      expectDockSelection(tester, BuyV2Destination.shop);
      await expectLater(
        find.byType(BuyV2Screen),
        matchesGoldenFile(
          'candidate_captures/buy-v2-r58-8-7-${viewport.label}.png',
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  });
}
