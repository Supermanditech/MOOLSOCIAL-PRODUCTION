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
    bool offers = false,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      initialCartScope: session.cartScope,
      initialOffersActive: offers,
    ),
  );

  void expectGlobalActions() {
    expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-buy')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-global-chat')), findsOneWidget);
  }

  void expectBuyActions() {
    expectGlobalActions();
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );
    for (final key in const [
      'buy-local-tab-wholesale',
      'buy-local-tab-orders',
      'buy-local-tab-offers',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    expect(
      find.byKey(const ValueKey('buy-scoped-purchase-owner')),
      findsNothing,
    );
  }

  void expectCareActions() {
    expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-book')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-global-chat')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('care-local-destination-tabs')),
      findsOneWidget,
    );
    for (final key in const [
      'care-local-tab-doctor',
      'care-local-tab-medicine',
      'care-local-tab-salon',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
  }

  testWidgets('Buy actions remain mounted through every purchase surface', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expectBuyActions();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    expectBuyActions();

    expect(session.openProduct('w-onion'), isTrue);
    await tester.pumpAndSettle();
    expectBuyActions();

    expect(session.addProduct('w-onion'), isTrue);
    session.openCart();
    await tester.pumpAndSettle();
    expectBuyActions();

    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    expectBuyActions();

    session.openOrders();
    await tester.pumpAndSettle();
    expectBuyActions();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Offers and GST overlay do not remove the established rail', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final offersSession = BuyV2Session(core: BuySession());
    addTearDown(offersSession.dispose);

    await tester.pumpWidget(app(offersSession, offers: true));
    await tester.pumpAndSettle();
    expectBuyActions();

    final checkout = BuyV2Session(core: BuySession());
    addTearDown(checkout.dispose);
    expect(checkout.addProduct('w-onion'), isTrue);
    checkout.openCart();
    expect(checkout.openCheckout(), isTrue);
    await tester.pumpWidget(app(checkout));
    await tester.pumpAndSettle();
    expectBuyActions();

    await tester.tap(find.byKey(const ValueKey('buy-gst-request-wholesale')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-gst-add-wholesale')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-gst-invoice-sheet')), findsOneWidget);
    expectBuyActions();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medicine Cart and Checkout retain every Care action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.medicine);

    await tester.pumpWidget(
      app(session, size: const Size(320, 568), textScale: 1.4),
    );
    await tester.pumpAndSettle();
    expectCareActions();

    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    expectCareActions();
    expect(tester.takeException(), isNull);
  });
}
